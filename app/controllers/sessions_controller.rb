class SessionsController < ApplicationController
  before_action :authenticate_user!, only: [:me]

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      render json: {
        message: "Logged in",
        user: { id: user.id, email: user.email }
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def destroy
    reset_session
    render json: { message: "Logged out" }, status: :ok
  end

  def me
    render json: { id: current_user.id, email: current_user.email }
  end
end