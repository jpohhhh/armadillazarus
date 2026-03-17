// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_mem/fidl.dart' as fuchsia_mem;
import 'package:fidl_fuchsia_scenic_snapshot/fidl.dart' as snapshot;
import 'package:fidl_fuchsia_sys/fidl.dart';
import 'package:fidl_fuchsia_ui_viewsv1/fidl.dart';
import 'package:lib.app.dart/app.dart';
import 'package:lib.ui.flutter/child_view.dart';

/// Manages loading of snapshots into view provided in |ChildViewConnection|.
class SnapshotManager {
  final ComponentControllerProxy _controller;
  final snapshot.LoaderProxy _loader;

  /// The |ChildViewConnection| for the view that displays the snapshot.
  final ChildViewConnection connection;

  SnapshotManager._create(this.connection, this._controller, this._loader);

  /// Factory method to create an instance of the SnapshotManager.
  factory SnapshotManager.create() {
    final controller = ComponentControllerProxy();
    final loader = snapshot.LoaderProxy();
    final startupContext = StartupContext.fromStartupInfo();
    final incomingServices = Services();

    final launcher = LauncherProxy();
    connectToService(startupContext.environmentServices, launcher.ctrl);
    launcher.createComponent(
      LaunchInfo(
        url: 'snapshot',
        directoryRequest: incomingServices.request(),
      ),
      controller.ctrl.request(),
    );
    launcher.ctrl.close();

    final viewProvider = ViewProviderProxy();
    incomingServices.connectToService(viewProvider.ctrl);

    final viewOwner = InterfacePair<ViewOwner>();
    viewProvider.createView(viewOwner.passRequest(), null);
    viewProvider.ctrl.close();

    incomingServices
      ..connectToService(loader.ctrl)
      ..close();

    return SnapshotManager._create(
      ChildViewConnection(viewOwner.passHandle()),
      controller,
      loader,
    );
  }

  /// Closes the snapshot loader and controller for the loader component.
  void close() {
    _loader.ctrl.close();
    _controller.ctrl.close();
  }

  /// Load the snapshot from the VMO buffer.
  void load(fuchsia_mem.Buffer snapshot) => _loader.load(snapshot);
}
