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
- `SessionsController` — email/password login, logout, `sso_login` (GET one-click SSO), `sso_continue` (POST from button)
- `OmniauthCallbacksController` — Google OAuth callback + failure (overridden in Turf Monster for merge support)
- `RegistrationsController` — signup with configurable params via `Studio.registration_params`

### Concern
- `Studio::ErrorHandling` — `current_user`, `logged_in?`, `require_authentication`, `set_app_session`, `clear_app_session`, `sso_user_available?`, `sso_display_name`, `sso_source_app`, `sso_hub_logo`, `rescue_and_log`, `create_error_log`, `handle_not_found`, `handle_unexpected_error`

### Models
- `ErrorLog` — polymorphic target/parent, `capture!(exception)`, cleaned backtrace
- `Sluggable` concern — `before_save :set_slug`, `to_param` returns slug

### Views
- `error_logs/index.html.erb` — Alpine.js search with loading spinner
- `error_logs/show.html.erb` — backtrace, target/parent with copy-to-clipboard, JSON dump
- `sessions/new.html.erb` — generic login (apps override with branded versions)
- `sessions/_sso_continue.html.erb` — "Continue as" button partial for cross-app awareness
- `registrations/new.html.erb` — generic signup, conditional name field based on config
- `components/_theme_toggle.html.erb` — sun/moon toggle button for dark/light mode

### Theme System (Shared Tailwind Config)

The engine's `studio.tailwind.config.js` defines semantic color tokens that map to CSS custom properties. Each app sets `--color-*` variables in its `application.tailwind.css` for dark and light themes.

**Tokens defined in config**: `page`, `surface`, `surface-alt`, `inset` (colors); `heading`, `body`, `secondary`, `muted` (textColor); `subtle`, `strong` (borderColor).

**FOUC prevention**: `_head.html.erb` includes a synchronous `<script>` that sets `class="dark"` from `localStorage.getItem('theme')` before any paint. Alpine theme store initialized on `alpine:init`.

**Views use semantic classes**: `bg-page`, `bg-surface`, `text-heading`, `text-body`, `border-subtle`, etc. Brand colors (`text-violet`, `bg-mint`) are static and don't use tokens.

See top-level `CLAUDE.md` for the full token reference table.

## Configuration

```ruby
# config/initializers/studio.rb (hub app — McRitchie Studio)
Studio.configure do |config|
  config.app_name = "McRitchie Studio"
  config.session_key = :studio_user_id
  config.sso_logo = "/studio-logo.svg"        # logo shown on satellite app SSO buttons
  config.welcome_message = ->(user) { "Welcome, #{user.display_name}!" }
  config.registration_params = [:name, :email, :password, :password_confirmation]
  config.configure_sso_user = ->(user) { user.role = "viewer" }
end

# config/initializers/studio.rb (satellite app — Turf Monster)
Studio.configure do |config|
  config.app_name = "Turf Monster"
  config.session_key = :turf_user_id
  config.configure_sso_user = ->(user) { user.balance_cents = 0 }
end
```

## One-Way SSO: Hub → Satellite

McRitchie Studio is the central auth hub. Satellite apps (Turf Monster, future apps) receive SSO from Studio — not the other way around. Each app has its own session key so login/logout is independent.

### Architecture

- **Hub app** (McRitchie Studio): Sets `sso_*` awareness fields in the shared session on login. Has a nav link to each satellite app's `/sso_login` for one-click SSO. Does NOT show "Continue as" on its own login page.
- **Satellite apps** (Turf Monster): Show "Continue as [name]" button on login page when hub session data exists. The button and branding come from the engine's `_sso_continue.html.erb` partial — no local override needed.
- **Shared cookie**: `_studio_session` spans `*.mcritchie.studio`. Each app reads/writes its own session key + shared `sso_*` fields.

### Session Methods

- **`set_app_session(user)`** — sets `session[Studio.session_key]` (app-specific). Only updates `sso_*` fields if this app is the source (prevents overwriting hub data when satellite logs in).
- **`set_sso_session(user)`** — alias for `set_app_session` (backwards compatibility)
- **`clear_app_session`** — deletes this app's session key. Clears `sso_*` fields only if this app is the source.
- **`current_user`** — looks up `session[Studio.session_key]`. Includes legacy migration for old `session[:user_id]` cookies.

### SSO Fields (stored in session by hub app)

`sso_email`, `sso_name`, `sso_provider`, `sso_uid`, `sso_wallet`, `sso_source`, `sso_logo`

### SSO Routes & Actions

- **`GET /sso_login`** — one-click SSO entry point. Linked from hub app nav. Auto-logs in from `sso_*` data, redirects to login if unavailable.
- **`POST /sso_continue`** — form-based SSO from the "Continue as" button on login page.

### View Helpers

- **`sso_user_available?`** — true when not logged in, `sso_email` present, and `sso_source` is a different app
- **`sso_display_name`** — name or email prefix from sso fields
- **`sso_source_app`** — which app set the sso data
- **`sso_hub_logo`** — logo path from `session[:sso_logo]` (set via `Studio.sso_logo` config)

### SSO Button Partial

`sessions/_sso_continue.html.erb` — engine-provided, renders centered "Continue as [name]" button with hub logo (from `sso_hub_logo`). Styled to match Google/Wallet sign-in buttons. Satellite apps just add `<%= render "sessions/sso_continue" %>` to their login view — no local partial needed.

### Key Design Decisions

- **One-way flow** — Studio is the hub, satellite apps are targets. Studio's login page has no "Continue as" button.
- **No auto-provisioning** — removed `create_sso_user`. Cross-app login requires explicit user action (clicking "Continue as" or the nav link).
- **Independent logout** — `clear_app_session` only removes this app's key. Logging out of a satellite doesn't affect the hub.
- **sso_source preservation** — `set_app_session` doesn't overwrite `sso_*` fields if another app set them. `clear_app_session` only clears them if this app is the source.
- **Wallet-only guard** — users with no email have no `sso_email`, so "Continue as" never appears.
- **Logo via config** — hub sets `config.sso_logo`, stored in `session[:sso_logo]`, rendered by engine partial. Satellite apps need the logo file in their `public/` folder.

### Adding a New Satellite App

1. Set `config.session_key` to a unique symbol
2. Set `config.configure_sso_user` for app-specific defaults
3. Add `<%= render "sessions/sso_continue" %>` to login view
4. Copy hub's logo to `public/` (e.g. `public/studio-logo.svg`)
5. Add the app as a nav link in the hub

### Requirements
- All apps share `SECRET_KEY_BASE` and identical `session_store.rb` config
- Each app sets a unique `config.session_key`

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
