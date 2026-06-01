// Tripnest design tokens, icons, shared atoms
const T = {
  bg0: '#0e0620',
  bg1: '#150a2a',
  bg2: '#1e1238',
  surface: 'rgba(139, 92, 246, 0.06)',
  surfaceStrong: 'rgba(139, 92, 246, 0.10)',
  border: 'rgba(167, 139, 250, 0.14)',
  borderStrong: 'rgba(167, 139, 250, 0.22)',
  text: '#f5f0ff',
  textMute: 'rgba(245, 240, 255, 0.62)',
  textDim: 'rgba(245, 240, 255, 0.38)',
  accent: '#8b5cf6',
  accent2: '#a78bfa',
  accentDeep: '#6d28d9',
  gold: '#f5c150',
  rose: '#f472b6',
  mint: '#86efac',
  blue: '#7dd3fc',
  font: '-apple-system, "SF Pro Display", "SF Pro Text", Inter, system-ui, sans-serif',
};

// ── Icons (24×24, stroke 1.75, line caps round) ───────────────
const Icon = ({ d, fill, size = 22, stroke = T.text, sw = 1.75, children, vb = 24 }) => (
  <svg width={size} height={size} viewBox={`0 0 ${vb} ${vb}`} fill="none">
    {d && <path d={d} stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" fill={fill || 'none'}/>}
    {children}
  </svg>
);

const I = {
  home: (p) => <Icon {...p} d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1v-9z"/>,
  trips: (p) => <Icon {...p} d="M4 7h16M4 12h16M4 17h10"/>,
  plane: (p) => <Icon {...p} d="M3.5 12.5L21 4l-5 17-4-7-7-1.5z"/>,
  spot: (p) => <Icon {...p} d="M12 21s-7-6.2-7-12a7 7 0 0 1 14 0c0 5.8-7 12-7 12z M12 11.5a2 2 0 1 0 0-4 2 2 0 0 0 0 4z"/>,
  wallet: (p) => <Icon {...p} d="M4 7a2 2 0 0 1 2-2h12v3M4 7v11a2 2 0 0 0 2 2h13a1 1 0 0 0 1-1v-3M4 7h15a1 1 0 0 1 1 1v3 M17 13.5a1 1 0 1 0 0 2 1 1 0 0 0 0-2z"/>,
  user: (p) => <Icon {...p} d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8z M4 21a8 8 0 0 1 16 0"/>,
  plus: (p) => <Icon {...p} d="M12 5v14M5 12h14"/>,
  search: (p) => <Icon {...p} d="M11 19a8 8 0 1 1 0-16 8 8 0 0 1 0 16zM21 21l-4.3-4.3"/>,
  bell: (p) => <Icon {...p} d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2.5h-15L6 16z M10 21a2 2 0 0 0 4 0"/>,
  arrow: (p) => <Icon {...p} d="M5 12h14M13 6l6 6-6 6"/>,
  back: (p) => <Icon {...p} d="M19 12H5M11 6l-6 6 6 6"/>,
  more: (p) => <Icon {...p} d="M5 12h.01M12 12h.01M19 12h.01" sw={2.5}/>,
  cam: (p) => <Icon {...p} d="M3 8a2 2 0 0 1 2-2h2l1.5-2h7L17 6h2a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8z M12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"/>,
  heart: (p) => <Icon {...p} d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>,
  cal: (p) => <Icon {...p} d="M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v13a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6z M4 10h16 M8 3v4 M16 3v4"/>,
  filter: (p) => <Icon {...p} d="M4 6h16M7 12h10M10 18h4"/>,
  star: (p) => <Icon {...p} d="M12 3.5l2.7 5.5 6 .9-4.4 4.2 1.05 6L12 17.3l-5.4 2.8L7.7 14 3.3 9.9l6-.9L12 3.5z"/>,
  edit: (p) => <Icon {...p} d="M4 20h4l11-11-4-4L4 16v4z M14 6l4 4"/>,
  check: (p) => <Icon {...p} d="M5 12l4 4 10-10"/>,
  close: (p) => <Icon {...p} d="M6 6l12 12M18 6L6 18"/>,
  food: (p) => <Icon {...p} d="M5 3v8a3 3 0 0 0 3 3v7 M8 3v6 M11 3v6 M17 3c-1.5 0-3 2-3 5s1 4 3 4v9"/>,
  hotel: (p) => <Icon {...p} d="M3 20V7M3 14h18v6 M7 11a2 2 0 1 0 0-4 2 2 0 0 0 0 4z M11 14V11a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v3"/>,
  bus: (p) => <Icon {...p} d="M5 17h14V7a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v10z M5 12h14 M8 21v-2 M16 21v-2 M9 16h.01M15 16h.01"/>,
  ticket: (p) => <Icon {...p} d="M3 9a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2a2 2 0 0 0 0 4v2a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2a2 2 0 0 0 0-4V9z M10 7v10"/>,
  gift: (p) => <Icon {...p} d="M4 12h16v8a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-8z M3 8h18v4H3z M12 8v13 M12 8s-3-5-5.5-3S7 8 12 8z M12 8s3-5 5.5-3S17 8 12 8z"/>,
  globe: (p) => <Icon {...p} d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z M3 12h18 M12 3c2.5 3 4 6 4 9s-1.5 6-4 9c-2.5-3-4-6-4-9s1.5-6 4-9z"/>,
  passport: (p) => <Icon {...p} d="M5 3h14v18H5z M9 8a3 3 0 1 0 6 0 3 3 0 0 0-6 0z M8 17h8"/>,
  sun: (p) => <Icon {...p} d="M12 17a5 5 0 1 0 0-10 5 5 0 0 0 0 10z M12 2v2M12 20v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M2 12h2M20 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4"/>,
};

// ── Paper-plane ambient motif background ──────────────────────
function PlaneMotif({ count = 14, seed = 1 }) {
  // deterministic pseudo-random
  const r = (i, m = 1) => {
    const x = Math.sin((i + seed) * 9301 + 49297) * 233280;
    return ((x - Math.floor(x)) * m);
  };
  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none', zIndex: 0 }}>
      {Array.from({ length: count }).map((_, i) => {
        const x = r(i, 100);
        const y = r(i + 99, 100);
        const s = 8 + r(i + 17, 16);
        const rot = -40 + r(i + 33, 80);
        const op = 0.05 + r(i + 7, 0.18);
        return (
          <svg key={i} width={s} height={s} viewBox="0 0 24 24" fill="none"
            style={{ position: 'absolute', left: `${x}%`, top: `${y}%`, opacity: op, transform: `rotate(${rot}deg)` }}>
            <path d="M3.5 12.5L21 4l-5 17-4-7-7-1.5z" fill="#a78bfa" stroke="#c4b5fd" strokeWidth="0.5"/>
          </svg>
        );
      })}
    </div>
  );
}

// ── Tripnest logo (paper plane app icon) ──────────────────────
function Logo({ size = 84, glow = true }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.24,
      background: 'linear-gradient(155deg, #1a0d33 0%, #0a0418 100%)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      position: 'relative',
      boxShadow: glow ? '0 18px 50px rgba(139,92,246,0.45), inset 0 1px 0 rgba(255,255,255,0.06)' : 'inset 0 1px 0 rgba(255,255,255,0.06)',
      border: '1px solid rgba(167,139,250,0.18)',
    }}>
      <svg width={size * 0.62} height={size * 0.62} viewBox="0 0 64 64" fill="none">
        <defs>
          <linearGradient id="planeGrad" x1="10" y1="10" x2="55" y2="55">
            <stop offset="0%" stopColor="#c4b5fd"/>
            <stop offset="55%" stopColor="#8b5cf6"/>
            <stop offset="100%" stopColor="#5b21b6"/>
          </linearGradient>
          <linearGradient id="planeShade" x1="32" y1="14" x2="32" y2="50">
            <stop offset="0%" stopColor="#ddd6fe"/>
            <stop offset="100%" stopColor="#7c3aed"/>
          </linearGradient>
        </defs>
        {/* main body */}
        <path d="M8 32 L54 10 L46 54 L34 40 L26 48 L26 38 L8 32z" fill="url(#planeGrad)"/>
        {/* fold highlight */}
        <path d="M54 10 L34 40 L26 38 z" fill="url(#planeShade)" opacity="0.85"/>
        {/* inner shadow */}
        <path d="M26 38 L34 40 L26 48 z" fill="#3b1d7a" opacity="0.7"/>
      </svg>
    </div>
  );
}

// ── Shared atoms ──────────────────────────────────────────────
function Card({ children, style = {}, padding = 18, glow = false }) {
  return (
    <div style={{
      background: 'linear-gradient(180deg, rgba(139,92,246,0.10) 0%, rgba(139,92,246,0.04) 100%)',
      border: `1px solid ${T.border}`,
      borderRadius: 22,
      padding,
      position: 'relative',
      overflow: 'hidden',
      boxShadow: glow ? '0 18px 40px rgba(15,5,35,0.4), inset 0 1px 0 rgba(255,255,255,0.04)' : 'inset 0 1px 0 rgba(255,255,255,0.04)',
      ...style,
    }}>{children}</div>
  );
}

function Pill({ children, active = false, color = T.accent, onClick, style = {} }) {
  return (
    <button onClick={onClick} style={{
      border: 'none',
      padding: '7px 14px',
      borderRadius: 999,
      fontFamily: T.font,
      fontSize: 13, fontWeight: 600,
      background: active ? color : 'rgba(167,139,250,0.10)',
      color: active ? '#fff' : T.text,
      border: active ? `1px solid ${color}` : `1px solid ${T.border}`,
      cursor: 'pointer',
      whiteSpace: 'nowrap',
      ...style,
    }}>{children}</button>
  );
}

function ProgressRing({ value, max, size = 130, stroke = 12, color = T.accent, trackColor = 'rgba(167,139,250,0.15)', children }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const pct = Math.min(1, value / max);
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={trackColor} strokeWidth={stroke} fill="none"/>
        <circle cx={size/2} cy={size/2} r={r} stroke={color} strokeWidth={stroke} fill="none"
          strokeLinecap="round" strokeDasharray={`${c * pct} ${c}`}/>
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column' }}>
        {children}
      </div>
    </div>
  );
}

// ── Image placeholder (destination tile) ───────────────────────
function DestPhoto({ label, hue = 270, w = '100%', h = 160, radius = 16, style = {} }) {
  // Striped gradient placeholder with monospace caption
  return (
    <div style={{
      width: w, height: h, borderRadius: radius,
      background: `linear-gradient(135deg, oklch(0.40 0.14 ${hue}) 0%, oklch(0.22 0.10 ${hue + 20}) 100%)`,
      position: 'relative', overflow: 'hidden',
      border: `1px solid ${T.border}`,
      ...style,
    }}>
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: 'repeating-linear-gradient(135deg, transparent 0 14px, rgba(255,255,255,0.04) 14px 15px)',
      }}/>
      <div style={{
        position: 'absolute', left: 12, bottom: 10,
        fontFamily: 'ui-monospace, SF Mono, Menlo, monospace',
        fontSize: 10, color: 'rgba(255,255,255,0.6)', letterSpacing: 0.5,
        textTransform: 'uppercase',
      }}>📷 {label}</div>
    </div>
  );
}

// ── Bottom tab bar ─────────────────────────────────────────────
function TabBar({ active, onChange }) {
  const tabs = [
    { id: 'home', label: 'Accueil', icon: I.home },
    { id: 'trips', label: 'Voyages', icon: I.globe },
    { id: 'add', label: '', icon: null },
    { id: 'budget', label: 'Budget', icon: I.wallet },
    { id: 'profile', label: 'Profil', icon: I.user },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      paddingBottom: 4, paddingTop: 10, paddingLeft: 12, paddingRight: 12,
      background: 'linear-gradient(180deg, rgba(14,6,32,0) 0%, rgba(14,6,32,0.85) 40%, rgba(14,6,32,0.98) 100%)',
      display: 'flex', alignItems: 'flex-end', justifyContent: 'space-around',
      zIndex: 30,
    }}>
      {tabs.map(t => {
        if (t.id === 'add') {
          return (
            <button key="add" onClick={() => onChange && onChange('add')} style={{
              width: 54, height: 54, borderRadius: '50%',
              background: `linear-gradient(160deg, ${T.accent2} 0%, ${T.accentDeep} 100%)`,
              border: '3px solid #150a2a',
              boxShadow: '0 8px 24px rgba(139,92,246,0.55)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer',
              transform: 'translateY(-14px)',
            }}>
              <I.plus stroke="#fff" sw={2.4} size={26}/>
            </button>
          );
        }
        const isActive = active === t.id;
        return (
          <button key={t.id} onClick={() => onChange && onChange(t.id)} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
            flex: 1, padding: '4px 0', color: isActive ? T.accent2 : T.textMute,
          }}>
            <t.icon stroke={isActive ? T.accent2 : T.textMute} sw={isActive ? 2 : 1.6} size={23}/>
            <span style={{ fontFamily: T.font, fontSize: 10, fontWeight: 600, letterSpacing: 0.2 }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ── Screen shell (bg + motif + status bar) ────────────────────
function Screen({ children, motif = true, style = {} }) {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: `radial-gradient(120% 80% at 50% -10%, ${T.bg2} 0%, ${T.bg1} 35%, ${T.bg0} 100%)`,
      fontFamily: T.font,
      color: T.text,
      overflow: 'hidden',
      ...style,
    }}>
      {motif && <PlaneMotif/>}
      <div style={{ position: 'relative', zIndex: 1, height: '100%' }}>{children}</div>
    </div>
  );
}

// Status bar in white for dark screens
function StatusBar({ time = '23:41' }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '14px 26px 8px', height: 44, boxSizing: 'border-box',
      fontFamily: T.font, color: '#fff', fontSize: 15, fontWeight: 600,
      position: 'relative', zIndex: 5,
    }}>
      <span>{time}</span>
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <svg width="17" height="11" viewBox="0 0 17 11"><rect x="0" y="6" width="3" height="4" rx="0.7" fill="#fff"/><rect x="4.5" y="4" width="3" height="6" rx="0.7" fill="#fff"/><rect x="9" y="2" width="3" height="8" rx="0.7" fill="#fff"/><rect x="13.5" y="0" width="3" height="10" rx="0.7" fill="#fff"/></svg>
        <svg width="15" height="11" viewBox="0 0 15 11"><path d="M7.5 2.8c2 0 3.8.8 5.1 2.2l1-1A8 8 0 0 0 7.5 1.3 8 8 0 0 0 1.4 4l1 1A6.8 6.8 0 0 1 7.5 2.8z M7.5 6c1.2 0 2.3.4 3.1 1.2l1-1a5 5 0 0 0-4.1-1.7A5 5 0 0 0 3.4 6.2l1 1A4 4 0 0 1 7.5 6z" fill="#fff"/><circle cx="7.5" cy="9.4" r="1.2" fill="#fff"/></svg>
        <div style={{
          width: 27, height: 12, borderRadius: 3, border: '1px solid rgba(255,255,255,0.5)',
          padding: 1, boxSizing: 'border-box', display: 'flex', alignItems: 'center', position: 'relative',
        }}>
          <div style={{ width: '40%', height: '100%', background: '#34d399', borderRadius: 1 }}/>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { T, I, Icon, PlaneMotif, Logo, Card, Pill, ProgressRing, DestPhoto, TabBar, Screen, StatusBar });
