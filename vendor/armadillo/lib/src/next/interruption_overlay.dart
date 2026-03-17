// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:armadillo/common.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/widgets.dart';

import 'suggestion.dart';
import 'suggestion_list.dart' show OnSuggestionSelected;
import 'suggestion_widget.dart';

const Duration _kInterruptionShowingTimeout =
    const Duration(milliseconds: 3500);

double _kBottomSpacing = 24.0;

enum _RemoveDirection {
  left,
  down,
}

/// The reason why an interruption was dismissed.
enum DismissalReason {
  /// The interruption was snoozed due to user interaction.
  snoozed,

  /// The interruption was discarded due to user interaction.
  discarded,

  /// The interruption display timed out.
  timedOut,

  /// The interruption was programatically removed.
  removed,
}

/// Called when an interruption is no longer showing.
typedef OnInterruptionDismissed = void Function(
  Suggestion interruption,
  DismissalReason dismissalReason,
);

/// Displays interruptions.
class InterruptionOverlay extends StatefulWidget {
  /// Called when an interruption is selected.
  final OnSuggestionSelected? onSuggestionSelected;

  /// Called when an interruption is no longer showing.
  final OnInterruptionDismissed? onInterruptionDismissed;

  /// Constructor.
  const InterruptionOverlay({
    Key? key,
    this.onSuggestionSelected,
    this.onInterruptionDismissed,
  }) : super(key: key);

  @override
  InterruptionOverlayState createState() => new InterruptionOverlayState();
}

/// Tracks the positions of the current interrupts.
class InterruptionOverlayState extends State<InterruptionOverlay> {
  final List<Suggestion> _queuedInterruptions = <Suggestion>[];
  Suggestion? _currentInterruption;
  Timer? _currentInterruptionTimer;
  final List<Widget> _exitingInterruptionWidgets = <Widget>[];
  BoxConstraints? _constraints;
  bool _removeImmediatelyOnPanEnd = false;

  /// Adds an interruption to the overlay.
  void onInterruptionAdded(Suggestion interruption) {
    if (_currentInterruption == null) {
      setState(() {
        _currentInterruption = interruption;
      });
      _startInterruptionTimer();
    } else {
      _queuedInterruptions.add(interruption);
    }
  }

  /// Removes the interruption from the overlay.
  void onInterruptionRemoved(String uuid) {
    // Remove the interruption if its in the queue.
    _queuedInterruptions.removeWhere(
      (Suggestion interruption) => interruption.id.value == uuid,
    );
    if (_currentInterruption?.id?.value == uuid) {
      _removeCurrentInterruption();
    }
  }

  /// Removes all interruptions from the overlay.
  void onInterruptionsRemoved() {
    // Remove all interruptions in the queue.
    _queuedInterruptions.clear();

    if (_currentInterruption != null) {
      _removeCurrentInterruption();
    }
  }

  // If an interruption is being displayed and not being interacted with the
  // user, dismiss it.  Otherwise, wait until the pan ends to dismiss it.
  void _removeCurrentInterruption() {
    if (_currentInterruptionTimer != null) {
      _stopInterruptionTimer();
      _removeInterruption(
        _RemoveDirection.down,
        Offset.zero,
        DismissalReason.removed,
      );
    } else {
      _removeImmediatelyOnPanEnd = true;
    }
  }

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _constraints = constraints;

          List<Widget> stackChildren = new List<Widget>.from(
            _exitingInterruptionWidgets,
          );
          if (_currentInterruption != null) {
            _currentInterruption!.suggestionLayout.layout(
              _constraints!.maxWidth,
              Directionality.of(context),
            );
            double suggestionHeight =
                _currentInterruption!.suggestionLayout.suggestionHeight;
            stackChildren.add(
              new ScopedModelDescendant<SizeModel>(
                builder: (
                  BuildContext context,
                  Widget? child,
                  SizeModel sizeModel,
                ) =>
                    new SimulatedPositioned(
                  key: new ObjectKey(_currentInterruption!),
                  initRect: new Rect.fromLTWH(
                    sizeModel.interruptionLeftMargin,
                    constraints.maxHeight + sizeModel.askHeight,
                    sizeModel.suggestionWidth,
                    suggestionHeight,
                  ),
                  rect: new Rect.fromLTWH(
                    sizeModel.interruptionLeftMargin,
                    constraints.maxHeight - _kBottomSpacing - suggestionHeight,
                    sizeModel.suggestionWidth,
                    suggestionHeight,
                  ),
                  dragOffsetTransform: (
                    Offset currentOffset,
                    DragUpdateDetails details,
                  ) {
                    Offset newOffset = currentOffset + details.delta;
                    return new Offset(
                      details.delta.dx * ((newOffset.dx <= 0.0) ? 1.0 : 0.3),
                      details.delta.dy *
                          ((newOffset.dy >= 0.0 &&
                                  newOffset.dy <=
                                      (sizeModel.askHeight +
                                          _kBottomSpacing +
                                          suggestionHeight))
                              ? 1.0
                              : 0.3),
                    );
                  },
                  onDragStart: (_) => _stopInterruptionTimer(),
                  onDragEnd: (SimulatedDragEndDetails details) {
                    if (details.offset.dy > 50.0) {
                      _removeInterruption(
                        _RemoveDirection.down,
                        details.offset,
                        DismissalReason.snoozed,
                      );
                    } else if (details.offset.dx < -100.0) {
                      _removeInterruption(
                        _RemoveDirection.left,
                        details.offset,
                        DismissalReason.discarded,
                      );
                    } else if (_removeImmediatelyOnPanEnd) {
                      _removeInterruption(
                        _RemoveDirection.down,
                        Offset.zero,
                        DismissalReason.removed,
                      );
                      _removeImmediatelyOnPanEnd = false;
                    } else {
                      _startInterruptionTimer();
                    }
                  },
                  child: child!,
                ),
                child: new Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: new _FadeInWidget(
                    key: new ObjectKey(_currentInterruption!),
                    opacity: 1.0,
                    child: new SuggestionWidget(
                      key: _currentInterruption!.globalKey,
                      suggestion: _currentInterruption!,
                      onSelected: () => _onSuggestionSelected(
                        _currentInterruption!,
                      ),
                      shadow: true,
                    ),
                  ),
                ),
              ),
            );
          }

          return new Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: stackChildren,
          );
        },
      );

  void _removeInterruption(
    _RemoveDirection direction,
    Offset offset,
    DismissalReason reason,
  ) {
    SizeModel sizeModel = SizeModel.of(context);
    Suggestion interruptionToRemove = _currentInterruption!;
    assert(interruptionToRemove != null);
    interruptionToRemove.suggestionLayout.layout(
      _constraints!.maxWidth,
      Directionality.of(context),
    );
    double suggestionHeight =
        interruptionToRemove.suggestionLayout.suggestionHeight;
    late Widget exitingWidget;
    exitingWidget = new SimulatedPositioned(
      key: new ObjectKey(interruptionToRemove),
      rect: new Rect.fromLTWH(
        direction == _RemoveDirection.down
            ? sizeModel.interruptionLeftMargin
            : -sizeModel.suggestionWidth - sizeModel.interruptionLeftMargin,
        direction == _RemoveDirection.down
            ? _constraints!.maxHeight + sizeModel.askHeight
            : _constraints!.maxHeight -
                _kBottomSpacing -
                suggestionHeight +
                offset.dy,
        sizeModel.suggestionWidth,
        suggestionHeight,
      ),
      onRectReached: () {
        if (mounted) {
          setState(() {
            _exitingInterruptionWidgets.remove(exitingWidget);
          });
        }
        widget.onInterruptionDismissed?.call(
          interruptionToRemove,
          reason,
        );
      },
      child: new Align(
        alignment: FractionalOffset.bottomCenter,
        child: new _FadeInWidget(
          key: new ObjectKey(interruptionToRemove),
          opacity: 1.0,
          child: new SuggestionWidget(
            key: interruptionToRemove.globalKey,
            suggestion: interruptionToRemove,
            shadow: true,
          ),
        ),
      ),
    );

    setState(() {
      _exitingInterruptionWidgets.add(exitingWidget);
      if (_queuedInterruptions.isEmpty) {
        _currentInterruption = null;
      } else {
        _currentInterruption = _queuedInterruptions.removeAt(0) as Suggestion;
        _startInterruptionTimer();
      }
    });
  }

  void _startInterruptionTimer() {
    _stopInterruptionTimer();
    _currentInterruptionTimer = new Timer(_kInterruptionShowingTimeout, () {
      if (mounted) {
        _removeInterruption(
          _RemoveDirection.down,
          Offset.zero,
          DismissalReason.timedOut,
        );
      }
    });
  }

  void _stopInterruptionTimer() {
    _currentInterruptionTimer?.cancel();
    _currentInterruptionTimer = null;
  }

  void _onSuggestionSelected(Suggestion suggestion) {
    setState(() {
      if (_queuedInterruptions.isEmpty) {
        _currentInterruption = null;
      } else {
        _currentInterruption = _queuedInterruptions.removeAt(0);
        _startInterruptionTimer();
      }
    });

    switch (suggestion.selectionType) {
      case SelectionType.launchStory:
      case SelectionType.modifyStory:
      case SelectionType.closeSuggestions:
        // We pass the bounds of the suggestion w.r.t.
        // global coordinates so it can be mapped back to
        // local coordinates when it's displayed in the
        // SelectedSuggestionOverlay.
        RenderBox box = suggestion.globalKey.currentContext!.findRenderObject()!
            as RenderBox;
        widget.onSuggestionSelected?.call(
          suggestion,
          box.localToGlobal(Offset.zero) & box.size,
        );
        break;
      case SelectionType.doNothing:
      default:
        break;
    }
  }
}

class _FadeInWidget extends StatefulWidget {
  final double opacity;
  final Widget child;

  const _FadeInWidget({Key? key, this.opacity = 1.0, required this.child})
      : super(key: key);

  @override
  _FadeInWidgetState createState() => new _FadeInWidgetState();
}

class _FadeInWidgetState extends State<_FadeInWidget> {
  bool _hasBeenBuilt = false;

  @override
  Widget build(BuildContext context) {
    double opacity = widget.opacity;
    if (!_hasBeenBuilt) {
      scheduleMicrotask(() => setState(() {}));
      _hasBeenBuilt = true;
      opacity = 0.0;
    }

    return new AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 300),
      curve: const Interval(0.33, 1.0, curve: Curves.fastOutSlowIn),
      child: widget.child,
    );
  }
}
