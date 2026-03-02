# COMFIE iOS Architecture

This document is a stable architecture map for recurring contributors and reviewers.
It is based on the current development baseline (`develop` branch).

## 0) Scope

### Audience
- Contributors touching multiple features.
- Reviewers validating cross-cutting changes.

### Non-goals
- File-by-file implementation walkthroughs.
- SwiftUI tutorial material.
- Full API reference for every type.

Rule of thumb: this is a country map, not a street map.

## 1) Update policy

- Update this doc on architecture drift, not on every PR.
- Keep only stable constraints and navigation hints.
- Delete details that track fast-changing behavior.

## 2) Bird's-eye view

### 2.1 System overview

COMFIE is a local-first SwiftUI app for memo capture, retrospection text, and "ComfieZone" location context.
The app applies emoji mapping to text while preserving user input history, and exposes feature flows through a centralized router.

The runtime model is a layered flow:
`View` -> `Store (Intent/Action/State)` -> `UseCase/Repository` -> `Service/Persistence`.
Data enters from user interactions and device services, then is persisted to local storage and reflected back into derived UI state.

### 2.2 Inputs -> Outputs (Ground vs Derived)

Inputs (ground state):
- User input text and UI intents from SwiftUI views.
- Device location and location authorization (`LocationService`).
- Local persisted data in Core Data (`UserRecordModel`) and UserDefaults (`hasEverOnboarded`).

Outputs (derived state):
- Feature UI state in store `State` structs.
- Navigation stack/path in `Router.path`.
- Emoji-transformed text derived from source text (`EmojiString`, `EmojiCharacter`).
- Rendered views and popups.

### 2.3 Update model

- Small changes are feature-local intent handling in one store.
- Stores receive intents, compute new state via actions, and emit side effects via publishers when UI control is required.
- Persistence and OS API calls are delegated to repositories/use cases/services; views do not own IO concerns.

## 3) Entry points

- App bootstrap: `COMFIE/App/COMFIEApp.swift`
- Root navigation shell: `COMFIE/App/COMFIERoutingView.swift`
- Routing core: `COMFIE/App/Router/Router.swift`, `COMFIE/App/Router/Route.swift`, `COMFIE/App/Router/Router + navigate.swift`
- Dependency assembly: `COMFIE/App/DIContainer/DIContainer.swift`
- Store protocol contract: `COMFIE/Presentation/Intent/IntentStore.swift`

## 4) Code map

### 4.1 Top-level repository map

- `/COMFIE/App`: App entry, DI setup, route definitions, root navigation logic.
- `/COMFIE/Presentation`: Feature views and stores (Onboarding, Memo, Retrospection, ComfieZoneSetting, More).
- `/COMFIE/Domain`: Domain entities (`Memo`, `ComfieZone`), use case (`LocationUseCase`), emoji mapping model.
- `/COMFIE/Data`: Core Data service, repository implementations, entity mapping extensions, UserDefaults service.
- `/COMFIE/Service`: OS-facing services (`LocationService`, `LocalAuthenticationService`).
- `/COMFIE/Resources`: Design system components, assets, localization strings, shared extensions.
- `/COMFIETests`, `/COMFIEUITests`: Test targets.

### 4.2 Major components

#### Component: App bootstrap and routing (`COMFIE/App`)
- Responsibility: Start app, create router and DI container, select root flow, push/pop routes.
- Owns: `Router.path`, loading gate, onboarding completion flag.
- Depends on: SwiftUI navigation primitives, `UserDefaultsService`, `DIContainer`.
- Must not depend on: Feature-specific persistence internals.
- Boundary status: Primary app composition and navigation boundary.
- Key invariants: Route construction goes through `Route` + `DIContainer.makeView`; root flow decision is centralized in `Router.rootView`.

#### Component: Presentation stores and views (`COMFIE/Presentation`)
- Responsibility: Translate UI intents into state transitions and side effects.
- Owns: Per-feature `State` values and UI side-effect publishers.
- Depends on: `Router`, repository protocols, use cases, and resources.
- Must not depend on: Core Data entities, `CLLocationManager`, or direct storage APIs.
- Boundary status: Main feature behavior boundary.
- Key invariants: Each feature store is the mutation authority for its feature state; views invoke store intents and do not orchestrate persistence directly.

#### Component: Domain model and behavior (`COMFIE/Domain`)
- Responsibility: Define core app entities and text-to-emoji mapping logic.
- Owns: `Memo`, `ComfieZone`, `EmojiString`, `EmojiCharacter`, `LocationUseCase`.
- Depends on: Foundation/CoreLocation-level types and repository protocols.
- Must not depend on: SwiftUI view types or Core Data entity classes.
- Boundary status: Feature-independent business model boundary.
- Key invariants: `EmojiString` keeps original and emoji character streams aligned; `LocationUseCase` is the location decision API used by stores.

#### Component: Data persistence (`COMFIE/Data`)
- Responsibility: Persist and fetch domain data from Core Data and UserDefaults.
- Owns: `CoreDataService`, repository implementations, Core Data <-> domain mapping extensions.
- Depends on: Core Data stack and domain entities.
- Must not depend on: SwiftUI view/store types.
- Boundary status: Persistence and storage boundary.
- Key invariants: Core Data entity mapping happens in `COMFIE/Data/CoreData/Extensions` only; store-facing persistence APIs are repository protocols.

#### Component: System services (`COMFIE/Service`)
- Responsibility: Wrap device and OS framework APIs.
- Owns: Location updates/authorization and local authentication requests.
- Depends on: `CoreLocation`, `MapKit`, `LocalAuthentication`.
- Must not depend on: Feature view logic.
- Boundary status: OS integration boundary.
- Key invariants: Location manager access is centralized in `LocationService`; authentication prompt flow is isolated in `LocalAuthenticationService`.

#### Component: UI resources and design system (`COMFIE/Resources`)
- Responsibility: Shared UI primitives, assets, typography, localization literals.
- Owns: `CF*` reusable components and string literal namespaces.
- Depends on: SwiftUI/UIKit rendering concerns only.
- Must not depend on: Repositories, use cases, or routing logic.
- Boundary status: Presentation support boundary.
- Key invariants: Feature views should consume shared design/localization components instead of duplicating constants.

## 5) Architectural invariants

**Architecture Invariant:** There is no direct Core Data access from presentation stores or views.
- Rationale: Keep persistence details behind repository boundaries.
- Enforced by: Repository protocols and `CoreDataService` ownership in Data layer.
- Violation symptoms: Stores import Core Data types, feature code tightly coupled to schema.

**Architecture Invariant:** There is no route stack mutation outside `Router` API usage.
- Rationale: Navigation behavior must remain predictable and reviewable.
- Enforced by: `Router.push/pop/popToRoot` and route enum-based flow.
- Violation symptoms: Inconsistent navigation behavior or duplicated navigation state.

**Architecture Invariant:** There is no domain entity <-> Core Data entity conversion outside mapping extensions.
- Rationale: Avoid scattered serialization logic and schema leak.
- Enforced by: Conversion helpers in `COMFIE/Data/CoreData/Extensions`.
- Violation symptoms: Duplicate conversion code and inconsistent persisted values.

**Architecture Invariant:** There is no direct OS permission flow in views.
- Rationale: Permissions and device APIs should be testable and centralized.
- Enforced by: `LocationUseCase`, `LocationService`, and popup/store intent flows.
- Violation symptoms: View-level permission branching and hard-to-test UI logic.

**Architecture Invariant:** There is no mutable shared feature state outside each feature store.
- Rationale: Maintain a single state authority per screen flow.
- Enforced by: `private(set) state` pattern in stores.
- Violation symptoms: Desynchronized UI, race conditions between views and services.

## 6) Boundaries and API surfaces

### 6.1 Boundary list

- Boundary surface: Presentation <-> Domain/Data (`COMFIE/Presentation/*Store.swift`)
- What crosses: Intents, domain entities (`Memo`, `ComfieZone`), repository/use case interfaces.
- Forbidden crossing: Core Data entities, direct `NSManagedObjectContext`, direct `CLLocationManager`.

- Boundary surface: Domain <-> Data (`COMFIE/Data/Repository/*`, `COMFIE/Domain/*`)
- What crosses: Domain entities and protocol-based operations.
- Forbidden crossing: SwiftUI view concerns and resource/UI component types.

- Boundary surface: Service <-> OS frameworks (`COMFIE/Service/*`)
- What crosses: Device state (location/auth results) as value/publisher outputs.
- Forbidden crossing: Feature UI mutation logic.

- Boundary surface: App routing <-> Features (`COMFIE/App/Router/*`, `COMFIE/App/DIContainer/*`)
- What crosses: `Route` values and injected store dependencies.
- Forbidden crossing: Feature code constructing ad-hoc root navigation policies.

### 6.2 Boundary rules ("only here")

- Core Data serialization/mapping happens in: `COMFIE/Data/CoreData/Extensions` (only here).
- Persistent IO happens in: `COMFIE/Data/CoreData/CoreDataService.swift` and `COMFIE/Data/UserDefaults/UserDefaultsService.swift` (only here).
- OS framework IO happens in: `COMFIE/Service/LocationService.swift` and `COMFIE/Service/LocalAuthenticationService.swift` (only here).
- Route stack mutation happens through: `COMFIE/App/Router/Router + navigate.swift` (only here).

## 7) Cross-cutting concerns

### Emoji transformation pipeline

- Input text editing is orchestrated by `MemoInputUITextView` delegate events.
- Character-level emoji mapping and synchronization lives in `Domain/TextToEmoji/Model`.
- Features consume emoji mapping as a domain concern, not as view-only string tricks.

### Location and authorization flow

- Permission request and location updates are centralized in `LocationService`.
- Stores consume location state through `LocationUseCase` and react in feature state.
- ComfieZone deletion can require authentication when user context requires stricter confirmation.

### Error handling style

- Repository APIs return `Result` to keep failure explicit at call sites.
- Store-level handling currently favors user-flow continuity (state update + local fallback/logging).

### Testing boundary note

- Test targets exist, but architecture-level boundary enforcement is primarily by module conventions and protocol seams.
- Dependency seams are provided through repository protocols and DI container construction points.

## 8) Writing constraints

- Keep this document architecture-first and stable.
- Prefer module/type/path names over implementation details.
- If a section starts tracking rapid UI behavior changes, shorten or remove it.
