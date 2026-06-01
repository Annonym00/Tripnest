import CoreImage
import PhotosUI
import SwiftUI
import UIKit

enum TripCoverKind: String, Codable, Hashable {
    /// Fond coloré uniquement (legacy : même rendu que `none`).
    case automatic
    case custom
    case none
}

/// Format fixe des couvertures (carte accueil 16:9) — le recadrage évite les bugs d’affichage.
enum TripCoverLayout {
    static let aspectRatio: CGFloat = 16 / 9
    static let exportPixelSize = CGSize(width: 1280, height: 720)
}

struct PendingCoverCrop: Identifiable {
    let id = UUID()
    let image: UIImage
}

enum TripCoverImageStore {
    private static let imageCacheQueue = DispatchQueue(label: "tripnest.coverImage.cache")
    nonisolated(unsafe) private static var imageCache: [String: UIImage] = [:]

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("TripCovers", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func fileURL(tripId: String) -> URL {
        directoryURL.appendingPathComponent("\(tripId).jpg")
    }

    static func modificationToken(tripId: String) -> String {
        let url = fileURL(tripId: tripId)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modifiedAt = attributes[.modificationDate] as? Date else {
            return "missing"
        }
        return String(modifiedAt.timeIntervalSince1970)
    }

    @discardableResult
    static func save(_ image: UIImage, tripId: String) -> Bool {
        let normalized = preparedForStorage(image)
        guard let data = normalized.jpegData(compressionQuality: 0.86) else { return false }
        do {
            try data.write(to: fileURL(tripId: tripId), options: .atomic)
            storeCachedImage(normalized, tripId: tripId)
            return true
        } catch {
            removeCachedImage(tripId: tripId)
            return false
        }
    }

    static func load(tripId: String) -> UIImage? {
        if let cached = cachedImage(tripId: tripId) { return cached }
        let url = fileURL(tripId: tripId)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        storeCachedImage(image, tripId: tripId)
        return image
    }

    static func delete(tripId: String) {
        removeCachedImage(tripId: tripId)
        let url = fileURL(tripId: tripId)
        try? FileManager.default.removeItem(at: url)
    }

    /// Recadre au format carte puis redimensionne pour un rendu identique partout.
    static func preparedForStorage(_ image: UIImage) -> UIImage {
        let upright = image.trip_coverOrientedUp()
        if upright.size == TripCoverLayout.exportPixelSize {
            return upright
        }
        let fitted = upright.trip_coverCenterCropped(toAspect: TripCoverLayout.aspectRatio)
        return fitted.trip_coverResized(to: TripCoverLayout.exportPixelSize)
    }

    static func exportCroppedImage(
        _ image: UIImage,
        cropSizePoints: CGSize,
        userScale: CGFloat,
        offset: CGSize
    ) -> UIImage {
        let upright = image.trip_coverOrientedUp()
        let iw = upright.size.width
        let ih = upright.size.height
        guard iw > 0, ih > 0, cropSizePoints.width > 0, cropSizePoints.height > 0 else {
            return preparedForStorage(image)
        }

        let base = max(cropSizePoints.width / iw, cropSizePoints.height / ih)
        let total = base * userScale
        let dw = iw * total
        let dh = ih * total
        let originX = (cropSizePoints.width - dw) / 2 + offset.width
        let originY = (cropSizePoints.height - dh) / 2 + offset.height

        let visibleW = cropSizePoints.width
        let visibleH = cropSizePoints.height
        let nx = max(0, -originX) / dw
        let ny = max(0, -originY) / dh
        let nw = min(1, visibleW / dw) - nx
        let nh = min(1, visibleH / dh) - ny

        let cropRect = CGRect(
            x: nx * iw,
            y: ny * ih,
            width: max(1, nw * iw),
            height: max(1, nh * ih)
        ).integral

        guard let cg = upright.cgImage?.cropping(to: cropRect) else {
            return preparedForStorage(image)
        }
        let cropped = UIImage(cgImage: cg, scale: upright.scale, orientation: .up)
        return cropped.trip_coverResized(to: TripCoverLayout.exportPixelSize)
    }

    private static func cachedImage(tripId: String) -> UIImage? {
        imageCacheQueue.sync { imageCache[tripId] }
    }

    private static func storeCachedImage(_ image: UIImage, tripId: String) {
        imageCacheQueue.sync { imageCache[tripId] = image }
    }

    private static func removeCachedImage(tripId: String) {
        imageCacheQueue.sync { _ = imageCache.removeValue(forKey: tripId) }
    }
}

// MARK: - Palette dérivée de la couverture (ambilight naturel)

enum TripCoverImagePalette {
    private static let cacheQueue = DispatchQueue(label: "tripnest.coverPalette.cache")
    nonisolated(unsafe) private static var cache: [String: Color] = [:]
    nonisolated(unsafe) private static var ambilightCache: [String: TripCoverAmbilightColors] = [:]
    private static let ciContext = CIContext(options: [.workingColorSpace: NSNull()])

    /// Retourne (et calcule si nécessaire) la couleur dominante de l'image perso d'un voyage.
    /// L'extraction se fait hors thread principal — appeler depuis `.task`.
    static func dominantColor(forTripId tripId: String) async -> Color? {
        if let cached = cached(forTripId: tripId) { return cached }
        let color = await Task.detached(priority: .userInitiated) { () -> Color? in
            guard let image = TripCoverImageStore.load(tripId: tripId) else { return nil }
            return averageColor(of: image)
        }.value
        if let color { store(color, forTripId: tripId) }
        return color
    }

    /// Palette dédiée à l'ambilight : on échantillonne les bords de l'image,
    /// pas le centre, pour reproduire la lumière qui déborde autour de la carte.
    static func ambilightColors(forTripId tripId: String) async -> TripCoverAmbilightColors? {
        if let cached = cachedAmbilight(forTripId: tripId) { return cached }
        let colors = await Task.detached(priority: .userInitiated) { () -> TripCoverAmbilightColors? in
            guard let image = TripCoverImageStore.load(tripId: tripId) else { return nil }
            return edgeAmbilightColors(of: image)
        }.value
        if let colors { storeAmbilight(colors, forTripId: tripId) }
        return colors
    }

    /// Couleur dominante tirée de la galerie de souvenirs (moyenne des premières photos).
    /// Permet à l'ambilight de l'accueil de s'adapter aux photos ajoutées par l'utilisateur.
    static func dominantGalleryColor(forTripId tripId: String, photoCount: Int) async -> Color? {
        guard photoCount > 0 else { return nil }
        return await Task.detached(priority: .userInitiated) { () -> Color? in
            let sampleCount = min(photoCount, 4)
            var rs = 0.0, gs = 0.0, bs = 0.0, n = 0.0
            for index in 0..<sampleCount {
                guard let image = TripPhotoStore.load(tripId: tripId, index: index),
                      let rgb = averageRGB(of: image) else { continue }
                rs += rgb.r; gs += rgb.g; bs += rgb.b; n += 1
            }
            guard n > 0 else { return nil }
            return boosted(r: rs / n, g: gs / n, b: bs / n)
        }.value
    }

    /// Invalide le cache lorsque l'image change ou est supprimée.
    static func invalidate(tripId: String) {
        cacheQueue.sync {
            _ = cache.removeValue(forKey: tripId)
            _ = ambilightCache.removeValue(forKey: tripId)
        }
    }

    private static func cached(forTripId tripId: String) -> Color? {
        cacheQueue.sync { cache[tripId] }
    }

    private static func store(_ color: Color, forTripId tripId: String) {
        cacheQueue.sync { cache[tripId] = color }
    }

    private static func cachedAmbilight(forTripId tripId: String) -> TripCoverAmbilightColors? {
        cacheQueue.sync { ambilightCache[tripId] }
    }

    private static func storeAmbilight(_ colors: TripCoverAmbilightColors, forTripId tripId: String) {
        cacheQueue.sync { ambilightCache[tripId] = colors }
    }

    /// Moyenne colorimétrique de l'image, légèrement saturée pour donner un ambilight vivant.
    private static func averageColor(of image: UIImage) -> Color? {
        guard let rgb = edgeRGB(of: image) ?? averageRGB(of: image) else { return nil }
        return boosted(r: rgb.r, g: rgb.g, b: rgb.b)
    }

    private static func edgeAmbilightColors(of image: UIImage) -> TripCoverAmbilightColors? {
        guard let ci = CIImage(image: image) else { return nil }
        let extent = ci.extent
        guard extent.width > 0, extent.height > 0 else { return nil }

        let leftRect = CGRect(
            x: extent.minX,
            y: extent.minY + extent.height * 0.10,
            width: extent.width * 0.30,
            height: extent.height * 0.80
        )
        let rightRect = CGRect(
            x: extent.maxX - extent.width * 0.30,
            y: extent.minY + extent.height * 0.10,
            width: extent.width * 0.30,
            height: extent.height * 0.80
        )

        let topRect = CGRect(
            x: extent.minX + extent.width * 0.14,
            y: extent.maxY - extent.height * 0.22,
            width: extent.width * 0.72,
            height: extent.height * 0.22
        )
        let bottomRect = CGRect(
            x: extent.minX + extent.width * 0.14,
            y: extent.minY,
            width: extent.width * 0.72,
            height: extent.height * 0.18
        )

        guard let left = averageRGB(of: ci, in: leftRect),
              let right = averageRGB(of: ci, in: rightRect) else {
            return nil
        }

        let edge = weightedAverage([
            (left, 0.34),
            (right, 0.34),
            (averageRGB(of: ci, in: topRect), 0.18),
            (averageRGB(of: ci, in: bottomRect), 0.14)
        ])

        let leading = boosted(r: left.r, g: left.g, b: left.b)
        let trailing = boosted(r: right.r, g: right.g, b: right.b)
        let combined = edge.map { boosted(r: $0.r, g: $0.g, b: $0.b) } ?? boosted(
            r: (left.r + right.r) / 2,
            g: (left.g + right.g) / 2,
            b: (left.b + right.b) / 2
        )
        return TripCoverAmbilightColors(leading: leading, trailing: trailing, combined: combined)
    }

    private static func edgeRGB(of image: UIImage) -> (r: Double, g: Double, b: Double)? {
        guard let ci = CIImage(image: image) else { return nil }
        let extent = ci.extent
        guard extent.width > 0, extent.height > 0 else { return nil }

        let strips: [((r: Double, g: Double, b: Double)?, Double)] = [
            (averageRGB(of: ci, in: CGRect(x: extent.minX, y: extent.minY, width: extent.width * 0.24, height: extent.height)), 0.32),
            (averageRGB(of: ci, in: CGRect(x: extent.maxX - extent.width * 0.24, y: extent.minY, width: extent.width * 0.24, height: extent.height)), 0.32),
            (averageRGB(of: ci, in: CGRect(x: extent.minX, y: extent.maxY - extent.height * 0.20, width: extent.width, height: extent.height * 0.20)), 0.20),
            (averageRGB(of: ci, in: CGRect(x: extent.minX, y: extent.minY, width: extent.width, height: extent.height * 0.16)), 0.16)
        ]
        return weightedAverage(strips)
    }

    /// Composantes RGB moyennes brutes (0…1) de l'image, sans rehaussement.
    private static func averageRGB(of image: UIImage) -> (r: Double, g: Double, b: Double)? {
        guard let ci = CIImage(image: image) else { return nil }
        let extent = ci.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        return averageRGB(of: ci, in: extent)
    }

    private static func averageRGB(of ci: CIImage, in rect: CGRect) -> (r: Double, g: Double, b: Double)? {
        let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ci,
            kCIInputExtentKey: CIVector(cgRect: rect)
        ])
        guard let output = filter?.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(output,
                         toBitmap: &bitmap,
                         rowBytes: 4,
                         bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                         format: .RGBA8,
                         colorSpace: CGColorSpaceCreateDeviceRGB())

        return (Double(bitmap[0]) / 255, Double(bitmap[1]) / 255, Double(bitmap[2]) / 255)
    }

    private static func weightedAverage(
        _ samples: [((r: Double, g: Double, b: Double)?, Double)]
    ) -> (r: Double, g: Double, b: Double)? {
        var rs = 0.0, gs = 0.0, bs = 0.0, total = 0.0
        for (sample, weight) in samples {
            guard let sample else { continue }
            rs += sample.r * weight
            gs += sample.g * weight
            bs += sample.b * weight
            total += weight
        }
        guard total > 0 else { return nil }
        return (rs / total, gs / total, bs / total)
    }

    /// Augmente la saturation et limite la luminosité — sinon les photos donnent un halo grisâtre.
    private static func boosted(r: Double, g: Double, b: Double) -> Color {
        let uiColor = UIColor(red: r, green: g, blue: b, alpha: 1)
        var hue: CGFloat = 0
        var sat: CGFloat = 0
        var bri: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        let boostedSat = min(1, max(sat, 0.55))
        let clampedBri = min(0.85, max(0.55, bri))
        return Color(hue: Double(hue), saturation: Double(boostedSat), brightness: Double(clampedBri))
    }
}

struct TripCoverAmbilightColors {
    let leading: Color
    let trailing: Color
    let combined: Color
}

// MARK: - Recadrage couverture

struct TripCoverCropSheet: View {
    let sourceImage: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var userScale: CGFloat = 1
    @State private var lastUserScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var cropSizePoints: CGSize = .zero

    private var oriented: UIImage { sourceImage.trip_coverOrientedUp() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Pince pour zoomer, glisse pour repositionner.")
                    .font(.tText(12))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                GeometryReader { geo in
                    let crop = Self.cropFrame(in: geo.size)
                    ZStack {
                        Color.black.opacity(0.92)
                        cropEditor(cropSize: crop)
                    }
                    .onAppear { cropSizePoints = crop }
                    .onChange(of: geo.size) { _, newSize in
                        cropSizePoints = Self.cropFrame(in: newSize)
                    }
                }

                HStack(spacing: 12) {
                    Button("Annuler", action: onCancel)
                        .font(.tText(15, weight: .semibold))
                        .foregroundColor(.tTextMute)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)

                    Button {
                        let exported = TripCoverImageStore.exportCroppedImage(
                            oriented,
                            cropSizePoints: cropSizePoints,
                            userScale: userScale,
                            offset: offset
                        )
                        onConfirm(exported)
                    } label: {
                        Text("Utiliser")
                            .font(.tText(15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.tAccent)
                            )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 12)
            }
            .background(Color.tBg0.ignoresSafeArea())
            .navigationTitle("Recadrer la couverture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tBg0, for: .navigationBar)
        }
    }

    private func cropEditor(cropSize: CGSize) -> some View {
        let iw = oriented.size.width
        let ih = oriented.size.height
        let base = max(cropSize.width / iw, cropSize.height / ih)
        let total = base * userScale
        let dw = iw * total
        let dh = ih * total
        let clamped = clampedOffset(offset, crop: cropSize, displayW: dw, displayH: dh)

        return ZStack {
            Image(uiImage: oriented)
                .resizable()
                .frame(width: dw, height: dh)
                .offset(clamped)
                .gesture(dragGesture(crop: cropSize, displayW: dw, displayH: dh))
                .simultaneousGesture(magnifyGesture)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                .frame(width: cropSize.width, height: cropSize.height)

            VStack {
                Text("Format carte")
                    .font(.tText(10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .padding(.top, 10)
                Spacer()
            }
            .frame(width: cropSize.width, height: cropSize.height)
        }
        .frame(width: cropSize.width, height: cropSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                userScale = min(4, max(1, lastUserScale * value.magnification))
            }
            .onEnded { _ in
                lastUserScale = userScale
            }
    }

    private func dragGesture(crop: CGSize, displayW: CGFloat, displayH: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clampedOffset(proposed, crop: crop, displayW: displayW, displayH: displayH)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func clampedOffset(_ proposed: CGSize, crop: CGSize, displayW: CGFloat, displayH: CGFloat) -> CGSize {
        let maxX = max(0, (displayW - crop.width) / 2)
        let maxY = max(0, (displayH - crop.height) / 2)
        return CGSize(
            width: min(maxX, max(-maxX, proposed.width)),
            height: min(maxY, max(-maxY, proposed.height))
        )
    }

    private static func cropFrame(in container: CGSize) -> CGSize {
        let maxW = max(0, container.width - 44)
        let maxH = max(0, container.height - 24)
        var w = maxW
        var h = w / TripCoverLayout.aspectRatio
        if h > maxH {
            h = maxH
            w = h * TripCoverLayout.aspectRatio
        }
        return CGSize(width: max(200, w), height: max(112, h))
    }
}

// MARK: - UIImage helpers

private extension UIImage {
    func trip_coverOrientedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func trip_coverCenterCropped(toAspect aspect: CGFloat) -> UIImage {
        let w = size.width
        let h = size.height
        guard w > 0, h > 0 else { return self }
        let current = w / h
        var crop = CGRect(origin: .zero, size: size)
        if current > aspect {
            let newW = h * aspect
            crop.origin.x = (w - newW) / 2
            crop.size.width = newW
        } else if current < aspect {
            let newH = w / aspect
            crop.origin.y = (h - newH) / 2
            crop.size.height = newH
        }
        crop = crop.integral
        guard let cg = cgImage?.cropping(to: crop) else { return self }
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }

    func trip_coverResized(to target: CGSize) -> UIImage {
        guard target.width > 0, target.height > 0 else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - Pickers

struct CameraImagePicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage, onCancel: onCancel) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

/// Sélecteur galerie en sheet — évite le style `.compact` de `PhotosPicker` qui casse la mise en page du formulaire.
struct GalleryPhotoPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage, onCancel: onCancel) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                onCancel()
                return
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self.onImage(image)
                    } else {
                        self.onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Photos de voyage (galerie)

enum TripPhotoStore {
    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("TripPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func fileURL(tripId: String, index: Int) -> URL {
        directoryURL.appendingPathComponent("\(tripId)_\(index).jpg")
    }

    @discardableResult
    static func save(_ image: UIImage, tripId: String, index: Int) -> Bool {
        // Préserve le ratio (plus de déformation en carré 1280×1280 qui « cassait » l'image).
        let resized = image.crop_downscaled(maxDimension: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.84) else { return false }
        do {
            try data.write(to: fileURL(tripId: tripId, index: index), options: .atomic)
            return true
        } catch { return false }
    }

    static func load(tripId: String, index: Int) -> UIImage? {
        let url = fileURL(tripId: tripId, index: index)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func loadAll(tripId: String, count: Int) -> [UIImage] {
        (0..<count).compactMap { load(tripId: tripId, index: $0) }
    }

    static func deleteAll(tripId: String, count: Int) {
        for i in 0..<max(count, 48) {
            try? FileManager.default.removeItem(at: fileURL(tripId: tripId, index: i))
        }
        try? FileManager.default.removeItem(at: memoriesURL(tripId: tripId))
    }

    static func memoriesURL(tripId: String) -> URL {
        directoryURL.appendingPathComponent("\(tripId)_memories.json")
    }

    static func loadMemories(tripId: String, count: Int) -> [TripPhotoMemory] {
        let url = memoriesURL(tripId: tripId)
        guard let data = try? Data(contentsOf: url),
              let stored = try? JSONDecoder().decode([TripPhotoMemory].self, from: data) else {
            return Array(repeating: TripPhotoMemory(), count: count)
        }
        var result = stored
        while result.count < count { result.append(TripPhotoMemory()) }
        if result.count > count { result = Array(result.prefix(count)) }
        return result
    }

    static func saveMemories(tripId: String, memories: [TripPhotoMemory]) {
        let normalized = memories.map { memory in
            var m = memory
            m.title = String(m.title.prefix(120))
            m.caption = TripPhotoMemory.clampedCaption(m.caption)
            return m
        }
        guard let data = try? JSONEncoder().encode(normalized) else { return }
        try? data.write(to: memoriesURL(tripId: tripId), options: .atomic)
    }
}

// MARK: - Spot photos

enum SpotImageStore {
    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("SpotPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func fileURL(spotId: String, index: Int) -> URL {
        directoryURL.appendingPathComponent("\(spotId)_\(index).jpg")
    }

    @discardableResult
    static func save(_ image: UIImage, spotId: String, index: Int) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return false }
        do {
            try data.write(to: fileURL(spotId: spotId, index: index), options: .atomic)
            return true
        } catch { return false }
    }

    static func load(spotId: String, index: Int) -> UIImage? {
        let url = fileURL(spotId: spotId, index: index)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func loadAll(spotId: String, count: Int) -> [UIImage] {
        (0..<count).compactMap { load(spotId: spotId, index: $0) }
    }

    static func deleteAll(spotId: String, count: Int) {
        for i in 0..<count {
            try? FileManager.default.removeItem(at: fileURL(spotId: spotId, index: i))
        }
    }
}


// MARK: - Recadrage interactif réutilisable (déplacé ici pour être inclus au build)

// MARK: - Recadrage interactif réutilisable (profil, souvenirs, etc.)
//
// Généralise la logique éprouvée de TripCoverCropSheet : pince pour zoomer,
// glisse pour repositionner. Paramétrable par ratio et forme (cercle / rectangle).
// L'image exportée est recadrée selon ce que l'utilisateur cadre — aucune distorsion.

/// Conteneur Identifiable pour présenter le cropper via `.fullScreenCover(item:)`.
struct PendingImageCrop: Identifiable {
    let id = UUID()
    let image: UIImage
}

enum ImageCropper {
    /// Recadre `image` selon la zone visible (cropSizePoints) après zoom/déplacement
    /// utilisateur, puis redimensionne en préservant le ratio (jamais d'étirement).
    static func export(
        _ image: UIImage,
        cropSizePoints: CGSize,
        userScale: CGFloat,
        offset: CGSize,
        outputMaxPixel: CGFloat
    ) -> UIImage {
        let upright = image.crop_orientedUp()
        let iw = upright.size.width
        let ih = upright.size.height
        guard iw > 0, ih > 0, cropSizePoints.width > 0, cropSizePoints.height > 0 else {
            return upright
        }

        let base = max(cropSizePoints.width / iw, cropSizePoints.height / ih)
        let total = base * userScale
        let dw = iw * total
        let dh = ih * total
        let originX = (cropSizePoints.width - dw) / 2 + offset.width
        let originY = (cropSizePoints.height - dh) / 2 + offset.height

        let nx = max(0, -originX) / dw
        let ny = max(0, -originY) / dh
        let nw = min(1, cropSizePoints.width / dw) - nx
        let nh = min(1, cropSizePoints.height / dh) - ny

        let cropRect = CGRect(
            x: nx * iw,
            y: ny * ih,
            width: max(1, nw * iw),
            height: max(1, nh * ih)
        ).integral

        guard let cg = upright.cgImage?.cropping(to: cropRect) else { return upright }
        let cropped = UIImage(cgImage: cg, scale: upright.scale, orientation: .up)

        let aspect = cropSizePoints.width / cropSizePoints.height
        let outW: CGFloat
        let outH: CGFloat
        if aspect >= 1 {
            outW = outputMaxPixel
            outH = outputMaxPixel / aspect
        } else {
            outH = outputMaxPixel
            outW = outputMaxPixel * aspect
        }
        return cropped.crop_resized(to: CGSize(width: max(1, outW), height: max(1, outH)))
    }
}

struct ImageCropSheet: View {
    let sourceImage: UIImage
    var aspectRatio: CGFloat = 1          // largeur / hauteur de la zone de recadrage
    var isCircle: Bool = false            // aperçu masqué en cercle (photo de profil)
    var title: String = "Recadrer"
    var hint: String = "Pince pour zoomer, glisse pour repositionner."
    var badge: String? = nil             // petit libellé en haut de la zone
    var outputMaxPixel: CGFloat = 1024
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var userScale: CGFloat = 1
    @State private var lastUserScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var cropSizePoints: CGSize = .zero

    private var oriented: UIImage { sourceImage.crop_orientedUp() }
    private var cornerRadius: CGFloat { isCircle ? 9999 : 14 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text(hint)
                    .font(.tText(12))
                    .foregroundColor(.tTextMute)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                GeometryReader { geo in
                    let crop = cropFrame(in: geo.size)
                    ZStack {
                        Color.black.opacity(0.92)
                        cropEditor(cropSize: crop)
                    }
                    .onAppear { cropSizePoints = crop }
                    .onChange(of: geo.size) { _, newSize in
                        cropSizePoints = cropFrame(in: newSize)
                    }
                }

                HStack(spacing: 12) {
                    Button("Annuler", action: onCancel)
                        .font(.tText(15, weight: .semibold))
                        .foregroundColor(.tTextMute)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)

                    Button {
                        let exported = ImageCropper.export(
                            oriented,
                            cropSizePoints: cropSizePoints,
                            userScale: userScale,
                            offset: offset,
                            outputMaxPixel: outputMaxPixel
                        )
                        onConfirm(exported)
                    } label: {
                        Text("Utiliser")
                            .font(.tText(15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.tAccent)
                            )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 12)
            }
            .background(Color.tBg0.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tBg0, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func cropEditor(cropSize: CGSize) -> some View {
        let iw = oriented.size.width
        let ih = oriented.size.height
        let base = max(cropSize.width / iw, cropSize.height / ih)
        let total = base * userScale
        let dw = iw * total
        let dh = ih * total
        let clamped = clampedOffset(offset, crop: cropSize, displayW: dw, displayH: dh)

        ZStack {
            Image(uiImage: oriented)
                .resizable()
                .frame(width: dw, height: dh)
                .offset(clamped)
                .gesture(dragGesture(crop: cropSize, displayW: dw, displayH: dh))
                .simultaneousGesture(magnifyGesture)

            if isCircle {
                Circle()
                    .stroke(Color.white.opacity(0.85), lineWidth: 2)
                    .frame(width: cropSize.width, height: cropSize.height)
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.85), lineWidth: 2)
                    .frame(width: cropSize.width, height: cropSize.height)
            }

            if let badge {
                VStack {
                    Text(badge)
                        .font(.tText(10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.45)))
                        .padding(.top, 10)
                    Spacer()
                }
                .frame(width: cropSize.width, height: cropSize.height)
            }
        }
        .frame(width: cropSize.width, height: cropSize.height)
        .clipShape(
            isCircle
                ? AnyShape(Circle())
                : AnyShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                userScale = min(4, max(1, lastUserScale * value.magnification))
            }
            .onEnded { _ in
                lastUserScale = userScale
                offset = clampedOffset(offset, crop: cropSizePoints,
                                       displayW: displayWidth, displayH: displayHeight)
                lastOffset = offset
            }
    }

    private var displayWidth: CGFloat {
        let base = max(cropSizePoints.width / oriented.size.width,
                       cropSizePoints.height / oriented.size.height)
        return oriented.size.width * base * userScale
    }
    private var displayHeight: CGFloat {
        let base = max(cropSizePoints.width / oriented.size.width,
                       cropSizePoints.height / oriented.size.height)
        return oriented.size.height * base * userScale
    }

    private func dragGesture(crop: CGSize, displayW: CGFloat, displayH: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clampedOffset(proposed, crop: crop, displayW: displayW, displayH: displayH)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func clampedOffset(_ proposed: CGSize, crop: CGSize, displayW: CGFloat, displayH: CGFloat) -> CGSize {
        let maxX = max(0, (displayW - crop.width) / 2)
        let maxY = max(0, (displayH - crop.height) / 2)
        return CGSize(
            width: min(maxX, max(-maxX, proposed.width)),
            height: min(maxY, max(-maxY, proposed.height))
        )
    }

    private func cropFrame(in container: CGSize) -> CGSize {
        let maxW = max(0, container.width - 44)
        let maxH = max(0, container.height - 24)
        var w = maxW
        var h = w / aspectRatio
        if h > maxH {
            h = maxH
            w = h * aspectRatio
        }
        return CGSize(width: max(80, w), height: max(80, h))
    }
}

// MARK: - UIImage helpers (génériques, non liés à la couverture)

extension UIImage {
    func crop_orientedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func crop_resized(to target: CGSize) -> UIImage {
        guard target.width > 0, target.height > 0 else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }

    /// Réduit l'image pour que sa plus grande dimension ne dépasse pas `maxDimension`,
    /// en **préservant le ratio** (aucune distorsion). Renvoie l'original si déjà assez petit.
    func crop_downscaled(maxDimension: CGFloat) -> UIImage {
        let upright = crop_orientedUp()
        let w = upright.size.width
        let h = upright.size.height
        guard w > 0, h > 0 else { return upright }
        let longest = max(w, h)
        guard longest > maxDimension else { return upright }
        let ratio = maxDimension / longest
        return upright.crop_resized(to: CGSize(width: w * ratio, height: h * ratio))
    }
}
