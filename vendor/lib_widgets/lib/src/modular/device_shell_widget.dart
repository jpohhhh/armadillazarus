// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:lib.app.dart/app.dart';
import 'package:fidl_fuchsia_auth/fidl.dart';
import 'package:fidl_fuchsia_modular/fidl.dart';
import 'package:fidl_fuchsia_modular_auth/fidl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fidl/fidl.dart';
import 'package:lib.device.dart/device.dart';
import 'package:meta/meta.dart';

import '../widgets/window_media_query.dart';
import 'device_shell_model.dart';

/// A wrapper widget intended to be the root of the application that is
/// a [DeviceShell].  Its main purpose is to hold the [StartupContext] and
/// [DeviceShell] instances so they aren't garbage collected.
/// For convenience, [advertise] does the advertising of the app as a
/// [DeviceShell] to the rest of the system via the [StartupContext].
/// Also for convienence, the [DeviceShellModel] given to this widget
/// will be made available to [child] and [child]'s descendants.
class DeviceShellWidget<T extends DeviceShellModel> extends StatelessWidget {
  /// The [StartupContext] to [advertise] its [DeviceShell] services to.
  final StartupContext startupContext;

  /// The bindings for the [DeviceShell] service implemented by [DeviceShellImpl].
  final Set<DeviceShellBinding> _deviceShellBindingSet =
      new Set<DeviceShellBinding>();

  /// The bindings for the [Lifecycle] service implemented by [DeviceShellImpl].
  final Set<LifecycleBinding> _lifecycleBindingSet =
      new Set<LifecycleBinding>();

  /// The [DeviceShell] to [advertise].
  final DeviceShellImpl _deviceShell;

  /// The rest of the application.
  final Widget child;

  final T _deviceShellModel;

  /// Constructor.
  DeviceShellWidget({
    required this.startupContext,
    T deviceShellModel,
    AuthenticationContext authenticationContext,
    AuthenticationUiContext authenticationUiContext,
    this.child,
  })  : _deviceShellModel = deviceShellModel,
        _deviceShell = _createDeviceShell(
          deviceShellModel,
          authenticationContext,
          authenticationUiContext,
        );

  @override
  Widget build(BuildContext context) => new MaterialApp(
        home: new Material(
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new WindowMediaQuery(
              child: _deviceShellModel == null
                  ? child
                  : new ScopedModel<T>(model: _deviceShellModel, child: child),
            ),
          ),
        ),
      );

  /// Advertises [_deviceShell] as a [DeviceShell] to the rest of the system via
  /// the [StartupContext].
  void advertise() {
    startupContext.outgoingServices
      ..addServiceForName((InterfaceRequest<DeviceShell> request) {
        DeviceShellBinding binding = new DeviceShellBinding()
          ..bind(_deviceShell, request);
        _deviceShellBindingSet.add(binding);
      }, DeviceShell.$serviceName)
      ..addServiceForName((InterfaceRequest<Lifecycle> request) {
        LifecycleBinding binding = new LifecycleBinding()
          ..bind(_deviceShell, request);
        _lifecycleBindingSet.add(binding);
      }, Lifecycle.$serviceName);
  }

  static DeviceShell _createDeviceShell(
    DeviceShellModel deviceShellModel,
    AuthenticationContext authenticationContext,
    AuthenticationUiContext authenticationUiContext,
  ) {
    return new DeviceShellImpl(
      authenticationContext: authenticationContext,
      authenticationUiContext: authenticationUiContext,
      onReady: deviceShellModel?.onReady,
      onStop: () {
        deviceShellModel?.onStop?.call();
      },
    );
  }

  /// Cancels any authentication flow currently in progress.
  void cancelAuthenticationFlow() {
    _deviceShell.closeAuthenticationContextBindings();
  }
}
