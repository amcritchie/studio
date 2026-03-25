# Studio Engine

Shared Rails engine gem for McRitchie apps. Provides auth, error handling, and common models so both apps stay in sync.

- **GitHub**: https://github.com/amcritchie/studio
- **Gem name**: `studio` (hosted on GitHub, not RubyGems — name "studio" is taken there)
- **Version**: 0.2.4
- **Consumed by**: McRitchie Studio (`mcritchie_studio/`) and Turf Monster (`turf_monster/`)

## Architecture

**Non-isolated engine** — no `isolate_namespace`. All classes merge into the host app's namespace (`ErrorLog`, not `Studio::ErrorLog`). Host app files take precedence over engine files automatically (Rails view/controller lookup order).

**Concern, not base class** — `Studio::ErrorHandling` is included in each app's `ApplicationController`. Contains auth helpers + two-layer error handling.

**Routes via helper** — `Studio.routes(self)` draws routes into the host's router. No `mount`. Route helpers (`login_path`, `error_logs_path`) work identically in both apps.

**Config via procs** — `Studio.configure` block in each app's `config/initializers/studio.rb` sets app-specific behavior (registration params, welcome message, new user setup, session key).

## What's in the Engine

### Controllers
- `ErrorLogsController` — public index (ILIKE search) + show (slug lookup)
- `SessionsController` — email/password login, logout, `sso_continue` (one-click cross-app login)
- `OmniauthCallbacksController` — Google OAuth callback + failure (overridden in Turf Monster for merge support)
- `RegistrationsController` — signup with configurable params via `Studio.registration_params`

### Concern
- `Studio::ErrorHandling` — `current_user`, `logged_in?`, `require_authentication`, `set_app_session`, `clear_app_session`, `sso_user_available?`, `sso_display_name`, `sso_source_app`, `rescue_and_log`, `create_error_log`, `handle_not_found`, `handle_unexpected_error`

### Models
- `ErrorLog` — polymorphic target/parent, `capture!(exception)`, cleaned backtrace
- `Sluggable` concern — `before_save :set_slug`, `to_param` returns slug

### Views
- `error_logs/index.html.erb` — Alpine.js search with loading spinner
- `error_logs/show.html.erb` — backtrace, target/parent with copy-to-clipboard, JSON dump
- `sessions/new.html.erb` — generic login (apps override with branded versions)
- `sessions/_sso_continue.html.erb` — "Continue as" button partial for cross-app awareness
- `registrations/new.html.erb` — generic signup, conditional name field based on config

## Configuration

```ruby
# config/initializers/studio.rb
Studio.configure do |config|
  config.app_name = "My App"
  config.session_key = :my_app_user_id       # per-app session key (default: :user_id)
  config.welcome_message = ->(user) { "Welcome, #{user.display_name}!" }
  config.registration_params = [:name, :email, :password, :password_confirmation]
  config.configure_new_user = ->(user) { }   # e.g. user.balance_cents = 0
  config.configure_sso_user = ->(user) { }   # set app-specific defaults for cross-app users created via sso_continue
end
```

## Independent Per-App Sessions with Cross-App Awareness

Each app has its own session key (e.g. `:turf_user_id`, `:studio_user_id`) so login/logout is independent. A shared `_studio_session` cookie still spans `*.mcritchie.studio` subdomains, but only `sso_*` awareness fields are shared.

### Session Methods

- **`set_app_session(user)`** — sets `session[Studio.session_key]` (app-specific) + `sso_*` fields (shared awareness: `sso_email`, `sso_name`, `sso_provider`, `sso_uid`, `sso_wallet`, `sso_source`). Called by all auth controllers on login/signup.
- **`set_sso_session(user)`** — alias for `set_app_session` (backwards compatibility, prefer `set_app_session` in new code)
- **`clear_app_session`** — deletes only this app's session key, preserves `sso_*` fields so the other app can show "Continue as" button
- **`current_user`** — looks up `session[Studio.session_key]`. Includes legacy migration: if `session[:user_id]` exists and `session_key != :user_id`, auto-migrates to new key.

### Cross-App "Continue As" Flow

- **`sso_user_available?`** — true when not logged in, `sso_email` present, and `sso_source` is a different app
- **`sso_display_name`** — name or email prefix from sso fields
- **`sso_source_app`** — which app the user is logged into
- **`sso_continue` action** — POST endpoint that finds/creates a local user from `sso_*` session data, logs them in. No auto-provisioning — user must click the button.
- **`_sso_continue.html.erb` partial** — renders "Continue as [name] (from [app])" button + divider. Apps render this at top of their login views.

### Key Design Decisions

- **No auto-provisioning** — removed `create_sso_user`. Cross-app login is now explicit (user clicks "Continue as" button).
- **Independent logout** — `clear_app_session` only removes this app's key. Logging out of one app does not affect the other.
- **Wallet-only guard** — users with no email have no `sso_email`, so "Continue as" never appears for them.
- **Legacy migration** — old `session[:user_id]` cookies auto-migrate to new per-app key on first visit. Can be removed after ~2 weeks.

### Requirements
- Both apps must share `SECRET_KEY_BASE` and use identical `session_store.rb` config
- Each app must set `config.session_key` to a unique symbol in its initializer

## When to Add Code Here vs in the App

**Add to engine when:**
- Both apps need the same controller, model, or view
- It's auth, error handling, or shared infrastructure
- A view is identical between apps (error logs)

**Keep in the app when:**
- It's app-specific business logic (tasks, contests, picks)
- The view has app-specific branding (login/signup pages)
- It's a model that only exists in one app
- It's app-specific auth logic (wallet auth, account merging — Turf Monster only)

**Override pattern:** To customize an engine view or controller, create the same file path in the app. Rails loads app files before engine files.

## Updating the Engine

1. Make changes in `/Users/alex/projects/studio/`
2. Commit and push to GitHub
3. In each app: `bundle update studio` to pull the latest
4. Test both apps after updating

## Code Standards

Follow the same conventions as the top-level `CLAUDE.md`:
- `find_by` not `find`, nil guards after lookups
- Bang methods inside `rescue_and_log`
- Every model gets timestamps and a slug
- Sluggable concern for URL-facing models
