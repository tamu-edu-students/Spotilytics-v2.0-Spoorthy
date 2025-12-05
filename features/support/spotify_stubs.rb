  $stubbed_top_tracks_call = nil

  def stub_spotify_top_tracks(limit:, time_range:)
    fake_tracks = Array.new(limit) do |i|
      rank = i + 1
      OpenStruct.new(
        rank: rank,
        name: "Track #{rank}",
        artists: "Artist #{rank}",
        album_name: "Album #{rank}",
        album_image_url: "http://img/#{rank}.jpg",
        popularity: 80 - i,
        preview_url: nil,
        spotify_url: "https://open.spotify.com/track/#{rank.to_s.rjust(2, '0')}"
      )
    end

    allow_any_instance_of(SpotifyClient).to receive(:top_tracks) do |_, args|
      # capture the last call so we can assert later
      $stubbed_top_tracks_call = args

      # emulate controller behavior: return data based on supplied args
      # dashboard (long_term) and page (short_term) both just get fake_tracks for now
      fake_tracks
    end

    fake_tracks
  end

  def stubbed_top_tracks_call
    $stubbed_top_tracks_call
  end
