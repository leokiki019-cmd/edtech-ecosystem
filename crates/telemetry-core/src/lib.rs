use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EventKind {
    Keystroke,
    Cursor,
    Paste,
    Focus,
    Blur,
    AiTabSwitch,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TelemetryEvent {
    pub id: String,
    pub session_id: String,
    pub assignment_id: String,
    pub student_id: String,
    pub kind: EventKind,
    pub occurred_at: String,
    pub payload: serde_json::Value,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EffortMetrics {
    pub keystrokes: u64,
    pub pastes: u64,
    pub paste_volume: u64,
    pub ai_tab_switches: u64,
    pub active_ms: u64,
}

impl EffortMetrics {
    pub fn from_events(events: &[TelemetryEvent]) -> Self {
        let mut metrics = Self::default();

        for event in events {
            match event.kind {
                EventKind::Keystroke => {
                    metrics.keystrokes += 1;
                    let delta = event
                        .payload
                        .get("deltaMs")
                        .and_then(|value| value.as_u64())
                        .unwrap_or(0);
                    metrics.active_ms += delta.min(5_000);
                }
                EventKind::Paste => {
                    metrics.pastes += 1;
                    let characters = event
                        .payload
                        .get("characterCount")
                        .and_then(|value| value.as_u64())
                        .unwrap_or(0);
                    metrics.paste_volume += characters;
                }
                EventKind::AiTabSwitch => metrics.ai_tab_switches += 1,
                EventKind::Cursor | EventKind::Focus | EventKind::Blur => {}
            }
        }

        metrics
    }

    pub fn active_seconds(&self) -> u64 {
        self.active_ms / 1_000
    }

    pub fn score(&self) -> u8 {
        let total_input = self.keystrokes + self.paste_volume;
        let paste_ratio = if total_input == 0 {
            0.0
        } else {
            self.paste_volume as f64 / total_input as f64
        };
        let paste_penalty = (paste_ratio * 100.0).min(45.0).round() as i64;
        let ai_penalty = (self.ai_tab_switches * 10).min(30) as i64;
        let idle_penalty = if self.active_seconds() < 60 && self.pastes > 0 {
            10
        } else {
            0
        };

        (100 - paste_penalty - ai_penalty - idle_penalty).clamp(0, 100) as u8
    }

    pub fn integrity_flags(&self) -> Vec<IntegrityFlag> {
        let mut flags = Vec::new();
        let total_input = self.keystrokes + self.paste_volume;
        let paste_ratio = if total_input == 0 {
            0.0
        } else {
            self.paste_volume as f64 / total_input as f64
        };

        if paste_ratio >= 0.35 || self.paste_volume >= 500 {
            flags.push(IntegrityFlag::LargePaste);
        }

        if self.ai_tab_switches > 0 {
            flags.push(IntegrityFlag::AiTabSwitch);
        }

        if self.keystrokes < 100 && self.paste_volume > 200 {
            flags.push(IntegrityFlag::LowTypingRatio);
        }

        if self.keystrokes == 0 && self.pastes == 0 {
            flags.push(IntegrityFlag::TelemetryGap);
        }

        if flags.is_empty() {
            flags.push(IntegrityFlag::None);
        }

        flags
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum IntegrityFlag {
    None,
    LargePaste,
    AiTabSwitch,
    LowTypingRatio,
    TelemetryGap,
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn event(kind: EventKind, payload: serde_json::Value) -> TelemetryEvent {
        TelemetryEvent {
            id: "e-001".to_string(),
            session_id: "s-001".to_string(),
            assignment_id: "a-001".to_string(),
            student_id: "u-student-1".to_string(),
            kind,
            occurred_at: "2026-10-19T10:00:00Z".to_string(),
            payload,
        }
    }

    #[test]
    fn organic_typing_scores_full_marks() {
        let events: Vec<TelemetryEvent> = (0..200)
            .map(|_| event(EventKind::Keystroke, json!({ "deltaMs": 120 })))
            .collect();

        let metrics = EffortMetrics::from_events(&events);

        assert_eq!(metrics.keystrokes, 200);
        assert_eq!(metrics.active_seconds(), 24);
        assert_eq!(metrics.score(), 100);
        assert_eq!(metrics.integrity_flags(), vec![IntegrityFlag::None]);
    }

    #[test]
    fn mass_paste_reduces_score_and_flags_large_paste() {
        let events = vec![
            event(EventKind::Keystroke, json!({ "deltaMs": 100 })),
            event(EventKind::Paste, json!({ "characterCount": 1200 })),
        ];

        let metrics = EffortMetrics::from_events(&events);

        assert_eq!(metrics.paste_volume, 1200);
        assert!(metrics.score() < 60);
        assert!(metrics.integrity_flags().contains(&IntegrityFlag::LargePaste));
    }

    #[test]
    fn ai_tab_switch_is_flagged_and_penalised() {
        let events = vec![
            event(EventKind::AiTabSwitch, json!({ "host": "chatgpt.com" })),
            event(EventKind::Keystroke, json!({ "deltaMs": 150 })),
        ];

        let metrics = EffortMetrics::from_events(&events);

        assert_eq!(metrics.ai_tab_switches, 1);
        assert!(metrics.integrity_flags().contains(&IntegrityFlag::AiTabSwitch));
        assert!(metrics.score() <= 90);
    }
}
