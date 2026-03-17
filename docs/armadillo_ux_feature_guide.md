# Armadillo: Every Feature, Explained for a Designer

This document explains every intended feature in Armadillo from a product/UX
perspective. No engineering jargon. Written from source code, not speculation.

---

## The Big Idea

Armadillo is a **home screen** for a device. Not an app. Not a launcher. The
entire screen is Armadillo, all the time.

It has four layers, stacked bottom to top:

1. **Wallpaper** — a photo background that changes based on where you are
2. **Recents** — your recent activities, shown as cards
3. **Now bar** — your identity and status, always at the bottom
4. **Suggestions** — a shelf of "what you could do next" that peeks up from behind Now

One thing — the **Conductor** — decides which layer gets attention at any
moment. All transitions between layers are continuous (spring-animated), never
jump-cuts.

---

## Layer 1: Wallpaper

A full-bleed photo behind everything. The original demo had three wallpapers:
- `aparna-home.jpg` — shown when the system detected you were at home
- `aparna-work.jpg` — shown when at work
- `aparna-sf.jpg` — shown in an unknown/transit location

The wallpaper changed automatically based on system context (wifi network,
location). You never picked it manually; the device "knew" where you were.

---

## Layer 2: Recents (the card field)

This is the most distinctive part of Armadillo. Your recent activities are
shown as **cards** floating in a scrollable field. Think of it as a desk
covered in papers, where the ones you've used recently are bigger and closer.

### Cards are sized by how much you've used them

Recently and heavily used cards are **larger**. Cards you haven't touched in a
while **shrink**. The system calls this "juggling" — if you've been switching
between 2–3 things in the last two hours, those cards get the most space.

Specifically:
- Cards used in the last **2 hours** are "juggling" — they get up to 30% bigger
- The most recent 4 juggling cards get the biggest boost
- Cards further back are progressively smaller
- The field is staggered, not a rigid grid — rows offset vertically for a
  natural, organic feel

### Cards are arranged in a scrollable field, not a list

On a wide screen, cards arrange into **multiple columns** with staggered rows.
On a narrow screen, they collapse to a **single column**. The breakpoint is
500dp wide.

In multi-column mode:
- Cards are organized in rows of 2–3
- Rows are staggered vertically (not grid-aligned) for a more organic feel
- The whole field scrolls vertically
- Older cards are further up (you scroll up to find old things)

### Each card has a title below it

Below each card is a small text label (20px tall) showing the card's name.
When you tap to focus a card, the title fades away as the card expands.

### Tapping a card focuses it

Tapping a card makes it expand to fill the screen. This is called **focus**.
When a card focuses:

1. The card smoothly expands from its recents size to full screen
2. Sibling cards fade and slide away cinematically
3. The Now bar minimizes to a thin strip at the bottom
4. The suggestions shelf hides
5. Scrolling locks — you can't scroll recents while focused
6. The scroll position resets to 0 behind the scenes (so when you unfocus,
   everything is clean)

### Unfocusing returns to the recents view

Dragging a focused card to the top or bottom edge of the screen triggers
**go to origin** — the universal "take me home" gesture. This:

1. Unfocuses the card (it shrinks back to its recents size)
2. Unlocks scrolling
3. Maximizes the Now bar
4. Resets scroll to the beginning
5. Peeks the suggestion shelf

### Long-press to drag a card

Long-pressing a card (not tapping) starts a **drag**. The card lifts up,
shrinks to 80% size, and follows your finger. While dragging:

- You can drop it onto another card to **group** them
- You can drag it to screen edges to auto-scroll the list
- You can fling it to dismiss/delete it

### Cards can be grouped together

This is the deepest feature. When you drop one card onto another, they
**combine into a group**. A group is a single card in the recents field that
contains multiple activities inside it.

Groups can be viewed in two modes:

#### Tab mode
Activities within the group appear as **tabs** — small colored bars across
the top of the card. Tapping a tab switches which activity is visible. Only
one activity shows at a time. The focused tab is slightly elevated (like a
real browser tab). If `_kGrowFocusedTab` is on, the focused tab gets double
width.

#### Panel mode
Activities within the group appear **simultaneously** as panels — a grid of
panes within the card. Think of it like a split-screen view inside one card.

Panels are arranged on a virtual 10,000 × 10,000 grid (for precision). The
system enforces:
- Minimum **300dp** width per panel
- Minimum **300dp** height per panel
- Maximum **3 columns** in landscape, 2 in portrait
- Maximum **3 rows** in portrait, 2 in landscape

Panels must tile perfectly — no gaps, no overlaps.

### You can resize panels by dragging the seams

When a group is focused and in panel mode, the **seams** between panels become
draggable. Grab the border between two panels and drag horizontally or
vertically to resize them. The system enforces minimums so you can't crush a
panel to nothing.

### You can drag a tab out of a group to un-group it

When a group is focused, each tab has its own **drag handle** (the story bar
at the top). Long-press a tab's bar to drag it out. When you pull it away:

1. The dragged activity becomes its own card again
2. A **placeholder** ghost appears in the original group showing where it was
3. The drag feedback shows a preview of what the layout would look like if
   you drop it somewhere else
4. If you drop it back, it returns to its original position
5. If you drop it on empty space, it becomes a standalone card
6. If you drop it on a different card, it joins that group instead

### Where you drop within a group matters

When you drag a card over a group, **drop targets** appear. These are
invisible zones within the card that determine where the new activity lands:

- **Top edge** — add as a new row above all panels
- **Bottom edge** — add as a new row below all panels
- **Left edge** — add as a new column to the left
- **Right edge** — add as a new column to the right
- **Top/bottom/left/right of a specific panel** — split that panel and add
  adjacent to it
- **Story bar area** — add as a new tab (switches group to tab mode)

The system analyzes your drag **direction** and **velocity** to pick the most
likely intended target. If you drag downward toward the bottom edge, bottom
targets get priority. The system also locks onto targets to prevent jitter.

### Inline preview: hovering shows what will happen

When you hold a card over another card for 400ms in the recents view (not
focused), the target card **scales up slightly** to show a preview of what
the grouped layout would look like. This is called **inline preview**.

There are two stages:
1. **Hint** (before 400ms) — a subtle scale-up to acknowledge the hover
2. **Full preview** (after 400ms) — the target accepts the card and shows
   the actual panel layout

### Auto-scrolling when dragging near edges

When you drag a card near the top or bottom 13% of the screen, the recents
list auto-scrolls in that direction. The closer to the edge, the faster it
scrolls. Named after "Kenichi" (presumably the engineer who tuned it), it uses
acceleration with friction so the scroll feels physical — it ramps up, and
when you move away from the edge, it decelerates smoothly instead of stopping
abruptly.

### Story bars (the colored title bar on each activity)

Each activity has a thin colored bar at the top showing its title (and
optionally icons). The bar's color is the activity's **theme color**.

Story bars have three states:
1. **Maximized** — full height (48dp), shows title and icons, used when focused
2. **Minimized** — thin strip (4dp), just a color accent, used in recents
3. **Hidden** — 0 height, used when you start interacting with a focused
   single-panel card (swipe down from top to bring it back)

The text color automatically adapts — white text on dark bars, black text on
light bars — using the W3C color contrast algorithm.

### Small screens hide the story bar automatically

When the screen is too small for panels (only 1 row and 1 column fits), the
story bar automatically hides when you start interacting with a focused card.
A drag-down from the top edge brings it back. This maximizes content space on
small devices.

---

## Layer 3: The Now Bar

The Now bar sits at the bottom of the screen, always visible. It represents
**you and your current moment**.

### Maximized state

When you're browsing recents (nothing focused), the Now bar is large:
- **Your photo** (a circular avatar)
- **Date and time**
- **Location context** (e.g. "Mountain View" or "Work")
- **Battery level** and **wifi status**

Tapping the avatar opens **Quick Settings** — a panel with:
- Wifi toggle
- Timezone picker
- Logout button
- Clear data button

### Minimized state

When you focus a card or scroll down far enough, the Now bar shrinks to a thin
strip at the bottom (like a dock). It still shows:
- A small avatar
- Truncated context info
- Battery/wifi icons

### Tapping the minimized bar goes home

Tapping the center of the minimized Now bar triggers **go to origin** — the
universal home gesture. Everything unfocuses, recents scroll resets, Now
maximizes, suggestions peek.

### Dragging up on the minimized bar opens suggestions

Vertical drag on the minimized bar controls the suggestion shelf. Drag up to
pull suggestions into view, release to snap open or closed.

### Now bar responds to scroll

As you scroll through recents:
- Scroll past **16dp** → quick settings hide
- Scroll past **120dp** → Now bar minimizes
- Scroll back up past that threshold → Now bar maximizes again

This is continuous — the Now bar doesn't jump between states, it eases.

### The Now bar grows when you overscroll

If you overscroll past the bottom of the recents list (pulling down), the Now
bar grows taller proportionally. This gives a stretchy, physical feel and also
serves as the trigger for opening suggestions.

---

## Layer 4: Suggestions

The suggestion shelf is a surface that lives behind the Now bar and can be
pulled up to reveal **things the system thinks you might want to do next**.

### The shelf peeks

When the Now bar is maximized, the suggestion shelf **peeks** — a tiny sliver
(28dp) is visible just above the Now bar, hinting that there's more below.

### Pull up to open

Overscrolling the recents list (pulling down past the end) or dragging up on
the Now bar opens the suggestion shelf. It springs up to fill most of the
screen. A dark scrim appears behind it. Tapping the scrim closes it.

### Snap behavior

If you drag the shelf partway and release:
- Fling upward (> 500dp/s) → snaps open
- Fling downward (> 500dp/s) → snaps closed
- Release near the middle → snaps to whichever state is closer

### Ask bar (search)

At the top of the suggestion shelf is a text input field. Typing changes the
suggestions from contextual ("next" suggestions) to query-based ("ask"
suggestions). The original demo supported queries like:
- `demo` — showed a curated set of demo suggestions
- `launch perspective` — launched the perspective demo app
- `launch infinite` — launched the infinite scroller

### Suggestion cards

Each suggestion is a white card with:
- **Headline** (e.g., "It's Danielle's Birthday")
- **Subheadline** (optional, e.g., "View photos")
- **Theme color** (used for accents and the selection animation)
- **Image** — either a large image on one side, or a circular person photo
- **Icons** — small app icons

Images can be displayed on the left (for person photos, circular) or right
(for article/location photos, rectangular). The layout automatically chooses
based on image type.

Suggestion cards are arranged in a **responsive grid**:
- Narrow screens: 1 column
- Medium screens: 2 columns
- Wide screens: 3 columns

### Two types of suggestion selection

When you tap a suggestion, one of two animations plays:

#### Expand
The card **grows from its position** to fill the entire screen (minus the Now
bar). As it expands, its content fades out and the launched activity fades in
behind. Used for launching a new activity.

#### Splash
The card stays in place while a **circle of color** (the suggestion's theme
color) radiates outward from the card's center to fill the entire screen. Then
a hole opens from the center, revealing the activity behind. Used for more
dramatic transitions (like launching a media experience).

### Interruptions (proactive suggestions)

The system can push suggestions to you even when you haven't opened the shelf.
These appear as a **floating card** that slides up from the bottom of the
screen.

Interruptions:
- Appear for **3.5 seconds**, then auto-dismiss downward
- Can be **swiped left** to discard
- Can be **swiped down** to snooze (dismiss gently)
- Can be **tapped** to select (triggers the expand/splash animation)
- Are draggable with **resistance** — dragging right or upward feels
  springy/resisted, dragging left or down feels natural
- Queue — if multiple interruptions arrive, they show one at a time
- Fade in with a 300ms animated opacity

### Contextual suggestions change based on where you are

The original system served different suggestions based on context:

**Unknown location:**
- "It's Danielle's Birthday"
- "17 min drive to Calafia"
- "Play Good Vibes Playlist"
- "Launch Fuchsia Dashboard"

**At work:**
- "View Expenses — Your June report has been approved"
- "Simon shared 'Toe the Line Analytics' with you"
- "Flux Weekly Sync starts in 25 minutes"

**At home:**
- "See movies playing near me"
- "New Episode for Three Peaks available"
- "Continue reading OverThrough Magazine"

---

## The Conductor (the invisible choreographer)

None of the above layers work independently. The **Conductor** is the invisible
system that coordinates all of them. It's not a visible feature — it's the
logic that makes the visible features feel like one coherent experience.

The Conductor translates gestures into **shell-wide state changes**:

| You do this...                        | The Conductor does this...                                               |
|---------------------------------------|--------------------------------------------------------------------------|
| Scroll recents down a little          | Hides quick settings                                                     |
| Scroll recents down a lot             | Minimizes Now bar, hides suggestions                                     |
| Scroll recents back up                | Maximizes Now bar                                                        |
| Overscroll past the bottom            | Opens suggestion shelf                                                   |
| Tap a card                            | Focuses card, minimizes Now, locks scroll, hides suggestions             |
| Drag card to top/bottom edge          | **Go to origin**: unfocus all, unlock scroll, maximize Now, peek suggestions, scroll to top |
| Tap minimized Now bar center          | **Go to origin**                                                         |
| Drag up on minimized Now bar          | Opens suggestion shelf                                                   |
| Tap minimized Now bar left/right      | Opens suggestion shelf                                                   |
| Tap suggestion card                   | Expand/splash animation, minimize Now, focus launched story              |
| Long-press + drag a card              | Card lifts, shrinks to 80%, follows finger, drop targets activate        |
| Drop card on another card             | Cards merge into a group                                                 |
| Start interacting with focused card   | Story bar hides (on small screens)                                       |
| Swipe down from top of focused card   | Story bar reappears                                                      |

The most important gesture is **go to origin**. It's not "back." It's not
"home" in the Android sense. It's "return the entire shell to its resting state."
Every surface resets. The desk is cleared. You're back to square one.

---

## Idle Mode (screensaver)

When the device is idle, a large **clock** appears over the wallpaper showing
time and date in a minimal, thin font. This was always offstage in the code
(never fully wired up), but the design intent was a lock-screen-like ambient
display.

---

## Debug Tools

The shell had built-in debug overlays (toggled by a model flag):

- **Target Overlay** — shows all the invisible drop zones as colored lines
  when dragging. Each zone has a distinct color (yellow for edges, blue for
  panel splits, grey for story bars, red for discard zones, green for
  bring-to-front).
- **Target Influence Overlay** — shows which zone your drag position is
  closest to, accounting for direction and distance.

These were designer tools — a way to visualize the complex targeting system
during development.

---

## Summary: What Made This Different

Most of these ideas existed individually in other products. What made Armadillo
unusual was combining them into one system:

1. **Cards sized by usage** — not a static grid, not a simple list
2. **Grouping by drag** — not just launching apps, but composing workspaces
3. **Tabs and panels as two views of the same group** — spatial multitasking
4. **The suggestion shelf** — proactive, contextual, always accessible
5. **The Conductor** — one orchestrator managing all transitions
6. **Go to origin** — a single gesture that resets everything
7. **Spring physics everywhere** — nothing snaps, everything settles

The design bet was: **a device that helps you juggle multiple things
simultaneously, with an intelligent surface suggesting what to do next, would
feel fundamentally different from app-at-a-time mobile OS design.**

Whether that bet would have paid off is unknowable — the project was cancelled
before shipping. But the machinery for it was real, detailed, and surprisingly
complete.

---

## How Everything Adapts to Screen Size

Armadillo has no single breakpoint. Almost every dimension in the system is a
continuous function of screen width and height. Here's every adaptation, with
exact thresholds.

### Form Factor (drives Now bar, suggestions, ask bar)

Determined by **screen height**:

| Height      | Form factor      | Now bar (min) | Suggestion peek | Ask bar |
|-------------|------------------|---------------|-----------------|---------|
| > 640dp     | Tablet           | 48dp          | 220dp           | 72dp    |
| 361–640dp   | Phone portrait   | 48dp          | 140dp           | 72dp    |
| ≤ 360dp     | Phone landscape  | 32dp          | 80dp            | 56dp    |

The Now bar maximized height is always `220dp + suggestion peek`. So on a
tablet, maximized Now is 440dp; on a landscape phone it's 300dp.

### Recents: Single Column vs Multi-Column

Determined by **screen width**:

| Width       | Layout         | Behavior                                        |
|-------------|----------------|-------------------------------------------------|
| < 500dp     | Single column  | Cards stretch to full width, stacked vertically  |
| ≥ 500dp     | Multi-column   | Cards arranged in rows of 2–3, staggered         |

In single column mode, every card is the same width (`screenWidth − 16dp`
margins). Height is always half the width.

In multi-column mode, card width is `(minRowWidth − gap) / 2`, where:
- `minRowWidth = screenWidth × max(0.5, 1 − (width−500)/1600) − 16`
- Cards get proportionally narrower on wider screens
- `gap` starts at 24dp and grows with screen width (see below)

### Grid Spacing (the invisible rhythm)

The spacing between cards adapts continuously:

| Screen width | Horizontal grid | Vertical grid | Horizontal gap |
|--------------|-----------------|---------------|----------------|
| 500dp        | 24dp            | 12dp          | 24dp           |
| 750dp        | 32dp            | 16dp          | 32dp           |
| 1000dp       | 40dp            | 20dp          | 40dp           |
| 1500dp       | 48dp            | 24dp          | 48dp           |

Formula: `baseHorizontalGrid = 24 + floor((width−500)/250) × 8`

This is why the recents field feels more spacious on bigger screens — the
rhythm literally opens up.

### Juggling Emphasis (bigger screens amplify recency)

Within a row of cards, the system exaggerates the size difference between
heavily-used and lightly-used cards. This scaling factor is:

| Screen width | Intra-row scaling |
|--------------|-------------------|
| 500dp        | 0% (all equal)    |
| 750dp        | 3.6%              |
| 1000dp       | 12%               |
| 1500dp       | 24%               |

On a phone, two cards in the same row are roughly the same size. On a large
tablet, the card you used more is visibly wider.

### Maximum Panels When Grouped (drives split-screen limits)

Determined by **both** width and height:

| Orientation | Max columns          | Max rows             | Max simultaneous |
|-------------|----------------------|----------------------|------------------|
| Landscape   | min(⌊w/300⌋, 3)     | min(⌊h/300⌋, 2)     | up to 6          |
| Portrait    | min(⌊w/300⌋, 2)     | min(⌊h/300⌋, 3)     | up to 6          |

Examples:
- **Phone (375×667)**: 1 col × 2 rows = 2 panels max
- **Small tablet (768×1024)**: 2 col × 2 rows = 4 panels max
- **Laptop (1440×900)**: 3 col × 2 rows = 6 panels max
- **Phone landscape (667×375)**: 2 col × 1 row = 2 panels max

When a card is too small for panels (1×1), the system hides story bars on
interaction and adds a drag-down-from-top gesture to show them again.

### Suggestion Grid Columns

Determined by **suggestion list width** (which is itself derived from screen
width):

| Suggestion list width | Columns | Card arrangement    |
|-----------------------|---------|---------------------|
| ≥ 952dp              | 3       | 3 across, centered  |
| ≥ 640dp              | 2       | 2 across, centered  |
| ≥ 328dp              | 1       | 1 column, centered  |
| < 328dp              | 1       | Cards shrink to fit |

Suggestion cards are always 296dp wide (or narrower if the screen can't fit
296dp + 32dp of margin).

### Suggestion List Width

The suggestion shelf doesn't stretch to fill the screen. It snaps to target
widths:

| Screen width | Suggestion list width | Behavior            |
|--------------|-----------------------|---------------------|
| ≥ 816dp      | 736dp                | Wide, centered       |
| 505–815dp    | 424dp                | Narrow, centered     |
| ≤ 504dp      | Full screen width    | Edge-to-edge         |

The list animates between these widths with a spring when the screen resizes.

### Inline Preview Scale

When you hover a card over another in recents, the target scales up to show a
preview. How much it scales depends on screen size:

| Largest dimension | Preview scale factor |
|-------------------|---------------------|
| 540dp             | 100% (full double)  |
| 1080dp            | 62.5%               |
| 1620dp+           | 50%                 |

Smaller screens get a more dramatic preview; larger screens keep it subtle.

### Story Bar Heights

The colored title bar on each card:

| State      | Height | When                                              |
|------------|--------|---------------------------------------------------|
| Maximized  | 24dp   | Card is focused                                   |
| Minimized  | 4dp    | Card is in recents (thin color accent)             |
| Hidden     | 0dp    | Interacting with focused card on small screen      |

### Card Aspect Ratio

Card height relative to width:

| Mode          | Aspect ratio                                          |
|---------------|-------------------------------------------------------|
| Single column | `width × 0.5` (2:1 landscape)                        |
| Multi-column  | `width × min(10/16, screenH/screenW) × juggling`     |

On a square-ish screen, cards are close to 10:16 (slightly taller than wide).
On a very wide screen, cards squash down to match the screen's own aspect
ratio. This prevents cards from being taller than the viewport.

---

## Non-Obvious Behaviors

Three behaviors that are real and implemented but not obvious from running the
shell:

### Fling to delete

When you long-press drag a card and fling it fast enough vertically (over
2000 dp/s), it is **deleted from the system entirely**. No confirmation dialog.
No undo. Fling hard enough = gone. This applies both to dragging a whole card
from recents and to dragging a single tab's bar out of a focused group. The
velocity threshold is checked at drop time — if you're moving fast enough when
you release, the drop targets are ignored and the card is dismissed.

### The story bar is the only un-group handle

When a group is focused (full-screen), each activity's colored title bar at
the top is independently long-press-draggable. **That is the only way to pull
a story out of a group.** You cannot un-group from the recents view — you must
first tap to focus the group, then long-press one of the tab bars and drag it
out.

From recents, long-press drag always moves the **entire group** as one unit.
The per-story drag handles only appear when focused.

### Tabs vs panels is not a user choice

There is no toggle or menu to switch between tab mode and panel mode. The
system decides based on **where you drop**:

- Drop onto the **story bar area** (top strip) → group becomes **tabs**
- Drop onto an **edge target** (top/bottom/left/right) → group becomes **panels**
- Drop onto a **panel edge** (edge of a specific pane) → stays in **panels**

If a group is currently in panel mode and you drop a new card onto its story
bar, it switches to tab mode. All panels collapse into tabs.

**There is no built-in way to switch from tabs back to panels.** Once a group
is tabbed, the only way to get panel layout back is to drag stories out one by
one and re-drop them onto edge targets. This was a design gap that was never
resolved before the project was cancelled.
