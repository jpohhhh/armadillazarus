// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/common.dart';
import 'package:armadillo/recent.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'expand_suggestion.dart';
import 'interruption_overlay.dart';
import 'peeking_overlay.dart';
import 'selected_suggestion_overlay.dart';
import 'splash_suggestion.dart';
import 'suggestion.dart';
import 'suggestion_list.dart';
import 'suggestion_model.dart';

const double _kSuggestionOverlayPullScrollOffset = 100.0;
const double _kSuggestionOverlayScrollFactor = 1.2;

/// Builds next.
class NextBuilder {
  final FocusScopeNode _conductorFocusNode = new FocusScopeNode();
  final FocusNode _askFocusNode = new FocusNode();

  final GlobalKey<PeekingOverlayState> _suggestionOverlayKey =
      new GlobalKey<PeekingOverlayState>();
  final GlobalKey<SuggestionListState> _suggestionListKey =
      new GlobalKey<SuggestionListState>();
  final ScrollController _suggestionListScrollController =
      new ScrollController();
  final GlobalKey<InterruptionOverlayState> _interruptionOverlayKey =
      new GlobalKey<InterruptionOverlayState>();

  /// The key for adding [Suggestion]s to the [SelectedSuggestionOverlay].  This
  /// is to allow us to animate from a [Suggestion] in an open [SuggestionList]
  /// to a Story focused in the StoryList.
  final GlobalKey<SelectedSuggestionOverlayState>
      _selectedSuggestionOverlayKey =
      new GlobalKey<SelectedSuggestionOverlayState>();

  /// Called when the suggestion overlay is shown/hidden.
  ValueChanged<bool>? _onSuggestionsOverlayChanged;

  /// Called when an interruption is no longer showing.
  OnInterruptionDismissed? _onInterruptionDismissed;

  /// Called when the suggestion overlay is shown/hidden.
  set onSuggestionsOverlayChanged(
      ValueChanged<bool> onSuggestionsOverlayChanged) {
    _onSuggestionsOverlayChanged = onSuggestionsOverlayChanged;
  }

  /// Called when an interruption is no longer showing.
  set onInterruptionDismissed(OnInterruptionDismissed onInterruptionDismissed) {
    _onInterruptionDismissed = onInterruptionDismissed;
  }

  /// Builds now.
  Widget build(
    BuildContext context, {
    VoidCallback? onMinimizeNow,
  }) =>
      _buildNow(context, onMinimizeNow: onMinimizeNow);

  Widget _buildNow(
    BuildContext context, {
    VoidCallback? onMinimizeNow,
  }) =>
      new Stack(
        children: <Widget>[
          new ScopedModelDescendant<SizeModel>(
            builder: (
              BuildContext context,
              Widget? child,
              SizeModel sizeModel,
            ) =>
                new Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                // TODO: remove this hack when Scenic focus is fixed (MZ-118)
                // HACK: Due to a mozart focus issue we need to focus when the mozart
                // window this widget is in is first tapped.
                if (!_askFocusNode.hasFocus) {
                  _conductorFocusNode.requestFocus(_askFocusNode);
                }
              },
              child: new FocusScope(
                autofocus: true,
                node: _conductorFocusNode,
                child: new PeekingOverlay(
                  key: _suggestionOverlayKey,
                  peekHeight: sizeModel.suggestionPeekHeight,
                  dragHandleHeight: sizeModel.askHeight,
                  onHide: () {
                    _onSuggestionsOverlayChanged?.call(false);

                    if (_suggestionListScrollController.hasClients) {
                      _suggestionListScrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.fastOutSlowIn,
                      );
                    }
                    _suggestionListKey.currentState?.stopAsking();
                  },
                  onShow: () {
                    _onSuggestionsOverlayChanged?.call(true);
                  },
                  child: new SuggestionList(
                    key: _suggestionListKey,
                    scrollController: _suggestionListScrollController,
                    onAskingStarted: () {
                      _suggestionOverlayKey.currentState?.show();
                    },
                    onAskingEnded: () {
                      // No-op: stopAsking already handles cleanup internally.
                      // Calling stopAsking here would cause infinite recursion.
                    },
                    onSuggestionSelected: (
                      Suggestion suggestion,
                      Rect globalBounds,
                    ) =>
                        _onSuggestionSelected(
                      context,
                      suggestion,
                      globalBounds,
                      onMinimizeNow ?? () {},
                    ),
                    askFocusNode: _askFocusNode,
                  ),
                ),
              ),
            ),
          ),

          // Selected Suggestion Overlay.
          // This is only visible in transitoning the user from a Suggestion
          // in an open SuggestionList to a focused Story in the StoryList.
          new SelectedSuggestionOverlay(
            key: _selectedSuggestionOverlayKey,
          ),

          // Interruption Overlay.
          new InterruptionOverlay(
            key: _interruptionOverlayKey,
            onSuggestionSelected: (
              Suggestion suggestion,
              Rect globalBounds,
            ) =>
                _onSuggestionSelected(
              context,
              suggestion,
              globalBounds,
              onMinimizeNow ?? () {},
            ),
            onInterruptionDismissed: _onInterruptionDismissed,
          ),
        ],
      );

  /// Shows the suggestion overlay.
  void show() => _suggestionOverlayKey.currentState?.show();

  /// Hides the suggestion overlay.
  void hide() => _suggestionOverlayKey.currentState?.hide();

  /// Unhides selected suggestion in suggestion list.
  void resetSelection() => _suggestionListKey.currentState?.resetSelection();

  /// Call when recents is scrolled.
  void onRecentsScrollOffsetChanged(BuildContext context, double scrollOffset) {
    // Peak suggestion overlay more when overscrolling.
    if (scrollOffset < -_kSuggestionOverlayPullScrollOffset &&
        (_suggestionOverlayKey.currentState?.hiding ?? true)) {
      _suggestionOverlayKey.currentState?.setValue(
        SizeModel.of(context).suggestionPeekHeight -
            (scrollOffset + _kSuggestionOverlayPullScrollOffset) *
                _kSuggestionOverlayScrollFactor,
      );
    }
  }

  /// Call when now bar is dragged vertically.
  void onNowBarVerticalDragUpdate(DragUpdateDetails details) =>
      _suggestionOverlayKey.currentState?.onVerticalDragUpdate(details);

  /// Call when now bar vertical drag ends.
  void onNowBarVerticalDragEnd(DragEndDetails details) =>
      _suggestionOverlayKey.currentState?.onVerticalDragEnd(details);

  /// Call when an interruption occurs.
  void onInterruption(Suggestion interruption) {
    _interruptionOverlayKey.currentState?.onInterruptionAdded(interruption);
  }

  void _onSuggestionSelected(
    BuildContext context,
    Suggestion suggestion,
    Rect globalBounds,
    VoidCallback onMinimizeNow,
  ) {
    SuggestionModel.of(context).onSuggestionSelected(suggestion);

    if (suggestion.selectionType == SelectionType.closeSuggestions) {
      hide();
    } else {
      _selectedSuggestionOverlayKey.currentState?.suggestionSelected(
        expansionBehavior: suggestion.selectionType == SelectionType.launchStory
            ? new ExpandSuggestion(
                suggestion: suggestion,
                suggestionInitialGlobalBounds: globalBounds,
              )
            : new SplashSuggestion(
                suggestion: suggestion,
                suggestionInitialGlobalBounds: globalBounds,
              ),
      );
      onMinimizeNow?.call();
    }
  }
}
