// 15-screen converting onboarding for Tripnest
// Funnel: hook → value × 3 → social proof → 5 qualifying Qs → loading → reveal → paywall → account → success

// Shared: progress bar at top
function ObProgress({ step, total = 15, label }) {
  return (
    <div style={{ padding: '6px 22px 0' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <button style={{ all: 'unset', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4, color: T.textMute, fontSize: 13, fontWeight: 600 }}>
          <I.back size={14} stroke={T.textMute}/> Retour
        </button>
        <div style={{ fontSize: 11, color: T.textMute, fontWeight: 700, letterSpacing: 1.5 }}>{step} / {total}{label ? ` · ${label}` : ''}</div>
        <button style={{ all: 'unset', cursor: 'pointer', color: T.textMute, fontSize: 13, fontWeight: 600 }}>Passer</button>
      </div>
      <div style={{ height: 3, borderRadius: 2, background: 'rgba(167,139,250,0.15)', overflow: 'hidden' }}>
        <div style={{ width: `${step / total * 100}%`, height: '100%',
          background: `linear-gradient(90deg, ${T.accent2}, ${T.accent})`,
          transition: 'width .4s' }}/>
      </div>
    </div>
  );
}

// Primary CTA reused
function CTA({ children, secondary, style = {}, ghost }) {
  if (ghost) return <button style={{
    all: 'unset', cursor: 'pointer', width: '100%', textAlign: 'center', padding: '14px 0',
    fontSize: 14, fontWeight: 700, color: T.textMute, ...style,
  }}>{children}</button>;
  return (
    <button style={{
      width: '100%', height: 56, borderRadius: 18,
      background: secondary ? T.surface : `linear-gradient(180deg, ${T.accent2} 0%, ${T.accentDeep} 100%)`,
      color: '#fff', fontSize: 16, fontWeight: 700,
      border: secondary ? `1px solid ${T.borderStrong}` : '1px solid rgba(167,139,250,0.4)',
      boxShadow: secondary ? 'none' : '0 12px 28px rgba(139,92,246,0.35), inset 0 1px 0 rgba(255,255,255,0.18)',
      fontFamily: T.font, letterSpacing: -0.2, cursor: 'pointer',
      ...style,
    }}>{children}</button>
  );
}

// ───────────────────────────────────────────────────────────────
// 01 · HOOK / WELCOME — big emotional moment
// ───────────────────────────────────────────────────────────────
function OB01_Welcome() {
  return (
    <Screen>
      <StatusBar/>
      {/* Floating planes large */}
      <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none' }}>
        {[
          { x: 15, y: 18, s: 28, r: -20, op: 0.22 },
          { x: 78, y: 22, s: 20, r: 30, op: 0.30 },
          { x: 22, y: 70, s: 16, r: 10, op: 0.25 },
          { x: 84, y: 76, s: 24, r: -40, op: 0.20 },
        ].map((p, i) => (
          <svg key={i} width={p.s * 4} height={p.s * 4} viewBox="0 0 24 24" fill="none"
            style={{ position: 'absolute', left: `${p.x}%`, top: `${p.y}%`, opacity: p.op, transform: `rotate(${p.r}deg)` }}>
            <path d="M3.5 12.5L21 4l-5 17-4-7-7-1.5z" fill="#a78bfa" stroke="#c4b5fd" strokeWidth="0.5"/>
          </svg>
        ))}
      </div>

      <div style={{ position: 'relative', height: 'calc(100% - 44px)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: '40px 28px 36px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 22, marginTop: 40 }}>
          <Logo size={120}/>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 2.5, color: T.accent2, marginBottom: 14 }}>BIENVENUE</div>
            <div style={{ fontSize: 44, fontWeight: 800, letterSpacing: -1.6, lineHeight: 1 }}>Voyage<br/>sans stress<span style={{ color: T.accent2 }}>.</span></div>
            <div style={{ fontSize: 16, color: T.textMute, marginTop: 18, lineHeight: 1.45, padding: '0 8px' }}>
              Budget, vols, spots et souvenirs.<br/>Tout ton voyage dans une seule app.
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <CTA>Commencer · c'est gratuit</CTA>
          <CTA ghost>J'ai déjà un compte</CTA>
        </div>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 02 · VALUE — Budget
// ───────────────────────────────────────────────────────────────
function OB02_Budget() {
  return (
    <Screen>
      <StatusBar/>
      <ObProgress step={2} label="Découverte"/>
      <div style={{ padding: '24px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        {/* visual */}
        <div style={{ flex: 1, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{
            width: 240, height: 240, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(139,92,246,0.20) 0%, transparent 70%)',
            position: 'absolute',
          }}/>
          <Card padding={22} glow style={{ width: 280, transform: 'rotate(-2deg)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <ProgressRing value={1124} max={1850} size={92} stroke={9} color={T.accent2}>
                <div style={{ fontSize: 17, fontWeight: 800, letterSpacing: -0.5 }}>61%</div>
              </ProgressRing>
              <div>
                <div style={{ fontSize: 10, color: T.textMute, fontWeight: 600, letterSpacing: 1 }}>RESTE</div>
                <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.6, color: T.mint }}>726€</div>
                <div style={{ fontSize: 10, color: T.textMute, marginTop: 2 }}>≈ 103€ / jour</div>
              </div>
            </div>
            <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 8 }}>
              {[['Hôtel', 68, T.rose], ['Repas', 47, T.gold], ['Transport', 35, T.blue]].map(([l, v, c]) => (
                <div key={l} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <div style={{ width: 24, height: 4, borderRadius: 2, background: 'rgba(167,139,250,0.15)', overflow: 'hidden', flex: 1 }}>
                    <div style={{ width: `${v}%`, height: '100%', background: c }}/>
                  </div>
                  <span style={{ fontSize: 11, color: T.textMute, minWidth: 70 }}>{l}</span>
                </div>
              ))}
            </div>
          </Card>
          {/* coin badges */}
          {['64€', '12€', '360€'].map((v, i) => (
            <div key={v} style={{
              position: 'absolute',
              top: [40, 220, 60][i], left: [30, 250, 240][i],
              padding: '6px 11px', borderRadius: 999,
              background: 'rgba(245,193,80,0.18)', border: '1px solid rgba(245,193,80,0.4)',
              fontSize: 12, fontWeight: 700, color: T.gold,
              transform: `rotate(${[-8, 12, -4][i]}deg)`,
            }}>−{v}</div>
          ))}
        </div>
        {/* copy */}
        <div>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>BUDGET INTELLIGENT</div>
          <div style={{ fontSize: 32, fontWeight: 800, letterSpacing: -1, marginTop: 8, lineHeight: 1.05 }}>
            Garde ton budget<br/>en main, jour après jour.
          </div>
          <div style={{ fontSize: 15, color: T.textMute, marginTop: 12, lineHeight: 1.4 }}>
            Catégorise tes dépenses, convertis les devises et vois en temps réel combien il te reste.
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 24 }}>
            <Dots active={0}/>
            <CTA style={{ width: 120, height: 48, fontSize: 14 }}>Suivant →</CTA>
          </div>
        </div>
      </div>
    </Screen>
  );
}

function Dots({ active, total = 3 }) {
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      {Array.from({ length: total }).map((_, i) => (
        <div key={i} style={{
          width: i === active ? 22 : 7, height: 7, borderRadius: 4,
          background: i === active ? T.accent2 : 'rgba(167,139,250,0.25)',
          transition: 'width .3s',
        }}/>
      ))}
    </div>
  );
}

// ───────────────────────────────────────────────────────────────
// 03 · VALUE — Flights
// ───────────────────────────────────────────────────────────────
function OB03_Flights() {
  return (
    <Screen>
      <StatusBar/>
      <ObProgress step={3} label="Découverte"/>
      <div style={{ padding: '24px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ flex: 1, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {/* boarding pass mini */}
          <div style={{
            width: 290, transform: 'rotate(-3deg)',
            borderRadius: 20, overflow: 'hidden',
            background: `linear-gradient(155deg, ${T.bg2} 0%, ${T.bg1} 100%)`,
            border: `1px solid ${T.borderStrong}`,
            boxShadow: '0 30px 60px rgba(15,5,35,0.55)',
          }}>
            <div style={{ padding: '14px 18px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: `1px dashed ${T.border}` }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ width: 24, height: 24, borderRadius: 6, background: `linear-gradient(135deg, ${T.accent2}, ${T.accentDeep})`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 800, color: '#fff' }}>AF</div>
                <span style={{ fontSize: 12, fontWeight: 700 }}>Air France · AF 6724</span>
              </div>
            </div>
            <div style={{ padding: '20px 18px', display: 'grid', gridTemplateColumns: '1fr auto 1fr', alignItems: 'center', gap: 6 }}>
              <div>
                <div style={{ fontSize: 36, fontWeight: 800, letterSpacing: -1.5, lineHeight: 1 }}>CDG</div>
                <div style={{ fontSize: 13, fontWeight: 700, marginTop: 6 }}>13:25</div>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                <div style={{ fontSize: 9, color: T.textDim, fontWeight: 700, letterSpacing: 1 }}>12h 05</div>
                <I.plane size={18} stroke={T.accent2}/>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 36, fontWeight: 800, letterSpacing: -1.5, lineHeight: 1 }}>NRT</div>
                <div style={{ fontSize: 13, fontWeight: 700, marginTop: 6 }}>11:30+1</div>
              </div>
            </div>
            <div style={{ padding: '12px 18px 16px' }}>
              <div style={{ display: 'flex', gap: 1, height: 28 }}>
                {Array.from({ length: 50 }).map((_, i) => (
                  <div key={i} style={{ width: 1 + (i % 3), height: '100%', background: i % 7 === 0 ? 'transparent' : T.text, opacity: 0.8 }}/>
                ))}
              </div>
            </div>
          </div>
          {/* small ticket behind */}
          <div style={{
            position: 'absolute', width: 240, height: 90, borderRadius: 14,
            background: T.surface, border: `1px solid ${T.border}`,
            top: 30, left: 32, transform: 'rotate(6deg)',
            zIndex: -1, opacity: 0.5,
          }}/>
        </div>
        <div>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>VOLS · BOARDING PASS</div>
          <div style={{ fontSize: 32, fontWeight: 800, letterSpacing: -1, marginTop: 8, lineHeight: 1.05 }}>
            Tes vols, parfaitement<br/>rangés.
          </div>
          <div style={{ fontSize: 15, color: T.textMute, marginTop: 12, lineHeight: 1.4 }}>
            Tous tes billets au même endroit. Rappels, sièges, portes — on s'occupe de tout.
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 24 }}>
            <Dots active={1}/>
            <CTA style={{ width: 120, height: 48, fontSize: 14 }}>Suivant →</CTA>
          </div>
        </div>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 04 · VALUE — Spots & memories
// ───────────────────────────────────────────────────────────────
function OB04_Spots() {
  return (
    <Screen>
      <StatusBar/>
      <ObProgress step={4} label="Découverte"/>
      <div style={{ padding: '24px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ flex: 1, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {/* polaroid stack */}
          {[
            { hue: 25, label: 'Lisbonne', date: 'mai 2025', rot: -8, x: -60, y: -10, z: 1 },
            { hue: 160, label: 'Bali', date: 'janv. 2024', rot: 5, x: 40, y: 30, z: 2 },
            { hue: 220, label: 'Islande', date: 'mars 2025', rot: -2, x: -10, y: 60, z: 3 },
          ].map((p, i) => (
            <div key={i} style={{
              position: 'absolute',
              transform: `translate(${p.x}px, ${p.y}px) rotate(${p.rot}deg)`,
              background: '#1a1138', padding: 10, paddingBottom: 28,
              borderRadius: 6, border: `1px solid ${T.border}`,
              boxShadow: '0 22px 40px rgba(0,0,0,0.5)',
              zIndex: p.z,
            }}>
              <DestPhoto label={p.label} hue={p.hue} w={150} h={150} radius={2}/>
              <div style={{ position: 'absolute', bottom: 6, left: 12, fontSize: 11, color: T.textMute, fontFamily: 'ui-monospace, monospace' }}>{p.label} · {p.date}</div>
            </div>
          ))}
        </div>
        <div>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>SPOTS · SOUVENIRS</div>
          <div style={{ fontSize: 32, fontWeight: 800, letterSpacing: -1, marginTop: 8, lineHeight: 1.05 }}>
            Chaque voyage,<br/>un souvenir.
          </div>
          <div style={{ fontSize: 15, color: T.textMute, marginTop: 12, lineHeight: 1.4 }}>
            Sauvegarde les lieux qui comptent et garde une trace visuelle de chaque aventure.
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 24 }}>
            <Dots active={2}/>
            <CTA style={{ width: 120, height: 48, fontSize: 14 }}>Continuer →</CTA>
          </div>
        </div>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 05 · SOCIAL PROOF
// ───────────────────────────────────────────────────────────────
function OB05_Social() {
  return (
    <Screen>
      <StatusBar/>
      <ObProgress step={5} label="Communauté"/>
      <div style={{ padding: '28px 28px 36px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        {/* Big stat */}
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>REJOINS LE VOL</div>
          <div style={{ fontSize: 64, fontWeight: 800, letterSpacing: -2.5, marginTop: 8, lineHeight: 1, background: `linear-gradient(180deg, #fff 0%, ${T.accent2} 100%)`, WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>52 480</div>
          <div style={{ fontSize: 15, color: T.textMute, marginTop: 4 }}>voyageurs ont planifié avec Tripnest</div>

          {/* avatars row */}
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 18 }}>
            {[T.rose, T.gold, T.mint, T.blue, T.accent2].map((c, i) => (
              <div key={i} style={{
                width: 32, height: 32, borderRadius: '50%',
                background: `linear-gradient(135deg, ${c}, ${T.accentDeep})`,
                border: '2px solid #150a2a',
                marginLeft: i === 0 ? 0 : -10,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 12, fontWeight: 800, color: '#fff',
              }}>{['SM','TL','JD','CR','AB'][i]}</div>
            ))}
            <div style={{
              width: 32, height: 32, borderRadius: '50%',
              background: T.bg2, border: `2px solid #150a2a`,
              marginLeft: -10, display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 10, fontWeight: 700, color: T.text,
            }}>+50k</div>
          </div>

          {/* rating */}
          <div style={{ marginTop: 18, display: 'inline-flex', alignItems: 'center', gap: 6, padding: '8px 14px', borderRadius: 999, background: 'rgba(245,193,80,0.10)', border: '1px solid rgba(245,193,80,0.25)' }}>
            <div style={{ display: 'flex', gap: 1 }}>
              {Array.from({ length: 5 }).map((_, i) => <I.star key={i} size={14} stroke={T.gold} fill={T.gold}/>)}
            </div>
            <span style={{ fontSize: 13, fontWeight: 700, color: T.gold }}>4,9</span>
            <span style={{ fontSize: 12, color: T.textMute }}>· 8 240 avis</span>
          </div>
        </div>

        {/* testimonials */}
        <div style={{ flex: 1, marginTop: 22, display: 'flex', flexDirection: 'column', gap: 10, overflowY: 'auto' }}>
          {[
            { n: 'Sarah · Bordeaux', q: '« J\'ai économisé 600€ sur mon Japon. Le suivi de budget est addictif. »', av: T.rose },
            { n: 'Tom · Lyon', q: '« L\'app que j\'attendais depuis 5 ans. Mes vols, mon budget, tout en un. »', av: T.blue },
            { n: 'Julie · Paris', q: '« Mes 30 voyages enfin rangés. Le souvenir préféré : Bali. »', av: T.mint },
          ].map(t => (
            <Card key={t.n} padding={14}>
              <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                <div style={{
                  width: 36, height: 36, borderRadius: '50%', flexShrink: 0,
                  background: `linear-gradient(135deg, ${t.av}, ${T.accentDeep})`,
                  border: `1.5px solid ${T.borderStrong}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 12, fontWeight: 800, color: '#fff',
                }}>{t.n.split(' ')[0][0]}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 700 }}>{t.n}</div>
                  <div style={{ display: 'flex', gap: 1, marginTop: 2 }}>
                    {Array.from({ length: 5 }).map((_, i) => <I.star key={i} size={10} stroke={T.gold} fill={T.gold}/>)}
                  </div>
                  <div style={{ fontSize: 13, color: T.textMute, marginTop: 6, lineHeight: 1.4 }}>{t.q}</div>
                </div>
              </div>
            </Card>
          ))}
        </div>
        <div style={{ marginTop: 16 }}>
          <CTA>Personnaliser mon expérience</CTA>
        </div>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 06 · Q1 — How do you travel
// ───────────────────────────────────────────────────────────────
function OB06_Travel() {
  return (
    <Screen>
      <StatusBar/>
      <ObProgress step={6} label="Personnalisation"/>
      <div style={{ padding: '24px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>Q1 · TON STYLE</div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.1 }}>Avec qui voyages-tu<br/>le plus souvent ?</div>
        <div style={{ fontSize: 14, color: T.textMute, marginTop: 6 }}>On adapte tes budgets et suggestions.</div>

        <div style={{ flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 24, alignContent: 'start' }}>
          {[
            { emoji: '🧍', l: 'Solo', d: 'Indépendant·e', active: true, c: T.accent2 },
            { emoji: '💑', l: 'En couple', d: 'Voyage à deux', c: T.rose },
            { emoji: '👨‍👩‍👧', l: 'En famille', d: 'Avec enfants', c: T.gold },
            { emoji: '👫', l: 'Entre amis', d: 'Groupe', c: T.mint },
          ].map(o => (
            <button key={o.l} style={{
              all: 'unset', cursor: 'pointer',
              padding: 18, borderRadius: 20, aspectRatio: '1',
              background: o.active ? `linear-gradient(160deg, ${o.c}22, ${o.c}05)` : T.surface,
              border: o.active ? `1.5px solid ${o.c}80` : `1px solid ${T.border}`,
              display: 'flex', flexDirection: 'column', justifyContent: 'space-between', position: 'relative',
              boxShadow: o.active ? `0 16px 32px ${o.c}33` : 'none',
            }}>
              <div style={{ fontSize: 38 }}>{o.emoji}</div>
              <div>
                <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: -0.3 }}>{o.l}</div>
                <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>{o.d}</div>
              </div>
              {o.active && (
                <div style={{ position: 'absolute', top: 12, right: 12, width: 24, height: 24, borderRadius: '50%', background: o.c, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <I.check size={14} stroke="#fff" sw={2.5}/>
                </div>
              )}
            </button>
          ))}
        </div>
        <CTA style={{ marginTop: 16 }}>Continuer</CTA>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 07 · Q2 — Frequency
// ───────────────────────────────────────────────────────────────
function OB07_Frequency() {
  return (
    <Screen>
      <StatusBar/>
      <ObProgress step={7} label="Personnalisation"/>
      <div style={{ padding: '24px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>Q2 · FRÉQUENCE</div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.1 }}>À quelle fréquence<br/>pars-tu en voyage ?</div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10, marginTop: 24 }}>
          {[
            { l: 'Plusieurs fois par an', d: '4+ voyages', emoji: '🚀', active: true },
            { l: 'Une à deux fois par an', d: '1–2 voyages', emoji: '🌤️' },
            { l: 'Un grand voyage par an', d: 'Long séjour, 2–4 sem.', emoji: '🏝️' },
            { l: 'Plus rarement', d: 'Mais je rêve fort', emoji: '✨' },
          ].map(o => (
            <button key={o.l} style={{
              all: 'unset', cursor: 'pointer',
              padding: '18px 18px', borderRadius: 18,
              background: o.active ? 'rgba(139,92,246,0.12)' : T.surface,
              border: o.active ? `1.5px solid ${T.accent2}80` : `1px solid ${T.border}`,
              display: 'flex', gap: 14, alignItems: 'center',
            }}>
              <div style={{ fontSize: 28 }}>{o.emoji}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 16, fontWeight: 700 }}>{o.l}</div>
                <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>{o.d}</div>
              </div>
              <div style={{
                width: 24, height: 24, borderRadius: '50%',
                border: `1.5px solid ${o.active ? T.accent2 : T.border}`,
                background: o.active ? T.accent2 : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{o.active && <I.check size={14} stroke="#fff" sw={2.5}/>}</div>
            </button>
          ))}
        </div>
        <CTA>Continuer</CTA>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 08 · Q3 — Budget slider
// ───────────────────────────────────────────────────────────────
function OB08_BudgetQ() {
  const value = 1850;
  const min = 500, max = 6000;
  const pct = (value - min) / (max - min) * 100;
  return (
    <Screen>
      <StatusBar/>
      <ObProgress step={8} label="Personnalisation"/>
      <div style={{ padding: '24px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>Q3 · BUDGET</div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.1 }}>Quel est ton budget<br/>moyen par voyage ?</div>
        <div style={{ fontSize: 14, color: T.textMute, marginTop: 6 }}>Hors transport longue distance.</div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 26 }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 80, fontWeight: 800, letterSpacing: -3.5, lineHeight: 1,
              background: `linear-gradient(180deg, #fff 0%, ${T.accent2} 100%)`,
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
              {value.toLocaleString('fr')}€
            </div>
            <div style={{ fontSize: 13, color: T.textMute, marginTop: 4 }}>≈ 230 € / jour pour 8 jours</div>
          </div>

          {/* slider */}
          <div style={{ width: '100%', padding: '0 6px' }}>
            <div style={{ position: 'relative', height: 8, background: 'rgba(167,139,250,0.15)', borderRadius: 4 }}>
              <div style={{ position: 'absolute', left: 0, top: 0, height: '100%', width: `${pct}%`, background: `linear-gradient(90deg, ${T.accent2}, ${T.accent})`, borderRadius: 4 }}/>
              <div style={{
                position: 'absolute', left: `calc(${pct}% - 14px)`, top: -10, width: 28, height: 28, borderRadius: '50%',
                background: '#fff', boxShadow: `0 6px 14px ${T.accent}66, 0 0 0 6px rgba(167,139,250,0.18)`,
                border: `3px solid ${T.accent}`,
              }}/>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 16, fontSize: 11, color: T.textMute }}>
              <span>500€</span><span>1500€</span><span>3000€</span><span>6000€+</span>
            </div>
          </div>

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center' }}>
            <Pill>Backpack &lt;1k</Pill>
            <Pill active>Confort 1–3k</Pill>
            <Pill>Luxe 3k+</Pill>
          </div>
        </div>
        <CTA>Continuer</CTA>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 09 · Q4 — Dream destinations (multi-select)
// ───────────────────────────────────────────────────────────────
function OB09_Dreams() {
  const dests = [
    { f: '🇯🇵', n: 'Japon', hue: 340, on: true },
    { f: '🇲🇦', n: 'Maroc', hue: 50, on: true },
    { f: '🇲🇽', n: 'Mexique', hue: 20 },
    { f: '🇮🇩', n: 'Bali', hue: 160, on: true },
    { f: '🇮🇸', n: 'Islande', hue: 220 },
    { f: '🇵🇹', n: 'Portugal', hue: 25 },
    { f: '🇻🇳', n: 'Vietnam', hue: 130 },
    { f: '🇮🇹', n: 'Italie', hue: 15 },
    { f: '🇵🇪', n: 'Pérou', hue: 90, on: true },
  ];
  return (
    <Screen>
      <StatusBar/>
      <ObProgress step={9} label="Personnalisation"/>
      <div style={{ padding: '24px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>Q4 · INSPIRATION</div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.1 }}>Tes destinations<br/>de rêve ?</div>
        <div style={{ fontSize: 14, color: T.textMute, marginTop: 6 }}>Sélectionnes-en au moins 3.</div>

        <div style={{ flex: 1, marginTop: 20, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, alignContent: 'start' }}>
          {dests.map(d => (
            <button key={d.n} style={{
              all: 'unset', cursor: 'pointer', position: 'relative',
              borderRadius: 14, overflow: 'hidden', aspectRatio: '1',
              border: d.on ? `2px solid ${T.accent2}` : `1px solid ${T.border}`,
              boxShadow: d.on ? `0 10px 24px rgba(139,92,246,0.35)` : 'none',
            }}>
              <DestPhoto label={d.n} hue={d.hue} w="100%" h="100%" radius={0}/>
              <div style={{ position: 'absolute', inset: 0, background: d.on ? 'linear-gradient(180deg, rgba(139,92,246,0.15) 0%, rgba(14,6,32,0.85) 100%)' : 'linear-gradient(180deg, transparent 40%, rgba(14,6,32,0.7) 100%)' }}/>
              <div style={{ position: 'absolute', top: 8, left: 8, fontSize: 20 }}>{d.f}</div>
              {d.on && (
                <div style={{ position: 'absolute', top: 8, right: 8, width: 22, height: 22, borderRadius: '50%', background: T.accent2, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <I.check size={12} stroke="#fff" sw={3}/>
                </div>
              )}
              <div style={{ position: 'absolute', bottom: 8, left: 8, right: 8, fontSize: 13, fontWeight: 700, color: '#fff', letterSpacing: -0.2 }}>{d.n}</div>
            </button>
          ))}
        </div>
        <div style={{ fontSize: 12, color: T.accent2, fontWeight: 600, textAlign: 'center', marginTop: 12 }}>4 sélectionnées</div>
        <CTA>Continuer</CTA>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 10 · Q5 — Notifications
// ───────────────────────────────────────────────────────────────
function OB10_Notifs() {
  const items = [
    { l: 'Rappels de vol', d: '24h avant chaque départ', i: I.plane, c: T.accent2, on: true },
    { l: 'Dépassement de budget', d: 'On t\'alerte avant les 100%', i: I.wallet, c: T.gold, on: true },
    { l: 'Spots à proximité', d: 'Suggestions selon ta position', i: I.spot, c: T.rose, on: false },
    { l: 'Souvenirs anniversaires', d: '1 an depuis ton voyage à…', i: I.heart, c: T.mint, on: true },
    { l: 'Hebdo · inspiration', d: 'Lundi · idées de destinations', i: I.sun, c: T.blue, on: false },
  ];
  return (
    <Screen>
      <StatusBar/>
      <ObProgress step={10} label="Personnalisation"/>
      <div style={{ padding: '24px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>Q5 · NOTIFICATIONS</div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.1 }}>Qu'est-ce qu'on<br/>te rappelle ?</div>
        <div style={{ fontSize: 14, color: T.textMute, marginTop: 6 }}>Tu peux changer plus tard.</div>

        <div style={{ flex: 1, marginTop: 20, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {items.map(it => (
            <Card key={it.l} padding={14}>
              <div style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
                <div style={{ width: 40, height: 40, borderRadius: 12, background: `${it.c}22`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <it.i size={18} stroke={it.c}/>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 700 }}>{it.l}</div>
                  <div style={{ fontSize: 12, color: T.textMute, marginTop: 1 }}>{it.d}</div>
                </div>
                {/* toggle */}
                <div style={{
                  width: 42, height: 26, borderRadius: 999,
                  background: it.on ? T.accent : 'rgba(167,139,250,0.15)',
                  position: 'relative', transition: 'background .2s',
                  border: `1px solid ${it.on ? T.accent : T.border}`,
                }}>
                  <div style={{
                    position: 'absolute', top: 2, left: it.on ? 18 : 2,
                    width: 20, height: 20, borderRadius: '50%', background: '#fff',
                    transition: 'left .2s', boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
                  }}/>
                </div>
              </div>
            </Card>
          ))}
        </div>
        <CTA>Activer les notifications</CTA>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 11 · LOADING / building your profile
// ───────────────────────────────────────────────────────────────
function OB11_Loading() {
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '40px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 44px)', justifyContent: 'space-between' }}>
        <div/>
        <div style={{ textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24 }}>
          {/* spinning planes ring */}
          <div style={{ position: 'relative', width: 200, height: 200 }}>
            <div style={{ position: 'absolute', inset: 0, borderRadius: '50%',
              background: 'radial-gradient(circle, rgba(139,92,246,0.25) 0%, transparent 70%)' }}/>
            <ProgressRing value={72} max={100} size={200} stroke={6} color={T.accent2} trackColor="rgba(167,139,250,0.10)">
              <Logo size={92}/>
            </ProgressRing>
            {/* orbit dots */}
            {[0, 72, 144, 216, 288].map(deg => (
              <div key={deg} style={{
                position: 'absolute', top: '50%', left: '50%',
                transform: `translate(-50%, -50%) rotate(${deg}deg) translateY(-100px) rotate(-${deg}deg)`,
              }}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                  <path d="M3.5 12.5L21 4l-5 17-4-7-7-1.5z" fill={T.accent2}/>
                </svg>
              </div>
            ))}
          </div>

          <div>
            <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8 }}>On prépare ton profil</div>
            <div style={{ fontSize: 14, color: T.textMute, marginTop: 8, maxWidth: 280, margin: '8px auto 0' }}>
              Analyse de tes préférences, calcul de ton budget idéal…
            </div>
          </div>

          <div style={{ width: '100%', maxWidth: 300, display: 'flex', flexDirection: 'column', gap: 10, marginTop: 4 }}>
            {[
              { l: 'Style de voyage analysé', done: true },
              { l: 'Budget moyen calibré', done: true },
              { l: 'Recommandations en cours…', done: false, busy: true },
            ].map(s => (
              <div key={s.l} style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 13, color: s.done ? T.text : T.textMute }}>
                <div style={{
                  width: 18, height: 18, borderRadius: '50%',
                  background: s.done ? T.mint : 'rgba(167,139,250,0.15)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {s.done ? <I.check size={12} stroke="#0e0620" sw={3}/> : (
                    <div style={{ width: 8, height: 8, borderRadius: '50%', background: T.accent2 }}/>
                  )}
                </div>
                {s.l}
              </div>
            ))}
          </div>
        </div>
        <div style={{ fontSize: 11, color: T.textDim, textAlign: 'center' }}>72% · Quelques secondes…</div>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 12 · REVEAL personalized plan
// ───────────────────────────────────────────────────────────────
function OB12_Reveal() {
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '24px 28px 30px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 44px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>TON PLAN PERSONNALISÉ</div>
        <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: -1, marginTop: 8, lineHeight: 1.05 }}>Ton premier voyage,<br/>déjà esquissé.</div>
        <div style={{ fontSize: 14, color: T.textMute, marginTop: 8 }}>Basé sur tes goûts. Modifiable à tout moment.</div>

        <div style={{ marginTop: 20, borderRadius: 22, overflow: 'hidden', position: 'relative', border: `1px solid ${T.borderStrong}` }}>
          <DestPhoto label="Tokyo · Shibuya" hue={340} h={180} radius={0}/>
          <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg, rgba(14,6,32,0.2) 0%, rgba(14,6,32,0.85) 90%)' }}/>
          <div style={{ position: 'absolute', top: 14, left: 14, padding: '4px 10px', borderRadius: 8, background: 'rgba(245,193,80,0.18)', border: '1px solid rgba(245,193,80,0.3)', fontSize: 11, fontWeight: 700, color: T.gold, letterSpacing: 1 }}>RECOMMANDÉ POUR TOI</div>
          <div style={{ position: 'absolute', bottom: 14, left: 14, right: 14 }}>
            <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.8, color: '#fff' }}>Tokyo 🇯🇵</div>
            <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.7)' }}>14 jours · sept. 2025</div>
          </div>
        </div>

        <Card padding={16} style={{ marginTop: 12 }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
            {[
              ['Budget', '4 200€', T.accent2],
              ['Vols', 'dès 720€', T.blue],
              ['Spots', '18 idées', T.rose],
            ].map(([k, v, c]) => (
              <div key={k}>
                <div style={{ fontSize: 11, color: T.textMute, fontWeight: 600 }}>{k}</div>
                <div style={{ fontSize: 18, fontWeight: 800, marginTop: 3, color: c, letterSpacing: -0.4 }}>{v}</div>
              </div>
            ))}
          </div>
        </Card>

        <Card padding={14} style={{ marginTop: 10 }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.textMute, letterSpacing: 1 }}>STARTERS POUR TOI</div>
          <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
            {['Shibuya neon', 'Onsen Hakone', 'Marché Tsukiji', 'Kyoto · 3j', 'Studio Ghibli'].map(s => (
              <Pill key={s}>{s}</Pill>
            ))}
          </div>
        </Card>

        <div style={{ flex: 1 }}/>
        <CTA>Activer mon plan Tripnest</CTA>
        <CTA ghost style={{ marginTop: 4 }}>Plus tard</CTA>
      </div>
    </Screen>
  );
}

// ───────────────────────────────────────────────────────────────
// 13 · PAYWALL — soft trial
// ───────────────────────────────────────────────────────────────
function OB13_Paywall() {
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '8px 22px', display: 'flex', justifyContent: 'flex-end' }}>
        <button style={{
          all: 'unset', cursor: 'pointer',
          width: 32, height: 32, borderRadius: '50%',
          background: T.surface, border: `1px solid ${T.border}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><I.close size={14} stroke={T.textMute}/></button>
      </div>
      <div style={{ padding: '8px 24px 30px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 88px)' }}>
        <div style={{ textAlign: 'center', marginTop: 4 }}>
          <div style={{ display: 'inline-flex', padding: '5px 12px', borderRadius: 999, background: 'rgba(245,193,80,0.12)', border: '1px solid rgba(245,193,80,0.3)', alignItems: 'center', gap: 4 }}>
            <span style={{ fontSize: 11 }}>✨</span>
            <span style={{ fontSize: 11, fontWeight: 700, color: T.gold, letterSpacing: 1 }}>TRIPNEST PRO · 7 JOURS OFFERTS</span>
          </div>
          <div style={{ fontSize: 32, fontWeight: 800, letterSpacing: -1, marginTop: 14, lineHeight: 1.05 }}>Décolle avec<br/>tout débloqué.</div>
        </div>

        {/* benefits */}
        <Card padding={18} style={{ marginTop: 18 }}>
          {[
            ['Voyages illimités', 'Au lieu de 2 sur le plan gratuit'],
            ['Spots & cartes hors ligne', 'Pas de réseau ? Pas de souci.'],
            ['Conversions de devises temps réel', 'Sur 180+ monnaies'],
            ['Souvenirs photo illimités', 'Export albums PDF'],
            ['Synchronisation web', 'Continue sur ordinateur'],
          ].map(([l, d]) => (
            <div key={l} style={{ display: 'flex', gap: 12, alignItems: 'flex-start', padding: '8px 0' }}>
              <div style={{ width: 22, height: 22, borderRadius: '50%', background: 'rgba(134,239,172,0.15)', border: '1px solid rgba(134,239,172,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: 1 }}>
                <I.check size={12} stroke={T.mint} sw={3}/>
              </div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{l}</div>
                <div style={{ fontSize: 11, color: T.textMute, marginTop: 1 }}>{d}</div>
              </div>
            </div>
          ))}
        </Card>

        {/* plans */}
        <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <PlanRow l="Annuel" sub="4,99€/mois · facturé 59,90€" save="−45%" active/>
          <PlanRow l="Mensuel" sub="8,99€/mois · annulable à tout moment"/>
        </div>

        <div style={{ flex: 1 }}/>
        <CTA style={{ marginTop: 14 }}>Commencer mes 7 jours offerts</CTA>
        <div style={{ fontSize: 11, color: T.textDim, textAlign: 'center', marginTop: 10, lineHeight: 1.4 }}>
          Aucun engagement · Annulable en 1 tap.<br/>Rappel avant facturation.
        </div>
      </div>
    </Screen>
  );
}

function PlanRow({ l, sub, save, active }) {
  return (
    <div style={{
      padding: 14, borderRadius: 16, position: 'relative',
      background: active ? 'rgba(139,92,246,0.14)' : T.surface,
      border: active ? `1.5px solid ${T.accent}` : `1px solid ${T.border}`,
      display: 'flex', alignItems: 'center', gap: 14,
    }}>
      <div style={{
        width: 22, height: 22, borderRadius: '50%',
        border: `1.5px solid ${active ? T.accent : T.border}`,
        background: active ? T.accent : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{active && <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#fff' }}/>}</div>
      <div style={{ flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 16, fontWeight: 700 }}>{l}</span>
          {save && <span style={{ fontSize: 10, fontWeight: 800, color: T.mint, background: 'rgba(134,239,172,0.15)', padding: '3px 7px', borderRadius: 6, letterSpacing: 0.5 }}>{save}</span>}
        </div>
        <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>{sub}</div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────────────────
// 14 · ACCOUNT CREATE
// ───────────────────────────────────────────────────────────────
function OB14_Account() {
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '8px 22px', display: 'flex', justifyContent: 'space-between' }}>
        <button style={{ all: 'unset', cursor: 'pointer', color: T.textMute, fontSize: 13, fontWeight: 600 }}>← Retour</button>
        <div style={{ fontSize: 11, color: T.textMute, fontWeight: 700, letterSpacing: 1.5 }}>14 / 15</div>
        <div style={{ width: 40 }}/>
      </div>

      <div style={{ padding: '20px 28px 30px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <Logo size={64}/>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8, marginTop: 18, lineHeight: 1.1 }}>Crée ton compte<br/>pour sauvegarder.</div>
        <div style={{ fontSize: 14, color: T.textMute, marginTop: 8 }}>30 secondes. Tu retrouves tout sur tous tes appareils.</div>

        {/* social */}
        <div style={{ marginTop: 22, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <SocialBtn label="Continuer avec Apple" icon="" dark/>
          <SocialBtn label="Continuer avec Google" icon="G"/>
        </div>

        {/* divider */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '18px 0' }}>
          <div style={{ flex: 1, height: 1, background: T.border }}/>
          <span style={{ fontSize: 11, color: T.textDim, letterSpacing: 1.5, fontWeight: 700 }}>OU PAR EMAIL</span>
          <div style={{ flex: 1, height: 1, background: T.border }}/>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <Field label="EMAIL" placeholder="lea@tripnest.app"/>
          <Field label="MOT DE PASSE" placeholder="Au moins 8 caractères"/>
          <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start', marginTop: 4 }}>
            <div style={{ width: 20, height: 20, borderRadius: 5, background: T.accent, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: 1 }}>
              <I.check size={12} stroke="#fff" sw={3}/>
            </div>
            <div style={{ fontSize: 11, color: T.textMute, lineHeight: 1.4 }}>
              J'accepte les <span style={{ color: T.accent2, fontWeight: 600 }}>conditions</span> et la <span style={{ color: T.accent2, fontWeight: 600 }}>politique de confidentialité</span>
            </div>
          </div>
        </div>

        <div style={{ flex: 1 }}/>
        <CTA>Créer mon compte</CTA>
      </div>
    </Screen>
  );
}

function SocialBtn({ label, icon, dark }) {
  return (
    <button style={{
      width: '100%', height: 52, borderRadius: 14,
      background: dark ? '#000' : '#fff',
      color: dark ? '#fff' : '#0e0620',
      border: `1px solid ${dark ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.1)'}`,
      fontSize: 15, fontWeight: 700,
      fontFamily: T.font,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
      cursor: 'pointer',
    }}>
      {dark ? (
        <svg width="18" height="20" viewBox="0 0 384 512" fill="#fff"><path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"/></svg>
      ) : (
        <div style={{
          width: 20, height: 20, borderRadius: '50%',
          background: 'conic-gradient(from 0deg, #ea4335, #fbbc05, #34a853, #4285f4, #ea4335)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 11, fontWeight: 900, color: '#fff',
        }}>G</div>
      )}
      {label}
    </button>
  );
}

// ───────────────────────────────────────────────────────────────
// 15 · SUCCESS — Bienvenue
// ───────────────────────────────────────────────────────────────
function OB15_Success() {
  return (
    <Screen>
      <StatusBar/>
      {/* burst */}
      <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none' }}>
        {Array.from({ length: 28 }).map((_, i) => {
          const angle = (i / 28) * Math.PI * 2;
          const r = 130 + (i % 4) * 70;
          const x = 50 + Math.cos(angle) * (r / 4);
          const y = 35 + Math.sin(angle) * (r / 5);
          const colors = [T.accent2, T.rose, T.gold, T.mint, T.blue];
          const c = colors[i % 5];
          const rot = (i * 37) % 360;
          return (
            <svg key={i} width="14" height="14" viewBox="0 0 24 24" fill="none"
              style={{ position: 'absolute', left: `${x}%`, top: `${y}%`, opacity: 0.85, transform: `rotate(${rot}deg)` }}>
              <path d="M3.5 12.5L21 4l-5 17-4-7-7-1.5z" fill={c}/>
            </svg>
          );
        })}
      </div>

      <div style={{ padding: '40px 28px 36px', height: 'calc(100% - 44px)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', position: 'relative', zIndex: 1 }}>
        <div/>
        <div style={{ textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18 }}>
          <div style={{ position: 'relative' }}>
            <div style={{ position: 'absolute', inset: -30, borderRadius: '50%',
              background: 'radial-gradient(circle, rgba(139,92,246,0.4) 0%, transparent 70%)' }}/>
            <Logo size={130}/>
            <div style={{
              position: 'absolute', bottom: -4, right: -4,
              width: 42, height: 42, borderRadius: '50%',
              background: T.mint, border: '4px solid #0e0620',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><I.check size={20} stroke="#0e0620" sw={3}/></div>
          </div>

          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2.5, marginBottom: 12 }}>TOUT EST PRÊT ✦</div>
            <div style={{ fontSize: 42, fontWeight: 800, letterSpacing: -1.6, lineHeight: 1 }}>Bienvenue,<br/>Léa.</div>
            <div style={{ fontSize: 16, color: T.textMute, marginTop: 14, lineHeight: 1.4, padding: '0 4px' }}>
              Ton premier voyage t'attend.<br/>Le ciel ne t'a jamais semblé plus proche.
            </div>
          </div>

          <Card padding={14} style={{ marginTop: 8 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ width: 40, height: 40, borderRadius: 11, background: 'rgba(245,193,80,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22 }}>🎁</div>
              <div style={{ textAlign: 'left' }}>
                <div style={{ fontSize: 13, fontWeight: 700 }}>Cadeau de bienvenue</div>
                <div style={{ fontSize: 11, color: T.textMute }}>7 jours Pro · activés</div>
              </div>
            </div>
          </Card>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <CTA>Entrer dans Tripnest →</CTA>
          <CTA ghost>Importer mes voyages passés</CTA>
        </div>
      </div>
    </Screen>
  );
}

Object.assign(window, {
  OB01_Welcome, OB02_Budget, OB03_Flights, OB04_Spots, OB05_Social,
  OB06_Travel, OB07_Frequency, OB08_BudgetQ, OB09_Dreams, OB10_Notifs,
  OB11_Loading, OB12_Reveal, OB13_Paywall, OB14_Account, OB15_Success,
  ObProgress, CTA, SocialBtn, Dots, PlanRow,
});
