import 'package:image_picker/image_picker.dart';

import 'clinical_data.dart';

class SelectedVideo {
  const SelectedVideo(
    this.file, {
    this.exerciseType = 'elbow_flexion',
    this.shareWithTherapist = false,
    this.consentAt,
    this.shareFullVideo = false,
    this.videoConsentAt,
    this.plan,
  });

  final XFile file;
  final String exerciseType;
  final bool shareWithTherapist;
  final DateTime? consentAt;
  final bool shareFullVideo;
  final DateTime? videoConsentAt;
  final TherapyPlan? plan;
}
