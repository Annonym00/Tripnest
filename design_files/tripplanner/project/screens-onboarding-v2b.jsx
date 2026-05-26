// Tripnest · Hard onboarding funnel v2 — Part B
// Screens 16-29 · Affirmation → Plan reveal → Lock-in → Hard paywall → Success

// ═════════════════════════════════════════════════════════════
// 16 · AFFIRMATION — Tu as ce qu'il faut (mirror back)
// ═════════════════════════════════════════════════════════════
function V2_16() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={16} label="Tu as ce qu'il faut"/>
      <div style={{ padding: '20px 26px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.mint, letterSpacing: 2 }}>BONNE NOUVELLE</div>
        <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: -0.9, marginTop: 8, lineHeight: 1.05 }}>
          Tu as tout pour réussir<br/>ton objectif<span style={{ color: T.mint }}>.</span>
        </div>
        <div style={{ fontSize: 14, color: T.textMute, marginTop: 8 }}>
          On a analysé tes réponses. Voici ce qu'on voit.
        </div>

        <div style={{ flex: 1, marginTop: 22, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Card padding={16}>
            <div style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
              <div style={{ width: 48, height: 48, borderRadius: 14, background: 'rgba(139,92,246,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24 }}>🎯</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, color: T.textMute }}>Ton objectif</div>
                <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: -0.3, marginTop: 1 }}>Économiser <span style={{ color: T.mint }}>620€</span> sur Tokyo</div>
              </div>
            </div>
          </Card>
          <Card padding={16}>
            <div style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
              <div style={{ width: 48, height: 48, borderRadius: 14, background: 'rgba(125,211,252,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24 }}>🧠</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, color: T.textMute }}>Ton profil</div>
                <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: -0.3, marginTop: 1 }}>Voyageuse Confort · Solo</div>
              </div>
            </div>
          </Card>
          <Card padding={16}>
            <div style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
              <div style={{ width: 48, height: 48, borderRadius: 14, background: 'rgba(244,114,182,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24 }}>💪</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, color: T.textMute }}>Ta motivation</div>
                <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: -0.3, marginTop: 1 }}>Forte — top 12%</div>
              </div>
            </div>
          </Card>
          <Card padding={16} style={{ background: 'rgba(134,239,172,0.06)', border: '1px solid rgba(134,239,172,0.18)' }}>
            <div style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
              <div style={{ width: 48, height: 48, borderRadius: 14, background: 'rgba(134,239,172,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24 }}>📈</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, color: T.mint, fontWeight: 700 }}>Notre prédiction</div>
                <div style={{ fontSize: 14, marginTop: 4, lineHeight: 1.4 }}>
                  Avec Tripnest, tu peux atteindre <b style={{ color: T.mint }}>92% de ton objectif</b> dès le premier voyage.
                </div>
              </div>
            </div>
          </Card>
        </div>
        <CTA>Voir mon plan personnalisé →</CTA>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 17 · SOCIAL PROOF — Témoignages utilisateurs similaires
// ═════════════════════════════════════════════════════════════
function V2_17() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={17} label="Ils l'ont fait"/>
      <div style={{ padding: '20px 26px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>ILS ÉTAIENT COMME TOI</div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.05 }}>
          Voyageurs solo confort —<br/>voici ce qu'ils ont gagné.
        </div>

        <div style={{ flex: 1, marginTop: 22, display: 'flex', flexDirection: 'column', gap: 12, overflowY: 'auto' }}>
          {[
            { n: 'Sarah, 28 ans', city: 'Bordeaux', dest: 'Japon · 2 sem.', saved: '740€', q: 'J\'avais peur de me ruiner. Tripnest m\'a vraiment fait économiser. Je suis rentrée avec 740€ de marge.', c: T.rose },
            { n: 'Marc, 34 ans', city: 'Lyon', dest: 'Vietnam · 3 sem.', saved: '510€', q: 'Premier voyage où je sais exactement combien je dépense en temps réel. Game changer.', c: T.blue },
            { n: 'Camille, 31 ans', city: 'Paris', dest: 'Maroc · 10 jours', saved: '380€', q: 'J\'ai même réussi à me payer un soin au hammam grâce à ce que j\'ai économisé sur la bouffe.', c: T.gold },
          ].map(t => (
            <Card key={t.n} padding={16}>
              <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                <div style={{
                  width: 44, height: 44, borderRadius: '50%', flexShrink: 0,
                  background: `linear-gradient(135deg, ${t.c}, ${T.accentDeep})`,
                  border: `1.5px solid ${T.borderStrong}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 14, fontWeight: 800, color: '#fff',
                }}>{t.n[0]}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                    <span style={{ fontSize: 14, fontWeight: 700 }}>{t.n}</span>
                    <span style={{ fontSize: 11, color: T.textMute }}>{t.city}</span>
                  </div>
                  <div style={{ fontSize: 11, color: T.textMute, marginTop: 1 }}>{t.dest} · économisé <b style={{ color: T.mint }}>{t.saved}</b></div>
                  <div style={{ display: 'flex', gap: 1, marginTop: 4 }}>
                    {Array.from({ length: 5 }).map((_, i) => <I.star key={i} size={10} stroke={T.gold} fill={T.gold}/>)}
                  </div>
                  <div style={{ fontSize: 13, color: T.textMute, marginTop: 6, lineHeight: 1.4 }}>« {t.q} »</div>
                </div>
              </div>
            </Card>
          ))}
        </div>
        <CTA>Suivant →</CTA>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 18 · COMMUNITY — Tu rejoins une vraie communauté
// ═════════════════════════════════════════════════════════════
function V2_18() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={18} label="La communauté"/>
      <div style={{ padding: '24px 26px 30px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>UNE VRAIE COMMUNAUTÉ</div>
          <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: -0.9, marginTop: 8, lineHeight: 1.05 }}>Tu rejoins<br/>52 480 voyageurs.</div>
        </div>

        {/* big stat */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 18 }}>
          <div style={{ position: 'relative', textAlign: 'center', padding: '24px 0' }}>
            <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle, rgba(139,92,246,0.30) 0%, transparent 65%)' }}/>
            <div style={{ fontSize: 80, fontWeight: 800, letterSpacing: -3, lineHeight: 1, position: 'relative',
              background: `linear-gradient(180deg, #fff 0%, ${T.accent2} 100%)`,
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>+18M€</div>
            <div style={{ fontSize: 13, color: T.textMute, marginTop: 4, position: 'relative' }}>économisés par la communauté en 2025</div>
          </div>

          <Card padding={4}>
            {[
              [I.globe, '74 pays', 'couverts'],
              [I.spot, '142 380', 'spots sauvés'],
              [I.plane, '24 800', 'vols suivis'],
              [I.heart, '4,9 / 5', '8 240 avis App Store'],
            ].map(([Ic, v, l], i, arr) => (
              <div key={l} style={{ padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 14, borderBottom: i < arr.length - 1 ? `1px solid ${T.border}` : 'none' }}>
                <div style={{ width: 36, height: 36, borderRadius: 11, background: 'rgba(139,92,246,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Ic size={16} stroke={T.accent2}/>
                </div>
                <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>{l}</div>
                <div style={{ fontSize: 17, fontWeight: 800, letterSpacing: -0.4, color: T.accent2 }}>{v}</div>
              </div>
            ))}
          </Card>

          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 14px', borderRadius: 14, background: 'rgba(244,114,182,0.06)', border: '1px solid rgba(244,114,182,0.18)' }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: T.mint, boxShadow: `0 0 8px ${T.mint}` }}/>
            <div style={{ fontSize: 12, color: T.text, lineHeight: 1.3 }}>
              <b>148 voyageurs</b> ont rejoint Tripnest aujourd'hui.
            </div>
          </div>
        </div>

        <CTA>Je rejoins l'aventure →</CTA>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 19 · AFFIRMATION — Plan en construction promise (build anticipation)
// ═════════════════════════════════════════════════════════════
function V2_19() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={19} label="On y est presque"/>
      <div style={{ padding: '24px 26px 30px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>DERNIÈRE LIGNE DROITE</div>
        <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: -0.9, marginTop: 8, lineHeight: 1.05 }}>
          On va construire ton plan<br/>en 4 étapes<span style={{ color: T.accent2 }}>.</span>
        </div>

        <div style={{ flex: 1, marginTop: 26, display: 'flex', flexDirection: 'column', gap: 14 }}>
          {[
            { n: '01', l: 'Analyse de ton profil', d: 'On croise tes 15 réponses', done: true },
            { n: '02', l: 'Calibrage de ton budget', d: 'On ajuste pour Tokyo · 14 jours', done: true },
            { n: '03', l: 'Recommandations de spots', d: 'Sélection adaptée à ton style', busy: true },
            { n: '04', l: 'Stratégie d\'économie', d: 'On planifie tes 620€ d\'économie', wait: true },
          ].map(s => (
            <div key={s.n} style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
              <div style={{
                width: 46, height: 46, borderRadius: 14, flexShrink: 0,
                background: s.done ? T.mint : s.busy ? 'rgba(139,92,246,0.18)' : T.surface,
                border: `1px solid ${s.done ? T.mint : s.busy ? T.accent2 : T.border}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 13, fontWeight: 800,
                color: s.done ? '#0e0620' : s.busy ? T.accent2 : T.textDim,
              }}>{s.done ? <I.check size={20} stroke="#0e0620" sw={3}/> : s.n}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 700, color: s.wait ? T.textMute : T.text }}>{s.l}</div>
                <div style={{ fontSize: 12, color: T.textMute, marginTop: 1 }}>{s.d}</div>
              </div>
              {s.busy && <div style={{ fontSize: 11, color: T.accent2, fontWeight: 700, letterSpacing: 1 }}>EN COURS</div>}
            </div>
          ))}
        </div>

        <CTA>Lancer la construction →</CTA>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 20 · LOADING — Analyse profile (multi-step animation feel)
// ═════════════════════════════════════════════════════════════
function V2_20() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={20} label="Construction · 1/4"/>
      <div style={{ padding: '40px 26px 30px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)', justifyContent: 'space-between' }}>
        <div/>
        <div style={{ textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22 }}>
          <div style={{ position: 'relative', width: 200, height: 200 }}>
            <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: 'radial-gradient(circle, rgba(139,92,246,0.30) 0%, transparent 70%)' }}/>
            <ProgressRing value={28} max={100} size={200} stroke={6} color={T.accent2}>
              <div style={{ fontSize: 11, color: T.textMute, fontWeight: 700, letterSpacing: 1 }}>ANALYSE</div>
              <div style={{ fontSize: 48, fontWeight: 800, letterSpacing: -2 }}>28%</div>
            </ProgressRing>
            {[0, 90, 180, 270].map(deg => (
              <div key={deg} style={{
                position: 'absolute', top: '50%', left: '50%',
                transform: `translate(-50%, -50%) rotate(${deg}deg) translateY(-100px) rotate(-${deg}deg)`,
              }}><svg width="12" height="12" viewBox="0 0 24 24" fill="none"><path d="M3.5 12.5L21 4l-5 17-4-7-7-1.5z" fill={T.accent2}/></svg></div>
            ))}
          </div>

          <div>
            <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: -0.7 }}>Analyse de ton profil…</div>
            <div style={{ fontSize: 13, color: T.textMute, marginTop: 6, lineHeight: 1.4 }}>
              On croise tes 15 réponses pour construire un plan vraiment perso.
            </div>
          </div>

          <div style={{ width: '100%', maxWidth: 280, display: 'flex', flexDirection: 'column', gap: 8, marginTop: 4 }}>
            {[
              { l: 'Style de voyage identifié · Solo Confort', done: true },
              { l: 'Préférences extraites · 18 signaux', done: true },
              { l: 'Calcul de l\'index de motivation…', busy: true },
            ].map(s => (
              <div key={s.l} style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 12, color: s.done ? T.text : T.textMute, textAlign: 'left' }}>
                <div style={{ width: 16, height: 16, borderRadius: '50%', background: s.done ? T.mint : 'rgba(167,139,250,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  {s.done ? <I.check size={10} stroke="#0e0620" sw={3}/> : <div style={{ width: 6, height: 6, borderRadius: '50%', background: T.accent2 }}/>}
                </div>
                {s.l}
              </div>
            ))}
          </div>
        </div>
        <div style={{ fontSize: 11, color: T.textDim, textAlign: 'center' }}>Étape 1 sur 4 · ne ferme pas l'app</div>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 21 · LOADING — Calibrage budget (different animation)
// ═════════════════════════════════════════════════════════════
function V2_21() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={21} label="Construction · 2/4"/>
      <div style={{ padding: '40px 26px 30px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)', justifyContent: 'space-between' }}>
        <div/>
        <div style={{ textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24 }}>
          {/* bars chart anim */}
          <div style={{ position: 'relative', width: 220, height: 200, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-around', padding: '0 20px' }}>
            <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle, rgba(245,193,80,0.18) 0%, transparent 60%)' }}/>
            {[68, 90, 55, 78, 100, 82].map((h, i) => (
              <div key={i} style={{
                width: 24, height: h * 1.5, borderRadius: '8px 8px 2px 2px',
                background: i === 4 ? `linear-gradient(180deg, ${T.gold}, ${T.accent2})` : 'rgba(167,139,250,0.25)',
                border: i === 4 ? `1px solid ${T.gold}` : `1px solid ${T.border}`,
                boxShadow: i === 4 ? `0 8px 24px ${T.gold}55` : 'none',
                position: 'relative',
              }}>
                {i === 4 && (
                  <div style={{ position: 'absolute', top: -28, left: '50%', transform: 'translateX(-50%)',
                    padding: '3px 8px', borderRadius: 7, background: T.gold,
                    fontSize: 10, fontWeight: 800, color: '#0e0620', whiteSpace: 'nowrap',
                  }}>TOI</div>
                )}
              </div>
            ))}
          </div>

          <div>
            <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: -0.7 }}>Calibrage du budget…</div>
            <div style={{ fontSize: 13, color: T.textMute, marginTop: 6, lineHeight: 1.4, padding: '0 10px' }}>
              On compare ton budget Tokyo aux 8 240 voyageurs solo qui sont déjà partis.
            </div>
          </div>

          <Card padding={14} style={{ width: '100%', maxWidth: 320 }}>
            <div style={{ fontSize: 11, color: T.textMute, fontWeight: 700, letterSpacing: 1 }}>MICRO-INSIGHT</div>
            <div style={{ fontSize: 13, color: T.text, marginTop: 6, lineHeight: 1.4 }}>
              Ton budget de 4 200€ pour 14j à Tokyo est <b style={{ color: T.mint }}>11% plus optimisé</b> que la moyenne.
            </div>
          </Card>
        </div>
        <div style={{ fontSize: 11, color: T.textDim, textAlign: 'center' }}>Étape 2 sur 4 · ne ferme pas l'app</div>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 22 · IDENTITY — Ton profil voyageur (badge of identity)
// ═════════════════════════════════════════════════════════════
function V2_22() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={22} label="Ton profil voyageur"/>
      <div style={{ padding: '20px 26px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>ANALYSE TERMINÉE</div>
        <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: -0.9, marginTop: 8, lineHeight: 1.05 }}>Tu es une<br/><span style={{ color: T.accent2 }}>Exploratrice Stratège</span><span style={{ color: T.text }}>.</span></div>
        <div style={{ fontSize: 13, color: T.textMute, marginTop: 8 }}>1 voyageur sur 14 partage ton profil.</div>

        {/* Avatar identity card */}
        <Card padding={20} style={{ marginTop: 18, textAlign: 'center' }}>
          <div style={{ display: 'inline-block', position: 'relative' }}>
            <div style={{ position: 'absolute', inset: -16, background: 'radial-gradient(circle, rgba(139,92,246,0.30) 0%, transparent 70%)' }}/>
            <div style={{
              width: 96, height: 96, borderRadius: '50%', position: 'relative',
              background: `linear-gradient(135deg, ${T.accent2}, ${T.rose})`,
              border: `3px solid ${T.borderStrong}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 44,
            }}>🧭</div>
          </div>
          <div style={{ fontSize: 12, color: T.textMute, fontWeight: 700, letterSpacing: 1.5, marginTop: 14 }}>TYPE</div>
          <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: -0.5, marginTop: 2 }}>Exploratrice Stratège</div>
          <div style={{ fontSize: 13, color: T.textMute, marginTop: 6, lineHeight: 1.4, padding: '0 10px' }}>
            Tu aimes voyager en autonomie, mais tu veux du contrôle. Tu optimises sans sacrifier le plaisir.
          </div>

          {/* traits */}
          <div style={{ marginTop: 18, display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[
              ['Indépendance', 92],
              ['Sens du budget', 84],
              ['Soif de découverte', 96],
              ['Organisation', 71],
            ].map(([l, v]) => (
              <div key={l} style={{ textAlign: 'left' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12 }}>
                  <span style={{ color: T.textMute }}>{l}</span>
                  <span style={{ fontWeight: 700 }}>{v}%</span>
                </div>
                <div style={{ marginTop: 4, height: 4, borderRadius: 2, background: 'rgba(167,139,250,0.15)', overflow: 'hidden' }}>
                  <div style={{ width: `${v}%`, height: '100%', background: `linear-gradient(90deg, ${T.accent2}, ${T.accent})` }}/>
                </div>
              </div>
            ))}
          </div>
        </Card>

        <div style={{ flex: 1 }}/>
        <CTA>Voir mon plan de voyage →</CTA>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 23 · REVEAL — Ton plan personnalisé (la valeur visible)
// ═════════════════════════════════════════════════════════════
function V2_23() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={23} label="Ton plan"/>
      <div style={{ padding: '20px 26px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>TON PLAN PERSONNALISÉ</div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.05 }}>Tokyo · 14 jours<br/>déjà esquissé pour toi.</div>

        <div style={{ marginTop: 18, borderRadius: 22, overflow: 'hidden', position: 'relative', border: `1px solid ${T.borderStrong}` }}>
          <DestPhoto label="Tokyo · Shibuya neon" hue={340} h={170} radius={0}/>
          <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg, rgba(14,6,32,0.1) 0%, rgba(14,6,32,0.85) 90%)' }}/>
          <div style={{ position: 'absolute', top: 14, left: 14, padding: '4px 10px', borderRadius: 8, background: 'rgba(245,193,80,0.20)', border: '1px solid rgba(245,193,80,0.4)', fontSize: 11, fontWeight: 700, color: T.gold, letterSpacing: 1 }}>FAIT POUR TOI</div>
          <div style={{ position: 'absolute', bottom: 14, left: 14, right: 14 }}>
            <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.8, color: '#fff' }}>Tokyo 🇯🇵</div>
            <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.8)' }}>04 — 18 sept. · 14 jours · ton style Confort Solo</div>
          </div>
        </div>

        <Card padding={14} style={{ marginTop: 12 }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
            {[
              ['Budget', '4 200€', T.accent2],
              ['Économie', '−620€', T.mint],
              ['Spots', '18 idées', T.rose],
            ].map(([k, v, c]) => (
              <div key={k} style={{ textAlign: 'center', padding: '6px 0' }}>
                <div style={{ fontSize: 10, color: T.textMute, fontWeight: 600, letterSpacing: 0.5 }}>{k.toUpperCase()}</div>
                <div style={{ fontSize: 18, fontWeight: 800, marginTop: 2, color: c, letterSpacing: -0.4 }}>{v}</div>
              </div>
            ))}
          </div>
        </Card>

        <div style={{ marginTop: 12, fontSize: 12, fontWeight: 700, color: T.textMute, letterSpacing: 1 }}>INCLUS DANS TON PLAN</div>
        <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 6 }}>
          {[
            ['Itinéraire jour par jour', '14 jours détaillés'],
            ['18 spots recommandés', 'Restos, miradors, quartiers'],
            ['Vol optimisé', 'CDG → NRT dès 720€'],
            ['Alertes budget intelligentes', 'On t\'avertit avant 100%'],
            ['Souvenir auto-généré', 'Album photo à ton retour'],
          ].map(([l, d]) => (
            <div key={l} style={{ display: 'flex', gap: 10, alignItems: 'flex-start', padding: '6px 0' }}>
              <div style={{ width: 18, height: 18, borderRadius: '50%', background: 'rgba(134,239,172,0.18)', border: '1px solid rgba(134,239,172,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: 2 }}>
                <I.check size={11} stroke={T.mint} sw={3}/>
              </div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{l}</div>
                <div style={{ fontSize: 11, color: T.textMute, marginTop: 1 }}>{d}</div>
              </div>
            </div>
          ))}
        </div>

        <div style={{ flex: 1 }}/>
        <CTA>Continuer →</CTA>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 24 · PROJECTION — Ce que tu vas économiser sur 12 mois
// ═════════════════════════════════════════════════════════════
function V2_24() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={24} label="Projection"/>
      <div style={{ padding: '20px 26px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.mint, letterSpacing: 2 }}>PROJECTION SUR 12 MOIS</div>
        <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: -0.9, marginTop: 8, lineHeight: 1.05 }}>Avec Tripnest, tu vas<br/>économiser…</div>

        <div style={{ marginTop: 26, textAlign: 'center' }}>
          <div style={{ fontSize: 90, fontWeight: 800, letterSpacing: -4, lineHeight: 1,
            background: `linear-gradient(180deg, ${T.mint} 0%, ${T.accent2} 100%)`,
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
            textShadow: `0 0 80px ${T.mint}`,
          }}>1 248€</div>
          <div style={{ fontSize: 13, color: T.textMute, marginTop: 6 }}>sur tes 4 voyages prévus en 2025</div>
        </div>

        {/* line graph */}
        <Card padding={16} style={{ marginTop: 22 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: T.textMute, fontWeight: 600 }}>
            <span>Sans Tripnest</span>
            <span>Avec Tripnest</span>
          </div>
          <svg width="100%" height="100" viewBox="0 0 300 100" style={{ marginTop: 8 }}>
            <path d="M0 30 L60 35 L120 25 L180 40 L240 35 L300 50" stroke={T.rose} strokeWidth="2.5" fill="none" strokeDasharray="4 4" opacity="0.7"/>
            <path d="M0 30 L60 25 L120 18 L180 15 L240 8 L300 4" stroke={T.mint} strokeWidth="2.5" fill="none"/>
            <circle cx="300" cy="4" r="5" fill={T.mint}/>
            <circle cx="300" cy="50" r="4" fill={T.rose} opacity="0.7"/>
          </svg>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: T.textMute, marginTop: 4 }}>
            <span>Jan</span><span>Avr</span><span>Juil</span><span>Oct</span><span>Déc</span>
          </div>
        </Card>

        <Card padding={14} style={{ marginTop: 12, background: 'rgba(134,239,172,0.06)', border: '1px solid rgba(134,239,172,0.18)' }}>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            <div style={{ fontSize: 28 }}>🎁</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, color: T.mint, fontWeight: 700 }}>1 248€ — c'est…</div>
              <div style={{ fontSize: 13, color: T.text, marginTop: 2, lineHeight: 1.4 }}>
                Un week-end à Rome <b>+</b> 5 nuits à Lisbonne <b>+</b> ton vol Tokyo.
              </div>
            </div>
          </div>
        </Card>

        <div style={{ flex: 1 }}/>
        <CTA>Sauvegarder mon plan →</CTA>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 25 · NOTIFICATIONS — Activation (engagement lock-in)
// ═════════════════════════════════════════════════════════════
function V2_25() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={25} label="Notifications"/>
      <div style={{ padding: '20px 26px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>RAPPELS INTELLIGENTS</div>
        <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.1 }}>
          On t'aide à tenir<br/>tes objectifs.
        </div>
        <div style={{ fontSize: 13, color: T.textMute, marginTop: 6 }}>
          73% des utilisateurs qui activent les notifications atteignent leur objectif d'économie.
        </div>

        <div style={{ flex: 1, marginTop: 22, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { l: 'Alerte dépassement de budget', d: 'Avant que tu atteignes 100%', i: I.wallet, c: T.gold, on: true },
            { l: 'Rappels avant tes vols', d: '24h avant chaque départ', i: I.plane, c: T.accent2, on: true },
            { l: 'Suggestion de spots à proximité', d: 'Quand tu es sur place', i: I.spot, c: T.rose, on: true },
            { l: 'Bilan hebdo de tes économies', d: 'Le lundi matin', i: I.sun, c: T.blue, on: false },
          ].map(it => (
            <Card key={it.l} padding={14}>
              <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                <div style={{ width: 38, height: 38, borderRadius: 11, background: `${it.c}22`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <it.i size={18} stroke={it.c}/>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 700 }}>{it.l}</div>
                  <div style={{ fontSize: 11, color: T.textMute, marginTop: 1 }}>{it.d}</div>
                </div>
                <div style={{
                  width: 42, height: 26, borderRadius: 999,
                  background: it.on ? T.accent : 'rgba(167,139,250,0.15)',
                  position: 'relative', border: `1px solid ${it.on ? T.accent : T.border}`,
                }}>
                  <div style={{ position: 'absolute', top: 2, left: it.on ? 18 : 2, width: 20, height: 20, borderRadius: '50%', background: '#fff', boxShadow: '0 1px 3px rgba(0,0,0,0.2)' }}/>
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

// ═════════════════════════════════════════════════════════════
// 26 · ACCOUNT CREATION — Lock-in commitment
// ═════════════════════════════════════════════════════════════
function V2_26() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={26} label="Sauvegarde"/>
      <div style={{ padding: '20px 26px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>SAUVEGARDE TON PROFIL</div>
        <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.1 }}>
          Ne perds pas tes 25 réponses<br/>et ton plan personnalisé.
        </div>

        {/* mini summary they're about to "save" */}
        <Card padding={14} style={{ marginTop: 14, background: 'rgba(139,92,246,0.08)', border: '1px solid rgba(139,92,246,0.22)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
              <div style={{ width: 40, height: 40, borderRadius: 11, background: `linear-gradient(135deg, ${T.accent2}, ${T.rose})`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20 }}>🧭</div>
              <div>
                <div style={{ fontSize: 12, color: T.textMute }}>Profil prêt à sauvegarder</div>
                <div style={{ fontSize: 14, fontWeight: 700 }}>Exploratrice Stratège · Tokyo</div>
              </div>
            </div>
            <div style={{ fontSize: 11, fontWeight: 700, color: T.mint, background: 'rgba(134,239,172,0.12)', padding: '4px 8px', borderRadius: 7 }}>−1 248€</div>
          </div>
        </Card>

        <div style={{ marginTop: 18, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <SocialBtn label="Continuer avec Apple" dark/>
          <SocialBtn label="Continuer avec Google"/>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '14px 0' }}>
          <div style={{ flex: 1, height: 1, background: T.border }}/>
          <span style={{ fontSize: 10, color: T.textDim, letterSpacing: 1.5, fontWeight: 700 }}>OU PAR EMAIL</span>
          <div style={{ flex: 1, height: 1, background: T.border }}/>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Field label="EMAIL" placeholder="ton.email@app.com"/>
          <Field label="MOT DE PASSE" placeholder="8 caractères min."/>
        </div>

        <div style={{ flex: 1 }}/>
        <CTA>Sauvegarder mon plan</CTA>
        <div style={{ fontSize: 10, color: T.textDim, textAlign: 'center', marginTop: 8, lineHeight: 1.4 }}>
          En continuant, tu acceptes les <span style={{ color: T.accent2 }}>conditions</span> et la <span style={{ color: T.accent2 }}>confidentialité</span>.
        </div>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 27 · RECAP — Ton plan EST PRÊT (sunk cost peak)
// ═════════════════════════════════════════════════════════════
function V2_27() {
  return (
    <Screen>
      <StatusBar/>
      <OBHeader step={27} label="Récapitulatif"/>
      <div style={{ padding: '20px 26px 28px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 80px)' }}>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', fontSize: 11, fontWeight: 700, color: T.mint, letterSpacing: 2 }}>
          <I.check size={14} stroke={T.mint} sw={3}/> PROFIL SAUVEGARDÉ
        </div>
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.8, marginTop: 8, lineHeight: 1.05 }}>Ton plan complet<br/>est prêt à décoller.</div>
        <div style={{ fontSize: 13, color: T.textMute, marginTop: 6 }}>Plus qu'une étape pour le débloquer.</div>

        <div style={{ flex: 1, marginTop: 18, display: 'flex', flexDirection: 'column', gap: 8, overflowY: 'auto' }}>
          {[
            { e: '🧭', k: 'Profil voyageur', v: 'Exploratrice Stratège' },
            { e: '🎯', k: 'Objectif d\'économie', v: '620€ sur Tokyo' },
            { e: '✈️', k: 'Voyage planifié', v: 'Tokyo · 04→18 sept.' },
            { e: '💰', k: 'Budget calibré', v: '4 200€ · 14 catégories' },
            { e: '📍', k: 'Spots sélectionnés', v: '18 lieux uniques' },
            { e: '📊', k: 'Projection 12 mois', v: '−1 248€' },
            { e: '🔔', k: 'Alertes activées', v: '3 rappels intelligents' },
          ].map(s => (
            <div key={s.k} style={{
              padding: '12px 14px', borderRadius: 14, background: T.surface, border: `1px solid ${T.border}`,
              display: 'flex', gap: 12, alignItems: 'center',
            }}>
              <div style={{ fontSize: 22 }}>{s.e}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 11, color: T.textMute }}>{s.k}</div>
                <div style={{ fontSize: 14, fontWeight: 700, marginTop: 1 }}>{s.v}</div>
              </div>
              <I.check size={16} stroke={T.mint} sw={2.5}/>
            </div>
          ))}
        </div>

        <CTA>Débloquer mon plan complet →</CTA>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 28 · HARD PAYWALL — pas de "skip", pas d'option gratuite
// ═════════════════════════════════════════════════════════════
function V2_28() {
  return (
    <Screen>
      <StatusBar/>
      {/* a tiny close, intentionally discreet */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', padding: '8px 22px 0' }}>
        <button style={{
          all: 'unset', cursor: 'pointer',
          width: 24, height: 24, opacity: 0.35,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><I.close size={12} stroke={T.textMute}/></button>
      </div>

      <div style={{ padding: '6px 24px 26px', display: 'flex', flexDirection: 'column', height: 'calc(100% - 78px)' }}>
        {/* urgency banner */}
        <div style={{
          alignSelf: 'center',
          padding: '6px 14px', borderRadius: 999,
          background: 'rgba(245,193,80,0.12)', border: '1px solid rgba(245,193,80,0.35)',
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <div style={{ width: 6, height: 6, borderRadius: '50%', background: T.gold, boxShadow: `0 0 6px ${T.gold}` }}/>
          <span style={{ fontSize: 11, fontWeight: 800, color: T.gold, letterSpacing: 1 }}>OFFRE EXPIRE DANS 14:52</span>
        </div>

        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2 }}>DERNIÈRE ÉTAPE</div>
          <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: -1, marginTop: 8, lineHeight: 1.05 }}>
            Débloque ton plan<br/>
            <span style={{
              background: `linear-gradient(135deg, ${T.gold} 0%, ${T.accent2} 100%)`,
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
            }}>Tripnest Pro.</span>
          </div>
        </div>

        {/* Value reminder */}
        <Card padding={14} style={{ marginTop: 16, background: 'rgba(134,239,172,0.06)', border: '1px solid rgba(134,239,172,0.25)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: 11, color: T.mint, fontWeight: 700, letterSpacing: 1 }}>TU VAS ÉCONOMISER</div>
              <div style={{ fontSize: 28, fontWeight: 800, color: T.mint, letterSpacing: -0.8, marginTop: 2 }}>1 248€</div>
              <div style={{ fontSize: 10, color: T.textMute, marginTop: 1 }}>sur 12 mois</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 11, color: T.textMute }}>Tripnest Pro</div>
              <div style={{ fontSize: 18, fontWeight: 800, marginTop: 2 }}>59,90€/an</div>
              <div style={{ fontSize: 10, color: T.textMute }}>soit 20× moins</div>
            </div>
          </div>
        </Card>

        {/* Plans */}
        <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{
            position: 'relative', padding: 14, borderRadius: 18,
            background: `linear-gradient(160deg, rgba(139,92,246,0.20), rgba(139,92,246,0.06))`,
            border: `2px solid ${T.accent}`,
            boxShadow: `0 18px 40px rgba(139,92,246,0.30)`,
            display: 'flex', alignItems: 'center', gap: 14,
          }}>
            <div style={{ position: 'absolute', top: -10, right: 14, padding: '3px 10px', borderRadius: 6, background: T.gold, fontSize: 10, fontWeight: 800, color: '#0e0620', letterSpacing: 0.5 }}>POPULAIRE · −45%</div>
            <div style={{ width: 22, height: 22, borderRadius: '50%', border: `1.5px solid ${T.accent}`, background: T.accent, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#fff' }}/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 16, fontWeight: 800 }}>Annuel · 7 jours offerts</div>
              <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>4,99€/mois · soit 59,90€/an</div>
              <div style={{ fontSize: 10, color: T.gold, fontWeight: 700, marginTop: 4, letterSpacing: 0.5 }}>ÉCONOMISE 49€/AN VS MENSUEL</div>
            </div>
          </div>

          <div style={{
            padding: 14, borderRadius: 18,
            background: T.surface, border: `1px solid ${T.border}`,
            display: 'flex', alignItems: 'center', gap: 14, opacity: 0.85,
          }}>
            <div style={{ width: 22, height: 22, borderRadius: '50%', border: `1.5px solid ${T.border}` }}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 700 }}>Mensuel</div>
              <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>8,99€/mois · annulable</div>
            </div>
          </div>
        </div>

        <div style={{ flex: 1 }}/>

        {/* Trial timeline */}
        <Card padding={12} style={{ marginTop: 14 }}>
          <div style={{ fontSize: 11, color: T.textMute, fontWeight: 700, letterSpacing: 1 }}>COMMENT MARCHE TON ESSAI</div>
          <div style={{ marginTop: 10, display: 'flex', gap: 8 }}>
            {[
              { d: 'Aujourd\'hui', l: 'Accès complet', c: T.mint },
              { d: 'Jour 5', l: 'Rappel email', c: T.gold },
              { d: 'Jour 7', l: 'Début de l\'abo', c: T.accent2 },
            ].map((s, i) => (
              <div key={s.d} style={{ flex: 1, position: 'relative' }}>
                <div style={{ width: 10, height: 10, borderRadius: '50%', background: s.c, margin: '0 auto' }}/>
                {i < 2 && <div style={{ position: 'absolute', top: 4.5, left: '60%', right: '-40%', height: 1, background: T.border }}/>}
                <div style={{ fontSize: 10, color: T.text, fontWeight: 700, textAlign: 'center', marginTop: 6 }}>{s.d}</div>
                <div style={{ fontSize: 9, color: T.textMute, textAlign: 'center', marginTop: 1 }}>{s.l}</div>
              </div>
            ))}
          </div>
        </Card>

        <CTA style={{ marginTop: 12, height: 60, fontSize: 17 }}>Commencer mes 7 jours offerts</CTA>
        <div style={{ fontSize: 10, color: T.textDim, textAlign: 'center', marginTop: 8, lineHeight: 1.4 }}>
          Annulable à tout moment · 4,99€/mois après l'essai · Tu seras prévenu avant.
        </div>

        {/* mini trust strip */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 14, marginTop: 10, fontSize: 10, color: T.textDim }}>
          <span>🔒 Sans engagement</span>
          <span>·</span>
          <span>↩ Annulation 1-tap</span>
          <span>·</span>
          <span>⭐ 4,9</span>
        </div>
      </div>
    </Screen>
  );
}

// ═════════════════════════════════════════════════════════════
// 29 · SUCCESS — Tout est prêt
// ═════════════════════════════════════════════════════════════
function V2_29() {
  return (
    <Screen>
      <StatusBar/>
      <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none' }}>
        {Array.from({ length: 32 }).map((_, i) => {
          const angle = (i / 32) * Math.PI * 2;
          const r = 130 + (i % 5) * 60;
          const x = 50 + Math.cos(angle) * (r / 4);
          const y = 38 + Math.sin(angle) * (r / 6);
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
            <div style={{ position: 'absolute', inset: -30, borderRadius: '50%', background: 'radial-gradient(circle, rgba(139,92,246,0.5) 0%, transparent 70%)' }}/>
            <Logo size={130}/>
            <div style={{
              position: 'absolute', bottom: -4, right: -4,
              width: 44, height: 44, borderRadius: '50%',
              background: T.mint, border: '4px solid #0e0620',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><I.check size={22} stroke="#0e0620" sw={3}/></div>
          </div>

          <div>
            <div style={{ fontSize: 11, fontWeight: 700, color: T.accent2, letterSpacing: 2.5, marginBottom: 10 }}>BIENVENUE DANS PRO ✦</div>
            <div style={{ fontSize: 42, fontWeight: 800, letterSpacing: -1.6, lineHeight: 1 }}>Décollage<br/>imminent.</div>
            <div style={{ fontSize: 15, color: T.textMute, marginTop: 14, lineHeight: 1.4, padding: '0 4px' }}>
              Ton plan Tokyo t'attend.<br/>L'aventure commence maintenant.
            </div>
          </div>

          <Card padding={12} style={{ background: 'rgba(245,193,80,0.06)', border: '1px solid rgba(245,193,80,0.18)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ fontSize: 24 }}>🎁</div>
              <div style={{ textAlign: 'left' }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: T.gold }}>7 jours Pro · activés</div>
                <div style={{ fontSize: 10, color: T.textMute }}>Accès complet jusqu'au 31 mai</div>
              </div>
            </div>
          </Card>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <CTA>Entrer dans Tripnest →</CTA>
          <CTA ghost>Partager avec un·e ami·e</CTA>
        </div>
      </div>
    </Screen>
  );
}

Object.assign(window, {
  V2_16, V2_17, V2_18, V2_19, V2_20, V2_21, V2_22, V2_23,
  V2_24, V2_25, V2_26, V2_27, V2_28, V2_29,
});
