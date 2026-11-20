# Qt types Zui deliberately does not expose

Zui's premise is that application logic lives in Ruby and QML is purely a renderer.
`test/framework_boundary_test.rb` enforces the consequences: components never silently
become another type, failures travel the framework error channel, and nothing lets
application code run inside the renderer.

Several public Qt QML types exist only to execute script, or only to be handed
application-authored QML. Wrapping them would either break that boundary or produce an
adapter with nothing behind it. This file records which ones, and why, so the decision is
reviewable rather than looking like an oversight — and so nobody re-derives it.

Each entry says what the Ruby-side equivalent is. "Not exposed" never means "not
supported": it means the capability belongs in Ruby, where the application already is.

## Types that execute script

### `QtQml.WorkerScript` — `WorkerScript`

`WorkerScript` loads a `.mjs` file and runs it on a separate thread, exchanging messages
with `sendMessage` and `onMessage`. The whole point of the type is to execute an
application-supplied script.

Exposing it would mean an application shipping JavaScript for the renderer to run, which
is the one thing the framework boundary exists to prevent. There is no declarative subset
to expose instead: a `WorkerScript` with no script is nothing.

**Ruby-side equivalent.** Background work belongs in Ruby, where the application's code
already lives: `Zui::Scheduler` for deferred and repeating work, and ordinary Ruby threads
or processes for parallelism. Ruby then publishes results as reactive properties, which is
the direction data already flows.

### `QtQuick.LocalStorage` — `LocalStorage`

A singleton whose entire API is `openDatabaseSync()`, returning a JavaScript object whose
`transaction` method takes a callback that executes SQL. It is only reachable from
JavaScript, and everything useful about it is a callback the application would have to
write.

Exposing it would require application QML or JS, and would put the application's
persistence layer behind the renderer rather than in Ruby.

**Ruby-side equivalent.** Persistence belongs in Ruby: the `settings` component for small
key/value state that should follow platform conventions, `standard_paths` to locate a
writable directory, and any Ruby database or file library for the rest. Ruby keeps the
schema and the queries, and feeds the UI as data.

Note that `QtQuick/LocalStorage` is also in `ClientBuilder::LINUX_QML_EXCLUSIONS`, so the
released Linux client does not ship the module at all. The two decisions agree.

### `QtScxml` — `StateMachine`, `StateMachineLoader`, `EventConnection`, `InvokedServices`

SCXML is a W3C state-chart format, and a chart arriving from a modelling tool is a
genuinely attractive interchange story. The whole module is still not exposed, for two
reasons that together leave nothing worth wrapping.

**The useful part executes application script.** A chart only becomes more capable than a
Ruby-declared machine once it has a data model: `cond` on a transition, `expr` on an
`<assign>`, a `<script>` element. Qt ships exactly one SCXML data model plugin —
`libqscxmlecmascriptdatamodel` — so the only data model available *is* a JavaScript engine,
evaluating expressions out of a document the application supplied. Exposing the module means
shipping that engine and running application-authored code in the renderer.

Policing the document instead — rejecting `datamodel="ecmascript"`, `<script>`, `cond`,
`expr` — would mean inventing a policy Qt does not have, enforced by pattern matching. A
partial check that reads like a guarantee is worse than no check, so it is not a real
option.

**The safe part is already there, in Ruby.** Without a data model an SCXML chart cannot
evaluate conditions at all, so its transitions reduce to "move on this event name" — which
is exactly what `state_machine`'s `signal_transition on:` already does, declared in Ruby
and driven by Ruby events. The script-free subset of SCXML adds the file format and nothing
else.

So the capability SCXML would add is the part that breaks the boundary, and the part that
respects the boundary is capability Zui already has.

**Ruby-side equivalent.** `state_machine` with `machine_state`, `final_state`,
`history_state`, `signal_transition` and `timeout_transition` — the full
`QtQml.StateMachine` hierarchy, declared in Ruby. An application that must consume an
`.scxml` document can parse it in Ruby and build that machine from it, which keeps the
interpretation in Ruby where it can be tested.

`QtScxml` is also absent from `ClientBuilder::LINUX_QML_ROOTS`, so the released Linux client
does not ship the module. That stays as it is: permitting a new module whose only data model
is a script engine is not a packaging change worth making for a module that is deliberately
not exposed.

### `QtQuick` — `StateChangeScript`

`StateChangeScript` runs a `ScriptAction` when a state is entered. Same reasoning: its
payload is a script.

**Ruby-side equivalent.** `state` and `state_group` already report `enter`, `exit` and
`change` to Ruby, and the hierarchical `state_machine` reports each state's `enter`, `exit`
and `finish` to that state's own Ruby node. Ruby runs its code in the handler, where it can
be tested.

## Types that only make sense with application-authored QML

### `QtQml` — `Connections`

`Connections` attaches handlers to a target object's signals. Its value in QML is that you
write the handler bodies inline — as script.

Zui already has this capability, and it is central to the framework: a Ruby node subscribes
to events, `Service.qml` validates each one against the node's declared subscriptions, and
the handler is a Ruby block. `Connections` would be a second, script-shaped way to do what
the event protocol already does properly.

Zui's own framework QML uses `Connections` extensively to watch `renderer.nodeChanged` —
that is renderer infrastructure, not application code, and is exactly the distinction being
drawn.

**Ruby-side equivalent.** Event subscription on the component itself:
`button { ... }` with an event handler block.

### `QtQml.Models` — `ListElement`

`ListElement` exists because QML has no hash literal inside a `ListModel`. Ruby has one.
`list_model [{ id: 1, name: "Ruby" }]` already works and is strictly more expressive than a
`ListElement` child node would be — it composes, it can be generated, and it is ordinary
Ruby data.

A `list_element` component would be a second syntax for a Ruby `Hash`, adding no capability.

**Ruby-side equivalent.** A Ruby `Hash` in `list_model`'s `items`.

### `QtQml.Models` — `Package`

`Package` lets one delegate's named parts be shown by several views at once, tagged with the
`Package.name` attached property. It only earns its keep when the application authors the
view delegates.

Zui's application layer is Ruby and its delegates are built by the framework, so there is no
application-authored delegate for parts to belong to. An adapter would be an empty
passthrough.

### `Qt.labs.qmlmodels` — `DelegateChoice`, `DelegateChooser`

`DelegateChoice.delegate` is a `Component` and `DelegateChooser` is assigned to a view's
`delegate`. Both exist to select between application-authored QML delegates.

The useful half of the idea — choosing per row *which renderer draws that row* — is a
Zui-native feature rather than a QML passthrough, and it needs two things this module cannot
supply on its own: a built-in view that accepts a chooser, and a way to map a row's role
value to a Zui component type with props drawn from that row. That belongs on the views
surface, with Ruby naming Zui component types rather than supplying QML.

### `QtQml` — `LoggingCategory`

`LoggingCategory` names a category for QML's `console.log(category, …)` and sets its default
level. It only has an effect on `console` calls, which only application QML could make — and
application QML does not exist here.

**Ruby-side equivalent.** Ruby logging. Framework-side failures already travel the error
channel to Ruby via `renderer.componentError`.

## Uninstantiable base types

These are `isCreatable: false` in Qt's own type data, so there is nothing to instantiate.
They are mapped in `lib/zui/mobile/component_catalog.rb` to the concrete adapters that
realise them, so mobile tree-shaking keeps their module — the same convention the catalog
already uses for `Plugin` and `RouteQuery`.

| Qt type | Module | Realised by |
| --- | --- | --- |
| `AbstractItemModel` | `QtQml.Models` | `list_model` |
| `AbstractListModel` | `QtQml.Models` | `list_model` |
| `AbstractDelegateComponent` | `QtQml.Models` | not exposed, see `DelegateChooser` |
| `QAbstractState` | `QtQml.StateMachine` | `machine_state` |
| `QState` | `QtQml.StateMachine` | `machine_state` |
| `QSignalTransition` | `QtQml.StateMachine` | `signal_transition` |

## What this does not rule out

Declarative data is not script, and the distinction is what makes the boundary useful rather
than merely restrictive. `property_binding` wraps `QtQml.Binding` and is exposed, because a
binding is a target, a property name, a source and a gate — data the framework interprets,
with nothing evaluated as code. The hierarchical `state_machine` is exposed for the same
reason: Ruby declares states and transitions and fires named events, and
`SignalTransition`'s `guard` script string is deliberately *not* part of the schema.

The test is not "does Qt call this declarative?" but "can an application make the renderer
run code it wrote?". If it can, the capability belongs in Ruby instead.
