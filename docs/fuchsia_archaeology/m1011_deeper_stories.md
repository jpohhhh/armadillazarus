# Deeper User Stories

Things nobody asks about until they see the architecture.

---

## 1. The Web Page That Became Intelligent

You open a web page in a WebView module — say, a recipe blog. The
WebView has a `SchemaOrgContext` extractor built into the C++ runtime.
As the page loads, it scrapes schema.org JSON-LD from the HTML:

```html
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Chicken Tikka Masala",
  "cookTime": "PT45M",
  "ingredients": ["chicken breast", "yogurt", "garam masala", ...]
}
</script>
```

The WebView calls `ContextWriter.WriteEntityTopic()` with the
extracted data, creating a `com.fuchsia.codelab.Recipe` entity in the
context graph. The user didn't do anything. They just opened a page.

Now the suggestion engine sees a Recipe entity in context. A grocery
agent (subscribed to `entity_type = Recipe`) wakes up and publishes:

```
Proposal {
  headline: "Add ingredients to your shopping list",
  annoyance: NONE,
  on_selected: [{
    add_module: {
      intent: { action: "com.grocery.ADD_ITEMS",
                parameters: [{ entity_type: "Recipe" }] }
    }
  }]
}
```

The suggestion appears in the Next shelf. Tap it → a grocery module
opens COPRESENT with the recipe page. The grocery module reads the
Recipe entity, extracts ingredients, shows checkboxes. You check what
you need, it adds them to your list.

**The web page never knew about the grocery app. The grocery app never
knew about the web page. The context engine connected them through
schema.org types.**

---

## 2. The Story That Followed You Across Devices

You're on your phone, reading a long article in a story called
"research." The story has two modules: a WebView showing the article
and a notes module you've been typing into. Both modules write their
state to Links:

```
Link("article_url").Set('"https://example.com/long-article"')
Link("article_scroll").Set('{"position": 4200}')
Link("notes").Set('{"text": "Key insight: the supply chain...""}')
```

Links are stored in the story's Ledger page. Ledger syncs to
Firestore. Your tablet, running the same user session, receives the
sync update via `LedgerPageWatcher`.

You pick up your tablet. In the Field, you see the "research" story
card. It was synced from your phone — `StoryProviderWatcher.OnChange()`
fired when the Ledger sync arrived. You tap it. The story starts on
the tablet.

The framework resolves the same modules (same intents, same manifest
matching). The WebView opens to the same URL. The notes module opens
with the same text. The scroll position is right where you left it,
because the module reads `Link("article_scroll")` on startup.

But now it gets interesting. You're on a tablet, which has a wider
screen. The `SizeModel` reports a larger viewport. Mondrian's
`copresent_layout.dart` gives more space to both modules. The notes
module, which was a narrow sidebar on the phone, is now a full-width
pane next to the article.

You keep typing. Both devices are running the story. Ledger merges
your edits. If you type on both simultaneously, conflict resolution
kicks in — the notes Link uses `LAST_ONE_WINS`, so whichever write
arrives last wins. (If this were Sledge with a `LastOneWinsString`
field, same thing. If it were an `IntCounter`, it'd merge additively.)

---

## 3. The Story That Deleted Itself

You search for "nearby restaurants" in the Ask box. The query resolves
to a module that shows a map with restaurant pins. A story is created.
But the creator sets deletion options:

```fidl
StoryPuppetMaster.SetCreateOptions(StoryOptions {
  deletion_policy: StoryDeletionPolicy {
    delete_after_last_focus: StoryDeleteAfterLastFocus {
      delay: 1800000000000  // 30 minutes in nanoseconds
    }
  }
})
```

You browse restaurants, pick one, leave the story. A timer starts.
If you don't come back within 30 minutes, the story is deleted from
Ledger. Gone from all devices. The card fades from the Field.

This is for ephemeral queries — "what's the weather", "where's the
nearest gas station", "what time does Target close." These are not
stories worth keeping. The framework garbage-collects them.

If you DO come back within 30 minutes, the timer resets. And if
you interact meaningfully — like saving the restaurant to favorites —
the module can call `PuppetMaster.Enqueue([SetKindOfProtoStoryOption])`
to upgrade the story to permanent.

---

## 4. The Clipboard That Understood Types

You're in a contacts module. You long-press a contact. The module
creates an entity:

```dart
ComponentContext.CreateEntityWithData([
  TypeToDataEntry("com.fuchsia.contact.Contact",
    '{"name":"Jane","email":"jane@example.com"}'),
  TypeToDataEntry("com.fuchsia.contact.Email",
    '"jane@example.com"'),
  TypeToDataEntry("text/plain",
    '"Jane - jane@example.com"')
])
```

One entity, three types. The entity reference goes to the clipboard
(backed by Ledger — the clipboard agent writes to
`Page("ClipboardPage___")`).

Now you switch to an email module and paste. The email module calls
`Entity.GetTypes()` → sees `com.fuchsia.contact.Email` → calls
`Entity.GetData("com.fuchsia.contact.Email")` → gets
`"jane@example.com"` → pastes it into the To: field as a structured
email address, not plain text.

But if you paste into a plain text editor, it calls
`Entity.GetData("text/plain")` → gets `"Jane - jane@example.com"` →
pastes the human-readable string.

Same clipboard, same entity, different rendering based on what the
receiver understands. **The clipboard is polymorphic.**

And because it's on Ledger, you can paste on a different device.

---

## 5. The Module That Spawned From a Module That Spawned From a Module

You start in a chat story. Someone sends you a link to a restaurant.
The chat module detects the URL entity type and calls:

```
ModuleContext.EmbedModule("preview",
  Intent { action: "com.fuchsia.PREVIEW", parameters: [urlEntity] },
  surface_relation: null  // embedded, not copresent
)
```

The framework resolves the intent: a web preview module matches. It
renders an inline preview card within the chat bubble. The preview
module scrapes schema.org → finds a `Restaurant` entity → writes it
to context.

You tap the preview. The chat module calls:

```
ModuleContext.AddModuleToStory("restaurant",
  Intent { action: "com.fuchsia.VIEW", parameters: [restaurantEntity] },
  surface_relation: { arrangement: COPRESENT, emphasis: 0.6 }
)
```

Mondrian splits: chat left, restaurant view right. The restaurant
module shows details, reviews, hours. It has a "Get Directions" button
that calls:

```
ModuleContext.AddModuleToStory("directions",
  Intent { action: "com.fuchsia.NAVIGATE", parameters: [geoEntity] },
  surface_relation: { arrangement: ONTOP }
)
```

The map module covers the restaurant view. Three levels deep now:

```
chat → (embedded) web preview
     → (copresent) restaurant view → (ontop) map directions
```

All within one story. All connected by Links. All laid out by
Mondrian. The chat module doesn't know about restaurants. The
restaurant module doesn't know about maps. Intent resolution
connected them.

And the whole chain — chat, preview, restaurant, map — is one card
in the Armadillo field. One thing you were doing. Clustered by the
Conductor. Restorable. Syncable. Dismissable as a unit.

---

## 6. The Multi-Device Focus Dance

You have a phone and a laptop, both logged in. The `DeviceMap` knows
both exist — each device registered itself with a `DeviceMapEntry`
containing its device_id, hostname, profile, and last_change_timestamp.

You focus a story on your phone. `FocusController.Set(story_id)` fires.
The focus info is written to Ledger:

```
FocusInfo {
  device_id: "phone-xxxx",
  focused_story_id: "recipe_research",
  last_focus_change_timestamp: 1539712345
}
```

Your laptop receives this via `FocusProvider.Watch()`. The laptop's
user shell (Armadillo) sees that story "recipe_research" is focused
on another device. It could:

- Show a subtle indicator on that card ("active on phone")
- Auto-scroll the field to make that card more prominent
- Show an interruption: "Continue 'recipe research' here?"

If you tap "continue here", the laptop calls
`FocusController.Set("recipe_research")`. Now both devices show the
story focused. Ledger syncs the story state. Both devices show the
same modules.

The `VisibleStoriesProvider` is separate from focus — the user shell
reports which stories are actually on screen. The user runner uses
this to pause/stop stories that are running but not visible. Spotify
keeps playing (ongoing activity override), but a game module gets
paused when its card scrolls off the field.

---

## 7. PuppetMaster: Stories as Scripts

A session agent (like Kronk, the AI assistant) has `PuppetMaster` — it
can create and manipulate stories programmatically. No UI. Pure
automation.

User says "plan a dinner party for Saturday." Kronk scripts a story:

```
PuppetMaster.ControlStory("dinner_party_saturday", storyPuppet)

storyPuppet.Enqueue([
  AddMod {
    mod_name: ["guest_list"],
    intent: Intent { action: "com.fuchsia.CONTACTS_LIST" },
    surface_relation: { arrangement: COPRESENT, emphasis: 0.5 }
  },
  AddMod {
    mod_name: ["recipes"],
    intent: Intent { action: "com.fuchsia.RECIPE_SEARCH",
                     parameters: [{ name: "query", data: "dinner party" }] },
    surface_relation: { arrangement: COPRESENT, emphasis: 0.5 },
    surface_parent_mod_name: ["guest_list"]
  },
  SetLinkValue {
    path: LinkPath { module_path: ["guest_list"], link_name: "filter" },
    value: '{"tag": "close_friends"}'
  }
])

storyPuppet.Execute()
```

A story appears in the field with two copresent modules: a contacts
list filtered to close friends, and a recipe search for "dinner party."
The AI assistant composed a multi-module story from voice input. The
user sees it as one card they can interact with, modify, add to.

The key: `StoryCommand`s are **symmetric with observation.**
`SessionWatcher.OnStoryCommands()` sends the same `AddMod`, `RemoveMod`,
`SetLinkValue`, `FocusMod` structures to watchers. So a session agent
can watch what the user does manually, learn patterns, and replay
modified versions later. The user is scripting stories by doing; the
AI is learning by watching the same command stream.

---

## 8. The Agent That Talks to Another Agent

The contacts agent needs to know when a chat message arrives so it
can update "last contacted" timestamps. But agents can't directly
call each other's methods.

The chat agent creates a MessageQueue:

```
ComponentContext.ObtainMessageQueue("incoming_messages", queueRequest)
queue.GetToken() → "token_abc123"
```

It shares `token_abc123` with the contacts agent (via a Link, or
hardcoded, or via another MessageQueue). The contacts agent gets a
MessageSender:

```
ComponentContext.GetMessageSender("token_abc123", senderRequest)
```

When a new chat message arrives, the chat agent sends:

```
sender.Send('{"from":"jane@example.com","time":1539712345}')
```

The contacts agent has registered a trigger:

```
AgentContext.ScheduleTask(TaskInfo {
  task_id: "update_last_contacted",
  trigger_condition: TriggerCondition { message_on_queue: "incoming_messages" },
  persistent: true  // survives reboots, syncs via Ledger
})
```

When the message arrives, the framework starts the contacts agent (if
not running) and calls `Agent.RunTask("update_last_contacted")`. The
agent reads the message, updates the contact record in Ledger.

The `persistent: true` flag means this trigger is stored in Ledger.
If you set it up on your phone, it works on your laptop too. The
agent wakes up on whichever device receives the message first.

---

## The Thing Nobody Talks About

Every one of these stories has a property that no other OS has:

**The user never installed an app.**

There's no app store. There's no "download Starbucks." There's no
icon grid. Modules are resolved by intent. If a `com.starbucks.ORDER`
module exists in the Firebase manifest registry, it's available to
every device. The user encounters it when a suggestion mentions
Starbucks, or when an entity of type `com.starbucks.MenuItem` needs
to be displayed, or when they search "order coffee" in the Ask box.

The module downloads on demand (Fuchsia packages are fetched from
package servers). It runs in a sandboxed component. It writes to its
own Ledger page. It can publish proposals, write context, create
entities. Then it stops. No home screen icon. No persistent process.
No notification permission dialog.

The user's relationship with software is: **I was doing something,
the system found the right tool, I used it, it went away.** The
tool might come back tomorrow if the context is right. Or it might
not. The system decides, based on ranking features, context,
recency, and the user's history.

Apps don't exist. Activities exist. Tools appear when needed and
dissolve when done.

That was the vision.
