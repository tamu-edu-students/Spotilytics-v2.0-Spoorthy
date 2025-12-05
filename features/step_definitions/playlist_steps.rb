require 'ostruct'

# ---------- Helpers ----------
def mock_spotify!
  @mock_spotify ||= instance_double(SpotifyClient)
  allow(SpotifyClient).to receive(:new).with(session: anything).and_return(@mock_spotify)
  @mock_spotify
end

def top_tracks_path_for_test
  Rails.application.routes.url_helpers.top_tracks_path
end

def create_playlist_path_for_test
  Rails.application.routes.url_helpers.create_playlist_path
end

def playlist_new_path
  Rails.application.routes.url_helpers.new_playlist_path
end

def create_playlist_from_recommendations_path_for_test
  Rails.application.routes.url_helpers.create_playlist_from_recommendations_path
end

def recommendations_path_for_test
  Rails.application.routes.url_helpers.recommendations_path
end

# ---------- Navigation / Session ----------

Given('I am logged in for playlists') do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new(
    provider: 'spotify',
    uid: 'user_123',
    info: { name: 'Test User', email: 'test@example.com', image: nil },
    credentials: {
      token:         'fake',
      refresh_token: 'fake_refresh',
      expires_at:    1.hour.from_now.to_i
    }
  )

  # Stub the /me endpoint for current_user_id
  stub_request(:get, "https://api.spotify.com/v1/me")
    .to_return(status: 200, body: { id: "user_123", display_name: "Test User" }.to_json)

  # Stub top_tracks endpoint for short_term (default fallback)
  stub_request(:get, "https://api.spotify.com/v1/me/top/tracks")
    .with(query: hash_including({}))
    .to_return(status: 200, body: { items: [] }.to_json)

  visit '/auth/spotify'
  visit '/auth/spotify/callback'
end

Given("I am logged in for playlists with user id {string}") do |uid|
  # Reuse the real login path so session keys exist
  step "I am logged in for playlists"

  # Safely mutate the Rack session through rack-test
  if page.driver.respond_to?(:request) && page.driver.request&.respond_to?(:session)
    page.driver.request.session[:spotify_user] ||= {}
    page.driver.request.session[:spotify_user]["id"] = uid
    page.driver.request.session[:spotify_user]["display_name"] ||= "Test User"
  else
    raise "Rack session is not available via page.driver.request.session"
  end
end

Given("I am logged in for playlists without user id") do
  step "I am logged in for playlists"

  if page.driver.respond_to?(:request) && page.driver.request&.respond_to?(:session)
    # Ensure there's no id in the session (forces PlaylistsController to call current_user_id)
    page.driver.request.session[:spotify_user] ||= {}
    page.driver.request.session[:spotify_user].delete("id")
    page.driver.request.session[:spotify_user]["display_name"] ||= "Test User"
  else
    raise "Rack session is not available via page.driver.request.session"
  end
end


# ---------- Spotify stubs ----------
Given('Spotify returns {int} top tracks for {string}') do |n, range|
  client  = mock_spotify!
  tracks  = (1..n).map { |i| OpenStruct.new(id: "t#{i}") }

  allow(client).to receive(:top_tracks).and_return([])

  allow(client).to receive(:top_tracks)
    .with(limit: 10, time_range: range)
    .and_return(tracks)
end

Given('Spotify creates playlist {string} and adds tracks') do |name|
  client = mock_spotify!
  allow(client).to receive(:create_playlist_for)
    .with(hash_including(name: name, public: false))
    .and_return('pl_123')
  allow(client).to receive(:add_tracks_to_playlist)
    .with(hash_including(playlist_id: 'pl_123', uris: kind_of(Array)))
    .and_return(true)
end

Given('Spotify API returns user id {string}') do |uid|
  client = mock_spotify!
  allow(client).to receive(:current_user_id).and_return(uid)
end

Given('Spotify raises Unauthorized on any call') do
  mock = mock_spotify!
  allow(mock).to receive(:top_artists).and_raise(SpotifyClient::UnauthorizedError.new("token expired"))
  allow(mock).to receive(:top_tracks).and_raise(SpotifyClient::UnauthorizedError.new("token expired"))
  allow(mock).to receive(:create_playlist_for).and_raise(SpotifyClient::UnauthorizedError.new("token expired"))
  allow(mock).to receive(:add_tracks_to_playlist).and_raise(SpotifyClient::UnauthorizedError.new("token expired"))
  allow(mock).to receive(:current_user_id).and_raise(SpotifyClient::UnauthorizedError.new("token expired"))
end

Given('Spotify raises Error on any call') do
  mock = mock_spotify!
  allow(mock).to receive(:top_artists).and_raise(SpotifyClient::Error.new("rate limited"))
  allow(mock).to receive(:top_tracks).and_raise(SpotifyClient::Error.new("rate limited"))
  allow(mock).to receive(:create_playlist_for).and_raise(SpotifyClient::Error.new("rate limited"))
  allow(mock).to receive(:add_tracks_to_playlist).and_raise(SpotifyClient::Error.new("rate limited"))
  allow(mock).to receive(:current_user_id).and_raise(SpotifyClient::Error.new("rate limited"))
end

Given('Spotify search returns track {string} by {string} with id {string}') do |title, artist, track_id|
  client = mock_spotify!
  track  = OpenStruct.new(id: track_id, name: title, artists: artist)
  allow(client).to receive(:search_tracks).and_return([ track ])
end

Given('Spotify search returns tracks:') do |table|
  client = mock_spotify!
  mapping = table.hashes.map do |row|
    {
      query: row.fetch("query"),
      track: OpenStruct.new(id: row.fetch("id"), name: row.fetch("name"), artists: row.fetch("artists"))
    }
  end

  allow(client).to receive(:search_tracks) do |query, limit: 10|
    match = mapping.find { |m| query.to_s.downcase.include?(m[:query].downcase) }
    match ? [ match[:track] ] : []
  end
end

Given('Spotify search returns no results') do
  client = mock_spotify!
  allow(client).to receive(:search_tracks).and_return([])
end

# ---------- Actions ----------
When("I POST create_playlist for {string}") do |range|
  page.driver.submit :post, create_playlist_path, { time_range: range }
end

When('I POST create_playlist for {string} without login') do |range|
  visit Rails.application.routes.url_helpers.root_path
  page.driver.request.session[:spotify_user] = nil
  page.driver.submit :post, create_playlist_path_for_test, { time_range: range }
end

When("I POST create_playlist_from_recommendations with name {string} and uris:") do |name, table|
  client = mock_spotify!
  allow(client).to receive(:top_artists).and_return([])
  allow(client).to receive(:top_tracks).and_return([])
  allow(client).to receive(:search_tracks).and_return([])

  uris = table.raw.flatten.map(&:to_s).reject(&:blank?)
  page.driver.submit :post, create_playlist_from_recommendations_path_for_test, {
    playlist_name: name,
    uris:          uris
  }
end

When("I POST create_playlist_from_recommendations without uris") do
  client = mock_spotify!
  allow(client).to receive(:top_artists).and_return([])
  allow(client).to receive(:top_tracks).and_return([])
  allow(client).to receive(:search_tracks).and_return([])

  page.driver.submit :post, create_playlist_from_recommendations_path_for_test, { uris: [] }
end

When("I visit the create playlist page") do
  visit playlist_new_path
end

When('I fill in {string} with {string}') do |label, value|
  fill_in label, with: value
end

When('I upload the CSV file {string}') do |relative_path|
  path = Rails.root.join(relative_path)
  attach_file("tracks_csv", path, make_visible: true)
end

Then('I should not see {string}') do |text|
  expect(page).not_to have_content(text)
end

# ---------- Expectations ----------
Then("I should be on the Top Tracks page") do
  expect(page).to have_current_path(
    Rails.application.routes.url_helpers.top_tracks_path,
    ignore_query: true
  )
end

Then("I should be on the recommendations page") do
  expect(page).to have_current_path(
    recommendations_path_for_test,
    ignore_query: true
  )
end

Given("I am logged in for playlists with non-mergeable session") do
  # First establish a normal logged-in session so other keys exist
  step "I am logged in for playlists"

  # Replace session[:spotify_user] with an object that:
  # - DOES NOT respond to :merge!   (forces the else branch)
  # - DOES respond to :[]= and :[]  (so controller can write/read "id")
  # - Supports :dup (controller calls .dup)
  klass = Class.new do
    def initialize; @h = {}; end
    def []=(k, v);  @h[k] = v; end
    def [](k);      @h[k]; end
    def dup;        self; end
    # No :merge! method on purpose
  end

  raise "Rack session unavailable" unless page.driver.respond_to?(:request) && page.driver.request&.respond_to?(:session)

  page.driver.request.session[:spotify_user] = klass.new
end
