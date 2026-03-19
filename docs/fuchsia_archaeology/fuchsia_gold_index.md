# Fuchsia Gold Index

This is the short map of the parts that actually mattered: the shell vision,
modular framework, suggestion/intelligence stack, storage stack, Scenic/UI
engine, and the later shells that show where things went after Armadillo.

## Branches worth caring about

- `topaz/milestone-1011` — Armadillo, Mondrian, the shell vision, demo apps
- `peridot/milestone-1011` — modular framework, Ledger, suggestions, agents
- `garnet/milestone-1011` — Scenic, UI units, Escher, compositor docs
- `experiences/main` — Ermine and Gazelle, the later session-shell era
- `topaz/topaz_test` — Capybara, the retreat to windows and a taskbar

## The shell / story / suggestion gold

### Topaz: the shell layer

- `topaz/shell/README.md` — the user-shell overview
- `topaz/shell/HACKING.md` — links to the shell documentation set
- `topaz/shell/docs/documentation.md` — how the team documented the shell
- `topaz/shell/docs/performance.md` — performance notes and priorities
- `topaz/shell/armadillo/` — the main Armadillo shell implementation
- `topaz/shell/mondrian_story_shell/` — the inner story compositor
- `topaz/shell/agents/home_work_agent/lib/home_work_proposer.dart` — the actual suggestion agent
- `topaz/shell/agents/home_work_agent/assets/ask_proposals.json` — ask/demo suggestion data
- `topaz/shell/agents/home_work_agent/assets/contextual_location_proposals.json` — home/work/unknown suggestions

### Topaz: the app zoo Armadillo was for

- `topaz/app/contacts/` — contacts app
- `topaz/app/documents/` — documents viewer
- `topaz/app/image/` — image app
- `topaz/app/infinite_scroller/` — endless scroll demo
- `topaz/app/ledger/ledger_dashboard/` — Ledger dashboard
- `topaz/app/perspective/` — perspective app
- `topaz/app/spinning_cube/` — 3D demo
- `topaz/app/term/` — terminal
- `topaz/app/video/` — video player
- `topaz/bin/chat/` — chat app (later removed from buildable state)
- `topaz/bin/xi/` — xi editor front-end
- `topaz/bin/maxwell/agents/module_suggester_dart/main.dart` — module suggestion agent

### Topaz: the reusable data model layer

- `topaz/docs/entities/structured-data.md` — entity/structured-data concepts
- `topaz/public/dart/sledge/README.md` — Sledge, the Dart API over Ledger
- `topaz/public/dart/sledge/lib/src/` — typed CRDT-ish document/schema code
- `topaz/public/lib/schemas/dart/README.md` — schema support docs

### Topaz: the module examples

- `topaz/examples/modular/README.md` — modular framework examples
- `topaz/examples/modular/shapes_mod/README.md` — simple mod example
- `topaz/examples/modular/slider_mod/README.md` — mod that can launch other mods
- `topaz/examples/ui/README.md` — example mod entry point
- `topaz/examples/ui/noodles/README.md` — Scenic/Skia rendering example
- `topaz/examples/ui/sketchy_flutter/README.md` — Flutter + Scenic integration example

## The modular framework gold

### Peridot: the framework docs

- `peridot/docs/modular/story.md` — what a story is
- `peridot/docs/modular/module.md` — modules and module composition
- `peridot/docs/modular/agent.md` — background agent model
- `peridot/docs/modular/entity.md` — entities as shared data
- `peridot/docs/modular/intent.md` — intent-based resolution
- `peridot/docs/modular/module_resolution.md` — discovery / matching logic
- `peridot/docs/modular/services.md` — service access model
- `peridot/docs/modular/run_sequence.md` — boot / run ordering diagram
- `peridot/docs/modular/getting_started.md` — framework entry point
- `peridot/docs/modular/manifests/module.md` — module manifest shape
- `peridot/docs/modular/manifests/entity_type.md` — entity typing rules

### Peridot: the Ledger docs

- `peridot/docs/ledger/README.md` — what Ledger is
- `peridot/docs/ledger/api_guide.md` — the client API guide
- `peridot/docs/ledger/architecture.md` — system architecture
- `peridot/docs/ledger/conflict_resolution.md` — merge/conflict behavior
- `peridot/docs/ledger/data_in_storage.md` — on-disk data model
- `peridot/docs/ledger/data_organization.md` — storage organization
- `peridot/docs/ledger/examples.md` — examples
- `peridot/docs/ledger/field_data.md` — field data format
- `peridot/docs/ledger/life_of_a_put.md` — the lifecycle of a write
- `peridot/docs/ledger/user_guide.md` — user-facing guide
- `peridot/docs/ledger/testing.md` — testing notes
- `peridot/docs/ledger/firebase.md` — Firebase/cloud sync bridge

### Peridot: the implementation gold

- `peridot/bin/suggestion_engine/` — suggestion ranking engine
- `peridot/bin/context_engine/` — context tracking engine
- `peridot/bin/ledger/` — Ledger implementation
- `peridot/bin/user_runner/story_runner/README.md` — story runner docs
- `peridot/public/fidl/fuchsia.modular/module/module_context.fidl` — module lifecycle API
- `peridot/public/fidl/fuchsia.modular/suggestion/suggestion_provider.fidl` — suggestion channels API
- `peridot/public/fidl/fuchsia.modular/suggestion/proposal.fidl` — proposal schema
- `peridot/public/fidl/fuchsia.modular/suggestion/suggestion_display.fidl` — suggestion image/provenance/annoyance schema
- `peridot/public/fidl/fuchsia.modular/story/story_controller.fidl` — story control API
- `peridot/public/fidl/fuchsia.modular/context/README.md` — context subsystem note
- `peridot/tests/suggestion/` — suggestion behavior tests
- `peridot/tests/module_context/` — module context tests
- `peridot/tests/story_shell/` — story shell integration tests
- `peridot/tests/link_passing/` — entity/link transfer tests
- `peridot/tests/link_data/` — link data tests

## The graphics / Scenic gold

### Garnet docs

- `garnet/docs/ui_scenic.md` — Scenic architecture, unified lighting, shared scene graph
- `garnet/docs/ui_units_and_metrics.md` — the pip unit system and correction layers
- `garnet/docs/ui.md` — UI subsystem overview
- `garnet/docs/ui_input.md` — input model
- `garnet/docs/bluetooth_architecture.md` — later-system architecture context

### Scenic / Escher / UI code

- `garnet/public/lib/ui/scenic/` — Scenic client library
- `garnet/public/lib/escher/` — Escher renderer library
- `garnet/public/fidl/fuchsia.ui.scenic/` — Scenic FIDL
- `garnet/examples/ui/hello_scenic/` — minimal Scenic example
- `garnet/examples/ui/shapes/` — shape demo
- `garnet/examples/ui/hello_input/` — input demo
- `garnet/examples/ui/hello_pose_buffer/` — pose buffer demo
- `garnet/examples/ui/spinning_square/` — classic visual demo
- `garnet/bin/ui/view_manager/` — view management plumbing
- `garnet/bin/ui/root_presenter/` — root presenter shell piece
- `garnet/bin/ui/set_root_view/` — root view bridge
- `garnet/bin/ui/present_view/` — view presentation tool
- `garnet/bin/ui/sketchy/` — Sketchy service

## The later shells / what happened after Armadillo

### Experiences: Ermine

- `experiences/session_shells/ermine/README.md` — Ermine shell overview
- `experiences/session_shells/ermine/shell/README.md` — Ermine shell internals
- `experiences/session_shells/ermine/shell/lib/src/widgets/app.dart` — main shell app widget
- `experiences/session_shells/ermine/shell/lib/src/widgets/app_view.dart` — main view/layout
- `experiences/session_shells/ermine/shell/lib/src/states/app_state.dart` — shell state model
- `experiences/session_shells/ermine/shell/lib/src/states/settings_state.dart` — settings state
- `experiences/lib/ermine_ui/` — reusable Ermine UI components

### Experiences: Gazelle

- `experiences/session_shells/gazelle/README.md` — Gazelle shell overview
- `experiences/session_shells/gazelle/shell/meta/gazelle_shell.cml` — shell manifest
- `experiences/session_shells/gazelle/shell/` — shell code
- `experiences/session_shells/gazelle/wm/` — window manager code
- `experiences/session_shells/gazelle/appkit/` — app kit library
- `experiences/session_shells/gazelle/element_router/` — routing plumbing
- `experiences/session_shells/gazelle/examples/bouncing_box/` — example app

### Topaz_test / Capybara

- `topaz/bin/session_shell/capybara_session_shell/` — the window-manager retreat
- `topaz/bin/session_shell/capybara_session_shell/lib/root.dart` — shell root
- `topaz/bin/session_shell/capybara_session_shell/lib/window/` — floating windows and tabs
- `topaz/bin/session_shell/capybara_session_shell/lib/launcher.dart` — launcher placeholder

## Previously missed gold

### The glue layer (armadillo_user_shell)

This is the Rosetta Stone — 18 Dart files that wire Armadillo to every
Fuchsia service. This is the REAL main.dart.

- `topaz/bin/user_shell/armadillo_user_shell/lib/main.dart` — full wiring: StoryProvider, SuggestionProvider, ContextProvider, FocusProvider, PowerManager, Audio, DeviceMap, Link, all connected
- `topaz/bin/user_shell/armadillo_user_shell/lib/story_provider_story_generator.dart` — how stories came from StoryProvider, were clustered, synced via Link, and focused
- `topaz/bin/user_shell/armadillo_user_shell/lib/suggestion_provider_suggestion_model.dart` — real suggestion wiring: Next, Query, and Interruption channels from Maxwell
- `topaz/bin/user_shell/armadillo_user_shell/lib/context_provider_context_model.dart` — real context model: location/home_work topic, activity/walking, wallpaper switching, device mode, timezone, user info
- `topaz/bin/user_shell/armadillo_user_shell/lib/wallpaper_chooser.dart` — end-to-end example: suggestion → create story → launch gallery module → watch Link for image selection → apply wallpaper
- `topaz/bin/user_shell/armadillo_user_shell/lib/focused_stories_tracker.dart` — tracks which stories are visible/focused
- `topaz/bin/user_shell/armadillo_user_shell/lib/hit_test_model.dart` — controls which stories receive touch
- `topaz/bin/user_shell/armadillo_user_shell/lib/maxwell_voice_model.dart` — voice input from Maxwell
- `topaz/bin/user_shell/armadillo_user_shell/lib/maxwell_hotword.dart` — hotword detection
- `topaz/bin/user_shell/armadillo_user_shell/lib/power_manager_power_model.dart` — real battery from PowerManager
- `topaz/bin/user_shell/armadillo_user_shell/lib/audio_policy_volume_model.dart` — real volume from Audio service

### The typed entity system (schemas)

38 Dart entity codecs — the type system for the system clipboard:

- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.color/` — Color entity
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.contact/` — Contact, Email, PhoneNumber, Filter entities
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.documents/` — Document ID entity
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.intent/` — Intent entity
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.location/` — Geolocation, StreetLocation entities
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.status/` — Status entity
- `topaz/public/lib/schemas/dart/lib/com/fuchsia/media/` — MediaAsset, Captions, Progress entities
- `topaz/public/lib/schemas/dart/lib/com/google/youtube/` — YouTube VideoId entity
- `topaz/public/lib/schemas/dart/lib/com/fuchsia/codelab/` — Finance, Lyrics, Recipe entities
- `topaz/public/lib/schemas/dart/lib/entity_codec.dart` — base EntityCodec class

### Dart client libraries for the framework

- `topaz/public/lib/proposal/dart/lib/src/proposal_builder.dart` — ProposalBuilder, how agents create suggestions
- `topaz/public/lib/story/dart/lib/` — LinkClient, LinkWatcherImpl, the Dart API for Link data
- `topaz/public/lib/entity/dart/lib/` — EntityClient, EntityResolverClient
- `topaz/public/lib/module/dart/lib/` — ModuleContextClient, ModuleControllerClient
- `topaz/public/lib/app_driver/` — ModuleDriver, the idiomatic high-level module API

### Context engine FIDL (the full context graph API)

- `peridot/public/fidl/fuchsia.modular/context/context_engine.fidl` — top-level ContextEngine service
- `peridot/public/fidl/fuchsia.modular/context/context_reader.fidl` — Subscribe with queries, Get snapshots
- `peridot/public/fidl/fuchsia.modular/context/context_writer.fidl` — CreateValue, WriteEntityTopic
- `peridot/public/fidl/fuchsia.modular/context/metadata.fidl` — StoryMetadata, ModuleMetadata, EntityMetadata, LinkMetadata, FocusedState
- `peridot/public/fidl/fuchsia.modular/context/value.fidl` — ContextValue with content + merged metadata
- `peridot/public/fidl/fuchsia.modular/context/value_type.fidl` — STORY, MODULE, AGENT, ENTITY, LINK
- `peridot/public/fidl/fuchsia.modular/context/debug.fidl` — debug listener for context changes

### Suggestion ranking features (the scoring brain)

- `peridot/bin/suggestion_engine/ranking_features/affinity_ranking_feature` — story affinity
- `peridot/bin/suggestion_engine/ranking_features/annoyance_ranking_feature` — annoyance level filter
- `peridot/bin/suggestion_engine/ranking_features/dead_story_ranking_feature` — don't suggest dismissed stories
- `peridot/bin/suggestion_engine/ranking_features/interrupting_ranking_feature` — interruption priority
- `peridot/bin/suggestion_engine/ranking_features/kronk_ranking_feature` — AI/assistant boost
- `peridot/bin/suggestion_engine/ranking_features/mod_pair_ranking_feature` — module co-occurrence
- `peridot/bin/suggestion_engine/ranking_features/proposal_hint_ranking_feature` — proposal metadata hints
- `peridot/bin/suggestion_engine/ranking_features/query_match_ranking_feature` — text query matching

### Escher (the physically based renderer)

- `garnet/public/lib/escher/README.md` — volumetric soft shadows, color bleeding, light diffusion, lens effect. Vulkan. Builds on Linux.
- `garnet/public/lib/escher/paper/` — paper rendering (Material Design physical model)
- `garnet/public/lib/escher/scene/` — scene graph nodes
- `garnet/public/lib/escher/shaders/` — GPU shaders
- `garnet/public/lib/escher/hmd/` — head-mounted display support

### The keyboard

- `topaz/shell/keyboard/lib/keyboard.dart` — full soft keyboard implementation
- `topaz/shell/keyboard/lib/keys.dart` — key definitions
- `topaz/shell/keyboard/lib/word_suggestion_service.dart` — predictive text

### Kernel panic screen

- `topaz/shell/kernel_panic/` — Fuchsia BSOD: hot pink, monospace panic text, QR code of crash info, tap to dismiss

### Surface arrangement test harness

- `topaz/examples/example_manual_relationships/lib/main.dart` — buttons to launch copresent, sequential, ontop, and container surfaces. Focus/dismiss controls. THE test app for Mondrian layouts.

### The modular framework integration tests

20+ test directories in peridot showing what was actually tested:

- `peridot/tests/suggestion/` — suggestion behavior
- `peridot/tests/intents/` — intent resolution
- `peridot/tests/link_passing/` — entity/link transfer between modules
- `peridot/tests/link_data/` — link data persistence
- `peridot/tests/link_context_entities/` — context ↔ entity bridge
- `peridot/tests/module_context/` — module lifecycle
- `peridot/tests/parent_child/` — parent/child module relationships
- `peridot/tests/story_shell/` — story shell integration
- `peridot/tests/story_update/` — story state updates
- `peridot/tests/chain/` — module chaining
- `peridot/tests/clipboard/` — clipboard sharing
- `peridot/tests/embed_shell/` — shell embedding
- `peridot/tests/trigger/` — trigger conditions
- `peridot/tests/queue_persistence/` — message queue persistence
- `peridot/tests/last_focus_time/` — focus time tracking
- `peridot/tests/component_context/` — component context access
- `peridot/tests/maxwell_integration/` — Maxwell intelligence integration

### Demo apps worth noting

- `topaz/app/color/lib/main.dart` — cleanest example of ModuleDriver API: watch Link entity, auto-update, publish. ~80 lines, full lifecycle.
- `topaz/app/dashboard/lib/main.dart` — Fuchsia CI dashboard. Real network, real data, real ModuleDriver. Shows all build targets.
- `topaz/app/perspective/lib/main.dart` — Scenic elevation showcase. Album maker + photo list + video player + animated sun, ALL using PhysicalModel elevation for real Scenic shadows.
- `topaz/app/spinning_cube/lib/main.dart` — 3D spinning cube demo
- `topaz/examples/mondrian_test/lib/main.dart` — random-color module for Mondrian testing

### Shared widget libraries

- `topaz/shell/widgets/lib/` — shared between Armadillo and Mondrian: icon_slider, key_mappings, three_column_aligned_layout_delegate, time_stringer
- `topaz/lib/shell/lib/models/` — overlay_position_model, overlay_drag_model
- `topaz/lib/story_shell/lib/` — key_listener, common utilities

## If you only read a few things

If you want the shortest route to the heart of the archive, read these:

- `topaz/shell/README.md`
- `topaz/shell/armadillo/` and `topaz/shell/mondrian_story_shell/`
- `topaz/shell/agents/home_work_agent/lib/home_work_proposer.dart`
- `peridot/docs/modular/story.md`
- `peridot/docs/modular/module.md`
- `peridot/docs/ledger/api_guide.md`
- `garnet/docs/ui_scenic.md`
- `garnet/docs/ui_units_and_metrics.md`
- `experiences/session_shells/ermine/shell/lib/src/widgets/app.dart`
- `experiences/session_shells/gazelle/README.md`
