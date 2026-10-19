import type { EffortScore, IntegrityFlag, TelemetryEvent } from "@edtech/shared";

export interface EffortMetrics {
  keystrokes: number;
  pastes: number;
  pasteVolume: number;
  aiTabSwitches: number;
  activeSeconds: number;
}

const clamp = (value: number, min: number, max: number) =>
  Math.min(max, Math.max(min, value));

export function computeEffortMetrics(events: TelemetryEvent[]): EffortMetrics {
  let keystrokes = 0;
  let pastes = 0;
  let pasteVolume = 0;
  let aiTabSwitches = 0;
  let activeMs = 0;

  for (const event of events) {
    if (event.type === "keystroke") {
      keystrokes += 1;
      const delta = Number(event.payload.deltaMs ?? 0);
      activeMs += Number.isFinite(delta) ? clamp(delta, 0, 5_000) : 0;
    }

    if (event.type === "paste") {
      pastes += 1;
      const characters = Number(event.payload.characterCount ?? 0);
      pasteVolume += Number.isFinite(characters) ? Math.max(0, characters) : 0;
    }

    if (event.type === "ai_tab_switch") {
      aiTabSwitches += 1;
    }
  }

  return {
    keystrokes,
    pastes,
    pasteVolume,
    aiTabSwitches,
    activeSeconds: Math.round(activeMs / 1_000),
  };
}

export function computeEffortScore(metrics: EffortMetrics): number {
  const totalInput = metrics.keystrokes + metrics.pasteVolume;
  const pasteRatio = totalInput === 0 ? 0 : metrics.pasteVolume / totalInput;
  const pastePenalty = Math.round(Math.min(45, pasteRatio * 100));
  const aiPenalty = Math.min(30, metrics.aiTabSwitches * 10);
  const idlePenalty = metrics.activeSeconds < 60 && metrics.pastes > 0 ? 10 : 0;

  return clamp(100 - pastePenalty - aiPenalty - idlePenalty, 0, 100);
}

export function computeIntegrityFlags(metrics: EffortMetrics): IntegrityFlag[] {
  const flags: IntegrityFlag[] = [];
  const totalInput = metrics.keystrokes + metrics.pasteVolume;
  const pasteRatio = totalInput === 0 ? 0 : metrics.pasteVolume / totalInput;

  if (pasteRatio >= 0.35 || metrics.pasteVolume >= 500) {
    flags.push("large_paste");
  }

  if (metrics.aiTabSwitches > 0) {
    flags.push("ai_tab_switch");
  }

  if (metrics.keystrokes < 100 && metrics.pasteVolume > 200) {
    flags.push("low_typing_ratio");
  }

  if (metrics.keystrokes === 0 && metrics.pastes === 0) {
    flags.push("telemetry_gap");
  }

  return flags.length > 0 ? flags : ["none"];
}

export function buildEffortScore(
  sessionId: string,
  studentId: string,
  assignmentId: string,
  metrics: EffortMetrics,
): EffortScore {
  return {
    sessionId,
    assignmentId,
    studentId,
    score: computeEffortScore(metrics),
    keystrokes: metrics.keystrokes,
    pastes: metrics.pastes,
    pasteVolume: metrics.pasteVolume,
    aiTabSwitches: metrics.aiTabSwitches,
    activeSeconds: metrics.activeSeconds,
    computedAt: new Date().toISOString(),
  };
}
