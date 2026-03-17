// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_modular/fidl.dart';
import 'package:fidl_fuchsia_ui_policy/fidl.dart';
import 'package:lib.widgets/model.dart';
import 'package:meta/meta.dart';

export 'package:lib.widgets/model.dart' show ScopedModel, ScopedModelDescendant;

/// The [Model] that provides a [DeviceShellContext] and [UserProvider].
class DeviceShellModel extends Model {
  DeviceShellContext _deviceShellContext;
  UserProvider _userProvider;
  Presentation _presentation;

  /// The [DeviceShellContext] given to this app's [DeviceShell].
  DeviceShellContext get deviceShellContext => _deviceShellContext;

  /// The [UserProvider] given to this app's [DeviceShell].
  UserProvider get userProvider => _userProvider;

  /// The [Presentation] given to this app's [DeviceShell].
  Presentation get presentation => _presentation;

  /// Called when this app's [DeviceShell] is given its [DeviceShellContext],
  /// and [UserProvider], and (optionally) its [Presentation].
  @mustCallSuper
  void onReady(
    UserProvider userProvider,
    DeviceShellContext deviceShellContext,
    Presentation presentation,
  ) {
    _userProvider = userProvider;
    _deviceShellContext = deviceShellContext;
    _presentation = presentation;
    notifyListeners();
  }

  /// Called when the app's [DeviceShell] stops.
  void onStop() => null;
}
