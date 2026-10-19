const AI_HOSTS = [
  "chatgpt.com",
  "chat.openai.com",
  "claude.ai",
  "gemini.google.com",
  "copilot.microsoft.com",
  "perplexity.ai",
];

const SESSIONS_KEY = "sessions";
const RECENT_WINDOW_MS = 30 * 60 * 1000;

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

async function loadSessions() {
  const stored = await chrome.storage.session.get(SESSIONS_KEY);
  return stored[SESSIONS_KEY] ?? {};
}

async function saveSessions(sessions) {
  await chrome.storage.session.set({ [SESSIONS_KEY]: sessions });
}

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
      session.cursorDistancePx = (session.cursorDistancePx ?? 0) + (Number.isFinite(distance) ? Math.max(0, Math.round(distance)) : 0);
    }
  }

  session.activeSeconds = Math.round(session.activeMs / 1000);
  session.score = computeScore(session);
  session.lastActiveAt = Date.now();
  session.updatedAt = Date.now();
}

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message?.type === "telemetry") {
    (async () => {
      const tabId = sender.tab?.id;
      if (tabId === undefined) {
        sendResponse({ ok: false });
        return;
      }

      const sessions = await loadSessions();
      const session = sessions[tabId] ?? emptySession(tabId, sender.tab.url ?? "");
      session.url = sender.tab.url ?? session.url;
      session.sessionId = message.sessionId ?? session.sessionId;
      if (message.assignmentId) {
        session.assignmentId = message.assignmentId;
      }

      applyEvents(session, Array.isArray(message.events) ? message.events : []);
      sessions[tabId] = session;
      await saveSessions(sessions);
      sendResponse({ ok: true, score: session.score });
    })();
    return true;
  }

  if (message?.type === "get-session") {
    (async () => {
      const sessions = await loadSessions();
      sendResponse({ session: sessions[message.tabId] ?? null });
    })();
    return true;
  }

  if (message?.type === "reset-session") {
    (async () => {
      const sessions = await loadSessions();
      delete sessions[message.tabId];
      await saveSessions(sessions);
      sendResponse({ ok: true });
    })();
    return true;
  }

  return false;
});

chrome.tabs.onActivated.addListener(async ({ tabId }) => {
  try {
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
});
