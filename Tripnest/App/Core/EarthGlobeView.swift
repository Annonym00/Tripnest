import CoreLocation
import SwiftUI
import WebKit

struct EarthGlobeTripMarker: Codable, Identifiable, Hashable {
    let id: String
    let lat: Double
    let lon: Double
    let flag: String
    let title: String
    let subtitle: String
    let detail: String
}

struct EarthGlobeRoutePoint: Codable, Hashable {
    let lat: Double
    let lon: Double
}

private struct EarthGlobeRoutePayload: Codable {
    let points: [EarthGlobeRoutePoint]
    let mode: String
    let departure: String
    let arrival: String
    let duration: String
    let originLabel: String
    let destLabel: String
}

// ─── SwiftUI View ─────────────────────────────────────────────────────────────
struct EarthGlobeView: UIViewRepresentable {
    /// Distance caméra–Terre (plus petit = Terre plus grande à l’écran).
    var cameraDistance: Double = 3.12
    var fieldOfView: Double = 47
    /// Décale la Terre dans le cadre (léger positif = un peu plus bas à l’écran).
    var cameraYOffset: Double = 0.1
    var flyToTrigger: Int = 0
    var flyToLatitude: Double?
    var flyToLongitude: Double?
    /// Zoom rapproché + verrouillage caméra (destination / drapeau).
    var flyWithZoom: Bool = false
    /// Grand cercle départ → arrivée (animation sur la planète).
    var routePath: [EarthGlobeRoutePoint] = []
    var routeTransportMode: String = "plane"
    var routeDepartureTime: String = ""
    var routeArrivalTime: String = ""
    var routeDurationLabel: String = ""
    var routeOriginLabel: String = ""
    var routeDestLabel: String = ""
    /// Déverrouille, dézoome vers la vue de base et relance la rotation.
    var resetGlobeTrigger: Int = 0
    var focusedMarkerId: String?
    var focusedMarkerRevision: Int = 0
    var tripMarkers: [EarthGlobeTripMarker] = []
    var markersRevision: Int = 0
    var onMarkerTap: ((String) -> Void)?
    var onDismissFocus: (() -> Void)?
    var onUserInteraction: (() -> Void)?
    /// `present` = milieu du vol (fiche), `complete` = vol terminé.
    var onFocusFlyPhase: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onMarkerTap: onMarkerTap,
            onDismissFocus: onDismissFocus,
            onUserInteraction: onUserInteraction,
            onFocusFlyPhase: onFocusFlyPhase
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var lastFlyTrigger = -1
        var lastResetTrigger = -1
        var lastFocusedMarkerRevision = -1
        var lastMarkersRevision = -1
        var isReady = false
        var pendingFlyTrigger = -1
        var pendingFlyLatitude: Double?
        var pendingFlyLongitude: Double?
        var pendingFlyWithZoom = false
        var pendingRoutePath: [EarthGlobeRoutePoint] = []
        var pendingRouteMode = "plane"
        var pendingRouteDeparture = ""
        var pendingRouteArrival = ""
        var pendingRouteDuration = ""
        var pendingRouteOriginLabel = ""
        var pendingRouteDestLabel = ""
        var onMarkerTap: ((String) -> Void)?
        var onDismissFocus: (() -> Void)?
        var onUserInteraction: (() -> Void)?
        var onFocusFlyPhase: ((String) -> Void)?

        init(
            onMarkerTap: ((String) -> Void)?,
            onDismissFocus: (() -> Void)?,
            onUserInteraction: (() -> Void)?,
            onFocusFlyPhase: ((String) -> Void)?
        ) {
            self.onMarkerTap = onMarkerTap
            self.onDismissFocus = onDismissFocus
            self.onUserInteraction = onUserInteraction
            self.onFocusFlyPhase = onFocusFlyPhase
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isReady = true
            lastMarkersRevision = -1
            lastFlyTrigger = -1
            lastResetTrigger = -1
            lastFocusedMarkerRevision = -1
            replayPendingFlyIfNeeded(in: webView)
        }

        func syncPendingFly(
            trigger: Int,
            latitude: Double?,
            longitude: Double?,
            withZoom: Bool,
            routePath: [EarthGlobeRoutePoint],
            routeMode: String,
            routeDeparture: String,
            routeArrival: String,
            routeDuration: String,
            routeOriginLabel: String,
            routeDestLabel: String
        ) {
            pendingFlyTrigger = trigger
            pendingFlyLatitude = latitude
            pendingFlyLongitude = longitude
            pendingFlyWithZoom = withZoom
            pendingRoutePath = routePath
            pendingRouteMode = routeMode
            pendingRouteDeparture = routeDeparture
            pendingRouteArrival = routeArrival
            pendingRouteDuration = routeDuration
            pendingRouteOriginLabel = routeOriginLabel
            pendingRouteDestLabel = routeDestLabel
        }

        func replayPendingFlyIfNeeded(in webView: WKWebView) {
            applyFlyToIfNeeded(
                trigger: pendingFlyTrigger,
                latitude: pendingFlyLatitude,
                longitude: pendingFlyLongitude,
                withZoom: pendingFlyWithZoom,
                routePath: pendingRoutePath,
                routeMode: pendingRouteMode,
                routeDeparture: pendingRouteDeparture,
                routeArrival: pendingRouteArrival,
                routeDuration: pendingRouteDuration,
                routeOriginLabel: pendingRouteOriginLabel,
                routeDestLabel: pendingRouteDestLabel,
                in: webView
            )
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "markerTap":
                guard let tripId = message.body as? String else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.onMarkerTap?(tripId)
                }
            case "globeDismiss":
                DispatchQueue.main.async { [weak self] in
                    self?.onDismissFocus?()
                }
            case "globeUserInteraction":
                DispatchQueue.main.async { [weak self] in
                    self?.onUserInteraction?()
                }
            case "globeFocusPhase":
                guard let phase = message.body as? String else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.onFocusFlyPhase?(phase)
                }
            default:
                break
            }
        }

        func applyFlyToIfNeeded(
            trigger: Int,
            latitude: Double?,
            longitude: Double?,
            withZoom: Bool,
            routePath: [EarthGlobeRoutePoint],
            routeMode: String,
            routeDeparture: String,
            routeArrival: String,
            routeDuration: String,
            routeOriginLabel: String,
            routeDestLabel: String,
            in webView: WKWebView
        ) {
            syncPendingFly(
                trigger: trigger,
                latitude: latitude,
                longitude: longitude,
                withZoom: withZoom,
                routePath: routePath,
                routeMode: routeMode,
                routeDeparture: routeDeparture,
                routeArrival: routeArrival,
                routeDuration: routeDuration,
                routeOriginLabel: routeOriginLabel,
                routeDestLabel: routeDestLabel
            )
            guard isReady, trigger != lastFlyTrigger,
                  let latitude, let longitude else { return }
            lastFlyTrigger = trigger
            let zoomFlag = withZoom ? "true" : "false"
            let script: String
            if routePath.count >= 2,
               let json = Self.encodeRouteJSON(
                routePath,
                mode: routeMode,
                departure: routeDeparture,
                arrival: routeArrival,
                duration: routeDuration,
                originLabel: routeOriginLabel,
                destLabel: routeDestLabel
               ) {
                script = "window.flyToRoute(\(json),\(zoomFlag));"
            } else {
                script = "window.flyToLatLon(\(latitude),\(longitude),\(zoomFlag));"
            }
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        private static func encodeRouteJSON(
            _ path: [EarthGlobeRoutePoint],
            mode: String,
            departure: String,
            arrival: String,
            duration: String,
            originLabel: String,
            destLabel: String
        ) -> String? {
            guard let data = try? JSONEncoder().encode(
                EarthGlobeRoutePayload(
                    points: path,
                    mode: mode,
                    departure: departure,
                    arrival: arrival,
                    duration: duration,
                    originLabel: originLabel,
                    destLabel: destLabel
                )
            ),
                  let json = String(data: data, encoding: .utf8) else { return nil }
            return json
        }

        func applyResetIfNeeded(trigger: Int, defaultCameraZ: Double, in webView: WKWebView) {
            guard isReady, trigger != lastResetTrigger else { return }
            lastResetTrigger = trigger
            let script = "window.resetGlobeToDefault(\(defaultCameraZ));"
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        func applyFocusedMarkerIfNeeded(
            revision: Int,
            markerId: String?,
            in webView: WKWebView
        ) {
            guard isReady, revision != lastFocusedMarkerRevision else { return }
            lastFocusedMarkerRevision = revision
            let idLiteral: String
            if let markerId, let data = try? JSONEncoder().encode(markerId),
               let encoded = String(data: data, encoding: .utf8) {
                idLiteral = encoded
            } else {
                idLiteral = "null"
            }
            webView.evaluateJavaScript("window.setFocusedMarkerId(\(idLiteral));", completionHandler: nil)
        }

        func applyMarkersIfNeeded(
            revision: Int,
            markers: [EarthGlobeTripMarker],
            in webView: WKWebView
        ) {
            guard isReady, revision != lastMarkersRevision else { return }
            lastMarkersRevision = revision
            guard let json = Self.encodeMarkers(markers) else { return }
            webView.evaluateJavaScript("window.setTripMarkers(\(json));", completionHandler: nil)
        }

        private static func encodeMarkers(_ markers: [EarthGlobeTripMarker]) -> String? {
            guard let data = try? JSONEncoder().encode(markers) else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.userContentController.add(context.coordinator, name: "markerTap")
        config.userContentController.add(context.coordinator, name: "globeDismiss")
        config.userContentController.add(context.coordinator, name: "globeUserInteraction")
        config.userContentController.add(context.coordinator, name: "globeFocusPhase")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        webView.navigationDelegate = context.coordinator
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onMarkerTap = onMarkerTap
        context.coordinator.onDismissFocus = onDismissFocus
        context.coordinator.onUserInteraction = onUserInteraction
        context.coordinator.onFocusFlyPhase = onFocusFlyPhase
        let coordinator = context.coordinator
        coordinator.applyFlyToIfNeeded(
            trigger: flyToTrigger,
            latitude: flyToLatitude,
            longitude: flyToLongitude,
            withZoom: flyWithZoom,
            routePath: routePath,
            routeMode: routeTransportMode,
            routeDeparture: routeDepartureTime,
            routeArrival: routeArrivalTime,
            routeDuration: routeDurationLabel,
            routeOriginLabel: routeOriginLabel,
            routeDestLabel: routeDestLabel,
            in: webView
        )
        coordinator.applyResetIfNeeded(
            trigger: resetGlobeTrigger,
            defaultCameraZ: cameraDistance,
            in: webView
        )
        coordinator.applyFocusedMarkerIfNeeded(
            revision: focusedMarkerRevision,
            markerId: focusedMarkerId,
            in: webView
        )
        coordinator.applyMarkersIfNeeded(
            revision: markersRevision,
            markers: tripMarkers,
            in: webView
        )
    }

    private var htmlContent: String {
        Self.htmlTemplate
            .replacingOccurrences(of: "__CAMERA_FOV__", with: String(fieldOfView))
            .replacingOccurrences(of: "__CAMERA_Z__", with: String(cameraDistance))
            .replacingOccurrences(of: "__CAMERA_Y__", with: String(cameraYOffset))
            .replacingOccurrences(of: "__FOCUS_CAMERA_Y__", with: String(cameraYOffset + 0.14))
            .replacingOccurrences(of: "__MIN_CAM_Z__", with: String(max(1.18, cameraDistance - 2.22)))
            .replacingOccurrences(of: "__MAX_CAM_Z__", with: String(cameraDistance + 2.85))
            .replacingOccurrences(of: "__DESTINATION_ZOOM_Z__", with: String(max(1.18, cameraDistance - 2.22)))
            .replacingOccurrences(of: "__COUNTRY_FR_JSON__", with: EarthGlobeCountryNames.frJSON)
            .replacingOccurrences(of: "__COUNTRY_FLAGS_JSON__", with: EarthGlobeCountryNames.flagsJSON)
    }

    // ─── HTML / JS embarqué ───────────────────────────────────────────────────
    private static let htmlTemplate: String = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
      <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        html, body { width:100%; height:100%; background:transparent; overflow:hidden; }
        canvas { width:100%!important; height:100%!important; display:block; touch-action:none; cursor:grab; }
      </style>
    </head>
    <body>
      <canvas id="c"></canvas>

      <!-- Librairies -->
      <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
      <script src="https://cdn.jsdelivr.net/npm/topojson-client@3/dist/topojson-client.min.js"></script>

      <script>
      (async function(){
        const canvas = document.getElementById('c');
        const renderer = new THREE.WebGLRenderer({canvas, antialias:true, alpha:true, powerPreference:'high-performance'});
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.75));
        renderer.setClearColor(0x000000, 0);
        renderer.toneMapping = THREE.ACESFilmicToneMapping;
        renderer.toneMappingExposure = 1.05;

        const scene  = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(__CAMERA_FOV__, 1, 0.1, 200);
        const minCamZ = __MIN_CAM_Z__;
        const maxCamZ = __MAX_CAM_Z__;
        camera.position.z = __CAMERA_Z__;
        const defaultCamY=__CAMERA_Y__;
        const focusCamY=__FOCUS_CAMERA_Y__;
        camera.position.y=defaultCamY;

        function resize(){
          const w = window.innerWidth, h = window.innerHeight;
          renderer.setSize(w, h);
          camera.aspect = w / h;
          camera.updateProjectionMatrix();
        }
        resize();
        window.addEventListener('resize', resize);

        // Étoiles
        const SN=4000, sp=new Float32Array(SN*3), sc=new Float32Array(SN*3);
        for(let i=0;i<SN;i++){
          const t=Math.random()*Math.PI*2, p=Math.acos(2*Math.random()-1), r=58+Math.random()*28;
          sp[i*3]=r*Math.sin(p)*Math.cos(t); sp[i*3+1]=r*Math.sin(p)*Math.sin(t); sp[i*3+2]=r*Math.cos(p);
          const k=Math.random(); sc[i*3]=0.6+k*0.4; sc[i*3+1]=0.6+k*0.35; sc[i*3+2]=0.78+k*0.22;
        }
        const stg=new THREE.BufferGeometry();
        stg.setAttribute('position',new THREE.BufferAttribute(sp,3));
        stg.setAttribute('color',new THREE.BufferAttribute(sc,3));
        scene.add(new THREE.Points(stg,new THREE.PointsMaterial({size:0.065,vertexColors:true,transparent:true,opacity:0.9})));

        // Lumières
        const sun=new THREE.DirectionalLight(0xfff6ee,1.6); sun.position.set(6,2,4); scene.add(sun);
        scene.add(new THREE.AmbientLight(0x04011a,0.4));
        const rimL=new THREE.PointLight(0x7c3aed,0.65,12); rimL.position.set(-5,-2,-4); scene.add(rimL);

        const pivot=new THREE.Group(); pivot.rotation.z=0.41; scene.add(pivot);

        // Shaders
        const vS=`varying vec2 vUv;varying vec3 vN;
        void main(){vUv=uv;vN=normalize(normalMatrix*normal);gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}`;
        const fS=`uniform sampler2D tDay;uniform sampler2D tSpec;uniform vec3 sunDir;
        varying vec2 vUv;varying vec3 vN;
        void main(){
          vec4 day=texture2D(tDay,vUv); float sm=texture2D(tSpec,vUv).r;
          vec3 L=normalize(sunDir); float NdL=dot(vN,L);
          float light=0.14+max(NdL,0.)*0.86;
          float night=smoothstep(0.04,-0.25,NdL);
          vec3 col=mix(day.rgb*light,day.rgb*0.03+vec3(0.003,0.005,0.018),night*0.93);
          vec3 view=normalize(vec3(0.,0.,1.));
          float spec=pow(max(dot(vN,normalize(L+view)),0.),200.)*sm*0.55;
          col+=vec3(0.75,0.88,1.)*spec;
          float rim=pow(1.-max(dot(vN,view),0.),4.2)*0.38;
          col+=vec3(0.35,0.08,0.82)*rim;
          gl_FragColor=vec4(clamp(col,0.,1.),1.);}`;
        const vA=`varying vec3 vN;void main(){vN=normalize(normalMatrix*normal);gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}`;
        const fA=`varying vec3 vN;void main(){float f=dot(vN,vec3(0.,0.,1.));float i=pow(clamp(0.64-f,0.,1.),2.9)*1.45;vec3 c=mix(vec3(0.14,0.50,1.),vec3(0.52,0.10,1.),pow(clamp(1.-f,0.,1.),1.5));gl_FragColor=vec4(c*i,i);}`;
        const fG=`varying vec3 vN;void main(){float i=pow(clamp(0.52-dot(vN,vec3(0.,0.,1.)),0.,1.),5.5)*0.52;gl_FragColor=vec4(0.18,0.03,0.75,i);}`;

        function addAtmosphere(){
          scene.add(new THREE.Mesh(new THREE.SphereGeometry(1.088,64,64),new THREE.ShaderMaterial({vertexShader:vA,fragmentShader:fA,blending:THREE.AdditiveBlending,side:THREE.BackSide,transparent:true,depthWrite:false})));
          scene.add(new THREE.Mesh(new THREE.SphereGeometry(1.21,32,32),new THREE.ShaderMaterial({vertexShader:vA,fragmentShader:fG,blending:THREE.AdditiveBlending,side:THREE.BackSide,transparent:true,depthWrite:false})));
        }

        function remapBiomes(data){
          for(let i=0;i<data.length;i+=4){
            const r=data[i]/255,g=data[i+1]/255,b=data[i+2]/255;
            const lum=r*0.299+g*0.587+b*0.114;
            const mx=Math.max(r,g,b),mn=Math.min(r,g,b),sat=mx>0?(mx-mn)/mx:0;
            const isO=b>0.30&&b>r*1.15&&b>g*0.84&&lum<0.72;
            const isI=lum>0.76&&sat<0.14;
            const isDes=r>0.48&&g>0.33&&b<0.27&&!isO&&sat>0.09;
            const isJ=g>0.30&&g>r*0.88&&g>b*1.04&&lum<0.44&&!isO&&!isDes;
            const isF=g>0.24&&g>r*0.80&&!isO&&!isDes&&!isJ&&lum<0.54;
            const isS=r>0.20&&g>0.20&&b<0.20&&!isO&&!isDes&&!isF&&!isJ;
            const isM=lum>0.27&&lum<0.60&&sat<0.17&&!isO&&!isI;
            let tr,tg,tb,bl;
            if(isI){tr=0.87;tg=0.91;tb=0.97;bl=0.32;}
            else if(isO){const d=Math.max(0,(b-0.30)/0.70);
              if(d<0.38){tr=0.04+d*0.09;tg=0.16+d*0.24;tb=0.40+d*0.28;}
              else{tr=0.01+d*0.05;tg=0.04+d*0.11;tb=0.14+d*0.30;}
              const s=lum*0.13;tr+=s*0.22;tg+=s*0.52;tb+=s*0.88;bl=0.84;}
            else if(isDes){tr=0.68+lum*0.22;tg=0.46+lum*0.18;tb=0.12+lum*0.10;bl=0.76;}
            else if(isJ){tr=0.03+lum*0.07;tg=0.17+lum*0.24;tb=0.02+lum*0.04;bl=0.78;}
            else if(isF){tr=0.05+lum*0.13;tg=0.22+lum*0.30;tb=0.03+lum*0.05;bl=0.72;}
            else if(isS){tr=0.36+lum*0.30;tg=0.40+lum*0.26;tb=0.06+lum*0.08;bl=0.62;}
            else if(isM){tr=0.27+lum*0.40;tg=0.23+lum*0.32;tb=0.17+lum*0.25;bl=0.65;}
            else{tr=0.29+lum*0.28;tg=0.22+lum*0.22;tb=0.13+lum*0.13;bl=0.58;}
            const lb=0.48+lum*0.88,k=1-bl;
            data[i]=Math.min(255,(tr*lb*bl+r*k)*255);
            data[i+1]=Math.min(255,(tg*lb*bl+g*k)*255);
            data[i+2]=Math.min(255,(tb*lb*bl+b*k)*255);
          }
        }

        function makeSpec(src,W,H){
          const c=document.createElement('canvas');c.width=W;c.height=H;
          const ctx=c.getContext('2d'),id=ctx.createImageData(W,H);
          for(let i=0;i<src.length;i+=4){
            const r=src[i]/255,g=src[i+1]/255,b=src[i+2]/255,lum=r*0.299+g*0.587+b*0.114;
            const v=(b>0.30&&b>r*1.15&&b>g*0.84&&lum<0.72)?Math.floor(100+b*60):2;
            id.data[i]=id.data[i+1]=id.data[i+2]=v;id.data[i+3]=255;
          }
          ctx.putImageData(id,0,0);return c;
        }

        function drawBorders(ctx,world,W,H){
          const borders=topojson.mesh(world,world.objects.countries,(a,b)=>a!==b);
          function proj([lon,lat]){return[(lon+180)/360*W,(90-lat)/180*H];}
          function trace(coords){ctx.beginPath();let lx=null;for(const co of coords){const[x,y]=proj(co);if(lx===null||Math.abs(x-lx)>W*0.40)ctx.moveTo(x,y);else ctx.lineTo(x,y);lx=x;}ctx.stroke();}
          const lines=borders.coordinates;
          ctx.save();ctx.lineCap='round';ctx.lineJoin='round';
          ctx.strokeStyle='rgba(130,60,255,0.06)';ctx.lineWidth=7;ctx.shadowColor='rgba(140,70,255,0.4)';ctx.shadowBlur=12;lines.forEach(trace);
          ctx.strokeStyle='rgba(160,100,255,0.18)';ctx.lineWidth=3.5;ctx.shadowBlur=7;lines.forEach(trace);
          ctx.strokeStyle='rgba(200,160,255,0.55)';ctx.lineWidth=1.0;ctx.shadowColor='rgba(200,170,255,0.9)';ctx.shadowBlur=3;lines.forEach(trace);
          ctx.strokeStyle='rgba(230,210,255,0.45)';ctx.lineWidth=0.4;ctx.shadowBlur=0;lines.forEach(trace);
          ctx.restore();
        }

        function loadImg(src){return new Promise((res,rej)=>{const i=new Image();i.crossOrigin='anonymous';i.onload=()=>res(i);i.onerror=rej;i.src=src;});}

        let cloudMesh=null;

        const [img,world]=await Promise.all([
          loadImg('https://unpkg.com/three-globe@2.31.1/example/img/earth-day.jpg'),
          fetch('https://cdn.jsdelivr.net/npm/world-atlas@2/countries-50m.json').then(r=>r.json())
        ]);

        const TW=2048,TH=1024;
        const off=document.createElement('canvas');off.width=TW;off.height=TH;
        const ctx=off.getContext('2d');
        ctx.drawImage(img,0,0,TW,TH);
        const raw=ctx.getImageData(0,0,TW,TH);
        const orig=new Uint8ClampedArray(raw.data);
        remapBiomes(raw.data);
        ctx.putImageData(raw,0,0);
        const specC=makeSpec(orig,TW,TH);
        drawBorders(ctx,world,TW,TH);

        const earthTex=new THREE.CanvasTexture(off);
        earthTex.anisotropy=renderer.capabilities.getMaxAnisotropy();
        earthTex.minFilter=THREE.LinearMipmapLinearFilter;
        earthTex.generateMipmaps=true;
        const specTex=new THREE.CanvasTexture(specC);
        specTex.anisotropy=renderer.capabilities.getMaxAnisotropy();

        const mat=new THREE.ShaderMaterial({
          uniforms:{tDay:{value:earthTex},tSpec:{value:specTex},sunDir:{value:new THREE.Vector3(6,2,4).normalize()}},
          vertexShader:vS,fragmentShader:fS
        });
        pivot.add(new THREE.Mesh(new THREE.SphereGeometry(1,256,256),mat));
        addAtmosphere();

        const cImg=new Image();cImg.crossOrigin='anonymous';
        cImg.onload=()=>{const cTex=new THREE.Texture(cImg);cTex.needsUpdate=true;cloudMesh=new THREE.Mesh(new THREE.SphereGeometry(1.015,96,96),new THREE.MeshPhongMaterial({map:cTex,transparent:true,opacity:0.26,depthWrite:false,color:0xeeeeff}));pivot.add(cloudMesh);};
        cImg.src='https://unpkg.com/three-globe@2.31.1/example/img/clouds.png';

        const markersGroup=new THREE.Group();
        const routesGroup=new THREE.Group();
        const countryLabelsGroup=new THREE.Group();
        const cityLabelsGroup=new THREE.Group();
        pivot.add(countryLabelsGroup);
        pivot.add(cityLabelsGroup);
        pivot.add(markersGroup);
        pivot.add(routesGroup);
        const routeRadius=1.036;
        let activeRoutePoints=[];
        let routeTrailMesh=null,routeGlowMesh=null,routeHeadSprite=null,routeTimeSprite=null;
        let routeStartDot=null,routeEndDot=null,routeStartLabel=null,routeEndLabel=null;
        let routeDepTime='',routeArrTime='';
        let routeVehicleMode='plane';
        let routeDrawProgress=0;
        const COUNTRY_FR=__COUNTRY_FR_JSON__;
        const COUNTRY_FLAGS=__COUNTRY_FLAGS_JSON__;
        const raycaster=new THREE.Raycaster();
        const pointer=new THREE.Vector2();
        const countryProj=new THREE.Vector3();
        const cityProj=new THREE.Vector3();

        function ringArea(ring){
          let a=0;
          for(let i=0;i<ring.length-1;i++){
            const[x1,y1]=ring[i],[x2,y2]=ring[i+1];
            a+=(x1*y2-x2*y1);
          }
          return Math.abs(a)*0.5;
        }
        function ringCentroid(ring){
          let sx=0,sy=0,a=0;
          for(let i=0;i<ring.length-1;i++){
            const[x1,y1]=ring[i],[x2,y2]=ring[i+1];
            const f=(x1*y2-x2*y1);
            a+=f;sx+=(x1+x2)*f;sy+=(y1+y2)*f;
          }
          if(Math.abs(a)<1e-8)return null;
          a*=0.5;
          return[sx/(6*a),sy/(6*a)];
        }
        function geomLabelPoint(geom){
          let best=null,bestA=0;
          function consider(coords){
            const outer=coords[0];
            const ar=ringArea(outer);
            if(ar>bestA){
              const c=ringCentroid(outer);
              if(c){bestA=ar;best=c;}
            }
          }
          if(geom.type==='Polygon')consider(geom.coordinates);
          else if(geom.type==='MultiPolygon')geom.coordinates.forEach(consider);
          return best;
        }
        function geomArea(geom){
          let total=0;
          function consider(coords){total+=ringArea(coords[0]);}
          if(geom.type==='Polygon')consider(geom.coordinates);
          else if(geom.type==='MultiPolygon')geom.coordinates.forEach(consider);
          return total;
        }
        function countryNameFr(props){
          const en=(props&&props.name)||'';
          return COUNTRY_FR[en]||en;
        }
        function countryFlag(props){
          const en=(props&&props.name)||'';
          return COUNTRY_FLAGS[en]||'🏳️';
        }

        function latLonToVec(lat,lon,r){
          const phi=THREE.MathUtils.degToRad(90-lat);
          const theta=THREE.MathUtils.degToRad(lon+180);
          return new THREE.Vector3(
            -r*Math.sin(phi)*Math.cos(theta),
            r*Math.cos(phi),
            r*Math.sin(phi)*Math.sin(theta)
          );
        }

        function makeCountryLabel(flag,name){
          const raw=(name||'').trim();
          const text=raw.length>14?raw.slice(0,14)+'…':raw;
          const flagStr=flag||'🏳️';
          const font='600 12px -apple-system, BlinkMacSystemFont, sans-serif';
          const flagFont='16px serif';
          const probe=document.createElement('canvas').getContext('2d');
          probe.font=font;
          const tw=Math.ceil(probe.measureText(text||' ').width);
          const flagW=22,gap=4,padR=4;
          const W=flagW+gap+tw+padR;
          const H=20;
          const c=document.createElement('canvas');
          c.width=W;c.height=H;
          const ctx=c.getContext('2d');
          ctx.font=flagFont;
          ctx.textAlign='center';
          ctx.textBaseline='middle';
          ctx.fillText(flagStr,flagW*0.5,H*0.5+1);
          ctx.font=font;
          ctx.textAlign='left';
          const tx=flagW+gap;
          const ty=H*0.5;
          ctx.lineWidth=2;
          ctx.strokeStyle='rgba(0,0,0,0.75)';
          ctx.strokeText(text||' ',tx,ty);
          ctx.fillStyle='rgba(220,210,255,0.94)';
          ctx.fillText(text||' ',tx,ty);
          const tex=new THREE.CanvasTexture(c);
          tex.needsUpdate=true;
          const mat=new THREE.SpriteMaterial({
            map:tex,transparent:true,depthTest:false,depthWrite:false
          });
          const sprite=new THREE.Sprite(mat);
          const sh=0.062;
          sprite.scale.set(sh*(W/H),sh,1);
          sprite.userData.labelAspect=W/H;
          sprite.userData.isCountry=true;
          sprite.userData.baseScale=sh;
          sprite.renderOrder=12;
          return sprite;
        }

        function makeCityLabel(name){
          const raw=(name||'').trim();
          const text=raw.length>18?raw.slice(0,18)+'…':raw;
          const font='600 11px -apple-system, BlinkMacSystemFont, sans-serif';
          const probe=document.createElement('canvas').getContext('2d');
          probe.font=font;
          const tw=Math.ceil(probe.measureText(text||' ').width);
          const W=tw+10;
          const H=18;
          const c=document.createElement('canvas');
          c.width=W;c.height=H;
          const ctx=c.getContext('2d');
          ctx.font=font;
          ctx.textAlign='center';
          ctx.textBaseline='middle';
          ctx.lineWidth=2;
          ctx.strokeStyle='rgba(0,0,0,0.86)';
          ctx.strokeText(text||' ',W*0.5,H*0.5);
          ctx.fillStyle='rgba(245,240,255,0.9)';
          ctx.fillText(text||' ',W*0.5,H*0.5);
          const tex=new THREE.CanvasTexture(c);
          tex.needsUpdate=true;
          const mat=new THREE.SpriteMaterial({
            map:tex,transparent:true,depthTest:false,depthWrite:false
          });
          const sprite=new THREE.Sprite(mat);
          const sh=0.046;
          sprite.scale.set(sh*(W/H),sh,1);
          sprite.userData.labelAspect=W/H;
          sprite.userData.baseScale=sh;
          sprite.renderOrder=13;
          return sprite;
        }

        function drawMapPin(ctx,px,tipY){
          ctx.save();
          ctx.fillStyle='#ef4444';
          ctx.strokeStyle='rgba(0,0,0,0.55)';
          ctx.lineWidth=1.2;
          ctx.beginPath();
          ctx.arc(px,tipY-18,7.5,0,Math.PI*2);
          ctx.fill();
          ctx.stroke();
          ctx.beginPath();
          ctx.moveTo(px,tipY-11);
          ctx.lineTo(px,tipY-2);
          ctx.lineWidth=2.4;
          ctx.strokeStyle='#dc2626';
          ctx.stroke();
          ctx.beginPath();
          ctx.ellipse(px,tipY,4.5,2.2,0,0,Math.PI*2);
          ctx.fillStyle='#b91c1c';
          ctx.fill();
          ctx.restore();
        }

        function makeTitleMarker(name){
          const raw=(name||'').trim();
          const text=raw.length>16?raw.slice(0,16)+'…':raw;
          const font='600 13px -apple-system, BlinkMacSystemFont, sans-serif';
          const probe=document.createElement('canvas').getContext('2d');
          probe.font=font;
          const tw=Math.ceil(probe.measureText(text||' ').width);
          const pinW=30,gap=5,padR=6;
          const W=pinW+gap+tw+padR;
          const H=40;
          const tipY=H-3;
          const pinX=pinW*0.5;
          const c=document.createElement('canvas');
          c.width=W;c.height=H;
          const ctx=c.getContext('2d');
          drawMapPin(ctx,pinX,tipY);
          ctx.font=font;
          ctx.textAlign='left';
          ctx.textBaseline='middle';
          const tx=pinW+gap;
          const ty=tipY-16;
          ctx.lineWidth=2;
          ctx.strokeStyle='rgba(24,10,48,0.78)';
          ctx.strokeText(text||' ',tx,ty);
          ctx.fillStyle='#ddd6fe';
          ctx.fillText(text||' ',tx,ty);
          const tex=new THREE.CanvasTexture(c);
          tex.needsUpdate=true;
          const mat=new THREE.SpriteMaterial({
            map:tex,transparent:true,depthTest:false,depthWrite:false
          });
          const sprite=new THREE.Sprite(mat);
          const sh=0.085;
          sprite.scale.set(sh*(W/H),sh,1);
          sprite.userData.labelAspect=W/H;
          sprite.userData.pinAnchorX=pinX/W;
          sprite.userData.pinAnchorY=1;
          sprite.renderOrder=20;
          return sprite;
        }

        let focusedMarkerId=null;
        const countryLabelsSorted=[];
        let visSerial=0;
        let flyAnimating=false;
        const camDirVec=new THREE.Vector3();
        const worldLabelVec=new THREE.Vector3();

        function smooth01(edge0,edge1,x){
          const t=Math.max(0,Math.min(1,(x-edge0)/(edge1-edge0)));
          return t*t*(3-2*t);
        }

        function markerFacingFactor(lat,lon,camDir){
          const local=latLonToVec(lat,lon,1).normalize();
          worldLabelVec.copy(local).applyQuaternion(pivot.quaternion);
          const dot=worldLabelVec.dot(camDir);
          return smooth01(-0.2,0.05,dot);
        }

        function updateTripMarkers(camDir){
          markersGroup.children.forEach(function(sprite){
            const lat=sprite.userData.lat;
            const lon=sprite.userData.lon;
            if(lat==null||lon==null)return;
            const id=sprite.userData.tripId;
            let a=markerFacingFactor(lat,lon,camDir);
            if(cameraLocked&&focusedMarkerId){
              if(id===focusedMarkerId)a=1;
              else a*=0.18;
            }
            a=Math.max(0,Math.min(1,a));
            const cur=sprite.material.opacity;
            sprite.material.opacity=cur+(a-cur)*0.22;
            sprite.visible=sprite.material.opacity>0.05;
            const sh=0.088*(0.76+0.24*a);
            const ar=sprite.userData.labelAspect||1;
            sprite.scale.set(sh*ar,sh,1);
            const ax=sprite.userData.pinAnchorX;
            const ay=sprite.userData.pinAnchorY;
            sprite.center.set(ax!=null?ax:0.5,ay!=null?ay:0.5);
          });
        }

        function boxesOverlap(a,b,margin){
          const m=margin||0;
          return a.l-m<b.r+m&&a.r+m>b.l-m&&a.b-m<b.t+m&&a.t+m>b.b-m;
        }

        function fadeCountryLabels(){
          for(let i=0;i<countryLabelsSorted.length;i++){
            const sprite=countryLabelsSorted[i];
            const want=(sprite.userData.desired||0)*(sprite.userData.horizonFade||0)*0.9;
            const cur=sprite.userData.fade!=null?sprite.userData.fade:0;
            const next=cur+(want-cur)*0.2;
            sprite.userData.fade=next;
            sprite.material.opacity=next;
            sprite.visible=next>0.03;
          }
        }

        function hideCountryLabelsQuick(){
          for(let i=0;i<countryLabelsSorted.length;i++){
            const sprite=countryLabelsSorted[i];
            const cur=sprite.userData.fade!=null?sprite.userData.fade:0;
            const next=cur*0.72;
            sprite.userData.fade=next;
            sprite.material.opacity=next;
            sprite.visible=next>0.03;
          }
        }

        function layoutCountryLabels(camDir){
          const camZ=camera.position.z;
          const zoomT=Math.max(0,Math.min(1,(defaultCamZ-camZ)/(defaultCamZ-focusZoomZ+0.001)));
          const regional=zoomT>=0.42;
          const maxLabels=regional?countryLabelsSorted.length:Math.floor(44+zoomT*36);
          const minFace=regional?Math.max(0.18,0.38-zoomT*0.18):0.44-zoomT*0.1;
          const viewPad=regional?Math.max(0.6,1.12-zoomT*0.46):1.14;
          const screenBoxes=[];
          for(let i=0;i<countryLabelsSorted.length;i++){
            const sprite=countryLabelsSorted[i];
            const lat=sprite.userData.lat;
            const lon=sprite.userData.lon;
            if(lat==null||lon==null)continue;
            const rank=sprite.userData.rank||999;
            const face=markerFacingFactor(lat,lon,camDir);
            sprite.userData.face=face;
            sprite.userData.horizonFade=smooth01(0.06,0.28,face);
            if(face<0.1){
              sprite.userData.held=false;
              sprite.userData.desired=0;
              continue;
            }
            if(sprite.userData.held&&face>=0.16){
              sprite.userData.desired=1;
              if(sprite.userData.holdBox)screenBoxes.push(sprite.userData.holdBox);
              continue;
            }
            let ok=false;
            if(face>=minFace&&rank<maxLabels){
              countryProj.copy(latLonToVec(lat,lon,1.028)).applyMatrix4(pivot.matrixWorld);
              countryProj.project(camera);
              if(countryProj.z<=1&&countryProj.z>=-1){
                const onScreen=!regional||(
                  Math.abs(countryProj.x)<=viewPad&&Math.abs(countryProj.y)<=viewPad
                );
                if(onScreen){
                  const base=sprite.userData.baseScale||0.062;
                  const ar=sprite.userData.labelAspect||1;
                  const sh=base*(0.68+0.32*face);
                  const halfW=sh*ar*0.46;
                  const halfH=sh*0.46;
                  const box={
                    l:countryProj.x-halfW,r:countryProj.x+halfW,
                    b:countryProj.y-halfH,t:countryProj.y+halfH
                  };
                  let overlap=false;
                  for(let j=0;j<screenBoxes.length;j++){
                    if(boxesOverlap(box,screenBoxes[j],0.03)){overlap=true;break;}
                  }
                  if(!overlap){
                    const holdBox={
                      l:box.l-0.03,r:box.r+0.03,b:box.b-0.03,t:box.t+0.03
                    };
                    screenBoxes.push(holdBox);
                    sprite.userData.holdBox=holdBox;
                    sprite.userData.held=true;
                    ok=true;
                  }
                }
              }
            }
            if(!ok){
              sprite.userData.held=false;
              sprite.userData.holdBox=null;
            }
            sprite.userData.desired=ok?1:0;
          }
        }

        function paintCountryLabels(camDir){
          for(let i=0;i<countryLabelsSorted.length;i++){
            const sprite=countryLabelsSorted[i];
            const lat=sprite.userData.lat;
            const lon=sprite.userData.lon;
            if(lat==null||lon==null)continue;
            const face=markerFacingFactor(lat,lon,camDir);
            sprite.userData.face=face;
            sprite.userData.horizonFade=smooth01(0.06,0.28,face);
            if(face<0.14){
              sprite.userData.held=false;
              sprite.userData.desired=0;
            }
            const want=(sprite.userData.desired||0)*(sprite.userData.horizonFade||0)*0.9;
            const cur=sprite.userData.fade!=null?sprite.userData.fade:0;
            sprite.userData.fade=cur+(want-cur)*0.14;
            sprite.material.opacity=sprite.userData.fade;
            sprite.visible=sprite.material.opacity>0.03;
            if(sprite.visible){
              const base=sprite.userData.baseScale||0.062;
              const ar=sprite.userData.labelAspect||1;
              const sh=base*(0.66+0.34*face);
              sprite.scale.set(sh*ar,sh,1);
              sprite.center.set(0.5,0.5);
            }
          }
        }

        function updateCityLabels(camDir){
          const camZ=camera.position.z;
          const zoomT=Math.max(0,Math.min(1,(defaultCamZ-camZ)/(defaultCamZ-minCamZ+0.001)));
          const cityT=smooth01(0.45,0.78,zoomT);
          const maxCities=Math.floor(10+cityT*70);
          const screenBoxes=[];
          for(let i=0;i<cityLabelsSorted.length;i++){
            const sprite=cityLabelsSorted[i];
            const lat=sprite.userData.lat;
            const lon=sprite.userData.lon;
            const face=markerFacingFactor(lat,lon,camDir);
            let want=0;
            if(cityT>0.02&&face>0.2&&i<maxCities){
              cityProj.copy(latLonToVec(lat,lon,1.041)).applyMatrix4(pivot.matrixWorld);
              cityProj.project(camera);
              if(cityProj.z<=1&&cityProj.z>=-1&&Math.abs(cityProj.x)<=0.96&&Math.abs(cityProj.y)<=0.96){
                const base=sprite.userData.baseScale||0.046;
                const ar=sprite.userData.labelAspect||1;
                const sh=base*(0.74+0.26*cityT);
                const box={
                  l:cityProj.x-sh*ar*0.46,
                  r:cityProj.x+sh*ar*0.46,
                  b:cityProj.y-sh*0.45,
                  t:cityProj.y+sh*0.45
                };
                let overlap=false;
                for(let j=0;j<screenBoxes.length;j++){
                  if(boxesOverlap(box,screenBoxes[j],0.024)){overlap=true;break;}
                }
                if(!overlap){
                  screenBoxes.push(box);
                  want=cityT*smooth01(0.16,0.38,face)*0.86;
                }
              }
            }
            const cur=sprite.userData.fade!=null?sprite.userData.fade:0;
            const next=cur+(want-cur)*0.18;
            sprite.userData.fade=next;
            sprite.material.opacity=next;
            sprite.visible=next>0.03;
            if(sprite.visible){
              const base=sprite.userData.baseScale||0.046;
              const ar=sprite.userData.labelAspect||1;
              const sh=base*(0.74+0.26*cityT);
              sprite.scale.set(sh*ar,sh,1);
              sprite.center.set(0.5,0.5);
            }
          }
        }

        function updateMarkerVisibility(){
          visSerial++;
          pivot.updateMatrixWorld(true);
          camera.updateMatrixWorld(true);
          camDirVec.set(0,camera.position.y,camera.position.z).normalize();

          if(cameraLocked){
            for(let i=0;i<countryLabelsSorted.length;i++){
              const s=countryLabelsSorted[i];
              s.visible=false;
              s.material.opacity=0;
              s.userData.desired=0;
              s.userData.held=false;
              s.userData.fade=0;
            }
          }else if(flyAnimating||resetAnim){
            hideCountryLabelsQuick();
          }else{
            const spinning=Math.abs(vx)>0.0012||drag;
            const camMoved=Math.abs(camera.position.z-lastCountryLayoutCamZ)>0.14;
            if(spinning){
              fadeCountryLabels();
              if(visSerial%12===0)layoutCountryLabels(camDirVec);
            }else{
              if(visSerial%2===0)paintCountryLabels(camDirVec);
              else fadeCountryLabels();
              if(visSerial<4||camMoved||visSerial%10===0){
                lastCountryLayoutCamZ=camera.position.z;
                layoutCountryLabels(camDirVec);
              }
            }
          }

          if(cameraLocked||flyAnimating||resetAnim){
            cityLabelsSorted.forEach(function(s){
              s.visible=false;
              s.material.opacity=0;
              s.userData.fade=0;
            });
          }else{
            updateCityLabels(camDirVec);
          }

          updateTripMarkers(camDirVec);
        }

        const countryEntries=[];
        topojson.feature(world,world.objects.countries).features.forEach(function(f){
          const pt=geomLabelPoint(f.geometry);
          if(!pt)return;
          const area=geomArea(f.geometry);
          if(area<0.01)return;
          countryEntries.push({
            f:f,lon:pt[0],lat:pt[1],area:area,
            label:countryNameFr(f.properties),
            flag:countryFlag(f.properties)
          });
        });
        countryEntries.sort(function(a,b){return b.area-a.area;});
        countryEntries.forEach(function(entry,rank){
          if(!entry.label)return;
          const sprite=makeCountryLabel(entry.flag,entry.label);
          sprite.position.copy(latLonToVec(entry.lat,entry.lon,1.028));
          sprite.userData.lat=entry.lat;
          sprite.userData.lon=entry.lon;
          sprite.userData.rank=rank;
          sprite.userData.area=entry.area;
          countryLabelsGroup.add(sprite);
          countryLabelsSorted.push(sprite);
        });

        const cityLabelEntries=[
          {name:'Paris',lat:48.8566,lon:2.3522,rank:1},{name:'Londres',lat:51.5072,lon:-0.1276,rank:2},
          {name:'New York',lat:40.7128,lon:-74.0060,rank:3},{name:'Tokyo',lat:35.6762,lon:139.6503,rank:4},
          {name:'Dubai',lat:25.2048,lon:55.2708,rank:5},{name:'Singapour',lat:1.3521,lon:103.8198,rank:6},
          {name:'Rome',lat:41.9028,lon:12.4964,rank:7},{name:'Barcelone',lat:41.3874,lon:2.1686,rank:8},
          {name:'Madrid',lat:40.4168,lon:-3.7038,rank:9},{name:'Amsterdam',lat:52.3676,lon:4.9041,rank:10},
          {name:'Berlin',lat:52.5200,lon:13.4050,rank:11},{name:'Istanbul',lat:41.0082,lon:28.9784,rank:12},
          {name:'Marrakech',lat:31.6295,lon:-7.9811,rank:13},{name:'Le Caire',lat:30.0444,lon:31.2357,rank:14},
          {name:'Lisbonne',lat:38.7223,lon:-9.1393,rank:15},{name:'Athènes',lat:37.9838,lon:23.7275,rank:16},
          {name:'Los Angeles',lat:34.0522,lon:-118.2437,rank:17},{name:'San Francisco',lat:37.7749,lon:-122.4194,rank:18},
          {name:'Mexico',lat:19.4326,lon:-99.1332,rank:19},{name:'Rio de Janeiro',lat:-22.9068,lon:-43.1729,rank:20},
          {name:'São Paulo',lat:-23.5558,lon:-46.6396,rank:21},{name:'Buenos Aires',lat:-34.6037,lon:-58.3816,rank:22},
          {name:'Lima',lat:-12.0464,lon:-77.0428,rank:23},{name:'Bogotá',lat:4.7110,lon:-74.0721,rank:24},
          {name:'Montréal',lat:45.5019,lon:-73.5674,rank:25},{name:'Toronto',lat:43.6532,lon:-79.3832,rank:26},
          {name:'Vancouver',lat:49.2827,lon:-123.1207,rank:27},{name:'Sydney',lat:-33.8688,lon:151.2093,rank:28},
          {name:'Melbourne',lat:-37.8136,lon:144.9631,rank:29},{name:'Bangkok',lat:13.7563,lon:100.5018,rank:30},
          {name:'Hong Kong',lat:22.3193,lon:114.1694,rank:31},{name:'Séoul',lat:37.5665,lon:126.9780,rank:32},
          {name:'Shanghai',lat:31.2304,lon:121.4737,rank:33},{name:'Pékin',lat:39.9042,lon:116.4074,rank:34},
          {name:'Mumbai',lat:19.0760,lon:72.8777,rank:35},{name:'Delhi',lat:28.6139,lon:77.2090,rank:36},
          {name:'Hanoï',lat:21.0278,lon:105.8342,rank:37},{name:'Bali',lat:-8.3405,lon:115.0920,rank:38},
          {name:'Jakarta',lat:-6.2088,lon:106.8456,rank:39},{name:'Le Cap',lat:-33.9249,lon:18.4241,rank:40},
          {name:'Nairobi',lat:-1.2921,lon:36.8219,rank:41},{name:'Casablanca',lat:33.5731,lon:-7.5898,rank:42},
          {name:'Stockholm',lat:59.3293,lon:18.0686,rank:43},{name:'Copenhague',lat:55.6761,lon:12.5683,rank:44},
          {name:'Oslo',lat:59.9139,lon:10.7522,rank:45},{name:'Reykjavik',lat:64.1466,lon:-21.9426,rank:46}
        ];
        const cityLabelsSorted=[];
        cityLabelEntries.sort(function(a,b){return a.rank-b.rank;});
        cityLabelEntries.forEach(function(entry){
          const sprite=makeCityLabel(entry.name);
          sprite.position.copy(latLonToVec(entry.lat,entry.lon,1.041));
          sprite.userData.lat=entry.lat;
          sprite.userData.lon=entry.lon;
          sprite.userData.rank=entry.rank;
          sprite.visible=false;
          sprite.material.opacity=0;
          cityLabelsGroup.add(sprite);
          cityLabelsSorted.push(sprite);
        });

        function transportEmoji(mode){
          switch(mode){
            case 'train':return '🚆';
            case 'boat':return '⛴️';
            case 'car':return '🚗';
            default:return '✈️';
          }
        }

        function clearRouteAnimation(){
          while(routesGroup.children.length){
            routesGroup.remove(routesGroup.children[0]);
          }
          activeRoutePoints=[];
          routeTrailMesh=null;
          routeGlowMesh=null;
          routeHeadSprite=null;
          routeTimeSprite=null;
          routeStartDot=null;
          routeEndDot=null;
          routeStartLabel=null;
          routeEndLabel=null;
          routeDepTime='';
          routeArrTime='';
          routeDrawProgress=0;
        }

        function parseRouteMinutes(raw){
          const m=(raw||'').match(/(\\d{1,2})[:h](\\d{2})?/i);
          if(!m)return null;
          return parseInt(m[1],10)*60+(parseInt(m[2],10)||0);
        }

        function routeTimeAtProgress(dep,arr,p){
          const d=parseRouteMinutes(dep);
          const a=parseRouteMinutes(arr);
          if(d==null||a==null)return '';
          let am=a;
          if(am<d)am+=24*60;
          const cur=d+Math.round((am-d)*Math.max(0,Math.min(1,p)));
          const h=Math.floor(cur/60)%24;
          const mn=cur%60;
          return (h<10?'0':'')+h+':'+(mn<10?'0':'')+mn;
        }

        function makeRouteTimeSprite(text){
          const label=(text||'').trim()||'--:--';
          const font='700 12px -apple-system, BlinkMacSystemFont, sans-serif';
          const probe=document.createElement('canvas').getContext('2d');
          probe.font=font;
          const tw=Math.max(36,Math.ceil(probe.measureText(label).width)+10);
          const c=document.createElement('canvas');
          c.width=tw;c.height=18;
          const ctx=c.getContext('2d');
          ctx.font=font;
          ctx.textAlign='center';
          ctx.textBaseline='middle';
          ctx.fillStyle='rgba(8,4,20,0.72)';
          const pad=4;
          const w=tw-pad*2,h=14;
          const x=pad,y=2;
          const r=5;
          ctx.beginPath();
          ctx.moveTo(x+r,y);
          ctx.lineTo(x+w-r,y);
          ctx.quadraticCurveTo(x+w,y,x+w,y+r);
          ctx.lineTo(x+w,y+h-r);
          ctx.quadraticCurveTo(x+w,y+h,x+w-r,y+h);
          ctx.lineTo(x+r,y+h);
          ctx.quadraticCurveTo(x,y+h,x,y+h-r);
          ctx.lineTo(x,y+r);
          ctx.quadraticCurveTo(x,y,x+r,y);
          ctx.fill();
          ctx.fillStyle='#ede9fe';
          ctx.fillText(label,tw*0.5,10);
          const tex=new THREE.CanvasTexture(c);
          tex.needsUpdate=true;
          const mat=new THREE.SpriteMaterial({
            map:tex,transparent:true,depthTest:false,depthWrite:false
          });
          const sprite=new THREE.Sprite(mat);
          sprite.scale.set(0.075,0.038,1);
          sprite.renderOrder=31;
          return sprite;
        }

        function updateRouteTimeSprite(sprite,text){
          if(!sprite)return;
          const label=(text||'').trim()||'--:--';
          const font='700 12px -apple-system, BlinkMacSystemFont, sans-serif';
          const probe=document.createElement('canvas').getContext('2d');
          probe.font=font;
          const tw=Math.max(36,Math.ceil(probe.measureText(label).width)+10);
          const c=document.createElement('canvas');
          c.width=tw;c.height=18;
          const ctx=c.getContext('2d');
          ctx.font=font;
          ctx.textAlign='center';
          ctx.textBaseline='middle';
          ctx.fillStyle='rgba(8,4,20,0.72)';
          const pad=4;
          const w=tw-pad*2,h=14;
          const x=pad,y=2;
          const r=5;
          ctx.beginPath();
          ctx.moveTo(x+r,y);
          ctx.lineTo(x+w-r,y);
          ctx.quadraticCurveTo(x+w,y,x+w,y+r);
          ctx.lineTo(x+w,y+h-r);
          ctx.quadraticCurveTo(x+w,y+h,x+w-r,y+h);
          ctx.lineTo(x+r,y+h);
          ctx.quadraticCurveTo(x,y+h,x,y+h-r);
          ctx.lineTo(x,y+r);
          ctx.quadraticCurveTo(x,y,x+r,y);
          ctx.fill();
          ctx.fillStyle='#ede9fe';
          ctx.fillText(label,tw*0.5,10);
          sprite.material.map.image=c;
          sprite.material.map.needsUpdate=true;
          const sh=0.075;
          sprite.scale.set(sh*(tw/18),sh,1);
        }

        function routeCoordAt(points,t){
          if(!points||points.length<2)return null;
          const p=Math.max(0,Math.min(1,t))*(points.length-1);
          const i=Math.floor(p);
          const f=p-i;
          const a=points[i];
          const b=points[Math.min(i+1,points.length-1)];
          return{
            lat:a.lat+(b.lat-a.lat)*f,
            lon:a.lon+(b.lon-a.lon)*f
          };
        }

        function routeAngularSpan(points){
          if(!points||points.length<2)return 0.35;
          const a=latLonToVec(points[0].lat,points[0].lon,1);
          const b=latLonToVec(points[points.length-1].lat,points[points.length-1].lon,1);
          return a.angleTo(b);
        }

        function routeFocusPoint(points){
          if(!points||!points.length)return null;
          return points[Math.floor(points.length*0.5)];
        }

        function routePositionsSlice(points,count){
          const n=Math.max(2,Math.min(points.length,count));
          const arr=new Float32Array(n*3);
          for(let i=0;i<n;i++){
            const v=latLonToVec(points[i].lat,points[i].lon,routeRadius);
            arr[i*3]=v.x;arr[i*3+1]=v.y;arr[i*3+2]=v.z;
          }
          return arr;
        }

        function makeRouteHeadSprite(mode){
          const emoji=transportEmoji(mode);
          const c=document.createElement('canvas');
          c.width=64;c.height=64;
          const ctx=c.getContext('2d');
          const g=ctx.createRadialGradient(32,34,4,32,34,28);
          g.addColorStop(0,'rgba(167,139,250,0.55)');
          g.addColorStop(1,'rgba(167,139,250,0)');
          ctx.fillStyle=g;
          ctx.fillRect(0,0,64,64);
          ctx.font='36px serif';
          ctx.textAlign='center';
          ctx.textBaseline='middle';
          ctx.fillText(emoji,32,34);
          const tex=new THREE.CanvasTexture(c);
          tex.needsUpdate=true;
          const mat=new THREE.SpriteMaterial({
            map:tex,transparent:true,depthTest:false,depthWrite:false
          });
          const sprite=new THREE.Sprite(mat);
          sprite.scale.set(0.17,0.17,1);
          sprite.userData.baseScale=0.17;
          sprite.renderOrder=30;
          return sprite;
        }

        function makeRoutePlaceLabel(text,kind){
          const raw=(text||'').trim();
          const label=raw.length>18?raw.slice(0,17)+'…':raw;
          const font='700 11px -apple-system, BlinkMacSystemFont, sans-serif';
          const probe=document.createElement('canvas').getContext('2d');
          probe.font=font;
          const tw=Math.max(48,Math.ceil(probe.measureText(label).width)+14);
          const c=document.createElement('canvas');
          c.width=tw;c.height=22;
          const ctx=c.getContext('2d');
          ctx.font=font;
          const bg=kind==='start'?'rgba(16,120,90,0.88)':'rgba(190,70,140,0.88)';
          ctx.fillStyle=bg;
          const r=6;
          const w=tw-4,h=16,x=2,y=3;
          ctx.beginPath();
          ctx.moveTo(x+r,y);
          ctx.lineTo(x+w-r,y);
          ctx.quadraticCurveTo(x+w,y,x+w,y+r);
          ctx.lineTo(x+w,y+h-r);
          ctx.quadraticCurveTo(x+w,y+h,x+w-r,y+h);
          ctx.lineTo(x+r,y+h);
          ctx.quadraticCurveTo(x,y+h,x,y+h-r);
          ctx.lineTo(x,y+r);
          ctx.quadraticCurveTo(x,y,x+r,y);
          ctx.fill();
          ctx.fillStyle='#f5f3ff';
          ctx.textAlign='center';
          ctx.textBaseline='middle';
          ctx.fillText(label,tw*0.5,12);
          const tex=new THREE.CanvasTexture(c);
          tex.needsUpdate=true;
          const mat=new THREE.SpriteMaterial({
            map:tex,transparent:true,depthTest:false,depthWrite:false
          });
          const sprite=new THREE.Sprite(mat);
          const sh=0.052;
          sprite.scale.set(sh*(tw/22),sh,1);
          sprite.userData.labelAspect=tw/22;
          sprite.renderOrder=28;
          return sprite;
        }

        function makeRouteDot(color){
          const mesh=new THREE.Mesh(
            new THREE.SphereGeometry(0.014,12,12),
            new THREE.MeshBasicMaterial({color:color,transparent:true,opacity:0.95,depthTest:true})
          );
          mesh.renderOrder=22;
          return mesh;
        }

        function buildRouteScene(points,mode,dep,arr,originLabel,destLabel){
          clearRouteAnimation();
          activeRoutePoints=points;
          routeVehicleMode=mode||'plane';
          routeDepTime=dep||'';
          routeArrTime=arr||'';
          const full=routePositionsSlice(points,points.length);
          const trailGeo=new THREE.BufferGeometry();
          trailGeo.setAttribute('position',new THREE.BufferAttribute(full,3));
          routeTrailMesh=new THREE.Line(
            trailGeo,
            new THREE.LineBasicMaterial({color:0x7c3aed,transparent:true,opacity:0.2})
          );
          routeTrailMesh.renderOrder=18;
          routesGroup.add(routeTrailMesh);

          const glowGeo=new THREE.BufferGeometry();
          glowGeo.setAttribute('position',new THREE.BufferAttribute(new Float32Array(6),3));
          routeGlowMesh=new THREE.Line(
            glowGeo,
            new THREE.LineBasicMaterial({color:0xc4b5fd,transparent:true,opacity:0.95})
          );
          routeGlowMesh.renderOrder=24;
          routesGroup.add(routeGlowMesh);

          routeStartDot=makeRouteDot(0x34d399);
          routeStartDot.position.copy(latLonToVec(points[0].lat,points[0].lon,routeRadius));
          routesGroup.add(routeStartDot);

          routeEndDot=makeRouteDot(0xf472b6);
          routeEndDot.position.copy(latLonToVec(points[points.length-1].lat,points[points.length-1].lon,routeRadius));
          routeEndDot.material.opacity=0.15;
          routesGroup.add(routeEndDot);

          routeStartLabel=makeRoutePlaceLabel(originLabel||'Départ','start');
          routeStartLabel.position.copy(latLonToVec(points[0].lat,points[0].lon,routeRadius+0.028));
          routeStartLabel.material.opacity=0;
          routesGroup.add(routeStartLabel);

          routeEndLabel=makeRoutePlaceLabel(destLabel||'Arrivée','end');
          routeEndLabel.position.copy(latLonToVec(points[points.length-1].lat,points[points.length-1].lon,routeRadius+0.028));
          routeEndLabel.material.opacity=0;
          routesGroup.add(routeEndLabel);

          routeHeadSprite=makeRouteHeadSprite(mode);
          routeHeadSprite.position.copy(latLonToVec(points[0].lat,points[0].lon,routeRadius+0.01));
          routeHeadSprite.material.opacity=0;
          routesGroup.add(routeHeadSprite);
          routeTimeSprite=makeRouteTimeSprite(routeDepTime);
          routeTimeSprite.position.copy(routeHeadSprite.position);
          routeTimeSprite.material.opacity=0;
          routesGroup.add(routeTimeSprite);
          setRouteDrawProgress(0);
        }

        function setRouteDrawProgress(progress){
          if(!activeRoutePoints.length||!routeGlowMesh)return;
          const p=Math.max(0,Math.min(1,progress));
          routeDrawProgress=p;
          const count=Math.max(2,Math.ceil(activeRoutePoints.length*p));
          const slice=routePositionsSlice(activeRoutePoints,count);
          routeGlowMesh.geometry.setAttribute(
            'position',
            new THREE.BufferAttribute(slice,3)
          );
          routeGlowMesh.geometry.attributes.position.needsUpdate=true;
          routeGlowMesh.geometry.setDrawRange(0,count);
          const head=routeCoordAt(activeRoutePoints,p);
          if(head&&routeHeadSprite){
            routeHeadSprite.position.copy(latLonToVec(head.lat,head.lon,routeRadius+0.016));
            routeHeadSprite.material.opacity=0.7+0.3*p;
            const base=routeHeadSprite.userData.baseScale||0.17;
            const pulse=1+0.1*Math.sin(performance.now()*0.009);
            routeHeadSprite.scale.set(base*pulse,base*pulse,1);
          }
          if(routeEndLabel){
            routeEndLabel.material.opacity=Math.min(1,Math.max(0,(p-0.7)/0.3));
          }
          if(routeStartLabel){
            routeStartLabel.material.opacity=Math.min(1,Math.max(0,1-p*1.4));
          }
          if(routeTimeSprite&&routeHeadSprite&&p>0.04){
            const label=routeTimeAtProgress(routeDepTime,routeArrTime,p);
            if(label)updateRouteTimeSprite(routeTimeSprite,label);
            routeTimeSprite.position.copy(routeHeadSprite.position);
            routeTimeSprite.material.opacity=routeHeadSprite.material.opacity;
          }else if(routeTimeSprite){
            routeTimeSprite.material.opacity=0;
          }
          if(routeEndDot){
            routeEndDot.material.opacity=0.12+0.88*Math.max(0,(p-0.82)/0.18);
          }
        }

        window.setFocusedMarkerId=function(id){
          focusedMarkerId=id||null;
          updateMarkerVisibility();
        };

        window.setTripMarkers=function(list){
          while(markersGroup.children.length){
            markersGroup.remove(markersGroup.children[0]);
          }
          if(!list||!list.length)return;
          list.forEach(function(m){
            const sprite=makeTitleMarker(m.title);
            sprite.position.copy(latLonToVec(m.lat,m.lon,1.05));
            sprite.userData.tripId=m.id;
            sprite.userData.lat=m.lat;
            sprite.userData.lon=m.lon;
            sprite.center.set(sprite.userData.pinAnchorX,sprite.userData.pinAnchorY);
            sprite.material.opacity=0.9;
            sprite.visible=true;
            markersGroup.add(sprite);
          });
          updateMarkerVisibility();
        };

        function pickMarker(clientX,clientY){
          const rect=canvas.getBoundingClientRect();
          pointer.x=((clientX-rect.left)/rect.width)*2-1;
          pointer.y=-((clientY-rect.top)/rect.height)*2+1;
          raycaster.setFromCamera(pointer,camera);
          const visible=markersGroup.children.filter(function(s){return s.visible&&s.material.opacity>0.2;});
          const hits=raycaster.intersectObjects(visible,false);
          if(!hits.length)return;
          const id=hits[0].object.userData.tripId;
          if(id&&window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.markerTap){
            window.webkit.messageHandlers.markerTap.postMessage(id);
          }
        }

        function touchDist(touches){
          const dx=touches[0].clientX-touches[1].clientX;
          const dy=touches[0].clientY-touches[1].clientY;
          return Math.hypot(dx,dy);
        }
        function clampCamZ(z){return Math.max(minCamZ,Math.min(maxCamZ,z));}
        function notifyUserInteraction(){
          if(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.globeUserInteraction){
            window.webkit.messageHandlers.globeUserInteraction.postMessage('');
          }
        }

        let drag=false,pinch=false,tapMoved=false,lockedTapMoved=false,px=0,py=0,vx=0,vy=0,pinchStartDist=0,pinchStartZ=camera.position.z;

        const focusZoomZ=__DESTINATION_ZOOM_Z__;
        const defaultCamZ=__CAMERA_Z__;
        let lastCountryLayoutCamZ=defaultCamZ;
        const globeTiltZ=0.41;
        let cameraLocked=false,lockedY=0,lockedX=0,lockedRotZ=globeTiltZ,lockedCamZ=camera.position.z,lockedCamY=defaultCamY;
        let resetAnim=false;
        let flyRafId=null;

        function lerpAngle(a,b,t){
          let d=b-a;
          while(d>Math.PI)d-=Math.PI*2;
          while(d<-Math.PI)d+=Math.PI*2;
          return a+d*t;
        }
        function easeSmooth(u){
          return u*u*(3-2*u);
        }
        function notifyFocusPhase(phase){
          if(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.globeFocusPhase){
            window.webkit.messageHandlers.globeFocusPhase.postMessage(phase);
          }
        }

        const rotCache={};
        function rotationForLatLon(lat,lon,camY,camZ){
          const key=lat.toFixed(2)+','+lon.toFixed(2)+','+camY.toFixed(2)+','+camZ.toFixed(2);
          if(rotCache[key])return rotCache[key];
          const z=globeTiltZ;
          let y=-THREE.MathUtils.degToRad(lon)-Math.PI*0.5;
          let x=THREE.MathUtils.degToRad(lat)*0.92;
          const savedY=camera.position.y;
          const savedZ=camera.position.z;
          camera.position.y=typeof camY==='number'?camY:savedY;
          camera.position.z=typeof camZ==='number'?camZ:savedZ;
          camera.updateMatrixWorld();
          for(let i=0;i<6;i++){
            pivot.rotation.set(x,y,z);
            pivot.updateMatrixWorld(true);
            const ndc=latLonToVec(lat,lon,1.05).applyMatrix4(pivot.matrixWorld).project(camera);
            y-=ndc.x*0.44;
            x+=ndc.y*0.34;
            x=Math.max(-1.2,Math.min(1.2,x));
          }
          camera.position.y=savedY;
          camera.position.z=savedZ;
          const out={y:y,x:x,z:z};
          rotCache[key]=out;
          return out;
        }

        canvas.addEventListener('touchstart',e=>{
          if(cameraLocked){
            cameraLocked=false;
            lockedTapMoved=false;
          }
          notifyUserInteraction();
          lockedTapMoved=false;
          tapMoved=false;
          if(e.touches.length===2){
            drag=false;pinch=true;
            pinchStartDist=touchDist(e.touches);
            pinchStartZ=camera.position.z;
            e.preventDefault();
            return;
          }
          if(e.touches.length===1){
            pinch=false;drag=true;
            px=e.touches[0].clientX;py=e.touches[0].clientY;vx=vy=0;
          }
        },{passive:false});

        canvas.addEventListener('touchmove',e=>{
          if(cameraLocked){
            if(e.touches.length===1){
              const dx=e.touches[0].clientX-px,dy=e.touches[0].clientY-py;
              if(Math.abs(dx)+Math.abs(dy)>8)lockedTapMoved=true;
            }
            return;
          }
          if(e.touches.length===2&&pinch){
            const d=touchDist(e.touches);
            if(pinchStartDist>0){
              const scale=Math.pow(d/pinchStartDist,1.18);
              camera.position.z=clampCamZ(pinchStartZ/scale);
            }
            e.preventDefault();
            return;
          }
          if(!drag||e.touches.length!==1)return;
          const dx=(e.touches[0].clientX-px)*0.0055,dy=(e.touches[0].clientY-py)*0.0055;
          if(Math.abs(dx)+Math.abs(dy)>0.02)tapMoved=true;
          vx=dx;vy=dy;pivot.rotation.y+=dx;
          pivot.rotation.x=Math.max(-1.2,Math.min(1.2,pivot.rotation.x+dy));
          px=e.touches[0].clientX;py=e.touches[0].clientY;
        },{passive:false});

        canvas.addEventListener('touchend',e=>{
          if(e.touches.length<2)pinch=false;
          if(e.touches.length===0){
            if(cameraLocked&&!lockedTapMoved&&!resetAnim&&e.changedTouches&&e.changedTouches[0]){
              if(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.globeDismiss){
                window.webkit.messageHandlers.globeDismiss.postMessage('');
              }
            } else if(drag&&!pinch&&!tapMoved&&e.changedTouches&&e.changedTouches[0]){
              pickMarker(e.changedTouches[0].clientX,e.changedTouches[0].clientY);
            }
            drag=false;
          }
        });

        canvas.addEventListener('wheel',e=>{
          if(cameraLocked)return;
          notifyUserInteraction();
          e.preventDefault();
          camera.position.z=clampCamZ(camera.position.z+e.deltaY*0.006);
        },{passive:false});

        let gestureStartZ=camera.position.z;
        canvas.addEventListener('gesturestart',e=>{
          if(cameraLocked)return;
          notifyUserInteraction();
          e.preventDefault();
          gestureStartZ=camera.position.z;
        },{passive:false});
        canvas.addEventListener('gesturechange',e=>{
          if(cameraLocked)return;
          e.preventDefault();
          camera.position.z=clampCamZ(gestureStartZ/Math.pow(e.scale,1.18));
        },{passive:false});
        canvas.addEventListener('gestureend',e=>{e.preventDefault();},{passive:false});

        window.resetGlobeToDefault=function(endZ){
          if(flyRafId!=null){cancelAnimationFrame(flyRafId);flyRafId=null;}
          clearRouteAnimation();
          cameraLocked=false;
          resetAnim=true;
          vx=0.0018;vy=0;
          const startCamZ=camera.position.z;
          const startCamY=camera.position.y;
          const targetCamZ=typeof endZ==='number'?endZ:defaultCamZ;
          const startRotZ=pivot.rotation.z;
          const t0=performance.now();
          const dur=920;
          function step(now){
            const u=Math.min(1,(now-t0)/dur);
            const ease=u*u*(3-2*u);
            camera.position.z=startCamZ+(targetCamZ-startCamZ)*ease;
            camera.position.y=startCamY+(defaultCamY-startCamY)*ease;
            pivot.rotation.z=startRotZ+(globeTiltZ-startRotZ)*ease;
            if(u<1){
              requestAnimationFrame(step);
              return;
            }
            camera.position.z=targetCamZ;
            camera.position.y=defaultCamY;
            pivot.rotation.z=globeTiltZ;
            resetAnim=false;
          }
          requestAnimationFrame(step);
        };

        window.flyToRoute=function(payload,withZoom){
          if(flyRafId!=null){cancelAnimationFrame(flyRafId);flyRafId=null;}
          clearRouteAnimation();
          resetAnim=false;
          cameraLocked=false;
          vx=vy=0;drag=false;pinch=false;tapMoved=false;
          const zoom=withZoom===true||withZoom==='true';
          const points=(payload&&payload.points)||[];
          const mode=(payload&&payload.mode)||'plane';
          const dep=(payload&&payload.departure)||'';
          const arr=(payload&&payload.arrival)||'';
          const originLabel=(payload&&payload.originLabel)||'';
          const destLabel=(payload&&payload.destLabel)||'';
          if(points.length<2){
            const mid=points[0];
            if(mid)window.flyToLatLon(mid.lat,mid.lon,withZoom);
            return;
          }
          buildRouteScene(points,mode,dep,arr,originLabel,destLabel);
          const focus=routeFocusPoint(points)||points[0];
          const span=routeAngularSpan(points);
          const runFly=function(){
          if(!zoom){
            const target=rotationForLatLon(focus.lat,focus.lon,camera.position.y,camera.position.z);
            const t0=performance.now();
            const dur=1100;
            const sY=pivot.rotation.y,sX=pivot.rotation.x,sZ=pivot.rotation.z;
            function stepLite(now){
              const u=Math.min(1,(now-t0)/dur);
              const e=easeSmooth(u);
              pivot.rotation.y=lerpAngle(sY,target.y,e);
              pivot.rotation.x=sX+(target.x-sX)*e;
              pivot.rotation.z=sZ+(target.z-sZ)*e;
              setRouteDrawProgress(e);
              updateMarkerVisibility();
              if(u<1){flyRafId=requestAnimationFrame(stepLite);return;}
              flyRafId=null;
              setRouteDrawProgress(1);
            }
            flyRafId=requestAnimationFrame(stepLite);
            return;
          }

          const sCamZ=camera.position.z;
          const sCamY=camera.position.y;
          const sY=pivot.rotation.y;
          const sX=pivot.rotation.x;
          const sZ=pivot.rotation.z;
          const pullZ=Math.max(defaultCamZ,sCamZ+0.38);
          const pullY=defaultCamY;
          const routeCamZ=THREE.MathUtils.clamp(defaultCamZ-0.42-span*0.95,focusZoomZ+0.22,defaultCamZ-0.06);
          const endCamZ=routeCamZ;
          const endCamY=focusCamY;
          const target=rotationForLatLon(focus.lat,focus.lon,endCamY,endCamZ);
          const endY=target.y;
          const endX=target.x;
          const endRotZ=target.z;
          const midY=lerpAngle(sY,endY,0.26);
          const midX=sX+(endX-sX)*0.26;
          const durPull=520;
          const durFly=2400;
          const totalDur=durPull+durFly;
          const t0=performance.now();
          let flyUiNotified=false;
          flyAnimating=true;

          function startRouteJourneyAnimation(duration){
            setRouteDrawProgress(0);
            if(routeHeadSprite)routeHeadSprite.material.opacity=0;
            if(routeStartLabel)routeStartLabel.material.opacity=0;
            if(routeEndLabel)routeEndLabel.material.opacity=0;
            notifyFocusPhase('zoomed');
            notifyFocusPhase('present');
            const t0=performance.now();
            const dur=typeof duration==='number'?duration:2800;
            function journeyStep(now){
              const u=Math.min(1,(now-t0)/dur);
              const e=easeSmooth(u);
              setRouteDrawProgress(e);
              if(u<1){flyRafId=requestAnimationFrame(journeyStep);return;}
              flyRafId=null;
              setRouteDrawProgress(1);
              notifyFocusPhase('complete');
            }
            flyRafId=requestAnimationFrame(journeyStep);
          }

          function step(now){
            const elapsed=now-t0;
            setRouteDrawProgress(0);
            if(elapsed<durPull){
              const u=elapsed/durPull;
              const e=easeSmooth(u);
              camera.position.z=sCamZ+(pullZ-sCamZ)*e;
              camera.position.y=sCamY+(pullY-sCamY)*e;
              pivot.rotation.y=lerpAngle(sY,midY,e);
              pivot.rotation.x=sX+(midX-sX)*e;
              pivot.rotation.z=sZ+(endRotZ-sZ)*e*0.35;
            }else{
              const u=Math.min(1,(elapsed-durPull)/durFly);
              const e=easeSmooth(u);
              camera.position.z=pullZ+(endCamZ-pullZ)*e;
              camera.position.y=pullY+(endCamY-pullY)*e;
              pivot.rotation.y=lerpAngle(midY,endY,e);
              pivot.rotation.x=midX+(endX-midX)*e;
              pivot.rotation.z=sZ+(endRotZ-sZ)*(0.35+0.65*e);
            }
            if(elapsed<totalDur){
              flyRafId=requestAnimationFrame(step);
              return;
            }
            flyRafId=null;
            flyAnimating=false;
            camera.position.z=endCamZ;
            camera.position.y=endCamY;
            pivot.rotation.y=endY;
            pivot.rotation.x=endX;
            pivot.rotation.z=endRotZ;
            cameraLocked=true;
            lockedY=endY;
            lockedX=endX;
            lockedRotZ=endRotZ;
            lockedCamZ=endCamZ;
            lockedCamY=endCamY;
            vx=vy=0;
            startRouteJourneyAnimation(2800);
          }
          flyRafId=requestAnimationFrame(step);
          };
          requestAnimationFrame(function(){
            requestAnimationFrame(runFly);
          });
        };

        window.flyToLatLon=function(lat,lon,withZoom){
          if(flyRafId!=null){cancelAnimationFrame(flyRafId);flyRafId=null;}
          clearRouteAnimation();
          resetAnim=false;
          cameraLocked=false;
          vx=vy=0;drag=false;pinch=false;tapMoved=false;
          const zoom=withZoom===true||withZoom==='true';
          const runFly=function(){
          if(!zoom){
            const target=rotationForLatLon(lat,lon,camera.position.y,camera.position.z);
            const t0=performance.now();
            const dur=980;
            const sY=pivot.rotation.y,sX=pivot.rotation.x,sZ=pivot.rotation.z;
            function stepLite(now){
              const u=Math.min(1,(now-t0)/dur);
              const e=easeSmooth(u);
              pivot.rotation.y=lerpAngle(sY,target.y,e);
              pivot.rotation.x=sX+(target.x-sX)*e;
              pivot.rotation.z=sZ+(target.z-sZ)*e;
              updateMarkerVisibility();
              if(u<1){flyRafId=requestAnimationFrame(stepLite);return;}
              flyRafId=null;
            }
            flyRafId=requestAnimationFrame(stepLite);
            return;
          }

          const sCamZ=camera.position.z;
          const sCamY=camera.position.y;
          const sY=pivot.rotation.y;
          const sX=pivot.rotation.x;
          const sZ=pivot.rotation.z;
          const pullZ=Math.max(defaultCamZ,sCamZ+0.42);
          const pullY=defaultCamY;
          const endCamZ=focusZoomZ;
          const endCamY=focusCamY;
          const target=rotationForLatLon(lat,lon,endCamY,endCamZ);
          const endY=target.y;
          const endX=target.x;
          const endRotZ=target.z;
          const midY=lerpAngle(sY,endY,0.28);
          const midX=sX+(endX-sX)*0.28;
          const durPull=580;
          const durFly=2100;
          const t0=performance.now();
          let flyUiNotified=false;
          flyAnimating=true;

          function step(now){
            const elapsed=now-t0;
            if(elapsed<durPull){
              const u=elapsed/durPull;
              const e=easeSmooth(u);
              camera.position.z=sCamZ+(pullZ-sCamZ)*e;
              camera.position.y=sCamY+(pullY-sCamY)*e;
              pivot.rotation.y=lerpAngle(sY,midY,e);
              pivot.rotation.x=sX+(midX-sX)*e;
              pivot.rotation.z=sZ+(endRotZ-sZ)*e*0.35;
            }else{
              const u=Math.min(1,(elapsed-durPull)/durFly);
              const e=easeSmooth(u);
              if(u>=0.52&&!flyUiNotified){
                flyUiNotified=true;
                notifyFocusPhase('present');
              }
              camera.position.z=pullZ+(endCamZ-pullZ)*e;
              camera.position.y=pullY+(endCamY-pullY)*e;
              pivot.rotation.y=lerpAngle(midY,endY,e);
              pivot.rotation.x=midX+(endX-midX)*e;
              pivot.rotation.z=sZ+(endRotZ-sZ)*(0.35+0.65*e);
            }
            if(elapsed<durPull+durFly){
              flyRafId=requestAnimationFrame(step);
              return;
            }
            flyRafId=null;
            flyAnimating=false;
            camera.position.z=endCamZ;
            camera.position.y=endCamY;
            pivot.rotation.y=endY;
            pivot.rotation.x=endX;
            pivot.rotation.z=endRotZ;
            cameraLocked=true;
            lockedY=endY;
            lockedX=endX;
            lockedRotZ=endRotZ;
            lockedCamZ=endCamZ;
            lockedCamY=endCamY;
            notifyFocusPhase('complete');
            vx=vy=0;
          }
          flyRafId=requestAnimationFrame(step);
          };
          requestAnimationFrame(function(){
            requestAnimationFrame(runFly);
          });
        };

        renderer.setAnimationLoop(function(){
          if(cameraLocked&&!resetAnim&&!flyAnimating){
            pivot.rotation.y=lockedY;
            pivot.rotation.x=lockedX;
            pivot.rotation.z=lockedRotZ;
            camera.position.z=lockedCamZ;
            camera.position.y=lockedCamY;
            vx=vy=0;
          }else if(!drag&&!resetAnim&&!flyAnimating){
            vx*=0.95;vy*=0.95;
            pivot.rotation.y+=vx+0.00062;
            pivot.rotation.x=Math.max(-1.2,Math.min(1.2,pivot.rotation.x+vy));
          }
          if(cloudMesh)cloudMesh.rotation.y+=0.000078;
          if(routeHeadSprite&&routeDrawProgress>0){
            const base=routeHeadSprite.userData.baseScale||0.17;
            const pulse=1+0.1*Math.sin(performance.now()*0.009);
            routeHeadSprite.scale.set(base*pulse,base*pulse,1);
          }
          updateMarkerVisibility();
          renderer.render(scene,camera);
        });
      })();
      </script>
    </body>
    </html>
    """
}

// MARK: - Position actuelle

enum EarthGlobeLocationFetcher {
    @MainActor
    static func currentCoordinate() async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            let helper = OneShotLocationFetcher(continuation: continuation)
            helper.start()
        }
    }
}

@MainActor
private final class OneShotLocationFetcher: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    private var didResume = false

    init(continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>) {
        self.continuation = continuation
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            finish(with: nil)
        }
    }

    private func finish(with coordinate: CLLocationCoordinate2D?) {
        guard !didResume else { return }
        didResume = true
        continuation?.resume(returning: coordinate)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            finish(with: nil)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finish(with: locations.last?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: nil)
    }
}

// ─── Preview ──────────────────────────────────────────────────────────────────
#Preview {
    EarthGlobeView()
        .ignoresSafeArea()
}
