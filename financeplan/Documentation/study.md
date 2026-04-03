# FinancePlan iOS Study Guide

## Purpose

This document is a deep study guide for the full iOS application.

It is meant to help you study:

- SwiftUI app structure
- MVVM in a real app
- dependency injection with `Factory`
- async networking in Swift
- authentication and session restoration
- feature composition
- reusable styling systems
- state management patterns
- accessibility, feedback, and modern Apple-style UI decisions

This app is not a toy example. It already mixes:

- API-backed features
- local-first planning state
- mocked future research features
- reusable design primitives
- unit-tested business logic

That makes it a good codebase to study both SwiftUI and app architecture.

## 1. What the App Is

FinancePlan is a dual-purpose app:

- a personal financial planning tool for salary, expenses, and reports
- a stock portfolio and stock research tool

At a high level the app supports:

- authentication
- onboarding and stock import
- dashboard
- portfolio holdings
- portfolio allocation
- watchlist
- monthly expense planning
- reports and analytics
- stock detail research
- stock valuation drafting
- profile management

Some features are already live against the backend. Others are intentionally mocked on the client and marked with `// to fill from endpoint later`.

## 2. Repository Layout

The working app repo is:

```text
financeplan/
├── Info.plist
├── LaunchScreen.storyboard
├── financeplan.xcodeproj
├── financeplan/                  # App target source
│   ├── API/
│   ├── Components/
│   ├── Documentation/
│   ├── Features/
│   ├── Typography/
│   ├── Utilities/
│   ├── AppEnvironment.swift
│   ├── Constants.swift
│   ├── Container+AppFactories.swift
│   ├── ContentView.swift
│   ├── NorviqaApp.swift
│   └── SessionManager.swift
├── financeplanTests/
└── financeplanUITests/
```

The code is organized by responsibility:

- `API/`: HTTP clients, endpoint definitions, transport helpers
- `Features/`: feature modules, usually view + view model + service/model
- `Components/`: reusable SwiftUI building blocks
- `Typography/`: font and text style abstractions
- `Utilities/`: generic helpers and modifiers
- root app files: bootstrapping, environment, app-wide dependency registration

## 3. App Startup and Root Flow

The app entry point is `financeplan/NorviqaApp.swift`.

### App shell

`NorviqaApp` does four important things:

1. creates the shared `SessionManager` as a `@StateObject`
2. injects the session manager into the environment
3. reads persisted appearance with `@AppStorage`
4. mounts `ContentView()` as the root screen

Important concepts here:

- `@main` declares the SwiftUI app entry
- `WindowGroup` is the main scene container
- `.preferredColorScheme(...)` centralizes theme selection
- `.tint(...)` sets a global accent color

### Root state machine

`financeplan/ContentView.swift` acts like a small app router.

It manages these phases:

1. splash
2. authentication
3. mandatory first stock import
4. main app shell

The root flow is state-driven:

- before launch completes: show `SplashScreen`
- authenticated but onboarding incomplete: show `OnboardingImportFlow`
- authenticated and onboarding complete: show `HomeScreen`
- otherwise: show `LoginScreen`

This is a common SwiftUI pattern: instead of a central imperative navigator, the UI is derived from a few state values.

### Testing hooks at startup

`ContentView` also supports UI-test launch arguments.

Examples:

- `-ui_test_skip_splash`
- `-ui_test_reset_session`
- forced auth token, refresh token, username, and imported-user state

This is a strong testing pattern: the app can be launched into deterministic states without tapping through the whole UI.

## 4. Environment and Configuration

The environment system is split across:

- `financeplan/AppEnvironment.swift`
- `financeplan/Constants.swift`
- `financeplan/SchemeEnvironment.swift`

### Environment model

`AppEnvironment` stores:

- `title`
- `apiBaseUrl`
- `wsBaseUrl`

Defined environments are:

- `local`
- `dev`
- `production`

### AppEnvironmentManager

`AppEnvironmentManager` is declared with the `@Observable` macro in `Constants.swift`.

That is important for study because it shows modern Swift observation, not only `ObservableObject`.

Environment resolution order is:

1. runtime env var `NORVIQA_ENVIRONMENT`
2. generated scheme value from `SchemeEnvironment`
3. persisted user defaults selection
4. build-based default: `dev` in debug, `production` in release

This design is good because:

- it supports local development
- it supports Xcode schemes
- it supports persistent manual switching
- it keeps network base URLs centralized

## 5. Dependency Injection with Factory

This app uses the `Factory` package for DI.

Main registration file:

- `financeplan/Container+AppFactories.swift`

Additional feature-specific factories:

- `API/UserProfile/Container+UserProfileFactories.swift`
- `API/Assets/Container+AssetSearchFactories.swift`

### Why this matters

Instead of constructing services everywhere in views, the app centralizes object creation inside `Container`.

Examples of registered dependencies:

- `appEnvironment`
- `windowSize`
- `authService`
- `authSessionStore`
- `authSessionManager`
- `stockService`
- `userProfileService`

### Benefits

- better testability
- easier swapping between real and stub implementations
- less coupling between UI and infrastructure

### Property wrapper usage

The app uses several injection-related wrappers:

- `@InjectedObject`
- `@InjectedObservable`
- direct `Container.shared.someDependency()`

This is worth studying because the code does not use a single DI style everywhere. It uses the right tool for the ownership model of each object.

## 6. State Management Patterns

This codebase is a good survey of SwiftUI state tools.

### `@State`

Used for local ephemeral view state:

- selected tabs
- sheet visibility
- dialogs
- selected scenario
- toast visibility

### `@StateObject`

Used when the view owns the lifecycle of a reference type:

- `LoginViewModel`
- `BudgetPlannerViewModel`
- `PortfolioViewModel`
- `UserProfileViewModel`

### `@ObservedObject`

Used when a parent owns the view model and passes it down:

- `ExpensesPlannerScreen(viewModel:)`
- `ExpensesComparisonScreen(viewModel:)`
- `StockCompareTab(viewModel:)`

### `@EnvironmentObject`

Used for truly shared root state:

- `SessionManager`
- `PortfolioViewModel` inside the portfolio root branch

### `@AppStorage`

Used for lightweight persistence:

- selected app appearance

### `@FocusState`

Used for form focus management:

- auth form fields

### `@AccessibilityFocusState`

Used for VoiceOver focus:

- `ToastBanner`

### `@Observable`

Used for:

- `AppEnvironmentManager`

This is the new Swift observation model and is worth comparing with `ObservableObject`.

## 7. Session and Authentication Architecture

The auth stack is one of the stronger architectural parts of the app.

Main files:

- `Features/Auth/AuthService.swift`
- `Features/Auth/AuthSessionManager.swift`
- `Features/Auth/LoginViewModel.swift`
- `Features/Auth/LoginScreen.swift`
- `API/Auth/AuthHTTPClient.swift`
- `API/Auth/AuthEndpoints.swift`

### Layers

The auth stack follows a clear layered shape:

1. view
2. view model
3. domain service
4. HTTP client
5. endpoint definitions
6. persistent session store

### AuthSessionStore

`UserDefaultsAuthSessionStore` stores:

- access token
- refresh token
- token expirations
- current user id
- current username
- login/signup UI mode
- whether onboarding import was completed for a user

It uses a secure string store and falls back to `UserDefaults` if needed.

This is a nice study example because it combines:

- security-conscious storage
- migration support
- simple app-state persistence

### AuthSessionManager

`AuthSessionManager` is the logic layer for token validity.

Responsibilities:

- restore session on app launch
- return a valid access token
- refresh token when needed
- clear invalid sessions
- broadcast invalidation through `NotificationCenter`

Important design detail:

- it deduplicates refresh work with a shared `Task` protected by `NSLock`

That avoids multiple concurrent refresh requests.

### LoginViewModel

`LoginViewModel` is a textbook `@MainActor` view model.

Responsibilities:

- own text field state
- validate fields
- switch between login and signup
- submit auth requests
- map errors to user-facing messages
- persist auth response on success

This is a good example of keeping business and submission logic out of the view.

### LoginScreen

`LoginScreen` focuses on composition and interaction:

- text field layout
- focus order
- sheets
- confirmation dialog
- toast banner
- error display

The view delegates logic to the view model, which is exactly what you want in MVVM.

## 8. Networking Pattern

The networking pattern is feature-specific but consistent.

Examples:

- `AuthHTTPClient`
- `UserProfileHTTPClient`
- `StockHTTPClient`

### Common shape

Each HTTP client usually does the following:

1. receives a typed endpoint
2. builds a `URLRequest`
3. executes via `URLSession` abstraction
4. checks HTTP status codes
5. decodes typed responses
6. maps server errors into app errors

### Why this is good for study

It shows a practical middle ground between:

- one huge generic networking layer
- and fully duplicated per-feature networking

Each feature gets:

- its own transport errors
- its own session abstraction for tests
- its own auth rules if necessary

### Service layer on top of HTTP client

The app uses service objects above HTTP clients:

- `AuthService`
- `StockService`
- `UserProfileHTTPService`

That layer:

- resolves the current environment
- injects auth/session dependencies
- retries unauthorized requests after refresh
- exposes domain-friendly methods to view models

This separation is one of the most useful architectural lessons in the codebase.

## 9. Navigation Architecture

Navigation is intentionally simple and mostly local.

### Top-level navigation

`HomeScreen` owns the main `TabView` with five tabs:

- Home
- Portfolio
- Expenses
- Reports
- Settings

### Feature-local navigation

Inside tabs, features use `NavigationStack`.

Examples:

- dashboard stack
- portfolio stack
- settings stack
- user profile modal stack

### Segmented navigation

Within some screens, the app uses segmented `Picker`s as local sub-navigation.

Examples:

- portfolio segments: `Holdings`, `Allocation`, `Watchlist`
- stock detail tabs: `Overview`, `Projections`, `Compare`
- report mode: `Months` vs `Years`

This is very Apple-like: top-level tabs for major areas, segmented controls for closely related sub-areas.

## 10. Feature Architecture by Module

### Dashboard

Main file:

- `Features/Home/HomeScreen.swift`

The dashboard mixes:

- greeting logic
- search
- summary cards
- charts
- insight cards
- entry points into other tabs

It currently contains mocked data for:

- trend points
- spending points
- insight cards

Those are explicitly marked to be replaced by endpoints later.

### Portfolio

Main files:

- `Features/Portfolio/PortfolioViewModel.swift`
- `Features/Portfolio/PortfolioScreen.swift`
- `Features/Portfolio/PortfolioAllocationScreen.swift`

The portfolio module is a good MVVM example.

#### `PortfolioViewModel`

Responsibilities:

- fetch holdings
- compute totals
- compute allocation slices
- create/update/delete positions
- expose UI state like `isLoading`, `isSaving`, `errorMessage`

Computed properties like `totalValue` and `allocationSlices` keep the view thin.

#### `PortfolioScreen`

Responsibilities:

- render summary
- render list of holdings
- present add/edit sheets
- send user actions to the view model

This is a strong pattern to study:

- view model holds the data and mutation logic
- view holds presentation and user interaction

#### `PortfolioAllocationScreen`

This screen is particularly valuable to study because it combines:

- `Swift Charts` sector chart
- legend rendering
- image rendering with `ImageRenderer`
- share sheet integration
- social-sharing use case

It is a practical example of turning a SwiftUI view into a shareable image.

### Expenses Planner

Main files:

- `Features/Expenses/BudgetPlannerModels.swift`
- `Features/Expenses/BudgetPlannerViewModel.swift`
- `Features/Expenses/ExpensesPlannerScreen.swift`

This is the most domain-heavy feature on the finance side.

#### Domain model

The budget system is built on three pillars:

- `Fundamentals`
- `Future You`
- `Fun`

The core model types are:

- `MonthlyBudgetSnapshot`
- `BudgetPlanItem`
- `BudgetActivity`
- `BudgetMonthSummary`
- `BudgetYearSummary`
- `PillarPlanningSummary`

This is a useful study example because the feature has an explicit domain vocabulary rather than passing raw dictionaries around.

#### `BudgetPlannerViewModel`

This view model is one of the most educational files in the app.

It shows how to:

- derive multiple UI summaries from one source of truth
- compute per-pillar targets from salary
- compute planned vs actual amounts
- clone a month forward
- normalize target shares
- ensure a month exists before recording activity

The current data is local and mock-seeded by default. That is clearly marked in the initializer.

#### `ExpensesPlannerScreen`

This screen uses many modern SwiftUI pieces:

- `NavigationStack`
- `ScrollView`
- `GlassCard`
- `toolbarTitleMenu`
- `Menu`
- `sheet`
- `confirmationDialog`
- `Grid`
- `Charts`

It is a good screen to study for dense but still structured financial UI.

### Reports

Main file:

- `Features/Expenses/ExpensesComparisonScreen.swift`

Reports are intentionally read-only analytics over the same planner state.

This is an important architectural idea:

- `Expenses` writes state
- `Reports` reads and visualizes derived summaries

The same `BudgetPlannerViewModel` instance is passed to both tabs from `HomeScreen`.

That means:

- no duplicated analytics state
- edits in expenses instantly affect reports

This is a strong example of sharing a domain view model across sibling screens.

### Stock Detail Research

Main files:

- `Features/Stocks/StockDetailsScreen.swift`
- `Features/Stocks/StockDetailsScreenViewModel.swift`
- `Features/Stocks/StockInsightsModels.swift`
- `Features/Stocks/StockInsightsViews.swift`

This is the most layered feature in the app.

#### Overview

The overview tab combines:

- position summary
- valuation summary
- current metrics
- price history
- news
- placeholder research sections

Some sections are real, others are placeholders for later endpoint work.

#### Projections

The projections tab models:

- current stock context
- scenario selection
- 5-year financial forecasts
- valuation ranges
- projected CAGR

The current UI is structured like a real analysis screen, but the projection data is still mocked on the client through `StockInsightsMockStore`.

#### Compare

The compare tab allows:

- one primary stock
- two peer stocks
- mandatory metric comparison
- advanced metric comparison

This is a nice example of keeping the screen declarative while centralizing peer-selection logic inside the view model.

#### Mixed data strategy

This feature is important to study because it mixes three data modes:

- API-backed stock details, history, news, valuation
- locally mocked comparison/projection data
- derived share/export formatting

That is realistic product evolution: not everything ships with full backend support at the same time.

### Onboarding

Main files:

- `Features/Onboarding/OnboardingImportFlow.swift`
- `Features/Onboarding/OnboardingImportViewModel.swift`
- `Features/Onboarding/InitialStockImportScreen.swift`

The onboarding flow is built like a local state machine.

`OnboardingImportViewModel.Step` drives:

- choose method
- CSV import
- manual import
- API import
- done

That is a clean SwiftUI pattern for wizard-like flows.

### User Profile

Main files:

- `Features/UserProfile/UserProfileViewModel.swift`
- `Features/UserProfile/UserProfileView.swift`
- `Features/UserProfile/UserProfileService.swift`

This module is a straightforward API-backed MVVM feature.

It is a useful contrast with the mocked budget planner:

- profile is backend-first
- planner is currently local-first

Studying both modules together helps you understand how the same UI architecture works over different data sources.

## 11. Styling and Design System

The app has a light internal design system rather than raw ad hoc styling.

Main files:

- `AppTheme.swift`
- `Typography/*`
- `Components/GlassCard.swift`
- `Components/MeshGradientBackground.swift`
- `Components/GlowingButton.swift`

### Color system

`AppTheme.Colors` centralizes:

- tint colors
- soft tints
- secondary accent
- page backgrounds
- card backgrounds
- elevated surfaces
- separators
- nav and tab backgrounds
- semantic colors

This is a good pattern because:

- colors adapt to light/dark mode
- visual decisions are centralized
- feature views stay focused on composition

### Typography system

The app defines semantic text roles through:

- `Typography`
- `TypographyStyle`
- `View.typography(...)`

Instead of scattering raw `.font(...)` calls everywhere, the UI often uses:

- `.typography(.hero, weight: .bold)`
- `.typography(.small)`
- `.typography(.caption)`

This is useful to study because it introduces semantic typography without building a huge custom framework.

### Reusable surfaces

`GlassCard` is the main reusable surface primitive.

It wraps content with:

- padding
- rounded rectangle fill
- subtle stroke
- shadow

The benefit is consistency. Many screens look cohesive because they all compose the same surface primitive.

### Background system

`MeshGradientBackground` provides the ambient animated background used on several screens.

Notable points:

- it respects `Reduce Motion`
- it uses soft blurred gradients
- it stays behind content using `ignoresSafeArea`

This is a good example of controlled visual polish without turning the whole app into a special-effects demo.

## 12. SwiftUI Modifiers Worth Studying

This app contains many useful modifier patterns.

### Layout and presentation

- `.background(... .ignoresSafeArea())`
- `.frame(maxWidth: .infinity, maxHeight: .infinity)`
- `.safeAreaInset(edge:)`
- `.scrollBounceBehavior(.basedOnSize)`
- `.scrollDismissesKeyboard(.interactively)`
- `.toolbarBackground(...)`
- `.toolbarTitleMenu`

### Async and lifecycle

- `.task`
- `.onAppear`
- `.onReceive`
- `.refreshable`
- `.onChange`

### Navigation and modals

- `.sheet`
- `.confirmationDialog`
- `.searchable`
- `.navigationBarTitleDisplayMode`

### Animation

- `.animation(.snappy(...), value: ...)`
- `.transition(.opacity.combined(with: .move(edge: ...)))`
- spring-style onboarding transitions

### Accessibility

- `.accessibilityLabel`
- `.accessibilityHint`
- `.accessibilityFocused`
- `.accessibilityAddTraits`

### Feedback

- `.appSensoryFeedback(...)`

That last one is a custom helper that wraps SwiftUI `sensoryFeedback` for success and destructive actions.

## 13. Utility Patterns

### Window size synchronization

Files:

- `WindowSizeSyncView.swift`
- `Container+AppFactories.swift`

`WindowSizeSyncView` writes the current rendered size into a shared `WindowSize` object.

That object computes `effectiveFormMaxWidth`, which is then used by forms like the login screen.

This is a practical pattern for:

- responsive iPhone vs iPad layout tuning
- keeping sizing logic outside individual screens

### FrameReader utilities

Files:

- `Utilities/FrameReader/*`

These provide helpers like:

- `readSize(into:)`
- `readFrame(into:)`
- `readWidth(into:)`

This is useful for advanced layout observation when plain SwiftUI stacks are not enough.

### Toast and accessibility

`ToastBanner` is worth reading carefully.

It combines:

- semantic styling
- transient UI
- VoiceOver focus management with `@AccessibilityFocusState`

This is a good example of accessibility-aware component design.

## 14. Apple-Style UI Decisions

The app has been pushed toward Apple Human Interface Guidelines in several ways:

- top-level `TabView` for major product areas
- `NavigationStack` with large titles
- segmented controls for closely related content
- grouped/settings-style lists where appropriate
- native sheets and confirmation dialogs
- semantic SF Symbols
- strong light/dark support
- restrained use of motion
- content-first layout with subtle chrome

At the same time, the app keeps a branded visual layer:

- custom tints
- mesh gradients
- glass cards
- valuation/share cards

That balance is worth studying: native structure first, brand second.

## 15. Testing Strategy

The test suite covers business logic and HTTP behavior more than pixel-perfect UI.

Key tests include:

- `AuthSessionManagerTests`
- `AuthSessionStoreTests`
- `LoginViewModelTests`
- `AuthHTTPClientTests`
- `StockServiceTests`
- `PortfolioViewModelTests`
- `BudgetPlannerViewModelTests`
- `StockDetailsViewModelTests`
- `ManualImportViewModelTests`
- `UserProfileHTTPClientTests`

### What this tells you

The team is testing:

- auth/session correctness
- request building and error decoding
- view model calculations
- feature business rules

That is a solid strategy for SwiftUI apps, where UI layout itself changes often but core logic should stay stable.

## 16. Mocked vs API-Backed Areas

This is important to understand before studying the app.

### Already API-backed

- authentication
- stock CRUD
- stock details
- stock history
- stock news
- stock valuation CRUD
- user profile
- watchlist

### Still mocked or local-first

- dashboard summary cards and trend data
- asset search
- expenses planner persistence
- reports persistence
- stock projections
- stock comparison metrics
- onboarding API import flow
- some fundamentals and earnings sections

The codebase is explicit about this. Many files include:

```swift
// to fill from endpoint later
```

That makes the current architecture easier to follow because you can see exactly where the client stops and where backend integration is meant to begin.

## 17. How the App Is Built Internally

If you want the mental model in one sentence:

> The app is a SwiftUI root shell that chooses the current app phase, injects shared services through `Factory`, loads feature-specific state in `@StateObject` view models, and renders branded Apple-style finance screens from derived domain data.

In more concrete terms:

1. `NorviqaApp` boots the app and global preferences.
2. `ContentView` decides which major flow to show.
3. feature roots own their view models
4. view models call services
5. services call feature-specific HTTP clients
6. HTTP clients execute endpoint-driven requests
7. shared design primitives keep screens visually consistent
8. tests protect the business logic

That is the internal spine of the whole application.

## 18. Best Files to Study First

If you want to learn this codebase efficiently, read in this order:

1. `financeplan/NorviqaApp.swift`
2. `financeplan/ContentView.swift`
3. `financeplan/Container+AppFactories.swift`
4. `financeplan/Constants.swift`
5. `financeplan/AppTheme.swift`
6. `financeplan/Typography/View+Typography.swift`
7. `financeplan/Features/Auth/LoginViewModel.swift`
8. `financeplan/Features/Auth/LoginScreen.swift`
9. `financeplan/Features/Auth/AuthSessionManager.swift`
10. `financeplan/Features/Portfolio/PortfolioViewModel.swift`
11. `financeplan/Features/Expenses/BudgetPlannerViewModel.swift`
12. `financeplan/Features/Stocks/StockDetailsScreenViewModel.swift`
13. `financeplan/Components/GlassCard.swift`
14. `financeplan/Components/ToastBanner.swift`
15. `financeplanTests/BudgetPlannerViewModelTests.swift`
16. `financeplanTests/StockDetailsViewModelTests.swift`

That reading order gives you:

- app shell
- dependency injection
- styling system
- one API-backed feature
- one local-first feature
- one mixed-data feature
- tests for understanding behavior

## 19. What Makes This a Good SwiftUI Study Project

This app is a strong study target because it includes:

- real async API calls
- token refresh and session recovery
- view-model-driven forms
- feature-local state machines
- chart-heavy finance UI
- reusable design primitives
- light-weight design system patterns
- accessibility work
- modern SwiftUI-only feedback and sharing
- both backend-first and local-first modules

That combination is much more educational than a small sample app.

## 20. Final Takeaway

If you study this project well, the main things to learn are:

- how to keep SwiftUI views declarative
- how to keep feature logic in view models
- how to separate transport, service, and presentation layers
- how to build a reusable visual system without overengineering it
- how to evolve an app while some features are still mocked

The architecture is not “pure” in a theoretical sense, but it is practical, readable, and product-driven. That makes it a valuable Swift and SwiftUI reference.
