require "rails_helper"
require "nokogiri"

RSpec.describe "Library", type: :request do
  def sign_in_with_spotify
    get "/auth/spotify/callback"
  end

  it "renders playlists when the API succeeds" do
    playlists = [
      OpenStruct.new(id: "pl1", name: "Morning Mix", owner: "Me", tracks_total: 20, image_url: "https://img/1", spotify_url: "https://open.spotify.com/playlist/pl1"),
      OpenStruct.new(id: "pl2", name: "Workout", owner: "Me", tracks_total: 15, image_url: nil, spotify_url: nil)
    ]

    allow_any_instance_of(SpotifyClient).to receive(:user_playlists_all).and_return(playlists)

    sign_in_with_spotify
    get library_path

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    expect(html.css("h1").text).to include("Your Library")
    expect(html.text).to include("Morning Mix", "Workout")
    expect(html.css(".nav-link.active").map(&:text)).to include("Library")
  end

  it "shows a fallback when there are no playlists" do
    allow_any_instance_of(SpotifyClient).to receive(:user_playlists_all).and_return([])

    sign_in_with_spotify
    get library_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No playlists found.")
  end

  it "redirects to home when Spotify returns unauthorized" do
    allow_any_instance_of(SpotifyClient).to receive(:user_playlists_all).and_raise(SpotifyClient::UnauthorizedError)

    sign_in_with_spotify
    get library_path

    expect(response).to redirect_to(home_path)
    follow_redirect!
    expect(response.body).to include("You must log in with spotify to view your library.")
  end

  it "shows an alert when a Spotify error occurs" do
    allow_any_instance_of(SpotifyClient).to receive(:user_playlists_all).and_raise(SpotifyClient::Error.new("boom"))

    sign_in_with_spotify
    get library_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("We were unable to load your playlists from Spotify. Please try again later.")
    expect(assigns(:playlists)).to eq([])
  end
end
