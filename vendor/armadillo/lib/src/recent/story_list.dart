// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:armadillo/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'armadillo_drag_target.dart';
import 'armadillo_overlay.dart';
import 'focus_model.dart';
import 'render_story_list_body.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_data.dart';
import 'story_cluster_entrance_transition_model.dart';
import 'story_cluster_widget.dart';
import 'story_drag_transition_model.dart';
import 'story_list_body_parent_data.dart';
import 'story_list_layout.dart';
import 'story_model.dart';
import 'story_rearrangement_scrim_model.dart';

/// Displays the [StoryCluster]s of it's ancestor [StoryModel].
class StoryList extends StatelessWidget {
  /// Called when the story list scrolls.
  final ValueChanged<double>? onScroll;

  /// Controls the scrolling of this list.
  final ScrollController scrollController;

  /// The overlay dragged stories should place their avatars when dragging.
  final GlobalKey<ArmadilloOverlayState> overlayKey;

  /// Called when a cluster is dragged to the top or bottom of the screen for
  /// a certain length of time.
  final VoidCallback? onStoryClusterVerticalEdgeHover;

  /// Constructor.
  const StoryList({
    Key? key,
    required this.scrollController,
    required this.overlayKey,
    this.onScroll,
    this.onStoryClusterVerticalEdgeHover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => new ScopedModelDescendant<StoryModel>(
        builder: (
          BuildContext context,
          Widget? child,
          StoryModel storyModel,
        ) {
          return new ScopedModelDescendant<SizeModel>(
            builder: (
              BuildContext context,
              Widget? child,
              SizeModel sizeModel,
            ) {
              return new Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  _createScrollableList(storyModel, sizeModel),
                  new Positioned(
                    left: 0.0,
                    top: 0.0,
                    bottom: 0.0,
                    width: 108.0,
                    child: _buildDiscardDragTarget(
                      storyModel: storyModel,
                      controller: new AnimationController(
                        vsync: new _TickerProvider(),
                        duration: const Duration(milliseconds: 200),
                      ),
                    ),
                  ),
                  new Positioned(
                    right: 0.0,
                    top: 0.0,
                    bottom: 0.0,
                    width: 108.0,
                    child: _buildDiscardDragTarget(
                      storyModel: storyModel,
                      controller: new AnimationController(
                        vsync: new _TickerProvider(),
                        duration: const Duration(milliseconds: 200),
                      ),
                    ),
                  ),
                  new ArmadilloOverlay(key: overlayKey),
                ],
              );
            },
          );
        },
      );

  Widget _createScrollableList(StoryModel storyModel, SizeModel sizeModel) =>
      new NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification &&
              notification.depth == 0) {
            onScroll?.call(notification.metrics.extentBefore);
          }
          return false;
        },
        child: new SingleChildScrollView(
          padding: new EdgeInsets.only(top: sizeModel.storyListTopPadding),
          reverse: true,
          controller: scrollController,
          child: new ScopedModelDescendant<SizeModel>(
            builder: (_, __, SizeModel sizeModel) =>
                new ScopedModelDescendant<StoryRearrangementScrimModel>(
              builder: (
                _,
                __,
                StoryRearrangementScrimModel storyRearrangementScrimModel,
              ) =>
                  new ScopedModelDescendant<StoryDragTransitionModel>(
                builder: (
                  BuildContext context,
                  _,
                  StoryDragTransitionModel storyDragTransitionModel,
                ) =>
                    new AnimatedBuilder(
                  animation: scrollController,
                  builder: (BuildContext context, Widget? child) =>
                      new _StoryListBody(
                    children: _toWidgets(context, storyModel),
                    listHeight: storyModel.listHeight,
                    scrollOffset: scrollController.offset,
                    bottomPadding: sizeModel.maximizedNowHeight,
                    // When we are dragging, the storyListSize
                    // takes up the entire screen since the now
                    // bar is hidden.
                    parentSize: new Size(
                      sizeModel.storySize.width,
                      sizeModel.storySize.height +
                          lerpDouble(
                            0.0,
                            sizeModel.minimizedNowHeight,
                            storyDragTransitionModel.value,
                          )!,
                    ),
                    storyDragTransitionModelProgress:
                        storyDragTransitionModel.value,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  List<Widget> _toWidgets(BuildContext context, StoryModel storyModel) =>
      storyModel.toWidgets((StoryCluster storyCluster) {
        return _createFocusableStoryCluster(
          context,
          storyModel,
          storyCluster,
        );
      });

  Widget _createFocusableStoryCluster(
    BuildContext context,
    StoryModel storyModel,
    StoryCluster storyCluster,
  ) =>
      _wrapWithModels(
        storyCluster,
        (BuildContext context) => new _StoryListChild(
          key: ValueKey(storyCluster.id),
          storyLayout: storyCluster.storyLayout!,
          focusProgress: storyCluster.focusModel.value,
          inlinePreviewScaleProgress:
              storyCluster.inlinePreviewScaleModel.value,
          inlinePreviewHintScaleProgress:
              storyCluster.inlinePreviewHintScaleModel.value,
          entranceTransitionProgress:
              storyCluster.storyClusterEntranceTransitionModel.value,
          child: _createStoryCluster(
            storyModel,
            storyCluster,
          ),
        ),
      );

  Widget _wrapWithModels(StoryCluster storyCluster, WidgetBuilder builder) =>
      new ScopedModel<StoryClusterEntranceTransitionModel>(
        model: storyCluster.storyClusterEntranceTransitionModel,
        child: new ScopedModelDescendant<StoryClusterEntranceTransitionModel>(
          builder: (_, __, ___) => new ScopedModel<InlinePreviewScaleModel>(
            model: storyCluster.inlinePreviewScaleModel,
            child: new ScopedModelDescendant<InlinePreviewScaleModel>(
              builder: (_, __, ___) =>
                  new ScopedModel<InlinePreviewHintScaleModel>(
                model: storyCluster.inlinePreviewHintScaleModel,
                child: new ScopedModelDescendant<InlinePreviewHintScaleModel>(
                  builder: (_, __, ___) => new ScopedModel<FocusModel>(
                    model: storyCluster.focusModel,
                    child: new ScopedModelDescendant<FocusModel>(
                      builder: (BuildContext context, __, ___) =>
                          builder(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _createStoryCluster(
    StoryModel storyModel,
    StoryCluster storyCluster,
  ) =>
      new RepaintBoundary(
        child: new StoryClusterWidget(
          overlayKey: overlayKey,
          storyCluster: storyCluster,
          onAccept: () {
            if (!_inFocus(storyCluster)) {
              _onGainFocus(storyModel, storyCluster);
            }
          },
          onTap: () => _onGainFocus(storyModel, storyCluster),
          onVerticalEdgeHover: onStoryClusterVerticalEdgeHover ?? () {},
        ),
      );

  bool _inFocus(StoryCluster s) => s.focusModel.value > 0.0;

  void _onGainFocus(
    StoryModel storyModel,
    StoryCluster storyCluster,
  ) {
    // Defocus any focused stories.
    storyModel.unfocusAll();

    // Bring tapped story into focus.
    storyCluster.focusModel.target = 1.0;

    storyCluster.maximizeStoryBars();
  }

  Widget _buildDiscardDragTarget({
    required StoryModel storyModel,
    required AnimationController controller,
  }) {
    CurvedAnimation curve = new CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    bool wasEmpty = true;
    return new ArmadilloDragTarget<StoryClusterDragData>(
      onWillAccept: (_, __) => storyModel.allUnfocused,
      onAccept: (StoryClusterDragData data, _, __) {
        storyModel.delete(storyModel.getStoryCluster(data.id));
        controller.reverse();
      },
      builder: (_, Map<StoryClusterDragData, Offset> candidateData, __) {
        if (candidateData.isEmpty && !wasEmpty) {
          controller.reverse();
        } else if (candidateData.isNotEmpty && wasEmpty) {
          controller.forward();
        }
        wasEmpty = candidateData.isEmpty;

        return new IgnorePointer(
          child: new AnimatedBuilder(
            animation: curve,
            builder: (BuildContext context, Widget? child) => new Container(
              color: Color.lerp(
                Colors.transparent,
                Colors.black12,
                curve.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => new Ticker(onTick);
}

// ARMADILLAZARUS(parity): Modern Flutter's MultiChildRenderObjectElement uses
// a `late` field for _children. When GlobalKey-ed children are stolen between
// two _StoryListBody instances during animation rebuilds, forgetChild is called
// on the old element before _children is initialized, causing a LateInitError.
// This custom element guards against that.
class _SafeMultiChildElement extends MultiChildRenderObjectElement {
  _SafeMultiChildElement(super.widget);
  bool _childrenInitialized = false;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _childrenInitialized = true;
  }

  @override
  void forgetChild(Element child) {
    if (!_childrenInitialized) return;
    super.forgetChild(child);
  }
}

class _StoryListBody extends MultiChildRenderObjectWidget {
  @override
  _SafeMultiChildElement createElement() => _SafeMultiChildElement(this);

  final double _scrollOffset;
  final double _bottomPadding;
  final double _listHeight;
  final Size _parentSize;
  final double _storyDragTransitionModelProgress;

  /// Constructor.
  _StoryListBody({
    Key? key,
    required List<Widget> children,
    required double scrollOffset,
    required double bottomPadding,
    required double listHeight,
    required Size parentSize,
    required double storyDragTransitionModelProgress,
  })  : _scrollOffset = scrollOffset,
        _bottomPadding = bottomPadding,
        _listHeight = listHeight,
        _parentSize = parentSize,
        _storyDragTransitionModelProgress = storyDragTransitionModelProgress,
        super(key: key, children: children);

  @override
  RenderStoryListBody createRenderObject(BuildContext context) =>
      new RenderStoryListBody(
        children: [],
        parentSize: _parentSize,
        scrollOffset: _scrollOffset,
        bottomPadding: _bottomPadding,
        listHeight: _listHeight,
        liftScale: lerpDouble(
          1.0,
          0.9,
          _storyDragTransitionModelProgress,
        )!,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderStoryListBody renderObject,
  ) {
    renderObject
      ..axisDirection = AxisDirection.down
      ..parentSize = _parentSize
      ..scrollOffset = _scrollOffset
      ..bottomPadding = _bottomPadding
      ..listHeight = _listHeight
      ..liftScale = lerpDouble(
        1.0,
        0.9,
        _storyDragTransitionModelProgress,
      )!;
  }
}

class _StoryListChild extends ParentDataWidget<StoryListBodyParentData> {
  final StoryLayout _storyLayout;
  final double _focusProgress;
  final double _inlinePreviewScaleProgress;
  final double _inlinePreviewHintScaleProgress;
  final double _entranceTransitionProgress;

  const _StoryListChild({
    super.key,
    required Widget child,
    required StoryLayout storyLayout,
    required double focusProgress,
    required double inlinePreviewScaleProgress,
    required double inlinePreviewHintScaleProgress,
    required double entranceTransitionProgress,
  })  : _storyLayout = storyLayout,
        _focusProgress = focusProgress,
        _inlinePreviewScaleProgress = inlinePreviewScaleProgress,
        _inlinePreviewHintScaleProgress = inlinePreviewHintScaleProgress,
        _entranceTransitionProgress = entranceTransitionProgress,
        super(child: child ?? const SizedBox.shrink());

  @override
  Type get debugTypicalAncestorWidgetClass => _StoryListBody;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StoryListBodyParentData);
    final parentData = renderObject.parentData as StoryListBodyParentData;
    final needsLayout = parentData.storyLayout != _storyLayout ||
        parentData.focusProgress != _focusProgress ||
        parentData.inlinePreviewScaleProgress != _inlinePreviewScaleProgress ||
        parentData.inlinePreviewHintScaleProgress !=
            _inlinePreviewHintScaleProgress ||
        parentData.entranceTransitionProgress != _entranceTransitionProgress;
    _setParentData(parentData);
    if (needsLayout) {
      final parent = renderObject.parent;
      if (parent is RenderObject) {
        parent.markNeedsLayout();
      }
    }
  }

  void _setParentData(StoryListBodyParentData parentData) {
    parentData
      ..storyLayout = _storyLayout
      ..focusProgress = _focusProgress
      ..inlinePreviewScaleProgress = _inlinePreviewScaleProgress
      ..inlinePreviewHintScaleProgress = _inlinePreviewHintScaleProgress
      ..entranceTransitionProgress = _entranceTransitionProgress;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description
      ..add(
        new DiagnosticsProperty<StoryLayout>(
          'storyLayout',
          _storyLayout,
        ),
      )
      ..add(
        new DoubleProperty(
          'focusProgress',
          _focusProgress,
        ),
      )
      ..add(
        new DoubleProperty(
          'inlinePreviewScaleProgress',
          _inlinePreviewScaleProgress,
        ),
      )
      ..add(
        new DoubleProperty(
          'inlinePreviewHintScaleProgress',
          _inlinePreviewHintScaleProgress,
        ),
      )
      ..add(
        new DoubleProperty(
          'entranceTransitionProgress',
          _entranceTransitionProgress,
        ),
      );
  }
}
