// ARMADILLAZARUS(parity): Original wrapped Fuchsia power service.
// Stubbed with reasonable defaults.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

/// Stub for Fuchsia power service.
class PowerModel extends Model {
  /// Whether the device has a battery.
  bool get hasBattery => false;

  /// Battery percentage text.
  String get batteryText => '';

  /// Battery image URL.
  String get batteryImageUrl => '';

  /// Wraps [ModelFinder.of] for this [Model].
  static PowerModel of(BuildContext context) =>
      ModelFinder<PowerModel>().of(context, rebuildOnChange: true);
}
