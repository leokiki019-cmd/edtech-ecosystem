const AI_HOSTS = [
  "chatgpt.com",
  "chat.openai.com",
  "claude.ai",
  "gemini.google.com",
  "copilot.microsoft.com",
  "perplexity.ai",
];

const SESSIONS_KEY = "sessions";
const PENDING_EVENTS_KEY = "pendingEvents";
const QUEUE_KEY = "uploadQueue";
const STATUS_KEY = "syncStatus";
const AUTH_KEY = "auth";
const INSTALL_KEY = "installKey";

// chrome.storage.sync holds user-facing settings so they roam with the profile.
const SETTINGS_KEY = "settings";

const RECENT_WINDOW_MS = 30 * 60 * 1000;
const FLUSH_INTERVAL_MS = 15_000;
const RETRY_BASE_MS = 10_000;
const RETRY_MAX_MS = 5 * 60 * 1000;
const MAX_PENDING_BATCHES = 200;
const MAX_QUEUE_EVENTS = 5_000;

const emptySession = (tabId, url) => ({
  tabId,
  url,
  sessionId: crypto.randomUUID(),
  assignmentId: null,
  keystrokes: 0,
  pastes: 0,
  pasteVolume: 0,
  aiTabSwitches: 0,
  activeMs: 0,
  activeSeconds: 0,
  score: 100,
  startedAt: Date.now(),
  lastActiveAt: Date.now(),
  updatedAt: Date.now(),
});

function hostFromUrl(url) {
  try {
    return new URL(url).hostname.replace(/^www\./, "");
  } catch {
    return null;
  }
}

function isAiHost(host) {
  return AI_HOSTS.some((aiHost) => host === aiHost || host.endsWith(`.${aiHost}`));
}

function computeScore(session) {
  const totalInput = session.keystrokes + session.pasteVolume;
  const pasteRatio = totalInput === 0 ? 0 : session.pasteVolume / totalInput;
  const pastePenalty = Math.round(Math.min(45, pasteRatio * 100));
  const aiPenalty = Math.min(30, session.aiTabSwitches * 10);
  const idlePenalty = session.activeSeconds < 60 && session.pastes > 0 ? 10 : 0;
  return Math.max(0, Math.min(100, 100 - pastePenalty - aiPenalty - idlePenalty));
}

/* ---------- storage helpers ---------- */

async function loadSessions() {
  const stored = await chrome.storage.session.get(SESSIONS_KEY);
  return stored[SESSIONS_KEY] ?? {};
}

async function saveSessions(sessions) {
  await chrome.storage.session.set({ [SESSIONS_KEY]: sessions });
}

async function getSettings() {
  const stored = await chrome.storage.sync.get(SETTINGS_KEY);
  const settings = stored[SETTINGS_KEY] ?? {};
  return {
    apiBaseUrl: normalizeBaseUrl(settings.apiBaseUrl ?? "http://localhost:4000"),
    consentEnabled: Boolean(settings.consentEnabled),
  };
}

async function getAuth() {
  const stored = await chrome.storage.local.get(AUTH_KEY);
  const auth = stored[AUTH_KEY] ?? {};
  return {
    token: typeof auth.token === "string" ? auth.token : null,
    studentId: typeof auth.studentId === "string" ? auth.studentId : null,
    studentName: typeof auth.studentName === "string" ? auth.studentName : null,
  };
}

function normalizeBaseUrl(url) {
  return String(url ?? "").trim().replace(/\/+$/, "");
}

async function loadPendingEvents() {
  const stored = await chrome.storage.session.get(PENDING_EVENTS_KEY);
  return stored[PENDING_EVENTS_KEY] ?? {};
}

async function savePendingEvents(pending) {
  await chrome.storage.session.set({ [PENDING_EVENTS_KEY]: pending });
}

async function loadQueue() {
  const stored = await chrome.storage.local.get(QUEUE_KEY);
  return stored[QUEUE_KEY] ?? [];
}

async function saveQueue(queue) {
  await chrome.storage.local.set({ [QUEUE_KEY]: queue });
}

async function updateStatus(patch) {
  const stored = await chrome.storage.session.get(STATUS_KEY);
  const status = { ...(stored[STATUS_KEY] ?? {}), ...patch, updatedAt: Date.now() };
  await chrome.storage.session.set({ [STATUS_KEY]: status });
  return status;
}

/* ---------- HMAC signing key (one per install) ---------- */

async function getSigningKey() {
  const stored = await chrome.storage.local.get(INSTALL_KEY);
  if (stored[INSTALL_KEY]?.privateKey) {
    return crypto.subtle.importKey(
      "jwk",
      stored[INSTALL_KEY].privateKey,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );
  }

  const key = await crypto.subtle.generateKey(
    { name: "HMAC", hash: "SHA-256" },
    true,
    ["sign", "verify"],
  );
  const privateKey = await crypto.subtle.exportKey("jwk", key);
  const publicKey = await crypto.subtle.exportKey("jwk", key);
  await chrome.storage.local.set({
    [INSTALL_KEY]: {
      // The HMAC key doubles as the client identity until the server
      // verifies real asymmetric signatures (planned hardening step).
      privateKey,
      publicKey: { kty: publicKey.kty, alg: "HS256" },
    },
  });
  return key;
}

async function signBatch(key, canonical) {
  const data = new TextEncoder().encode(canonical);
  const signature = await crypto.subtle.sign("HMAC", key, data);
  return b64url(new Uint8Array(signature));
}

function b64url(bytes) {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/* ---------- telemetry ingestion from content scripts ---------- */

function applyEvents(session, events) {
  for (const event of events) {
    if (event.type === "keystroke") {
      session.keystrokes += 1;
      const delta = Number(event.payload?.deltaMs ?? 0);
      session.activeMs += Number.isFinite(delta) ? Math.min(Math.max(delta, 0), 5000) : 0;
    } else if (event.type === "paste") {
      session.pastes += 1;
      const characters = Number(event.payload?.characterCount ?? 0);
      session.pasteVolume += Number.isFinite(characters) ? Math.max(0, characters) : 0;
    } else if (event.type === "cursor") {
      const distance = Number(event.payload?.distancePx ?? 0);
      session.cursorDistancePx =
        (session.cursorDistancePx ?? 0) +
        (Number.isFinite(distance) ? Math.max(0, Math.round(distance)) : 0);
    }
  }

  session.activeSeconds = Math.round(session.activeMs / 1000);
  session.score = computeScore(session);
  session.lastActiveAt = Date.now();
  session.updatedAt = Date.now();
}

async function handleTelemetry(message, sender) {
  const tabId = sender.tab?.id;
  if (tabId === undefined) {
    return { ok: false, reason: "no-tab" };
  }

  const settings = await getSettings();
  if (!settings.consentEnabled) {
    return { ok: false, disabled: true };
  }

  const sessions = await loadSessions();
  const session = sessions[tabId] ?? emptySession(tabId, sender.tab.url ?? "");
  session.url = sender.tab.url ?? session.url;
  session.sessionId = message.sessionId ?? session.sessionId;
  if (message.assignmentId && message.assignmentId !== "unassigned") {
    session.assignmentId = message.assignmentId;
  }

  applyEvents(session, Array.isArray(message.events) ? message.events : []);
  sessions[tabId] = session;
  await saveSessions(sessions);

  // Buffer raw events for batch upload to the API.
  const pending = await loadPendingEvents();
  const bucket = pending[tabId] ?? { sessionId: session.sessionId, events: [] };
  bucket.events.push(...(Array.isArray(message.events) ? message.events : []));
  if (bucket.events.length > MAX_QUEUE_EVENTS) {
    bucket.events = bucket.events.slice(-MAX_QUEUE_EVENTS);
  }
  pending[tabId] = bucket;
  await savePendingEvents(pending);

  return { ok: true, score: session.score };
}

/* ---------- batch construction and upload ---------- */

async function flushToApi() {
  const settings = await getSettings();
  if (!settings.consentEnabled) {
    return;
  }

  const auth = await getAuth();
  if (!auth.token || !auth.studentId) {
    return;
  }

  const pending = await loadPendingEvents();
  const sessions = await loadSessions();
  const queue = await loadQueue();

  for (const [tabId, bucket] of Object.entries(pending)) {
    if (!bucket?.events?.length) {
      delete pending[tabId];
      continue;
    }

    const session = sessions[tabId];
    const assignmentId = session?.assignmentId ?? null;
    if (!assignmentId) {
      // Sessions not attached to an assignment stay local only.
      continue;
    }

    const batch = {
      batchId: crypto.randomUUID(),
      studentId: auth.studentId,
      assignmentId,
      createdAt: new Date().toISOString(),
      events: bucket.events.map((event) => ({
        id: crypto.randomUUID(),
        sessionId: bucket.sessionId,
        assignmentId,
        studentId: auth.studentId,
        type: event.type,
        occurredAt: event.occurredAt ?? new Date().toISOString(),
        payload: event.payload ?? {},
      })),
    };

    queue.push({ batch, attempts: 0, nextAttemptAt: 0 });
    delete pending[tabId];
  }

  if (queue.length > MAX_PENDING_BATCHES) {
    queue.splice(0, queue.length - MAX_PENDING_BATCHES);
  }

  const totalEvents = queue.reduce((sum, item) => sum + item.batch.events.length, 0);
  await savePendingEvents(pending);
  await saveQueue(queue);
  await updateStatus({
    consentEnabled: true,
    pendingBatches: queue.length,
    pendingEvents: totalEvents,
    loggedIn: Boolean(auth.studentId),
    studentName: auth.studentName,
  });

  await uploadReadyBatches(settings, auth);
}

async function uploadReadyBatches(settings, auth) {
  const queue = await loadQueue();
  if (queue.length === 0) {
    return;
  }

  let signingKey = null;
  let hadTransportError = false;

  while (queue.length > 0) {
    const item = queue[0];
    if (item.nextAttemptAt > Date.now()) {
      break;
    }

    if (!signingKey) {
      signingKey = await getSigningKey();
    }

    const storedKey = (await chrome.storage.local.get(INSTALL_KEY))[INSTALL_KEY];
    const canonical = JSON.stringify({
      batchId: item.batch.batchId,
      studentId: item.batch.studentId,
      assignmentId: item.batch.assignmentId,
      createdAt: item.batch.createdAt,
      events: item.batch.events,
    });
    const clientSignature = await signBatch(signingKey, canonical);

    let response;
    try {
      response = await fetch(`${settings.apiBaseUrl}/api/v1/telemetry/batches`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${auth.token}`,
        },
        body: JSON.stringify({
          ...item.batch,
          clientSignature,
          clientPublicKey: JSON.stringify(storedKey?.publicKey ?? {}),
        }),
      });
    } catch {
      // Network failure: back off and retry later, keep the batch queued.
      hadTransportError = true;
      item.attempts += 1;
      item.nextAttemptAt =
        Date.now() + Math.min(RETRY_BASE_MS * 2 ** item.attempts, RETRY_MAX_MS);
      break;
    }

    if (response.ok) {
      queue.shift();
      await saveQueue(queue);
      await updateStatus({
        lastUploadAt: Date.now(),
        lastError: null,
        needsReauth: false,
        pendingBatches: queue.length,
      });
      continue;
    }

    if (response.status === 401 || response.status === 403) {
      // Token expired or rejected: keep the batch, ask the user to sign in again.
      await updateStatus({ needsReauth: true, lastError: "Session expired" });
      break;
    }

    if (response.status >= 400 && response.status < 500) {
      // Permanently rejected batch (e.g. unknown assignment): drop it.
      queue.shift();
      await saveQueue(queue);
      await updateStatus({
        lastError: `Batch rejected (${response.status})`,
        pendingBatches: queue.length,
      });
      continue;
    }

    // Server error: retry with backoff.
    item.attempts += 1;
    item.nextAttemptAt =
      Date.now() + Math.min(RETRY_BASE_MS * 2 ** item.attempts, RETRY_MAX_MS);
    hadTransportError = true;
    break;
  }

  if (hadTransportError) {
    await saveQueue(queue);
  }
  await updateStatus({ pendingBatches: queue.length });
}

/* ---------- runtime messages ---------- */

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message?.type === "telemetry") {
    handleTelemetry(message, sender).then(sendResponse);
    return true;
  }

  if (message?.type === "get-consent") {
    getSettings().then((settings) => sendResponse({ enabled: settings.consentEnabled }));
    return true;
  }

  if (message?.type === "get-session") {
    (async () => {
      const sessions = await loadSessions();
      sendResponse({ session: sessions[message.tabId] ?? null });
    })();
    return true;
  }

  if (message?.type === "get-sync-status") {
    (async () => {
      const [sessionStored, settings, auth] = await Promise.all([
        chrome.storage.session.get(STATUS_KEY),
        getSettings(),
        getAuth(),
      ]);
      const queue = await loadQueue();
      sendResponse({
        status: {
          ...(sessionStored[STATUS_KEY] ?? {}),
          consentEnabled: settings.consentEnabled,
          loggedIn: Boolean(auth.token && auth.studentId),
          studentName: auth.studentName,
          pendingBatches: queue.length,
          pendingEvents: queue.reduce((sum, item) => sum + item.batch.events.length, 0),
        },
      });
    })();
    return true;
  }

  if (message?.type === "reset-session") {
    (async () => {
      const sessions = await loadSessions();
      delete sessions[message.tabId];
      await saveSessions(sessions);
      const pending = await loadPendingEvents();
      delete pending[message.tabId];
      await savePendingEvents(pending);
      sendResponse({ ok: true });
    })();
    return true;
  }

  return false;
});

/* ---------- AI tab-switch tracking ---------- */

chrome.tabs.onActivated.addListener(async ({ tabId }) => {
  try {
    const settings = await getSettings();
    if (!settings.consentEnabled) {
      return;
    }

    const tab = await chrome.tabs.get(tabId);
    const host = tab.url ? hostFromUrl(tab.url) : null;
    if (!host || !isAiHost(host)) {
      return;
    }

    const sessions = await loadSessions();
    const now = Date.now();
    let targetId = null;
    let latestActivity = 0;

    for (const [id, session] of Object.entries(sessions)) {
      const isRecent = now - session.lastActiveAt < RECENT_WINDOW_MS;
      if (isRecent && session.lastActiveAt > latestActivity) {
        latestActivity = session.lastActiveAt;
        targetId = id;
      }
    }

    if (targetId === null) {
      return;
    }

    const session = sessions[targetId];
    session.aiTabSwitches += 1;
    session.lastAiHost = host;
    session.score = computeScore(session);
    session.updatedAt = now;
    sessions[targetId] = session;
    await saveSessions(sessions);
  } catch {
    return;
  }
});

chrome.tabs.onRemoved.addListener(async (tabId) => {
  const sessions = await loadSessions();
  if (sessions[tabId]) {
    delete sessions[tabId];
    await saveSessions(sessions);
  }
  const pending = await loadPendingEvents();
  if (pending[tabId]) {
    delete pending[tabId];
    await savePendingEvents(pending);
  }
});

/* ---------- lifecycle ---------- */

chrome.runtime.onInstalled.addListener(() => {
  // First-run and updates open settings so the student can review consent.
  chrome.runtime.openOptionsPage();
});

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "sync" && changes[SETTINGS_KEY]) {
    flushToApi().catch(() => {});
  }
});

// Periodic flush: batches queued events and retries failed uploads.
setInterval(() => {
  flushToApi().catch(() => {});
}, FLUSH_INTERVAL_MS);

// Best-effort flush when the worker shuts down.
chrome.runtime.onSuspend.addListener(() => {
  flushToApi().catch(() => {});
});
