class ThemeSettingsController < ApplicationController
  before_action :require_admin_for_theme

  def edit
    @theme_setting = ThemeSetting.current
    @defaults = Studio.theme_config
    @preview_css = Studio::ThemeResolver.new(@theme_setting.resolved_colors).to_css
  end

  def update
    @theme_setting = ThemeSetting.find_or_initialize_by(app_name: Studio.app_name)

    rescue_and_log(target: @theme_setting) do
      @theme_setting.update!(theme_params)
      Rails.cache.delete("studio/theme/#{Studio.app_name}")
      redirect_to admin_theme_edit_path, notice: "Theme saved."
    end
  rescue StandardError => e
    @defaults = Studio.theme_config
    @preview_css = Studio::ThemeResolver.new(@theme_setting.resolved_colors).to_css
    flash.now[:alert] = "Error saving theme: #{e.message}"
    render :edit, status: :unprocessable_entity
  end

  def regenerate
    Rails.cache.delete("studio/theme/#{Studio.app_name}")
    redirect_to admin_theme_edit_path, notice: "Theme cache cleared."
  end

  private

  def require_admin_for_theme
    return redirect_to root_path, alert: "Not authorized" unless logged_in? && current_user.admin?
  end

  def theme_params
    params.require(:theme_setting).permit(:primary, :accent1, :accent2, :warning, :danger, :dark, :light)
  end

  def admin_theme_edit_path
    "/admin/theme"
  end
end
