module SsoOpenid
  module ApplicationHelper
    def sso_openid_sign_in(admin, args = {})
      if args[:remember_me].present?
        cookies.permanent[:admin_uid] = admin.uid
      else
        cookies[:admin_uid] = admin.uid
      end
      ahoy.authenticate(admin) if defined?(ahoy)
    end

    def sso_openid_sign_out
      cookies.delete(:admin_uid)
      reset_session
    end

    def current_admin
      return nil if cookies[:admin_uid].nil?
      @current_admin ||= Admin.find_by(uid: cookies[:admin_uid])
    end

    def authenticate_admin!
      if current_admin.present?
        return true
      else
        session[:stored_location] = request.path
        redirect_to SsoOpenid::Configuration.auth_path_with_provider
      end
    end

    def stored_location
      session.delete(:stored_location)
    end
  end
end
