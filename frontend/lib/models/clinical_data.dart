import 'dart:typed_data';

class TherapyPlan {
  const TherapyPlan({
    required this.patientId,
    required this.exerciseType,
    required this.title,
    required this.instructions,
    required this.sessionsPerWeek,
    required this.targetRepetitions,
    this.version = 1,
    this.sets = 1,
    this.targetAmplitudeDegrees,
    this.trainingSide = 'affected',
    this.cadenceSeconds,
    this.restSeconds = 60,
    this.customDetectionEnabled = false,
    this.detectionStartThreshold,
    this.detectionChangeThreshold,
    this.calibrationReason,
    this.startDate,
    this.endDate,
    this.active = true,
  });

  final String patientId;
  final String exerciseType;
  final String title;
  final String instructions;
  final int sessionsPerWeek;
  final int targetRepetitions;
  final int version;
  final int sets;
  final double? targetAmplitudeDegrees;
  final String trainingSide;
  final double? cadenceSeconds;
  final int restSeconds;
  final bool customDetectionEnabled;
  final double? detectionStartThreshold;
  final double? detectionChangeThreshold;
  final String? calibrationReason;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;
}

class RehabilitationSession {
  const RehabilitationSession({
    required this.id,
    required this.patientId,
    required this.exerciseType,
    required this.status,
    required this.createdAt,
    this.repetitions = 0,
    this.averageAmplitudeDegrees,
    this.confidence,
    this.averageDurationSeconds,
    this.averageVelocityDegreesPerSecond,
    this.averageSymmetryDifferenceDegrees,
    this.averageDistance,
    this.wellbeingScore,
    this.wellbeingNote,
    this.painScore,
    this.fatigueScore,
    this.professionalRating,
    this.professionalConduct,
    this.requiresReview = false,
    this.simulated = false,
    this.message = '',
    this.technicalIssueCode,
    this.videoStoragePath,
    this.videoSharedAt,
    this.videoConsentAt,
    this.videoRetentionUntil,
    this.videoConsentVersion,
    this.prescriptionVersion,
    this.prescribedSets,
    this.prescribedRepetitions,
    this.prescribedSessionsPerWeek,
    this.prescribedAmplitudeDegrees,
    this.prescribedTrainingSide,
    this.prescribedCadenceSeconds,
    this.prescribedRestSeconds,
    this.customDetectionApplied = false,
    this.detectionStartThreshold,
    this.detectionChangeThreshold,
    this.calibrationReason,
    this.movementEvents = const [],
    this.repetitionDetails = const [],
    this.affectedSide,
    this.unaffectedSide,
    this.averageAffectedAngleDegrees,
    this.averageUnaffectedAngleDegrees,
    this.eventReviews = const {},
    this.reviewComment,
    this.reviewVisibleToPatient = false,
    this.analysisParametersVersion,
    this.validFrames,
    this.totalFrames,
    this.detectionRatio,
    this.evidence = const [],
    this.evidenceConsentAt,
    this.evidenceConsentVersion,
  });

  final String id;
  final String patientId;
  final String exerciseType;
  final String status;
  final DateTime createdAt;
  final int repetitions;
  final double? averageAmplitudeDegrees;
  final double? confidence;
  final double? averageDurationSeconds;
  final double? averageVelocityDegreesPerSecond;
  final double? averageSymmetryDifferenceDegrees;
  final double? averageDistance;
  final int? wellbeingScore;
  final String? wellbeingNote;
  final int? painScore;
  final int? fatigueScore;
  final int? professionalRating;
  final String? professionalConduct;
  final bool requiresReview;
  final bool simulated;
  final String message;
  final String? technicalIssueCode;
  final String? videoStoragePath;
  final DateTime? videoSharedAt;
  final DateTime? videoConsentAt;
  final DateTime? videoRetentionUntil;
  final String? videoConsentVersion;
  final int? prescriptionVersion;
  final int? prescribedSets;
  final int? prescribedRepetitions;
  final int? prescribedSessionsPerWeek;
  final double? prescribedAmplitudeDegrees;
  final String? prescribedTrainingSide;
  final double? prescribedCadenceSeconds;
  final int? prescribedRestSeconds;
  final bool customDetectionApplied;
  final double? detectionStartThreshold;
  final double? detectionChangeThreshold;
  final String? calibrationReason;
  final List<MovementEvent> movementEvents;
  final List<RepetitionDetail> repetitionDetails;
  final String? affectedSide;
  final String? unaffectedSide;
  final double? averageAffectedAngleDegrees;
  final double? averageUnaffectedAngleDegrees;
  final Map<String, String> eventReviews;
  final String? reviewComment;
  final bool reviewVisibleToPatient;
  final String? analysisParametersVersion;
  final int? validFrames;
  final int? totalFrames;
  final double? detectionRatio;
  final List<AnalysisEvidence> evidence;
  final DateTime? evidenceConsentAt;
  final String? evidenceConsentVersion;

  bool get hasSharedVideo {
    if (videoStoragePath?.isNotEmpty != true) return false;
    final retention = videoRetentionUntil;
    return retention == null || retention.isAfter(DateTime.now());
  }

  bool get hasEvidence => evidence.isNotEmpty;
}

class AnalysisEvidence {
  const AnalysisEvidence({
    required this.eventIndex,
    required this.eventType,
    required this.title,
    required this.timestampSeconds,
    required this.bytes,
    this.contentType = 'image/jpeg',
  });

  final int eventIndex;
  final String eventType;
  final String title;
  final double timestampSeconds;
  final Uint8List bytes;
  final String contentType;
}

class MovementEvent {
  const MovementEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.startSeconds,
    required this.endSeconds,
    required this.severity,
    this.repetition,
  });

  final String type;
  final String title;
  final String description;
  final double startSeconds;
  final double endSeconds;
  final String severity;
  final int? repetition;

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'description': description,
    'startSeconds': startSeconds,
    'endSeconds': endSeconds,
    'severity': severity,
    'repetition': repetition,
  };

  factory MovementEvent.fromJson(Map<String, dynamic> json) => MovementEvent(
    type: json['type']?.toString() ?? 'information',
    title: json['title']?.toString() ?? 'Momento da análise',
    description: json['description']?.toString() ?? '',
    startSeconds:
        (json['startSeconds'] as num?)?.toDouble() ??
        (json['start_seconds'] as num?)?.toDouble() ??
        0,
    endSeconds:
        (json['endSeconds'] as num?)?.toDouble() ??
        (json['end_seconds'] as num?)?.toDouble() ??
        0,
    severity: json['severity']?.toString() ?? 'information',
    repetition: (json['repetition'] as num?)?.toInt(),
  );
}

class RepetitionDetail {
  const RepetitionDetail({
    required this.number,
    required this.startSeconds,
    required this.endSeconds,
    required this.amplitudeDegrees,
    required this.durationSeconds,
    required this.classification,
  });

  final int number;
  final double startSeconds;
  final double endSeconds;
  final double amplitudeDegrees;
  final double durationSeconds;
  final String classification;

  Map<String, dynamic> toJson() => {
    'number': number,
    'startSeconds': startSeconds,
    'endSeconds': endSeconds,
    'amplitudeDegrees': amplitudeDegrees,
    'durationSeconds': durationSeconds,
    'classification': classification,
  };

  factory RepetitionDetail.fromJson(Map<String, dynamic> json) =>
      RepetitionDetail(
        number: (json['number'] as num?)?.toInt() ?? 0,
        startSeconds:
            (json['startSeconds'] as num?)?.toDouble() ??
            (json['start_seconds'] as num?)?.toDouble() ??
            0,
        endSeconds:
            (json['endSeconds'] as num?)?.toDouble() ??
            (json['end_seconds'] as num?)?.toDouble() ??
            0,
        amplitudeDegrees:
            (json['amplitudeDegrees'] as num?)?.toDouble() ??
            (json['amplitude_degrees'] as num?)?.toDouble() ??
            0,
        durationSeconds:
            (json['durationSeconds'] as num?)?.toDouble() ??
            (json['duration_seconds'] as num?)?.toDouble() ??
            0,
        classification: json['classification']?.toString() ?? 'regular',
      );
}

class CareLink {
  const CareLink({
    required this.id,
    required this.patientId,
    required this.therapistId,
    required this.status,
    this.therapistName = 'Fisioterapeuta',
  });

  final String id;
  final String patientId;
  final String therapistId;
  final String therapistName;
  final String status;
}

class ProfessionalNote {
  const ProfessionalNote({
    required this.id,
    required this.patientId,
    required this.therapistId,
    required this.text,
    required this.createdAt,
    this.visibleToPatient = true,
  });

  final String id;
  final String patientId;
  final String therapistId;
  final String text;
  final DateTime createdAt;
  final bool visibleToPatient;
}

class CareMessage {
  const CareMessage({
    required this.id,
    required this.patientId,
    required this.therapistId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.category = 'general',
    this.sessionId,
    this.readAt,
  });

  final String id;
  final String patientId;
  final String therapistId;
  final String senderId;
  final String senderRole;
  final String text;
  final String category;
  final String? sessionId;
  final DateTime createdAt;
  final DateTime? readAt;
}

class DashboardSummary {
  const DashboardSummary({
    required this.patients,
    required this.sessions,
    required this.requiresReview,
    required this.adherence,
    this.attentionPatients = 0,
    this.inactivePatients = 0,
  });

  final int patients;
  final int sessions;
  final int requiresReview;
  final int adherence;
  final int attentionPatients;
  final int inactivePatients;
}
