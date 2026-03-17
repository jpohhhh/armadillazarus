// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fuchsia/fuchsia.dart' as fuchsia;
import 'package:lib.app.dart/app.dart';
import 'package:fidl_fuchsia_modular/fidl.dart';
import 'package:lib.story.dart/story.dart';

import '../utils/deprecate.dart';

/// Called when Module connects to its [ModuleContext].
typedef OnModuleReady = void Function(
  ModuleContext moduleContext,
  Link link,
);

/// Called at the beginning of [Lifecycle.terminate].
typedef OnModuleStopping = void Function();

/// Called at the conclusion of [Lifecycle.terminate].
typedef OnModuleStop = void Function();

/// Called when the device map entry for the current device changes.
typedef OnDeviceMapChange = void Function(DeviceMapEntry deviceMapEntry);

/// Implements the [Lifecycle] service a Module needs to provide and connects to
/// the [ModuleContext] it needs to use.
class ModuleImpl implements Lifecycle {
  final ModuleContextProxy _moduleContextProxy = new ModuleContextProxy();
  final LinkProxy _linkProxy = new LinkProxy();
  final DeviceMapProxy _deviceMapProxy = new DeviceMapProxy();
  final DeviceMapWatcherBinding _deviceMapWatcherBinding =
      new DeviceMapWatcherBinding();

  LinkWatcherBinding _linkWatcherBinding;
  LinkWatcherImpl _linkWatcherImpl;

  /// The application context to use to get various system services.
  final StartupContext startupContext;

  /// Called when the Module connects to its [ModuleContext] service.
  final OnModuleReady onReady;

  /// Called at the beginning of [Lifecycle.terminate].
  final OnModuleStopping onStopping;

  /// Called at the conclusion of [Lifecycle.terminate].
  final OnModuleStop onStop;

  /// Called when [LinkWatcher.notify] is called.
  final LinkWatcherNotifyCallback onNotify;

  /// Called when the device map entry for the current device changes.
  final OnDeviceMapChange onDeviceMapChange;

  /// Indicates whether the [LinkWatcher] should watch for all changes including
  /// the changes made by this Module. If `true`, it calls [Link.watchAll] to
  /// register the [LinkWatcher], and [Link.watch] otherwise. Only takes effect
  /// when the [onNotify] callback is also provided. Defaults to `false`.
  final bool watchAll;

  /// Constructor.
  ModuleImpl({
    this.startupContext,
    this.onReady,
    this.onStopping,
    this.onStop,
    this.onNotify,
    this.onDeviceMapChange,
    bool watchAll,
  }) : watchAll = watchAll ?? false {
    deprecate('lib.widget\'s ModuleImpl');

    connectToService(
        startupContext.environmentServices, _moduleContextProxy.ctrl);

    _moduleContextProxy.getLink(null, _linkProxy.ctrl.request());

    if (onReady != null) {
      onReady(_moduleContextProxy, _linkProxy);
    }

    if (onNotify != null) {
      _linkWatcherImpl = new LinkWatcherImpl(onNotify: onNotify);
      _linkWatcherBinding = new LinkWatcherBinding();

      if (watchAll) {
        _linkProxy.watchAll(_linkWatcherBinding.wrap(_linkWatcherImpl));
      } else {
        _linkProxy.watch(_linkWatcherBinding.wrap(_linkWatcherImpl));
      }
    }

    if (onDeviceMapChange != null) {
      connectToService(
        startupContext.environmentServices,
        _deviceMapProxy.ctrl,
      );
      _deviceMapProxy.watchDeviceMap(
        _deviceMapWatcherBinding.wrap(
          new _DeviceMapWatcherImpl(onDeviceMapChange),
        ),
      );
    }
  }

  @override
  void terminate() {
    onStopping?.call();
    _linkWatcherBinding?.close();
    _moduleContextProxy.ctrl.close();
    _linkProxy.ctrl.close();
    _deviceMapProxy.ctrl.close();
    _deviceMapWatcherBinding.close();
    onStop?.call();
    fuchsia.exit(0);
  }
}

class _DeviceMapWatcherImpl extends DeviceMapWatcher {
  OnDeviceMapChange _onDeviceMapChange;

  _DeviceMapWatcherImpl(this._onDeviceMapChange);

  @override
  void onDeviceMapChange(DeviceMapEntry entry) {
    _onDeviceMapChange?.call(entry);
  }
}
