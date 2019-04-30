module SsoOpenid
  module ApplicationHelper
    def sso_openid_sign_in(admin, options = {})
      store_in_session = options.key?(:store) ? options[:store] : true
      if store_in_session
        session[:admin_uid] = admin.uid
        session[:admin_id] = admin.id
      end
      after_sso_sign_in_call_back
      @current_admin = admin
    end

    def sso_openid_sign_out
      session.delete(:admin_uid)
      session.delete(:admin_id)
      reset_session
    end

    def after_sso_sign_in_call_back
      # This can be overridden in the including application
      # to run processes after a user successfully signs in.
    end

    def current_admin
      return @current_admin if @current_admin
      return nil if session[:admin_uid].nil?
      @current_admin = ::Admin.find_by(uid: session[:admin_uid], id: session[:admin_id])
    end

    def authenticate_admin!
      if current_admin.present?
        return true
      else
        session[:stored_location] = request.path
        redirect_to sso_openid.auth_path(params)
      end
    end

    def stored_location
      session.delete(:stored_location)
    end
  end
end
