# Armadillo UX / demo / test data inventory

This is the current map of historical data sources dug out of `topaz-m1011` for the Armadillo resurrection.

## 1. Suggestion / proposal demo data

### Ask suggestions
Path:
- `_research/topaz-m1011/shell/agents/home_work_agent/assets/ask_proposals.json`

Contains 9 canned ask proposals with:
- `id`
- `headline`
- optional `subheadline`
- `color`
- `image_url` or `icon_url`
- `module_url`
- optional `module_data`
- optional `type`

Examples:
- Read NatureSense's June Newsletter
- Review your saved recipe
- Shamra release new album
- Read about Google I/O 2017
- Reply to Danielle
- View hotel confirmation
- Scroll through an infinite list
- Email

These are the strongest source for seeding the empty `SuggestionModel` in the current port.

### Contextual home/work/unknown suggestions
Path:
- `_research/topaz-m1011/shell/agents/home_work_agent/assets/contextual_location_proposals.json`

Contains location-keyed proposal sets for:
- `home`
- `work`
- `unknown`

Each entry includes:
- `story_title`
- `headline`
- optional `subheadline`
- `color`
- `icon_url` or `image_url`
- `module_url`
- optional `module_data`
- optional `type`

Examples:
- Cinefilm Showtimes
- Three Peaks Episode 6
- Good Foods
- OverThrough Magazine
- Expense Report
- Toe The Line Analytics
- Calendar / Flux Weekly Sync
- Q4'17 Marketing Plan
- It's Danielle's Birthday
- 17 min drive to Calafia
- Play Good Vibes Playlist
- Launch Fuchsia Dashboard

## 2. Suggestion asset pack used by those proposals

Path:
- `_research/topaz-m1011/shell/agents/home_work_agent/assets/`

Notable files:
- `ask_proposals.json`
- `contextual_location_proposals.json`
- people/photos: `danielle_cc0.jpg`, `miguel_cc0.png`, `simon_96.jpg`, `sophie_cc0.jpg`
- article/media art: `drawing.jpeg`, `pavlova.jpg`, `shamra.jpg`, `9-hotel.jpg`, `cc0_calafia.jpg`, `cc0_music.jpg`, `panda.png.jpg`
- app icons: `calendar.png`, `docs.png`, `google_photos.png`, `youtube_96dp.png`, `music_96dp.png`, `chat_96dp.png`, `cinefilm_96.png`, `expenses_96.png`
- story screenshots / hero images:
  - `story_calendar.png`
  - `story_cinefilm.png`
  - `story_expense.png`
  - `story_fluxMemories.png`
  - `story_googleIO.png`
  - `story_hype.png`
  - `story_marketing.png`
  - `story_natureSense.png`
  - `story_overthrough.png`
  - `story_phonecall.png`
  - `story_steps.png`
  - `story_threepeaks.png`
  - `story_toetheline.png`
  - `story_topcook.png`
  - `story_truefoods.png`

This directory is effectively the original visual demo pack for the suggestion UI.

## 3. The actual proposer code that served those suggestions

Path:
- `_research/topaz-m1011/shell/agents/home_work_agent/lib/home_work_proposer.dart`

What it does:
- loads `ask_proposals.json`
- loads `contextual_location_proposals.json`
- publishes `unknown` suggestions immediately
- swaps in `home` or `work` suggestions based on the `location/home_work` context topic
- registers an ask query handler
- supports some special demo queries like:
  - `demo`
  - `launch shader`
  - `launch perspective`
  - `launch infinite`
  - `launch spinning`
  - `launch hotel`
  - `launch concert`
- also scans package/system directories for matching apps when query text length >= 2

This is the single best source for reproducing the original suggestion behavior with canned/demo data.

## 4. User shell suggestion bridge

Path:
- `_research/topaz-m1011/bin/user_shell/armadillo_user_shell/lib/suggestion_provider_suggestion_model.dart`

What it reveals:
- Armadillo had three suggestion channels:
  - ask results
  - next results
  - interruptions
- ask suggestions were debounced by 500ms
- next suggestions could include timed-out interruptions
- suggestion selection notified Maxwell of interaction
- conversion from Maxwell suggestions into Armadillo `Suggestion` objects happened here

Useful for understanding how our dummy `SuggestionModel` should behave.

## 5. Story/demo data for recents layout

### Story recency distribution test data
Path:
- `_research/topaz-m1011/shell/armadillo/test/story_list_layout_test.dart`

Contains 24 dummy stories with realistic:
- `lastInteraction` offsets
- `cumulativeInteractionDuration`

This is the data we already stole for the current richer recents demo.
It is specifically for exercising the recency-weighted layout algorithm.

Also includes expected layout rects for:
- `360x640`
- `1280x800`

### StoryList widget sizing tests
Path:
- `_research/topaz-m1011/shell/armadillo/test/story_list_test.dart`

Contains a `_DummyStoryModel` that builds clusters with keyed container widgets.
Useful for:
- sizing expectations
- model wrapping requirements
- minimum shell harness setup

## 6. Drag-and-drop behavioral tests

Path:
- `_research/topaz-m1011/shell/armadillo/test/armadillo_drag_target_test.dart`

Covers:
- long-press drag start timing
- child vs `childWhenDragging`
- animate-back behavior
- preventing multiple simultaneous drags
- drag target accept/reject semantics
- overlapping drag targets

This is the best behavioral spec for restoring drag interactions faithfully.

## 7. Panel/grid geometry tests

Path:
- `_research/topaz-m1011/shell/armadillo/test/panel_test.dart`

Covers:
- panel splitting
- absorption/merging
- max rows / columns
- width/height factor thresholds
- adjacency/origin alignment
- span partition logic

This is the reference for multi-panel cluster behavior.

## 8. Candidate drag-lock tests

Path:
- `_research/topaz-m1011/shell/armadillo/test/candidate_info_test.dart`

Covers:
- drag direction inference
- target locking
- lock timing and relock behavior

This is useful if we want the drag/drop feel to match the original shell more closely.

## 9. User shell contextual / wallpaper demo data

### Context config
Path:
- `_research/topaz-m1011/bin/user_shell/armadillo_user_shell/assets/contextual_config.json`

Contains mappings for:
- background image by `default`, `home`, `work`
- plus contextual placeholders for battery/date/location/time/wifi

Background images referenced:
- `/system/data/sysui/aparna-sf.jpg`
- `/system/data/sysui/aparna-home.jpg`
- `/system/data/sysui/aparna-work.jpg`

### User shell wallpaper/context assets
Path:
- `_research/topaz-m1011/bin/user_shell/armadillo_user_shell/assets/`

Notable files:
- `aparna-home.jpg`
- `aparna-sf.jpg`
- `aparna-work.jpg`
- `danielle-home.jpg`
- `AgentIcon.png`
- `contextual_config.json`

These are part of the higher-fidelity user shell demo, not just the generic shell package.

### Context provider model
Path:
- `_research/topaz-m1011/bin/user_shell/armadillo_user_shell/lib/context_provider_context_model.dart`

Shows how the real shell selected:
- background image
- wifi network text
- location text
- time/date overrides
- user name / user image
- build timestamp
- device mode

### Wallpaper chooser
Path:
- `_research/topaz-m1011/bin/user_shell/armadillo_user_shell/lib/wallpaper_chooser.dart`

Shows there was also an explicit wallpaper-changing suggestion/action flow.
It proposed `Change Wallpaper`, launched a gallery story, watched a link, then updated the contextual background.

## 10. Story provider / live story generator

Path:
- `_research/topaz-m1011/bin/user_shell/armadillo_user_shell/lib/story_provider_story_generator.dart`

This is not just test data; it is the real bridge from Modular stories into Armadillo clusters.

Useful facts from it:
- max active clusters: `6`
- clustering state was serialized through a link key: `story_clusters`
- stories carried `story_title` and `color` via `StoryInfo.extra`
- story widgets were live child views, not placeholders
- focusing and clustering updates propagated back through links

If we want a more faithful story demo, this file is the blueprint.

## 11. Full user shell assembly / model wiring

Path:
- `_research/topaz-m1011/bin/user_shell/armadillo_user_shell/lib/main.dart`

Why it matters:
- shows the real model graph around Armadillo
- shows how Conductor, StoryModel, SuggestionModel, ContextModel, PeekModel, QuickSettingsProgressModel, etc. were wired together
- confirms the original shell used the full `Armadillo` wrapper, not just `Conductor`
- shows the `DefaultAssetBundle(defaultBundle)` wrapping behavior used by the original shell demo

## 12. Demo module targets referenced by proposal data

From the proposal JSONs and proposer code, the main demo targets are:
- `image`
- `chat_conversation_list`
- `hotel_confirmation`
- `infinite_scroller`
- `dashboard`
- `email/nav`
- via typed query logic also: `perspective`, `spinning_cube`, `shadertoy_client`, `concert_event_list`

Confirmed present in repo at least for:
- `app/image`
- `app/infinite_scroller`
- `app/dashboard`
- `app/perspective`
- `app/spinning_cube`

Some others may have moved, been renamed, or lived behind different module URLs.

## Practical recommendation

If the goal is to make the resurrected Armadillo demo feel like itself, the best order of attack is:

1. Seed `SuggestionModel` from `ask_proposals.json` and `contextual_location_proposals.json`.
2. Copy the associated `home_work_agent/assets` images into our vendored demo assets.
3. Recreate at least a fake `home/work/unknown` context toggle.
4. Optionally map suggestion selection to placeholder Wright/demo surfaces.
5. Later, steal more from `story_provider_story_generator.dart` if we want a truer story ecosystem.
