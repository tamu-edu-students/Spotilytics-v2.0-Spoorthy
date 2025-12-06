require "rails_helper"
require "nokogiri"

RSpec.describe "Library collaboration", type: :request do
  let(:playlists) do
    [
      OpenStruct.new(
        id: "pl1",
        name: "My Playlist",
        owner: "Me",
        owner_id: "spotify-uid-123",
        description: "Old description",
        collaborative: false,
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

  it "shows collaborative controls for owned playlists" do
    sign_in

    get library_path

    html = Nokogiri::HTML(response.body)
    form = html.at_css("form[action='#{playlist_collaborative_path('pl1')}']")
    expect(form).not_to be_nil
    button = form.at_css("input[type='submit']")
    expect(button["value"]).to eq("Enable collaboration")
  end

  it "enables collaboration when owner submits" do
    updated_playlists = playlists.map { |p| p.dup.tap { |pp| pp.collaborative = true } }
    allow_any_instance_of(SpotifyClient).to receive(:user_playlists_all).with(skip_cache: true).and_return(updated_playlists)

    sign_in
    expect_any_instance_of(SpotifyClient).to receive(:update_playlist_collaborative)
      .with(playlist_id: "pl1", collaborative: true).and_return(true)
    expect_any_instance_of(SpotifyClient).to receive(:clear_user_cache)

    patch playlist_collaborative_path("pl1"), params: { collaborative: "true", owner_id: "spotify-uid-123" }

    expect(response).to redirect_to(library_path(refresh_playlists: 1))
    follow_redirect!
    expect(response.body).to include("Collaboration enabled.")

    html = Nokogiri::HTML(response.body)
    button = html.at_css("form[action='#{playlist_collaborative_path('pl1')}'] input[type='submit']")
    expect(button["value"]).to eq("Disable collaboration")
  end

  it "rejects collaboration change when not owner" do
    sign_in

    patch playlist_collaborative_path("pl1"), params: { collaborative: "false", owner_id: "someone-else" }

    expect(response).to redirect_to(library_path)
    follow_redirect!
    expect(response.body).to include("You can only change collaboration for playlists you own.")
  end
end
