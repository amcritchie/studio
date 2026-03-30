module Studio
  module ColorScale
    # Mix ratios: how much white (lighter) or black (darker) to mix
    LIGHT_RATIOS = {
      50  => 0.95,
      100 => 0.85,
      200 => 0.70,
      300 => 0.50,
      400 => 0.30
    }.freeze

    DARK_RATIOS = {
      600 => 0.15,
      700 => 0.30,
      800 => 0.45,
      900 => 0.60
    }.freeze

    # Generate a full 50-900 shade scale from a base hex color.
    # 500 = base color, lighter shades mix toward white, darker toward black.
    def self.generate(hex)
      r, g, b = hex_to_rgb(hex)
      scale = { 500 => hex.upcase }

      LIGHT_RATIOS.each do |shade, ratio|
        scale[shade] = rgb_to_hex(
          (r + (255 - r) * ratio).round,
          (g + (255 - g) * ratio).round,
          (b + (255 - b) * ratio).round
        )
      end

      DARK_RATIOS.each do |shade, ratio|
        scale[shade] = rgb_to_hex(
          (r * (1 - ratio)).round,
          (g * (1 - ratio)).round,
          (b * (1 - ratio)).round
        )
      end

      scale.sort.to_h
    end

    def self.lighten(hex, amount)
      r, g, b = hex_to_rgb(hex)
      rgb_to_hex(
        (r + (255 - r) * amount).round,
        (g + (255 - g) * amount).round,
        (b + (255 - b) * amount).round
      )
    end

    def self.darken(hex, amount)
      r, g, b = hex_to_rgb(hex)
      rgb_to_hex(
        (r * (1 - amount)).round,
        (g * (1 - amount)).round,
        (b * (1 - amount)).round
      )
    end

    def self.hex_to_rgb(hex)
      hex = hex.delete("#")
      [
        hex[0..1].to_i(16),
        hex[2..3].to_i(16),
        hex[4..5].to_i(16)
      ]
    end

    def self.rgb_to_hex(r, g, b)
      "#%02X%02X%02X" % [r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)]
    end

    def self.with_opacity(hex, opacity)
      r, g, b = hex_to_rgb(hex)
      "rgba(#{r},#{g},#{b},#{opacity})"
    end
  end
end
