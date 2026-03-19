# milestone-1011: Must-Read List

Read in this order. Each file teaches something you can't get from any other.

---

## 1. The vision (what they were building)

**`topaz/shell/armadillo/lib/src/overview/conductor.dart`**
The whole Armadillo state machine. Every gesture mapped to a shell
transition.

**`topaz/shell/armadillo/lib/src/recent/story_list_layout.dart`**
The juggling algorithm. Cards sized by recency, multi-column layout,
grid spacing adapts to screen size.

**`topaz/shell/armadillo/lib/src/next/peeking_overlay.dart`**
The suggestion shelf — peeks, pulls up, snaps. Spring physics on a
gesture-driven overlay.

**`topaz/shell/armadillo/lib/src/recent/story_cluster_widget.dart`**
How a card renders, focuses, unfocuses, lifts for drag. Full lifecycle
of a single card.

## 2. The real wiring (how it connected to everything)

**`topaz/bin/user_shell/armadillo_user_shell/lib/main.dart`**
THE glue. StoryProvider, SuggestionProvider, ContextProvider,
FocusProvider, PowerManager, Audio, DeviceMap, Link — all wired in
one file.

**`topaz/bin/user_shell/armadillo_user_shell/lib/story_provider_story_generator.dart`**
How stories came from the framework, were clustered, synced via Link,
and focused. 600 lines, the most complex wiring file.

**`topaz/bin/user_shell/armadillo_user_shell/lib/suggestion_provider_suggestion_model.dart`**
How Next, Query, and Interruption suggestion channels were consumed.

**`topaz/bin/user_shell/armadillo_user_shell/lib/wallpaper_chooser.dart`**
End-to-end: suggestion selected → create story → launch gallery module
→ watch Link for image → apply wallpaper. The whole pipeline in one file.

## 3. The inner compositor (Mondrian)

**`topaz/shell/mondrian_story_shell/lib/layout/copresent_layout.dart`**
Emphasis-based tiling. How multiple surfaces divide space proportionally.

**`topaz/shell/mondrian_story_shell/lib/models/surface/surface_graph.dart`**
The surface graph — parent/child, focus stack, dismiss cascade,
external associations.

**`topaz/shell/mondrian_story_shell/lib/anim/flux.dart`**
Spring animations with velocity handoff. Zero-jerk transitions.
No Fuchsia deps. Copy-paste liftable.

## 4. The intelligence layer

**`topaz/shell/agents/home_work_agent/lib/home_work_proposer.dart`**
The actual suggestion agent. Subscribes to location context, swaps
proposal sets.

**`topaz/shell/agents/home_work_agent/assets/contextual_location_proposals.json`**
The real suggestion data. Home/work/unknown suggestions with colors,
icons, module URLs.

**`peridot/public/fidl/fuchsia.modular/suggestion/proposal.fidl`**
The Proposal schema — id, headline, confidence, annoyance, story
affinity, actions.

**`peridot/public/fidl/fuchsia.modular/suggestion/suggestion_provider.fidl`**
Three suggestion channels: Query, Next, Interruption.

## 5. The modular framework

**`peridot/docs/modular/story.md`**
What a story actually was.

**`peridot/docs/modular/module.md`**
What a module was — composable component within a story.

**`peridot/docs/modular/intent.md`**
Intent-based module resolution. "I want to view a photo" → system
finds the right module.

**`peridot/public/fidl/fuchsia.modular/module/module_context.fidl`**
The module lifecycle API — AddModuleToStory, EmbedModule, GetLink,
StartOngoingActivity.

**`topaz/app/color/lib/main.dart`**
Cleanest example of the module lifecycle. Watch Link, auto-update,
publish to context. ~80 lines.

**`topaz/examples/example_manual_relationships/lib/main.dart`**
Surface arrangement test harness. Shows copresent, sequential, ontop,
container — with focus/dismiss controls.

## 6. The typed entity system

**`topaz/public/lib/schemas/dart/lib/entity_codec.dart`**
Base EntityCodec class.

**`topaz/public/lib/schemas/dart/lib/src/com.fuchsia.contact/`**
Contact entity with Email, Phone, Filter sub-entities.
Shows nested entity composition.

**`peridot/public/fidl/fuchsia.modular/entity/entity.fidl`**
The Entity FIDL — GetTypes, GetData, WriteData, Watch.

## 7. The storage layer (Ledger + Sledge)

**`peridot/docs/ledger/api_guide.md`**
The Ledger client API. Pages, keys, values, transactions, snapshots,
watchers.

**`peridot/docs/ledger/conflict_resolution.md`**
CRDT merge strategies — LAST_ONE_WINS, AUTOMATIC_WITH_FALLBACK, CUSTOM.

**`peridot/docs/ledger/life_of_a_put.md`**
Trace of a single write from client through btree through cloud sync.

**`topaz/public/dart/sledge/README.md`**
Sledge — typed CRDT ORM. Schemas, documents, typed fields, automatic
per-field conflict resolution.

## 8. The graphics engine

**`garnet/docs/ui_scenic.md`**
Scenic: retained-mode 3D scene graph on Vulkan via Escher. Unified
lighting, cross-process shadows, server-side animation.

**`garnet/docs/ui_units_and_metrics.md`**
The pip unit system. Five correction layers: aspect ratio, angular size,
ergonomic, perceptual, user. Read this for the thinking about how to
make UI work across wildly different form factors.

**`garnet/public/lib/escher/README.md`**
Escher: volumetric soft shadows, color bleeding, light diffusion,
lens effect. Physically based. HMD support. Builds on Linux.

## 9. The suggestion ranking brain

**`peridot/bin/suggestion_engine/ranking_features/kronk_ranking_feature.cc`**
AI/assistant confidence boost.

**`peridot/bin/suggestion_engine/ranking_features/mod_pair_ranking_feature.cc`**
Module co-occurrence — "people who used X also used Y."

**`peridot/bin/suggestion_engine/ranking_features/annoyance_ranking_feature.cc`**
Annoyance filtering — respecting the user's attention.

## 10. The context graph

**`peridot/public/fidl/fuchsia.modular/context/context_reader.fidl`**
Subscribe with structured queries.

**`peridot/public/fidl/fuchsia.modular/context/context_writer.fidl`**
Write context values and entity topics.

**`peridot/public/fidl/fuchsia.modular/context/metadata.fidl`**
Context metadata: story focus state, module path, entity type, link
name. The schema for "what the user is doing right now."

**`topaz/bin/user_shell/armadillo_user_shell/lib/context_provider_context_model.dart`**
How Armadillo consumed context: location/home_work, activity/walking,
timezone, user info, device profile.

---

## Reading time estimate

The core vision (1–4): ~2.5 hours of careful reading.
The framework + entities (5–6): ~1 hour.
The storage + graphics (7–8): ~1 hour.
The ranking + context (9–10): ~30 minutes.

Total: ~5 hours for everything. The most you'll ever learn about an
OS shell vision that was actually built and then abandoned.
