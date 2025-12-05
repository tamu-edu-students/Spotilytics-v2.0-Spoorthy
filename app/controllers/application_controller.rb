require "ostruct"

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_user, :logged_in?, :spotify_user_id

  def current_user
    return nil unless session[:spotify_user]
    @current_user ||= OpenStruct.new(session[:spotify_user])
  end

  def logged_in?
    current_user.present?
  end

  def spotify_user_id
    user = session[:spotify_user] || {}
    user["id"] || user[:id]
  end

  def require_spotify_auth!
    return if session[:spotify_token].present?
    redirect_to root_path, alert: "Please sign in with Spotify first."
  end

  # Hidden top tracks stored in session per Spotify user id and time_range.
  helper_method :hidden_top_tracks_for_user, :hidden_top_track_count_for

  def hidden_top_tracks_for_user(user_id = current_user&.id)
    return {} unless user_id
    session[:hidden_top_tracks] ||= {}
    session[:hidden_top_tracks][user_id] ||= {
      "short_term" => [],
      "medium_term" => [],
      "long_term" => []
    }
    session[:hidden_top_tracks][user_id]
  end

  def hidden_top_track_count_for(time_range, user_id = current_user&.id)
    hidden_top_tracks_for_user(user_id)[time_range].to_a.size
  end

  def add_hidden_top_track(time_range, track_id, user_id = current_user&.id)
    return false unless user_id && time_range.present? && track_id.present?
    ht = hidden_top_tracks_for_user(user_id)
    arr = ht[time_range] ||= []
    return true if arr.include?(track_id)
    return false if arr.size >= 5
    arr << track_id
    session[:hidden_top_tracks][user_id] = ht
    true
  end

  def remove_hidden_top_track(time_range, track_id, user_id = current_user&.id)
    return false unless user_id && time_range.present? && track_id.present?
    ht = hidden_top_tracks_for_user(user_id)
    arr = ht[time_range] ||= []
    arr.delete(track_id)
    session[:hidden_top_tracks][user_id] = ht
    true
  end
end
