// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:fidl_fuchsia_ui_input/fidl.dart';
import 'package:fidl_fuchsia_ui_policy/fidl.dart';
import 'package:flutter/scheduler.dart';

/// Listens for pointer events and injects them into Flutter input pipeline.
class PointerEventsListener implements PointerCaptureListenerHack {
  // Holds the fidl binding to receive pointer events.
  final PointerCaptureListenerHackBinding _pointerCaptureListenerBinding =
      new PointerCaptureListenerHackBinding();

  // Holds the last [PointerEvent] mapped to its pointer id. This is used to
  // determine the correct [PointerDataPacket] to generate at boundary condition
  // of the screen rect.
  final Map<int, PointerEvent> _lastPointerEvent = <int, PointerEvent>{};

  // Flag to remember that a down event was seen before a move event.
  // TODO(sanjayc): Should really convert to a FSM for PointerEvent.
  final Map<int, bool> _downEvent = <int, bool>{};

  // Holds the [onPointerDataCallback] assigned to [ui.window] at
  // the start of the program.
  ui.PointerDataPacketCallback _originalCallback;

  final _queuedEvents = <PointerEvent>[];
  bool _frameScheduled = false;

  /// Starts listening to pointer events. Also overrides the original
  /// [ui.window.onPointerDataPacket] callback to a NOP since we
  /// inject the pointer events received from the [Presentation] service.
  void listen(Presentation presentation) {
    _originalCallback = ui.window.onPointerDataPacket;
    ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {};

    presentation
        .capturePointerEventsHack(_pointerCaptureListenerBinding.wrap(this));
  }

  /// Stops listening to pointer events. Also restores the
  /// [ui.window.onPointerDataPacket] callback.
  void stop() {
    if (_originalCallback != null) {
      _cleanupPointerEvents();
      _pointerCaptureListenerBinding.close();

      // Restore the original pointer events callback on the window.
      ui.window.onPointerDataPacket = _originalCallback;
      _originalCallback = null;
      _lastPointerEvent.clear();
      _downEvent.clear();
    }
  }

  void _cleanupPointerEvents() {
    for (PointerEvent lastEvent in _lastPointerEvent.values.toList()) {
      if (lastEvent.phase != PointerEventPhase.remove &&
          lastEvent.type != PointerEventType.mouse) {
        onPointerEvent(_clone(lastEvent, PointerEventPhase.remove));
      }
    }
  }

  PointerEvent _clone(PointerEvent event, [PointerEventPhase phase]) {
    return new PointerEvent(
        buttons: event.buttons,
        deviceId: event.deviceId,
        eventTime: event.eventTime,
        phase: phase ?? event.phase,
        pointerId: event.pointerId,
        radiusMajor: event.radiusMajor,
        radiusMinor: event.radiusMinor,
        type: event.type,
        x: event.x,
        y: event.y);
  }

  /// |PointerCaptureListener|.
  @override
  void onPointerEvent(PointerEvent event) {
    _onPointerEvent(event);
  }

  void _onPointerEvent(PointerEvent event) {
    if (_originalCallback == null) {
      return;
    }

    _queuedEvents.add(event);

    if (_frameScheduled) {
      return;
    }

    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (_originalCallback == null) {
        return;
      }
      _frameScheduled = false;
      Timeline.startSync('PointerEventsListener.onPointerEvent');
      List<ui.PointerData> packets = [];
      for (PointerEvent event in _queuedEvents) {
        final packet = _getPacket(event);
        if (packet != null) {
          packets.add(packet);
        }
      }
      if (packets.isNotEmpty) {
        _originalCallback(new ui.PointerDataPacket(data: packets));
      }
      _queuedEvents.clear();
      Timeline.finishSync();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  ui.PointerChange _changeFromPointerEvent(PointerEvent event) {
    PointerEvent lastEvent = _lastPointerEvent[event.pointerId] ?? event;

    switch (event.phase) {
      case PointerEventPhase.add:
        return ui.PointerChange.add;
      case PointerEventPhase.hover:
        return ui.PointerChange.hover;
      case PointerEventPhase.down:
        _downEvent[event.pointerId] = true;
        return ui.PointerChange.down;
      case PointerEventPhase.move:
        // If move is the first event, convert to `add` event. Otherwise,
        // flutter pointer state machine throws an exception.
        if (event.type != PointerEventType.mouse &&
            _lastPointerEvent[event.pointerId] == null) {
          return ui.PointerChange.add;
        }

        // If move event was seen before down event, convert to `down` event.
        if (event.type != PointerEventType.mouse &&
            _downEvent[event.pointerId] != true) {
          _downEvent[event.pointerId] = true;
          return ui.PointerChange.down;
        }

        // For mouse, return a hover event if no buttons were pressed.
        if (event.type == PointerEventType.mouse && event.buttons == 0) {
          return ui.PointerChange.hover;
        }

        // Check if this is a boundary condition and convert to up/down event.
        if (lastEvent?.phase == PointerEventPhase.move) {
          if (_outside(lastEvent) && _inside(event)) {
            return ui.PointerChange.down;
          }
          if (_inside(lastEvent) && _outside(event)) {
            return ui.PointerChange.cancel;
          }
        }

        return ui.PointerChange.move;
      case PointerEventPhase.up:
        _downEvent[event.pointerId] = false;
        return ui.PointerChange.up;
      case PointerEventPhase.remove:
        return ui.PointerChange.remove;
      case PointerEventPhase.cancel:
      default:
        return ui.PointerChange.cancel;
    }
  }

  ui.PointerDeviceKind _kindFromPointerEvent(PointerEvent event) {
    switch (event.type) {
      case PointerEventType.mouse:
        return ui.PointerDeviceKind.mouse;
      case PointerEventType.stylus:
        return ui.PointerDeviceKind.stylus;
      case PointerEventType.invertedStylus:
        return ui.PointerDeviceKind.invertedStylus;
      case PointerEventType.touch:
      default:
        return ui.PointerDeviceKind.touch;
    }
  }

  ui.PointerData _getPacket(PointerEvent event) {
    PointerEvent lastEvent = _lastPointerEvent[event.pointerId] ?? event;

    // Only allow add and remove pointer events from outside the window bounds.
    // For other events, we drop them if the last two were outside the window
    // bounds. If any of current event or last event lies inside the window,
    // we generate a synthetic down or up event.
    if (event.phase != PointerEventPhase.add &&
        event.phase != PointerEventPhase.remove &&
        _outside(event) &&
        _outside(lastEvent)) {
      _lastPointerEvent[event.pointerId] = event;
      return null;
    }

    // Convert from PointerEvent to PointerData.
    final data = new ui.PointerData(
      buttons: event.buttons,
      device: event.pointerId,
      timeStamp: new Duration(microseconds: event.eventTime ~/ 1000),
      change: _changeFromPointerEvent(event),
      kind: _kindFromPointerEvent(event),
      physicalX: event.x * ui.window.devicePixelRatio,
      physicalY: event.y * ui.window.devicePixelRatio,
    );

    // Remember this event for checking boundary condition on the next event.
    _lastPointerEvent[event.pointerId] = event;

    return data;
  }

  bool _inside(PointerEvent event) {
    return event != null &&
        event.x * ui.window.devicePixelRatio >= 0 &&
        event.x * ui.window.devicePixelRatio < ui.window.physicalSize.width &&
        event.y * ui.window.devicePixelRatio >= 0 &&
        event.y * ui.window.devicePixelRatio < ui.window.physicalSize.height;
  }

  bool _outside(PointerEvent event) => !_inside(event);
}
