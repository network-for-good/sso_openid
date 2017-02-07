module SsoOpenid
  module ApplicationHelper
    def sign_in(admin)
      if params[:session] && params[:session][:remember_me] == '1'
        cookies.permanent[:admin_uid] = admin.uid
      else
        cookies[:admin_uid] = admin.uid
      end
    end

    def sign_out
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
