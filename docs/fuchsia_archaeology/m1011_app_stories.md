# How Apps Live in the Armadillo World

User stories for Starbucks, Spotify, and El Pollo Loco — showing how
every piece of the m1011 architecture (stories, modules, suggestions,
entities, links, context, surfaces, Ledger) comes alive.

---

## Starbucks

### Story: "Morning Coffee"

You're at home. It's 7:14 AM. The home_work_agent sees
`context/location = home` and `context/time = morning`. It publishes a
Next proposal:

```json
{
  "id": "starbucks_morning_01",
  "story_name": "morning_coffee",
  "headline": "Order your usual from Starbucks",
  "subheadline": "Grande oat milk latte — ready in 8 min at Hillsdale",
  "color": "0xFF00704A",
  "icon_url": "starbucks_96.png",
  "confidence": 0.85,
  "annoyance": "NONE",
  "affinity": [],
  "display": {
    "image_type": "OTHER"
  },
  "on_selected": [
    {
      "add_module": {
        "module_name": "starbucks_order",
        "intent": {
          "action": "com.starbucks.ORDER",
          "parameters": [
            { "name": "item", "entity_type": "com.starbucks.MenuItem" },
            { "name": "store", "entity_type": "com.fuchsia.location.Geolocation" }
          ]
        },
        "surface_relation": { "arrangement": "NONE" }
      }
    }
  ]
}
```

**What happens when you tap it:**

1. The suggestion expands (expand_suggestion.dart splash animation).
2. The framework creates a new Story named "morning_coffee" in Ledger.
3. The `starbucks_order` module launches inside the story.
4. The module receives the intent, resolves your usual order from its
   own backend, and renders the order confirmation screen.
5. The story appears as a card in the Field — green, Starbucks branded.

### Composing modules within the story

You tap "Customize" on the order. The `starbucks_order` module calls:

```
ModuleContext.AddModuleToStory(
  "customizer",
  Intent { action: "com.starbucks.CUSTOMIZE", parameters: [menuItem] },
  surface_relation: SurfaceRelation {
    arrangement: COPRESENT,
    emphasis: 0.6
  }
)
```

Mondrian receives the surface relation. `copresent_layout.dart` splits
the card: 40% order summary on left, 60% customizer on right. The
customizer module writes changes to a shared Link:

```
Link("order_item").Set('{"size":"venti","milk":"oat","extra_shot":true}')
```

The order module watches the Link and updates the total in real time.

### Paying

You confirm the order. The order module calls:

```
ModuleContext.AddModuleToStory(
  "payment",
  Intent { action: "com.starbucks.PAY" },
  surface_relation: SurfaceRelation {
    arrangement: ONTOP
  }
)
```

ONTOP: the payment module covers the order screen entirely. It shows
Apple Pay / card selection. After payment, it calls
`RemoveSelfFromStory()` and the order module is back, now showing
"Your order is being prepared."

### Drive-time suggestion

You leave the house. Context changes: `location = unknown`,
`activity = driving`. The starbucks agent sees the active story
"morning_coffee" and publishes an Interruption:

```json
{
  "headline": "Your latte is ready",
  "subheadline": "Hillsdale store — 4 min away",
  "annoyance": "PEEK",
  "on_selected": [{ "focus_story": {} }]
}
```

A PEEK toast slides up from the Now bar. Tap it → the morning_coffee
story focuses. The order module now shows pickup instructions with a
map module embedded COPRESENT:

```
AddModuleToStory("pickup_map",
  Intent { action: "com.fuchsia.MAP", parameters: [storeLocation] },
  surface_relation: { arrangement: COPRESENT, emphasis: 0.5 }
)
```

Two panes: order status left, map right. One card in the Field.

### Loyalty card as entity

The payment module writes a `com.starbucks.Reward` entity to the
story's Ledger page. Any other module that handles rewards — a wallet
app, a loyalty tracker — can resolve this entity. The context engine
indexes it:

```
ContextWriter.WriteEntityTopic("com.starbucks.Reward", rewardRef)
```

Next time you're near a Starbucks, the suggestion engine sees the
reward entity in your context and boosts the confidence of a "Redeem
your free drink" proposal.

---

## Spotify

### Story: "Listening"

You pull up on the Now bar, type "chill" in the Ask box. The query
goes to the suggestion engine's Query channel. The Spotify agent
receives it via QueryHandler:

```
QueryHandler.OnQuery("chill") → [
  Proposal {
    id: "spotify_playlist_chill",
    headline: "Chill Vibes",
    subheadline: "Your personalized playlist — 2h 34m",
    color: 0xFF1DB954,
    image: album_art_vmo,
    confidence: 0.92,
    on_selected: [{
      add_module: {
        module_name: "spotify_player",
        intent: {
          action: "com.spotify.PLAY",
          parameters: [{ name: "playlist", data: "spotify:playlist:chill_vibes" }]
        }
      }
    }]
  },
  Proposal {
    id: "spotify_playlist_lofi",
    headline: "Lo-Fi Beats",
    subheadline: "Study & focus — 3h 12m",
    ...
  }
]
```

You tap "Chill Vibes." Story created. The player module starts. Music
plays. The module declares an ongoing activity:

```
ModuleContext.StartOngoingActivity(OngoingActivityType.AUDIO, request)
```

This tells the framework: keep this story alive even when not focused.
The user shell sees the ongoing activity via StoryProvider.WatchActivity()
and shows a persistent indicator in the Now bar.

### The card in the field

The Spotify story card in the Field shows album art as its story
content. When unfocused (in the recents grid), it's a beautiful
card with the playlist cover. When you focus it (tap), the card
expands and the full player UI appears — controls, queue, lyrics.

### Lyrics as a composed module

You tap the lyrics button. The player module calls:

```
AddModuleToStory("lyrics",
  Intent {
    action: "com.spotify.LYRICS",
    parameters: [{ name: "track", entity_type: "com.spotify.Track" }]
  },
  surface_relation: {
    arrangement: COPRESENT,
    dependency: DEPENDENT,
    emphasis: 0.4
  }
)
```

Mondrian splits: 60% player, 40% lyrics. `DEPENDENT` means if the
player is dismissed, lyrics go too. The lyrics module auto-scrolls
synced to playback position via a shared Link:

```
Link("playback_position").Set('{"ms":142350}')
```

The lyrics module watches the link and highlights the current line.

### Cross-story interaction: Spotify + Starbucks

You're in the Starbucks story ordering coffee. Spotify is still playing
(ongoing activity). The Now bar shows the Spotify indicator. You can:

1. Tap the indicator → Spotify story focuses (Starbucks goes back to
   the field as an unfocused card).
2. Long-press drag the Spotify card ONTO the Starbucks card → they
   GROUP into a single cluster. Now one card in the field shows both:
   Starbucks order on top, Spotify mini-player on bottom.

The framework merges the two stories into a StoryCluster. The cluster
is stored in Ledger. Next time you open the device, the cluster is
restored — your coffee order and your music, together.

### Context-aware suggestions

It's 5 PM Friday. Context: `location = work`, `time = evening`.
The Spotify agent publishes a Next suggestion:

```json
{
  "headline": "Friday Wind-Down Mix",
  "subheadline": "Based on your listening history",
  "annoyance": "NONE",
  "confidence": 0.7,
  "affinity": [{ "story_affinity": { "story_name": "listening" } }]
}
```

The `story_affinity` means this suggestion only appears when the
Spotify story is focused or when no story is focused (in overview).
It won't interrupt you while you're in Starbucks or Maps.

### Sharing

You long-press a track. The player module creates a
`com.spotify.Track` entity:

```dart
EntityCodec<SpotifyTrack>.encode(track) → reference
```

The entity enters the system clipboard. You switch to a chat story,
paste → the chat module resolves the entity type, renders a rich
Spotify embed card. The entity traveled between stories via the
framework's EntityResolver, not via Spotify's servers.

---

## El Pollo Loco

### Story: "Lunch"

It's 11:45 AM. You're in the car. Context: `location = unknown`,
`activity = driving`, `time = midday`. The food agent sees you're
near an El Pollo Loco and you haven't eaten (no recent food-order
story). It publishes a Next proposal:

```json
{
  "id": "epl_lunch_nearby",
  "headline": "El Pollo Loco — 2 min away",
  "subheadline": "New: Double Chicken Bowl $8.99",
  "color": "0xFFFF6B00",
  "image": "epl_bowl.jpg",
  "confidence": 0.6,
  "annoyance": "NONE",
  "on_selected": [{
    "add_module": {
      "module_name": "epl_menu",
      "intent": {
        "action": "com.elpolloLoco.MENU",
        "parameters": [{
          "name": "store",
          "entity_type": "com.fuchsia.location.Geolocation",
          "data": "{ \"lat\": 37.55, \"lng\": -122.05 }"
        }]
      }
    }
  }]
}
```

The suggestion appears in the shelf between the Starbucks reward
reminder and a calendar notification. Ranked by the suggestion engine:
- `query_match`: 0 (no query, this is passive Next)
- `affinity`: 0 (no story affinity)
- `mod_pair`: 0.3 (you've used food ordering before)
- `kronk`: 0.4 (time-of-day pattern match)
- `annoyance`: 1.0 (NONE, not annoying)
- Final score: weighted combination → appears in position 3

### The order flow

You tap it. Story "lunch" is created. The `epl_menu` module shows the
menu. You tap "Double Chicken Bowl." The module writes the selection
to a Link and launches the customizer:

```
AddModuleToStory("customize",
  Intent { action: "com.elpolloLoco.CUSTOMIZE" },
  surface_relation: { arrangement: SEQUENTIAL }
)
```

`SEQUENTIAL`: the menu module slides away, the customizer takes over.
Not copresent — the screen isn't big enough on a phone for both. On a
tablet, the system might override this to COPRESENT based on screen
size (SizeModel).

You pick rice, black beans, extra salsa. Each choice writes to the
shared Link. Then "Add to Cart" → back to the menu (customizer calls
`RemoveSelfFromStory()`).

### The combo suggestion

You've added one item. The EPL agent sees the active story and the
item entity. It publishes an Interruption:

```json
{
  "headline": "Add a drink for $1.99?",
  "subheadline": "Upgrade to a combo and save $2",
  "annoyance": "PEEK",
  "affinity": [{ "story_affinity": { "story_name": "lunch" } }],
  "on_selected": [{
    "set_link_value_action": {
      "link_path": { "module_path": ["epl_menu"], "link_name": "combo_upsell" },
      "value": "{\"drink\":\"horchata\",\"price\":1.99}"
    }
  }]
}
```

A PEEK toast appears. You tap it. The framework doesn't launch a new
module — it just writes to the link. The menu module is watching that
link and instantly shows the drink added to your cart. The suggestion
resolved to a data write, not a UI change.

### Pickup with map

You pay. The story transitions to pickup mode. The order module
launches a map:

```
AddModuleToStory("directions",
  Intent { action: "com.fuchsia.NAVIGATE", parameters: [storeLocation] },
  surface_relation: { arrangement: COPRESENT, emphasis: 0.6 }
)
```

The map module is not El Pollo Loco's — it's the system map module,
resolved by the framework because the Intent action is
`com.fuchsia.NAVIGATE` and the parameter type is `Geolocation`.
Module resolution found it:

```
ModuleManifest {
  action: "com.fuchsia.NAVIGATE",
  parameter_types: ["com.fuchsia.location.Geolocation"],
  binary: "maps_module"
}
```

Two panes: order status left (40%), map with directions right (60%).
The map module has no knowledge of El Pollo Loco. It just received
a Geolocation entity and is showing directions.

### Order history in Ledger

The completed order is written to the story's Ledger page:

```
Page("lunch").Put("order_2024_01_15", orderJson)
```

This syncs across devices via Ledger's cloud sync (Firestore). On your
tablet at home later, the "lunch" story is there in the field, showing
your order history. The story persists. The data persists.

### Dead story ranking

Two days later, the same EPL lunch suggestion would normally appear
again. But the `dead_story_ranking_feature` in the suggestion engine
sees that story "lunch" already exists and was recently active. It
suppresses the duplicate. Instead, the agent publishes:

```json
{
  "headline": "Reorder your Double Chicken Bowl?",
  "on_selected": [{ "focus_story": { "story_name": "lunch" } }]
}
```

This focuses the existing story instead of creating a new one. Your
order history, your saved customizations, your loyalty points — all
still there in the same Ledger page.

---

## Cross-app: The Lunch Break

It's 12:30 PM. You have three stories active:

1. **"Listening"** (Spotify) — ongoing audio activity, playing in background
2. **"Lunch"** (El Pollo Loco) — order placed, waiting for pickup
3. **"Morning Coffee"** (Starbucks) — completed, card in field with reward

In the Armadillo field, they're three cards at different sizes:
- EPL is largest (most recently interacted with, story_list_layout.dart
  recency-based sizing)
- Spotify is medium (ongoing activity keeps it prominent)
- Starbucks is smallest (completed, aging out)

You long-press drag EPL onto Spotify → they cluster. One card, two
stories. Mondrian tiles them: EPL order status on top, Spotify mini-
player on bottom. The cluster is named by the framework and persisted
in Ledger.

The Now bar shows: time, your avatar, a music indicator (ongoing
activity), and a peek of the next suggestion — "Your order is ready
for pickup."

You pull up the Now bar → Quick Settings: volume slider (controlling
Spotify's audio via the real AudioPolicy service), wifi, battery.

You pull up further → the Ask box. Type "receipt" → Query channel
fires → both the Starbucks and EPL agents respond with proposals
showing their respective receipts. The suggestion engine ranks them
by recency, affinity, and query_match. EPL wins (more recent). You
tap it → the EPL story focuses and the receipt module launches ONTOP.

---

## The architecture in action

Every interaction above used real m1011 components:

| What happened | Component |
|---------------|-----------|
| "Order your usual" appeared | home_work_agent → Next proposal |
| You tapped it | suggestion_provider → story creation |
| Two panes appeared | Mondrian copresent_layout |
| Payment covered the screen | SurfaceArrangement.ONTOP |
| "Your latte is ready" toast | AnnoyanceType.PEEK → interruption_overlay |
| Music kept playing | OngoingActivityType.AUDIO |
| Cards sized by recency | story_list_layout.dart |
| Cards grouped by drag | StoryCluster + panel_drag_target_generator |
| Order persisted across devices | Ledger cloud_sync + Page.Put |
| Map module found automatically | module_resolver + IntentBuilder |
| Reward entity shared | EntityCodec + ContextWriter |
| Duplicate suggestion suppressed | dead_story_ranking_feature |
| "Add a drink" wrote to link | set_link_value_action |
| Receipt found by typing "receipt" | Query channel + query_match_ranking |
