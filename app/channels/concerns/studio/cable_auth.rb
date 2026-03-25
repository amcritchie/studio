module Studio
  module CableAuth
    extend ActiveSupport::Concern

    included do
      identified_by :current_user
    end

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      session = cookies.encrypted["_studio_session"]
      return reject_unauthorized_connection unless session

      user = User.find_by(id: session["user_id"])
      user ||= User.find_by(email: session["user_email"]) if session["user_email"].present?
      user || reject_unauthorized_connection
    end
  end
end
