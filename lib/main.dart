import 'dart:math' as math;

import 'package:armadillo/common.dart';
import 'package:armadillo/next.dart';
import 'package:armadillo/now.dart';
import 'package:armadillo/overview.dart';
import 'package:armadillo/recent.dart';
import 'package:armadillo/src/now/power_model.dart';
import 'package:armadillo/src/now/volume_model.dart';
import 'package:armadillo/src/next/voice_model.dart';
import 'package:armadillo/src/recent/display_mode.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import 'demo_suggestion_model.dart';

void main() {
  runApp(const ArmadillazarusApp());
}

class ArmadillazarusApp extends StatelessWidget {
  const ArmadillazarusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Armadillazarus',
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!,
        child: const _ArmadilloHost(),
      ),
    );
  }
}

class _ArmadilloHost extends StatefulWidget {
  const _ArmadilloHost();

  @override
  State<_ArmadilloHost> createState() => _ArmadilloHostState();
}

class _ArmadilloHostState extends State<_ArmadilloHost> {
  final _storyModel = _RichStoryModel();
  final _sizeModel = SizeModel();
  final _conductorModel = ConductorModel();
  final _peekModel = PeekModel();
  final _quickSettingsModel = QuickSettingsProgressModel();
  final _contextModel = _DummyContextModel();
  final _suggestionModel = DemoSuggestionModel();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    if (mq.size != Size.zero) {
      _sizeModel.screenSize = mq.size;
      _storyModel.updateLayouts(mq.size);
    }
    _suggestionModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<DebugModel>(
      model: DebugModel(),
      child: ScopedModel<SizeModel>(
        model: _sizeModel,
        child: ScopedModel<StoryModel>(
          model: _storyModel,
          child: ScopedModel<ConductorModel>(
            model: _conductorModel,
            child: ScopedModel<PeekModel>(
              model: _peekModel,
              child: ScopedModel<QuickSettingsProgressModel>(
                model: _quickSettingsModel,
                child: ScopedModel<ContextModel>(
                  model: _contextModel,
                  child: ScopedModel<SuggestionModel>(
                    model: _suggestionModel,
                    child: ScopedModel<PanelResizingModel>(
                      model: PanelResizingModel(),
                      child: ScopedModel<StoryClusterDragStateModel>(
                        model: StoryClusterDragStateModel(),
                        child: ScopedModel<StoryRearrangementScrimModel>(
                          model: StoryRearrangementScrimModel(),
                          child: ScopedModel<StoryDragTransitionModel>(
                            model: StoryDragTransitionModel(),
                            child: ScopedModel<PowerModel>(
                              model: PowerModel(),
                              child: ScopedModel<VolumeModel>(
                                model: VolumeModel(),
                                child: ScopedModel<VoiceModel>(
                                  model: VoiceModel(),
                                  child: Armadillo(
                                    scopedModelBuilders: const [],
                                    conductor: Conductor(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rich story data stolen from the original test suite ─────────────

const _kStoryNames = [
  'Launch Week',
  'Checkout Incident',
  'Metrics Dashboard',
  'Inbox Triage',
  'Customer Escalations',
  'Deploy Pipeline',
  'Code Review',
  'Architecture RFC',
  'Sprint Planning',
  'Team Standup',
  'Bug Bash',
  'Design Critique',
  'Quarterly Review',
  'Onboarding Doc',
  'API Migration',
  'Security Audit',
  'Performance Tuning',
  'Release Notes',
  'Retrospective',
  'Roadmap Update',
  'Hiring Pipeline',
  'Vendor Eval',
  'Budget Review',
  'Offsite Planning',
];

const _kColors = [
  Color(0xFF355C7D),
  Color(0xFFC06C84),
  Color(0xFF6C5B7B),
  Color(0xFFF67280),
  Color(0xFF99B898),
  Color(0xFFFECEAB),
  Color(0xFFFF847C),
  Color(0xFFE84A5F),
  Color(0xFF2A363B),
  Color(0xFFA8E6CE),
  Color(0xFFDCEDC2),
  Color(0xFFFFD3B5),
  Color(0xFFFF8C94),
  Color(0xFF3B8686),
  Color(0xFF79BD9A),
  Color(0xFFA8DBA8),
  Color(0xFFCFF09E),
  Color(0xFF547980),
  Color(0xFF45ADA8),
  Color(0xFF9DE0AD),
  Color(0xFFE5FCC2),
  Color(0xFF594F4F),
  Color(0xFF9E9E9E),
  Color(0xFFE0B0FF),
];

// Time distributions from the original test suite — realistic juggling pattern
final _kInteractionTimes = [
  Duration.zero,
  const Duration(minutes: 7),
  const Duration(minutes: 41),
  const Duration(minutes: 65),
  const Duration(minutes: 89),
  const Duration(minutes: 107),
  const Duration(minutes: 108),
  const Duration(minutes: 152),
  const Duration(minutes: 198),
  const Duration(minutes: 207),
  const Duration(minutes: 213),
  const Duration(minutes: 241),
  const Duration(minutes: 272),
  const Duration(minutes: 273),
  const Duration(minutes: 276),
  const Duration(minutes: 296),
  const Duration(minutes: 324),
  const Duration(minutes: 327),
  const Duration(minutes: 369),
  const Duration(minutes: 387),
  const Duration(minutes: 403),
  const Duration(minutes: 420),
  const Duration(minutes: 446),
  const Duration(minutes: 475),
];

final _kCumulativeDurations = [
  const Duration(minutes: 7),
  const Duration(minutes: 34),
  const Duration(minutes: 24),
  const Duration(minutes: 24),
  const Duration(minutes: 18),
  const Duration(minutes: 1),
  const Duration(minutes: 29),
  const Duration(minutes: 20),
  const Duration(minutes: 9),
  const Duration(minutes: 6),
  const Duration(minutes: 28),
  const Duration(minutes: 26),
  const Duration(minutes: 1),
  const Duration(minutes: 3),
  const Duration(minutes: 20),
  const Duration(minutes: 28),
  const Duration(minutes: 3),
  const Duration(minutes: 18),
  const Duration(minutes: 18),
  const Duration(minutes: 16),
  const Duration(minutes: 17),
  const Duration(minutes: 26),
  const Duration(minutes: 29),
  const Duration(minutes: 8),
];

class _RichStoryModel extends StoryModel {
  _RichStoryModel() : super() {
    final now = DateTime.now();
    final clusters = <StoryCluster>[];

    for (int i = 0; i < _kStoryNames.length; i++) {
      final color = _kColors[i % _kColors.length];
      final story = Story(
        id: StoryId('story-$i'),
        title: _kStoryNames[i],
        lastInteraction: now.subtract(_kInteractionTimes[i]),
        cumulativeInteractionDuration: _kCumulativeDurations[i],
        themeColor: color,
        widget: _StoryContent(title: _kStoryNames[i], color: color),
      );

      final cluster = StoryCluster(
        stories: [story],
        onStoryClusterChanged: () => notifyListeners(),
      );
      cluster
        ..lastInteraction = now.subtract(_kInteractionTimes[i])
        ..cumulativeInteractionDuration = _kCumulativeDurations[i]
        ..displayMode = DisplayMode.tabs
        ..focusedStoryId = story.id;

      clusters.add(cluster);
    }

    // Make one multi-story cluster (panels side by side)
    final panelCluster = StoryCluster(
      stories: [
        Story(
          id: const StoryId('panel-left'),
          title: 'Incident Commander',
          lastInteraction: now.subtract(const Duration(minutes: 30)),
          cumulativeInteractionDuration: const Duration(minutes: 45),
          themeColor: const Color(0xFFE84A5F),
          widget: const _StoryContent(
            title: 'Incident Commander',
            color: Color(0xFFE84A5F),
          ),
          panel: Panel(origin: FractionalOffset.topLeft, widthFactor: 0.5),
        ),
        Story(
          id: const StoryId('panel-right'),
          title: 'Live Metrics',
          lastInteraction: now.subtract(const Duration(minutes: 30)),
          cumulativeInteractionDuration: const Duration(minutes: 45),
          themeColor: const Color(0xFF2A363B),
          widget: const _StoryContent(
            title: 'Live Metrics',
            color: Color(0xFF2A363B),
          ),
          panel: Panel(
            origin: const FractionalOffset(0.5, 0.0),
            widthFactor: 0.5,
          ),
        ),
      ],
      onStoryClusterChanged: () => notifyListeners(),
    );
    panelCluster
      ..lastInteraction = now.subtract(const Duration(minutes: 30))
      ..cumulativeInteractionDuration = const Duration(minutes: 45)
      ..displayMode = DisplayMode.panels
      ..focusedStoryId = const StoryId('panel-left');

    clusters.insert(1, panelCluster); // Put it near the top

    onStoryClustersChanged(clusters);
  }
}

// ── Stub models ─────────────────────────────────────────────────────

class _DummyContextModel extends ContextModel {
  @override
  String? get userName => 'Armadillazarus';
  @override
  String? get userImageUrl => null;
  @override
  DateTime? get buildTimestamp => DateTime.now();
  @override
  DeviceMode get deviceMode => DeviceMode.normal;

  @override
  String get timeOnly {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  String get meridiem => DateTime.now().hour >= 12 ? 'PM' : 'AM';

  @override
  String get dateOnly {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // backgroundImageProvider inherited from ContextModel — uses the
  // vendored Background.jpg automatically.
}

// _DummySuggestionModel replaced by DemoSuggestionModel in demo_suggestion_model.dart

class _StoryContent extends StatelessWidget {
  const _StoryContent({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      alignment: Alignment.bottomLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
