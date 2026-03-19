# milestone-1011: Complete Index

Three repos. One snapshot. October 16, 2018.

## Repo stats

| Repo | Files | Dart | C++(.cc+.h) | Rust | FIDL | Markdown |
|------|-------|------|-------------|------|------|----------|
| topaz | 2,090 | 905 | — | — | 6 | 68 |
| peridot | 1,487 | 0 | 978 | — | 81 | 76 |
| garnet | 6,143 | 0 | 3,781 | 342 | 169 | 156 |

---

## TOPAZ — the shell and app layer

### shell/ — Armadillo + Mondrian + agents

- `shell/armadillo/` — 99 Dart files. The spatial card-based home shell.
- `shell/mondrian_story_shell/` — 36 Dart files. The inner story compositor.
- `shell/agents/home_work_agent/` — suggestion agent + JSON proposal data
- `shell/kernel_panic/` — Fuchsia BSOD (hot pink, QR code)
- `shell/keyboard/` — soft keyboard + word suggestion + tests
- `shell/widgets/` — shared widget library (icon_slider, time_stringer, three_column_layout, key_mappings)
- `shell/third_party/QR-Code-generator/` — QR code lib (used by kernel_panic)
- `shell/docs/` — documentation.md, performance.md, setup.md, dev_setup.md, code_reviews.md

### bin/user_shell/ — the real wiring layer

- `bin/user_shell/armadillo_user_shell/` — 18 Dart files. Glue between Armadillo UI and Fuchsia services:
  - `main.dart` — full service wiring
  - `story_provider_story_generator.dart` — stories from StoryProvider
  - `suggestion_provider_suggestion_model.dart` — Next/Query/Interruption channels
  - `context_provider_context_model.dart` — location, activity, timezone, user info
  - `wallpaper_chooser.dart` — suggestion→story→module→link→wallpaper pipeline
  - `focused_stories_tracker.dart` — focus tracking
  - `hit_test_model.dart` — touch routing
  - `maxwell_voice_model.dart` — voice input
  - `maxwell_hotword.dart` — hotword detection
  - `power_manager_power_model.dart` — real battery
  - `audio_policy_volume_model.dart` — real volume
  - `active_agents_manager.dart` — agent lifecycle
  - `armadillo_user_shell_model.dart` — shell model

### app/ — the apps that ran inside Armadillo

- `app/color/` — ModuleDriver example (~80 lines, full lifecycle)
- `app/contacts/` — 37 Dart files. Contacts app with agents.
- `app/dashboard/` — Fuchsia CI build dashboard (real network, ModuleDriver)
- `app/documents/` — 15 Dart files. Document viewer.
- `app/image/` — image display module
- `app/infinite_scroller/` — infinite scroll demo
- `app/latin-ime/` — Latin input method editor
- `app/ledger/ledger_dashboard/` — Ledger inspection dashboard
- `app/link_viewer/` — Link data viewer/debugger
- `app/maxwell/agents/module_suggester_dart/` — module suggestion agent
- `app/maxwell/agents/usage_log/` — usage tracking agent
- `app/perspective/` — Scenic elevation showcase (PhysicalModel shadows)
- `app/spinning_cube/` — 3D spinning cube demo
- `app/term/` — terminal emulator
- `app/video/` — video player module

### examples/

- `examples/modular/` — shapes_mod, slider_mod, text_mod, two_mods, colored_container, blue_app
- `examples/mondrian_test/` — random-color module for Mondrian testing
- `examples/example_manual_relationships/` — surface arrangement test harness
- `examples/story_shell_test/` — story shell test harness
- `examples/ui/` — noodles (Scenic/Skia), sketchy_flutter, taxi, thing
- `examples/ledger/` — todo_list, todo_list_sledge, vote_list_sledge
- `examples/media/` — vu_meter
- `examples/mediaplayer/` — mediaplayer_flutter, mediaplayer_skia
- `examples/mine_digger/` — minesweeper game
- `examples/tictactoe/` — tic-tac-toe with FIDL service
- `examples/bluetooth/` — BLE scanner, eddystone
- `examples/eddystone_agent/` — BLE beacon agent
- `examples/fidl/` — echo client/server examples
- `examples/oauth_token_manager/` — OAuth token management

### public/dart/ — shared Dart libraries

- `public/dart/sledge/` — 93 files. Typed CRDT ORM over Ledger.
- `public/dart/widgets/` — rk4_spring_simulation, default_bundle
- `public/dart/scenic/` — Dart Scenic client
- `public/dart/fidl/` — Dart FIDL bindings
- `public/dart/fuchsia/` — Dart Fuchsia platform library
- `public/dart/modular/` — Dart modular framework client
- `public/dart/modular_flutter/` — Flutter modular helpers
- `public/dart/scoped_model/` — scoped model state management
- `public/dart/scheduler/` — animated simulation/spring/tick/cubit
- `public/dart/zircon/` — Dart Zircon bindings

### public/lib/ — Dart framework client libraries

- `public/lib/proposal/` — ProposalBuilder
- `public/lib/story/` — LinkClient, LinkWatcherImpl
- `public/lib/entity/` — EntityClient, EntityResolverClient
- `public/lib/module/` — ModuleContextClient, ModuleControllerClient
- `public/lib/module_resolver/` — IntentBuilder
- `public/lib/agent/` — AgentClient
- `public/lib/app_driver/` — ModuleDriver (high-level module API)
- `public/lib/context/` — context publishing helpers
- `public/lib/schemas/` — 38 typed entity codecs (Color, Contact, Email, Phone, Documents, Intent, Location, Geolocation, Status, Media, YouTube, Codelab, Finance, Lyrics, Recipe)
- `public/lib/app/` — application connection helpers
- `public/lib/config/` — configuration
- `public/lib/decomposition/` — link decomposition
- `public/lib/device/` — device info
- `public/lib/display/` — display info
- `public/lib/intent_handler/` — intent handler
- `public/lib/ledger/` — Ledger client helpers
- `public/lib/lifecycle/` — lifecycle management
- `public/lib/media/` — media helpers
- `public/lib/mediaplayer/` — media player helpers
- `public/lib/run_mod/` — run module helpers
- `public/lib/settings/` — settings client
- `public/lib/testing/` — test helpers
- `public/lib/ui/` — UI helpers
- `public/lib/user/` — user helpers
- `public/lib/widgets/` — scoped model, model finder

### lib/ — internal shared libraries

- `lib/shell/` — overlay_position_model, overlay_drag_model
- `lib/story_shell/` — key_listener, common utilities
- `lib/keyboard/` — keyboard rendering and input
- `lib/settings/` — settings framework
- `lib/setui/` — system UI settings
- `lib/xi/` — xi editor: client, fuchsia_client, widgets
- `lib/device_shell/` — device shell helpers
- `lib/deprecated_loop/` — C++ message loop (deprecated)
- `lib/fuchsia_test_helper/` — test helper framework

### bin/ — other services and tools

- `bin/bluetooth_settings/` — Bluetooth settings UI
- `bin/device_settings/` — Device settings UI
- `bin/display_settings/` — Display settings UI
- `bin/wifi_settings/` — WiFi settings UI
- `bin/system_dashboard/` — System dashboard
- `bin/ermine/` — early Ermine (config only)
- `bin/xi/` — xi editor front-end module
- `bin/chat/` — chat app (removed, README only)
- `bin/userpicker_device_shell/` — device shell with user picker
- `bin/fidlgen_dart/` — FIDL→Dart code generator
- `bin/repl/` — Dart REPL
- `bin/ui/benchmarks/` — UI benchmarks
- `bin/flutter_screencap_test/` — screenshot test

### runtime/ — Dart and Flutter runners

- `runtime/dart_runner/` — Dart component runner (C++)
- `runtime/flutter_runner/` — Flutter component runner (C++). Vulkan surfaces, vsync, Scenic integration.
- `runtime/web_runner/` — Web component runner
- `runtime/web_runner_prototype/` — Prototype web runner
- `runtime/web_view/` — WebView with schema.org context extraction

### auth_providers/

- `auth_providers/google/` — Google OAuth provider (C++)
- `auth_providers/spotify/` — Spotify OAuth provider (C++)
- `auth_providers/oauth/` — shared OAuth request/response (C++)

### tools/

- `tools/mod/` — `mod` CLI for managing modules
- `tools/widget_explorer/` — widget introspection tool
- `tools/doc_checker/` — documentation lint checker
- `tools/dartfmt_extras/` — Dart formatting extensions
- `tools/repl/` — REPL tooling

### docs/

- `docs/entities/structured-data.md` — entity/structured-data concepts
- `docs/dart_fidl_bindings.md` — Dart FIDL bindings guide
- `docs/repository_structure.md` — repo organization
- `docs/standalone_build.md` — standalone build instructions

---

## PERIDOT — the modular framework

### docs/modular/ — framework design docs

- `docs/modular/story.md` — story: container for root app + data
- `docs/modular/module.md` — module: component within a story
- `docs/modular/agent.md` — agent: background service
- `docs/modular/entity.md` — entity: typed shared data
- `docs/modular/intent.md` — intent: action→module resolution
- `docs/modular/module_resolution.md` — discovery/matching
- `docs/modular/services.md` — service access model
- `docs/modular/run_sequence.md` — boot order diagram
- `docs/modular/getting_started.md` — getting started guide
- `docs/modular/manifests/module.md` — module manifest shape
- `docs/modular/manifests/entity_type.md` — entity typing rules

### docs/ledger/ — distributed storage docs

- `docs/ledger/README.md` — what Ledger is
- `docs/ledger/api_guide.md` — client API guide
- `docs/ledger/architecture.md` — system architecture
- `docs/ledger/conflict_resolution.md` — merge strategies
- `docs/ledger/data_in_storage.md` — on-disk data model
- `docs/ledger/data_organization.md` — storage organization
- `docs/ledger/life_of_a_put.md` — lifecycle of a write
- `docs/ledger/examples.md` — examples
- `docs/ledger/field_data.md` — field data format
- `docs/ledger/firebase.md` — Firebase cloud sync
- `docs/ledger/user_guide.md` — user guide
- `docs/ledger/testing.md` — testing notes
- `docs/ledger/style_guide.md` — code style

### bin/ — framework implementations

- `bin/suggestion_engine/` — 46 C++ files. Ranking, filtering, processing.
  - `ranking_features/` — 8 algorithms: affinity, annoyance, dead_story, interrupting, kronk, mod_pair, proposal_hint, query_match
  - `filters/` — passive, active, conjugate
  - `decision_policies/` — rank-above-threshold
  - `rankers/` — linear ranker combining features
  - `next_processor`, `query_processor`, `navigation_processor`, `interruptions_processor`
- `bin/context_engine/` — 18 C++ files. Reader, writer, repository, index, debug.
- `bin/ledger/` — 405 C++ files. Full distributed CRDT storage:
  - `app/` — client API, branch tracker, merging
  - `cloud_sync/` — cloud sync
  - `p2p_provider/` — P2P discovery
  - `p2p_sync/` — P2P protocol
  - `storage/` — LevelDB-backed B-tree, content-addressed chunking
  - `encryption/` — encryption layer
  - `sync_coordinator/` — cloud + P2P coordination
- `bin/maxwell/` — intelligence services coordinator
- `bin/module_resolver/` — module resolution, type inference
- `bin/user_runner/` — story runner, agent runner, entity provider, focus, message queue, puppet master, storage
- `bin/device_runner/` — device runner, user provider
- `bin/sessionctl/` — session control CLI
- `bin/cloud_provider_firestore/` — Firestore gRPC cloud provider
- `bin/agents/clipboard/` — system clipboard
- `bin/acquirers/story_info/` — context acquirer for story info
- `bin/test_driver/` — test driver framework
- `bin/token_manager/` — dev token manager

### public/fidl/ — ALL the FIDL contracts (81 files)

#### fuchsia.modular
- `agent/` — Agent, AgentContext, AgentController, AgentProvider, SessionAgent
- `clipboard/` — Clipboard
- `component/` — ComponentContext, MessageQueue
- `context/` — ContextEngine, ContextReader, ContextWriter, debug, metadata, value, value_type
- `device/` — DeviceRunnerMonitor, DeviceShell, UserProvider
- `entity/` — Entity, EntityProvider, EntityReferenceFactory, EntityResolver
- `intent/` — Intent, IntentHandler
- `lifecycle/` — Lifecycle
- `module/` — Module, ModuleContext, ModuleController, ModuleData, ModuleManifest, ModuleState, LinkPath
- `module_resolver/` — ModuleResolver
- `story/` — StoryController, StoryProvider, StoryShell, StoryInfo, StoryState, StoryVisibilityState, StoryOptions, StoryCommand, PuppetMaster, Link, CreateLink, CreateModuleParameterMap
- `suggestion/` — SuggestionEngine, SuggestionProvider, Proposal, ProposalPublisher, QueryHandler, SuggestionDisplay, UserInput, debug
- `surface/` — Surface, Container
- `user/` — UserShell, Focus, DeviceMap
- `user_intelligence/` — IntelligenceServices, Scope, UserIntelligenceProvider

#### fuchsia.ledger
- `ledger.fidl` — Ledger, LedgerRepository, Page, PageSnapshot, PageWatcher

#### fuchsia.ledger.cloud
- `cloud_provider.fidl` — CloudProvider, DeviceSet, PageCloud

#### fuchsia.speech
- `speech_to_text.fidl` — SpeechToText

### tests/ — 20+ integration test suites

- `tests/suggestion/` — suggestion behavior
- `tests/intents/` — intent resolution
- `tests/link_passing/` — entity/link transfer
- `tests/link_data/` — link data persistence
- `tests/link_context_entities/` — context↔entity bridge
- `tests/module_context/` — module lifecycle
- `tests/parent_child/` — parent/child modules
- `tests/story_shell/` — story shell integration
- `tests/story_update/` — story state updates
- `tests/chain/` — module chaining
- `tests/clipboard/` — clipboard sharing
- `tests/embed_shell/` — shell embedding
- `tests/trigger/` — trigger conditions
- `tests/queue_persistence/` — message queue persistence
- `tests/last_focus_time/` — focus time tracking
- `tests/component_context/` — component context access
- `tests/maxwell_integration/` — Maxwell integration
- `tests/user_shell/` — user shell integration
- `tests/benchmarks/` — modular benchmarks

### examples/

- `examples/simple/` — simple agent + module (C++)
- `examples/swap_cpp/` — module swapping
- `examples/todo_cpp/` — todo list with Ledger
- `examples/guides/how_to_write_a_module_cc.md` — module writing guide
- `examples/guides/how_to_write_an_agent_cc.md` — agent writing guide
- `examples/cloud_components/` — cloud component index

### lib/ — shared framework libraries

- `lib/common/` — async_holder, story_provider_watcher_base, teardown, xdr, names
- `lib/convert/` — type conversion
- `lib/fidl/` — app_client, json_xdr, view_host, proxy, environment, single_service_app
- `lib/firebase/` — Firebase client (event_stream, encoding, status)
- `lib/firebase_auth/` — Firebase auth
- `lib/ledger_client/` — Ledger client helpers (page_client, operations, status)
- `lib/module_manifest/` — module manifest XDR
- `lib/module_manifest_source/` — manifest sources (firebase, json, package)
- `lib/testing/` — test fakes (component_context, entity_resolver, module_resolver, story_controller, story_provider, ledger_repository)
- `lib/user_shell_settings/` — user shell settings
- `lib/device_info/` — device info and profile
- `lib/bound_set/` — bound set container
- `lib/rng/` — random number generation
- `lib/socket/` — socket utilities

### web/

- `web/cloud_dashboard/` — Angular web dashboard for Ledger cloud

---

## GARNET — the system services layer

### docs/

- `docs/ui_scenic.md` — Scenic: 3D scene graph, unified lighting, cross-process shadows
- `docs/ui_units_and_metrics.md` — pip unit system: 5 correction layers
- `docs/ui.md` — UI subsystem overview
- `docs/ui_input.md` — input model
- `docs/bluetooth_architecture.md` — bluetooth architecture
- `docs/debugger.md` — zxdb debugger
- `docs/inspect.md` — component inspection
- `docs/tracing_usage_guide.md` — tracing guide

### bin/ui/ — UI system

- `bin/ui/scenic/` — Scenic compositor (C++)
- `bin/ui/root_presenter/` — root presenter
- `bin/ui/view_manager/` — view management
- `bin/ui/sketchy/` — Sketchy service (procedural drawing)
- `bin/ui/ime/` — input method editor
- `bin/ui/input/` — input handling
- `bin/ui/input_reader/` — input device reading
- `bin/ui/present_view/` — view presentation
- `bin/ui/set_root_view/` — root view setter
- `bin/ui/screencap/` — screen capture
- `bin/ui/snapshot/` — scene snapshot
- `bin/ui/recovery_ui/` — recovery mode UI
- `bin/ui/benchmarks/` — UI benchmarks

### public/lib/escher/ — physically based renderer

- Volumetric soft shadows, color bleeding, light diffusion, lens effect
- Paper rendering (Material Design), scene graph, GPU shaders, HMD support
- Builds on Linux

### public/fidl/ — system API contracts (169 FIDL files)

- `fuchsia.ui.scenic/` — session, commands, events
- `fuchsia.ui.gfx/` — scene graph: nodes, shapes, materials, cameras, lights, renderers, layers, hit testing, pose buffer, display info
- `fuchsia.ui.input/` — input events, IME
- `fuchsia.ui.views/` — view hierarchy
- `fuchsia.ui.viewsv1/` — v1 view system (Mondrian's API)
- `fuchsia.ui.policy/` — display policy, presentation
- `fuchsia.ui.sketchy/` — Sketchy canvas
- `fuchsia.ui.vectorial/` — vectorial drawing
- `fuchsia.ui.app/` — view provider
- `fuchsia.images/` — image pipe
- `fuchsia.media/` — audio renderer, capturer, gain, stream
- `fuchsia.mediaplayer/` — player, metadata, seeking, timeline
- `fuchsia.mediacodec/` — codec factory
- `fuchsia.power/` — power management
- `fuchsia.fonts/` — font provider
- `fuchsia.bluetooth.*` — BLE, GATT, control, pairing
- `fuchsia.wlan.*` — WLAN service, stats, MLME
- `fuchsia.net.*` — HTTP, netstack
- `fuchsia.sys/` — component lifecycle, environment, launcher, runner
- `fuchsia.auth/` — auth provider, token manager
- `fuchsia.stash/` — persistent key-value storage
- `fuchsia.timezone/` — timezone service
- `fuchsia.tts/` — text-to-speech
- `fuchsia.xi/` — xi editor service
- `fuchsia.accessibility/` — a11y manager, semantics
- `fuchsia.guest/` — VM guest, vsock, Wayland bridge
- `fuchsia.inspect/` — component inspection

### examples/

- `examples/escher/waterfall/` — Escher demo
- `examples/ui/hello_scenic/` — minimal Scenic example
- `examples/ui/shapes/` — shape demo
- `examples/ui/hello_input/` — input demo
- `examples/ui/hello_pose_buffer/` — VR pose buffer demo
- `examples/ui/hello_stereo/` — stereoscopic demo
- `examples/ui/hello_views/` — view hierarchy demo
- `examples/ui/shadertoy/` — shader toy
- `examples/ui/sketchy/` — Sketchy drawing demo
- `examples/ui/spinning_square/` — spinning square
- `examples/ui/tile/` — tile layout
- `examples/ui/video_display/` — video display
- `examples/ui/yuv_to_image_pipe/` — YUV→image pipe

### bin/ — other system services

- `bin/media/audio_core/` — audio mixing
- `bin/mediaplayer/` — media player (ffmpeg, demux, decode, render)
- `bin/bluetooth/` — Bluetooth stack
- `bin/fonts/` — font service (Rust)
- `bin/cobalt/` — analytics/telemetry
- `bin/power_manager/` — power management (Rust)
- `bin/timezone/` — timezone service
- `bin/tts/` — text-to-speech
- `bin/xi_core/` — xi editor core (Rust)
- `bin/terminal/` — terminal emulator (Rust)
- `bin/wayland/` — Wayland bridge
- `bin/guest/` — VM guest management
- `bin/zxdb/` — debugger
- `bin/debug_agent/` — debug agent
- `bin/trace/` + `bin/trace_manager/` — system tracing
- `bin/sysmgr/` — system manager
- `bin/appmgr/` — application manager
- `bin/a11y/` — accessibility

### drivers/

- `drivers/bluetooth/` — Bluetooth HCI
- `drivers/gpu/` — GPU (ARM Mali, Intel Gen, Vivante)
- `drivers/wlan/` — WLAN (Mediatek, Realtek)
- `drivers/usb_video/` — USB video
- `drivers/video/` — Amlogic video decoder
