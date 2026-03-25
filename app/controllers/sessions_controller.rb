class SessionsController < ApplicationController
  skip_before_action :require_authentication

  def new
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      set_sso_session(user)
      redirect_to root_path, notice: "Welcome back, #{user.display_name}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    SessionChannel.broadcast_to(current_user, { type: "logout" }) if current_user
    reset_session
    redirect_to login_path, notice: "Logged out."
  end
end
