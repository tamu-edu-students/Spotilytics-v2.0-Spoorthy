require "ostruct"

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_user, :logged_in?

  def current_user
    return nil unless session[:spotify_user]
    @current_user ||= OpenStruct.new(session[:spotify_user])
  end

  def logged_in?
    current_user.present?
  end

  def require_spotify_auth!
    return if session[:spotify_token].present?
    redirect_to root_path, alert: "Please sign in with Spotify first."
  end
end
