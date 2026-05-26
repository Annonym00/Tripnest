// Budget, Flights, Spots, Memories, Profile, Trips list, Add modal

// ────────────────────────────────────────────────────────────
// BUDGET
// ────────────────────────────────────────────────────────────
function BudgetScreen({ onNav }) {
  const t = TRIPS.lisbon;
  const cats = [
    { name: 'Hébergement', icon: I.hotel, spent: 480, budget: 700, c: T.rose },
    { name: 'Restaurants', icon: I.food, spent: 312, budget: 450, c: T.gold },
    { name: 'Transport', icon: I.bus, spent: 142, budget: 250, c: T.blue },
    { name: 'Activités', icon: I.ticket, spent: 130, budget: 300, c: T.mint },
    { name: 'Souvenirs', icon: I.gift, spent: 60, budget: 150, c: T.accent2 },
  ];
  const txs = [
    { t: '12 mai · 21:14', l: 'A Cevicheria', cat: 'Restaurant', a: 64, i: I.food, c: T.gold },
    { t: '12 mai · 16:20', l: 'Memmo Alfama (3 nuits)', cat: 'Hébergement', a: 360, i: I.hotel, c: T.rose },
    { t: '12 mai · 15:02', l: 'Bolt aéroport → centre', cat: 'Transport', a: 18, i: I.bus, c: T.blue },
    { t: '12 mai · 14:48', l: 'Carte Viva Viagem', cat: 'Transport', a: 12, i: I.ticket, c: T.mint },
  ];
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '6px 22px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontSize: 11, color: T.textMute, fontWeight: 700, letterSpacing: 1.5 }}>BUDGET · LISBONNE</div>
          <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: -0.5 }}>Suivi des dépenses</div>
        </div>
        <IconBtn icon={I.filter}/>
      </div>

      <div style={{ padding: '0 18px 130px', overflowY: 'auto', height: 'calc(100% - 88px)' }}>
        {/* Big ring */}
        <Card padding={22} glow style={{ marginBottom: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
            <ProgressRing value={t.spent} max={t.budget} size={130} stroke={11} color={T.accent2}>
              <div style={{ fontSize: 11, color: T.textMute }}>Dépensé</div>
              <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.6 }}>{t.spent}€</div>
              <div style={{ fontSize: 11, color: T.textMute }}>/ {t.budget}€</div>
            </ProgressRing>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, color: T.textMute }}>Reste</div>
              <div style={{ fontSize: 32, fontWeight: 800, letterSpacing: -0.8, color: T.mint }}>{t.budget - t.spent}€</div>
              <div style={{ fontSize: 12, color: T.textMute, marginTop: 6 }}>≈ {Math.round((t.budget - t.spent) / 7)}€/jour pour 7 jours</div>
              <div style={{
                marginTop: 12, padding: '8px 12px', borderRadius: 10,
                background: 'rgba(134,239,172,0.10)', border: `1px solid rgba(134,239,172,0.20)`,
                fontSize: 12, color: T.mint, display: 'flex', gap: 6, alignItems: 'center', fontWeight: 600,
              }}><I.check size={14} stroke={T.mint}/> Dans le budget</div>
            </div>
          </div>
        </Card>

        {/* By category */}
        <div style={{ fontSize: 14, fontWeight: 700, color: T.textMute, padding: '0 4px 10px', letterSpacing: 0.4 }}>PAR CATÉGORIE</div>
        <Card padding={4} style={{ marginBottom: 18 }}>
          {cats.map((c, i) => {
            const pct = Math.min(100, c.spent / c.budget * 100);
            return (
              <div key={c.name} style={{
                padding: '14px 16px',
                borderBottom: i < cats.length - 1 ? `1px solid ${T.border}` : 'none',
                display: 'flex', alignItems: 'center', gap: 14,
              }}>
                <div style={{ width: 38, height: 38, borderRadius: 11, background: `${c.c}22`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <c.icon size={18} stroke={c.c}/>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                    <span style={{ fontSize: 14, fontWeight: 600 }}>{c.name}</span>
                    <span style={{ fontSize: 13, fontWeight: 700 }}>{c.spent}€ <span style={{ color: T.textMute, fontWeight: 500, fontSize: 11 }}>/ {c.budget}€</span></span>
                  </div>
                  <div style={{ marginTop: 8, height: 5, borderRadius: 3, background: 'rgba(167,139,250,0.10)', overflow: 'hidden' }}>
                    <div style={{ width: `${pct}%`, height: '100%', background: c.c, opacity: 0.85 }}/>
                  </div>
                </div>
              </div>
            );
          })}
        </Card>

        {/* Recent transactions */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', padding: '0 4px 10px' }}>
          <div style={{ fontSize: 14, fontWeight: 700, color: T.textMute, letterSpacing: 0.4 }}>DÉPENSES RÉCENTES</div>
          <div style={{ fontSize: 12, color: T.accent2, fontWeight: 600 }}>Voir tout</div>
        </div>
        <Card padding={4}>
          {txs.map((x, i) => (
            <div key={i} style={{
              padding: '12px 14px', display: 'flex', gap: 12, alignItems: 'center',
              borderBottom: i < txs.length - 1 ? `1px solid ${T.border}` : 'none',
            }}>
              <div style={{ width: 36, height: 36, borderRadius: 10, background: `${x.c}22`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <x.i size={16} stroke={x.c}/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{x.l}</div>
                <div style={{ fontSize: 11, color: T.textMute, marginTop: 2 }}>{x.t} · {x.cat}</div>
              </div>
              <div style={{ fontSize: 15, fontWeight: 700, color: T.text }}>−{x.a}€</div>
            </div>
          ))}
        </Card>
      </div>

      <TabBar active="budget" onChange={onNav}/>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// FLIGHTS
// ────────────────────────────────────────────────────────────
function FlightsScreen({ onNav }) {
  const next = { code: 'TP 432', from: 'LIS', fromCity: 'Lisbonne', to: 'CDG', toCity: 'Paris', date: '19 mai', dep: '14:20', arr: '18:10', dur: '2h 50', seat: '14A', gate: 'B12', terminal: '1', co: 'TAP Air Portugal' };
  const upcoming = [
    { code: 'AF 6724', from: 'CDG', to: 'NRT', date: '04 sept.', dep: '13:25', dur: '12h 05', co: 'Air France' },
    { code: 'NH 879', from: 'NRT', to: 'CDG', date: '18 sept.', dep: '11:50', dur: '14h 20', co: 'ANA' },
  ];
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '6px 22px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: -0.5 }}>Mes vols</div>
          <div style={{ fontSize: 13, color: T.textMute, marginTop: 2 }}>3 à venir · 12 effectués</div>
        </div>
        <IconBtn icon={I.search}/>
      </div>

      <div style={{ padding: '0 18px 130px', overflowY: 'auto', height: 'calc(100% - 88px)' }}>
        {/* segmented */}
        <div style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
          <Pill active>Prochain</Pill>
          <Pill>À venir (3)</Pill>
          <Pill>Effectués</Pill>
        </div>

        {/* Boarding pass */}
        <div style={{
          borderRadius: 24, overflow: 'hidden', position: 'relative',
          background: `linear-gradient(155deg, ${T.bg2} 0%, ${T.bg1} 100%)`,
          border: `1px solid ${T.borderStrong}`,
          boxShadow: '0 24px 60px rgba(15,5,35,0.55)',
          marginBottom: 16,
        }}>
          <div style={{ padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: `1px dashed ${T.border}` }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{ width: 28, height: 28, borderRadius: 7, background: `linear-gradient(135deg, ${T.accent2}, ${T.accentDeep})`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 800, color: '#fff' }}>TP</div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 700 }}>{next.co}</div>
                <div style={{ fontSize: 11, color: T.textMute }}>{next.code}</div>
              </div>
            </div>
            <div style={{ fontSize: 11, fontWeight: 700, color: T.mint, background: 'rgba(134,239,172,0.12)', padding: '4px 10px', borderRadius: 8 }}>À L'HEURE</div>
          </div>

          <div style={{ padding: '24px 20px', display: 'grid', gridTemplateColumns: '1fr auto 1fr', alignItems: 'center', gap: 8 }}>
            <div>
              <div style={{ fontSize: 12, color: T.textMute }}>{next.fromCity}</div>
              <div style={{ fontSize: 44, fontWeight: 800, letterSpacing: -2, lineHeight: 1 }}>{next.from}</div>
              <div style={{ fontSize: 22, fontWeight: 700, marginTop: 6, letterSpacing: -0.6 }}>{next.dep}</div>
              <div style={{ fontSize: 11, color: T.textMute }}>{next.date}</div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
              <div style={{ fontSize: 10, color: T.textDim, fontWeight: 700, letterSpacing: 1 }}>{next.dur}</div>
              <svg width="80" height="22">
                <line x1="0" y1="11" x2="78" y2="11" stroke={T.accent2} strokeWidth="1" strokeDasharray="2 3"/>
                <circle cx="0" cy="11" r="3" fill="none" stroke={T.accent2} strokeWidth="1.5"/>
                <circle cx="78" cy="11" r="3" fill={T.accent2}/>
              </svg>
              <I.plane size={20} stroke={T.accent2}/>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 12, color: T.textMute }}>{next.toCity}</div>
              <div style={{ fontSize: 44, fontWeight: 800, letterSpacing: -2, lineHeight: 1 }}>{next.to}</div>
              <div style={{ fontSize: 22, fontWeight: 700, marginTop: 6, letterSpacing: -0.6 }}>{next.arr}</div>
              <div style={{ fontSize: 11, color: T.textMute }}>{next.date}</div>
            </div>
          </div>

          {/* perforation */}
          <div style={{ position: 'relative', height: 0 }}>
            <div style={{ position: 'absolute', left: -12, top: -12, width: 24, height: 24, borderRadius: '50%', background: T.bg0 }}/>
            <div style={{ position: 'absolute', right: -12, top: -12, width: 24, height: 24, borderRadius: '50%', background: T.bg0 }}/>
            <div style={{ position: 'absolute', left: 12, right: 12, top: -1, borderTop: `1.5px dashed ${T.border}` }}/>
          </div>

          <div style={{ padding: '20px 20px 18px', display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
            {[
              ['Passager', 'L. Martin'],
              ['Siège', next.seat],
              ['Porte', next.gate],
              ['Term.', next.terminal],
            ].map(([k, v]) => (
              <div key={k}>
                <div style={{ fontSize: 10, color: T.textMute, letterSpacing: 1, fontWeight: 700 }}>{k.toUpperCase()}</div>
                <div style={{ fontSize: 16, fontWeight: 700, marginTop: 3, letterSpacing: -0.3 }}>{v}</div>
              </div>
            ))}
          </div>

          {/* Barcode */}
          <div style={{ padding: '0 20px 18px' }}>
            <div style={{ display: 'flex', gap: 1, height: 42, alignItems: 'center' }}>
              {Array.from({ length: 64 }).map((_, i) => (
                <div key={i} style={{ width: 1 + (i % 3), height: '100%', background: i % 7 === 0 ? 'transparent' : T.text, opacity: 0.85 }}/>
              ))}
            </div>
            <div style={{ fontSize: 10, color: T.textMute, fontFamily: 'ui-monospace, Menlo, monospace', marginTop: 6, letterSpacing: 2 }}>TP432 LIS CDG 19MAY 14A</div>
          </div>
        </div>

        {/* Upcoming smaller cards */}
        <div style={{ fontSize: 14, fontWeight: 700, color: T.textMute, padding: '0 4px 10px', letterSpacing: 0.4 }}>SUIVANTS</div>
        {upcoming.map((f, i) => (
          <Card key={i} padding={16} style={{ marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ width: 36, height: 36, borderRadius: 10, background: 'rgba(167,139,250,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <I.plane size={18} stroke={T.accent2}/>
                </div>
                <div>
                  <div style={{ fontSize: 15, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 6 }}>
                    {f.from} <I.arrow size={12} stroke={T.textMute}/> {f.to}
                  </div>
                  <div style={{ fontSize: 11, color: T.textMute, marginTop: 1 }}>{f.co} · {f.code}</div>
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 13, fontWeight: 700 }}>{f.date}</div>
                <div style={{ fontSize: 11, color: T.textMute }}>{f.dep} · {f.dur}</div>
              </div>
            </div>
          </Card>
        ))}
      </div>

      <TabBar active="trips" onChange={onNav}/>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// SPOTS (map + list)
// ────────────────────────────────────────────────────────────
function SpotsScreen({ onNav }) {
  const cats = ['Tous', 'Restaurant', 'À voir', 'Hôtel', 'Bar', 'Plage'];
  const [cat, setCat] = React.useState('Tous');
  const spots = [
    { name: 'Time Out Market', cat: 'Restaurant', area: 'Cais do Sodré', star: 4.5, saved: true, hue: 25, x: 32, y: 65, c: T.gold, i: I.food },
    { name: 'Miradouro S. Pedro', cat: 'À voir', area: 'Alfama', star: 4.8, saved: false, hue: 280, x: 58, y: 35, c: T.rose, i: I.star },
    { name: 'Pastéis de Belém', cat: 'Restaurant', area: 'Belém', star: 4.7, saved: true, hue: 50, x: 18, y: 78, c: T.gold, i: I.food },
    { name: 'Memmo Alfama', cat: 'Hôtel', area: 'Alfama', star: 4.9, saved: true, hue: 200, x: 65, y: 50, c: T.blue, i: I.hotel },
    { name: 'Park Bar', cat: 'Bar', area: 'Bairro Alto', star: 4.6, saved: true, hue: 340, x: 42, y: 48, c: T.accent2, i: I.gift },
  ];
  return (
    <Screen motif={false}>
      <StatusBar/>
      <div style={{ padding: '6px 22px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: -0.5 }}>Spots</div>
          <div style={{ fontSize: 13, color: T.textMute }}>14 enregistrés à Lisbonne</div>
        </div>
        <IconBtn icon={I.search}/>
      </div>

      {/* Map area */}
      <div style={{ margin: '0 18px', borderRadius: 22, overflow: 'hidden', position: 'relative', height: 240, border: `1px solid ${T.border}` }}>
        {/* fake map */}
        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(160deg, #1a1138 0%, #100624 100%)' }}/>
        {/* grid streets */}
        <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0, opacity: 0.35 }}>
          <defs>
            <pattern id="map" width="40" height="40" patternUnits="userSpaceOnUse">
              <path d="M0 20h40M20 0v40" stroke="rgba(167,139,250,0.25)" strokeWidth="0.5"/>
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#map)"/>
          {/* "river" */}
          <path d="M0 200 Q120 180 240 200 T480 220" stroke="rgba(125,211,252,0.35)" strokeWidth="22" fill="none" strokeLinecap="round"/>
          <path d="M0 200 Q120 180 240 200 T480 220" stroke="rgba(125,211,252,0.15)" strokeWidth="40" fill="none" strokeLinecap="round"/>
          {/* roads */}
          <path d="M50 0 Q80 100 30 200 T120 400" stroke="rgba(245,240,255,0.18)" strokeWidth="2" fill="none"/>
          <path d="M400 0 Q360 80 320 160 T240 280" stroke="rgba(245,240,255,0.18)" strokeWidth="2" fill="none"/>
        </svg>
        {/* pins */}
        {spots.map(s => (
          <div key={s.name} style={{
            position: 'absolute', left: `${s.x}%`, top: `${s.y}%`,
            transform: 'translate(-50%, -100%)',
          }}>
            <div style={{
              width: 32, height: 32, borderRadius: '50% 50% 50% 0', transform: 'rotate(-45deg)',
              background: s.c, display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: `0 0 16px ${s.c}99, 0 6px 14px rgba(0,0,0,0.4)`,
              border: '2px solid #fff',
            }}>
              <div style={{ transform: 'rotate(45deg)' }}><s.i size={14} stroke="#fff" sw={2.2}/></div>
            </div>
          </div>
        ))}
        {/* "you" */}
        <div style={{ position: 'absolute', left: '48%', top: '58%', transform: 'translate(-50%, -50%)' }}>
          <div style={{ width: 14, height: 14, borderRadius: '50%', background: T.blue, border: '3px solid #fff', boxShadow: `0 0 0 6px rgba(125,211,252,0.25), 0 0 0 12px rgba(125,211,252,0.12)` }}/>
        </div>
      </div>

      {/* category pills */}
      <div style={{ padding: '14px 18px 8px', display: 'flex', gap: 6, overflowX: 'auto' }}>
        {cats.map(c => <Pill key={c} active={cat === c} onClick={() => setCat(c)}>{c}</Pill>)}
      </div>

      {/* list */}
      <div style={{ padding: '8px 18px 130px', overflowY: 'auto', height: 'calc(100% - 410px)' }}>
        {spots.filter(s => cat === 'Tous' || s.cat === cat).map(s => (
          <Card key={s.name} padding={12} style={{ marginBottom: 10 }}>
            <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
              <DestPhoto label={s.name} hue={s.hue} w={64} h={64} radius={12}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
                  <span style={{ fontSize: 15, fontWeight: 700, letterSpacing: -0.2 }}>{s.name}</span>
                </div>
                <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>{s.cat} · {s.area}</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 5 }}>
                  <I.star size={12} stroke={T.gold} fill={T.gold}/>
                  <span style={{ fontSize: 11, fontWeight: 700 }}>{s.star}</span>
                  <span style={{ fontSize: 11, color: T.textMute, marginLeft: 6 }}>· Sauvé par toi</span>
                </div>
              </div>
              <div style={{
                width: 36, height: 36, borderRadius: 11,
                background: s.saved ? 'rgba(244,114,182,0.15)' : 'rgba(167,139,250,0.10)',
                border: `1px solid ${s.saved ? 'rgba(244,114,182,0.30)' : T.border}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <I.heart size={16} stroke={s.saved ? T.rose : T.textMute} fill={s.saved ? T.rose : 'none'}/>
              </div>
            </div>
          </Card>
        ))}
      </div>
      <TabBar active="trips" onChange={onNav}/>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// MEMORIES (past trips)
// ────────────────────────────────────────────────────────────
function MemoriesScreen({ onNav }) {
  const past = [TRIPS.marrakech, TRIPS.islande, TRIPS.rome, TRIPS.bali];
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '6px 22px 14px' }}>
        <div style={{ fontSize: 11, color: T.textMute, fontWeight: 700, letterSpacing: 1.5 }}>SOUVENIRS</div>
        <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.6, marginTop: 2 }}>Mon carnet de voyages</div>
      </div>

      {/* stats strip */}
      <div style={{ padding: '0 18px 16px', display: 'flex', gap: 8 }}>
        {[
          { l: 'Pays', v: '12', c: T.accent2 },
          { l: 'Voyages', v: '24', c: T.rose },
          { l: 'Jours', v: '187', c: T.gold },
          { l: 'Km', v: '74k', c: T.blue },
        ].map(s => (
          <div key={s.l} style={{
            flex: 1, padding: '12px 0', textAlign: 'center',
            borderRadius: 14, background: T.surface, border: `1px solid ${T.border}`,
          }}>
            <div style={{ fontSize: 22, fontWeight: 800, color: s.c, letterSpacing: -0.5 }}>{s.v}</div>
            <div style={{ fontSize: 10, color: T.textMute, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }}>{s.l}</div>
          </div>
        ))}
      </div>

      <div style={{ padding: '0 18px 4px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', gap: 6 }}>
          <Pill active>Tous</Pill>
          <Pill>2025</Pill>
          <Pill>2024</Pill>
        </div>
        <div style={{ fontSize: 12, color: T.textMute, fontWeight: 600 }}>Plus récents ⌄</div>
      </div>

      <div style={{ padding: '14px 18px 130px', overflowY: 'auto', height: 'calc(100% - 280px)', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        {past.map((p, i) => (
          <div key={p.id} style={{
            borderRadius: 18, overflow: 'hidden', position: 'relative',
            background: T.bg2, border: `1px solid ${T.border}`,
            transform: i % 2 === 0 ? 'rotate(-0.6deg)' : 'rotate(0.5deg)',
            height: 220,
            boxShadow: '0 12px 30px rgba(15,5,35,0.4)',
          }}>
            <DestPhoto label={p.cover} hue={p.hue} h={160} radius={0}/>
            <div style={{ position: 'absolute', top: 10, left: 10, fontSize: 18,
              background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(8px)',
              width: 28, height: 28, borderRadius: 9, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{p.flag}</div>
            <div style={{ position: 'absolute', top: 10, right: 10,
              background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(8px)',
              padding: '3px 8px', borderRadius: 8, fontSize: 11, fontWeight: 700, color: '#fff',
              display: 'flex', alignItems: 'center', gap: 3 }}>
              <I.star size={10} stroke={T.gold} fill={T.gold}/> {p.rating}
            </div>
            <div style={{ padding: '10px 12px' }}>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: -0.2 }}>{p.dest}</div>
              <div style={{ fontSize: 10, color: T.textMute, marginTop: 2 }}>{p.dates}</div>
              <div style={{ display: 'flex', gap: 8, marginTop: 6, fontSize: 10, color: T.textMute }}>
                <span>{p.days}j</span>
                <span>·</span>
                <span>{p.spent}€</span>
              </div>
            </div>
          </div>
        ))}
      </div>
      <TabBar active="trips" onChange={onNav}/>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// TRIPS LIST (all)
// ────────────────────────────────────────────────────────────
function TripsScreen({ onNav }) {
  const active = [TRIPS.lisbon];
  const planned = [TRIPS.tokyo];
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '6px 22px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.6 }}>Mes voyages</div>
        <button style={{
          height: 36, padding: '0 14px', borderRadius: 12,
          background: T.accent, color: '#fff', border: 'none',
          fontFamily: T.font, fontSize: 13, fontWeight: 700,
          display: 'flex', alignItems: 'center', gap: 6,
        }}><I.plus size={14} stroke="#fff" sw={2.5}/> Nouveau</button>
      </div>

      <div style={{ padding: '0 18px 130px', overflowY: 'auto', height: 'calc(100% - 88px)' }}>
        <div style={{ fontSize: 12, fontWeight: 700, color: T.mint, letterSpacing: 1.5, marginBottom: 10, display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ width: 6, height: 6, borderRadius: '50%', background: T.mint }}/> EN COURS
        </div>
        {active.map(t => <TripRow key={t.id} t={t} onClick={() => onNav('trip')}/>)}

        <div style={{ fontSize: 12, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, margin: '20px 0 10px' }}>À VENIR</div>
        {planned.map(t => <TripRow key={t.id} t={t}/>)}

        <div style={{ fontSize: 12, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, margin: '20px 0 10px' }}>SOUVENIRS</div>
        {[TRIPS.marrakech, TRIPS.islande, TRIPS.rome].map(t => <TripRow key={t.id} t={t} done/>)}
      </div>
      <TabBar active="trips" onChange={onNav}/>
    </Screen>
  );
}

function TripRow({ t, done, onClick }) {
  const pct = Math.round(t.spent / t.budget * 100);
  return (
    <button onClick={onClick} style={{
      all: 'unset', cursor: 'pointer', display: 'block', width: '100%',
      borderRadius: 18, overflow: 'hidden', position: 'relative',
      background: T.surface, border: `1px solid ${T.border}`,
      marginBottom: 10, padding: 0,
    }}>
      <div style={{ display: 'flex', gap: 14, padding: 12 }}>
        <DestPhoto label={t.cover} hue={t.hue} w={76} h={76} radius={14}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: -0.3 }}>{t.dest} <span style={{ fontSize: 14 }}>{t.flag}</span></div>
            <div style={{ fontSize: 11, color: T.textMute }}>{t.days}j</div>
          </div>
          <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>{t.dates}</div>
          <div style={{ marginTop: 8 }}>
            <div style={{ height: 4, borderRadius: 2, background: 'rgba(167,139,250,0.10)', overflow: 'hidden' }}>
              <div style={{ width: `${Math.min(100, pct)}%`, height: '100%',
                background: pct > 100 ? T.rose : done ? T.textMute : T.accent2 }}/>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 5, fontSize: 11, color: T.textMute }}>
              <span>{t.spent}€ / {t.budget}€</span>
              <span style={{ color: pct > 100 ? T.rose : (done ? T.textMute : T.accent2), fontWeight: 700 }}>{pct}%</span>
            </div>
          </div>
        </div>
      </div>
    </button>
  );
}

// ────────────────────────────────────────────────────────────
// PROFILE
// ────────────────────────────────────────────────────────────
function ProfileScreen({ onNav }) {
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '6px 22px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: -0.5 }}>Profil</div>
        <IconBtn icon={I.edit}/>
      </div>
      <div style={{ padding: '0 18px 130px', overflowY: 'auto', height: 'calc(100% - 88px)' }}>
        <Card padding={20} style={{ textAlign: 'center', marginBottom: 14 }}>
          <div style={{ display: 'inline-block', position: 'relative', marginBottom: 10 }}>
            <div style={{
              width: 88, height: 88, borderRadius: '50%',
              background: `linear-gradient(135deg, ${T.accent2}, ${T.rose})`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 32, fontWeight: 800, color: '#fff',
              border: `3px solid ${T.borderStrong}`,
            }}>LM</div>
            <div style={{
              position: 'absolute', bottom: -2, right: -2,
              width: 28, height: 28, borderRadius: '50%', background: T.accent,
              border: '3px solid #150a2a', display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><I.cam size={14} stroke="#fff"/></div>
          </div>
          <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: -0.4 }}>Léa Martin</div>
          <div style={{ fontSize: 13, color: T.textMute }}>@leamartin · Membre depuis 2023</div>
          <div style={{ display: 'flex', gap: 6, justifyContent: 'center', marginTop: 10, flexWrap: 'wrap' }}>
            <Pill style={{ pointerEvents: 'none' }}>✈️ Globe-trotteuse</Pill>
            <Pill style={{ pointerEvents: 'none' }}>🌍 12 pays</Pill>
          </div>
        </Card>

        <div style={{ fontSize: 12, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, padding: '8px 4px' }}>PRÉFÉRENCES</div>
        <Card padding={4}>
          {[
            ['Devise par défaut', 'EUR (€)', I.wallet],
            ['Notifications', 'Activées', I.bell],
            ['Carte préférée', 'Standard', I.spot],
            ['Langue', 'Français', I.globe],
          ].map(([l, v, Ic], i, arr) => (
            <div key={l} style={{ display: 'flex', alignItems: 'center', padding: '14px 14px', borderBottom: i < arr.length - 1 ? `1px solid ${T.border}` : 'none', gap: 12 }}>
              <div style={{ width: 34, height: 34, borderRadius: 10, background: 'rgba(167,139,250,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic size={16} stroke={T.accent2}/>
              </div>
              <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>{l}</div>
              <div style={{ fontSize: 13, color: T.textMute }}>{v}</div>
              <I.arrow size={14} stroke={T.textDim}/>
            </div>
          ))}
        </Card>

        <div style={{ fontSize: 12, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, padding: '20px 4px 8px' }}>COMPTE</div>
        <Card padding={4}>
          {[['Documents · passeport, ID', I.passport], ['Conversions de devise', I.wallet], ['Aide & support', I.bell], ['Se déconnecter', I.close]].map(([l, Ic], i, arr) => (
            <div key={l} style={{ display: 'flex', alignItems: 'center', padding: '14px 14px', borderBottom: i < arr.length - 1 ? `1px solid ${T.border}` : 'none', gap: 12, color: l.startsWith('Se déconnecter') ? T.rose : T.text }}>
              <div style={{ width: 34, height: 34, borderRadius: 10, background: l.startsWith('Se déconnecter') ? 'rgba(244,114,182,0.10)' : 'rgba(167,139,250,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic size={16} stroke={l.startsWith('Se déconnecter') ? T.rose : T.accent2}/>
              </div>
              <div style={{ flex: 1, fontSize: 14, fontWeight: 600 }}>{l}</div>
              <I.arrow size={14} stroke={T.textDim}/>
            </div>
          ))}
        </Card>
      </div>
      <TabBar active="profile" onChange={onNav}/>
    </Screen>
  );
}

// ────────────────────────────────────────────────────────────
// ADD EXPENSE (modal-like full screen)
// ────────────────────────────────────────────────────────────
function AddExpenseScreen({ onNav }) {
  const [cat, setCat] = React.useState('food');
  const cats = [
    { id: 'food', l: 'Repas', i: I.food, c: T.gold },
    { id: 'hotel', l: 'Hôtel', i: I.hotel, c: T.rose },
    { id: 'bus', l: 'Transport', i: I.bus, c: T.blue },
    { id: 'ticket', l: 'Activité', i: I.ticket, c: T.mint },
    { id: 'gift', l: 'Souvenir', i: I.gift, c: T.accent2 },
    { id: 'more', l: 'Autre', i: I.more, c: T.textMute },
  ];
  return (
    <Screen>
      <StatusBar/>
      {/* dim backdrop for modal feel */}
      <div style={{ padding: '6px 22px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <IconBtn icon={I.close}/>
        <div style={{ fontSize: 16, fontWeight: 700 }}>Nouvelle dépense</div>
        <div style={{ width: 40 }}/>
      </div>

      <div style={{ padding: '0 22px 18px', textAlign: 'center' }}>
        <div style={{ fontSize: 11, color: T.textMute, letterSpacing: 1.5, fontWeight: 700 }}>MONTANT</div>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: 4, marginTop: 10 }}>
          <div style={{ fontSize: 64, fontWeight: 800, letterSpacing: -3, color: T.text }}>64</div>
          <div style={{ fontSize: 28, fontWeight: 700, color: T.textMute, letterSpacing: -0.5 }}>,00 €</div>
        </div>
        <div style={{ display: 'inline-flex', gap: 6, marginTop: 8 }}>
          <Pill active style={{ background: 'rgba(139,92,246,0.18)', color: T.accent2, border: `1px solid ${T.borderStrong}` }}>EUR</Pill>
          <Pill>USD</Pill>
          <Pill>JPY</Pill>
        </div>
      </div>

      <div style={{ padding: '0 22px', overflowY: 'auto', height: 'calc(100% - 380px)' }}>
        <div style={{ fontSize: 12, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, marginBottom: 10 }}>CATÉGORIE</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
          {cats.map(c => {
            const active = cat === c.id;
            return (
              <button key={c.id} onClick={() => setCat(c.id)} style={{
                all: 'unset', cursor: 'pointer',
                padding: '14px 10px', borderRadius: 16,
                background: active ? `${c.c}1f` : T.surface,
                border: `1px solid ${active ? c.c + '55' : T.border}`,
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
              }}>
                <div style={{
                  width: 40, height: 40, borderRadius: 12,
                  background: active ? c.c : `${c.c}22`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}><c.i size={18} stroke={active ? '#fff' : c.c}/></div>
                <span style={{ fontSize: 12, fontWeight: 600, color: active ? c.c : T.text }}>{c.l}</span>
              </button>
            );
          })}
        </div>

        <div style={{ fontSize: 12, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, marginTop: 22, marginBottom: 10 }}>DÉTAILS</div>
        <Card padding={4}>
          {[
            ['Description', 'A Cevicheria'],
            ['Voyage', 'Lisbonne · en cours'],
            ['Date', '12 mai 2025 · 21:14'],
            ['Payé avec', 'Carte Revolut'],
          ].map(([k, v], i, arr) => (
            <div key={k} style={{ padding: '14px 14px', display: 'flex', alignItems: 'center', borderBottom: i < arr.length - 1 ? `1px solid ${T.border}` : 'none' }}>
              <div style={{ flex: 1, fontSize: 13, color: T.textMute }}>{k}</div>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{v}</div>
              <I.arrow size={14} stroke={T.textDim} style={{ marginLeft: 8 }}/>
            </div>
          ))}
        </Card>

        <button style={{
          marginTop: 22, width: '100%', height: 56,
          borderRadius: 18,
          background: `linear-gradient(180deg, ${T.accent2} 0%, ${T.accentDeep} 100%)`,
          color: '#fff', fontSize: 16, fontWeight: 700,
          border: '1px solid rgba(167,139,250,0.4)',
          boxShadow: '0 12px 28px rgba(139,92,246,0.35)',
          fontFamily: T.font, cursor: 'pointer',
        }}>Enregistrer la dépense</button>
      </div>
    </Screen>
  );
}

Object.assign(window, { BudgetScreen, FlightsScreen, SpotsScreen, MemoriesScreen, TripsScreen, ProfileScreen, AddExpenseScreen });
