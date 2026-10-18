import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/clinical_data.dart';
import '../models/patient_summary.dart';
import 'clinical_repository.dart';
import 'patient_alert_evaluator.dart';
import 'video_api_service.dart';

class FirebaseClinicalRepository implements ClinicalRepository {
  FirebaseClinicalRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    VideoApiService? videoApi,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _videoApi =
           videoApi ??
           VideoApiService(
             accessTokenProvider: () async =>
                 await (auth ?? FirebaseAuth.instance).currentUser
                     ?.getIdToken(),
           );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final VideoApiService _videoApi;

  @override
  bool get isDemo => false;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const ClinicalRepositoryException(
        'Sua sessão expirou. Entre novamente.',
      );
    }
    return uid;
  }

  @override
  Stream<List<TherapyPlan>> watchMyPlan() => _firestore
      .collection('plans')
      .where('patientId', isEqualTo: _uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(_planFrom)
            .where((plan) => _planAvailableToday(plan))
            .toList(),
      );

  @override
  Stream<List<TherapyPlan>> watchPatientPlans(String patientId) => _firestore
      .collection('plans')
      .where('patientId', isEqualTo: patientId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_planFrom).toList());

  bool _planAvailableToday(TherapyPlan plan) {
    if (!plan.active) return false;
    final today = DateTime.now();
    final start = plan.startDate;
    final end = plan.endDate;
    if (start != null && today.isBefore(start)) return false;
    if (end != null && today.isAfter(end.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  @override
  Stream<List<RehabilitationSession>> watchMySessions() =>
      watchPatientSessions(_uid);

  @override
  Stream<List<CareLink>> watchPendingLinks() => _firestore
      .collection('careLinks')
      .where('patientId', isEqualTo: _uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_linkFrom).toList());

  @override
  Stream<List<PatientSummary>> watchLinkedPatients() => _firestore
      .collection('careLinks')
      .where('therapistId', isEqualTo: _uid)
      .where('status', isEqualTo: 'accepted')
      .snapshots()
      .asyncMap((snapshot) async {
        final patients = <PatientSummary>[];
        for (final link in snapshot.docs) {
          final patientId = link.data()['patientId']?.toString() ?? '';
          if (patientId.isEmpty) continue;
          final profile = await _firestore
              .collection('users')
              .doc(patientId)
              .get();
          if (!profile.exists) continue;
          final sessions = await _firestore
              .collection('sessions')
              .where('patientId', isEqualTo: patientId)
              .get();
          final plans = await _firestore
              .collection('plans')
              .where('patientId', isEqualTo: patientId)
              .get();
          final data = profile.data()!;
          final sessionRecords = sessions.docs.map(_sessionFrom).toList();
          final planRecords = plans.docs.map(_planFrom).toList();
          final review = sessionRecords.any((item) => item.requiresReview);
          final dates = sessionRecords.map((item) => item.createdAt).toList()
            ..sort((a, b) => b.compareTo(a));
          final now = DateTime.now();
          final startOfPeriod = now.subtract(const Duration(days: 7));
          final recentSessions = dates
              .where((date) => date.isAfter(startOfPeriod))
              .length;
          final activePlans = planRecords.where(_planAvailableToday).toList();
          final expectedSessions = activePlans.fold<int>(
            0,
            (total, plan) => total + plan.sessionsPerWeek,
          );
          final adherence = expectedSessions == 0
              ? 0
              : ((recentSessions / expectedSessions) * 100)
                    .clamp(0, 100)
                    .round();
          final alerts = PatientAlertEvaluator.evaluate(
            sessions: sessionRecords,
            activePlans: activePlans,
            sessionsLastSevenDays: recentSessions,
            expectedSessionsPerWeek: expectedSessions,
            now: now,
          );
          final name = data['name']?.toString() ?? 'Paciente';
          patients.add(
            PatientSummary(
              id: patientId,
              name: name,
              initials: _initials(name),
              lastSession: dates.isEmpty
                  ? 'Sem sessões registradas'
                  : _dateLabel(dates.first),
              sessions: sessions.size,
              adherence: adherence,
              status: alerts.isNotEmpty
                  ? alerts.first.title
                  : review
                  ? 'Sessão requer revisão'
                  : 'Acompanhamento ativo',
              requiresReview: review,
              alerts: alerts,
              affectedSide: data['affectedSide']?.toString(),
              strokeType: data['strokeType']?.toString(),
              mobility: data['mobility']?.toString(),
              ageRange: data['ageRange']?.toString(),
              monthsSinceStroke: (data['monthsSinceStroke'] as num?)?.toInt(),
              dominantSide: data['dominantSide']?.toString(),
              assistiveDevice: data['assistiveDevice']?.toString(),
              participantContext:
                  data['participantContext']?.toString() ?? 'not_informed',
            ),
          );
        }
        patients.sort((a, b) {
          final attention = b.needsAttention.toString().compareTo(
            a.needsAttention.toString(),
          );
          if (attention != 0) return attention;
          final alerts = b.alerts.length.compareTo(a.alerts.length);
          return alerts != 0 ? alerts : a.name.compareTo(b.name);
        });
        return patients;
      });

  @override
  Stream<List<RehabilitationSession>> watchPatientSessions(String patientId) =>
      _firestore
          .collection('sessions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(_sessionFrom).toList());

  @override
  Stream<List<ProfessionalNote>> watchNotes(String patientId) => _firestore
      .collection('notes')
      .where('patientId', isEqualTo: patientId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_noteFrom).toList());

  @override
  Stream<List<ProfessionalNote>> watchMyOrientations() => _firestore
      .collection('notes')
      .where('patientId', isEqualTo: _uid)
      .where('visibleToPatient', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final notes = snapshot.docs.map(_noteFrom).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notes;
      });

  @override
  Stream<List<CareMessage>> watchMessages({String? patientId}) {
    final resolvedPatientId = patientId?.trim().isNotEmpty == true
        ? patientId!.trim()
        : _uid;
    return _firestore
        .collection('messages')
        .where('participants', arrayContains: _uid)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(_messageFrom)
              .where((message) => message.patientId == resolvedPatientId)
              .toList(),
        );
  }

  @override
  Stream<DashboardSummary> watchDashboard() => watchLinkedPatients().asyncMap((
    patients,
  ) async {
    var sessions = 0;
    var review = 0;
    final startOfPeriod = DateTime.now().subtract(const Duration(days: 7));
    for (final patient in patients) {
      final snapshot = await _firestore
          .collection('sessions')
          .where('patientId', isEqualTo: patient.id)
          .get();
      sessions += snapshot.docs.where((item) {
        final createdAt = item.data()['createdAt'];
        return createdAt is Timestamp &&
            createdAt.toDate().isAfter(startOfPeriod);
      }).length;
      review += snapshot.docs
          .where((item) => item.data()['requiresReview'] == true)
          .length;
    }
    final adherence = patients.isEmpty
        ? 0
        : (patients.fold<int>(
                    0,
                    (total, patient) => total + patient.adherence,
                  ) /
                  patients.length)
              .round();
    return DashboardSummary(
      patients: patients.length,
      sessions: sessions,
      requiresReview: review,
      adherence: adherence,
      attentionPatients: patients
          .where((patient) => patient.needsAttention)
          .length,
      inactivePatients: patients.where((patient) => patient.isInactive).length,
    );
  });

  @override
  Future<void> requestPatientLink(String patientId) async {
    final normalized = patientId.trim();
    if (normalized.isEmpty || normalized == _uid) {
      throw const ClinicalRepositoryException(
        'Informe um código de paciente válido.',
      );
    }
    final therapist = await _firestore.collection('users').doc(_uid).get();
    final linkId = '${_uid}_$normalized';
    try {
      final reference = _firestore.collection('careLinks').doc(linkId);
      final existing = await reference.get();
      if (existing.exists) {
        final status = existing.data()?['status']?.toString();
        if (status == 'accepted') {
          throw const ClinicalRepositoryException(
            'Este paciente já está vinculado ao seu perfil.',
          );
        }
        if (status == 'pending') {
          throw const ClinicalRepositoryException(
            'Já existe um convite aguardando resposta.',
          );
        }
        await reference.update({
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      await reference.set({
        'therapistId': _uid,
        'therapistName':
            therapist.data()?['name']?.toString() ?? 'Fisioterapeuta',
        'patientId': normalized,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on ClinicalRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const ClinicalRepositoryException(
        'Não foi possível enviar o convite. Confira o código informado.',
      );
    }
  }

  @override
  Future<void> respondToLink(String linkId, {required bool accept}) async {
    await _firestore.collection('careLinks').doc(linkId).update({
      'status': accept ? 'accepted' : 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> savePlan(TherapyPlan plan) async {
    final reference = _firestore
        .collection('plans')
        .doc('${plan.patientId}_${plan.exerciseType}');
    await _firestore.runTransaction((transaction) async {
      final current = await transaction.get(reference);
      final version = ((current.data()?['version'] as num?)?.toInt() ?? 0) + 1;
      transaction.set(reference, {
        'patientId': plan.patientId,
        'therapistId': _uid,
        'exerciseType': plan.exerciseType,
        'title': plan.title,
        'instructions': plan.instructions,
        'sessionsPerWeek': plan.sessionsPerWeek,
        'targetRepetitions': plan.targetRepetitions,
        'version': version,
        'sets': plan.sets,
        'targetAmplitudeDegrees': plan.targetAmplitudeDegrees,
        'trainingSide': plan.trainingSide,
        'cadenceSeconds': plan.cadenceSeconds,
        'restSeconds': plan.restSeconds,
        'customDetectionEnabled': plan.customDetectionEnabled,
        'detectionStartThreshold': plan.detectionStartThreshold,
        'detectionChangeThreshold': plan.detectionChangeThreshold,
        'calibrationReason': plan.calibrationReason,
        'startDate': plan.startDate == null
            ? null
            : Timestamp.fromDate(plan.startDate!),
        'endDate': plan.endDate == null
            ? null
            : Timestamp.fromDate(plan.endDate!),
        'active': plan.active,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> addNote({
    required String patientId,
    required String text,
    required bool visibleToPatient,
  }) async {
    await _firestore.collection('notes').add({
      'patientId': patientId,
      'therapistId': _uid,
      'text': text.trim(),
      'visibleToPatient': visibleToPatient,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendMessage({
    String? patientId,
    required String text,
    String category = 'general',
    String? sessionId,
  }) async {
    final normalized = text.trim();
    if (normalized.length < 2 || normalized.length > 1000) {
      throw const ClinicalRepositoryException(
        'A mensagem deve ter entre 2 e 1000 caracteres.',
      );
    }
    final profile = await _firestore.collection('users').doc(_uid).get();
    final role = profile.data()?['role']?.toString();
    late final String resolvedPatientId;
    late final String therapistId;
    if (role == 'patient') {
      resolvedPatientId = _uid;
      final links = await _firestore
          .collection('careLinks')
          .where('patientId', isEqualTo: _uid)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();
      if (links.docs.isEmpty) {
        throw const ClinicalRepositoryException(
          'Você ainda não possui um fisioterapeuta vinculado.',
        );
      }
      therapistId = links.docs.first.data()['therapistId']?.toString() ?? '';
    } else if (role == 'therapist' && patientId?.trim().isNotEmpty == true) {
      resolvedPatientId = patientId!.trim();
      therapistId = _uid;
    } else {
      throw const ClinicalRepositoryException(
        'Não foi possível identificar esta conversa.',
      );
    }
    await _firestore.collection('messages').add({
      'patientId': resolvedPatientId,
      'therapistId': therapistId,
      'senderId': _uid,
      'senderRole': role,
      'recipientId': role == 'patient' ? therapistId : resolvedPatientId,
      'participants': [resolvedPatientId, therapistId],
      'text': normalized,
      'category': category,
      'sessionId': sessionId,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': null,
    });
  }

  @override
  Future<void> markConversationRead({String? patientId}) async {
    final resolvedPatientId = patientId?.trim().isNotEmpty == true
        ? patientId!.trim()
        : _uid;
    final snapshot = await _firestore
        .collection('messages')
        .where('participants', arrayContains: _uid)
        .get();
    final unread = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['patientId'] == resolvedPatientId &&
          data['recipientId'] == _uid &&
          data['readAt'] == null;
    }).toList();
    if (unread.isEmpty) return;
    final batch = _firestore.batch();
    for (final message in unread) {
      batch.update(message.reference, {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  @override
  Future<void> saveSession(RehabilitationSession session) async {
    await _firestore.collection('sessions').doc(session.id).set({
      'patientId': _uid,
      'exerciseType': session.exerciseType,
      'status': session.status,
      'repetitions': session.repetitions,
      'averageAmplitudeDegrees': session.averageAmplitudeDegrees,
      'confidence': session.confidence,
      'averageDurationSeconds': session.averageDurationSeconds,
      'averageVelocityDegreesPerSecond':
          session.averageVelocityDegreesPerSecond,
      'averageSymmetryDifferenceDegrees':
          session.averageSymmetryDifferenceDegrees,
      'averageDistance': session.averageDistance,
      'requiresReview': session.requiresReview,
      'simulated': session.simulated,
      'message': session.message,
      'technicalIssueCode': session.technicalIssueCode,
      'prescriptionVersion': session.prescriptionVersion,
      'prescribedSets': session.prescribedSets,
      'prescribedRepetitions': session.prescribedRepetitions,
      'prescribedSessionsPerWeek': session.prescribedSessionsPerWeek,
      'prescribedAmplitudeDegrees': session.prescribedAmplitudeDegrees,
      'prescribedTrainingSide': session.prescribedTrainingSide,
      'prescribedCadenceSeconds': session.prescribedCadenceSeconds,
      'prescribedRestSeconds': session.prescribedRestSeconds,
      'customDetectionApplied': session.customDetectionApplied,
      'detectionStartThreshold': session.detectionStartThreshold,
      'detectionChangeThreshold': session.detectionChangeThreshold,
      'calibrationReason': session.calibrationReason,
      'movementEvents': session.movementEvents
          .map((event) => event.toJson())
          .toList(),
      'repetitionDetails': session.repetitionDetails
          .map((detail) => detail.toJson())
          .toList(),
      'affectedSideAtAnalysis': session.affectedSide,
      'unaffectedSideAtAnalysis': session.unaffectedSide,
      'averageAffectedAngleDegrees': session.averageAffectedAngleDegrees,
      'averageUnaffectedAngleDegrees': session.averageUnaffectedAngleDegrees,
      'analysisParametersVersion': session.analysisParametersVersion,
      'validFrames': session.validFrames,
      'totalFrames': session.totalFrames,
      'detectionRatio': session.detectionRatio,
      'analysisEvidence': session.evidence
          .map(
            (item) => {
              'eventIndex': item.eventIndex,
              'eventType': item.eventType,
              'title': item.title,
              'timestampSeconds': item.timestampSeconds,
              'contentType': item.contentType,
              'bytes': Blob(item.bytes),
            },
          )
          .toList(),
      'evidenceConsentAt': session.evidenceConsentAt == null
          ? null
          : Timestamp.fromDate(session.evidenceConsentAt!.toUtc()),
      'evidenceConsentVersion': session.evidenceConsentVersion,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> uploadSessionVideo({
    required String sessionId,
    required List<int> bytes,
    required String contentType,
    required DateTime consentAt,
  }) async {
    try {
      final links = await _firestore
          .collection('careLinks')
          .where('patientId', isEqualTo: _uid)
          .get();
      final accepted = links.docs.where(
        (document) => document.data()['status'] == 'accepted',
      );
      if (accepted.isEmpty) {
        throw const ClinicalRepositoryException(
          'Vincule um fisioterapeuta antes de compartilhar o vídeo.',
        );
      }
      final therapistId = accepted.first.data()['therapistId']?.toString();
      if (therapistId == null || therapistId.isEmpty) {
        throw const ClinicalRepositoryException(
          'O vínculo profissional não está completo.',
        );
      }
      final result = await _videoApi.upload(
        sessionId: sessionId,
        therapistId: therapistId,
        bytes: Uint8List.fromList(bytes),
        filename: 'session-$sessionId.${_videoExtension(contentType)}',
        contentType: contentType,
        consentAt: consentAt,
      );
      await _firestore.collection('sessions').doc(sessionId).update({
        'videoStoragePath': result.storagePath,
        'videoSharedAt': Timestamp.fromDate(result.sharedAt),
        'videoConsentAt': Timestamp.fromDate(result.consentAt),
        'videoRetentionUntil': Timestamp.fromDate(result.retentionUntil),
        'videoConsentVersion': result.consentVersion,
      });
    } on ClinicalRepositoryException {
      rethrow;
    } catch (_) {
      throw const ClinicalRepositoryException(
        'Não foi possível compartilhar o vídeo. A sessão foi mantida sem o arquivo.',
      );
    }
  }

  @override
  Future<String> downloadSessionVideo(RehabilitationSession session) async {
    final path = session.videoStoragePath;
    if (path == null || path.isEmpty) {
      throw const ClinicalRepositoryException('Esta sessão não possui vídeo.');
    }
    if (!session.hasSharedVideo) {
      throw const ClinicalRepositoryException(
        'O período de compartilhamento deste vídeo terminou.',
      );
    }
    try {
      return await _videoApi.download(session.id);
    } catch (_) {
      throw const ClinicalRepositoryException(
        'Não foi possível carregar o vídeo da sessão.',
      );
    }
  }

  @override
  Future<void> deleteSessionVideo(RehabilitationSession session) async {
    final path = session.videoStoragePath;
    if (path == null || path.isEmpty) return;
    await _videoApi.delete(session.id);
    await _firestore.collection('sessions').doc(session.id).update({
      'videoStoragePath': FieldValue.delete(),
      'videoDeletedAt': FieldValue.serverTimestamp(),
    });
  }

  String _videoExtension(String contentType) => switch (contentType) {
    'video/quicktime' => 'mov',
    'video/webm' => 'webm',
    _ => 'mp4',
  };

  @override
  Future<void> deleteSessionEvidence(RehabilitationSession session) async {
    await _firestore.collection('sessions').doc(session.id).update({
      'analysisEvidence': <Map<String, dynamic>>[],
      'evidenceDeletedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markSessionReviewed(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'requiresReview': false,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': _uid,
    });
  }

  @override
  Future<void> reviewSession({
    required String sessionId,
    required int rating,
    required String conduct,
    Map<String, String> eventReviews = const {},
    String? comment,
    bool visibleToPatient = false,
  }) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'requiresReview': false,
      'professionalRating': rating,
      'professionalConduct': conduct,
      'eventReviews': eventReviews,
      'reviewComment': comment?.trim() ?? '',
      'reviewVisibleToPatient': visibleToPatient,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': _uid,
    });
  }

  @override
  Future<void> saveWellbeing({
    required String sessionId,
    required int score,
    required int painScore,
    required int fatigueScore,
    String? note,
  }) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'wellbeingScore': score,
      'wellbeingNote': note?.trim() ?? '',
      'painScore': painScore,
      'fatigueScore': fatigueScore,
      'wellbeingUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  TherapyPlan _planFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return TherapyPlan(
      patientId: data['patientId']?.toString() ?? '',
      exerciseType: data['exerciseType']?.toString() ?? 'elbow_flexion',
      title: data['title']?.toString() ?? 'Exercício',
      instructions: data['instructions']?.toString() ?? '',
      sessionsPerWeek: (data['sessionsPerWeek'] as num?)?.toInt() ?? 0,
      targetRepetitions: (data['targetRepetitions'] as num?)?.toInt() ?? 0,
      version: (data['version'] as num?)?.toInt() ?? 1,
      sets: (data['sets'] as num?)?.toInt() ?? 1,
      targetAmplitudeDegrees: (data['targetAmplitudeDegrees'] as num?)
          ?.toDouble(),
      trainingSide: data['trainingSide']?.toString() ?? 'affected',
      cadenceSeconds: (data['cadenceSeconds'] as num?)?.toDouble(),
      restSeconds: (data['restSeconds'] as num?)?.toInt() ?? 60,
      customDetectionEnabled: data['customDetectionEnabled'] == true,
      detectionStartThreshold: (data['detectionStartThreshold'] as num?)
          ?.toDouble(),
      detectionChangeThreshold: (data['detectionChangeThreshold'] as num?)
          ?.toDouble(),
      calibrationReason: data['calibrationReason']?.toString(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      active: data['active'] != false,
    );
  }

  CareLink _linkFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CareLink(
      id: doc.id,
      patientId: data['patientId']?.toString() ?? '',
      therapistId: data['therapistId']?.toString() ?? '',
      therapistName: data['therapistName']?.toString() ?? 'Fisioterapeuta',
      status: data['status']?.toString() ?? 'pending',
    );
  }

  RehabilitationSession _sessionFrom(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return RehabilitationSession(
      id: doc.id,
      patientId: data['patientId']?.toString() ?? '',
      exerciseType: data['exerciseType']?.toString() ?? 'elbow_flexion',
      status: data['status']?.toString() ?? 'inconclusive',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repetitions: (data['repetitions'] as num?)?.toInt() ?? 0,
      averageAmplitudeDegrees: (data['averageAmplitudeDegrees'] as num?)
          ?.toDouble(),
      confidence: (data['confidence'] as num?)?.toDouble(),
      averageDurationSeconds: (data['averageDurationSeconds'] as num?)
          ?.toDouble(),
      averageVelocityDegreesPerSecond:
          (data['averageVelocityDegreesPerSecond'] as num?)?.toDouble(),
      averageSymmetryDifferenceDegrees:
          (data['averageSymmetryDifferenceDegrees'] as num?)?.toDouble(),
      averageDistance: (data['averageDistance'] as num?)?.toDouble(),
      wellbeingScore: (data['wellbeingScore'] as num?)?.toInt(),
      wellbeingNote: data['wellbeingNote']?.toString(),
      painScore: (data['painScore'] as num?)?.toInt(),
      fatigueScore: (data['fatigueScore'] as num?)?.toInt(),
      professionalRating: (data['professionalRating'] as num?)?.toInt(),
      professionalConduct: data['professionalConduct']?.toString(),
      requiresReview: data['requiresReview'] == true,
      simulated: data['simulated'] == true,
      message: data['message']?.toString() ?? '',
      technicalIssueCode: data['technicalIssueCode']?.toString(),
      videoStoragePath: data['videoStoragePath']?.toString(),
      videoSharedAt: (data['videoSharedAt'] as Timestamp?)?.toDate(),
      videoConsentAt: (data['videoConsentAt'] as Timestamp?)?.toDate(),
      videoRetentionUntil: (data['videoRetentionUntil'] as Timestamp?)
          ?.toDate(),
      videoConsentVersion: data['videoConsentVersion']?.toString(),
      prescriptionVersion: (data['prescriptionVersion'] as num?)?.toInt(),
      prescribedSets: (data['prescribedSets'] as num?)?.toInt(),
      prescribedRepetitions: (data['prescribedRepetitions'] as num?)?.toInt(),
      prescribedSessionsPerWeek: (data['prescribedSessionsPerWeek'] as num?)
          ?.toInt(),
      prescribedAmplitudeDegrees: (data['prescribedAmplitudeDegrees'] as num?)
          ?.toDouble(),
      prescribedTrainingSide: data['prescribedTrainingSide']?.toString(),
      prescribedCadenceSeconds: (data['prescribedCadenceSeconds'] as num?)
          ?.toDouble(),
      prescribedRestSeconds: (data['prescribedRestSeconds'] as num?)?.toInt(),
      customDetectionApplied: data['customDetectionApplied'] == true,
      detectionStartThreshold: (data['detectionStartThreshold'] as num?)
          ?.toDouble(),
      detectionChangeThreshold: (data['detectionChangeThreshold'] as num?)
          ?.toDouble(),
      calibrationReason: data['calibrationReason']?.toString(),
      movementEvents: (data['movementEvents'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MovementEvent.fromJson)
          .toList(),
      repetitionDetails:
          (data['repetitionDetails'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(RepetitionDetail.fromJson)
              .toList(),
      affectedSide: data['affectedSideAtAnalysis']?.toString(),
      unaffectedSide: data['unaffectedSideAtAnalysis']?.toString(),
      averageAffectedAngleDegrees: (data['averageAffectedAngleDegrees'] as num?)
          ?.toDouble(),
      averageUnaffectedAngleDegrees:
          (data['averageUnaffectedAngleDegrees'] as num?)?.toDouble(),
      eventReviews: (data['eventReviews'] as Map<String, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key, value.toString())),
      reviewComment: data['reviewComment']?.toString(),
      reviewVisibleToPatient: data['reviewVisibleToPatient'] == true,
      analysisParametersVersion: data['analysisParametersVersion']?.toString(),
      validFrames: (data['validFrames'] as num?)?.toInt(),
      totalFrames: (data['totalFrames'] as num?)?.toInt(),
      detectionRatio: (data['detectionRatio'] as num?)?.toDouble(),
      evidence: (data['analysisEvidence'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final value = item['bytes'];
            return AnalysisEvidence(
              eventIndex: (item['eventIndex'] as num?)?.toInt() ?? 0,
              eventType: item['eventType']?.toString() ?? 'information',
              title: item['title']?.toString() ?? 'Momento da análise',
              timestampSeconds:
                  (item['timestampSeconds'] as num?)?.toDouble() ?? 0,
              contentType: item['contentType']?.toString() ?? 'image/jpeg',
              bytes: value is Blob ? value.bytes : Uint8List(0),
            );
          })
          .where((item) => item.bytes.isNotEmpty)
          .toList(),
      evidenceConsentAt: (data['evidenceConsentAt'] as Timestamp?)?.toDate(),
      evidenceConsentVersion: data['evidenceConsentVersion']?.toString(),
    );
  }

  ProfessionalNote _noteFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ProfessionalNote(
      id: doc.id,
      patientId: data['patientId']?.toString() ?? '',
      therapistId: data['therapistId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      visibleToPatient: data['visibleToPatient'] != false,
    );
  }

  CareMessage _messageFrom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CareMessage(
      id: doc.id,
      patientId: data['patientId']?.toString() ?? '',
      therapistId: data['therapistId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderRole: data['senderRole']?.toString() ?? 'patient',
      text: data['text']?.toString() ?? '',
      category: data['category']?.toString() ?? 'general',
      sessionId: data['sessionId']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
