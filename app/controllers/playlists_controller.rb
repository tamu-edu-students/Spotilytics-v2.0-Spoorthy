require "csv"

class PlaylistsController < ApplicationController
  before_action :require_spotify_auth!

  VALID_RANGES = {
    "short_term"  => { label: "Last 4 Weeks" },
    "medium_term" => { label: "Last 6 Months" },
    "long_term"   => { label: "Last 1 Year" }
  }.freeze

  def create
    time_range = params[:time_range].to_s

    unless VALID_RANGES.key?(time_range)
      redirect_to top_tracks_path, alert: "Invalid time range."
      return
    end

    client = SpotifyClient.new(session: session)

    begin
      # ---- Resolve user_id safely (handles old sessions) ----
      user_info   = (session[:spotify_user] || {}).dup
      indifferent = user_info.respond_to?(:with_indifferent_access) ? user_info.with_indifferent_access : user_info
      user_id     = indifferent[:id].presence || indifferent["id"].presence

      # Fallback: ask Spotify /me if not present in session (works for old logins)
      unless user_id.present?
        user_id = client.current_user_id
        # cache it back into the session for next time
        session[:spotify_user] ||= {}
        if session[:spotify_user].respond_to?(:merge!)
          session[:spotify_user].merge!({ "id" => user_id })
        else
          session[:spotify_user]["id"] = user_id
        end
      end

      # ---- Fetch tracks for the requested time range ----
      tracks = client.top_tracks(limit: 10, time_range: time_range)
      if tracks.empty?
        redirect_to top_tracks_path, alert: "No tracks available for #{VALID_RANGES[time_range][:label]}."
        return
      end

      # ---- Create playlist + add tracks ----
      playlist_name = "Your Top Tracks - #{VALID_RANGES[time_range][:label]}"
      playlist_desc = "Auto-created from Spotilytics • #{VALID_RANGES[time_range][:label]}"

      playlist_id = client.create_playlist_for(
        user_id:     user_id,
        name:        playlist_name,
        description: playlist_desc,
        public:      false
      )

      uris = tracks.map { |t| "spotify:track:#{t.id}" }
      client.add_tracks_to_playlist(playlist_id: playlist_id, uris: uris)

      redirect_to top_tracks_path, notice: "Playlist created on Spotify: #{playlist_name}"
    rescue SpotifyClient::UnauthorizedError => e
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
    rescue SpotifyClient::Error => e
      redirect_to top_tracks_path, alert: "Couldn't create playlist on Spotify."
    end
  end

  # POST /create_playlist_from_recommendations
  def create_from_recommendations
    spotify_client = SpotifyClient.new(session: session)

    uris = Array(params[:uris]).map(&:to_s).reject(&:blank?)
    if uris.empty?
      redirect_to recommendations_path, alert: "No tracks to add to playlist." and return
    end

    begin
      user_info   = (session[:spotify_user] || {}).dup
      indifferent = user_info.respond_to?(:with_indifferent_access) ? user_info.with_indifferent_access : user_info
      user_id     = indifferent[:id].presence || indifferent["id"].presence

      unless user_id.present?
        user_id = spotify_client.current_user_id
        session[:spotify_user] ||= {}
        if session[:spotify_user].respond_to?(:merge!)
          session[:spotify_user].merge!({ "id" => user_id })
        else
          session[:spotify_user]["id"] = user_id
        end
      end

      playlist_name = params[:playlist_name].presence || "Spotilytics Recommendations - #{Time.current.strftime('%b %d, %Y')}"
      playlist_desc = params[:playlist_desc].presence || "Auto-created from Spotilytics • Your Recommendations"

      playlist_id = spotify_client.create_playlist_for(
        user_id:     user_id,
        name:        playlist_name,
        description: playlist_desc,
        public:      false
      )

      spotify_client.add_tracks_to_playlist(playlist_id: playlist_id, uris: uris)

      redirect_to recommendations_path, notice: "Playlist created on Spotify: #{playlist_name}"
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
    rescue SpotifyClient::Error => e
      redirect_to recommendations_path, alert: "Couldn't create playlist on Spotify: #{e.message}"
    end
  end

  def rename
    playlist_id = params[:id]
    new_name    = params[:name].to_s.strip
    owner_id    = params[:owner_id].to_s

    if new_name.blank?
      redirect_to library_path, alert: "Playlist name cannot be blank." and return
    end

    user_id = ensure_spotify_user_id
    unless owner_id.present? && owner_id == user_id
      redirect_to library_path, alert: "You can only rename playlists you own." and return
    end

    begin
      spotify_client.update_playlist_name(playlist_id: playlist_id, name: new_name)
      redirect_to library_path, notice: "Playlist renamed to #{new_name}."
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
    rescue SpotifyClient::Error => e
      redirect_to library_path, alert: "Couldn't rename playlist: #{e.message}"
    end
  end

  def new
    load_builder_state
  end

  def add_song
    load_builder_state

    if params[:remove_track_id].present?
      removed = remove_track_from_builder(params[:remove_track_id].to_s)
      flash.now[:notice] = removed ? "Removed song from list." : "Song not found in list."
      return render :new
    end

    bulk_button   = params[:bulk_add].present?
    single_button = params[:single_add].present?
    file_button   = params[:file_add].present?
    bulk_input    = params[:bulk_songs].to_s
    query         = params[:song_query].to_s.strip
    upload        = params[:tracks_csv]

    if file_button
      if upload.nil?
        flash.now[:alert] = "Choose a CSV file with columns like title, artist."
        return render :new, status: :unprocessable_entity
      end

      added = 0
      duplicates = []
      not_found = []

      begin
        csv = CSV.new(upload.read, headers: true)
        csv.each do |row|
          title  = row["title"] || row["track"] || row[0]
          artist = row["artist"] || row["artists"] || row[1]
          search = track_search_query(title: title, artist: artist)
          next if search.blank?

          track = spotify_client.search_tracks(search, limit: 1).first
          if track.present?
            if add_track_to_builder(track)
              added += 1
            else
              duplicates << track.name
            end
          else
            not_found << search
          end
        end
      rescue CSV::MalformedCSVError
        flash.now[:alert] = "Could not read that CSV file. Please check the formatting."
        return render :new, status: :unprocessable_entity
      end

      notices = []
      notices << "Added #{added} #{'song'.pluralize(added)}." if added.positive?
      notices << "Skipped duplicates: #{duplicates.join(', ')}." if duplicates.any?
      flash.now[:notice] = notices.join(" ") if notices.any?
      flash.now[:alert] = "No matches for: #{not_found.join(', ')}." if not_found.any?
      return render :new
    end

    if bulk_button
      titles = bulk_input.split(",").map { |t| t.strip }.reject(&:blank?)
      if titles.empty?
        flash.now[:alert] = "Enter at least one song title."
        return render :new, status: :unprocessable_entity
      end

      added = 0
      not_found = []
      duplicates = []

      titles.each do |title|
        track = spotify_client.search_tracks(track_search_query(title: title), limit: 1).first
        if track.present?
          if add_track_to_builder(track)
            added += 1
          else
            duplicates << track.name
          end
        else
          not_found << title
        end
      end

      notices = []
      notices << "Added #{added} #{'song'.pluralize(added)}." if added.positive?
      notices << "Skipped duplicates: #{duplicates.join(', ')}." if duplicates.any?
      flash.now[:notice] = notices.join(" ") if notices.any?
      flash.now[:alert] = "No matches for: #{not_found.join(', ')}." if not_found.any?
      return render :new
    end

    # default to single add if the single button was used (or no button but query present)
    if single_button || query.present?
      if query.blank?
        flash.now[:alert] = "Enter a song name to search and add."
        return render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Choose a song to add."
      return render :new, status: :unprocessable_entity
    end

    begin
      track = spotify_client.search_tracks(query, limit: 1).first
      if track.present?
        added = add_track_to_builder(track)
        flash.now[:notice] = added ? "Added #{track.name} by #{track.artists}." : "#{track.name} is already in your list."
      else
        flash.now[:alert] = "No songs found for \"#{query}\"."
      end
      render :new
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
    rescue SpotifyClient::Error => e
      flash.now[:alert] = "Couldn't search Spotify: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end

  def create_custom
    load_builder_state

    if @builder_tracks.empty?
      flash.now[:alert] = "Add at least one song before creating your playlist."
      render :new, status: :unprocessable_entity and return
    end

    begin
      user_id = ensure_spotify_user_id
      playlist_id = spotify_client.create_playlist_for(
        user_id:     user_id,
        name:        @playlist_name,
        description: @playlist_description.presence || "Custom playlist created with Spotilytics",
        public:      false
      )

      uris = @builder_tracks.map { |t| "spotify:track:#{t[:id] || t['id']}" }
      spotify_client.add_tracks_to_playlist(playlist_id: playlist_id, uris: uris)

      redirect_to new_playlist_path, notice: "Playlist created on Spotify: #{@playlist_name}"
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
    rescue SpotifyClient::Error => e
      flash.now[:alert] = "Couldn't create playlist on Spotify: #{e.message}"
      load_builder_state
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_spotify_auth!
    unless session[:spotify_user].present?
      redirect_to root_path, alert: "Please sign in with Spotify first."
    end
  end

  def spotify_client
    @spotify_client ||= SpotifyClient.new(session: session)
  end

  def ensure_spotify_user_id
    user_info   = (session[:spotify_user] || {}).dup
    indifferent = user_info.respond_to?(:with_indifferent_access) ? user_info.with_indifferent_access : user_info
    user_id     = indifferent[:id].presence || indifferent["id"].presence

    return user_id if user_id.present?

    spotify_client.current_user_id
  end

  def load_builder_state
    @builder_tracks = parse_tracks_params
    @playlist_name = params[:playlist_name].presence || default_playlist_name
    @playlist_description = params[:playlist_description].to_s
  end

  def add_track_to_builder(track)
    existing = @builder_tracks.any? { |t| (t[:id] || t["id"]) == track.id }
    return false if existing

    @builder_tracks << {
      id: track.id,
      name: track.name,
      artists: track.artists
    }
    true
  end

  def remove_track_from_builder(track_id)
    before = @builder_tracks.size
    @builder_tracks.reject! { |t| (t[:id] || t["id"]).to_s == track_id.to_s }
    before != @builder_tracks.size
  end

  def default_playlist_name
    "My Spotilytics Playlist - #{Time.current.strftime('%b %d, %Y')}"
  end

  def track_search_query(title:, artist: nil)
    t = title.to_s.strip
    a = artist.to_s.strip
    return "" if t.blank? && a.blank?

    parts = []
    parts << %(track:"#{t}") unless t.blank?
    parts << %(artist:"#{a}") unless a.blank?

    parts.join(" ")
  end

  def parse_tracks_params
    raw = params[:tracks]
    return [] if raw.blank?

    entries =
      if raw.is_a?(ActionController::Parameters)
        raw.to_unsafe_h.values
      elsif raw.is_a?(Hash)
        raw.values
      else
        Array(raw)
      end

    entries.map do |track|
      {
        id: track[:id] || track["id"],
        name: track[:name] || track["name"],
        artists: track[:artists] || track["artists"]
      }
    end.select { |t| t[:id].present? && t[:name].present? && t[:artists].present? }
  end
end
