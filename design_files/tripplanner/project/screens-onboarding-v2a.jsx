// Tripnest · Hard onboarding funnel v2 — 29 screens
// Phases : Hook(1) → Reflection(2-4) → Qualifying(5-10) → Goals+Commitment(11-15)
//          → Affirmation+Proof(16-19) → Plan(20-24) → Lock-in(25-26) → Hard paywall(27-29)
// Part A : screens 01-15 (hook + reflection + qualifying + goals)

const TOTAL = 29;

// ── reusable progress header ──────────────────────────────────
function OBHeader({ step, label, hideSkip, onBack }) {
  return (
    <div style={{ padding: '6px 22px 0' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <button style={{ all: 'unset', cursor: 'pointer',
          width: 32, height: 32, borderRadius: '50%',
          background: T.surface, border: `1px solid ${T.border}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><I.back size={14} stroke={T.textMute}/></button>
        <div style={{ flex: 1, padding: '0 14px' }}>
          <div style={{ height: 4, borderRadius: 3, background: 'rgba(167,139,250,0.12)', overflow: 'hidden' }}>
            <div style={{ width: `${step / TOTAL * 100}%`, height: '100%',
              background: `linear-gradient(90deg, ${T.accent2}, ${T.accent})`,
              boxShadow: `0 0 8px ${T.accent2}`,
              transition: 'width .4s' }}/>
          </div>
          <div style={{ fontSize: 10, color: T.textDim, marginTop: 4, textAlign: 'center', letterSpacing: 1, fontWeight: 700 }}>
            Étape {step} / {TOTAL}{label ? ` · ${label.toUpperCase()}` : ''}
          </div>
        </div>
        <div style={{ width: 32 }}/>
      </div>
    </div>
  );
}

function Q({ subtitle, title, hint, children, cta = 'Continuer', step, label, footer, secondary }) {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={step} label={label}/>
      <div style={{ padding: '20px 26px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        {subtitle && <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>{subtitle}</div>}
        <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.1 }}>{title}</div>
        {hint && <div style={{ fontSize: 13, color: T.textMute, marginTop: 6 }}>{hint}</div>}
        <div style={{ flex: 1, marginTop: 20, display: 'flex', flexDirection: 'column' }}>{children}</div>
        {footer}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginTop: 12 }}>
          {secondary && <CTA ghost>{secondary}</CTA>}
          <CTA>{cta}</CTA>
        </div>
      </div>
    </Screen>
  );
}

// Card option (single-select). Spread props for active state.
function OptCard({ emoji, l, d, active, color = T.accent2 }) {
  return (
    <button style={{
      all: 'unset', cursor: 'pointer',
      padding: '16px 16px', borderRadius: 16,
      background: active ? `${color}1c` : T.surface,
      border: active ? `1.5px solid ${color}` : `1px solid ${T.border}`,
      display: 'flex', gap: 14, alignItems: 'center',
      boxShadow: active ? `0 12px 24px ${color}33` : 'none',
    }}>
      {emoji && <div style={{ fontSize: 26 }}>{emoji}</div>}
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 15, fontWeight: 700 }}>{l}</div>
        {d && <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>{d}</div>}
      </div>
      <div style={{
        width: 22, height: 22, borderRadius: '50%',
        border: `1.5px solid ${active ? color : T.border}`,
        background: active ? color : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{active && <I.check size={13} stroke="#fff" sw={3}/>}</div>
    </button>
  );
}

// Multi check
function MultiCard({ emoji, l, d, active, color = T.accent2 }) {
  return (
    <button style={{
      all: 'unset', cursor: 'pointer',
      padding: '14px 14px', borderRadius: 14,
      background: active ? `${color}1c` : T.surface,
      border: active ? `1.5px solid ${color}` : `1px solid ${T.border}`,
      display: 'flex', gap: 12, alignItems: 'center',
    }}>
      {emoji && <div style={{ fontSize: 22 }}>{emoji}</div>}
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 14, fontWeight: 700 }}>{l}</div>
        {d && <div style={{ fontSize: 11, color: T.textMute, marginTop: 1 }}>{d}</div>}
      </div>
      <div style={{
        width: 22, height: 22, borderRadius: 6,
        border: `1.5px solid ${active ? color : T.border}`,
        background: active ? color : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{active && <I.check size={13} stroke="#fff" sw={3}/>}</div>
    </button>
  );
}

// ═════════════════════════════════════════════════════════════
// 01 · HOOK / Welcome
// ═════════════════════════════════════════════════════════════
function V2_01() {
  return (
    <Screen>
      <StatusBar/>
      <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none' }}>
        {[
          { x: 15, y: 18, s: 28, r: -20, op: 0.20 },
          { x: 78, y: 22, s: 20, r: 30, op: 0.28 },
          { x: 22, y: 70, s: 16, r: 10, op: 0.22 },
          { x: 84, y: 76, s: 24, r: -40, op: 0.18 },
        ].map((p, i) => (
          <svg key={i} width={p.s * 4} height={p.s * 4} viewBox="0 0 24 24" fill="none"
            style={{ position: 'absolute', left: `${p.x}%`, top: `${p.y}%`, opacity: p.op, transform: `rotate(${p.r}deg)` }}>
            <path d="M3.5 12.5L21 4l-5 17-4-7-7-1.5z" fill="#a78bfa" stroke="#c4b5fd" strokeWidth="0.5"/>
          </svg>
        ))}
      </div>
      <div style={{ position: 'relative', height: 'calc(100% - 44px)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: '40px 28px 36px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 22, marginTop: 30 }}>
          <Logo size={120}/>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 2.5, color: T.accent2, marginBottom: 14 }}>BIENVENUE</div>
            <div style={{ fontSize: 44, fontWeight: 800, letterSpacing: -1.6, lineHeight: 1 }}>Voyage<br/>sans stress<span style={{ color: T.accent2 }}>.</span></div>
            <div style={{ fontSize: 15, color: T.textMute, marginTop: 18, lineHeight: 1.45, padding: '0 12px' }}>
              On va te poser quelques questions.<br/>2 minutes pour construire ton plan voyage.
            </div>
          </div>
          {/* trust strip */}
          <div style={{ marginTop: 4, display: 'flex', alignItems: 'center', gap: 10, padding: '8px 14px', borderRadius: 999, background: T.surface, border: `1px solid ${T.border}` }}>
            <div style={{ display: 'flex' }}>
              {[T.rose, T.gold, T.mint, T.blue].map((c, i) => (
                <div key={i} style={{ width: 22, height: 22, borderRadius: '50%', background: `linear-gradient(135deg, ${c}, ${T.accentDeep})`, border: '1.5px solid #150a2a', marginLeft: i === 0 ? 0 : -8 }}/>
              ))}
            </div>
            <span style={{ fontSize: 11, color: T.text, fontWeight: 600 }}>52 480 voyageurs · </span>
            <I.star size={11} stroke={T.gold} fill={T.gold}/>
            <span style={{ fontSize: 11, color: T.gold, fontWeight: 700 }}>4,9</span>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <CTA>Construire mon plan voyage</CTA>
          <CTA ghost>J'ai déjà un compte</CTA>
        </div>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 02 · REFLECTION — pourquoi
// ═════════════════════════════════════════════════════════════
function V2_02() {
  return (
    <Q step={2} label="Réflexion"
      subtitle="POUR COMMENCER"
      title={<>Pourquoi as-tu téléchargé<br/>Tripnest aujourd'hui ?</>}
      hint="Une seule réponse — celle qui te ressemble le plus."
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <OptCard emoji="💸" l="Économiser sur mes voyages" d="J'ai déjà dépassé mon budget une fois de trop" active color={T.accent2}/>
        <OptCard emoji="🗺️" l="Mieux m'organiser" d="Mes voyages sont chaotiques" color={T.rose}/>
        <OptCard emoji="🌍" l="Voir plus du monde" d="J'ai des destinations en tête à concrétiser" color={T.blue}/>
        <OptCard emoji="📸" l="Garder mes souvenirs" d="Mes voyages partent dans l'oubli" color={T.gold}/>
        <OptCard emoji="✈️" l="Tout ça à la fois" color={T.mint}/>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 03 · REFLECTION — défi le plus gros
// ═════════════════════════════════════════════════════════════
function V2_03() {
  return (
    <Q step={3} label="Réflexion"
      subtitle="TON DÉFI"
      title={<>Quel est ton plus gros défi<br/>quand tu voyages ?</>}
      hint="Sois honnête — c'est ce qu'on va régler ensemble."
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <OptCard emoji="💸" l="Dépasser mon budget" d="Je perds le contrôle vite" active color={T.gold}/>
        <OptCard emoji="📋" l="Oublier les détails" d="Réservations, horaires, documents" color={T.rose}/>
        <OptCard emoji="🤯" l="Tout planifier en amont" d="Trop d'onglets, trop d'apps" color={T.blue}/>
        <OptCard emoji="📷" l="Garder une trace propre" d="Mes photos s'éparpillent" color={T.mint}/>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 04 · AFFIRMATION — pas seul·e
// ═════════════════════════════════════════════════════════════
function V2_04() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={4} label="Tu n'es pas seul·e"/>
      <div style={{ padding: '20px 26px 30px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>TU N'ES PAS SEUL·E</div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.9, marginTop: 8, lineHeight: 1.05 }}>
          7 voyageurs sur 10<br/>dépassent leur budget<span style={{ color: T.gold }}>.</span>
        </div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 18 }}>
          {/* big stat visual */}
          <div style={{ position: 'relative', padding: '20px 0' }}>
            <div style={{ display: 'flex', gap: 6, justifyContent: 'center', flexWrap: 'wrap', maxWidth: 280, margin: '0 auto' }}>
              {Array.from({ length: 10 }).map((_, i) => (
                <div key={i} style={{
                  width: 38, height: 56, borderRadius: 8,
                  background: i < 7 ? 'rgba(245,193,80,0.18)' : T.surface,
                  border: `1.5px solid ${i < 7 ? 'rgba(245,193,80,0.4)' : T.border}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22,
                }}>{i < 7 ? '😰' : '😎'}</div>
              ))}
            </div>
            <div style={{ textAlign: 'center', marginTop: 12, fontSize: 11, color: T.textMute, fontWeight: 600 }}>
              Source · enquête INSEE 2024 sur les vacances
            </div>
          </div>

          <Card padding={16} style={{ background: 'rgba(245,193,80,0.06)', border: '1px solid rgba(245,193,80,0.18)' }}>
            <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
              <div style={{ fontSize: 28 }}>💡</div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 700, color: T.gold }}>Le saviez-vous</div>
                <div style={{ fontSize: 13, color: T.text, marginTop: 4, lineHeight: 1.45 }}>
                  Les voyageurs qui suivent leur budget en temps réel économisent <b>en moyenne 312€</b> par voyage.
                </div>
              </div>
            </div>
          </Card>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <CTA>Je veux faire partie des 3 sur 10 →</CTA>
        </div>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 05 · QUALIFYING — Style
// ═════════════════════════════════════════════════════════════
function V2_05() {
  return (
    <Q step={5} label="Personnalisation"
      subtitle="Q1 · TON STYLE"
      title={<>Avec qui voyages-tu<br/>le plus souvent ?</>}
    >
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {[
          { e: '🧍', l: 'Solo', d: 'Indépendant·e', active: true, c: T.accent2 },
          { e: '💑', l: 'En couple', d: 'Voyage à deux', c: T.rose },
          { e: '👨‍👩‍👧', l: 'En famille', d: 'Avec enfants', c: T.gold },
          { e: '👫', l: 'Entre amis', d: 'Groupe', c: T.mint },
        ].map(o => (
          <button key={o.l} style={{
            all: 'unset', cursor: 'pointer',
            padding: 18, borderRadius: 18, aspectRatio: '1',
            background: o.active ? `${o.c}1f` : T.surface,
            border: o.active ? `1.5px solid ${o.c}` : `1px solid ${T.border}`,
            display: 'flex', flexDirection: 'column', justifyContent: 'space-between', position: 'relative',
            boxShadow: o.active ? `0 14px 28px ${o.c}33` : 'none',
          }}>
            <div style={{ fontSize: 36 }}>{o.e}</div>
            <div>
              <div style={{ fontSize: 16, fontWeight: 700 }}>{o.l}</div>
              <div style={{ fontSize: 11, color: T.textMute, marginTop: 1 }}>{o.d}</div>
            </div>
            {o.active && (
              <div style={{ position: 'absolute', top: 12, right: 12, width: 22, height: 22, borderRadius: '50%', background: o.c, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <I.check size={12} stroke="#fff" sw={3}/>
              </div>
            )}
          </button>
        ))}
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 06 · QUALIFYING — Fréquence
// ═════════════════════════════════════════════════════════════
function V2_06() {
  return (
    <Q step={6} label="Personnalisation"
      subtitle="Q2 · FRÉQUENCE"
      title={<>À quelle fréquence<br/>pars-tu en voyage ?</>}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <OptCard emoji="🚀" l="Plusieurs fois par an" d="4+ voyages" active/>
        <OptCard emoji="🌤️" l="Une à deux fois par an" d="1–2 voyages"/>
        <OptCard emoji="🏝️" l="Un grand voyage par an" d="Long séjour"/>
        <OptCard emoji="✨" l="Plus rarement, mais je rêve" d=""/>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 07 · QUALIFYING — Déjà dépassé ton budget ?  (commits pain)
// ═════════════════════════════════════════════════════════════
function V2_07() {
  return (
    <Q step={7} label="Vérité"
      subtitle="Q3 · MOMENT DE VÉRITÉ"
      title={<>As-tu déjà dépassé ton<br/>budget en voyage ?</>}
      hint="Pas de jugement. Juste pour calibrer ton plan."
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 30 }}>
        <OptCard emoji="😅" l="Oui, plusieurs fois" d="C'est même devenu une habitude" active color={T.gold}/>
        <OptCard emoji="🙃" l="Oui, une fois ou deux" d="Et c'est pour ça que je suis ici"/>
        <OptCard emoji="🤔" l="Je ne sais pas" d="Je ne suis pas vraiment mon budget"/>
        <OptCard emoji="🧘" l="Non, jamais" d="Mais je veux optimiser quand même"/>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 08 · QUALIFYING — De combien ?  (anchors the pain in €)
// ═════════════════════════════════════════════════════════════
function V2_08() {
  const val = 380; // anchored
  const pct = (val - 50) / (1500 - 50) * 100;
  return (
    <Q step={8} label="Vérité"
      subtitle="Q4 · DE COMBIEN"
      title={<>De combien as-tu dépassé<br/>en moyenne ?</>}
    >
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 26 }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 84, fontWeight: 800, letterSpacing: -3.5, lineHeight: 1,
            background: `linear-gradient(180deg, ${T.gold} 0%, ${T.accent} 100%)`,
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
            ~{val}€
          </div>
          <div style={{ fontSize: 13, color: T.textMute, marginTop: 6 }}>par voyage en moyenne</div>
        </div>
        <div style={{ width: '100%', padding: '0 6px' }}>
          <div style={{ position: 'relative', height: 8, background: 'rgba(167,139,250,0.15)', borderRadius: 4 }}>
            <div style={{ position: 'absolute', left: 0, top: 0, height: '100%', width: `${pct}%`, background: `linear-gradient(90deg, ${T.gold}, ${T.accent})`, borderRadius: 4 }}/>
            <div style={{
              position: 'absolute', left: `calc(${pct}% - 14px)`, top: -10, width: 28, height: 28, borderRadius: '50%',
              background: '#fff', boxShadow: `0 6px 14px ${T.accent}66, 0 0 0 6px rgba(167,139,250,0.18)`,
              border: `3px solid ${T.accent}`,
            }}/>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 14, fontSize: 11, color: T.textMute }}>
            <span>moins de 100€</span><span>500€</span><span>1500€+</span>
          </div>
        </div>
        <Card padding={12} style={{ background: 'rgba(244,114,182,0.06)', border: '1px solid rgba(244,114,182,0.18)' }}>
          <div style={{ fontSize: 12, color: T.text, textAlign: 'center', lineHeight: 1.4 }}>
            Sur 4 voyages par an, ça fait <b style={{ color: T.rose }}>1 520€ par an</b> de perte.
          </div>
        </Card>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 09 · QUALIFYING — Outils actuels (creates dissatisfaction)
// ═════════════════════════════════════════════════════════════
function V2_09() {
  return (
    <Q step={9} label="État des lieux"
      subtitle="Q5 · TES OUTILS"
      title={<>Comment t'organises-tu<br/>aujourd'hui ?</>}
      hint="Plusieurs choix possibles."
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <MultiCard emoji="📊" l="Une feuille Excel / Google Sheets" d="Toujours obsolète, jamais à jour" active/>
        <MultiCard emoji="📝" l="L'app Notes" d="Tout est en vrac" active color={T.rose}/>
        <MultiCard emoji="💳" l="L'app de ma banque" d="Catégories pas adaptées au voyage"/>
        <MultiCard emoji="🤷" l="Rien de précis" d="Je fais au feeling" color={T.gold}/>
        <MultiCard emoji="🧮" l="Une autre app" d="Mais ça ne me convient pas" color={T.blue}/>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 10 · QUALIFYING — Frustrations (multi, intensifies pain)
// ═════════════════════════════════════════════════════════════
function V2_10() {
  return (
    <Q step={10} label="État des lieux"
      subtitle="Q6 · CE QUI TE FRUSTRE"
      title={<>Qu'est-ce qui te frustre<br/>le plus avec ces outils ?</>}
      hint="Plusieurs choix possibles."
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <MultiCard emoji="🕰️" l="Trop de temps à saisir" d="Je finis par ne plus le faire" active/>
        <MultiCard emoji="💱" l="Les conversions de devises" d="Je ne sais jamais où j'en suis" active color={T.gold}/>
        <MultiCard emoji="📵" l="Pas de mode hors-ligne" d="Inutile en plein voyage"/>
        <MultiCard emoji="🌫️" l="Aucune vision d'ensemble" d="Je découvre les dégâts au retour" active color={T.rose}/>
        <MultiCard emoji="📍" l="Je perds les lieux découverts" d="Adresses oubliées, restos perdus" color={T.blue}/>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 11 · GOALS — Objectif principal (commitment)
// ═════════════════════════════════════════════════════════════
function V2_11() {
  return (
    <Q step={11} label="Ton objectif"
      subtitle="OBJECTIF PRINCIPAL"
      title={<>Quel est ton objectif<br/>numéro 1 cette année ?</>}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <OptCard emoji="💰" l="Économiser 500€+ sur mes voyages" d="Plus de marge, moins de stress" active color={T.gold}/>
        <OptCard emoji="🗺️" l="Visiter 3 nouvelles destinations" d="Sortir de ma zone" color={T.rose}/>
        <OptCard emoji="📅" l="Mieux planifier mes vacances" d="Anticiper, ne plus subir" color={T.blue}/>
        <OptCard emoji="🌍" l="Faire le voyage de ma vie" d="Cette année, c'est la bonne" color={T.mint}/>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 12 · GOALS — Budget moyen par voyage
// ═════════════════════════════════════════════════════════════
function V2_12() {
  const v = 1850; const min = 500, max = 6000;
  const pct = (v - min) / (max - min) * 100;
  return (
    <Q step={12} label="Ton objectif"
      subtitle="TON BUDGET MOYEN"
      title={<>Combien dépenses-tu<br/>par voyage en moyenne ?</>}
      hint="Hors transport longue distance. Estime au mieux."
    >
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 30 }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 78, fontWeight: 800, letterSpacing: -3.5, lineHeight: 1,
            background: `linear-gradient(180deg, #fff 0%, ${T.accent2} 100%)`,
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>{v.toLocaleString('fr')}€</div>
          <div style={{ fontSize: 13, color: T.textMute, marginTop: 4 }}>≈ 230€ / jour pour 8 jours</div>
        </div>
        <div style={{ width: '100%', padding: '0 6px' }}>
          <div style={{ position: 'relative', height: 8, background: 'rgba(167,139,250,0.15)', borderRadius: 4 }}>
            <div style={{ position: 'absolute', left: 0, top: 0, height: '100%', width: `${pct}%`, background: `linear-gradient(90deg, ${T.accent2}, ${T.accent})`, borderRadius: 4 }}/>
            <div style={{ position: 'absolute', left: `calc(${pct}% - 14px)`, top: -10, width: 28, height: 28, borderRadius: '50%', background: '#fff', boxShadow: `0 6px 14px ${T.accent}66, 0 0 0 6px rgba(167,139,250,0.18)`, border: `3px solid ${T.accent}` }}/>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 14, fontSize: 11, color: T.textMute }}>
            <span>500€</span><span>1500€</span><span>3000€</span><span>6000€+</span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <Pill>Backpack</Pill>
          <Pill active>Confort</Pill>
          <Pill>Luxe</Pill>
        </div>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 13 · GOALS — Destinations rêvées (visual investment)
// ═════════════════════════════════════════════════════════════
function V2_13() {
  const d = [
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
    <Q step={13} label="Inspiration"
      subtitle="DESTINATIONS RÊVÉES"
      title={<>Où as-tu envie d'aller<br/>en priorité ?</>}
      hint="Choisis au moins 3 destinations."
      cta="Continuer (4 choisies)"
    >
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginTop: 4 }}>
        {d.map(x => (
          <button key={x.n} style={{
            all: 'unset', cursor: 'pointer', position: 'relative',
            borderRadius: 12, overflow: 'hidden', aspectRatio: '1',
            border: x.on ? `2px solid ${T.accent2}` : `1px solid ${T.border}`,
            boxShadow: x.on ? `0 10px 24px rgba(139,92,246,0.35)` : 'none',
          }}>
            <DestPhoto label={x.n} hue={x.hue} w="100%" h="100%" radius={0}/>
            <div style={{ position: 'absolute', inset: 0, background: x.on ? 'linear-gradient(180deg, rgba(139,92,246,0.15) 0%, rgba(14,6,32,0.85) 100%)' : 'linear-gradient(180deg, transparent 40%, rgba(14,6,32,0.7) 100%)' }}/>
            <div style={{ position: 'absolute', top: 6, left: 6, fontSize: 18 }}>{x.f}</div>
            {x.on && (<div style={{ position: 'absolute', top: 6, right: 6, width: 20, height: 20, borderRadius: '50%', background: T.accent2, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><I.check size={11} stroke="#fff" sw={3}/></div>)}
            <div style={{ position: 'absolute', bottom: 6, left: 6, right: 6, fontSize: 12, fontWeight: 700, color: '#fff' }}>{x.n}</div>
          </button>
        ))}
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 14 · COMMITMENT — Prochain voyage (data entry = sunk cost)
// ═════════════════════════════════════════════════════════════
function V2_14() {
  return (
    <Q step={14} label="Engagement"
      subtitle="TON PROCHAIN VOYAGE"
      title={<>As-tu un voyage<br/>prévu ou en tête ?</>}
      hint="On l'utilise pour construire ton premier plan."
      cta="Construire mon plan"
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, marginBottom: 8 }}>DESTINATION</div>
          <div style={{
            height: 54, borderRadius: 14, padding: '0 16px',
            background: T.surface, border: `1.5px solid ${T.borderStrong}`,
            display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: 22 }}>🇯🇵</span>
              <span style={{ fontSize: 16, fontWeight: 600 }}>Tokyo, Japon</span>
            </div>
            <I.search size={18} stroke={T.textMute}/>
          </div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, marginBottom: 8 }}>DÉPART</div>
            <div style={{ height: 54, borderRadius: 14, padding: '0 14px', background: T.surface, border: `1px solid ${T.borderStrong}`, display: 'flex', alignItems: 'center', gap: 8 }}>
              <I.cal size={16} stroke={T.accent2}/>
              <span style={{ fontSize: 14, fontWeight: 600 }}>04 sept.</span>
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, marginBottom: 8 }}>RETOUR</div>
            <div style={{ height: 54, borderRadius: 14, padding: '0 14px', background: T.surface, border: `1px solid ${T.borderStrong}`, display: 'flex', alignItems: 'center', gap: 8 }}>
              <I.cal size={16} stroke={T.accent2}/>
              <span style={{ fontSize: 14, fontWeight: 600 }}>18 sept.</span>
            </div>
          </div>
        </div>
        <div>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, marginBottom: 8 }}>BUDGET ENVISAGÉ</div>
          <div style={{ height: 54, borderRadius: 14, padding: '0 16px', background: T.surface, border: `1px solid ${T.borderStrong}`, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ fontSize: 16, fontWeight: 700 }}>4 200 €</span>
            <Pill active style={{ pointerEvents: 'none' }}>14 jours</Pill>
          </div>
        </div>
        <button style={{
          all: 'unset', cursor: 'pointer', textAlign: 'center',
          fontSize: 13, color: T.textMute, fontWeight: 600, padding: '6px 0',
        }}>Je n'ai pas encore de plan précis →</button>
      </div>
    </Q>
  );
}

// ═════════════════════════════════════════════════════════════
// 15 · COMMITMENT — Objectif d'économie chiffré
// ═════════════════════════════════════════════════════════════
function V2_15() {
  const save = 620;
  const pct = (save - 100) / (2000 - 100) * 100;
  return (
    <Q step={15} label="Engagement"
      subtitle="TON OBJECTIF D'ÉCONOMIE"
      title={<>Combien veux-tu économiser<br/>sur ton prochain voyage ?</>}
      hint="Sois ambitieux·se. On va t'y aider."
    >
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 26 }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 12, color: T.mint, fontWeight: 700, letterSpacing: 2 }}>OBJECTIF</div>
          <div style={{ fontSize: 78, fontWeight: 800, letterSpacing: -3.5, lineHeight: 1, marginTop: 6,
            background: `linear-gradient(180deg, ${T.mint} 0%, ${T.accent2} 100%)`,
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
            −{save}€
          </div>
          <div style={{ fontSize: 13, color: T.textMute, marginTop: 4 }}>soit 15% de ton budget Tokyo</div>
        </div>
        <div style={{ width: '100%', padding: '0 6px' }}>
          <div style={{ position: 'relative', height: 8, background: 'rgba(167,139,250,0.15)', borderRadius: 4 }}>
            <div style={{ position: 'absolute', left: 0, top: 0, height: '100%', width: `${pct}%`, background: `linear-gradient(90deg, ${T.mint}, ${T.accent2})`, borderRadius: 4 }}/>
            <div style={{ position: 'absolute', left: `calc(${pct}% - 14px)`, top: -10, width: 28, height: 28, borderRadius: '50%', background: '#fff', boxShadow: `0 6px 14px ${T.accent}66, 0 0 0 6px rgba(167,139,250,0.18)`, border: `3px solid ${T.mint}` }}/>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 14, fontSize: 11, color: T.textMute }}>
            <span>100€</span><span>500€</span><span>1000€</span><span>2000€</span>
          </div>
        </div>
        <Card padding={14} style={{ background: 'rgba(134,239,172,0.06)', border: '1px solid rgba(134,239,172,0.18)' }}>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            <div style={{ fontSize: 28 }}>🎯</div>
            <div style={{ fontSize: 13, color: T.text, lineHeight: 1.4 }}>
              <b style={{ color: T.mint }}>Réaliste</b> — c'est exactement ce que les utilisateurs Tripnest comme toi économisent en moyenne.
            </div>
          </div>
        </Card>
      </div>
    </Q>
  );
}

Object.assign(window, {
  V2_01, V2_02, V2_03, V2_04, V2_05, V2_06, V2_07, V2_08,
  V2_09, V2_10, V2_11, V2_12, V2_13, V2_14, V2_15,
  OBHeader, Q, OptCard, MultiCard, TOTAL,
});
