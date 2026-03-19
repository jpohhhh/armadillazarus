# PuppetMaster User Stories

PuppetMaster is the API that lets session agents create and manipulate
stories programmatically. Same StoryCommand types that SessionWatcher
emits when the user acts manually. Observation and automation are
symmetric.

---

## 1. "Good Morning"

It's 7 AM. Your alarm agent fires (ScheduleTask with alarm_in_seconds).
It has PuppetMaster. It scripts your morning briefing:

```
PuppetMaster.ControlStory("morning_briefing") → puppet

puppet.Enqueue([
  AddMod {
    mod_name: ["weather"],
    intent: Intent { action: "com.fuchsia.WEATHER" },
    surface_relation: { arrangement: COPRESENT, emphasis: 0.3 }
  },
  AddMod {
    mod_name: ["calendar"],
    intent: Intent { action: "com.fuchsia.CALENDAR_TODAY" },
    surface_relation: { arrangement: COPRESENT, emphasis: 0.4 },
    surface_parent_mod_name: ["weather"]
  },
  AddMod {
    mod_name: ["commute"],
    intent: Intent {
      action: "com.fuchsia.NAVIGATE",
      parameters: [{ name: "destination", data: workLocation }]
    },
    surface_relation: { arrangement: COPRESENT, emphasis: 0.3 },
    surface_parent_mod_name: ["calendar"]
  },
  SetFocusState { focused: true }
])

puppet.Execute()
```

You pick up your phone. A story is already there, focused. Three
panes: weather (30%), today's calendar (40%), commute map (30%).
You didn't ask for it. The agent composed it because it's Tuesday
and that's what you look at every Tuesday.

Next Tuesday, the agent does the same thing. But it's raining.
The agent adjusts:

```
puppet.Enqueue([
  AddMod {
    mod_name: ["commute"],
    intent: Intent {
      action: "com.fuchsia.NAVIGATE",
      parameters: [{
        name: "destination",
        data: workLocation,
      }, {
        name: "avoid",
        data: "flooding"
      }]
    },
    ...
  },
  SetLinkValue {
    path: LinkPath { module_path: ["weather"], link_name: "alert" },
    value: '{"type":"rain","severity":"heavy","message":"Allow extra time"}'
  }
])
```

Same story structure, different data. The weather module's link now
has an alert. The commute module got a different intent parameter.
The agent adapted the briefing to conditions.

---

## 2. Learning by Watching

The SessionWatcher sees everything the user does, expressed as
StoryCommands:

```
OnStoryCommands("research", [
  AddMod { mod_name: ["browser"], intent: "VIEW_URL" },
])

// 30 seconds later...
OnStoryCommands("research", [
  AddMod { mod_name: ["notes"], intent: "TAKE_NOTES",
           surface_parent: ["browser"],
           surface_relation: COPRESENT }
])
```

The agent sees: when this user opens a browser, they add a notes
module 30 seconds later, copresent, parented to the browser. Every
time. For weeks.

Now the agent can preempt:

```
// User opens a browser in a new story
OnStoryCommands("new_research", [
  AddMod { mod_name: ["browser"], intent: "VIEW_URL" }
])

// Agent immediately scripts the notes module
PuppetMaster.ControlStory("new_research") → puppet
puppet.Enqueue([
  AddMod {
    mod_name: ["notes"],
    intent: Intent { action: "TAKE_NOTES" },
    surface_relation: { arrangement: COPRESENT, emphasis: 0.4 },
    surface_parent_mod_name: ["browser"]
  }
])
puppet.Execute()
```

The notes pane appears before the user adds it manually. The agent
learned the pattern from the symmetric command stream. No ML model.
Just frequency counting on StoryCommand sequences.

---

## 3. Kiosk Mode

A business deploys Fuchsia devices as restaurant ordering kiosks.
A session agent uses PuppetMaster at boot to create one locked story:

```
PuppetMaster.ControlStory("kiosk_order") → puppet

puppet.SetCreateOptions(StoryOptions {
  kind_of_proto_story: true  // simplified chrome, no story bar
})

puppet.Enqueue([
  AddMod {
    mod_name: ["menu"],
    intent: Intent { action: "com.restaurant.KIOSK_MENU" },
    surface_relation: { arrangement: NONE }
  },
  SetFocusState { focused: true }
])

puppet.Execute()
```

The story launches fullscreen. No Now bar. No suggestion shelf. No
Field. Just the menu module. When the order completes, the agent
watches for it:

```
SessionWatcher.OnStoryCommands("kiosk_order", [
  SetLinkValue { path: "order_status", value: '{"complete":true}' }
])

// Agent resets the story for the next customer
puppet.Enqueue([
  RemoveMod { mod_name: ["payment"] },
  RemoveMod { mod_name: ["customizer"] },
  SetLinkValue { path: "cart", value: "[]" },
  SetLinkValue { path: "order_status", value: '{"complete":false}' }
])
puppet.Execute()
```

The kiosk resets. Same story, wiped state. No human touched
anything in the shell. The agent is the operator.

---

## 4. "Continue on TV"

You're watching a recipe video on your phone. The kitchen TV (also
Fuchsia, same user session) is idle. A session agent on the TV
watches for video stories on other devices via DeviceMap + Ledger
sync:

The phone's story syncs to Ledger. The TV's session agent sees the
new story via StoryProvider.Watch(). It checks: is this a video?
Is the TV idle? Is the user in the same room (context: location)?

```
PuppetMaster.ControlStory("cooking_along") → puppet

puppet.Enqueue([
  AddMod {
    mod_name: ["video"],
    intent: Intent {
      action: "com.fuchsia.PLAY_VIDEO",
      parameters: [{ name: "url", data: videoUrl }]
    },
    surface_relation: { arrangement: COPRESENT, emphasis: 0.6 }
  },
  AddMod {
    mod_name: ["recipe"],
    intent: Intent {
      action: "com.fuchsia.VIEW_RECIPE",
      parameters: [{ name: "recipe", data: recipeEntity }]
    },
    surface_relation: { arrangement: COPRESENT, emphasis: 0.4 },
    surface_parent_mod_name: ["video"]
  },
  SetFocusState { focused: true }
])

puppet.Execute()
```

The TV shows the video (60%) and the recipe steps (40%) side by
side. The phone could show a suggestion: "Moved to TV" with a
link to the same story.

The recipe module on the TV and the video module share a Link for
playback position. As the video plays, the recipe module highlights
the current step. Two modules from potentially different developers,
composed by an agent on a device the user didn't touch.

---

## 5. "Undo Everything"

A session agent that provides undo. It watches all StoryCommands
via SessionWatcher and keeps a stack:

```
stack = []

OnStoryCommands("research", [
  AddMod { mod_name: ["notes"], ... }
]) → stack.push(("research", RemoveMod { mod_name: ["notes"] }))

OnStoryCommands("research", [
  SetLinkValue { path: "notes/text", value: "new text" }
]) → stack.push(("research", SetLinkValue { path: "notes/text", value: oldValue }))
```

User says "undo" (voice) or hits Ctrl+Z (global shortcut):

```
(story_name, inverse_command) = stack.pop()
PuppetMaster.ControlStory(story_name) → puppet
puppet.Enqueue([inverse_command])
puppet.Execute()
```

The mod that was added gets removed. The link value reverts.
Global undo across the entire session, across all stories, powered
by the symmetric command/observation API.

---

## 6. "Do What I Did Yesterday"

A session agent that records daily patterns. On Monday it saw:

```
8:00  StoryCommands("email",    [AddMod "inbox", SetFocusState true])
8:45  StoryCommands("standup",  [AddMod "video_call" to="team-standup"])
9:00  StoryCommands("standup",  [RemoveMod "video_call"])
9:01  StoryCommands("project",  [AddMod "browser", AddMod "terminal"])
```

On Tuesday at 7:55, the agent proposes a Next suggestion:

```
Proposal {
  headline: "Start your morning? Email → Standup → Project",
  on_selected: [{ focus_story: {} }]
}
```

If the user taps it, the agent replays Monday's 8:00 commands:

```
PuppetMaster.ControlStory("email") → puppet
puppet.Enqueue([
  AddMod { mod_name: ["inbox"], intent: "CHECK_EMAIL" },
  SetFocusState { focused: true }
])
puppet.Execute()
```

At 8:43, two minutes before usual standup time:

```
PuppetMaster.ControlStory("standup") → puppet
puppet.Enqueue([
  AddMod { mod_name: ["video_call"],
           intent: Intent { action: "JOIN_CALL", params: [team_standup_link] } },
  SetFocusState { focused: true }
])
puppet.Execute()
```

The standup call opens. The user didn't navigate to it. The agent
knew the pattern.

---

## The Point

PuppetMaster turns the shell from a place you navigate into a
place that navigates for you. The StoryCommand vocabulary is small —
AddMod, RemoveMod, SetLinkValue, FocusMod, SetFocusState,
UpdateMod — but it's complete. Anything a user can do by tapping,
an agent can do by scripting. And anything an agent scripts, a
watcher can observe. The whole system is a loop:

```
User acts → StoryCommands → SessionWatcher → Agent learns
Agent scripts → StoryCommands → PuppetMaster → User sees
```

Same types. Same pipe. Both directions.
