// ARMADILLAZARUS(parity): Original used lib.settings/timezone_picker.dart
// which was a Fuchsia-specific timezone selection module.
// Stubbed as a placeholder. Original preserved in _research/topaz-m1011.

import 'package:flutter/material.dart';

import 'context_model.dart';

/// Placeholder for Fuchsia timezone picker.
class TimezonePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) => new ScopedModelDescendant<ContextModel>(
        builder:
            (BuildContext context, Widget? child, ContextModel contextModel) =>
                new Center(
          child: new Material(
            color: Colors.white,
            borderRadius: new BorderRadius.circular(8.0),
            child: new Padding(
              padding: const EdgeInsets.all(32.0),
              child: new Text('Timezone Picker\n(Fuchsia module stub)',
                  textAlign: TextAlign.center),
            ),
          ),
        ),
      );
}
