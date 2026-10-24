const SETTINGS_KEY = "settings";
const AUTH_KEY = "auth";

const elements = {
  apiUrl: document.getElementById("api-url"),
  loginId: document.getElementById("login-id"),
  loginPassword: document.getElementById("login-password"),
  login: document.getElementById("login"),
  logout: document.getElementById("logout"),
  testConnection: document.getElementById("test-connection"),
  accountStatus: document.getElementById("account-status"),
  consent: document.getElementById("consent"),
  consentStatus: document.getElementById("consent-status"),
  statPending: document.getElementById("stat-pending"),
  statEvents: document.getElementById("stat-events"),
  statLastUpload: document.getElementById("stat-last-upload"),
  statError: document.getElementById("stat-error"),
  flush: document.getElementById("flush"),
};

function normalizeBaseUrl(url) {
  return String(url ?? "").trim().replace(/\/+$/, "");
}

function setStatus(element, text, kind) {
  element.textContent = text;
  element.classList.remove("ok", "err");
  if (kind) {
    element.classList.add(kind);
  }
}

async function loadState() {
  const [syncStored, localStored] = await Promise.all([
    chrome.storage.sync.get(SETTINGS_KEY),
    chrome.storage.local.get(AUTH_KEY),
  ]);
  const settings = syncStored[SETTINGS_KEY] ?? {};
  const auth = localStored[AUTH_KEY] ?? {};

  elements.apiUrl.value = settings.apiBaseUrl ?? "http://localhost:4000";
  elements.consent.checked = Boolean(settings.consentEnabled);

  if (auth.studentName) {
    setStatus(
      elements.accountStatus,
      `Signed in as ${auth.studentName}`,
      "ok",
    );
  } else {
    setStatus(elements.accountStatus, "Not signed in.", null);
  }
  if (elements.consent.checked) {
    setStatus(elements.consentStatus, "Monitoring is enabled.", "ok");
  } else {
    setStatus(elements.consentStatus, "Monitoring is off. Sessions stay local only.", null);
  }
}

async function saveSettings(patch) {
  const stored = await chrome.storage.sync.get(SETTINGS_KEY);
  const settings = { ...(stored[SETTINGS_KEY] ?? {}), ...patch };
  await chrome.storage.sync.set({ [SETTINGS_KEY]: settings });
  return settings;
}

elements.testConnection.addEventListener("click", async () => {
  const base = normalizeBaseUrl(elements.apiUrl.value);
  setStatus(elements.accountStatus, "Testing connection…", null);
  try {
    const response = await fetch(`${base}/health`, { method: "GET" });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    const health = await response.json();
    setStatus(
      elements.accountStatus,
      `Connected to ${health.service ?? "API"} (${health.version ?? "unknown version"}).`,
      "ok",
    );
  } catch (error) {
    setStatus(
      elements.accountStatus,
      `Could not reach the API: ${error.message}. Is it running?`,
      "err",
    );
  }
});

elements.login.addEventListener("click", async () => {
  const base = normalizeBaseUrl(elements.apiUrl.value);
  const loginId = elements.loginId.value.trim();
  const password = elements.loginPassword.value;

  if (!loginId || !password) {
    setStatus(elements.accountStatus, "Enter your phone/email and password.", "err");
    return;
  }

  setStatus(elements.accountStatus, "Signing in…", null);
  try {
    const isEmail = loginId.includes("@");
    const response = await fetch(`${base}/api/v1/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(
        isEmail ? { email: loginId, password } : { phone: loginId, password },
      ),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new Error(payload?.error?.message ?? `HTTP ${response.status}`);
    }

    await chrome.storage.local.set({
      [AUTH_KEY]: {
        token: payload.data.token,
        studentId: payload.data.user.id,
        studentName: payload.data.user.displayName,
      },
    });
    await saveSettings({ apiBaseUrl: base });
    setStatus(
      elements.accountStatus,
      `Signed in as ${payload.data.user.displayName}.`,
      "ok",
    );
    elements.loginPassword.value = "";
  } catch (error) {
    setStatus(elements.accountStatus, `Sign-in failed: ${error.message}`, "err");
  }
});

elements.logout.addEventListener("click", async () => {
  await chrome.storage.local.remove(AUTH_KEY);
  setStatus(elements.accountStatus, "Signed out. Queued data was kept locally.", null);
});

elements.consent.addEventListener("change", async () => {
  await saveSettings({ consentEnabled: elements.consent.checked });
  if (elements.consent.checked) {
    setStatus(elements.consentStatus, "Monitoring is enabled.", "ok");
  } else {
    setStatus(
      elements.consentStatus,
      "Monitoring is off. New typing is no longer recorded or uploaded.",
      null,
    );
  }
});

elements.flush.addEventListener("click", async () => {
  // Nudge the service worker by querying status; its interval loop uploads.
  await chrome.runtime.sendMessage({ type: "get-sync-status" }).catch(() => {});
  setTimeout(refreshStats, 500);
  setTimeout(refreshStats, 2500);
});

async function refreshStats() {
  try {
    const response = await chrome.runtime.sendMessage({ type: "get-sync-status" });
    const status = response?.status ?? {};
    elements.statPending.textContent = String(status.pendingBatches ?? 0);
    elements.statEvents.textContent = String(status.pendingEvents ?? 0);
    elements.statLastUpload.textContent = status.lastUploadAt
      ? new Date(status.lastUploadAt).toLocaleTimeString()
      : "Never";
    elements.statError.textContent = status.lastError ?? "None";
    if (status.needsReauth) {
      setStatus(elements.accountStatus, "Session expired — sign in again.", "err");
    }
  } catch {
    elements.statPending.textContent = "–";
  }
}

elements.apiUrl.addEventListener("change", async () => {
  await saveSettings({ apiBaseUrl: normalizeBaseUrl(elements.apiUrl.value) });
});

loadState().then(refreshStats);
setInterval(refreshStats, 3000);
