// ARMADILLAZARUS: Demo suggestion model seeded from the original
// home_work_agent ask_proposals.json and contextual_location_proposals.json.

import 'dart:typed_data';

import 'package:armadillo/next.dart';
import 'package:armadillo/recent.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Remaps old Fuchsia `/system/data/sysui/X` paths to our vendored assets.
String _assetPath(String? fuchsiaPath) {
  if (fuchsiaPath == null || fuchsiaPath.isEmpty) return '';
  final filename = fuchsiaPath.split('/').last;
  return 'packages/armadillo/lib/res/demo/$filename';
}

/// Loads an asset image as bytes, returning null on failure.
Future<Uint8List?> _loadImageBytes(String assetPath) async {
  if (assetPath.isEmpty) return null;
  try {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// A suggestion model seeded with the original Armadillo demo data.
class DemoSuggestionModel extends SuggestionModel {
  String _askText = '';
  bool _asking = false;

  List<Suggestion> _nextSuggestions = [];
  List<Suggestion> _askSuggestions = [];

  bool _loaded = false;

  /// Call this once a BuildContext with DefaultAssetBundle is available.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    // "Next" suggestions = contextual (unknown + work)
    _nextSuggestions = await _buildSuggestions([
      // unknown context
      _P(
        id: 'unknown_01',
        headline: "It's Danielle's Birthday",
        color: 0xFFFF8F00,
        imageUrl: '/system/data/sysui/danielle_cc0.jpg',
        imageType: ImageType.person,
      ),
      _P(
        id: 'unknown_02',
        headline: '17 min drive to Calafia',
        color: 0xFF4054B2,
        imageUrl: '/system/data/sysui/cc0_calafia.jpg',
      ),
      _P(
        id: 'unknown_03',
        headline: 'Play Good Vibes Playlist',
        color: 0xFF4054B2,
        imageUrl: '/system/data/sysui/cc0_music.jpg',
      ),
      _P(
        id: 'unknown_04',
        headline: 'Launch Fuchsia Dashboard',
        color: 0xFFFF0080,
      ),
      // work context
      _P(
        id: 'work_01',
        headline: 'View Expenses',
        subheadline: 'Your June report has been approved',
        color: 0xFF0887A5,
        iconUrl: '/system/data/sysui/expenses_96.png',
      ),
      _P(
        id: 'work_02',
        headline: "Simon shared 'Toe the Line Analytics' with you",
        color: 0xFFF6B500,
        imageUrl: '/system/data/sysui/simon_96.jpg',
        imageType: ImageType.person,
      ),
      _P(
        id: 'work_03',
        headline: 'Flux Weekly Sync starts in 25 minutes',
        color: 0xFF4285F4,
        iconUrl: '/system/data/sysui/calendar.png',
      ),
      // home context
      _P(
        id: 'home_01',
        headline: 'See movies playing near me',
        color: 0xFFA52714,
        iconUrl: '/system/data/sysui/cinefilm_96.png',
      ),
      _P(
        id: 'home_02',
        headline: 'New Episode for Three Peaks available',
        color: 0xFF827717,
        imageUrl: '/system/data/sysui/threepeaks.png',
      ),
      _P(
        id: 'home_04',
        headline: 'Continue reading OverThrough Magazine',
        subheadline:
            'Finding peace in drawing. 10 easy lessons to start meditating with a pen in your hands.',
        color: 0xFFFF8A65,
        imageUrl: '/system/data/sysui/drawing.jpeg',
      ),
    ]);

    // "Ask" suggestions = the original ask_proposals
    _askSuggestions = await _buildSuggestions([
      _P(
        id: 'ask_01',
        headline: "Read NatureSense's June Newsletter",
        subheadline: 'Read now',
        color: 0xFF64944E,
        imageUrl: '/system/data/sysui/panda.png.jpg',
      ),
      _P(
        id: 'ask_02',
        headline: 'Review your saved recipe',
        color: 0xFF880E4F,
        imageUrl: '/system/data/sysui/pavlova.jpg',
      ),
      _P(
        id: 'ask_03',
        headline: 'Shamra release new album',
        subheadline: 'Read more',
        color: 0xFF423227,
        imageUrl: '/system/data/sysui/shamra.jpg',
      ),
      _P(
        id: 'ask_04',
        headline: 'Read about Google I/O 2017',
        color: 0xFF4285F4,
        iconUrl: '/system/data/sysui/slides.png',
      ),
      _P(
        id: 'ask_05',
        headline: 'Miguel added 5 photos to Flux Memories',
        subheadline: 'View photos',
        color: 0xFF4285F4,
        iconUrl: '/system/data/sysui/google_photos.png',
      ),
      _P(
        id: 'ask_07',
        headline: 'Reply to Danielle',
        color: 0xFF9C26B0,
        imageUrl: '/system/data/sysui/danielle_cc0.jpg',
        imageType: ImageType.person,
      ),
      _P(
        id: 'ask_10',
        headline: 'View hotel confirmation',
        color: 0xFFE64A19,
        imageUrl: '/system/data/sysui/9-hotel.jpg',
      ),
      _P(
        id: 'ask_11',
        headline: 'Scroll through an infinite list',
        subheadline: 'Launch now',
        color: 0xFF5D4037,
        iconUrl: '/system/data/sysui/ic_stat_3_googblue_2x_web_24dp.png',
      ),
      _P(
        id: 'ask_12',
        headline: 'Email',
        subheadline: 'Read now',
        color: 0xFF4285F4,
        iconUrl: '/system/data/sysui/docs.png',
      ),
    ]);

    notifyListeners();
  }

  Future<List<Suggestion>> _buildSuggestions(List<_P> proposals) async {
    final suggestions = <Suggestion>[];
    for (int i = 0; i < proposals.length; i++) {
      final p = proposals[i];

      // Load image bytes
      EncodedImage? mainImage;
      if (p.imageUrl != null) {
        final bytes = await _loadImageBytes(_assetPath(p.imageUrl));
        if (bytes != null) mainImage = EncodedImage(data: bytes);
      }

      // Load icon bytes
      final icons = <EncodedImage>[];
      if (p.iconUrl != null) {
        final bytes = await _loadImageBytes(_assetPath(p.iconUrl));
        if (bytes != null) icons.add(EncodedImage(data: bytes));
      }

      suggestions.add(
        Suggestion(
          id: SuggestionId(p.id),
          title: p.headline,
          description: p.subheadline ?? '',
          themeColor: Color(p.color),
          selectionType: SelectionType.closeSuggestions,
          selectionStoryId: StoryId(p.id),
          image: mainImage,
          imageType: p.imageType,
          icons: icons,
          confidence: 1.0 - (i * 0.05), // decreasing confidence for ordering
        ),
      );
    }
    return suggestions;
  }

  @override
  set askText(String? text) {
    _askText = text ?? '';
    notifyListeners();
  }

  @override
  String get askText => _askText;

  @override
  set asking(bool value) {
    _asking = value;
    notifyListeners();
  }

  @override
  bool get asking => _asking;

  @override
  bool get processingAsk => false;

  @override
  bool get processingNext => false;

  @override
  List<Suggestion> get askSuggestions => _askSuggestions;

  @override
  List<Suggestion> get nextSuggestions => _nextSuggestions;

  @override
  void onSuggestionSelected(Suggestion suggestion) {
    debugPrint('Suggestion selected: ${suggestion.title}');
  }

  @override
  void storyClusterFocusChanged(StoryCluster storyCluster) {}
}

/// Internal proposal descriptor.
class _P {
  final String id;
  final String headline;
  final String? subheadline;
  final int color;
  final String? imageUrl;
  final String? iconUrl;
  final ImageType imageType;

  const _P({
    required this.id,
    required this.headline,
    this.subheadline,
    required this.color,
    this.imageUrl,
    this.iconUrl,
    this.imageType = ImageType.other,
  });
}
