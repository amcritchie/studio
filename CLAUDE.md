# Studio Engine

Shared Rails engine gem for McRitchie apps. Provides auth, error handling, and common models so both apps stay in sync.

- **GitHub**: https://github.com/amcritchie/studio
- **Gem name**: `studio` (hosted on GitHub, not RubyGems — name "studio" is taken there)
- **Version**: 0.2.3
- **Consumed by**: McRitchie Studio (`mcritchie_studio/`) and Turf Monster (`turf_monster/`)

## Architecture

**Non-isolated engine** — no `isolate_namespace`. All classes merge into the host app's namespace (`ErrorLog`, not `Studio::ErrorLog`). Host app files take precedence over engine files automatically (Rails view/controller lookup order).

**Concern, not base class** — `Studio::ErrorHandling` is included in each app's `ApplicationController`. Contains auth helpers + two-layer error handling.

**Routes via helper** — `Studio.routes(self)` draws routes into the host's router. No `mount`. Route helpers (`login_path`, `error_logs_path`) work identically in both apps.

**Config via procs** — `Studio.configure` block in each app's `config/initializers/studio.rb` sets app-specific behavior (registration params, welcome message, new user setup).

## What's in the Engine

### Controllers
- `ErrorLogsController` — public index (ILIKE search) + show (slug lookup)
- `SessionsController` — email/password login, logout
- `OmniauthCallbacksController` — Google OAuth callback + failure (overridden in Turf Monster for merge support)
- `RegistrationsController` — signup with configurable params via `Studio.registration_params`

### Concern
- `Studio::ErrorHandling` — `current_user`, `logged_in?`, `require_authentication`, `set_sso_session`, `create_sso_user`, `rescue_and_log`, `create_error_log`, `handle_not_found`, `handle_unexpected_error`

### Models
- `ErrorLog` — polymorphic target/parent, `capture!(exception)`, cleaned backtrace
- `Sluggable` concern — `before_save :set_slug`, `to_param` returns slug

### Views
- `error_logs/index.html.erb` — Alpine.js search with loading spinner
- `error_logs/show.html.erb` — backtrace, target/parent with copy-to-clipboard, JSON dump
- `sessions/new.html.erb` — generic login (apps override with branded versions)
- `registrations/new.html.erb` — generic signup, conditional name field based on config

## Configuration

```ruby
# config/initializers/studio.rb
Studio.configure do |config|
  config.app_name = "My App"
  config.welcome_message = ->(user) { "Welcome, #{user.display_name}!" }
  config.registration_params = [:name, :email, :password, :password_confirmation]
  config.configure_new_user = ->(user) { }  # e.g. user.balance_cents = 0
  config.configure_sso_user = ->(user) { }  # set app-specific defaults for cross-app auto-provisioned users
end
```

## Cross-App SSO

The engine provides SSO across `*.mcritchie.studio` subdomains via a shared `_studio_session` cookie.

- **`set_sso_session(user)`** — stores `user_id`, `user_email`, `user_name`, `user_provider`, `user_uid`, `wallet_address` in session. Called by all auth controllers on login/signup.
- **`current_user`** — tries `user_id` first (fast path), falls back to `user_email` lookup, auto-provisions via `create_sso_user` if no local user exists.
- **`create_sso_user`** — returns nil early if `user_email` is blank (wallet-only users can't SSO cross-app). Otherwise builds a User from session data with random password, calls `Studio.configure_sso_user` for app-specific defaults.
- **Logout** — `reset_session` clears the shared cookie, logging out across all apps.
- **Requirements**: Both apps must share `SECRET_KEY_BASE` and use identical `session_store.rb` config.
- **Wallet-only users**: Cannot SSO cross-app because email is the sync key. Once they add an email, SSO works.

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
