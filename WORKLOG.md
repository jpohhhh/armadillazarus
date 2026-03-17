# Armadillazarus worklog

## What exists now

This workspace was created to host-side resurrect pieces of old Fuchsia
Armadillo / Mondrian shell code from:

- `/Users/jpo/dev/_research/topaz-m1011/shell/armadillo`
- `/Users/jpo/dev/_research/topaz-m1011/shell/widgets`
- `/Users/jpo/dev/_research/topaz-m1011/public/dart/widgets`
- `/Users/jpo/dev/_research/topaz-m1011/tools/widget_explorer/packages/widget_explorer_meta`

Vendored into:

- `vendor/armadillo`
- `vendor/sysui_widgets`
- `vendor/lib_widgets`
- `vendor/widget_explorer_meta`

The root app has a first-pass recents/story-cluster harness in `lib/main.dart`.

## What we already trimmed

A few obviously dead or host-incompatible pieces were removed or rewired so the
workspace could at least resolve packages:

- rewired vendored `pubspec.yaml` path dependencies to local `vendor/...`
- removed stale `models`, `util`, and `widgets` deps from `vendor/armadillo`
- repointed vendored `analysis_options.yaml` includes at this workspace root
- removed `flutter_image` dependency from `vendor/lib_widgets`
- replaced `NetworkImageWithRetry` with plain `NetworkImage` in `alphatar.dart`
- removed `snapshot_manager` export from `vendor/lib_widgets/lib/widgets.dart`
- removed `tracing_spring_model` export from `vendor/lib_widgets/lib/model.dart`
- trimmed a couple of imports that were pulling in larger shell surfaces than
  the recents harness actually needs

## Current state

`flutter pub get` works.

`flutter analyze lib/main.dart` is effectively clean for the root harness,
except for one deliberate `src/` import used to reach `DisplayMode`.

`flutter build macos --debug` gets well into compilation and then fails on real
source migration issues.

## The real blockers now

We are past path/packaging archaeology. The remaining issues are structural:

### 1. Null-safety migration

The vendored code is still pre-null-safety and modern Dart now interprets many
old optional parameters and fields as invalid. This is the bulk of the current
error volume.

Examples:
- optional constructor params with implicit `null`
- fields that are assigned later but now must be initialized
- old `@required` annotation patterns
- old assumptions about nullable framework APIs

### 2. Flutter framework API drift

Some framework contracts have changed enough that code needs semantic updates,
not just nullability fixes.

Examples already surfaced:
- `ParentDataWidget` generic usage / `debugTypicalAncestorWidgetClass`
- old `BuildContext.inheritFromWidgetOfExactType`
- old drag / pointer APIs
- old render-tree assumptions around nullable `RenderObject` / `RenderBox`

### 3. A few historical shell dependencies still baked into deeper layers

The narrowed recents harness avoided most Fuchsia-only imports, but deeper
`next` / `now` shell layers still reference FIDL-era packages and old internal
packages.

This is not the first thing to solve if the goal is understanding the recents /
story-cluster system.

## Recommended next move

Do **not** try to migrate the whole shell at once.

Instead, keep narrowing around the recents/story-cluster slice and make that
slice compile first.

Concretely, the next sensible target is:

- get `vendor/lib_widgets/lib/src/model/model.dart` host-safe on modern Flutter
- get `vendor/armadillo/lib/src/recent/story_list.dart` and its render tree
  compiling against modern `ParentDataWidget` / render APIs
- continue pruning exports/imports so `next` and `now` are not on the critical
  path for the first visual harness

Once the recents slice compiles, we can actually look at the thing and start
learning from it visually. That is the real payoff.

## New learning after the first real build attempt

The first successful `flutter build macos --debug` attempt was useful because it
showed the next layer of truth.

The workspace is no longer blocked on package archaeology. It now fails inside
the **interactive recents subtree itself**. That subtree pulls in a lot:
`StoryList` → `StoryClusterWidget` → panel drag targets → drag avatars /
overlay → simulation widgets → null-safety churn across most of `recent/`.

So there are now two plausible paths forward:

1. keep migrating the original interactive recents implementation file by file,
   preserving as much source fidelity as possible
2. build a host-side "museum renderer" that preserves the old data models and
   layout algorithms, but replaces the old drag/gesture/simulation shell widgets
   with simpler modern Flutter equivalents

The careful product call is probably to do (2) first for understanding, and
only do (1) where it buys us something specific.

That would let us see the layout, clustering, panel-vs-tab behavior, and
recency field much sooner, without committing to a full resurrection of every
legacy shell gesture primitive.

## Current resurrection frontier

We are now past the package-resolution phase and deep into mechanical
null-safety / framework-contract migration inside the recents shell.

The encouraging part is that the deeper "engine" files are settling down:
- `lib_widgets` model layer
- `SizeModel`
- `StoryCluster`
- `StoryModel`
- `StoryListLayout`
- related core data/layout code

The build is now failing later, in the more interaction-heavy shell widgets:
- drag targets / candidate tracking
- story panels / cluster widgets
- story bar / drag feedback / overlays
- render-object edge cases in the story list body

That is progress. It means the resurrection is moving from core state/layout
logic into the outer gesture-and-render shell.

## Migration scorecard

| Checkpoint | Errors | Files | Notes |
|-----------|--------|-------|---------|
| Start | 495 | 46 | All null-safety + framework drift |
| After core model/layout pass | ~443 | 46 | ScopedModel, SizeModel, StoryCluster modernized |
| After batch sed passes | 301 | 36 | Constructor params, Color?, Timer?, field inits |
| After panel_event_handler | 239 | 33 | Biggest single-file win (32 errors) |
| After typedef + drag target fixes | 176 | 28 | Typedefs matched, drag target modernized |

Remaining work is the same mechanical patterns repeated across ~28 files.
No deep framework redesign needed. No product logic changes.
