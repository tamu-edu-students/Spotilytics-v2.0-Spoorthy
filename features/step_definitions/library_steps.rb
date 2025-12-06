require "securerandom"

Given("Spotify playlists API returns the following playlists:") do |table|
  stub_spotify_me_profile

  items = table.hashes.map do |row|
    {
      "id" => row["id"].presence || SecureRandom.uuid,
      "name" => row.fetch("name"),
      "images" => [ { "url" => "https://img/#{row['name'].parameterize}.jpg" } ],
      "owner" => { "display_name" => row.fetch("owner"), "id" => row.fetch("owner_id", "owner-1") },
      "tracks" => { "total" => row.fetch("tracks_total").to_i },
      "description" => row["description"],
      "collaborative" => ActiveModel::Type::Boolean.new.cast(row["collaborative"]),
      "public" => row["public"],
      "external_urls" => { "spotify" => "https://open.spotify.com/playlist/#{row.fetch('name').parameterize}" }
    }
  end

  stub_request(:get, %r{\Ahttps://api\.spotify\.com/v1/me/playlists})
    .to_return(status: 200, body: JSON.generate({ items: items }), headers: { "Content-Type" => "application/json" })
end

Given("Spotify playlists API returns an error") do
  stub_spotify_me_profile

  stub_request(:get, %r{\Ahttps://api\.spotify\.com/v1/me/playlists})
    .to_return(status: 401, body: JSON.generate(error: { message: "Invalid token" }), headers: { "Content-Type" => "application/json" })
end

Given('Spotify playlist rename API succeeds for {string}') do |playlist_id|
  stub_spotify_me_profile

  stub_request(:put, "https://api.spotify.com/v1/playlists/#{playlist_id}")
    .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
end

Given('Spotify playlist visibility API succeeds for {string}') do |playlist_id|
  stub_spotify_me_profile

  stub_request(:put, "https://api.spotify.com/v1/playlists/#{playlist_id}")
    .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
end

Given('Spotify playlist description API succeeds for {string}') do |playlist_id|
  stub_spotify_me_profile

  stub_request(:put, "https://api.spotify.com/v1/playlists/#{playlist_id}")
    .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
end

Given('Spotify playlist collaboration API succeeds for {string}') do |playlist_id|
  stub_spotify_me_profile

  stub_request(:put, "https://api.spotify.com/v1/playlists/#{playlist_id}")
    .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
end

def stub_spotify_me_profile
  stub_request(:get, "https://api.spotify.com/v1/me")
    .to_return(
      status: 200,
      body: JSON.generate({ id: "spotify-uid-123" }),
      headers: { "Content-Type" => "application/json" }
    )
end
