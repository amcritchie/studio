require "studio/version"
require "studio/engine"
require "studio/color_scale"
require "studio/theme_resolver"

module Studio
  mattr_accessor :app_name,            default: "Studio"
  mattr_accessor :session_key,         default: :user_id
  mattr_accessor :welcome_message,     default: ->(user) { "Welcome, #{user.display_name}!" }
  mattr_accessor :registration_params, default: [:name, :email, :password, :password_confirmation]
  mattr_accessor :configure_new_user,  default: ->(user) {}
  mattr_accessor :configure_sso_user,  default: ->(user) {}
  mattr_accessor :sso_logo,            default: nil

  # Theme role colors (7 roles)
  mattr_accessor :theme_primary,  default: "#8E82FE"
  mattr_accessor :theme_accent1,  default: "#06D6A0"
  mattr_accessor :theme_accent2,  default: nil
  mattr_accessor :theme_warning,  default: "#FF7C47"
  mattr_accessor :theme_danger,   default: "#EF4444"
  mattr_accessor :theme_dark,     default: "#1A1535"
  mattr_accessor :theme_light,    default: "#f8fafc"

  def self.configure
    yield self
  end

  def self.theme_config
    {
      primary: theme_primary,
      accent1: theme_accent1,
      accent2: theme_accent2,
      warning: theme_warning,
      danger:  theme_danger,
      dark:    theme_dark,
      light:   theme_light
    }.compact
  end

  def self.routes(router)
    router.instance_exec do
      get  "login",  to: "sessions#new"
      post "login",  to: "sessions#create"
      post "sso_continue", to: "sessions#sso_continue"
      get  "sso_login",    to: "sessions#sso_login"
      get  "logout", to: "sessions#destroy"
      get  "signup", to: "registrations#new"
      post "signup", to: "registrations#create"
      get  "auth/:provider/callback", to: "omniauth_callbacks#create"
      get  "auth/failure", to: "omniauth_callbacks#failure"
      resources :error_logs, only: [:index, :show]

      # Theme admin
      get   "admin/theme/edit",       to: "theme_settings#edit",       as: :admin_theme_edit
      patch "admin/theme/update",     to: "theme_settings#update",     as: :admin_theme_update
      post  "admin/theme/regenerate", to: "theme_settings#regenerate", as: :admin_theme_regenerate
    end
  end
end
