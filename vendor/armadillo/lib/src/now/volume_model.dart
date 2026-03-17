// ARMADILLAZARUS(parity): Original wrapped Fuchsia audio service.
// Stubbed as a simple Model with a level property.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

/// Stub for Fuchsia volume service.
class VolumeModel extends Model {
  double _level = 0.5;

  /// The current volume level from 0.0 to 1.0.
  double get level => _level;
  set level(double value) {
    _level = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Wraps [ModelFinder.of] for this [Model].
  static VolumeModel of(BuildContext context) =>
      ModelFinder<VolumeModel>().of(context, rebuildOnChange: true);
}
