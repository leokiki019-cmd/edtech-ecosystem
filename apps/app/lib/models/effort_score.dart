import 'package:flutter/material.dart';

class EffortScore {
  const EffortScore({
    required this.sessionId,
    required this.assignmentId,
    required this.studentId,
    required this.score,
    required this.keystrokes,
    required this.pastes,
    required this.pasteVolume,
    required this.aiTabSwitches,
    required this.activeSeconds,
    required this.computedAt,
  });

  final String sessionId;
  final String assignmentId;
  final String studentId;
  final int score;
  final int keystrokes;
  final int pastes;
  final int pasteVolume;
  final int aiTabSwitches;
  final int activeSeconds;
  final DateTime computedAt;

  factory EffortScore.fromJson(Map<String, dynamic> json) {
    return EffortScore(
      sessionId: json['sessionId'] as String,
      assignmentId: json['assignmentId'] as String,
      studentId: json['studentId'] as String,
      score: json['score'] as int,
      keystrokes: json['keystrokes'] as int,
      pastes: json['pastes'] as int,
      pasteVolume: json['pasteVolume'] as int,
      aiTabSwitches: json['aiTabSwitches'] as int,
      activeSeconds: json['activeSeconds'] as int,
      computedAt: DateTime.tryParse(json['computedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'score': score,
      'keystrokes': keystrokes,
      'pastes': pastes,
      'pasteVolume': pasteVolume,
      'aiTabSwitches': aiTabSwitches,
      'activeSeconds': activeSeconds,
      'computedAt': computedAt.toIso8601String(),
    };
  }

  Color get scoreColor {
    if (score >= 75) {
      return const Color(0xFF34D399);
    }
    if (score >= 50) {
      return const Color(0xFFBBBF24);
    }
    return const Color(0xFFF87171);
  }
}
