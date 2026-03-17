// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/common.dart';
import 'package:armadillo/overview.dart';
import 'package:armadillo/recent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

const double _kWidthSingleColumn = 500.0;
const double _kWidthMultiColumn = 700.0;
const double _kHeight = 600.0;

void main() {
  testWidgets('Single Column StoryList children extend to fit parent',
      (WidgetTester tester) async {
    GlobalKey storyListKey = new GlobalKey();
    ScrollController scrollController = new ScrollController();

    List<GlobalKey> storyKeys =
        new List<GlobalKey>.generate(4, (int index) => new GlobalKey());

    StoryList storyList = new StoryList(
      key: storyListKey,
      overlayKey: new GlobalKey(),
      scrollController: scrollController,
    );
    StoryModel storyModel = new _DummyStoryModel(storyKeys: storyKeys);
    await tester.pumpWidget(
      _wrapWithModels(
        storyModel: storyModel,
        child: new Center(
          child: new SizedBox(
            width: _kWidthSingleColumn,
            height: _kHeight,
            child: storyList,
          ),
        ),
      ),
    );
    expect(find.byKey(storyListKey), isNotNull);
    expect(tester.getSize(find.byKey(storyListKey)).width, _kWidthSingleColumn);
    for (GlobalKey key in storyKeys) {
      final Finder finder = find.byKey(key);
      expect(finder, isNotNull);
      final Size size = tester.getSize(finder);
      expect(size.width, _kWidthSingleColumn);
    }
  });

  testWidgets(
      'Multicolumn StoryList children do not extend to fit parent and are instead 16/9 aspect ratio',
      (WidgetTester tester) async {
    GlobalKey storyListKey = new GlobalKey();
    ScrollController scrollController = new ScrollController();

    List<GlobalKey> storyKeys =
        new List<GlobalKey>.generate(4, (int index) => new GlobalKey());

    StoryList storyList = new StoryList(
      key: storyListKey,
      overlayKey: new GlobalKey(),
      scrollController: scrollController,
    );
    StoryModel storyModel = new _DummyStoryModel(storyKeys: storyKeys);

    await tester.pumpWidget(
      _wrapWithModels(
        storyModel: storyModel,
        child: new Center(
          child: new SizedBox(
            width: _kWidthMultiColumn,
            height: _kHeight,
            child: storyList,
          ),
        ),
      ),
    );
    expect(find.byKey(storyListKey), isNotNull);
    expect(tester.getSize(find.byKey(storyListKey)).width, _kWidthMultiColumn);
    for (GlobalKey key in storyKeys) {
      final Finder finder = find.byKey(key);
      expect(finder, isNotNull);
      final Size size = tester.getSize(finder);
      expect(size.width, _kWidthMultiColumn);
      expect(size.height, _kHeight - SizeModel.kStoryBarMaximizedHeight);
    }
  });
}

class _DummyStoryModel extends StoryModel {
  final List<GlobalKey> storyKeys;

  _DummyStoryModel({this.storyKeys});

  @override
  List<StoryCluster> get storyClusters => new List<StoryCluster>.generate(
        storyKeys.length,
        (int index) => new StoryCluster(
          stories: <Story>[
            new Story(
              id: new StoryId('${storyKeys[index]}'),
              widget: new Container(key: storyKeys[index]),
              title: '',
              lastInteraction: new DateTime.now(),
              cumulativeInteractionDuration: const Duration(minutes: 5),
              themeColor: const Color(0xFFFFFFFF),
            ),
          ],
          storyLayout: new _DummyStoryLayout(),
        ),
      );
}

class _DummyStoryLayout extends StoryLayout {
  @override
  Size get size => const Size(200.0, 200.0);

  @override
  Offset get offset => Offset.zero;

  @override
  Rect get bounds => offset & size;
}

Widget _wrapWithModels({Widget child, StoryModel storyModel}) =>
    new ScopedModel<DebugModel>(
      model: new DebugModel(),
      child: new ScopedModel<PanelResizingModel>(
        model: new PanelResizingModel(),
        child: new ScopedModel<StoryModel>(
          model: storyModel,
          child: new ScopedModel<StoryClusterDragStateModel>(
            model: new StoryClusterDragStateModel(),
            child: new ScopedModel<StoryRearrangementScrimModel>(
              model: new StoryRearrangementScrimModel(),
              child: new ScopedModel<StoryDragTransitionModel>(
                model: new StoryDragTransitionModel(),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
