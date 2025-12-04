require "rails_helper"

RSpec.describe SpotifyClient, "#user_playlists" do
  let(:session) do
    {
      spotify_token: "access-token-1",
      spotify_refresh_token: "refresh-token-1",
      spotify_expires_at: 1.hour.from_now.to_i,
      spotify_user: { "id" => "user-123" }
    }
  end

  let(:client) { described_class.new(session: session) }
  let(:auth_headers) do
    {
      "Authorization" => "Bearer access-token-1"
    }
  end

  before do
    stub_request(:get, "https://api.spotify.com/v1/me")
      .with(headers: auth_headers)
      .to_return(
        status: 200,
        body: JSON.generate({ id: "spotify-user-1" }),
        headers: { "Content-Type" => "application/json" }
      )
  end

  def playlist_payload(id_suffix, count)
    (1..count).map do |i|
      {
        "id" => "pl_#{id_suffix}_#{i}",
        "name" => "Playlist #{id_suffix} #{i}",
        "images" => [ { "url" => "https://img/#{id_suffix}/#{i}.jpg" } ],
        "owner" => { "display_name" => "Owner #{id_suffix}" },
        "tracks" => { "total" => i * 2 },
        "external_urls" => { "spotify" => "https://open.spotify.com/playlist/pl_#{id_suffix}_#{i}" }
      }
    end
  end

  it "fetches playlists with the given limit and offset" do
    stub_request(:get, "https://api.spotify.com/v1/me/playlists")
      .with(query: hash_including({ "limit" => "2", "offset" => "3" }), headers: auth_headers)
      .to_return(
        status: 200,
        body: JSON.generate({ items: playlist_payload("first", 2) }),
        headers: { "Content-Type" => "application/json" }
      )

    playlists = client.user_playlists(limit: 2, offset: 3)

    expect(playlists.size).to eq(2)
    expect(playlists.first.name).to eq("Playlist first 1")
    expect(playlists.first.owner).to eq("Owner first")
    expect(playlists.first.tracks_total).to eq(2)
    expect(a_request(:get, "https://api.spotify.com/v1/me/playlists")
      .with(query: hash_including({ "limit" => "2", "offset" => "3" }))).to have_been_made
  end

  it "accumulates all pages with user_playlists_all" do
    stub_request(:get, "https://api.spotify.com/v1/me/playlists")
      .with(query: hash_including({ "limit" => "50", "offset" => "0" }), headers: auth_headers)
      .to_return(
        status: 200,
        body: JSON.generate({ items: playlist_payload("page1", 50) }),
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://api.spotify.com/v1/me/playlists")
      .with(query: hash_including({ "limit" => "50", "offset" => "50" }), headers: auth_headers)
      .to_return(
        status: 200,
        body: JSON.generate({ items: playlist_payload("page2", 10) }),
        headers: { "Content-Type" => "application/json" }
      )

    playlists = client.user_playlists_all

    expect(playlists.size).to eq(60)
    expect(playlists.last.name).to eq("Playlist page2 10")
    expect(a_request(:get, "https://api.spotify.com/v1/me/playlists")
      .with(query: hash_including({ "offset" => "50" }))).to have_been_made
  end
end
