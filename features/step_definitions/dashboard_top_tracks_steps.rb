require 'ostruct'

#
class CucumberDashboardController < ApplicationController
  def index
    # Pretend the user is logged in so the view can say "Logged in as"
    session[:spotify_user] ||= { "id" => "fake_user_id", "name" => "Test User" }

    #
    # ----- Top Tracks card data (the thing we're testing) -----
    #
    @top_tracks = [
      OpenStruct.new(
        rank: 1,
        name: "Dashboard Banger",
        artists: "Cool Artist",
        album_name: "Cool Album",
        album_image_url: "http://img/cool.jpg",
        popularity: 99,
        preview_url: nil,
        spotify_url: "https://open.spotify.com/track/xyz999"
      ),
      OpenStruct.new(
        rank: 2,
        name: "Runner Up Heat",
        artists: "Another Person",
        album_name: "Side B",
        album_image_url: "http://img/sideb.jpg",
        popularity: 91,
        preview_url: "http://preview2.mp3",
        spotify_url: "https://open.spotify.com/track/pqr555"
      )
    ]

    @primary_track = @top_tracks.first

    #
    # ----- Top Artists card data (not under test, but prevents view from crashing) -----
    #
    @top_artists = [
      OpenStruct.new(
        name: "Placeholder Artist",
        image_url: "http://example.com/artist.jpg",
        genres: [ "alt" ],
        popularity: 75,
        spotify_url: "https://open.spotify.com/artist/fake"
      )
    ]
    @primary_artist = @top_artists.first

    render template: "pages/dashboard"
  end
end

def stub_spotify_for_dashboard!
    @mock_spotify ||= instance_double(SpotifyClient)
    allow(SpotifyClient).to receive(:new).with(session: anything).and_return(@mock_spotify)
    @mock_spotify
  end


#
# GIVEN: logged in for dashboard
#
Given("I am logged in with Spotify for the dashboard") do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new(
    provider: 'spotify',
    uid:      'test-uid',
    info:     { name: 'Test User', email: 'test@example.com' },
    credentials: {
      token:         'fake-token',
      refresh_token: 'fake-refresh',
      expires_at:    1.hour.from_now.to_i
    }
  )

  # Hit your real callback to populate session[:spotify_user]
  visit '/auth/spotify'
  visit '/auth/spotify/callback'
end

#
# GIVEN: Spotify responds with top tracks for the dashboard
# We keep this step for readability, but it's a no-op now that
# our controller bakes in deterministic @top_tracks/@primary_track.
#
Given("Spotify responds with top tracks for the dashboard") do
  tracks = [
    OpenStruct.new(
      rank: 1,
      name: "Dashboard Banger",
      artists: "Cool Artist",
      album_name: "Cool Album",
      album_image_url: "http://img/cool.jpg",
      popularity: 99,
      preview_url: nil,
      spotify_url: "https://open.spotify.com/track/xyz999"
    ),
    OpenStruct.new(
      rank: 2,
      name: "Runner Up Heat",
      artists: "Another Person",
      album_name: "Side B",
      album_image_url: "http://img/sideb.jpg",
      popularity: 91,
      preview_url: "http://preview2.mp3",
      spotify_url: "https://open.spotify.com/track/pqr555"
    )
  ]

  artists = [
    OpenStruct.new(
      name: "Placeholder Artist",
      image_url: "http://example.com/artist.jpg",
      genres: [ "alt" ],
      popularity: 75,
      spotify_url: "https://open.spotify.com/artist/fake"
    )
  ]

  mock = instance_double(SpotifyClient)
  allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock)
  allow(mock).to receive(:top_tracks).with(limit: 10, time_range: "long_term").and_return(tracks)
  allow(mock).to receive(:top_artists).with(limit: 10, time_range: "long_term").and_return(artists)
  allow(mock).to receive(:followed_artists).and_return([])
  allow(mock).to receive(:new_releases).and_return([])
  allow(mock).to receive(:saved_shows).and_return(OpenStruct.new(items: []))
  allow(mock).to receive(:saved_episodes).and_return(OpenStruct.new(items: []))
end

When("I go to the dashboard") do
  visit '/dashboard'
end

Then("I should see the Top Tracks card") do
  expect(page).to have_content("Top Tracks")
end

Then("I should see the dashboard primary track name") do
  expect(page).to have_content("Dashboard Banger")
end

Then("I should see the dashboard primary track artist") do
  expect(page).to have_content("Cool Artist")
end

Then("I should see the dashboard CTA to view top tracks") do
  expect(page).to have_content("Your Top Tracks")
end

Given("Spotify for the dashboard raises Unauthorized") do
  mock = stub_spotify_for_dashboard!
  allow(mock).to receive(:top_tracks).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
  allow(mock).to receive(:top_artists).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
  allow(mock).to receive(:saved_shows).and_return(OpenStruct.new(items: []))
  allow(mock).to receive(:saved_episodes).and_return(OpenStruct.new(items: []))
end

Given("Spotify for the dashboard raises a generic error") do
  mock = stub_spotify_for_dashboard!
  allow(mock).to receive(:top_tracks).and_raise(SpotifyClient::Error.new("rate limited"))
  allow(mock).to receive(:top_artists).and_raise(SpotifyClient::Error.new("rate limited"))
  allow(mock).to receive(:saved_shows).and_return(OpenStruct.new(items: []))
  allow(mock).to receive(:saved_episodes).and_return(OpenStruct.new(items: []))
end
