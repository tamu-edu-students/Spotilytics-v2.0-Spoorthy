require "rails_helper"
require "nokogiri"

RSpec.describe "Library description", type: :request do
  let(:playlists) do
    [
      OpenStruct.new(
        id: "pl1",
        name: "My Playlist",
        owner: "Me",
        owner_id: "spotify-uid-123",
        description: "Old description",
        public: false,
        tracks_total: 3,
        image_url: nil,
        spotify_url: nil
      )
    ]
  end

  before do
    allow_any_instance_of(SpotifyClient).to receive(:user_playlists_all).and_return(playlists)
  end

  def sign_in
    get "/auth/spotify/callback"
  end

  it "shows the description form for owned playlists" do
    sign_in

    get library_path

    html = Nokogiri::HTML(response.body)
    form = html.at_css("form[action='#{playlist_description_path('pl1')}']")
    expect(form).not_to be_nil
    expect(form.text).to include("Update description")
  end

  it "updates the description when user is owner" do
    sign_in
    expect_any_instance_of(SpotifyClient).to receive(:update_playlist_description).with(playlist_id: "pl1", description: "New desc").and_return(true)
    allow_any_instance_of(SpotifyClient).to receive(:clear_user_cache)

    patch playlist_description_path("pl1"), params: { description: "New desc", owner_id: "spotify-uid-123" }

    expect(response).to redirect_to(library_path(refresh_playlists: 1))
    follow_redirect!
    expect(response.body).to include("Playlist description updated.")
  end

  it "rejects description update when not owner" do
    sign_in

    patch playlist_description_path("pl1"), params: { description: "New desc", owner_id: "someone-else" }

    expect(response).to redirect_to(library_path)
    follow_redirect!
    expect(response.body).to include("You can only update playlists you own.")
  end

  it "rejects blank description" do
    sign_in

    patch playlist_description_path("pl1"), params: { description: "  ", owner_id: "spotify-uid-123" }

    expect(response).to redirect_to(library_path)
    follow_redirect!
    expect(response.body).to include("Playlist description cannot be blank.")
  end
end
