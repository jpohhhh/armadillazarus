// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:armadillo/common.dart';
import 'package:armadillo/next.dart';
import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'suggestion.dart';
import 'suggestion_layout.dart';
import 'suggestion_model.dart';
import 'suggestion_widget.dart';

const String _kLogoSmall = 'packages/armadillo/lib/res/logo_googleg_24dpx4.png';
const String _kLogoLarge =
    'packages/armadillo/lib/res/googlelogo_color_62x24dp.png';
const String _kMicImage = 'packages/armadillo/lib/res/googlemic_color_24dp.png';
const Duration _kFadeInDuration = const Duration(milliseconds: 500);

/// The gap between suggestions.
const double _kSuggestionGap = 16.0;

const double _kThreeColumnWidthThreshold =
    kSuggestionWidth * 3 + _kSuggestionGap * 4;
const double _kTwoColumnWidthThreshold =
    kSuggestionWidth * 2 + _kSuggestionGap * 3;
const double _kOneColumnWidthThreshold = kSuggestionWidth + _kSuggestionGap * 2;
const double _kThreeColumnWidth = kSuggestionWidth * 3 + _kSuggestionGap * 2;
const double _kTwoColumnWidth = kSuggestionWidth * 2 + _kSuggestionGap;
const double _kOneColumnWidth = kSuggestionWidth;
const double _kSuggestionListBottomPadding = 32.0;

const ListEquality<Suggestion> _kSuggestionListEquality =
    const ListEquality<Suggestion>();

/// Called when a suggestion is selected.  [globalBounds] indicates the location
/// of the widget representing [suggestion] was on screen when it was selected.
typedef OnSuggestionSelected = void Function(
    Suggestion suggestion, Rect globalBounds);

/// Displays a list of suggestions and provides a mechanism for asking for
/// new things to do.
class SuggestionList extends StatefulWidget {
  /// The controller to use for scrolling the list.
  final ScrollController? scrollController;

  /// Called when the user begins asking.
  final VoidCallback? onAskingStarted;

  /// Called when the user ends asking.
  final VoidCallback? onAskingEnded;

  /// Called when a suggestion is selected.
  final OnSuggestionSelected? onSuggestionSelected;

  /// The [FocusNode] to be used by the ask text field.
  final FocusNode? askFocusNode;

  /// Constructor.
  const SuggestionList({
    Key? key,
    this.scrollController,
    this.onAskingStarted,
    this.onAskingEnded,
    this.onSuggestionSelected,
    this.askFocusNode,
  }) : super(key: key);

  @override
  SuggestionListState createState() => new SuggestionListState();
}

/// Manages the asking state for the [SuggestionList].
class SuggestionListState extends State<SuggestionList>
    with TickerProviderStateMixin {
  final TextEditingController _askTextController = new TextEditingController();
  Suggestion? _selectedSuggestion;
  DateTime? _lastBuildTime;
  late AnimationController _fadeInAnimation;
  late CurvedAnimation _curvedFadeInAnimation;
  VoiceModel? _voiceModel;
  bool _useSpeechInput = false;

  @override
  void initState() {
    super.initState();

    _fadeInAnimation = new AnimationController(
      vsync: this,
      value: 0.0,
      duration: _kFadeInDuration,
    );
    _curvedFadeInAnimation = new CurvedAnimation(
      parent: _fadeInAnimation,
      curve: Curves.fastOutSlowIn,
    );
    _askTextController.addListener(() {
      if (_askTextController.text.isNotEmpty) {
        _startAsking();
      }
    });

    // ARMADILLAZARUS(parity): moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voiceModel?.removeListener(_updateTranscript);
    _voiceModel = VoiceModel.of(context)..addListener(_updateTranscript);
  }

  @override
  void dispose() {
    _voiceModel?.removeListener(_updateTranscript);
    _fadeInAnimation.dispose();
    super.dispose();
  }

  void _startAsking() {
    SuggestionModel.of(context).asking = true;
    widget.onAskingStarted?.call();
  }

  /// Clears the ask text.
  void _clear() {
    _askTextController.clear();
    SuggestionModel.of(context).askText = '';
  }

  void _updateTranscript() {
    if (_voiceModel!.isInput) {
      _useSpeechInput = true;
    }

    if (_useSpeechInput) {
      _askTextController
        ..text = _voiceModel!.transcription
        ..selection = new TextSelection.collapsed(
            offset: _voiceModel!.transcription.length);
      SuggestionModel.of(context).askText = _voiceModel!.transcription;
    }

    // There may (or may not) be a case where voice state transitions from input
    // to passive while transcription settles, so have the _useSpeechinput off
    // switch after the transcription sync.
    if (_voiceModel!.state == VoiceState.passive) {
      _useSpeechInput = false;
    }
  }

  /// Clears the last selected suggestion.  The selected suggestion isn't drawn
  /// in favor of a splash transition drawing it.
  void resetSelection() {
    setState(() {
      _selectedSuggestion = null;
    });
  }

  /// Stops asking and clears the the ask text.
  void stopAsking() {
    _clear();
    SuggestionModel.of(context).asking = false;
    widget.onAskingEnded?.call();
  }

  /// Selects the first suggestion in the list as if it had been tapped.
  void selectFirstSuggestions() {
    List<Suggestion> suggestions = SuggestionModel.of(context).asking
        ? SuggestionModel.of(context).askSuggestions
        : SuggestionModel.of(context).nextSuggestions;
    if (suggestions.isNotEmpty) {
      _onSuggestionSelected(suggestions[0]);
    }
  }

  Widget _buildSuggestionGrid() => new ScopedModelDescendant<SuggestionModel>(
        builder: (
          BuildContext context,
          Widget? child,
          SuggestionModel suggestionModel,
        ) {
          _lastBuildTime = new DateTime.now();
          _fadeInAnimation
            ..value = 0.0
            ..forward();
          List<Suggestion> suggestions = suggestionModel.asking
              ? suggestionModel.askSuggestions
              : suggestionModel.nextSuggestions;
          return new Container(
            color: const Color(0xFFDBE2E5),
            padding: const EdgeInsets.only(top: 32.0),
            child: new CustomScrollView(
              controller: widget.scrollController,
              slivers: <Widget>[
                new SliverGrid(
                  gridDelegate: new _SuggestionListSliverGridDelegate(
                    suggestions: suggestions,
                    textDirection: Directionality.of(context),
                  ),
                  delegate: new SliverChildBuilderDelegate(
                    (BuildContext context, int index) => _createSuggestion(
                      suggestions[index],
                    ),
                    childCount: suggestions.length,
                  ),
                ),
              ],
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) => new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) => new LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  constraints.maxWidth == 0.0
                      ? const Offstage()
                      : new ScopedModelDescendant<SizeModel>(
                          builder: (
                            BuildContext context,
                            Widget? child,
                            SizeModel sizeModel,
                          ) =>
                              new PhysicalModel(
                            elevation: Elevations.suggestionList,
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: const Radius.circular(8.0),
                              topRight: const Radius.circular(8.0),
                            ),
                            child: new Stack(
                              children: <Widget>[
                                // We overlap a little to avoid aliasing issues.
                                new Positioned.fill(
                                  top: sizeModel.askHeight - 8.0,
                                  child: _buildSuggestionGrid(),
                                ),
                                new Positioned(
                                  left: 0.0,
                                  right: 0.0,
                                  top: 0.0,
                                  height: sizeModel.askHeight,
                                  child: new Container(
                                    color: Colors.white,
                                    padding: new EdgeInsets.symmetric(
                                      horizontal: _getLeftOffset(
                                        constraints.maxWidth,
                                      ),
                                    ),
                                    child: _buildAsk(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ],
      );

  Widget _buildAsk(BuildContext context) => new GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startAsking,
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new ScopedModelDescendant<SuggestionModel>(
              builder: (
                BuildContext context,
                Widget? child,
                SuggestionModel suggestionModel,
              ) =>
                  new Image.asset(
                suggestionModel.asking ? _kLogoSmall : _kLogoLarge,
                height: 24.0,
                fit: BoxFit.fitHeight,
              ),
            ),
            new Container(width: 16.0),
            // Ask Anything text field.
            new Expanded(
              child: new ScopedModelDescendant<SuggestionModel>(
                builder: (
                  BuildContext context,
                  Widget? child,
                  SuggestionModel suggestionModel,
                ) =>
                    new Offstage(
                  offstage: !suggestionModel.asking,
                  child: child,
                ),
                child: new Material(
                  color: Colors.transparent,
                  child: new TextField(
                    decoration: const InputDecoration(border: null),
                    style: new TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[600],
                    ),
                    focusNode: widget.askFocusNode,
                    controller: _askTextController,
                    onChanged: (String text) {
                      SuggestionModel.of(context).askText = text;
                    },
                    onSubmitted: (String text) {
                      // Select the first suggestion on text commit (ie.
                      // Pressing enter or tapping 'Go').
                      selectFirstSuggestions();
                    },
                  ),
                ),
              ),
            ),
            new GestureDetector(
              onTap: VoiceModel.of(context).beginSpeechCapture,
              child: new Image.asset(
                _kMicImage,
                height: 24.0,
                fit: BoxFit.fitHeight,
              ),
            ),
          ],
        ),
      );

  void _onSuggestionSelected(Suggestion suggestion) {
    if (_lastBuildTime != null &&
        new DateTime.now().difference(_lastBuildTime!) < _kFadeInDuration) {
      return;
    }
    switch (suggestion.selectionType) {
      case SelectionType.launchStory:
      case SelectionType.modifyStory:
      case SelectionType.closeSuggestions:
        setState(() {
          _selectedSuggestion = suggestion;
        });
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

  Widget _createSuggestion(Suggestion suggestion) => new RepaintBoundary(
        child: new FadeTransition(
          opacity: _curvedFadeInAnimation,
          child: new SuggestionWidget(
            key: suggestion.globalKey,
            visible: _selectedSuggestion?.id != suggestion.id,
            suggestion: suggestion,
            onSelected: () => _onSuggestionSelected(suggestion),
          ),
        ),
      );

  /// Determines the width of a suggestion in the suggestion list.
  static double getSuggestionWidth(double maxWidth) =>
      math.min(kSuggestionWidth, maxWidth - 2 * _kSuggestionGap);

  /// Determines the horizontal margin of suggestions in the suggestion list.
  static double getSuggestionHorizontalMargin() => _kSuggestionGap;
}

class _SuggestionListSliverGridDelegate extends SliverGridDelegate {
  final List<Suggestion> suggestions;
  final TextDirection textDirection;

  _SuggestionListSliverGridDelegate(
      {required this.suggestions, required this.textDirection});

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) =>
      new _SuggestionListSliverGridLayout(
        suggestions: suggestions,
        width: constraints.crossAxisExtent,
        textDirection: textDirection,
      );

  @override
  bool shouldRelayout(_SuggestionListSliverGridDelegate oldDelegate) =>
      !_kSuggestionListEquality.equals(suggestions, oldDelegate.suggestions);
}

class _SuggestionListSliverGridLayout extends SliverGridLayout {
  final List<Suggestion> suggestions;
  final double width;
  final TextDirection textDirection;

  const _SuggestionListSliverGridLayout({
    required this.suggestions,
    required this.width,
    required this.textDirection,
  });

  /// The minimum child index that is visible at (or after) this scroll offset.
  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) =>
      suggestions.isEmpty ? -1 : 0;

  /// The maximum child index that is visible at (or before) this scroll offset.
  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) =>
      suggestions.isEmpty ? -1 : suggestions.length - 1;

  /// The size and position of the child with the given index.
  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    if (index < 0 || index >= suggestions.length) {
      return const SliverGridGeometry(
        scrollOffset: 0.0,
        crossAxisOffset: 0.0,
        mainAxisExtent: 0.0,
        crossAxisExtent: 0.0,
      );
    }
    int columnCount = _getColumnCount(width);
    double leftOffset = _getLeftOffset(width);
    double crossAxisExtent = width >= kSuggestionWidth + 2 * _kSuggestionGap
        ? kSuggestionWidth
        : width - 2 * _kSuggestionGap;
    double crossAxisOffset = (columnCount == 1)
        ? leftOffset
        : (columnCount == 2 && ((index % 2) == 0))
            ? leftOffset
            : (columnCount == 2 && ((index % 2) == 1))
                ? leftOffset + _kSuggestionGap + kSuggestionWidth
                : ((index % 3) == 0)
                    ? leftOffset
                    : ((index % 3) == 1)
                        ? leftOffset + _kSuggestionGap + kSuggestionWidth
                        : leftOffset +
                            _kSuggestionGap * 2 +
                            kSuggestionWidth * 2;
    suggestions[index].suggestionLayout.layout(width, textDirection);
    double mainAxisExtent =
        suggestions[index].suggestionLayout.suggestionHeight;
    double scrollOffset = 0.0;
    for (int i = index - columnCount; i >= 0; i -= columnCount) {
      scrollOffset += _kSuggestionGap;
      suggestions[i].suggestionLayout.layout(width, textDirection);
      scrollOffset += suggestions[i].suggestionLayout.suggestionHeight;
    }
    return new SliverGridGeometry(
      scrollOffset: scrollOffset,
      crossAxisOffset: crossAxisOffset,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: math.max(0.0, crossAxisExtent),
    );
  }

  /// An estimate of the scroll extent needed to fully display all the tiles if
  /// there are `childCount` children in total.
  @override
  double computeMaxScrollOffset(int childCount) {
    int columnCount = _getColumnCount(width);
    double maxScrollOffset = 0.0;
    for (int i = 0; i < math.min(childCount, columnCount); i++) {
      SliverGridGeometry geometry =
          getGeometryForChildIndex(childCount - 1 - i);
      maxScrollOffset = math.max(
        maxScrollOffset,
        geometry.scrollOffset +
            geometry.mainAxisExtent +
            _kSuggestionListBottomPadding,
      );
    }
    return maxScrollOffset;
  }
}

double _getLeftOffset(double width) => width >= _kThreeColumnWidthThreshold
    ? (width - _kThreeColumnWidth) / 2.0
    : width >= _kTwoColumnWidthThreshold
        ? (width - _kTwoColumnWidth) / 2.0
        : width >= _kOneColumnWidthThreshold
            ? (width - _kOneColumnWidth) / 2.0
            : _kSuggestionGap;

int _getColumnCount(double width) => width >= _kThreeColumnWidthThreshold
    ? 3
    : width >= _kTwoColumnWidthThreshold
        ? 2
        : 1;
