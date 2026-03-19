# Fuchsia Must-Read: The Short List

Read in this order. Each file is chosen because it teaches something you
can't get from any of the others.

---

## 1. The vision (what they were building)

**`topaz/shell/armadillo/lib/src/overview/conductor.dart`**
The one file that shows the whole Armadillo state machine. Every gesture
mapped to a shell-wide transition.

**`topaz/shell/armadillo/lib/src/recent/story_list_layout.dart`**
The juggling algorithm. How cards are sized by recency, how multi-column
layout works, how grid spacing adapts to screen size. The spatial heart
of Armadillo.

**`topaz/shell/armadillo/lib/src/next/peeking_overlay.dart`**
The suggestion shelf — peeks, pulls up, snaps. Spring physics on a
gesture-driven overlay.

**`topaz/shell/armadillo/lib/src/recent/story_cluster_widget.dart`**
How a card renders, focuses, unfocuses, lifts for drag. The full lifecycle
of a single card in the Field.

## 2. The inner compositor (Mondrian)

**`topaz/shell/mondrian_story_shell/lib/layout/copresent_layout.dart`**
Emphasis-based tiling. How multiple surfaces divide space proportionally.

**`topaz/shell/mondrian_story_shell/lib/models/surface/surface_graph.dart`**
The surface graph — parent/child relationships, focus stack, dismiss
cascade, external associations. The data model behind Mondrian.

**`topaz/shell/mondrian_story_shell/lib/anim/flux.dart`**
Spring animations that carry velocity through gesture→animation handoffs.
Zero-jerk transitions. Directly liftable Dart code, no Fuchsia deps.

## 3. The intelligence layer (suggestions + context)

**`topaz/shell/agents/home_work_agent/lib/home_work_proposer.dart`**
The actual agent that fed Armadillo's suggestion shelf. Subscribes to
location context, swaps proposal sets.

**`topaz/shell/agents/home_work_agent/assets/contextual_location_proposals.json`**
The real suggestion data. Home suggestions, work suggestions, unknown-
location suggestions. Shows what contextual proposals looked like.

**`peridot/public/fidl/fuchsia.modular/suggestion/proposal.fidl`**
The Proposal schema — id, headline, subheadline, confidence, annoyance
type, story affinity, actions. The contract between agents and the shell.

**`peridot/public/fidl/fuchsia.modular/suggestion/suggestion_provider.fidl`**
Three suggestion channels: Query (ask), Next (passive/contextual),
Interruption (proactive push). The API Armadillo consumed.

## 4. The modular framework (mods)

**`peridot/docs/modular/story.md`**
What a story actually was — a logical container for a root app plus data.

**`peridot/docs/modular/module.md`**
What a module was — a component within a story, composed via intents.

**`peridot/docs/modular/intent.md`**
Intent-based module resolution. "I want to view a photo" → system finds
the right module.

**`peridot/public/fidl/fuchsia.modular/module/module_context.fidl`**
The module lifecycle API — AddModuleToStory, EmbedModule, GetLink,
StartOngoingActivity. The contract between a mod and the framework.

## 5. The storage layer (Ledger + Sledge)

**`peridot/docs/ledger/api_guide.md`**
The Ledger client API. Pages, keys, values, transactions, snapshots,
watchers. How distributed storage worked.

**`peridot/docs/ledger/conflict_resolution.md`**
CRDT merge strategies — LAST_ONE_WINS, AUTOMATIC_WITH_FALLBACK, CUSTOM.
How multi-device sync resolved conflicts.

**`peridot/docs/ledger/life_of_a_put.md`**
Trace of a single write from client API through local btree update
through cloud sync. The clearest explanation of how Ledger worked.

**`topaz/public/dart/sledge/README.md`**
Sledge — the typed Dart CRDT ORM on top of Ledger. Schemas, documents,
typed fields, automatic conflict resolution per field type.

## 6. The graphics engine (Scenic)

**`garnet/docs/ui_scenic.md`**
Scenic architecture — retained-mode 3D scene graph on Vulkan via Escher.
Unified lighting, cross-process shadows, jank-free server-side animation.

**`garnet/docs/ui_units_and_metrics.md`**
The pip unit system. Five correction layers: aspect ratio, angular size,
ergonomic, perceptual, user. Way beyond dp. Read this for the thinking
about how to make UI work across wildly different form factors.

## 7. The retreat (what replaced Armadillo)

**`topaz_test: bin/session_shell/capybara_session_shell/lib/root.dart`**
Capybara — the immediate replacement. Floating windows, a taskbar,
drag tabs. ~500 lines. Read to understand what was lost.

**`experiences/session_shells/ermine/shell/lib/src/widgets/app.dart`**
Ermine — what shipped. One fullscreen view at a time. MobX state. A
complete retreat from spatial composition.

## 8. The reusable Dart libraries (liftable as-is)

**`topaz/shell/mondrian_story_shell/lib/anim/flux.dart`**
+ `sim.dart` — ~500 lines. Generic spring animation with velocity
handoff. No Fuchsia deps. Copy-paste into any Flutter project.

**`topaz/public/dart/widgets/lib/src/widgets/rk4_spring_simulation.dart`**
RK4 spring simulation used by Armadillo's simulated_* widgets. Also
vendored into armadillazarus already.

**`topaz/shell/mondrian_story_shell/lib/widgets/gestures.dart`**
Unidirectional horizontal gesture detector with asymmetric friction.
Clean, self-contained, useful for swipe-to-dismiss.

**`topaz/shell/mondrian_story_shell/lib/models/inset_manager.dart`**
Spring-animated insets between surfaces. 22 lines. Elegant pattern for
dynamic spacing that settles smoothly.

**`topaz/shell/mondrian_story_shell/lib/models/surface/surface_form.dart`**
SurfaceForm — immutable description of a surface's position, size, and
depth. Clean value type with lerp support. Good pattern for any animated
layout system.

---

## Reading time estimate

The must-read core (items 1–4): ~2 hours of careful reading.
The storage + graphics docs (5–6): ~1 hour.
The retreat + vendorable code (7–8): ~30 minutes.
