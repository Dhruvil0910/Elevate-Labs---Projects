import { useState } from "react";

// ── Design tokens ────────────────────────────────────────────────
const T = {
  navy:    "#0A0F1E",
  navyMid: "#0F1628",
  card:    "#141B2D",
  cardHi:  "#1A2340",
  border:  "#1E2D4A",
  cyan:    "#00D4FF",
  cyanDim: "#0099BB",
  amber:   "#FFB800",
  red:     "#FF4560",
  green:   "#00E396",
  text:    "#E8EDF5",
  muted:   "#6B7A99",
  ghost:   "#2A3550",
};

// ── Tiny helpers ─────────────────────────────────────────────────
const Badge = ({ label, color = T.cyan }) => (
  <span style={{
    background: color + "22", color, border: `1px solid ${color}44`,
    borderRadius: 4, padding: "2px 8px", fontSize: 11, fontWeight: 600,
    letterSpacing: ".5px", whiteSpace: "nowrap"
  }}>{label}</span>
);

const Pill = ({ children, active, onClick }) => (
  <button onClick={onClick} style={{
    background: active ? T.cyan : "transparent",
    color: active ? T.navy : T.muted,
    border: `1px solid ${active ? T.cyan : T.border}`,
    borderRadius: 20, padding: "5px 14px", fontSize: 12,
    fontWeight: 600, cursor: "pointer", transition: "all .2s"
  }}>{children}</button>
);

const Input = ({ label, type = "text", placeholder, icon, value, onChange }) => (
  <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
    <label style={{ fontSize: 11, color: T.muted, fontWeight: 600, letterSpacing: ".5px" }}>{label}</label>
    <div style={{ position: "relative" }}>
      {icon && <span style={{
        position: "absolute", left: 12, top: "50%", transform: "translateY(-50%)",
        fontSize: 15, opacity: .5
      }}>{icon}</span>}
      <input type={type} placeholder={placeholder} value={value} onChange={onChange}
        style={{
          width: "100%", background: T.navyMid, border: `1px solid ${T.border}`,
          borderRadius: 8, padding: icon ? "10px 12px 10px 36px" : "10px 12px",
          color: T.text, fontSize: 13, outline: "none", boxSizing: "border-box",
          fontFamily: "inherit"
        }}
      />
    </div>
  </div>
);

const Btn = ({ children, onClick, variant = "primary", full, small, disabled }) => {
  const styles = {
    primary: { background: `linear-gradient(135deg, ${T.cyan}, ${T.cyanDim})`, color: T.navy },
    danger:  { background: `linear-gradient(135deg, ${T.red}, #c0392b)`, color: "#fff" },
    ghost:   { background: "transparent", color: T.cyan, border: `1px solid ${T.cyan}44` },
    amber:   { background: `linear-gradient(135deg, ${T.amber}, #cc9200)`, color: T.navy },
  };
  return (
    <button onClick={onClick} disabled={disabled} style={{
      ...styles[variant],
      borderRadius: 8, padding: small ? "6px 14px" : "10px 20px",
      fontWeight: 700, fontSize: small ? 12 : 13, cursor: disabled ? "not-allowed" : "pointer",
      border: "none", width: full ? "100%" : "auto", opacity: disabled ? .5 : 1,
      transition: "opacity .2s", fontFamily: "inherit"
    }}>{children}</button>
  );
};

const Card = ({ children, style }) => (
  <div style={{
    background: T.card, border: `1px solid ${T.border}`,
    borderRadius: 12, padding: 20, ...style
  }}>{children}</div>
);

// Pulsing threat dot
const ThreatDot = ({ level }) => {
  const colors = { high: T.red, medium: T.amber, low: T.green };
  const c = colors[level] || T.green;
  return (
    <span style={{
      display: "inline-block", width: 8, height: 8, borderRadius: "50%",
      background: c, boxShadow: `0 0 6px ${c}`, marginRight: 6,
      animation: level === "high" ? "pulse 1.2s infinite" : "none"
    }} />
  );
};

// ── SCREEN: REGISTER ─────────────────────────────────────────────
function RegisterScreen({ onNavigate }) {
  const [form, setForm] = useState({ name: "", email: "", password: "", confirm: "", role: "analyst" });
  const set = k => e => setForm(f => ({ ...f, [k]: e.target.value }));

  return (
    <div style={{
      minHeight: "100vh", background: T.navy, display: "flex",
      alignItems: "center", justifyContent: "center",
      backgroundImage: `radial-gradient(ellipse at 20% 50%, #0D1F3C 0%, transparent 60%),
                        radial-gradient(ellipse at 80% 20%, #001830 0%, transparent 50%)`
    }}>
      <style>{`@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}`}</style>

      <div style={{ width: 420 }}>
        {/* Logo */}
        <div style={{ textAlign: "center", marginBottom: 36 }}>
          <div style={{
            display: "inline-flex", alignItems: "center", gap: 10,
            marginBottom: 8
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: `linear-gradient(135deg, ${T.cyan}33, ${T.cyan}11)`,
              border: `1px solid ${T.cyan}44`,
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 20
            }}>🛡</div>
            <span style={{ color: T.text, fontSize: 22, fontWeight: 800, letterSpacing: -1 }}>
              Sentinel<span style={{ color: T.cyan }}>FD</span>
            </span>
          </div>
          <p style={{ color: T.muted, fontSize: 13, margin: 0 }}>
            Fraud Detection Intelligence Platform
          </p>
        </div>

        <Card>
          <h2 style={{ color: T.text, margin: "0 0 4px", fontSize: 18, fontWeight: 700 }}>
            Create account
          </h2>
          <p style={{ color: T.muted, fontSize: 13, margin: "0 0 24px" }}>
            Join your organisation's fraud unit
          </p>

          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            <Input label="FULL NAME" icon="👤" placeholder="Dhruvil Bhatt"
              value={form.name} onChange={set("name")} />
            <Input label="WORK EMAIL" icon="✉" placeholder="you@organisation.com"
              value={form.email} onChange={set("email")} />
            <Input label="PASSWORD" type="password" icon="🔒" placeholder="Min. 8 characters"
              value={form.password} onChange={set("password")} />
            <Input label="CONFIRM PASSWORD" type="password" icon="🔒" placeholder="Repeat password"
              value={form.confirm} onChange={set("confirm")} />

            {/* Role selector */}
            <div>
              <label style={{ fontSize: 11, color: T.muted, fontWeight: 600, letterSpacing: ".5px", display: "block", marginBottom: 8 }}>
                ROLE
              </label>
              <div style={{ display: "flex", gap: 8 }}>
                {["analyst", "admin", "viewer"].map(r => (
                  <Pill key={r} active={form.role === r} onClick={() => setForm(f => ({ ...f, role: r }))}>
                    {r.charAt(0).toUpperCase() + r.slice(1)}
                  </Pill>
                ))}
              </div>
            </div>

            <Btn full onClick={() => onNavigate("login")}>Create account</Btn>

            <p style={{ textAlign: "center", color: T.muted, fontSize: 13, margin: 0 }}>
              Already registered?{" "}
              <span style={{ color: T.cyan, cursor: "pointer", fontWeight: 600 }}
                onClick={() => onNavigate("login")}>Sign in</span>
            </p>
          </div>
        </Card>
      </div>
    </div>
  );
}

// ── SCREEN: LOGIN ────────────────────────────────────────────────
function LoginScreen({ onNavigate }) {
  const [form, setForm] = useState({ email: "", password: "" });
  const [loading, setLoading] = useState(false);
  const set = k => e => setForm(f => ({ ...f, [k]: e.target.value }));

  const handleLogin = () => {
    setLoading(true);
    setTimeout(() => { setLoading(false); onNavigate("dashboard"); }, 1200);
  };

  return (
    <div style={{
      minHeight: "100vh", background: T.navy,
      display: "flex", alignItems: "center", justifyContent: "center",
      backgroundImage: `radial-gradient(ellipse at 80% 50%, #0D1F3C 0%, transparent 60%)`
    }}>
      <div style={{ width: 400 }}>
        <div style={{ textAlign: "center", marginBottom: 36 }}>
          <div style={{
            display: "inline-flex", alignItems: "center", gap: 10, marginBottom: 8
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 10,
              background: `linear-gradient(135deg, ${T.cyan}33, ${T.cyan}11)`,
              border: `1px solid ${T.cyan}44`,
              display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20
            }}>🛡</div>
            <span style={{ color: T.text, fontSize: 22, fontWeight: 800, letterSpacing: -1 }}>
              Sentinel<span style={{ color: T.cyan }}>FD</span>
            </span>
          </div>
          <p style={{ color: T.muted, fontSize: 13, margin: 0 }}>
            Fraud Detection Intelligence Platform
          </p>
        </div>

        <Card>
          <h2 style={{ color: T.text, margin: "0 0 4px", fontSize: 18, fontWeight: 700 }}>
            Sign in
          </h2>
          <p style={{ color: T.muted, fontSize: 13, margin: "0 0 24px" }}>
            Access the intelligence console
          </p>

          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            <Input label="EMAIL" icon="✉" placeholder="you@organisation.com"
              value={form.email} onChange={set("email")} />
            <Input label="PASSWORD" type="password" icon="🔒" placeholder="••••••••"
              value={form.password} onChange={set("password")} />

            <div style={{ display: "flex", justifyContent: "flex-end" }}>
              <span style={{ color: T.cyan, fontSize: 12, cursor: "pointer", fontWeight: 600 }}>
                Forgot password?
              </span>
            </div>

            <Btn full onClick={handleLogin} disabled={loading}>
              {loading ? "Authenticating…" : "Sign in"}
            </Btn>

            <div style={{
              display: "flex", alignItems: "center", gap: 10,
              padding: "10px 12px", borderRadius: 8,
              background: T.cyan + "11", border: `1px solid ${T.cyan}33`
            }}>
              <span style={{ fontSize: 16 }}>🔐</span>
              <span style={{ color: T.muted, fontSize: 12 }}>
                Secured with end-to-end encryption
              </span>
            </div>

            <p style={{ textAlign: "center", color: T.muted, fontSize: 13, margin: 0 }}>
              New analyst?{" "}
              <span style={{ color: T.cyan, cursor: "pointer", fontWeight: 600 }}
                onClick={() => onNavigate("register")}>Request access</span>
            </p>
          </div>
        </Card>
      </div>
    </div>
  );
}

// ── SHARED: SIDEBAR ──────────────────────────────────────────────
const NAV = [
  { icon: "⬡", label: "Dashboard",   screen: "dashboard" },
  { icon: "🔍", label: "Scan",        screen: "scan" },
  { icon: "📁", label: "Batch Upload",screen: "batch" },
  { icon: "👤", label: "My Profile",  screen: "profile" },
];

function Sidebar({ active, onNavigate, onLogout }) {
  return (
    <div style={{
      width: 220, background: T.navyMid, borderRight: `1px solid ${T.border}`,
      display: "flex", flexDirection: "column", minHeight: "100vh", flexShrink: 0
    }}>
      {/* Logo */}
      <div style={{
        padding: "20px 16px 16px", borderBottom: `1px solid ${T.border}`,
        display: "flex", alignItems: "center", gap: 10
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: `linear-gradient(135deg, ${T.cyan}33, ${T.cyan}11)`,
          border: `1px solid ${T.cyan}44`,
          display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16
        }}>🛡</div>
        <span style={{ color: T.text, fontSize: 16, fontWeight: 800, letterSpacing: -0.5 }}>
          Sentinel<span style={{ color: T.cyan }}>FD</span>
        </span>
      </div>

      {/* System status */}
      <div style={{ padding: "12px 16px", borderBottom: `1px solid ${T.border}` }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 6,
          padding: "6px 10px", borderRadius: 6,
          background: T.green + "11", border: `1px solid ${T.green}33`
        }}>
          <ThreatDot level="low" />
          <span style={{ color: T.green, fontSize: 11, fontWeight: 600 }}>SYSTEM OPERATIONAL</span>
        </div>
      </div>

      {/* Nav items */}
      <nav style={{ flex: 1, padding: "12px 10px" }}>
        {NAV.map(n => (
          <button key={n.screen} onClick={() => onNavigate(n.screen)} style={{
            width: "100%", display: "flex", alignItems: "center", gap: 10,
            padding: "10px 12px", borderRadius: 8, marginBottom: 2,
            background: active === n.screen ? T.cyan + "18" : "transparent",
            border: active === n.screen ? `1px solid ${T.cyan}33` : "1px solid transparent",
            color: active === n.screen ? T.cyan : T.muted,
            fontSize: 13, fontWeight: active === n.screen ? 600 : 400,
            cursor: "pointer", textAlign: "left", transition: "all .15s",
            fontFamily: "inherit"
          }}>
            <span style={{ fontSize: 16 }}>{n.icon}</span>
            {n.label}
          </button>
        ))}
      </nav>

      {/* User mini-card + logout */}
      <div style={{ padding: 12, borderTop: `1px solid ${T.border}` }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 10,
          padding: "8px 10px", borderRadius: 8, marginBottom: 8,
          background: T.card
        }}>
          <div style={{
            width: 32, height: 32, borderRadius: "50%",
            background: `linear-gradient(135deg, ${T.cyan}, ${T.cyanDim})`,
            display: "flex", alignItems: "center", justifyContent: "center",
            color: T.navy, fontWeight: 800, fontSize: 13, flexShrink: 0
          }}>DB</div>
          <div style={{ overflow: "hidden" }}>
            <div style={{ color: T.text, fontSize: 12, fontWeight: 600, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
              Dhruvil Bhatt
            </div>
            <div style={{ color: T.muted, fontSize: 11 }}>Analyst</div>
          </div>
        </div>
        <button onClick={onLogout} style={{
          width: "100%", padding: "8px", borderRadius: 8,
          background: T.red + "11", border: `1px solid ${T.red}33`,
          color: T.red, fontSize: 12, fontWeight: 600, cursor: "pointer",
          fontFamily: "inherit"
        }}>⬡ Sign out</button>
      </div>
    </div>
  );
}

// ── SCREEN: DASHBOARD ────────────────────────────────────────────
const MOCK_HISTORY = [
  { id: "TXN20240901-A3F9K2", amount: 4820.50, result: "FRAUD",      score: 0.94, date: "2024-09-01 14:32", votes: 3 },
  { id: "TXN20240901-B7C2M1", amount: 120.00,  result: "LEGITIMATE", score: 0.08, date: "2024-09-01 13:10", votes: 0 },
  { id: "TXN20240831-ZQ91X4", amount: 9999.00, result: "FRAUD",      score: 0.87, date: "2024-08-31 22:55", votes: 2 },
  { id: "TXN20240831-KP33W7", amount: 55.20,   result: "LEGITIMATE", score: 0.11, date: "2024-08-31 10:04", votes: 1 },
  { id: "TXN20240830-MN44T9", amount: 2350.75, result: "FRAUD",      score: 0.76, date: "2024-08-30 09:18", votes: 2 },
];

function StatCard({ icon, label, value, sub, accent }) {
  return (
    <div style={{
      background: T.card, border: `1px solid ${T.border}`,
      borderRadius: 12, padding: "18px 20px",
      borderLeft: `3px solid ${accent || T.cyan}`
    }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <div>
          <div style={{ color: T.muted, fontSize: 11, fontWeight: 600, marginBottom: 6, letterSpacing: ".4px" }}>
            {label}
          </div>
          <div style={{ color: T.text, fontSize: 26, fontWeight: 800, lineHeight: 1 }}>
            {value}
          </div>
          {sub && <div style={{ color: T.muted, fontSize: 11, marginTop: 4 }}>{sub}</div>}
        </div>
        <span style={{ fontSize: 22, opacity: .7 }}>{icon}</span>
      </div>
    </div>
  );
}

function DashboardScreen() {
  const [filter, setFilter] = useState("all");
  const filtered = MOCK_HISTORY.filter(t =>
    filter === "all" ? true : t.result.toLowerCase() === filter
  );

  return (
    <div style={{ flex: 1, overflow: "auto", background: T.navy }}>
      {/* Top bar */}
      <div style={{
        padding: "16px 28px", borderBottom: `1px solid ${T.border}`,
        display: "flex", justifyContent: "space-between", alignItems: "center",
        background: T.navyMid
      }}>
        <div>
          <h1 style={{ color: T.text, margin: 0, fontSize: 18, fontWeight: 700 }}>
            Intelligence Dashboard
          </h1>
          <p style={{ color: T.muted, margin: "2px 0 0", fontSize: 12 }}>
            Wednesday, 01 September 2026 — Live monitoring
          </p>
        </div>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <ThreatDot level="medium" />
          <span style={{ color: T.amber, fontSize: 12, fontWeight: 600 }}>2 alerts today</span>
        </div>
      </div>

      <div style={{ padding: 28 }}>
        {/* Stat cards */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 16, marginBottom: 28 }}>
          <StatCard icon="📊" label="TOTAL SCANNED" value="1,284" sub="This month" accent={T.cyan} />
          <StatCard icon="🚨" label="FRAUD DETECTED" value="47" sub="3.66% rate" accent={T.red} />
          <StatCard icon="✅" label="LEGITIMATE" value="1,237" sub="96.34% cleared" accent={T.green} />
          <StatCard icon="⚡" label="AVG SCORE" value="0.82" sub="Fraud confidence" accent={T.amber} />
        </div>

        {/* User banner */}
        <div style={{
          background: T.card, border: `1px solid ${T.border}`,
          borderRadius: 12, padding: 20, marginBottom: 24,
          display: "flex", alignItems: "center", gap: 20
        }}>
          <div style={{
            width: 60, height: 60, borderRadius: "50%", flexShrink: 0,
            background: `linear-gradient(135deg, ${T.cyan}, ${T.cyanDim})`,
            display: "flex", alignItems: "center", justifyContent: "center",
            color: T.navy, fontWeight: 900, fontSize: 22,
            boxShadow: `0 0 20px ${T.cyan}44`
          }}>DB</div>
          <div style={{ flex: 1 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
              <span style={{ color: T.text, fontSize: 17, fontWeight: 700 }}>Dhruvil Bhatt</span>
              <Badge label="ANALYST" color={T.cyan} />
              <Badge label="ACTIVE" color={T.green} />
            </div>
            <div style={{ color: T.muted, fontSize: 12 }}>
              bhattdhruvil2005@gmail.com · Joined Sep 2024 · CHARUSAT Intelligence Unit
            </div>
          </div>
          <div style={{ display: "flex", gap: 24, textAlign: "center" }}>
            {[
              { label: "Scans run", val: "342" },
              { label: "Fraud found", val: "28" },
              { label: "Batch jobs", val: "14" },
            ].map(s => (
              <div key={s.label}>
                <div style={{ color: T.cyan, fontSize: 20, fontWeight: 800 }}>{s.val}</div>
                <div style={{ color: T.muted, fontSize: 11 }}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent transactions table */}
        <Card>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
            <h3 style={{ color: T.text, margin: 0, fontSize: 14, fontWeight: 700 }}>
              Recent Transactions
            </h3>
            <div style={{ display: "flex", gap: 6 }}>
              {["all", "fraud", "legitimate"].map(f => (
                <Pill key={f} active={filter === f} onClick={() => setFilter(f)}>
                  {f.charAt(0).toUpperCase() + f.slice(1)}
                </Pill>
              ))}
            </div>
          </div>

          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ borderBottom: `1px solid ${T.border}` }}>
                {["Transaction ID", "Amount", "Verdict", "Score", "Votes", "Time"].map(h => (
                  <th key={h} style={{
                    color: T.muted, fontSize: 11, fontWeight: 600, textAlign: "left",
                    padding: "8px 10px", letterSpacing: ".4px"
                  }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((t, i) => (
                <tr key={t.id} style={{
                  borderBottom: `1px solid ${T.border}22`,
                  background: i % 2 === 0 ? "transparent" : T.navyMid + "44"
                }}>
                  <td style={{ padding: "10px 10px", color: T.cyan, fontSize: 12, fontFamily: "monospace" }}>
                    {t.id}
                  </td>
                  <td style={{ padding: "10px 10px", color: T.text, fontSize: 13, fontWeight: 600 }}>
                    ${t.amount.toFixed(2)}
                  </td>
                  <td style={{ padding: "10px 10px" }}>
                    <Badge
                      label={t.result}
                      color={t.result === "FRAUD" ? T.red : T.green}
                    />
                  </td>
                  <td style={{ padding: "10px 10px" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                      <div style={{
                        width: 60, height: 4, borderRadius: 2, background: T.ghost,
                        overflow: "hidden"
                      }}>
                        <div style={{
                          width: `${t.score * 100}%`, height: "100%", borderRadius: 2,
                          background: t.score > .6 ? T.red : T.green
                        }} />
                      </div>
                      <span style={{ color: T.muted, fontSize: 11 }}>{t.score.toFixed(2)}</span>
                    </div>
                  </td>
                  <td style={{ padding: "10px 10px", color: T.muted, fontSize: 12 }}>
                    {t.votes}/3
                  </td>
                  <td style={{ padding: "10px 10px", color: T.muted, fontSize: 11, fontFamily: "monospace" }}>
                    {t.date}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      </div>
    </div>
  );
}

// ── SCREEN: SCAN (single transaction) ────────────────────────────
function ScanScreen() {
  const [form, setForm] = useState({ txnId: "", amount: "", time: "" });
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const set = k => e => setForm(f => ({ ...f, [k]: e.target.value }));

  const scan = () => {
    setLoading(true); setResult(null);
    setTimeout(() => {
      setLoading(false);
      setResult({
        prediction: "FRAUD", is_fraud: true, fraud_score: 0.8742,
        votes: 2, isolation_forest: "FRAUD", lof: "LEGITIMATE", xgboost: "FRAUD",
        transaction_id: form.txnId || "TXN20240901-AUTO01"
      });
    }, 1800);
  };

  return (
    <div style={{ flex: 1, overflow: "auto", background: T.navy, padding: 28 }}>
      <div style={{ maxWidth: 720, margin: "0 auto" }}>
        <h2 style={{ color: T.text, margin: "0 0 4px", fontSize: 18, fontWeight: 700 }}>
          Transaction Scanner
        </h2>
        <p style={{ color: T.muted, fontSize: 13, margin: "0 0 24px" }}>
          Submit a single credit card transaction for real-time fraud analysis
        </p>

        <Card style={{ marginBottom: 20 }}>
          <h3 style={{ color: T.cyan, fontSize: 13, fontWeight: 600, margin: "0 0 16px" }}>
            Transaction Details
          </h3>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, marginBottom: 16 }}>
            <Input label="TRANSACTION ID (optional)" icon="🔑"
              placeholder="Auto-generated if blank" value={form.txnId} onChange={set("txnId")} />
            <Input label="AMOUNT ($)" icon="💳" type="number"
              placeholder="e.g. 4820.50" value={form.amount} onChange={set("amount")} />
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, marginBottom: 16 }}>
            <Input label="TIME (seconds since first txn)" icon="⏱"
              type="number" placeholder="e.g. 86400"
              value={form.time} onChange={set("time")} />
            <div>
              <label style={{ fontSize: 11, color: T.muted, fontWeight: 600, letterSpacing: ".5px", display: "block", marginBottom: 6 }}>
                SOURCE
              </label>
              <div style={{ display: "flex", gap: 6, marginTop: 2 }}>
                {["Manual", "POS", "Online", "ATM"].map(s => (
                  <Pill key={s} active={s === "Manual"}>{s}</Pill>
                ))}
              </div>
            </div>
          </div>

          {/* V1-V28 collapsed */}
          <div style={{
            padding: 12, borderRadius: 8,
            background: T.navyMid, border: `1px solid ${T.border}`,
            marginBottom: 16
          }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <span style={{ color: T.muted, fontSize: 12 }}>
                V1–V28 PCA features
              </span>
              <Badge label="DEFAULT 0.0 — expand to override" color={T.muted} />
            </div>
          </div>

          <Btn onClick={scan} disabled={loading || !form.amount}>
            {loading ? "⟳ Analysing…" : "🔍 Run fraud scan"}
          </Btn>
        </Card>

        {/* Result card */}
        {loading && (
          <Card style={{ textAlign: "center", padding: 40 }}>
            <div style={{ color: T.cyan, fontSize: 28, marginBottom: 12 }}>⟳</div>
            <div style={{ color: T.muted, fontSize: 13 }}>
              Running through Isolation Forest · LOF · XGBoost…
            </div>
          </Card>
        )}

        {result && (
          <Card style={{
            border: `1px solid ${result.is_fraud ? T.red : T.green}66`,
            background: result.is_fraud ? T.red + "08" : T.green + "08"
          }}>
            {/* Verdict banner */}
            <div style={{
              display: "flex", alignItems: "center", justifyContent: "space-between",
              marginBottom: 20, paddingBottom: 16, borderBottom: `1px solid ${T.border}`
            }}>
              <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
                <span style={{ fontSize: 40 }}>{result.is_fraud ? "🚨" : "✅"}</span>
                <div>
                  <div style={{
                    fontSize: 24, fontWeight: 900,
                    color: result.is_fraud ? T.red : T.green
                  }}>{result.prediction}</div>
                  <div style={{ color: T.muted, fontSize: 12, fontFamily: "monospace" }}>
                    {result.transaction_id}
                  </div>
                </div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ color: T.muted, fontSize: 11, marginBottom: 2 }}>FRAUD PROBABILITY</div>
                <div style={{
                  fontSize: 32, fontWeight: 900,
                  color: result.is_fraud ? T.red : T.green
                }}>{(result.fraud_score * 100).toFixed(1)}%</div>
              </div>
            </div>

            {/* Model breakdown */}
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12 }}>
              {[
                { name: "Isolation Forest", val: result.isolation_forest },
                { name: "Local Outlier Factor", val: result.lof },
                { name: "XGBoost", val: result.xgboost },
              ].map(m => (
                <div key={m.name} style={{
                  padding: 14, borderRadius: 8, background: T.card,
                  border: `1px solid ${m.val === "FRAUD" ? T.red + "44" : T.green + "44"}`,
                  textAlign: "center"
                }}>
                  <div style={{ color: T.muted, fontSize: 11, marginBottom: 6 }}>{m.name}</div>
                  <Badge label={m.val} color={m.val === "FRAUD" ? T.red : T.green} />
                </div>
              ))}
            </div>

            <div style={{ marginTop: 16, display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <Btn variant="ghost" small>Export report</Btn>
              <Btn variant={result.is_fraud ? "danger" : "ghost"} small>
                {result.is_fraud ? "Flag for review" : "Mark as verified"}
              </Btn>
            </div>
          </Card>
        )}
      </div>
    </div>
  );
}

// ── SCREEN: BATCH UPLOAD ─────────────────────────────────────────
function BatchScreen() {
  const [dragging, setDragging] = useState(false);
  const [file, setFile] = useState(null);
  const [progress, setProgress] = useState(0);
  const [done, setDone] = useState(false);

  const handleFile = f => { setFile(f); setProgress(0); setDone(false); };

  const runBatch = () => {
    let p = 0;
    const iv = setInterval(() => {
      p += Math.random() * 18;
      if (p >= 100) { p = 100; clearInterval(iv); setDone(true); }
      setProgress(Math.min(p, 100));
    }, 200);
  };

  const BATCH_RESULTS = [
    { id: "TXN-B001", amount: 4820.50, result: "FRAUD",      score: 0.94 },
    { id: "TXN-B002", amount: 23.00,   result: "LEGITIMATE", score: 0.04 },
    { id: "TXN-B003", amount: 9999.00, result: "FRAUD",      score: 0.89 },
    { id: "TXN-B004", amount: 112.50,  result: "LEGITIMATE", score: 0.12 },
  ];

  return (
    <div style={{ flex: 1, overflow: "auto", background: T.navy, padding: 28 }}>
      <div style={{ maxWidth: 760, margin: "0 auto" }}>
        <h2 style={{ color: T.text, margin: "0 0 4px", fontSize: 18, fontWeight: 700 }}>
          Batch Analysis
        </h2>
        <p style={{ color: T.muted, fontSize: 13, margin: "0 0 24px" }}>
          Upload a CSV file to scan multiple transactions simultaneously
        </p>

        {/* Drop zone */}
        <div
          onDragOver={e => { e.preventDefault(); setDragging(true); }}
          onDragLeave={() => setDragging(false)}
          onDrop={e => { e.preventDefault(); setDragging(false); handleFile(e.dataTransfer.files[0]); }}
          style={{
            border: `2px dashed ${dragging ? T.cyan : file ? T.green : T.border}`,
            borderRadius: 12, padding: "40px 20px", textAlign: "center",
            marginBottom: 20, transition: "all .2s",
            background: dragging ? T.cyan + "08" : file ? T.green + "08" : T.card,
            cursor: "pointer"
          }}
          onClick={() => document.getElementById("csv-input").click()}
        >
          <input id="csv-input" type="file" accept=".csv" style={{ display: "none" }}
            onChange={e => handleFile(e.target.files[0])} />
          <div style={{ fontSize: 40, marginBottom: 12 }}>
            {file ? "📄" : "📂"}
          </div>
          {file ? (
            <>
              <div style={{ color: T.green, fontWeight: 700, fontSize: 15, marginBottom: 4 }}>
                {file.name}
              </div>
              <div style={{ color: T.muted, fontSize: 12 }}>
                {(file.size / 1024).toFixed(1)} KB · Click to replace
              </div>
            </>
          ) : (
            <>
              <div style={{ color: T.text, fontWeight: 600, fontSize: 15, marginBottom: 4 }}>
                Drop your CSV file here
              </div>
              <div style={{ color: T.muted, fontSize: 12 }}>
                or click to browse · Must include Time, Amount, V1–V28 columns
              </div>
            </>
          )}
        </div>

        {/* CSV format hint */}
        <Card style={{ marginBottom: 20 }}>
          <div style={{ color: T.cyan, fontSize: 12, fontWeight: 600, marginBottom: 8 }}>
            Required CSV format
          </div>
          <div style={{
            fontFamily: "monospace", fontSize: 11, color: T.muted,
            background: T.navyMid, padding: 10, borderRadius: 6,
            overflowX: "auto", whiteSpace: "nowrap"
          }}>
            Time,V1,V2,V3,...,V28,Amount<br />
            406.0,-2.31,1.95,-1.60,...,0.13,149.62<br />
            472.0,1.19,0.26,0.16,...,-0.33,2.69
          </div>
        </Card>

        {file && !done && (
          <div style={{ marginBottom: 20 }}>
            <Btn onClick={runBatch}>⚡ Start batch scan</Btn>
          </div>
        )}

        {/* Progress bar */}
        {progress > 0 && (
          <Card style={{ marginBottom: 20 }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
              <span style={{ color: T.text, fontSize: 13, fontWeight: 600 }}>
                {done ? "Analysis complete" : "Scanning transactions…"}
              </span>
              <span style={{ color: T.cyan, fontSize: 13, fontWeight: 700 }}>
                {Math.round(progress)}%
              </span>
            </div>
            <div style={{ height: 6, background: T.ghost, borderRadius: 3, overflow: "hidden" }}>
              <div style={{
                width: `${progress}%`, height: "100%", borderRadius: 3,
                background: done
                  ? `linear-gradient(90deg, ${T.green}, ${T.cyan})`
                  : `linear-gradient(90deg, ${T.cyan}, ${T.cyanDim})`,
                transition: "width .3s"
              }} />
            </div>
            {done && (
              <div style={{ display: "flex", gap: 16, marginTop: 12 }}>
                <span style={{ color: T.red, fontSize: 12 }}>🚨 2 FRAUD detected</span>
                <span style={{ color: T.green, fontSize: 12 }}>✅ 2 LEGITIMATE</span>
                <span style={{ color: T.muted, fontSize: 12 }}>Total: 4 transactions</span>
              </div>
            )}
          </Card>
        )}

        {/* Batch results table */}
        {done && (
          <Card>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
              <h3 style={{ color: T.text, margin: 0, fontSize: 14, fontWeight: 700 }}>Batch Results</h3>
              <Btn variant="ghost" small>⬇ Download report</Btn>
            </div>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr style={{ borderBottom: `1px solid ${T.border}` }}>
                  {["Transaction ID", "Amount", "Verdict", "Score"].map(h => (
                    <th key={h} style={{ color: T.muted, fontSize: 11, fontWeight: 600, padding: "8px 10px", textAlign: "left" }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {BATCH_RESULTS.map(r => (
                  <tr key={r.id} style={{ borderBottom: `1px solid ${T.border}22` }}>
                    <td style={{ padding: "10px 10px", color: T.cyan, fontSize: 12, fontFamily: "monospace" }}>{r.id}</td>
                    <td style={{ padding: "10px 10px", color: T.text, fontWeight: 600 }}>${r.amount.toFixed(2)}</td>
                    <td style={{ padding: "10px 10px" }}>
                      <Badge label={r.result} color={r.result === "FRAUD" ? T.red : T.green} />
                    </td>
                    <td style={{ padding: "10px 10px", color: r.score > .6 ? T.red : T.green, fontWeight: 700 }}>
                      {(r.score * 100).toFixed(1)}%
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
        )}
      </div>
    </div>
  );
}

// ── SCREEN: PROFILE ──────────────────────────────────────────────
function ProfileScreen() {
  const [tab, setTab] = useState("info");
  const tabs = ["info", "history", "uploads", "security"];

  return (
    <div style={{ flex: 1, overflow: "auto", background: T.navy }}>
      {/* Profile banner */}
      <div style={{
        background: `linear-gradient(135deg, ${T.navyMid}, #0D1628)`,
        borderBottom: `1px solid ${T.border}`,
        padding: "28px 32px 0"
      }}>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 20, marginBottom: 24 }}>
          <div style={{
            width: 80, height: 80, borderRadius: "50%", flexShrink: 0,
            background: `linear-gradient(135deg, ${T.cyan}, ${T.cyanDim})`,
            display: "flex", alignItems: "center", justifyContent: "center",
            color: T.navy, fontWeight: 900, fontSize: 30,
            boxShadow: `0 0 30px ${T.cyan}55`,
            border: `3px solid ${T.navy}`
          }}>DB</div>
          <div style={{ flex: 1, paddingBottom: 4 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
              <h2 style={{ color: T.text, margin: 0, fontSize: 22, fontWeight: 800 }}>Dhruvil Bhatt</h2>
              <Badge label="ANALYST" color={T.cyan} />
              <Badge label="ACTIVE" color={T.green} />
            </div>
            <div style={{ color: T.muted, fontSize: 13 }}>
              bhattdhruvil2005@gmail.com · ID: USR-00042 · Joined September 2024
            </div>
          </div>
          <div style={{ display: "flex", gap: 32, paddingBottom: 8 }}>
            {[
              { label: "Total scans", val: "342", color: T.cyan },
              { label: "Fraud found", val: "28", color: T.red },
              { label: "Batch jobs", val: "14", color: T.amber },
              { label: "Accuracy", val: "97.4%", color: T.green },
            ].map(s => (
              <div key={s.label} style={{ textAlign: "center" }}>
                <div style={{ color: s.color, fontSize: 22, fontWeight: 800 }}>{s.val}</div>
                <div style={{ color: T.muted, fontSize: 11 }}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Tabs */}
        <div style={{ display: "flex", gap: 0 }}>
          {tabs.map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              padding: "10px 20px", background: "transparent", border: "none",
              borderBottom: tab === t ? `2px solid ${T.cyan}` : "2px solid transparent",
              color: tab === t ? T.cyan : T.muted,
              fontSize: 13, fontWeight: tab === t ? 600 : 400,
              cursor: "pointer", fontFamily: "inherit", transition: "all .15s"
            }}>
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div style={{ padding: 28 }}>

        {/* INFO TAB */}
        {tab === "info" && (
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
            <Card>
              <h3 style={{ color: T.cyan, fontSize: 13, fontWeight: 600, margin: "0 0 16px" }}>Personal Information</h3>
              {[
                ["Full name", "Dhruvil Bhatt"],
                ["Email", "bhattdhruvil2005@gmail.com"],
                ["Role", "Analyst"],
                ["Organisation", "CHARUSAT University"],
                ["Location", "Nadiad, Gujarat"],
                ["Phone", "+91 9265996642"],
              ].map(([k, v]) => (
                <div key={k} style={{
                  display: "flex", justifyContent: "space-between",
                  padding: "10px 0", borderBottom: `1px solid ${T.border}33`
                }}>
                  <span style={{ color: T.muted, fontSize: 12 }}>{k}</span>
                  <span style={{ color: T.text, fontSize: 12, fontWeight: 500 }}>{v}</span>
                </div>
              ))}
              <div style={{ marginTop: 16 }}>
                <Btn variant="ghost" small>Edit profile</Btn>
              </div>
            </Card>

            <Card>
              <h3 style={{ color: T.cyan, fontSize: 13, fontWeight: 600, margin: "0 0 16px" }}>Activity Summary</h3>
              {[
                { label: "Scans this week", val: "24", color: T.cyan },
                { label: "Fraud flagged this week", val: "3", color: T.red },
                { label: "Batch jobs this month", val: "5", color: T.amber },
                { label: "Last login", val: "Today, 09:14 AM", color: T.text },
                { label: "Account status", val: "Active", color: T.green },
              ].map(r => (
                <div key={r.label} style={{
                  display: "flex", justifyContent: "space-between",
                  padding: "10px 0", borderBottom: `1px solid ${T.border}33`
                }}>
                  <span style={{ color: T.muted, fontSize: 12 }}>{r.label}</span>
                  <span style={{ color: r.color, fontSize: 12, fontWeight: 600 }}>{r.val}</span>
                </div>
              ))}
            </Card>
          </div>
        )}

        {/* HISTORY TAB */}
        {tab === "history" && (
          <Card>
            <h3 style={{ color: T.cyan, fontSize: 13, fontWeight: 600, margin: "0 0 16px" }}>
              My Scan History
            </h3>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr style={{ borderBottom: `1px solid ${T.border}` }}>
                  {["Transaction ID", "Amount", "Verdict", "Score", "Date"].map(h => (
                    <th key={h} style={{ color: T.muted, fontSize: 11, fontWeight: 600, padding: "8px 10px", textAlign: "left" }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {MOCK_HISTORY.map((t, i) => (
                  <tr key={t.id} style={{ borderBottom: `1px solid ${T.border}22`, background: i % 2 ? T.navyMid + "44" : "transparent" }}>
                    <td style={{ padding: "10px", color: T.cyan, fontSize: 12, fontFamily: "monospace" }}>{t.id}</td>
                    <td style={{ padding: "10px", color: T.text, fontWeight: 600 }}>${t.amount.toFixed(2)}</td>
                    <td style={{ padding: "10px" }}>
                      <Badge label={t.result} color={t.result === "FRAUD" ? T.red : T.green} />
                    </td>
                    <td style={{ padding: "10px", color: t.score > .6 ? T.red : T.green, fontWeight: 700 }}>
                      {(t.score * 100).toFixed(1)}%
                    </td>
                    <td style={{ padding: "10px", color: T.muted, fontSize: 11, fontFamily: "monospace" }}>{t.date}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
        )}

        {/* UPLOADS TAB */}
        {tab === "uploads" && (
          <Card>
            <h3 style={{ color: T.cyan, fontSize: 13, fontWeight: 600, margin: "0 0 16px" }}>
              My Batch Uploads
            </h3>
            {[
              { name: "transactions_aug.csv", rows: 1240, fraud: 18, date: "2024-08-31", status: "completed" },
              { name: "batch_test_01.csv",    rows: 80,   fraud: 3,  date: "2024-08-28", status: "completed" },
              { name: "transactions_jul.csv", rows: 950,  fraud: 11, date: "2024-07-31", status: "completed" },
            ].map(u => (
              <div key={u.name} style={{
                display: "flex", alignItems: "center", justifyContent: "space-between",
                padding: "14px 0", borderBottom: `1px solid ${T.border}33`
              }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                  <span style={{ fontSize: 24 }}>📄</span>
                  <div>
                    <div style={{ color: T.text, fontSize: 13, fontWeight: 600 }}>{u.name}</div>
                    <div style={{ color: T.muted, fontSize: 11 }}>
                      {u.rows} rows · {u.fraud} fraud found · {u.date}
                    </div>
                  </div>
                </div>
                <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                  <Badge label={u.status.toUpperCase()} color={T.green} />
                  <Btn variant="ghost" small>View</Btn>
                </div>
              </div>
            ))}
          </Card>
        )}

        {/* SECURITY TAB */}
        {tab === "security" && (
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
            <Card>
              <h3 style={{ color: T.cyan, fontSize: 13, fontWeight: 600, margin: "0 0 16px" }}>Change Password</h3>
              <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
                <Input label="CURRENT PASSWORD" type="password" icon="🔒" placeholder="••••••••" value="" onChange={() => {}} />
                <Input label="NEW PASSWORD" type="password" icon="🔒" placeholder="Min. 8 characters" value="" onChange={() => {}} />
                <Input label="CONFIRM NEW PASSWORD" type="password" icon="🔒" placeholder="Repeat new password" value="" onChange={() => {}} />
                <Btn>Update password</Btn>
              </div>
            </Card>
            <Card>
              <h3 style={{ color: T.cyan, fontSize: 13, fontWeight: 600, margin: "0 0 16px" }}>Login Sessions</h3>
              {[
                { device: "Chrome · Windows", location: "Nadiad, Gujarat", time: "Now", current: true },
                { device: "Firefox · Windows", location: "Nadiad, Gujarat", time: "2 days ago", current: false },
              ].map(s => (
                <div key={s.time} style={{
                  display: "flex", justifyContent: "space-between", alignItems: "center",
                  padding: "12px 0", borderBottom: `1px solid ${T.border}33`
                }}>
                  <div>
                    <div style={{ color: T.text, fontSize: 12, fontWeight: 600 }}>{s.device}</div>
                    <div style={{ color: T.muted, fontSize: 11 }}>{s.location} · {s.time}</div>
                  </div>
                  {s.current
                    ? <Badge label="THIS SESSION" color={T.green} />
                    : <Btn variant="danger" small>Revoke</Btn>
                  }
                </div>
              ))}
              <div style={{ marginTop: 16 }}>
                <Btn variant="danger">Sign out all other sessions</Btn>
              </div>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
}

// ── APP SHELL ────────────────────────────────────────────────────
export default function App() {
  const [screen, setScreen] = useState("login");

  if (screen === "login")    return <LoginScreen    onNavigate={setScreen} />;
  if (screen === "register") return <RegisterScreen onNavigate={setScreen} />;

  return (
    <div style={{ display: "flex", minHeight: "100vh", fontFamily: "Inter, system-ui, sans-serif" }}>
      <style>{`
        * { box-sizing: border-box; }
        body { margin: 0; background: ${T.navy}; }
        input::placeholder { color: ${T.muted}; }
        input:focus { border-color: ${T.cyan} !important; box-shadow: 0 0 0 2px ${T.cyan}22; }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: ${T.navyMid}; }
        ::-webkit-scrollbar-thumb { background: ${T.border}; border-radius: 3px; }
        @keyframes pulse { 0%,100%{opacity:1;box-shadow:0 0 6px currentColor} 50%{opacity:.4;box-shadow:0 0 2px currentColor} }
      `}</style>
      <Sidebar active={screen} onNavigate={setScreen} onLogout={() => setScreen("login")} />
      {screen === "dashboard" && <DashboardScreen />}
      {screen === "scan"      && <ScanScreen />}
      {screen === "batch"     && <BatchScreen />}
      {screen === "profile"   && <ProfileScreen />}
    </div>
  );
}
