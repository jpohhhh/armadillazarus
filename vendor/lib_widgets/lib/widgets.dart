// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

// NOTE: Some of the non-fuchsia flutter projects import this file, so this file
// should only contain pure dart/flutter files. Including any fuchsia-specific,
// FIDL related files here will break some of the host-side flutter tests we
// have. (See: https://fuchsia.atlassian.net/browse/SO-435)

export 'src/widgets/alphatar.dart';
export 'src/widgets/conditional_builder.dart';
export 'src/widgets/fuchsia_spinner.dart';
export 'src/widgets/future_widget.dart';
export 'src/widgets/mondrian_spinner.dart';
export 'src/widgets/rk4_spring_simulation.dart';
export 'src/widgets/shadowed_text.dart';
export 'src/widgets/simulated_positioned.dart';
export 'src/widgets/text_placeholder.dart';
export 'src/widgets/ticking_double_state.dart';
export 'src/widgets/ticking_state.dart';
export 'src/widgets/window_media_query.dart';

// ARMADILLAZARUS(parity): Fuchsia-only modular exports removed.
// Original also had a separate modular.dart barrel that exported:
// - src/modular/user_shell_model.dart
// - src/modular/user_shell_widget.dart
// - src/modular/device_shell_model.dart
// - src/modular/device_shell_widget.dart
// - src/modular/dank_user_shell_widget.dart
// - src/application/application_widget.dart
// These depend on Fuchsia FIDL services and are not needed for shell UI.
