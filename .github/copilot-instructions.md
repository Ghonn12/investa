## Purpose

This file gives focused, actionable context for AI coding agents working on the `investa` Flutter app so they can be productive immediately.

## Big picture architecture
- Flutter app using GetX (navigation, DI, state). UI is split into `lib/modules/<feature>/views` and controllers in `lib/modules/<feature>/controllers`.
- Routes and bindings: `lib/routes/app_pages.dart` (routes defined with `GetPage`, `BindingsBuilder`, `Get.lazyPut`).
- Services live in `lib/services/` and are registered either at bootstrap (in `lib/main.dart` with `Get.putAsync`) or per-route (via `Get.lazyPut` in `app_pages.dart`).
- Networking: two patterns exist — a central `ApiService` (Dio) used by `AuthService` and many features, and a separate `FinanceService2` that uses `package:http` and a hard-coded `baseUrl`.

## Key, project-specific conventions
- Service initialization: async services that must be ready at startup use `Get.putAsync<Service>(() => Service().init())` in `lib/main.dart`.
- Lazy bindings: use `Get.lazyPut(() => MyController())` in `app_pages.dart` to keep memory low until a route loads.
- Token storage: authentication token is stored in `FlutterSecureStorage` under the key `auth_token` (see `lib/services/auth_service.dart`).
- Shared API base URL: canonical base URL is defined in `lib/core/values/api_constants.dart` — prefer using that constant instead of hard-coded strings.
- Locale: app explicitly initializes Indonesian date formatting in `lib/main.dart` with `initializeDateFormatting('id_ID', null)`. Keep locale and date-format assumptions in mind when modifying UI or tests.

## Networking & Backend integration notes (critical)
- `lib/services/api_service.dart` uses Dio and adds an Authorization header by reading `auth_token` from `FlutterSecureStorage`. It also shows a snackbar when the server responds with 401 (but redirect logic lives in AuthService).
- `lib/services/finance_service2.dart` currently calls `http://localhost:8080/api` directly. Important runtime detail:
  - On Android emulator, `localhost` must be `10.0.2.2` (see comments in `lib/core/values/api_constants.dart`).
  - On iOS simulator use `localhost`.
  - On a physical device, use your machine IP (e.g. `192.168.x.x`).
  - Recommendation: replace hard-coded `baseUrl` in `finance_service2.dart` with `ApiConstants.baseUrl` for consistent behavior across devices.

## Patterns and common places to change behavior
- Add a new async service: implement `Future<Service> init()` returning `this`, then register in `lib/main.dart` with `Get.putAsync`.
- Add a new feature route: update `lib/routes/app_pages.dart` and register controller/service in the `BindingsBuilder` for that `GetPage`.
- Network calls: prefer `ApiService` (`Dio`) for consistent interceptors/headers; if you must use `http`, ensure Authorization header is set using `Get.find<AuthService>().token`.

## Build, run, and debugging commands (dev workflow)
- Get dependencies: `flutter pub get`.
- Run app (choose emulator/device): `flutter run -d <device-id>` or via VS Code Run/Debug.
- Build APK: `flutter build apk`.
- Run tests: `flutter test` (unit/widget tests under `test/`).
- If using Android emulator and backend on host: ensure backend reachable via `10.0.2.2:8080` or set `ApiConstants.baseUrl` accordingly.

## Files to inspect when troubleshooting
- Boot & DI: `lib/main.dart`.
- Routing/bindings: `lib/routes/app_pages.dart`, `lib/routes/app_routes.dart`.
- HTTP config: `lib/core/values/api_constants.dart`, `lib/services/api_service.dart`.
- Auth/token: `lib/services/auth_service.dart`.
- Finance (old vs new): `lib/services/finance_service.dart` (legacy) and `lib/services/finance_service2.dart` (new Sakuku implementation).
- Models referenced by services: `lib/models/transaction_model_v2.dart`, `lib/models/wallet_model.dart`, `lib/models/category_model.dart`.

## Small examples to reference
- Register an async service at boot (in `lib/main.dart`):
  Get.putAsync<ApiService>(() async => await ApiService().init());
- Lazy bind service/controller for a route (in `app_pages.dart`):
  GetPage(..., binding: BindingsBuilder(() { Get.lazyPut(() => FinanceService2()); Get.lazyPut(() => Finance2Controller()); }))

## What agents should *not* assume
- Do not assume the backend runs at `localhost:8080` for all environments — emulator/device differences matter. Always check `lib/core/values/api_constants.dart` and adapt `finance_service2.dart` if needed.
- There are two different HTTP clients in codebase (Dio vs `package:http`); do not refactor one to the other without checking all call sites.

## Edit guidance for PRs
- Small fixes: follow existing file structure, update `ApiConstants` for URL changes rather than patching multiple services.
- When adding new endpoints, update or add models under `lib/models/` and unit-test parsing where possible.

If anything above is ambiguous or you want more detail (example request/response JSON, CI steps, or preferred emulator/device to test against), tell me what to expand.
