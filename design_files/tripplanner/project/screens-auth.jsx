// Login + Onboarding-ish auth screen (matches user reference)

function LoginScreen() {
  return (
    <Screen>
      <StatusBar/>
      <div style={{ padding: '40px 28px 28px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18 }}>
        <div style={{ marginTop: 28 }}><Logo size={108}/></div>
        <div style={{ fontSize: 38, fontWeight: 800, letterSpacing: -1.2, marginTop: 4 }}>Tripnest</div>
        <div style={{ fontSize: 17, color: T.textMute, marginTop: -8 }}>Bon retour&nbsp;!</div>
      </div>

      <div style={{ padding: '20px 24px 0', display: 'flex', flexDirection: 'column', gap: 18 }}>
        <Card padding={26} style={{ borderRadius: 28 }}>
          <Field label="IDENTIFIANT" placeholder="Identifiant"/>
          <div style={{ height: 22 }}/>
          <Field label="MOT DE PASSE" placeholder="Mot de passe" type="password"/>
          <div style={{ textAlign: 'right', marginTop: 14, fontSize: 13, fontWeight: 600, color: T.text }}>Mot de passe oublié</div>

          <button style={{
            marginTop: 18, width: '100%', height: 56,
            borderRadius: 18,
            background: `linear-gradient(180deg, ${T.accent2} 0%, ${T.accentDeep} 100%)`,
            color: '#fff', fontSize: 17, fontWeight: 700,
            border: '1px solid rgba(167,139,250,0.4)',
            boxShadow: '0 12px 28px rgba(139,92,246,0.35), inset 0 1px 0 rgba(255,255,255,0.18)',
            fontFamily: T.font, letterSpacing: -0.2, cursor: 'pointer',
          }}>Se connecter</button>

          <div style={{ textAlign: 'center', marginTop: 22, fontSize: 15, fontWeight: 700, color: T.accent2 }}>
            Création de compte
          </div>
        </Card>
      </div>
    </Screen>
  );
}

function Field({ label, placeholder, type = 'text', value = '' }) {
  return (
    <div>
      <div style={{ fontSize: 12, fontWeight: 700, color: T.textMute, letterSpacing: 1.5, marginBottom: 10 }}>{label}</div>
      <div style={{
        height: 52, borderRadius: 14,
        background: 'rgba(139,92,246,0.05)',
        border: `1px solid ${T.borderStrong}`,
        display: 'flex', alignItems: 'center', padding: '0 18px',
        color: value ? T.text : T.textDim, fontSize: 16,
      }}>{value || placeholder}</div>
    </div>
  );
}

Object.assign(window, { LoginScreen, Field });
