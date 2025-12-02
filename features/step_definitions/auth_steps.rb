Given("OmniAuth is in test mode") do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new(
    provider: "spotify",
    uid: "spotify-uid-123",
    info: {
      name:  "Test User",
      email: "test-user@example.com",
      image: "https://pics.example/avatar.png"
    },
    credentials: {
      token:         "access-token-1",
      refresh_token: "refresh-token-1",
      expires_at:    2.hours.from_now.to_i
    }
  )
end

Given("I am signed in with Spotify") do
  step %(OmniAuth is in test mode)
  visit "/auth/spotify"
  visit "/auth/spotify/callback"
end

Given("I am on the home page") do
  visit root_path
end

Given("OmniAuth will return {string}") do |kind|
  case kind
  when "developer access not configured"
    OmniAuth.config.mock_auth[:spotify] = :developer_access_not_configured
  else
    raise "Unknown mock kind: #{kind}"
  end
end

# NEW STEP: This handles all the backend API mocking separately
Given("the dashboard API is available") do
  common_headers = {
    'Accept'=>'*/*',
    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    'Authorization'=>'Bearer access-token-1',
    'Content-Type'=>'application/json',
    'Host'=>'api.spotify.com',
    'User-Agent'=>'Ruby'
  }

  # Mock 11: Top Artists (or similar)
  stub_request(:get, "https://api.spotify.com/v1/me").
    with(headers: common_headers).
    to_return(status: 200, body: "", headers: {})

  # Mock 12: Top Tracks (or similar)
  stub_request(:get, "https://api.spotify.com/v1/me/top/artists?limit=10&time_range=long_term").
    with(headers: common_headers).
    to_return(status: 200, body: JSON.generate({ items: [] }), headers: { 'Content-Type' => 'application/json' })

  # Mock 13: Followed Artists
  stub_request(:get, "https://api.spotify.com/v1/me/top/tracks?limit=10&time_range=long_term").
    with(headers: common_headers).
    to_return(status: 200, body: JSON.generate({ items: [] }), headers: { 'Content-Type' => 'application/json' })

  # Mock 14: New Releases - Artists
  stub_request(:get, "https://api.spotify.com/v1/me/following?limit=20&type=artist").
    with(headers: common_headers).
    to_return(status: 200, body: JSON.generate({ artists: { items: [] } }), headers: { 'Content-Type' => 'application/json' })

  # Mock 15: New Releases - Albums
  stub_request(:get, "https://api.spotify.com/v1/browse/new-releases?limit=2").
    with(headers: common_headers).
    to_return(status: 200, body: JSON.generate({ albums: { items: [] } }), headers: { 'Content-Type' => 'application/json' })

  # Mock 16: Saved Shows
  stub_request(:get, "https://api.spotify.com/v1/me/shows?limit=8&offset=0").
    with(headers: common_headers).
    to_return(status: 200, body: JSON.generate({ items: [] }), headers: { 'Content-Type' => 'application/json' })

  # Mock 17: Saved Episodes
  stub_request(:get, "https://api.spotify.com/v1/me/episodes?limit=8&offset=0").
    with(headers: common_headers).
    to_return(status: 200, body: JSON.generate({ items: [] }), headers: { 'Content-Type' => 'application/json' })
end

# REFACTORED: Now this step is clean, generic, and reusable
When("I click {string}") do |text|
  click_link_or_button text
end

When('I visit {string}') do |path|
  visit path
end

Then("I should be on the home page") do
  uri  = Addressable::URI.parse(page.current_url)
  path = uri.path
  home = Rails.application.routes.url_helpers.home_path
  root = Rails.application.routes.url_helpers.root_path
  expect([ home, root ]).to include(path)
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end
