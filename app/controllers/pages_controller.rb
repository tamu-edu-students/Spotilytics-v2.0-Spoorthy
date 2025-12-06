require "set"

class PagesController < ApplicationController
  # MERGE: Added :top_tracks from main to the list
  before_action :require_spotify_auth!, only: %i[dashboard top_artists top_tracks view_profile clear library]

  TOP_ARTIST_TIME_RANGES = [
    { key: "long_term", label: "Past Year" },
    { key: "medium_term", label: "Past 6 Months" },
    { key: "short_term", label: "Past 4 Weeks" }
  ].freeze

  def clear
    spotify_client.clear_user_cache
    redirect_to home_path, notice: "Data refreshed successfully"
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to refresh your data."
  rescue SpotifyClient::Error => e
    redirect_to home_path, alert: "We were unable to load your Spotify data right now. Please try again later."
  end

  def home
  end

  def dashboard
    # Top Artists
    @top_artists = fetch_top_artists(limit: 10)
    @primary_artist = @top_artists.first

    # Top Tracks
    @top_tracks = fetch_top_tracks(limit: 10)
    @primary_track = @top_tracks.first

    # Genre Chart
    build_genre_chart!(@top_artists)

    # Followed Artists
    @followed_artists = fetch_followed_artists(limit: 20)

    # New Releases
    @new_releases = fetch_new_releases(limit: 2)

    # MERGE: Kept these lines from feat/save-episodes-and-shows
    # Saved Content for Dashboard
    @saved_shows_dashboard = fetch_saved_shows(limit: 8)
    @saved_episodes_dashboard = fetch_saved_episodes(limit: 8)

  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to access the dashboard." and return
  rescue SpotifyClient::Error => e
    flash.now[:alert] = "We were unable to load your Spotify data right now. Please try again later."
    @top_artists = []
    @primary_artist = nil
    @top_tracks = []
    @primary_track = nil
    @genre_chart = nil
    @followed_artists = []
    @new_releases = []
    @saved_shows_dashboard = []
    @saved_episodes_dashboard = []
  end

  def view_profile
    @profile = fetch_profile()

  rescue SpotifyClient::UnauthorizedError
    Rails.logger.warn "Unauthorized dashboard access"
    redirect_to home_path, alert: "You must log in with spotify to view your profile." and return
  rescue SpotifyClient::Error => e
    Rails.logger.warn "Failed to fetch Spotify data for dashboard: #{e.message}"
    flash.now[:alert] = "We were unable to load your Spotify data right now. Please try again later."

    @profile = nil
  end

  def top_artists
    @time_ranges = TOP_ARTIST_TIME_RANGES
    @top_artists_by_range = {}
    @limits = {}

    collected_ids = []

    @time_ranges.each do |range|
      key         = range[:key]
      param_name = "limit_#{key}"
      limit       = normalize_limit(params[param_name])

      @limits[key] = limit
      artists = fetch_top_artists(limit: limit, time_range: key)
      @top_artists_by_range[key] = artists
      collected_ids.concat(extract_artist_ids(artists))
    end

    unique_ids = collected_ids.uniq

    @followed_artist_ids =
      if unique_ids.any?
        spotify_client.followed_artist_ids(unique_ids)
      else
        Set.new
      end
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to view your top artists." and return
  rescue SpotifyClient::Error => e
    if insufficient_scope?(e)
      reset_spotify_session!
      redirect_to login_path, alert: "Spotify now needs permission to manage your follows. Please sign in again."
    else
      Rails.logger.warn "Failed to fetch Spotify top artists: #{e.message}"
      flash.now[:alert] = "We were unable to load your top artists from Spotify. Please try again later."
      @top_artists_by_range = TOP_ARTIST_TIME_RANGES.each_with_object({}) { |range, acc| acc[range[:key]] = [] }
      @limits = TOP_ARTIST_TIME_RANGES.to_h { |range| [ range[:key], 10 ] }
      @followed_artist_ids = Set.new
      @time_ranges = TOP_ARTIST_TIME_RANGES
    end
  end

  # MERGE: Added this method from main
  def top_tracks
    limit = normalize_limit(params[:limit])
    @top_tracks = fetch_top_tracks(limit: limit)
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to view your top tracks." and return
  rescue SpotifyClient::Error => e
    Rails.logger.warn "Failed to fetch Spotify top tracks: #{e.message}"
    flash.now[:alert] = "We were unable to load your top tracks from Spotify. Please try again later."
    @top_tracks = []
  end

  def library
    refresh = params[:refresh_playlists].present?
    @playlists = fetch_user_playlists_all(refresh: refresh)
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to view your library." and return
  rescue SpotifyClient::Error => e
    Rails.logger.warn "Failed to fetch Spotify playlists: #{e.message}"
    flash.now[:alert] = "We were unable to load your playlists from Spotify. Please try again later."
    @playlists = []
  end

  private

  def spotify_client
    @spotify_client ||= SpotifyClient.new(session: session)
  end

  def fetch_profile
    spotify_client.profile()
  end

  def fetch_new_releases(limit:)
    spotify_client.new_releases(limit: limit)
  end

  def fetch_top_artists(limit:, time_range: "long_term")
    spotify_client.top_artists(limit: limit, time_range: time_range)
  end

  # MERGE: Used the version from 'main' because it includes the hiding logic
  def fetch_top_tracks(limit:)
    tracks = spotify_client.top_tracks(limit: limit, time_range: "long_term")
    user_id = session.dig(:spotify_user, "id")
    # This logic was missing in your feature branch but present in main
    if user_id.present? && defined?(hidden_top_tracks_for_user)
      # I added a 'defined?' check just in case that helper isn't merged yet,
      # but if you have the helper in this file (or included), remove the 'defined?' check.
      hidden = hidden_top_tracks_for_user(user_id) rescue nil
      if hidden
         tracks = tracks.reject { |t| hidden["long_term"].include?(t.id) }
      end
    end
    tracks
  end

  def fetch_followed_artists(limit:)
    spotify_client.followed_artists(limit: limit)
  end

  def fetch_user_playlists(limit:, offset: 0)
    spotify_client.user_playlists(limit: limit, offset: offset)
  end

  def fetch_user_playlists_all(refresh: false)
    spotify_client.user_playlists_all(skip_cache: refresh)
  end

  # MERGE: Added these methods from feat/save-episodes-and-shows
  def fetch_saved_shows(limit:)
    spotify_client.saved_shows(limit: limit).items
  rescue SpotifyClient::Error
    []
  end

  def fetch_saved_episodes(limit:)
    spotify_client.saved_episodes(limit: limit).items
  rescue SpotifyClient::Error
    []
  end

  # Accept only 10, 25, 50; default to 10
  def normalize_limit(value)
    v = value.to_i
    [ 10, 25, 50 ].include?(v) ? v : 10
  end

  def build_genre_chart!(artists)
    counts = Hash.new(0)

    Array(artists).each do |a|
      genres = a.respond_to?(:genres) ? a.genres : Array(a["genres"])
      next if genres.blank?
      genres.each do |g|
        g = g.to_s.strip.downcase
        next if g.empty?
        counts[g] += 1         # count artists per genre
      end
    end

    if counts.empty?
      @genre_chart = nil
      return
    end

    sorted = counts.sort_by { |(_, c)| -c }
    top_n = 8
    top   = sorted.first(top_n)
    other = sorted.drop(top_n).sum { |(_, c)| c }

    labels = top.map { |(g, _)| g.split.map(&:capitalize).join(" ") }
    data   = top.map(&:last)
    if other > 0
      labels << "Other"
      data   << other
    end

    @genre_chart = {
      labels: labels,
      datasets: [
        {
          label: "Top Artist Genres",
          data: data
        }
      ]
    }
  end

  def extract_artist_ids(artists)
    Array(artists).map { |artist| artist_identifier(artist) }.compact
  end

  def artist_identifier(artist)
    if artist.respond_to?(:id)
      artist.id
    elsif artist.respond_to?(:[])
      artist["id"] || artist[:id]
    end
  end

  def insufficient_scope?(error)
    error.message.to_s.downcase.include?("insufficient client scope")
  end

  def reset_spotify_session!
    session.delete(:spotify_token)
    session.delete(:spotify_refresh_token)
    session.delete(:spotify_expires_at)
  end
end
