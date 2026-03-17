// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

// NOTE: Some of the non-fuchsia flutter projects import this file, so this file
// should only contain pure dart/flutter files. Including any fuchsia-specific,
// FIDL related files here will break some of the host-side flutter tests we
// have. (See: https://fuchsia.atlassian.net/browse/SO-435)

export 'src/model/embedder_model.dart';
export 'src/model/idle_model.dart';
export 'src/model/model.dart';
export 'src/model/spring_model.dart';
export 'src/model/ticking_model.dart';

// ARMADILLAZARUS(parity): Fuchsia-only modular exports removed.
// Original also exported:
// - src/model/embedder_model.dart
// - src/model/tracing_spring_model.dart
// These depend on Fuchsia FIDL/Cobalt and are not needed for the shell UI.
