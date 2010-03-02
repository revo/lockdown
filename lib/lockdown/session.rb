module Lockdown
  module Session

    protected

    def add_lockdown_session_values(user = nil)
      user ||= current_user

      if user
        session[:current_user_id] = user.id
        session[:access_rights] = :all if user.user_group.name.downcase == Lockdown.administrator_group_symbol.to_s
      end
    end

    def logged_in?
      current_user_id.to_i > 0
    end

    def current_user_id
      session[:current_user_id]
    end

    def current_user_is_admin?
      session[:access_rights] == :all
    end

    def reset_lockdown_session
      [:expiry_time, :current_user_id, :access_rights].each do |val|
        session[val] = nil if session[val]
      end
    end 

    alias_method :nil_lockdown_values, :reset_lockdown_session
  end # Session
end # Lockdown
