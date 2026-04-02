# frozen_string_literal: true

require_relative "../../test_helper"

class Studio::ColorScaleTest < Minitest::Test
  # ── hex_to_rgb ──────────────────────────────────────────────

  def test_hex_to_rgb_parses_standard_hex
    assert_equal [142, 130, 254], Studio::ColorScale.hex_to_rgb("#8E82FE")
  end

  def test_hex_to_rgb_parses_without_hash
    assert_equal [142, 130, 254], Studio::ColorScale.hex_to_rgb("8E82FE")
  end

  def test_hex_to_rgb_full_black
    assert_equal [0, 0, 0], Studio::ColorScale.hex_to_rgb("#000000")
  end

  def test_hex_to_rgb_full_white
    assert_equal [255, 255, 255], Studio::ColorScale.hex_to_rgb("#FFFFFF")
  end

  def test_hex_to_rgb_lowercase
    assert_equal [75, 175, 80], Studio::ColorScale.hex_to_rgb("#4baf50")
  end

  # ── rgb_to_hex ──────────────────────────────────────────────

  def test_rgb_to_hex_standard
    assert_equal "#8E82FE", Studio::ColorScale.rgb_to_hex(142, 130, 254)
  end

  def test_rgb_to_hex_black
    assert_equal "#000000", Studio::ColorScale.rgb_to_hex(0, 0, 0)
  end

  def test_rgb_to_hex_white
    assert_equal "#FFFFFF", Studio::ColorScale.rgb_to_hex(255, 255, 255)
  end

  def test_rgb_to_hex_clamps_above_255
    assert_equal "#FFFFFF", Studio::ColorScale.rgb_to_hex(300, 999, 256)
  end

  def test_rgb_to_hex_clamps_below_0
    assert_equal "#000000", Studio::ColorScale.rgb_to_hex(-10, -1, -255)
  end

  def test_rgb_to_hex_mixed_clamp
    assert_equal "#FF0080", Studio::ColorScale.rgb_to_hex(300, -5, 128)
  end

  # ── roundtrip ───────────────────────────────────────────────

  def test_hex_rgb_roundtrip
    hex = "#4BAF50"
    r, g, b = Studio::ColorScale.hex_to_rgb(hex)
    assert_equal hex, Studio::ColorScale.rgb_to_hex(r, g, b)
  end

  # ── lighten ─────────────────────────────────────────────────

  def test_lighten_zero_returns_same_color
    hex = "#4BAF50"
    assert_equal hex.upcase, Studio::ColorScale.lighten(hex, 0.0).upcase
  end

  def test_lighten_one_returns_white
    assert_equal "#FFFFFF", Studio::ColorScale.lighten("#4BAF50", 1.0)
  end

  def test_lighten_black_by_half
    # Black (0,0,0) lightened by 0.5 = (127.5,127.5,127.5) -> (128,128,128)
    result = Studio::ColorScale.lighten("#000000", 0.5)
    r, g, b = Studio::ColorScale.hex_to_rgb(result)
    assert_equal 128, r
    assert_equal 128, g
    assert_equal 128, b
  end

  def test_lighten_moves_toward_white
    original = Studio::ColorScale.hex_to_rgb("#8E82FE")
    lightened = Studio::ColorScale.hex_to_rgb(Studio::ColorScale.lighten("#8E82FE", 0.3))
    # Each channel should be >= original
    3.times { |i| assert lightened[i] >= original[i], "Channel #{i} should be lighter" }
  end

  def test_lighten_white_stays_white
    assert_equal "#FFFFFF", Studio::ColorScale.lighten("#FFFFFF", 0.5)
  end

  # ── darken ──────────────────────────────────────────────────

  def test_darken_zero_returns_same_color
    hex = "#4BAF50"
    assert_equal hex.upcase, Studio::ColorScale.darken(hex, 0.0).upcase
  end

  def test_darken_one_returns_black
    assert_equal "#000000", Studio::ColorScale.darken("#4BAF50", 1.0)
  end

  def test_darken_white_by_half
    # White (255,255,255) darkened by 0.5 = (127.5,127.5,127.5) -> (128,128,128)
    result = Studio::ColorScale.darken("#FFFFFF", 0.5)
    r, g, b = Studio::ColorScale.hex_to_rgb(result)
    assert_equal 128, r
    assert_equal 128, g
    assert_equal 128, b
  end

  def test_darken_moves_toward_black
    original = Studio::ColorScale.hex_to_rgb("#8E82FE")
    darkened = Studio::ColorScale.hex_to_rgb(Studio::ColorScale.darken("#8E82FE", 0.3))
    # Each channel should be <= original
    3.times { |i| assert darkened[i] <= original[i], "Channel #{i} should be darker" }
  end

  def test_darken_black_stays_black
    assert_equal "#000000", Studio::ColorScale.darken("#000000", 0.5)
  end

  # ── generate ────────────────────────────────────────────────

  def test_generate_returns_hash_with_all_shades
    scale = Studio::ColorScale.generate("#8E82FE")
    expected_keys = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900]
    assert_equal expected_keys, scale.keys.sort
  end

  def test_generate_500_is_base_color
    scale = Studio::ColorScale.generate("#8E82FE")
    assert_equal "#8E82FE", scale[500]
  end

  def test_generate_lower_shades_are_lighter
    scale = Studio::ColorScale.generate("#8E82FE")
    base_r, base_g, base_b = Studio::ColorScale.hex_to_rgb(scale[500])
    base_luminance = base_r + base_g + base_b

    [50, 100, 200, 300, 400].each do |shade|
      r, g, b = Studio::ColorScale.hex_to_rgb(scale[shade])
      shade_luminance = r + g + b
      assert shade_luminance >= base_luminance,
        "Shade #{shade} (#{scale[shade]}) should be lighter than 500 (#{scale[500]})"
    end
  end

  def test_generate_higher_shades_are_darker
    scale = Studio::ColorScale.generate("#8E82FE")
    base_r, base_g, base_b = Studio::ColorScale.hex_to_rgb(scale[500])
    base_luminance = base_r + base_g + base_b

    [600, 700, 800, 900].each do |shade|
      r, g, b = Studio::ColorScale.hex_to_rgb(scale[shade])
      shade_luminance = r + g + b
      assert shade_luminance <= base_luminance,
        "Shade #{shade} (#{scale[shade]}) should be darker than 500 (#{scale[500]})"
    end
  end

  def test_generate_is_sorted_by_shade_key
    scale = Studio::ColorScale.generate("#4BAF50")
    assert_equal scale.keys, scale.keys.sort
  end

  def test_generate_lighter_shades_are_monotonically_ordered
    scale = Studio::ColorScale.generate("#8E82FE")
    light_shades = [50, 100, 200, 300, 400, 500]
    luminances = light_shades.map do |shade|
      r, g, b = Studio::ColorScale.hex_to_rgb(scale[shade])
      r + g + b
    end
    # 50 is lightest, 500 is darkest in this range -> luminances should be descending
    assert_equal luminances, luminances.sort.reverse,
      "Shades 50-500 should decrease in lightness"
  end

  def test_generate_darker_shades_are_monotonically_ordered
    scale = Studio::ColorScale.generate("#8E82FE")
    dark_shades = [500, 600, 700, 800, 900]
    luminances = dark_shades.map do |shade|
      r, g, b = Studio::ColorScale.hex_to_rgb(scale[shade])
      r + g + b
    end
    # 500 is lightest, 900 is darkest -> luminances should be descending
    assert_equal luminances, luminances.sort.reverse,
      "Shades 500-900 should decrease in lightness"
  end

  def test_generate_black_produces_valid_scale
    scale = Studio::ColorScale.generate("#000000")
    assert_equal "#000000", scale[500]
    # Light shades should be gray (moving toward white)
    assert_equal "#F2F2F2", scale[50]
    # Dark shades of black are still black
    assert_equal "#000000", scale[900]
  end

  def test_generate_white_produces_valid_scale
    scale = Studio::ColorScale.generate("#FFFFFF")
    assert_equal "#FFFFFF", scale[500]
    # All lighter shades of white are still white
    assert_equal "#FFFFFF", scale[50]
    # Darker shades move toward black
    r, g, b = Studio::ColorScale.hex_to_rgb(scale[900])
    assert r < 255 && g < 255 && b < 255, "Shade 900 of white should be darker"
  end

  # ── with_opacity ────────────────────────────────────────────

  def test_with_opacity
    result = Studio::ColorScale.with_opacity("#8E82FE", 0.5)
    assert_equal "rgba(142,130,254,0.5)", result
  end

  def test_with_opacity_full
    result = Studio::ColorScale.with_opacity("#000000", 1)
    assert_equal "rgba(0,0,0,1)", result
  end
end
