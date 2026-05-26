// Tripnest data + main screens
// All amounts in € EUR

const TRIPS = {
  lisbon: {
    id: 'lisbon', dest: 'Lisbonne', country: 'Portugal', flag: '🇵🇹',
    dates: '12 — 19 mai', days: 8, hue: 25, status: 'active',
    budget: 1850, spent: 1124, cover: 'Lisbonne · trams jaunes',
  },
  tokyo: {
    id: 'tokyo', dest: 'Tokyo', country: 'Japon', flag: '🇯🇵',
    dates: '04 — 18 sept.', days: 14, hue: 340, status: 'planned',
    budget: 4200, spent: 380, cover: 'Tokyo · Shibuya neon',
  },
  marrakech: {
    id: 'marrakech', dest: 'Marrakech', country: 'Maroc', flag: '🇲🇦',
    dates: '14 — 21 oct. 2025', days: 7, hue: 50, cover: 'Médina · ruelles',
    budget: 1200, spent: 1145, status: 'done', rating: 4.8,
  },
  islande: {
    id: 'islande', dest: 'Reykjavik', country: 'Islande', flag: '🇮🇸',
    dates: '02 — 09 mars 2025', days: 7, hue: 220, cover: 'Aurores boréales',
    budget: 2400, spent: 2510, status: 'done', rating: 4.9,
  },
  rome: {
    id: 'rome', dest: 'Rome', country: 'Italie', flag: '🇮🇹',
    dates: '15 — 19 août 2024', days: 4, hue: 15, cover: 'Trastevere',
    budget: 900, spent: 870, status: 'done', rating: 4.6,
  },
  bali: {
    id: 'bali', dest: 'Bali', country: 'Indonésie', flag: '🇮🇩',
    dates: '08 — 22 janv. 2024', days: 14, hue: 160, cover: 'Ubud · rizières',
    budget: 1800, spent: 1620, status: 'done', rating: 4.7,
  },
};

// ────────────────────────────────────────────────────────────
// HOME
// ────────────────────────────────────────────────────────────
function HomeScreen({ onNav }) {
  const t = TRIPS.lisbon;
  const pct = Math.round(t.spent / t.budget * 100);
  return (
    <Screen>
      <StatusBar/>
      {/* header */}
      <div style={{ padding: '8px 22px 18px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontSize: 13, color: T.textMute }}>Mardi 12 mai</div>
          <div style={{ fontSize: 24, fontWeight: 700, marginTop: 2, letterSpacing: -0.5 }}>Salut Léa ✦</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <IconBtn icon={I.bell} dot/>
          <Avatar/>
        </div>
      </div>

      <div style={{ padding: '0 18px 120px', display: 'flex', flexDirection: 'column', gap: 14, overflowY: 'auto', height: 'calc(100% - 86px)' }}>

        {/* ACTIVE TRIP HERO */}
        <button onClick={() => onNav && onNav('trip')} style={{
          all: 'unset', cursor: 'pointer', display: 'block',
          borderRadius: 26, overflow: 'hidden', position: 'relative',
          height: 220,
          background: `linear-gradient(180deg, oklch(0.42 0.16 ${t.hue}) 0%, oklch(0.20 0.12 ${t.hue + 10}) 100%)`,
          border: `1px solid ${T.borderStrong}`,
          boxShadow: '0 22px 50px rgba(15,5,35,0.5)',
        }}>
          <div style={{ position: 'absolute', inset: 0,
            backgroundImage: 'repeating-linear-gradient(135deg, transparent 0 18px, rgba(255,255,255,0.04) 18px 19px)' }}/>
          {/* dotted route */}
          <svg width="100%" height="50" viewBox="0 0 350 50" style={{ position: 'absolute', top: 80, left: 0, opacity: 0.4 }}>
            <path d="M20 40 Q175 0 330 30" stroke="#fff" strokeWidth="1.5" strokeDasharray="2 6" fill="none"/>
            <circle cx="20" cy="40" r="3" fill="#fff"/>
            <circle cx="330" cy="30" r="3" fill="#fff"/>
          </svg>
          <div style={{ position: 'absolute', top: 16, left: 18, display: 'flex', gap: 6, alignItems: 'center' }}>
            <div style={{ width: 7, height: 7, borderRadius: '50%', background: '#86efac', boxShadow: '0 0 10px #86efac' }}/>
            <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.5, color: '#86efac' }}>EN COURS · JOUR 1/8</span>
          </div>
          <div style={{ position: 'absolute', top: 16, right: 18, fontSize: 24 }}>{t.flag}</div>
          <div style={{ position: 'absolute', bottom: 18, left: 18, right: 18 }}>
            <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.7)', letterSpacing: 0.5 }}>PROCHAINE ESCALE</div>
            <div style={{ fontSize: 34, fontWeight: 800, letterSpacing: -1.2, marginTop: 2, color: '#fff' }}>{t.dest}</div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginTop: 6 }}>
              <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)' }}>{t.dates} · {t.days} jours</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 13, fontWeight: 600 }}>
                Détails <I.arrow size={14} stroke="#fff"/>
              </div>
            </div>
          </div>
        </button>

        {/* QUICK STATS ROW */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Card padding={16}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div style={{ fontSize: 12, color: T.textMute, fontWeight: 600 }}>BUDGET RESTANT</div>
              <I.wallet size={18} stroke={T.accent2}/>
            </div>
            <div style={{ fontSize: 24, fontWeight: 800, marginTop: 8, letterSpacing: -0.6 }}>{t.budget - t.spent}€</div>
            <div style={{ marginTop: 8, height: 5, borderRadius: 3, background: 'rgba(167,139,250,0.15)', overflow: 'hidden' }}>
              <div style={{ width: `${pct}%`, height: '100%', background: `linear-gradient(90deg, ${T.accent2}, ${T.accent})` }}/>
            </div>
            <div style={{ fontSize: 11, color: T.textMute, marginTop: 6 }}>{pct}% utilisé · {t.spent}€ / {t.budget}€</div>
          </Card>
          <Card padding={16}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div style={{ fontSize: 12, color: T.textMute, fontWeight: 600 }}>SPOTS SAUVÉS</div>
              <I.spot size={18} stroke={T.accent2}/>
            </div>
            <div style={{ fontSize: 24, fontWeight: 800, marginTop: 8, letterSpacing: -0.6 }}>14<span style={{ fontSize: 14, color: T.textMute, fontWeight: 600 }}> / 22</span></div>
            <div style={{ display: 'flex', gap: 4, marginTop: 10 }}>
              {['#f472b6','#7dd3fc','#86efac','#f5c150'].map((c,i) => (
                <div key={i} style={{ width: 18, height: 18, borderRadius: 6, background: c, opacity: 0.3 + i * 0.15, border: '1.5px solid #150a2a' }}/>
              ))}
              <div style={{ width: 18, height: 18, borderRadius: 6, background: 'rgba(167,139,250,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, color: T.text, fontWeight: 700 }}>+9</div>
            </div>
          </Card>
        </div>

        {/* NEXT FLIGHT */}
        <Card padding={0} style={{ borderRadius: 22 }}>
          <div style={{ padding: '14px 18px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: `1px dashed ${T.border}` }}>
            <div style={{ fontSize: 11, color: T.textMute, fontWeight: 700, letterSpacing: 1.5 }}>VOL RETOUR · DANS 7 JOURS</div>
            <span style={{ fontSize: 11, fontWeight: 700, color: T.gold, background: 'rgba(245,193,80,0.12)', padding: '3px 8px', borderRadius: 8 }}>TP 432</span>
          </div>
          <div style={{ padding: '14px 18px', display: 'grid', gridTemplateColumns: '1fr auto 1fr', alignItems: 'center', gap: 8 }}>
            <div>
              <div style={{ fontSize: 12, color: T.textMute }}>Lisbonne</div>
              <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.5 }}>LIS</div>
              <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>19 mai · 14:20</div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <div style={{ fontSize: 10, color: T.textDim, fontWeight: 700, letterSpacing: 1 }}>2h 50</div>
              <svg width="80" height="20"><line x1="0" y1="10" x2="78" y2="10" stroke={T.accent2} strokeWidth="1" strokeDasharray="3 3"/><circle cx="0" cy="10" r="2" fill={T.accent2}/><circle cx="78" cy="10" r="2" fill={T.accent2}/></svg>
              <I.plane size={16} stroke={T.accent2}/>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 12, color: T.textMute }}>Paris</div>
              <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: -0.5 }}>CDG</div>
              <div style={{ fontSize: 12, color: T.textMute, marginTop: 2 }}>19 mai · 18:10</div>
            </div>
          </div>
        </Card>

        {/* SECTION: récents spots */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: 6, padding: '0 4px' }}>
          <div style={{ fontSize: 17, fontWeight: 700 }}>Spots à proximité</div>
          <div style={{ fontSize: 12, color: T.accent2, fontWeight: 600 }}>Voir la carte</div>
        </div>
        <div style={{ display: 'flex', gap: 10, overflowX: 'auto', padding: '2px 4px 8px' }}>
          {[
            { name: 'Time Out Market', cat: 'food', tag: 'Restaurant', dist: '320m', hue: 30 },
            { name: 'Miradouro S. Pedro', cat: 'star', tag: 'À voir', dist: '850m', hue: 280 },
            { name: 'Pastéis de Belém', cat: 'food', tag: 'Restaurant', dist: '2.4km', hue: 50 },
          ].map(s => (
            <div key={s.name} style={{
              width: 160, flexShrink: 0,
              borderRadius: 16, background: T.surface,
              border: `1px solid ${T.border}`,
              overflow: 'hidden',
            }}>
              <DestPhoto label={s.name} hue={s.hue} h={88} radius={0}/>
              <div style={{ padding: '10px 12px' }}>
                <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: -0.2 }}>{s.name}</div>
                <div style={{ fontSize: 11, color: T.textMute, marginTop: 4, display: 'flex', justifyContent: 'space-between' }}>
                  <span>{s.tag}</span><span>· {s.dist}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <TabBar active="home" onChange={onNav}/>
    </Screen>
  );
}

function IconBtn({ icon: Ic, dot }) {
  return (
    <div style={{
      width: 40, height: 40, borderRadius: 14,
      background: T.surface, border: `1px solid ${T.border}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
    }}>
      <Ic size={20}/>
      {dot && <div style={{ position: 'absolute', top: 8, right: 9, width: 8, height: 8, borderRadius: '50%', background: T.rose, border: '2px solid #150a2a' }}/>}
    </div>
  );
}

function Avatar() {
  return (
    <div style={{
      width: 40, height: 40, borderRadius: '50%',
      background: `linear-gradient(135deg, ${T.accent2}, ${T.rose})`,
      border: `2px solid ${T.borderStrong}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 14, fontWeight: 700, color: '#fff',
    }}>LM</div>
  );
}

// ────────────────────────────────────────────────────────────
// TRIP DETAIL
// ────────────────────────────────────────────────────────────
function TripDetailScreen({ onNav }) {
  const t = TRIPS.lisbon;
  const [tab, setTab] = React.useState('itinerary');
  return (
    <Screen motif={false}>
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 280, overflow: 'hidden' }}>
        <DestPhoto label={t.cover} hue={t.hue} h={280} radius={0}/>
        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg, rgba(14,6,32,0.35) 0%, rgba(14,6,32,0) 40%, rgba(14,6,32,0.9) 90%, #0e0620 100%)' }}/>
      </div>
      <div style={{ position: 'relative', zIndex: 2 }}>
        <StatusBar/>
        <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 22px' }}>
          <IconBtn icon={I.back}/>
          <div style={{ display: 'flex', gap: 8 }}>
            <IconBtn icon={I.heart}/>
            <IconBtn icon={I.more}/>
          </div>
        </div>

        {/* hero text */}
        <div style={{ padding: '120px 22px 0' }}>
          <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.75)', display: 'flex', gap: 6, alignItems: 'center' }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: T.mint }}/>
            <span style={{ letterSpacing: 1.2, fontWeight: 700, fontSize: 11 }}>VOYAGE EN COURS</span>
          </div>
          <div style={{ fontSize: 40, fontWeight: 800, letterSpacing: -1.5, marginTop: 4 }}>Lisbonne <span style={{ fontSize: 30 }}>{t.flag}</span></div>
          <div style={{ fontSize: 14, color: T.textMute, marginTop: 2 }}>{t.dates} · {t.days} jours · {t.country}</div>
        </div>

        {/* stat strip */}
        <div style={{ display: 'flex', gap: 8, padding: '20px 18px 14px', overflowX: 'auto' }}>
          {[
            { l: 'Dépensé', v: `${t.spent}€`, sub: `/ ${t.budget}€`, c: T.accent2 },
            { l: 'Spots', v: '14', sub: 'sauvés', c: T.rose },
            { l: 'Photos', v: '128', sub: 'cliché', c: T.blue },
            { l: 'Jours', v: '1', sub: '/ 8', c: T.mint },
          ].map(s => (
            <div key={s.l} style={{
              minWidth: 96, padding: '12px 14px',
              borderRadius: 16, background: T.surface, border: `1px solid ${T.border}`,
            }}>
              <div style={{ fontSize: 11, color: T.textMute, fontWeight: 600 }}>{s.l}</div>
              <div style={{ fontSize: 22, fontWeight: 800, marginTop: 4, letterSpacing: -0.5, color: s.c }}>{s.v}</div>
              <div style={{ fontSize: 11, color: T.textMute }}>{s.sub}</div>
            </div>
          ))}
        </div>

        {/* segmented tabs */}
        <div style={{ display: 'flex', gap: 6, padding: '0 18px', overflowX: 'auto' }}>
          {[
            ['itinerary', 'Itinéraire'],
            ['budget', 'Budget'],
            ['spots', 'Spots'],
            ['flights', 'Vols'],
            ['notes', 'Notes'],
          ].map(([id, lbl]) => (
            <Pill key={id} active={tab === id} onClick={() => setTab(id)}>{lbl}</Pill>
          ))}
        </div>

        {/* content */}
        <div style={{ padding: '18px 18px 130px', display: 'flex', flexDirection: 'column', gap: 12, overflowY: 'auto', maxHeight: 'calc(100vh - 540px)' }}>
          {tab === 'itinerary' && (
            <>
              {[
                { d: '12', mois: 'mai', day: 'Aujourd\'hui', items: [
                  { t: '14:20', l: 'Arrivée aéroport Humberto Delgado', c: T.blue, i: I.plane },
                  { t: '16:00', l: 'Check-in · Memmo Alfama', c: T.rose, i: I.hotel },
                  { t: '20:30', l: 'Dîner · A Cevicheria', c: T.gold, i: I.food },
                ]},
                { d: '13', mois: 'mai', day: 'Mardi', items: [
                  { t: '10:00', l: 'Tram 28 → Castelo São Jorge', c: T.accent2, i: I.bus },
                  { t: '15:00', l: 'Quartier Alfama · à pied', c: T.mint, i: I.spot },
                ]},
              ].map(d => (
                <Card key={d.d} padding={16}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 12 }}>
                    <div style={{
                      width: 44, height: 50, borderRadius: 12,
                      background: 'rgba(139,92,246,0.15)', border: `1px solid ${T.borderStrong}`,
                      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: -0.5 }}>{d.d}</div>
                      <div style={{ fontSize: 9, color: T.textMute, textTransform: 'uppercase' }}>{d.mois}</div>
                    </div>
                    <div>
                      <div style={{ fontSize: 15, fontWeight: 700 }}>{d.day}</div>
                      <div style={{ fontSize: 12, color: T.textMute }}>{d.items.length} étapes</div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 10, paddingLeft: 6 }}>
                    {d.items.map((it, i) => (
                      <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                        <div style={{
                          width: 34, height: 34, borderRadius: 10, flexShrink: 0,
                          background: `${it.c}22`, display: 'flex', alignItems: 'center', justifyContent: 'center',
                        }}><it.i size={16} stroke={it.c}/></div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontSize: 11, color: T.textMute, fontWeight: 600 }}>{it.t}</div>
                          <div style={{ fontSize: 14, marginTop: 1 }}>{it.l}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
              ))}
            </>
          )}
          {tab !== 'itinerary' && (
            <Card padding={18}>
              <div style={{ fontSize: 14, color: T.textMute, textAlign: 'center', padding: '20px 0' }}>
                Onglet «&nbsp;{tab}&nbsp;» — voir l'écran dédié.
              </div>
            </Card>
          )}
        </div>
      </div>
      <TabBar active="trips" onChange={onNav}/>
    </Screen>
  );
}

Object.assign(window, { TRIPS, HomeScreen, TripDetailScreen, IconBtn, Avatar });
