class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def root
    render text: 'root path', status: :ok
  end

  def sso_openid_after_sign_in_path
    root_path
  end

  def sso_openid_after_sign_out_path
    root_path
  end

  def sso_openid_failure_path
    root_path
  end
end