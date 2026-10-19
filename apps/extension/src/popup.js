const elements = {
  score: document.getElementById("score"),
  meter: document.getElementById("meter-fill"),
  hint: document.getElementById("score-hint"),
  keystrokes: document.getElementById("keystrokes"),
  pastes: document.getElementById("pastes"),
  pasteVolume: document.getElementById("paste-volume"),
  aiSwitches: document.getElementById("ai-switches"),
  activeTime: document.getElementById("active-time"),
  siteName: document.getElementById("site-name"),
  assignment: document.getElementById("assignment"),
  statusDot: document.getElementById("status-dot"),
  reset: document.getElementById("reset"),
};

let currentTabId = null;

function scoreColor(score) {
  if (score >= 75) {
    return "#34d399";
  }
  if (score >= 50) {
    return "#fbbf24";
  }
  return "#f87171";
}

function scoreHint(session) {
  if (!session || session.keystrokes + session.pastes === 0) {
    return "Start typing in a document to build a session.";
  }
  if (session.aiTabSwitches > 0) {
    return "AI platform tab switches were recorded during this session.";
  }
  if (session.pasteVolume >= 500) {
    return "A large paste was detected. Typed input carries more effort weight.";
  }
  return "Session looks organic so far. Keep drafting.";
}

function render(session, tab) {
  const host = tab?.url ? new URL(tab.url).hostname.replace(/^www\./, "") : "No active tab";
  elements.siteName.textContent = host;

  if (!session) {
    elements.assignment.textContent = "No assignment detected";
    elements.score.textContent = "--";
    elements.meter.style.width = "0%";
    elements.hint.textContent = "Start typing in a document to build a session.";
    elements.keystrokes.textContent = "0";
    elements.pastes.textContent = "0";
    elements.pasteVolume.textContent = "0";
    elements.aiSwitches.textContent = "0";
    elements.activeTime.textContent = "0s active";
    elements.statusDot.classList.remove("active");
    return;
  }

  const active = Date.now() - session.lastActiveAt < 60_000;
  elements.statusDot.classList.toggle("active", active);
  elements.assignment.textContent = session.assignmentId
    ? `Assignment: ${session.assignmentId}`
    : "No assignment detected";
  elements.score.textContent = String(session.score);
  elements.meter.style.width = `${Math.max(0, Math.min(100, session.score))}%`;
  elements.meter.style.background = scoreColor(session.score);
  elements.hint.textContent = scoreHint(session);
  elements.keystrokes.textContent = String(session.keystrokes);
  elements.pastes.textContent = String(session.pastes);
  elements.pasteVolume.textContent = String(session.pasteVolume);
  elements.aiSwitches.textContent = String(session.aiTabSwitches);
  elements.activeTime.textContent = `${session.activeSeconds}s active`;
}

async function refresh() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  currentTabId = tab?.id ?? null;

  if (currentTabId === null) {
    render(null, null);
    return;
  }

  const response = await chrome.runtime.sendMessage({
    type: "get-session",
    tabId: currentTabId,
  });
  render(response?.session ?? null, tab);
}

elements.reset.addEventListener("click", async () => {
  if (currentTabId === null) {
    return;
  }
  await chrome.runtime.sendMessage({ type: "reset-session", tabId: currentTabId });
  await refresh();
});

refresh();
setInterval(refresh, 1000);
