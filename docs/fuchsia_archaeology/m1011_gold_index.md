# milestone-1011: Gold Index

The parts that contain original thinking, design decisions, or liftable code.
Organized by what you'd use them for.

---

## How the shell worked (Armadillo internals)

### The state machine
- `topaz/shell/armadillo/lib/src/overview/conductor.dart` — every gesture mapped to a shell transition
- `topaz/shell/armadillo/lib/src/overview/conductor_model.dart` — the state: overview vs story vs minimized

### The spatial layout
- `topaz/shell/armadillo/lib/src/recent/story_list_layout.dart` — juggling algorithm: recency-based sizing, multi-column grid, dynamic spacing
- `topaz/shell/armadillo/lib/src/recent/story_list.dart` — the render object that paints the card field
- `topaz/shell/armadillo/lib/src/recent/render_story_list_body.dart` — custom multi-child layout with spring-driven positioning

### Cards
- `topaz/shell/armadillo/lib/src/recent/story_cluster.dart` — a card: stories, panels, display mode, keys, drag state
- `topaz/shell/armadillo/lib/src/recent/story_cluster_widget.dart` — how a card renders, focuses, unfocuses, lifts for drag
- `topaz/shell/armadillo/lib/src/recent/story.dart` — a single story within a cluster
- `topaz/shell/armadillo/lib/src/recent/story_bar.dart` — the title bar on focused cards
- `topaz/shell/armadillo/lib/src/recent/story_title.dart` — title rendering

### Drag and drop
- `topaz/shell/armadillo/lib/src/recent/armadillo_drag_target.dart` — custom drag target with candidate tracking
- `topaz/shell/armadillo/lib/src/recent/story_cluster_drag_feedback.dart` — drag feedback overlay
- `topaz/shell/armadillo/lib/src/recent/story_cluster_drag_data.dart` — drag payload
- `topaz/shell/armadillo/lib/src/recent/story_cluster_drag_state_model.dart` — tracks what's being dragged
- `topaz/shell/armadillo/lib/src/recent/panel_drag_target_generator.dart` — generates drop zones for panel rearrangement
- `topaz/shell/armadillo/lib/src/recent/panel_drag_targets.dart` — the actual drop zones
- `topaz/shell/armadillo/lib/src/recent/panel_drag_target.dart` — individual drop zone
- `topaz/shell/armadillo/lib/src/recent/edge_scroll_drag_target.dart` — auto-scroll when dragging to edges
- `topaz/shell/armadillo/lib/src/recent/kenichi_edge_scrolling.dart` — edge scroll physics
- `topaz/shell/armadillo/lib/src/recent/long_press_gesture_detector.dart` — long press detection for drag initiation
- `topaz/shell/armadillo/lib/src/recent/target_influence_overlay.dart` — visual feedback for drop targets
- `topaz/shell/armadillo/lib/src/recent/target_overlay.dart` — overlay for drop zone visualization

### Panels (multi-app composition within a card)
- `topaz/shell/armadillo/lib/src/recent/panel.dart` — a rectangular region within a card
- `topaz/shell/armadillo/lib/src/recent/story_panels.dart` — arranges panels within a focused card, tab bar, Mondrian zoom
- `topaz/shell/armadillo/lib/src/recent/cluster_layout.dart` — how panels tile within a cluster
- `topaz/shell/armadillo/lib/src/recent/panel_resizing_model.dart` — panel resize state
- `topaz/shell/armadillo/lib/src/recent/panel_resizing_overlay.dart` — resize handles
- `topaz/shell/armadillo/lib/src/recent/panel_event_handler.dart` — panel interaction events
- `topaz/shell/armadillo/lib/src/recent/story_cluster_panels_model.dart` — panels within a cluster
- `topaz/shell/armadillo/lib/src/recent/display_mode.dart` — tabs vs panels display mode

### Spring-animated widgets
- `topaz/shell/armadillo/lib/src/recent/simulated_padding.dart` — spring-animated padding
- `topaz/shell/armadillo/lib/src/recent/simulated_sized_box.dart` — spring-animated size
- `topaz/shell/armadillo/lib/src/recent/simulated_fractional.dart` — spring-animated fractional
- `topaz/shell/armadillo/lib/src/recent/simulated_fractionally_sized_box.dart` — spring-animated fractional size
- `topaz/shell/armadillo/lib/src/recent/simulated_transform.dart` — spring-animated transform
- `topaz/shell/armadillo/lib/src/recent/story_full_size_simulated_sized_box.dart` — full-size spring box
- `topaz/public/dart/widgets/lib/src/widgets/rk4_spring_simulation.dart` — RK4 spring simulation

### The suggestion shelf
- `topaz/shell/armadillo/lib/src/next/peeking_overlay.dart` — shelf peek/pull/snap with springs
- `topaz/shell/armadillo/lib/src/next/suggestion_list.dart` — suggestion list rendering
- `topaz/shell/armadillo/lib/src/next/suggestion_layout.dart` — suggestion sizing
- `topaz/shell/armadillo/lib/src/next/suggestion_widget.dart` — individual suggestion card
- `topaz/shell/armadillo/lib/src/next/suggestion_model.dart` — suggestion data model
- `topaz/shell/armadillo/lib/src/next/suggestion.dart` — suggestion data class
- `topaz/shell/armadillo/lib/src/next/selected_suggestion_overlay.dart` — expand animation on selection
- `topaz/shell/armadillo/lib/src/next/expand_suggestion.dart` — suggestion expansion animation
- `topaz/shell/armadillo/lib/src/next/splash_suggestion.dart` — splash effect on suggestion
- `topaz/shell/armadillo/lib/src/next/splash_painter.dart` — splash rendering
- `topaz/shell/armadillo/lib/src/next/interruption_overlay.dart` — interruption display
- `topaz/shell/armadillo/lib/src/next/peek_model.dart` — peek state
- `topaz/shell/armadillo/lib/src/next/next_builder.dart` — builds the suggestion shelf widget tree
- `topaz/shell/armadillo/lib/src/next/voice_model.dart` — voice input model

### The Now bar
- `topaz/shell/armadillo/lib/src/now/now.dart` — the Now bar root widget
- `topaz/shell/armadillo/lib/src/now/now_builder.dart` — Now bar builder
- `topaz/shell/armadillo/lib/src/now/now_minimization_model.dart` — minimized vs maximized state
- `topaz/shell/armadillo/lib/src/now/now_user_and_maximized_info.dart` — user info + expanded panel
- `topaz/shell/armadillo/lib/src/now/now_user_image.dart` — user avatar
- `topaz/shell/armadillo/lib/src/now/minimized_now_bar.dart` — collapsed bar
- `topaz/shell/armadillo/lib/src/now/context_model.dart` — context data model
- `topaz/shell/armadillo/lib/src/now/user_context_text.dart` �� context text rendering
- `topaz/shell/armadillo/lib/src/now/important_info.dart` — important info layout
- `topaz/shell/armadillo/lib/src/now/vertical_shifter.dart` — vertical positioning
- `topaz/shell/armadillo/lib/src/now/quick_settings.dart` — quick settings panel
- `topaz/shell/armadillo/lib/src/now/quick_settings_progress_model.dart` — settings expand progress
- `topaz/shell/armadillo/lib/src/now/toggle_icon.dart` — toggle switch
- `topaz/shell/armadillo/lib/src/now/timezone_picker.dart` — timezone picker
- `topaz/shell/armadillo/lib/src/now/wifi_settings.dart` — wifi settings
- `topaz/shell/armadillo/lib/src/now/power_model.dart` — battery model
- `topaz/shell/armadillo/lib/src/now/volume_model.dart` — volume model

### Animation transitions
- `topaz/shell/armadillo/lib/src/recent/story_cluster_entrance_transition_model.dart` — card entrance animation
- `topaz/shell/armadillo/lib/src/recent/story_drag_transition_model.dart` — drag state transition
- `topaz/shell/armadillo/lib/src/recent/story_rearrangement_scrim_model.dart` — scrim during rearrangement
- `topaz/shell/armadillo/lib/src/overview/idle_mode_builder.dart` — idle mode transition
- `topaz/shell/armadillo/lib/src/overview/idle_model.dart` — idle state
- `topaz/shell/armadillo/lib/src/overview/idle_model_builder.dart` — idle model construction

---

## How the inner compositor worked (Mondrian)

### Layout algorithms
- `topaz/shell/mondrian_story_shell/lib/layout/copresent_layout.dart` — emphasis-based proportional tiling
- `topaz/shell/mondrian_story_shell/lib/layout/pattern_layout.dart` — named layout patterns
- `topaz/shell/mondrian_story_shell/lib/layout/line_layout.dart` — linear arrangement
- `topaz/shell/mondrian_story_shell/lib/layout/container_layout.dart` — container layout
- `topaz/shell/mondrian_story_shell/lib/layout/layout.dart` — layout base
- `topaz/shell/mondrian_story_shell/lib/layout/widget_layout.dart` — widget-level layout

### Surface model
- `topaz/shell/mondrian_story_shell/lib/models/surface/surface.dart` — a surface instance
- `topaz/shell/mondrian_story_shell/lib/models/surface/surface_form.dart` — immutable position/size/depth (with lerp)
- `topaz/shell/mondrian_story_shell/lib/models/surface/surface_graph.dart` — surface graph: parent/child, focus stack, dismiss cascade
- `topaz/shell/mondrian_story_shell/lib/models/surface/surface_properties.dart` — surface properties
- `topaz/shell/mondrian_story_shell/lib/models/surface/surface_relation_util.dart` — relationship utilities
- `topaz/shell/mondrian_story_shell/lib/models/surface/surface_relationships.dart` — relationship types
- `topaz/shell/mondrian_story_shell/lib/models/surface/surface_state.dart` — surface lifecycle state
- `topaz/shell/mondrian_story_shell/lib/models/surface/surface_transition.dart` — surface transition animations

### Animation
- `topaz/shell/mondrian_story_shell/lib/anim/flux.dart` — spring with velocity handoff, zero-jerk
- `topaz/shell/mondrian_story_shell/lib/anim/sim.dart` — simulation helpers

### Tree model
- `topaz/shell/mondrian_story_shell/lib/models/tree/tree.dart` — generic tree structure
- `topaz/shell/mondrian_story_shell/lib/models/tree/spanning_tree.dart` — spanning tree

### Widgets
- `topaz/shell/mondrian_story_shell/lib/widgets/mondrian.dart` — root Mondrian widget
- `topaz/shell/mondrian_story_shell/lib/widgets/surface_director.dart` — surface orchestration
- `topaz/shell/mondrian_story_shell/lib/widgets/surface_stage.dart` — surface rendering stage
- `topaz/shell/mondrian_story_shell/lib/widgets/surface_frame.dart` — frame + elevation
- `topaz/shell/mondrian_story_shell/lib/widgets/surface_resize.dart` — resize interaction
- `topaz/shell/mondrian_story_shell/lib/widgets/resize_border.dart` — resize handles
- `topaz/shell/mondrian_story_shell/lib/widgets/gestures.dart` — unidirectional horizontal gesture with asymmetric friction
- `topaz/shell/mondrian_story_shell/lib/widgets/humanizer.dart` — gesture humanization
- `topaz/shell/mondrian_story_shell/lib/widgets/overview.dart` — overview mode
- `topaz/shell/mondrian_story_shell/lib/widgets/box.dart` — box rendering
- `topaz/shell/mondrian_story_shell/lib/widgets/mondrian_child_view.dart` — child view embedding
- `topaz/shell/mondrian_story_shell/lib/widgets/child_view.dart` — child view
- `topaz/shell/mondrian_story_shell/lib/widgets/widget_utils.dart` — utilities

### Other Mondrian
- `topaz/shell/mondrian_story_shell/lib/models/depth_model.dart` — Z-depth management
- `topaz/shell/mondrian_story_shell/lib/models/inset_manager.dart` — spring-animated surface insets
- `topaz/shell/mondrian_story_shell/lib/models/layout_model.dart` — layout state
- `topaz/shell/mondrian_story_shell/lib/models/center_controller.dart` — centering control
- `topaz/shell/mondrian_story_shell/lib/models/position_model.dart` — position state
- `topaz/shell/mondrian_story_shell/lib/models/patterns.dart` — named layout patterns
- `topaz/shell/mondrian_story_shell/lib/key_listener.dart` — keyboard shortcuts
- `topaz/shell/mondrian_story_shell/lib/story_shell_impl.dart` — FIDL service implementation

---

## How the intelligence layer worked

### The suggestion agent
- `topaz/shell/agents/home_work_agent/lib/home_work_proposer.dart` — subscribes to location context, swaps proposal sets
- `topaz/shell/agents/home_work_agent/assets/contextual_location_proposals.json` — home/work/unknown suggestions
- `topaz/shell/agents/home_work_agent/assets/ask_proposals.json` — ask/search suggestions

### The suggestion engine (C++)
- `peridot/bin/suggestion_engine/ranking_features/affinity_ranking_feature` — story affinity boost
- `peridot/bin/suggestion_engine/ranking_features/annoyance_ranking_feature` — annoyance level filter
- `peridot/bin/suggestion_engine/ranking_features/dead_story_ranking_feature` — suppress dismissed stories
- `peridot/bin/suggestion_engine/ranking_features/interrupting_ranking_feature` — interruption priority
- `peridot/bin/suggestion_engine/ranking_features/kronk_ranking_feature` — AI/assistant boost
- `peridot/bin/suggestion_engine/ranking_features/mod_pair_ranking_feature` — module co-occurrence
- `peridot/bin/suggestion_engine/ranking_features/proposal_hint_ranking_feature` — proposal metadata hints
- `peridot/bin/suggestion_engine/ranking_features/query_match_ranking_feature` — text query matching

### The context engine
- `peridot/bin/context_engine/` — context reader, writer, repository, index, debug
- `peridot/public/fidl/fuchsia.modular/context/context_reader.fidl` — subscribe with queries
- `peridot/public/fidl/fuchsia.modular/context/context_writer.fidl` — create/write values
- `peridot/public/fidl/fuchsia.modular/context/metadata.fidl` — story, module, entity, link metadata + focus state
- `peridot/public/fidl/fuchsia.modular/context/value_type.fidl` — STORY, MODULE, AGENT, ENTITY, LINK

### The real wiring (how Armadillo consumed it all)
- `topaz/bin/user_shell/armadillo_user_shell/lib/suggestion_provider_suggestion_model.dart` — Next/Query/Interruption channels from Maxwell
- `topaz/bin/user_shell/armadillo_user_shell/lib/story_provider_story_generator.dart` — stories from StoryProvider, clustered via Link
- `topaz/bin/user_shell/armadillo_user_shell/lib/context_provider_context_model.dart` — location, activity, timezone, user info
- `topaz/bin/user_shell/armadillo_user_shell/lib/wallpaper_chooser.dart` — suggestion→story→module→link→wallpaper

---

## How the modular framework worked

### Design docs
- `peridot/docs/modular/story.md` — story: container for root app + data
- `peridot/docs/modular/module.md` — module: composable component
- `peridot/docs/modular/agent.md` — agent: background service
- `peridot/docs/modular/entity.md` — entity: typed shared data
- `peridot/docs/modular/intent.md` — intent: action→module resolution
- `peridot/docs/modular/module_resolution.md` — discovery/matching
- `peridot/docs/modular/services.md` — service access
- `peridot/docs/modular/run_sequence.md` — boot order diagram

### FIDL contracts
- `peridot/public/fidl/fuchsia.modular/suggestion/proposal.fidl` — Proposal: id, headline, confidence, annoyance, actions
- `peridot/public/fidl/fuchsia.modular/suggestion/suggestion_provider.fidl` — three channels: Query, Next, Interruption
- `peridot/public/fidl/fuchsia.modular/suggestion/suggestion_display.fidl` — image type, annoyance type
- `peridot/public/fidl/fuchsia.modular/module/module_context.fidl` — AddModuleToStory, EmbedModule, GetLink
- `peridot/public/fidl/fuchsia.modular/story/story_controller.fidl` — story lifecycle control
- `peridot/public/fidl/fuchsia.modular/entity/entity.fidl` — Entity: GetTypes, GetData
- `peridot/public/fidl/fuchsia.modular/intent/intent.fidl` — Intent: action + parameters
- `peridot/public/fidl/fuchsia.modular/surface/surface.fidl` — SurfaceRelation: arrangement, dependency, emphasis

### The typed entity system
- `topaz/public/lib/schemas/dart/lib/entity_codec.dart` — base EntityCodec
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.color/` — Color
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.contact/` — Contact, Email, Phone, Filter
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.documents/` — Document ID
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.intent/` — Intent
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.location/` — Geolocation, StreetLocation
- `topaz/public/lib/schemas/dart/lib/src/com.fuchsia.status/` — Status
- `topaz/public/lib/schemas/dart/lib/com/fuchsia/media/` — MediaAsset, Captions, Progress
- `topaz/public/lib/schemas/dart/lib/com/google/youtube/` — YouTube VideoId
- `topaz/public/lib/schemas/dart/lib/com/fuchsia/codelab/` — Finance, Lyrics, Recipe

---

## How distributed storage worked (Ledger + Sledge)

### Ledger docs
- `peridot/docs/ledger/api_guide.md` — pages, keys, values, transactions, snapshots, watchers
- `peridot/docs/ledger/architecture.md` — local btree + cloud sync + p2p sync
- `peridot/docs/ledger/conflict_resolution.md` — LAST_ONE_WINS, AUTOMATIC_WITH_FALLBACK, CUSTOM
- `peridot/docs/ledger/life_of_a_put.md` — trace of a write through the system
- `peridot/docs/ledger/data_in_storage.md` — on-disk format
- `peridot/docs/ledger/firebase.md` — Firestore cloud provider

### Ledger implementation
- `peridot/bin/ledger/app/` — client API, branch tracking, merging
- `peridot/bin/ledger/cloud_sync/` — cloud sync
- `peridot/bin/ledger/p2p_provider/` — P2P discovery
- `peridot/bin/ledger/p2p_sync/` — P2P sync protocol
- `peridot/bin/ledger/storage/` — LevelDB-backed B-tree, content-addressed chunking
- `peridot/bin/ledger/encryption/` — encryption
- `peridot/bin/cloud_provider_firestore/` — Firestore gRPC cloud provider

### Sledge (CRDT ORM)
- `topaz/public/dart/sledge/README.md` — overview, assumptions, schema definition
- `topaz/public/dart/sledge/lib/src/schema/schema.dart` — schema definition
- `topaz/public/dart/sledge/lib/src/document/` — Document, Value, Change, LeafValue
- `topaz/public/dart/sledge/lib/src/document/values/` — typed CRDT values (map, set, ordered_list, pos_neg_counter, last_one_wins)
- `topaz/public/dart/sledge/lib/src/conflict_resolver/` — document conflict resolver, factory
- `topaz/public/dart/sledge/lib/src/sledge.dart` — main Sledge class
- `topaz/public/dart/sledge/lib/src/query/` — query support (WIP)

---

## How the graphics engine worked (Scenic + Escher)

### Scenic docs
- `garnet/docs/ui_scenic.md` — retained-mode 3D scene graph, unified lighting, cross-process shadows
- `garnet/docs/ui_units_and_metrics.md` — pip unit system: 5 correction layers
- `garnet/docs/ui.md` — UI subsystem overview
- `garnet/docs/ui_input.md` — input model

### Escher
- `garnet/public/lib/escher/README.md` — volumetric soft shadows, color bleeding, light diffusion, lens effect, HMD
- `garnet/public/lib/escher/paper/` — Material Design paper rendering
- `garnet/public/lib/escher/scene/` — scene graph
- `garnet/public/lib/escher/shaders/` — GPU shaders
- `garnet/public/lib/escher/hmd/` — head-mounted display

### Scenic FIDL
- `garnet/public/fidl/fuchsia.ui.scenic/` — session, commands, events
- `garnet/public/fidl/fuchsia.ui.gfx/` — scene graph: nodes, shapes, materials, cameras, lights, renderers, layers, hit testing, pose buffer, display info
- `garnet/public/fidl/fuchsia.ui.input/` — input events, IME
- `garnet/public/fidl/fuchsia.ui.views/` — view hierarchy
- `garnet/public/fidl/fuchsia.ui.policy/` — presentation policy

---

## Liftable code (no Fuchsia deps)

- `topaz/shell/mondrian_story_shell/lib/anim/flux.dart` + `sim.dart` — spring animation with velocity handoff
- `topaz/public/dart/widgets/lib/src/widgets/rk4_spring_simulation.dart` — RK4 spring
- `topaz/shell/mondrian_story_shell/lib/widgets/gestures.dart` — unidirectional gesture with friction
- `topaz/shell/mondrian_story_shell/lib/models/inset_manager.dart` — spring-animated insets
- `topaz/shell/mondrian_story_shell/lib/models/surface/surface_form.dart` — immutable position/size/depth with lerp
- `topaz/shell/widgets/lib/time_stringer.dart` — relative time formatting
- `topaz/shell/third_party/QR-Code-generator/dart/qrcodegen/` — QR code generation
- `topaz/public/dart/scheduler/lib/animated/spring.dart` — spring animation
- `topaz/public/dart/scheduler/lib/animated/simulation.dart` — simulation base
