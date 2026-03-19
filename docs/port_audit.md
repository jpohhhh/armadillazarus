# Armadillazarus Port Audit

Comparison of the ported code against the original Fuchsia checkout at
`/Users/jpo/dev/_research/topaz-m1011/shell/armadillo`. Every `.dart` file
is present (99/99). Changes fall into three categories.

---

## Real Bugs / Broken Features

### 1. Drag-and-drop GlobalKey is disabled

**File:** `story_cluster_widget.dart:84`

`storyCluster.clusterDraggableKey` is commented out:
```dart
// key: storyCluster.clusterDraggableKey,
```

**Why:** Modern Flutter's `MultiChildRenderObjectElement._children` is a
`late` field. When GlobalKey-ed children are stolen between widget trees
during animation rebuilds, `forgetChild()` fires before `_children` is
initialized, causing `LateInitializationError`.

**Impact:** Long-press drag initiates but the feedback overlay doesn't have
a proper widget reference back to the original card. Drag visually works
(the card lifts and follows your finger) but drop target resolution and
animate-back may misbehave. Grouping (the core Armadillo interaction) is
unreliable.

**Fix:** Either find a way to defer the GlobalKey assignment until after
mount, or use `_SafeMultiChildElement` (which we already added to
`story_list.dart`) more broadly. Or restructure the drag feedback to not
rely on GlobalKey stealing.

### 2. _SafeMultiChildElement may leak elements

**File:** `story_list.dart:296`

Our workaround guards `forgetChild()`:
```dart
@override
void forgetChild(Element child) {
  if (!_childrenInitialized) return;  // ← swallows the call
  super.forgetChild(child);
}
```

**Impact:** If a child IS stolen before mount completes, it won't be
properly forgotten. The old parent element may retain a stale reference.
In practice this hasn't caused a visible bug yet but could leak memory or
cause state corruption under heavy drag activity.

### 3. Suggestion selection has no target story

**File:** `demo_suggestion_model.dart`

All demo suggestions use `SelectionType.closeSuggestions`, which just hides
the shelf. The expand and splash animations are fully wired but have no
story to focus on after the animation completes.

**Impact:** Tapping a suggestion dismisses the shelf. The original behavior
was: suggestion expands to fill screen → launched activity appears behind
it. We get the first half (dismiss) but not the second (launch).

**Fix:** When a suggestion is selected, create a new `StoryCluster` from
the suggestion's data, add it to the `StoryModel`, and focus it. This
requires wiring `DemoSuggestionModel.onSuggestionSelected` to
`StoryModel.addStoryCluster` + `ConductorModel.focusStoryCluster`.

### 4. Spring overshoot clamp may cause visual stutter

**File:** `simulated_padding.dart:32`

```dart
// ARMADILLAZARUS(parity): clamp final result to prevent spring overshoot
```

Padding values are clamped to `>= 0` to prevent Flutter assertion failures.
Old Flutter silently accepted negative padding.

**Impact:** At the exact frame where a spring overshoots past 0, the
animation "sticks" at 0 instead of the original micro-negative value. This
can cause a single-frame visual hitch during fast spring animations.
Unlikely to be noticeable but not identical to original behavior.

### 5. story_cluster_widget clamp on opacity

**File:** `story_cluster_widget.dart:244`

```dart
// ARMADILLAZARUS(parity): added clamp to prevent -0.0 from rounding
```

Opacity clamped to `0.0..1.0`. Same issue as #4 — spring overshoot into
negative opacity caused a Flutter assertion. Clamp prevents crash but the
fade-out animation may not be frame-identical to original.

---

## Missing / Stubbed Features

### 6. No battery, volume, wifi, or voice input

**Files:**
- `power_model.dart` → `hasBattery => false`, `percentage => 1.0`
- `volume_model.dart` → `level => 1.0`
- `wifi_settings.dart` → placeholder UI, no real scanning
- `voice_model.dart` → `isInput => false`

**Impact:** The Now bar's quick settings panel shows but battery/wifi/volume
indicators are static. Voice input button exists but does nothing.

### 7. No real context model

**File:** `main.dart` → `_DummyContextModel`

Returns hardcoded time/date strings. No location detection, no home/work
switching, no contextual wallpaper changes.

**Impact:** The wallpaper is always the same. Contextual suggestions don't
switch between home/work/unknown sets. The "context-aware assistant" part
of the Armadillo vision is absent.

### 8. Story content is colored rectangles

**File:** `main.dart` → `_StoryContent`

Each story card renders a `Container(color: color)` with a centered title.
No real app content, no embedded Wright applets, no interactive surfaces.

**Impact:** The recents field looks like a color palette instead of a
multitasking workspace. Focus/unfocus works but there's nothing interesting
inside the cards.

### 9. No user image

**File:** `main.dart` → `_DummyContextModel.userImageUrl => null`

**Impact:** The Now bar shows a default silhouette avatar instead of a
user photo.

### 10. Timezone picker and WiFi settings are decorative

**Files:** `timezone_picker.dart`, `wifi_settings.dart`

Show real-looking UI (timezone list, network scan) but actions are no-ops.

### 11. StoryModel.normalize() is unimplemented

**File:** `story_model.dart:300`

```dart
// TODO(apwilson): implement this!
```

**Impact:** When the screen resizes, panels within grouped stories don't
rearrange to fit the new dimensions. A 3-column panel group that was valid
on a wide screen may have panels that violate minimum size constraints on a
narrow screen. **This was unfinished in the ORIGINAL Fuchsia code, not our
port.**

---

## Original Team TODOs (inherited, not introduced)

These were never finished by the original team:

- `story_list_layout.dart:292` — "Should be vertical grid not horizontal"
  (appears 3 times)
- `story_list_layout.dart:301` — "doesn't take into account multiple
  columns"
- `story_list_layout.dart:335` — "Should probably be based on the highest
  story in this row"
- `story_cluster_widget.dart:34` — "Reduce the height of this. It's large
  for now for ease of touch."
- `panel.dart:16` — "This should be calculated from size rather than being
  a constant"
- `story_model.dart:305` — "have callers handle when the story cluster no
  longer exists"
- `story_panels.dart:341` — "Remove the lerpDouble from 1.03 to 1.0"
  (the Mondrian zoom hack, cosmetic only)
- `next_builder.dart:82` — "remove this hack when Scenic focus is fixed"
  (Fuchsia-specific, irrelevant)
- `important_info.dart:263` — `shouldRelayout` always returns `false`,
  meaning the Now bar info section may not re-layout when data changes

---

## Summary

| Category                   | Count | Severity           |
|----------------------------|-------|--------------------|
| Real bugs (our port)       | 5     | Medium — drag is the biggest |
| Missing/stubbed features   | 6     | Expected — platform stubs    |
| Original team TODOs        | 9+    | Low — inherited               |

**Update:** Bug #1 (GlobalKey on drag) has been fixed. The GlobalKey was
restored after confirming that `_SafeMultiChildElement` (guarding
`forgetChild()`) combined with `ValueKey(clusterId)` on `_StoryListChild`
prevents the `LateInitializationError`. Drag-and-drop now works — cards
can be long-pressed, lifted, and dropped onto other cards for grouping.

Remaining issues are either expected (platform service stubs) or cosmetic
(spring clamp artifacts, static story content, inherited TODOs).
