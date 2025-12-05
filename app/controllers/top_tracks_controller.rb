class TopTracksController < ApplicationController
  before_action :require_spotify_auth!

  TIME_RANGES = [
    { key: "short_term",  label: "Last 4 Weeks" },
    { key: "medium_term", label: "Last 6 Months" },
    { key: "long_term",   label: "Last 1 Year" }
  ].freeze

  def index
    client = SpotifyClient.new(session: session)

    @limits = {
      "short_term"  => normalize_limit(params[:limit_short_term]),
      "medium_term" => normalize_limit(params[:limit_medium_term]),
      "long_term"   => normalize_limit(params[:limit_long_term])
    }

    @time_ranges = TIME_RANGES

    begin
      @tracks_short  = client.top_tracks(limit: @limits["short_term"],  time_range: "short_term")
      @tracks_medium = client.top_tracks(limit: @limits["medium_term"], time_range: "medium_term")
      @tracks_long   = client.top_tracks(limit: @limits["long_term"],   time_range: "long_term")

      # Filter out any hidden tracks for the current user per time range
      user_id = spotify_user_id
      if user_id.present?
        hidden = hidden_top_tracks_for_user(user_id)

        # Build arrays of hidden track objects so the user can unhide them from this page.
        begin
          short_ids = Array(hidden["short_term"]).map(&:to_s)
          medium_ids = Array(hidden["medium_term"]).map(&:to_s)
          long_ids = Array(hidden["long_term"]).map(&:to_s)

          # Use the existing top_tracks endpoint where possible to avoid additional track endpoint calls.
          # We'll fetch up to 50 items (Spotify's max) for each time range and then pick out any hidden ids.
          @hidden_short = []
          if short_ids.any?
            candidates = client.top_tracks(limit: [ 50, short_ids.size ].max, time_range: "short_term")
            map = candidates.index_by(&:id)
            @hidden_short = short_ids.map { |id| map[id] }.compact
          end

          @hidden_medium = []
          if medium_ids.any?
            candidates = client.top_tracks(limit: [ 50, medium_ids.size ].max, time_range: "medium_term")
            map = candidates.index_by(&:id)
            @hidden_medium = medium_ids.map { |id| map[id] }.compact
          end

          @hidden_long = []
          if long_ids.any?
            candidates = client.top_tracks(limit: [ 50, long_ids.size ].max, time_range: "long_term")
            map = candidates.index_by(&:id)
            @hidden_long = long_ids.map { |id| map[id] }.compact
          end

          # Log if any hidden ids were not found via top_tracks (they may be outside the top 50).
          missing = (short_ids + medium_ids + long_ids) - ((@hidden_short + @hidden_medium + @hidden_long).map(&:id))
          if missing.any?
            Rails.logger.info "Hidden track ids not found in top_tracks response (may be outside top 50): #{missing.inspect}"
          end
        rescue SpotifyClient::Error => e
          Rails.logger.error "Failed to load hidden track details via top_tracks: #{e.message}"
          @hidden_short = []
          @hidden_medium = []
          @hidden_long = []
        end

        @tracks_short  = @tracks_short.reject  { |t| hidden["short_term"].include?(t.id) }
        @tracks_medium = @tracks_medium.reject { |t| hidden["medium_term"].include?(t.id) }
        @tracks_long   = @tracks_long.reject   { |t| hidden["long_term"].include?(t.id) }
      end
      @error = nil
    rescue SpotifyClient::UnauthorizedError => e
      Rails.logger.error "Spotify unauthorized: #{e.message}"
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
      nil
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      @tracks_short  = []
      @tracks_medium = []
      @tracks_long   = []
      @error = "Couldn't load your top tracks from Spotify."
    end
  end

  private

  def normalize_limit(v)
    n = v.to_i
    [ 10, 25, 50 ].include?(n) ? n : 10
  end

  def require_spotify_auth!
    unless session[:spotify_user].present?
      redirect_to root_path, alert: "Please sign in with Spotify first."
    end
  end

  public

  # POST /top_tracks/hide
  def hide
    time_range = params[:time_range].to_s
    track_id = params[:track_id].to_s

    unless %w[short_term medium_term long_term].include?(time_range)
      redirect_to top_tracks_path, alert: "Invalid time range." and return
    end

    user_id = spotify_user_id
    unless user_id.present?
      redirect_to root_path, alert: "Please sign in with Spotify first." and return
    end

    success = add_hidden_top_track(time_range, track_id, user_id)
    if success
      redirect_to top_tracks_path, notice: "Track hidden from #{time_range.humanize.downcase} list."
    else
      redirect_to top_tracks_path, alert: "Could not hide track — you can hide at most 5 tracks per list."
    end
  end

  # POST /top_tracks/unhide
  def unhide
    time_range = params[:time_range].to_s
    track_id = params[:track_id].to_s

    user_id = spotify_user_id
    unless user_id.present?
      redirect_to root_path, alert: "Please sign in with Spotify first." and return
    end

    remove_hidden_top_track(time_range, track_id, user_id)
    redirect_to top_tracks_path, notice: "Track restored to #{time_range.humanize.downcase} list."
  end
end
