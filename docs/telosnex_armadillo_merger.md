# The Merger: Telosnex × Armadillo

## What Telosnex Has Today

Three screens, two navigation modes:

**Home Screen** (one scrollable surface):
- DateTime header (time, date, menu) — fixed behind content, tappable when
  scrolled to top
- Blank space pushes content to the bottom of the viewport
- Chats — horizontal scrolling row of conversation tiles
- Ideas — staggered grid of AI-generated suggestion cards
- Companion — text field + contextual chips + footer buttons (script picker,
  files, go/send), pinned to bottom

**Conversation Screen** (push navigation from home):
- App bar at top
- Scrolling list of LoomTiles (dialogue, tool calls, wright applets, search,
  art, audio, errors, suggestions, history summaries)
- Same Companion at bottom (text field + chips + buttons)

**Wright Applets** (inline in conversation messages):
- Lua state machine: init() → render(state) → on_event(state, event)
- Renders real Flutter widgets via JSON config (Text, Button, Chip, Toggle,
  TextInput, ListTile, Slider, Dropdown, Chart, Grid, Row, Column, Markdown,
  Expansion, Icon, BackButton)
- Can call any MCP tool and dispatch agent calls
- AI-editable ("Edit with AI" dialog rewrites the Lua)
- Debug tabs: View / Code / State / Tree
- State cached in LRU so scrolling away and back doesn't re-init

**Ideas** (AI-generated suggestions on home):
- Agent examines last 48 hours of conversations, generates contextual ideas
- Each idea has: title, prompt, color, icon, thought process
- Tap copies prompt to Companion text field
- Auto-refreshes every 5 minutes

**Companion** (the universal input bar):
- Same widget on both screens (home vs chat host)
- Text field, FAB send button, script picker, files, go button
- Header: animated contextual chips (clear, TTS, close, scroll-to-end,
  jump-to-history, live audio controls, camera, mute, art settings, skill
  picker, agent instructions, remote target, show/hide code)
- Adapts to left/right handedness
- Hero-animated between home and conversation

---

## What Armadillo Had

Summarized from the companion feature guide, the pieces that matter for this
merger:

1. **Cards sized by usage** — recently touched things are bigger
2. **A scrollable field of cards** — not a list, a spatial surface
3. **Grouping by drag** — drop one card on another to compose a workspace
4. **Tabs and panels** — two views of the same group
5. **The suggestion shelf** — proactive, contextual, peeks from behind Now
6. **The Conductor** — one state machine choreographing all layers
7. **Go to origin** — single gesture resets everything
8. **Inline preview** — hovering shows what *would* happen
9. **Spring physics everywhere** — nothing jumps, everything settles

---

## The Conceptual Mapping

Telosnex already has every Armadillo concept, but decomposed across separate
screens and navigation pushes:

| Armadillo Concept      | Telosnex Equivalent                          | Gap                                                                 |
|------------------------|----------------------------------------------|---------------------------------------------------------------------|
| Story (activity card)  | Conversation + its Wright applets            | Conversations are tiles in a row, not cards in a spatial field      |
| Story cluster (group)  | Nothing explicit                             | No way to group conversations or applets side-by-side               |
| Story bar (title bar)  | Chat tile label + app bar                    | Not draggable, not colored by content                               |
| Suggestion             | Home Idea                                    | Already works; tapping puts prompt in companion                     |
| Suggestion shelf       | Ideas section on home                        | Not a pull-up sheet; not proactive/push                             |
| Now bar                | Companion                                    | Already at the bottom; already has contextual chips                 |
| Conductor              | Nothing explicit                             | Home/Conversation are separate routes; no choreographer             |
| Focus (tap to expand)  | `context.push(kRouteConversation(id))`       | Page navigation, not spatial expand                                 |
| Unfocus (go to origin) | Navigator pop                                | Not a universal reset; no scroll-to-0, no Now-maximize              |
| Wright applet          | Armadillo had nothing like this              | Wright is Telosnex's unique advantage; Armadillo had no code-gen UI |
| Panel mode             | Nothing                                      | Can't view two conversations or two applets side by side            |
| Drag to group          | Nothing                                      | No drag interaction on home screen at all                           |
| Inline preview         | Nothing                                      | No hover feedback on cards                                          |
| Juggling (recency)     | Chats sorted by modified date                | Same data; not expressed spatially (size, prominence)               |

---

## The Design

### One Surface, Not Two Screens

Kill the push navigation to ConversationScreen. Home and Conversation are no
longer separate routes. They are states of one surface, orchestrated by a
Conductor.

The surface has three layers, bottom to top:

1. **Wallpaper** — already exists, stays the same
2. **The Field** — conversations and applets as cards in a spatial layout
3. **Companion** — the input bar, pinned to bottom, already exists

The Field replaces both HomeChats, HomeIdeas, and ConversationScreen.

### The Field: Cards on a Desk

Every conversation is a **card** in the Field. Cards are arranged in a
scrollable, staggered layout — not a horizontal row or a vertical list, but a
responsive grid that adapts to screen size (same multi-column logic Armadillo
used: single column below 500dp, multi-column above).

**Card size reflects recency and engagement:**
- Conversations you've been actively using (messages in the last 2 hours)
  are larger — Armadillo's juggling algorithm, applied to conversations
- Conversations you haven't touched in days are smaller
- Starred conversations get a size bonus

**Card content is a live preview, not a label:**
- Each card shows a *live thumbnail* of its last visible state — the last
  message, the last Wright applet's rendered UI, the last art output
- This is not a screenshot. It's the actual widget tree, clipped and scaled
- For conversations with active Wright applets, the applet is *running* in
  the thumbnail — buttons work, state updates
- Wright content adapts to the card's available size via generic layout rules
  (see mondrian_debrief.md "The System Should Handle This, Not the AI").
  Rows wrap, text scales, low-priority children elide. The Lua author writes
  one render function; the system makes it fit.

### Focus: Tap to Expand

Tapping a card expands it to fill the screen. This is Armadillo's focus
mechanic:

1. The card springs from its Field position to full screen
2. Sibling cards fade/scale away
3. Companion stays at the bottom (it was always there)
4. The conversation's message list is now visible and scrollable
5. Field scrolling locks

This replaces `context.push(kRouteConversation(id))` with an animated state
change. The conversation doesn't "open" — it *zooms in*.

### Unfocus: Go to Origin

The universal reset gesture. Any of:
- Drag focused card to top or bottom edge
- Tap the Companion's FAB when already at scroll bottom
- Swipe down from the top of a focused conversation
- Keyboard shortcut (Cmd+Shift+H or equivalent)

Go to origin:
1. Unfocuses any focused card (shrinks it back)
2. Unlocks Field scrolling
3. Scrolls Field to 0
4. Triggers Ideas refresh if stale
5. Peeks the suggestion shelf

### Ideas Become the Suggestion Shelf

Ideas move from a staggered grid embedded in the scroll to a **pull-up shelf**
behind the Companion. Identical to Armadillo's suggestion overlay:

- **Peek**: a 28dp sliver of the first suggestion visible above Companion at
  rest
- **Pull up**: overscroll the Field (drag past the last card) or drag up on
  Companion to open the shelf
- **Snap**: fling up → open, fling down → close, release near middle → snap
  to nearest
- **Search/Ask**: typing in Companion while the shelf is open filters/re-
  generates ideas based on the prompt
- **Interruptions**: ideas with high confidence push themselves as a floating
  card that slides up from the bottom (auto-dismiss after 3.5s, swipe to
  dismiss, tap to act)

Selecting an idea still copies its prompt to Companion. But now it can also
trigger the Armadillo **expand animation**: the idea card grows to fill the
screen, its content fades out, and the new conversation appears behind it.
Or the **splash animation** for more dramatic launches.

### Wright Applets as First-Class Cards

This is where Telosnex goes beyond Armadillo.

Wright applets can be **promoted to cards**. When a Wright applet is useful
enough to live on its own — a dashboard, a tool, a game — the user can drag
it out of a conversation and into the Field.

A promoted Wright applet:
- Has its own card in the Field
- Shows its rendered UI as the card's live preview
- Can be focused independently (fills the screen)
- Retains its Lua state (already cached in LRU)
- Can be **grouped** with a conversation (see below)

This is the killer feature. Armadillo only had "activities" which were opaque
surfaces from other apps. Telosnex's activities are *generated by the AI and
fully interactive*.

### Grouping: Panels and Tabs

From Armadillo, directly:

**Drop one card onto another** to create a group. Groups display in two modes:

**Tab mode**: one conversation/applet visible at a time. Tabs are thin colored
bars across the top. Tap to switch. Good for phone-sized screens.

**Panel mode**: all members visible simultaneously, tiled. Good for tablets and
laptops. Panels are resizable by dragging the seam between them.

Where you drop determines the mode:
- Drop on the top strip (story bar area) → tabs
- Drop on an edge → panels, with the new item on that edge

**Why this matters for Telosnex specifically:**

A user asks the AI to build a dashboard (Wright applet). The AI also generates
some analysis in the same conversation. The user drags the Wright applet card
out of the conversation, then drops it next to the conversation card to create
a side-by-side panel group: conversation on the left, live dashboard on the
right.

Now they can keep chatting with the AI while watching the dashboard update in
real time. This is the spatial multitasking Armadillo envisioned, but with
AI-generated content instead of static apps.

### The Conductor

A single state machine that coordinates everything. Maps gestures to
shell-wide transitions:

| Input                                    | Conductor Action                                                           |
|------------------------------------------|----------------------------------------------------------------------------|
| Tap a card                               | Focus card, lock Field scroll, animate expansion                           |
| Go-to-origin gesture                     | Unfocus all, unlock scroll, reset to 0, refresh ideas, peek shelf          |
| Overscroll past last card                | Open suggestion shelf                                                      |
| Drag up on Companion                     | Open suggestion shelf                                                      |
| Long-press + drag a card                 | Card lifts at 80%, follows finger, drop targets activate                   |
| Drop card on another card                | Merge into group (tab or panel based on drop zone)                         |
| Drop card on empty space                 | Card becomes standalone again                                              |
| Fling card fast enough                   | Delete/archive conversation                                                |
| Tap an idea                              | Copy prompt to Companion, optionally expand-animate new conversation       |
| Interruption appears                     | Slide up from bottom, auto-dismiss after 3.5s                              |
| Companion prompt changes while shelf open| Re-generate ideas based on prompt                                          |
| Scroll Field down a little               | Fade datetime header                                                       |
| Scroll Field down a lot                  | Shrink Companion to minimal state                                          |

### DateTime Header

Keeps its current behavior: fixed behind the Field, visible when scrolled to
top, fades as you scroll down. The hit-test passthrough logic already works.
No changes needed.

### Companion Stays Companion

The Companion widget barely changes. It already:
- Lives at the bottom of both screens
- Has contextual chips that appear/disappear based on state
- Adapts to left/right handedness
- Hero-animates between contexts

The only changes:
- **Pull-up gesture** on Companion opens the suggestion shelf (replaces the
  current up/down arrows)
- **Minimal state**: when scrolled far down, Companion shrinks to just the FAB
  and a thin text indicator (like Armadillo's minimized Now bar)
- **Tap minimized Companion → go to origin**
- **Input routing**: when no card is focused, Companion input creates a new
  conversation. When a card is focused, Companion input goes to that
  conversation. This replaces the current behavior where the same Companion
  widget lives on two separate screens — now it's one widget whose target
  changes based on Conductor state.

### The Conversation App Bar Goes Away

Today, ConversationScreen has an app bar: back button, conversation title,
star toggle, overflow menu. In the merged world there is no app bar.

Those controls move to the **story bar** — the colored title bar at the top of
each card (from Armadillo). When a card is focused:
- Story bar shows the conversation title
- Tap the star icon in the story bar to toggle star
- Overflow menu lives in the story bar
- Dragging the story bar down is the "go to origin" gesture (replaces the
  back button)

This unifies the conversation chrome with the card chrome. One bar, not two
separate navigation paradigms.

### What Gets Cut

- `HomeChats` horizontal row → replaced by the Field
- `HomeIdeas` staggered grid → replaced by the suggestion shelf
- `HomeInnerColumn` → gone, Field is the inner content
- `HomeScrollableOverlay` → greatly simplified, becomes the Field's scroll view
- `_BlankSpaceWidget` (the invisible spacer that pushes content to the bottom
  of the viewport) → gone, the Field fills the screen
- `ConversationScreen` as a separate route → becomes a focused state of a card
- The up/down scroll arrows → replaced by the suggestion shelf peek gesture
- `Mod` widget (the horizontal-scrolling-with-header container) → cards don't
  need a container type; they *are* the layout
- `ConversationAppBar` → replaced by the story bar on each card
- All `context.push(kRouteConversation(id))` calls (in HomeChats new button,
  tile tap, HomeIdeas view-chat chip) → become Conductor focus actions

### What Stays

- `Home` shell structure (wallpaper + positioned layers as a Stack)
- `HomeDateTime` (header behind content)
- `Companion` (bottom input bar) — including all ~20 contextual chips in
  CompanionHeader, which already show/hide based on state not screen
- `CompanionFooter` content-behind detection (tracks if scrollable content
  extends below the footer) — same logic, applied to Field scrolling
- `Companion.fullBottomPadding` calculation — Field needs the same padding
  so cards aren't covered by Companion
- `companionConversationIdProvider` — currently overridden per
  ConversationScreen, in the merged world set by Conductor based on
  focused card ID
- `WrightWidget` (Lua applet engine)
- `WrightWidget.cache` LRU(32) — needs new cache key pattern for promoted
  Wright cards not inside a conversation step
- `RenderUi` (JSON → Flutter widget renderer) — already handles wallpaper-
  adaptive colors for `.noBackground` mode by measuring screen position and
  deriving colors from the wallpaper region beneath. Wright cards in the
  Field sitting on wallpaper already get correct text colors.
- `ConversationListView` (message list inside a focused card)
- `LoomTile` hierarchy (all message types)
- All providers and state management
- Wallpaper and theming systems
- Hit-test passthrough for DateTime
- `HomeIdeas.maybeForceIdeasRefresh` 5-minute cooldown and auto-scheduling
  — drives suggestion shelf refresh timing

---

## Implementation Phases

### Phase 1: The Field (Replace HomeChats + HomeIdeas Layout)

Replace `HomeInnerColumn` with a `Field` widget that lays out conversation
cards in a staggered multi-column grid using Armadillo's `StoryListLayout`
logic:

- Juggling algorithm based on `modifiedAt` and star status
- Multi-column above 500dp, single column below
- Card aspect ratios adapt to screen dimensions
- Each card renders a `ConversationCardPreview` — the last visible message
  or Wright applet, clipped to the card bounds

This is purely layout. No new interactions. Chats and Ideas remain distinct
sections but use the new card visual language.

### Phase 2: Focus/Unfocus (Kill the Route Push)

Replace `context.push(kRouteConversation(id))` with an animated focus
transition:

- `AnimatedContainer` / `Hero`-like transition from card bounds to full screen
- Focused state renders `ConversationListView` inside the expanded card
- Go-to-origin gesture unfocuses
- Companion persists across the transition (it's already in the same Stack)

The Conductor is introduced as a `ChangeNotifier` or Riverpod provider that
holds `focusedCardId`, `isShelfOpen`, `fieldScrollOffset` and drives all
transitions.

### Phase 3: Suggestion Shelf (Move Ideas Behind Companion)

Extract Ideas from the Field scroll into a pull-up overlay behind Companion:

- `PeekingOverlay` from Armadillo adapted for Telosnex's spring constants
- Ideas rendered inside the overlay
- Overscroll and drag-up gestures open it
- Interruptions: high-confidence ideas push as floating cards

### Phase 4: Promoted Wright Applets

Allow Wright applets to be promoted to standalone cards in the Field:

- Long-press a Wright applet within a conversation → "Promote to Card"
- Creates a new Field card that wraps the `WrightWidget` with its cached
  state
- The card is independently focusable

### Phase 5: Grouping (Drag to Compose)

Implement Armadillo's grouping mechanic:

- Long-press drag a card in the Field
- Drop targets appear on other cards (edges for panels, top bar for tabs)
- Groups render as tab or panel mode within a single card
- Panel resizing via seam drag

This is the most complex phase and can be deferred. Phases 1–3 already
deliver a radically different experience.

---

## What Makes This Different From Just Copying Armadillo

Armadillo's cards were **opaque app surfaces**. The system couldn't see inside
them. It could arrange them spatially but couldn't understand or generate
their content.

Telosnex's cards are **AI-generated, fully introspectable, and editable**:

- The AI builds the Wright applet → the user sees its live UI in the Field
- The user focuses the applet → full-screen interactive experience
- The user says "Edit with AI: add a filter by date" → the Lua is rewritten
  in-place
- The user groups the applet with its parent conversation → side-by-side
  panel showing the chat and the live dashboard

Armadillo was a spatial shell for dumb rectangles.
This is a spatial shell for intelligent, self-modifying surfaces.

---

## What the Document Was Missing: Not Every Card Wants Full Screen

The design above treats every card the same way: tap → expand to full screen.
But a weather Wright applet doesn't want full screen. A timer doesn't. A
music control doesn't. They're small, self-contained, useful at their
natural size.

The fix is not a separate "widget layer" — in an Armadillo-style Field, the
cards fill the viewport and there's no wallpaper real estate sitting around
empty. The fix is that **cards have different focus behaviors**.

### Card Focus Modes

Every card in the Field is still a card. It participates in the same layout,
the same juggling, the same grouping system. But when you tap it, what
happens depends on the card:

#### Full Focus (conversations, dashboards, editors)

What the document already describes. The card springs to fill the screen.
You're now inside it. Go-to-origin to leave. This is the default for
conversations and large Wright applets.

#### Inline Focus (weather, timers, small tools)

The card **stays in the Field** but expands slightly in place — maybe 1.5×
its resting size — to show more detail or enable interaction. Sibling cards
nudge aside to make room. The Field is still visible around it. Tapping
outside or tapping the card again collapses it back.

Think of it like Armadillo's inline preview, but as the *primary* interaction
rather than a hover preview. The card doesn't take over the screen because
it doesn't need to.

#### No Focus (pure glanceable)

The card is interactive at its resting size in the Field. Buttons work.
The refresh button refreshes. Nothing expands. You never "enter" it.

This is already how Wright applets work inside conversations today — the
buttons in the weather demo work without expanding anything. The same
behavior, but the card is in the Field instead of inside a conversation
message list.

### How the System Knows Which Mode

Two signals:

**1. The Wright applet declares it.** The Lua `render()` return includes a
focus hint:

```lua
function render(state)
  return {
    type = "Column",
    focusMode = "inline",  -- "full" | "inline" | "none"
    children = { ... }
  }
end
```

- `"full"` — default for conversations, expands to fill screen
- `"inline"` — expands in place within the Field
- `"none"` — interactive at resting size, never expands
- Absent — system defaults based on card type (conversation = full,
  promoted Wright = inline)

**2. The card's content size implies it.** A card whose rendered content is
a single temperature reading and a refresh button is obviously not a
full-screen experience. The system could infer focus mode from the rendered
widget tree's intrinsic size vs. the available screen size, without
requiring the Lua to declare anything.

### What This Changes in the Design

Very little. The Field layout is the same. Grouping is the same. The
suggestion shelf is the same. The Conductor just needs to know that "tap
a card" dispatches to one of three behaviors instead of always doing full
focus.

The Conductor table gains nuance:

| Input                     | Card Focus Mode | Conductor Action                                           |
|---------------------------|----------------|------------------------------------------------------------|
| Tap a card                | full           | Focus card, lock Field scroll, animate expansion           |
| Tap a card                | inline         | Expand card in place, nudge siblings, Field still scrolls  |
| Tap a card                | none           | Nothing (card is already interactive)                      |
| Tap outside inline card   | inline         | Collapse card back to resting size                         |
| Go-to-origin              | any            | Collapse any inline cards, unfocus any full cards, reset   |

### What This Means for the Weather Example

1. User asks AI for weather → conversation with Wright applet
2. User promotes the Wright applet to the Field as a card
3. The weather Lua declares `focusMode = "inline"` (or the system infers it
   from the small content size)
4. The weather card sits in the Field, same juggling as everything else, sized
   by recency
5. At its resting size, it shows "72° ☀️" — the render function already
   handles this, it's just text
6. The refresh button works at resting size (focus mode "none" behavior for
   buttons within any card)
7. Tapping the card expands it inline to show the hourly forecast — still in
   the Field, siblings nudge aside
8. Tapping again or tapping outside collapses it

No separate widget layer. No wallpaper positioning system. No new persistence
model. It's a card in the Field that happens to not want full screen.

### Small Cards Still Participate in Everything

This is the important part. A weather card can still be:
- **Grouped** with a conversation via drag-and-drop (panel mode: weather on
  the right, chat on the left)
- **Juggled** by recency (if you check weather constantly, it gets bigger)
- **Dragged** to reorder in the Field
- **Flung** to dismiss
- **Shown as a tab** in a group with other cards

It's a full citizen of the Field. It just has a different answer to "what
happens when you tap me."

---

## Composition: Multiple Wrights, One Card

### The Problem

You have three Wright applets: weather, deliveries today, and a map. On a
phone, Armadillo gives you three options, all bad:

1. **Three separate cards** — too many cards, too much scrolling, you wanted
   one glance not three taps
2. **Three tabs in a group** — can only see one at a time, defeats the purpose
3. **Three panels in a group** — phone can only fit 1 column × 2 rows max,
   so one gets cut

What you actually want: one card that shows weather at the top, deliveries in
the middle, map at the bottom. One thing in the Field. One tap to interact.

### Solution A: The AI Composes a Single Wright

This already works today. A single Lua script calls three APIs and returns
one widget tree:

```lua
function render(state)
  return {
    type = "Column",
    children = {
      weather_section(state),
      deliveries_section(state),
      map_section(state),
    }
  }
end
```

One script, one state, one card. The AI can generate this if you ask "show me
weather, deliveries, and my commute." The Ideas agent could generate it
proactively as a "morning briefing."

This is the simplest path. No new system needed. But it has a limitation: the
three concerns are fused into one Lua script. If you want to swap out the
weather section for a different one, or add a fourth section, you're editing
one monolithic script.

### Solution B: Composed Cards

The system allows **multiple independent Wright applets to render as sections
of one card**. Each applet has its own `init/render/on_event` cycle, its own
state, its own cache key. But they share a card in the Field.

A composed card is a lightweight container that lays out N Wright applets in a
Column (phone) or Grid (tablet). Each applet is independent — weather can
refresh without touching deliveries. One crashes, the others keep running.

How a composed card is created:
- The AI generates it as a tool response: instead of one `applet` tool call
  with one big script, it emits a `composed_applet` call with N scripts
- The user drags a Wright card onto another Wright card, and instead of
  Armadillo-style tab/panel grouping, the system merges them into one
  composed card (because they're both small, not conversations)
- The user says "combine my weather and deliveries widgets" and the AI
  restructures them

How it renders:
- Each section gets a proportional slice of the card's height
- On a wide screen, sections can be arranged in a Grid (2 columns)
- On a narrow screen, sections stack in a Column
- Each section has a thin divider or subtle header showing its name
- Each section handles its own events independently

How it differs from Armadillo panel mode:
- Armadillo panels were rigid rectangles in a tiling grid with minimum sizes
  (300dp × 300dp) and draggable seams
- Composed card sections are **flowing** — they take whatever height their
  content needs, like items in a Column. No minimum size. No seam dragging.
  The weather section is 80dp tall, deliveries is 120dp, the map is 200dp.
  They're not fighting over a fixed grid.

### Solution C: The AI Does Both, Contextually

The right answer is probably: the AI picks the right approach depending on
what it's building.

- Building a morning briefing from scratch? → Solution A. One script that
  composes everything. Tightest integration, shared state (the map can show
  delivery locations).
- User has three existing standalone Wright applets and wants them together?
  → Solution B. Compose the existing applets without rewriting them.
- User groups a conversation card with a Wright card? → Armadillo-style
  panels. Different types of content need the rigid panel layout.

The system supports all three. The AI chooses. The user can override.

### What This Changes in the Design

The Field gains a new card type alongside "conversation" and "promoted
Wright":

- **Conversation card** — focuses full screen, shows message list
- **Wright card** — single Wright applet, focus depends on focusMode
- **Composed card** — N Wright applets in a flowing layout, inline or no
  focus by default (the whole point is glanceability)

The Conductor table gains:

| Input                                    | Conductor Action                                         |
|------------------------------------------|----------------------------------------------------------|
| Drop small Wright card onto small Wright | Merge into composed card (flowing Column, not rigid panel)|
| Drop conversation onto anything          | Armadillo-style group (tabs or panels)                   |
| AI emits `composed_applet`               | Create composed card directly in Field                   |
| Long-press section in composed card      | Option to detach as standalone card                      |

### The Morning Briefing, End to End

1. 7:00 AM. Ideas agent runs. Sees your delivery tracking conversation from
   yesterday, the weather you asked about last week, your calendar.
2. Agent generates an idea: "Morning briefing — weather, 2 deliveries today,
   30 min commute"
3. Idea appears as an interruption (floating card, slides up from bottom)
4. User taps it. The AI generates a composed card (or a single composed
   Wright) with three sections.
5. The card appears in the Field. At its resting juggling size, you see:
   - ☀️ 72° (weather, 1 line)
   - 📦 2 deliveries arriving by 3 PM (deliveries, 1 line)
   - 🚗 30 min to work (map, 1 line)
6. Tapping the card does inline focus — expands in the Field to show the full
   weather forecast, delivery tracking details, and a small map.
7. Tomorrow the agent generates a new briefing. The card updates. You never
   asked for it, never configured it, never dragged anything.

This is what Armadillo couldn't do. The shell didn't know what was inside its
cards. It couldn't compose them. It couldn't generate new ones proactively.
It could only arrange opaque rectangles that apps provided.

Telosnex generates the content AND arranges it. That's the difference.
