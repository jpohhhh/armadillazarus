// ARMADILLAZARUS(parity): Original wrapped Fuchsia voice input service.
// Stubbed as a no-op Model.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

/// Voice input state.
enum VoiceState { passive, listening, input }

/// Stub for Fuchsia voice input service.
class VoiceModel extends Model {
  /// Current voice state.
  VoiceState get state => VoiceState.passive;

  /// Whether voice is actively receiving input.
  bool get isInput => false;

  /// The current transcription text.
  String get transcription => '';

  /// Begin speech capture (no-op in stub).
  void beginSpeechCapture() {}

  /// Wraps [ModelFinder.of] for this [Model].
  static VoiceModel of(BuildContext context) =>
      ModelFinder<VoiceModel>().of(context, rebuildOnChange: true);
}
