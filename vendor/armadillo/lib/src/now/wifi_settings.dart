// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ARMADILLAZARUS(parity): Original launched a separate Fuchsia module for
// WiFi settings via ApplicationWidget + modular framework.
// Stubbed to a placeholder. Original preserved in _research/topaz-m1011.

import 'package:flutter/widgets.dart';

/// Placeholder for Fuchsia WiFi settings module.
class WifiSettings extends StatelessWidget {
  /// Constructor.
  const WifiSettings({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('WiFi Settings\n(Fuchsia module stub)',
            textAlign: TextAlign.center),
      );
}
