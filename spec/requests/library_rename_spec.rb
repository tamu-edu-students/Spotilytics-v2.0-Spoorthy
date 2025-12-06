require "rails_helper"
require "nokogiri"

RSpec.describe "Library rename", type: :request do
  let(:playlists) do
    [
      OpenStruct.new(
        id: "pl1",
        name: "Old Name",
        owner: "Owner",
        owner_id: "spotify-uid-123",
        public: false,
        tracks_total: 1,
        image_url: nil,
        spotify_url: "http://example.com/pl1"
      )
    ]
  end

  before do
    allow_any_instance_of(SpotifyClient).to receive(:user_playlists_all).and_return(playlists)
  end

  def sign_in
    get "/auth/spotify/callback"
  end

  it "shows a rename form for playlists owned by the current user" do
    sign_in

    get library_path

    html = Nokogiri::HTML(response.body)
    form = html.at_css("form[action='#{rename_playlist_path('pl1')}']")
    expect(form).not_to be_nil
    expect(form.css("input[name='name']").attr("value").value).to eq("Old Name")
  end

  it "renames a playlist when user is the owner" do
    sign_in
    expect_any_instance_of(SpotifyClient).to receive(:update_playlist_name).with(playlist_id: "pl1", name: "New Name").and_return(true)
    expect_any_instance_of(SpotifyClient).to receive(:clear_user_cache)

    patch rename_playlist_path("pl1"), params: { name: "New Name", owner_id: "spotify-uid-123" }

    expect(response).to redirect_to(library_path(refresh_playlists: 1))
    follow_redirect!
    expect(response.body).to include("Playlist renamed to New Name.")
  end

  it "rejects rename when user is not the owner" do
    sign_in

    patch rename_playlist_path("pl1"), params: { name: "New Name", owner_id: "someone-else" }

    expect(response).to redirect_to(library_path)
    follow_redirect!
    expect(response.body).to include("You can only rename playlists you own.")
  end

  it "rejects rename with blank name" do
    sign_in

    patch rename_playlist_path("pl1"), params: { name: "  ", owner_id: "spotify-uid-123" }

    expect(response).to redirect_to(library_path)
    follow_redirect!
    expect(response.body).to include("Playlist name cannot be blank.")
  end
end
