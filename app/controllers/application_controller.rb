class ApplicationController < ActionController::API
	rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
	rescue_from ActionController::ParameterMissing, with: :render_bad_request
	private

	def current_user
		@current_user ||= User.find_by(id: session[:user_id])
	end

	def authenticate_user!
		return if current_user
		render json: { error: "Unauthorized" }, status: :unauthorized
	end

	def render_not_found(e)
		render json: { error: e.message }, status: :not_found
	end

	def render_bad_request(e)
		render json: { error: "Parameter wajib: #{e.param}" }, status: :bad_request
	end
	
	def render_service_error(error, status:)
		render json: { error: error.message }, status: status
	end
end
