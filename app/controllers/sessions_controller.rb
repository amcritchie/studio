class SessionsController < ApplicationController
  skip_before_action :require_authentication

  def new
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      set_app_session(user)
      redirect_to root_path, notice: "Welcome back, #{user.display_name}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def sso_continue
    return redirect_to login_path unless sso_user_available?

    user = User.find_by(email: session[:sso_email])
    unless user
      user = User.new(
        email:    session[:sso_email],
        name:     session[:sso_name],
        provider: session[:sso_provider],
        uid:      session[:sso_uid],
        password: SecureRandom.hex(16)
      )
      Studio.configure_sso_user.call(user)
      rescue_and_log(target: user) do
        user.save!
      end
    end

    set_app_session(user)
    redirect_to root_path, notice: Studio.welcome_message.call(user)
  rescue StandardError => e
    redirect_to login_path, alert: "Could not continue session. Please log in."
  end

  def destroy
    clear_app_session
    redirect_to login_path, notice: "Logged out."
  end
end
