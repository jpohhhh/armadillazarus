// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'model.dart';

/// Status enum for [EmbedderModel]
enum EmbedderModelStatus {
  /// ModuleState
  starting,

  /// ModuleState
  running,

  /// ModuleState
  unlinked,

  /// ModuleState
  done,

  /// ModuleState
  stopped,

  /// ModuleState
  error,

  /// resolution status
  resolving,

  /// resolution status
  notFound,
}

/// Abstract .
abstract class EmbedderModel extends Model {
  /// The current status of the Module being embedded.
  late EmbedderModelStatus status;

  /// Indicates whether the intent has been started.
  bool get intentStarted;

  /// Gets the desired height of this embedded module.
  double get height;

  /// The build method to be used by builders of any
  /// ScopedModelDescendant<EmbedderModel>.
  Widget build(BuildContext context);
}
