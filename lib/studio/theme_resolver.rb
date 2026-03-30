module Studio
  class ThemeResolver
    ROLES = %i[primary accent1 accent2 warning danger dark light].freeze

    attr_reader :colors

    # colors: hash of role => hex string (e.g. { primary: "#8E82FE", dark: "#1A1535", ... })
    def initialize(colors = {})
      @colors = colors.symbolize_keys
    end

    def to_css
      dark_vars  = dark_mode_vars.map { |k, v| "  #{k}: #{v};" }.join("\n")
      light_vars = light_mode_vars.map { |k, v| "  #{k}: #{v};" }.join("\n")

      <<~CSS
        :root, .dark {
        #{dark_vars}
        }

        html:not(.dark) {
        #{light_vars}
        }
      CSS
    end

    def dark_mode_vars
      dark_scale  = ColorScale.generate(colors[:dark] || "#1A1535")
      cta_scale   = ColorScale.generate(colors[:primary] || "#8E82FE")

      {
        "--color-page"           => colors[:dark] || "#1A1535",
        "--color-surface"        => dark_scale[400],
        "--color-surface-alt"    => dark_scale[600],
        "--color-inset"          => dark_scale[800],
        "--color-text"           => "#ffffff",
        "--color-text-body"      => "#e2e8f0",
        "--color-text-secondary" => "#94a3b8",
        "--color-text-muted"     => "#64748b",
        "--color-border"         => ColorScale.with_opacity(dark_scale[300], 0.2),
        "--color-border-strong"  => ColorScale.with_opacity(dark_scale[300], 0.4),
        "--color-shadow"         => "transparent",
        "--color-cta"            => colors[:primary] || "#8E82FE",
        "--color-cta-hover"      => cta_scale[700],
        "--color-success"        => colors[:accent1] || "#06D6A0",
        "--color-warning"        => colors[:warning] || "#FF7C47",
        "--color-danger"         => colors[:danger] || "#EF4444"
      }
    end

    def light_mode_vars
      light_scale = ColorScale.generate(colors[:light] || "#f8fafc")

      {
        "--color-page"           => colors[:light] || "#f8fafc",
        "--color-surface"        => "#ffffff",
        "--color-surface-alt"    => light_scale[100],
        "--color-inset"          => light_scale[200],
        "--color-text"           => "#0f172a",
        "--color-text-body"      => "#334155",
        "--color-text-secondary" => "#64748b",
        "--color-text-muted"     => "#94a3b8",
        "--color-border"         => light_scale[200],
        "--color-border-strong"  => light_scale[300],
        "--color-shadow"         => "rgba(0,0,0,0.05)"
      }
    end
  end
end
