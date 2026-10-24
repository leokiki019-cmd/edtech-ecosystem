(() => {
  const SESSION_ID = crypto.randomUUID();
  const FLUSH_INTERVAL_MS = 2000;
  const CURSOR_SAMPLE_MS = 500;
  const MODIFIER_KEYS = new Set([
    "Shift",
    "Control",
    "Alt",
    "Meta",
    "CapsLock",
    "Escape",
    "Tab",
    "ArrowUp",
    "ArrowDown",
    "ArrowLeft",
    "ArrowRight",
  ]);

  const metaAssignment = document.querySelector('meta[name="edtech-assignment-id"]');
  const assignmentId =
    new URLSearchParams(window.location.search).get("assignmentId") ||
    metaAssignment?.getAttribute("content") ||
    "unassigned";

  let queue = [];
  let lastKeyAt = 0;
  let lastCursorAt = 0;
  let lastCursorX = null;
  let lastCursorY = null;
  let consentEnabled = false;

  // Capture only runs when the student has enabled monitoring in settings.
  try {
    chrome.runtime.sendMessage({ type: "get-consent" }, (response) => {
      consentEnabled = Boolean(response?.enabled);
    });
  } catch {
    consentEnabled = false;
  }

  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === "sync" && changes.settings) {
      consentEnabled = Boolean(changes.settings.newValue?.consentEnabled);
      if (!consentEnabled) {
        queue = [];
      }
    }
  });

  function isSensitiveTarget(target) {
    if (!(target instanceof HTMLElement)) {
      return false;
    }

    if (target instanceof HTMLInputElement) {
      const type = (target.getAttribute("type") || "text").toLowerCase();
      return type === "password" || type === "hidden";
    }

    return Boolean(target.closest("[data-sensitive]"));
  }

  function enqueue(type, payload) {
    if (!consentEnabled) {
      return;
    }
    queue.push({
      type,
      payload,
      occurredAt: new Date().toISOString(),
    });
  }

  function flush() {
    if (queue.length === 0) {
      return;
    }

    const events = queue;
    queue = [];
    try {
      chrome.runtime.sendMessage({
        type: "telemetry",
        sessionId: SESSION_ID,
        assignmentId,
        events,
      });
    } catch {
      return;
    }
  }

  window.addEventListener(
    "keydown",
    (event) => {
      if (event.isComposing || MODIFIER_KEYS.has(event.key) || isSensitiveTarget(event.target)) {
        return;
      }

      const now = performance.now();
      const deltaMs = lastKeyAt === 0 ? 0 : Math.round(now - lastKeyAt);
      lastKeyAt = now;
      enqueue("keystroke", { deltaMs });
    },
    true,
  );

  window.addEventListener(
    "paste",
    (event) => {
      if (isSensitiveTarget(event.target)) {
        return;
      }

      const text = event.clipboardData?.getData("text") ?? "";
      enqueue("paste", { characterCount: text.length });
    },
    true,
  );

  window.addEventListener(
    "mousemove",
    (event) => {
      const now = performance.now();
      if (now - lastCursorAt < CURSOR_SAMPLE_MS) {
        return;
      }

      if (lastCursorX !== null && lastCursorY !== null) {
        const distance = Math.round(
          Math.hypot(event.clientX - lastCursorX, event.clientY - lastCursorY),
        );
        enqueue("cursor", { distancePx: distance });
      }

      lastCursorAt = now;
      lastCursorX = event.clientX;
      lastCursorY = event.clientY;
    },
    { capture: true, passive: true },
  );

  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "hidden") {
      flush();
    }
  });

  window.addEventListener("pagehide", flush);

  setInterval(flush, FLUSH_INTERVAL_MS);
})();
