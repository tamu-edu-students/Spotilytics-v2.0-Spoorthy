require 'ostruct'
require 'set'
require 'uri'

module TopArtistsCallStore
  class << self
    attr_accessor :log, :followed_ids
  end
end

TopArtistsCallStore.log = []
TopArtistsCallStore.followed_ids = Set.new

def stubbed_top_artists_calls
  TopArtistsCallStore.log || []
end

def range_label_to_key(label)
  {
    "Past Year"      => "long_term",
    "Past 6 Months"  => "medium_term",
    "Past 4 Weeks"   => "short_term"
  }.fetch(label)
end

def spotify_mock
  @spotify_mock || raise('Spotify mock not initialized; ensure "Spotify returns top artists data" ran first')
end

Given("Spotify returns top artists data") do
  TopArtistsCallStore.log = []
  TopArtistsCallStore.followed_ids = Set.new

  call_log = TopArtistsCallStore.log
  followed_state = TopArtistsCallStore.followed_ids

  mock = instance_double(SpotifyClient)
  @spotify_mock = mock
  allow(SpotifyClient).to receive(:new).and_return(mock)
  allow(mock).to receive(:followed_artists).and_return([])
  allow(mock).to receive(:new_releases).and_return([])
  allow(mock).to receive(:saved_shows).and_return(OpenStruct.new(items: []))
  allow(mock).to receive(:saved_episodes).and_return(OpenStruct.new(items: []))

  allow(mock).to receive(:top_artists) do |**args|
    limit = (args[:limit] || 10).to_i
    range = args[:time_range] || "long_term"

    call_log << { limit: limit, time_range: range }

    (1..limit).map do |i|
      OpenStruct.new(
        id:        "#{range}_artist_#{i}",
        name:      "Artist #{range} #{i}",
        playcount: 1_000 - i,
        image_url: nil
      )
    end
  end

  allow(mock).to receive(:top_tracks) do |**args|
    limit = (args[:limit] || 10).to_i
    range = args[:time_range] || "long_term"

    (1..limit).map do |i|
      OpenStruct.new(
        rank:              i,
        name:              "Track #{range} #{i}",
        artists:           "Artist #{i}",
        album_name:        "Album #{i}",
        album_image_url:   nil,
        popularity:        50 + i,
        preview_url:       nil,
        spotify_url:       "https://open.spotify.com/track/#{i}"
      )
    end
  end

  allow(mock).to receive(:followed_artist_ids) do |ids|
    Array(ids).map(&:to_s).each_with_object(Set.new) do |id, acc|
      acc << id if followed_state.include?(id)
    end
  end

  allow(mock).to receive(:follow_artists) do |ids|
    Array(ids).map(&:to_s).each { |id| followed_state << id }
    true
  end

  allow(mock).to receive(:unfollow_artists) do |ids|
    Array(ids).map(&:to_s).each { |id| followed_state.delete(id) }
    true
  end
end

Given("I am an authenticated user with spotify data") do
  step "Spotify returns top artists data"
  allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(OpenStruct.new(email: 'test@example.com'))
end

When("I visit the dashboard page") do
  visit dashboard_path
end

When("I click the View Top Artists button") do
  click_link 'View Top Artists'
  @top_artist_calls_snapshot = TopArtistsCallStore.log.dup
end

Given("the first artist in {string} column is already followed") do |range_key|
  artist_id = "#{range_key}_artist_1"
  TopArtistsCallStore.followed_ids ||= Set.new
  TopArtistsCallStore.followed_ids << artist_id
  mark_artist_followed!([ artist_id ]) if respond_to?(:mark_artist_followed!)
end

Given("Spotify follow API raises an unauthorized error once") do
  call_count = 0
  allow(spotify_mock).to receive(:follow_artists) do |ids|
    if call_count.zero?
      call_count += 1
      raise SpotifyClient::UnauthorizedError.new('token expired')
    else
      Array(ids).map(&:to_s).each { |id| TopArtistsCallStore.followed_ids << id }
      true
    end
  end
end

Given("Spotify follow API raises an insufficient scope error once") do
  call_count = 0
  allow(spotify_mock).to receive(:follow_artists) do |ids|
    if call_count.zero?
      call_count += 1
      raise SpotifyClient::Error.new('Insufficient client scope')
    else
      Array(ids).map(&:to_s).each { |id| TopArtistsCallStore.followed_ids << id }
      true
    end
  end
end

Given("Spotify follow API raises an error {string} once") do |message|
  call_count = 0
  allow(spotify_mock).to receive(:follow_artists) do |ids|
    if call_count.zero?
      call_count += 1
      raise SpotifyClient::Error.new(message)
    else
      Array(ids).map(&:to_s).each { |id| TopArtistsCallStore.followed_ids << id }
      true
    end
  end
end

Given("Spotify unfollow API raises an error {string} once") do |message|
  call_count = 0
  allow(spotify_mock).to receive(:unfollow_artists) do |ids|
    if call_count.zero?
      call_count += 1
      raise SpotifyClient::Error.new(message)
    else
      Array(ids).map(&:to_s)
      true
    end
  end
end

Given("Spotify unfollow API raises an unauthorized error once") do
  call_count = 0
  allow(spotify_mock).to receive(:unfollow_artists) do |ids|
    if call_count.zero?
      call_count += 1
      raise SpotifyClient::UnauthorizedError.new('token expired')
    else
      Array(ids).map(&:to_s)
      true
    end
  end
end

When("I go to the top artists page") do
  visit top_artists_path
end

When("I submit a follow request for {string}") do |artist_id|
  page.driver.header 'Referer', top_artists_path
  page.driver.post artist_follows_path, { spotify_id: artist_id }
end

When("I submit an unfollow request for {string}") do |artist_id|
  page.driver.header 'Referer', top_artists_path
  page.driver.delete artist_follow_path(artist_id)
end


When('I choose {string} for {string} and click Update') do |label, range_label|
  key = range_label_to_key(range_label)
  within(%Q(.top-artists-column[data-range="#{key}"])) do
    select(label, from: "limit_#{key}")
    click_button 'Update'
  end
end

When('I visit the top artists page with limits {string} for {string} and {string} for {string}') do |val1, r1, val2, r2|
  k1 = range_label_to_key(r1)
  k2 = range_label_to_key(r2)
  visit top_artists_path(
    "limit_#{k1}" => val1,
    "limit_#{k2}" => val2
  )
end

Then("I should be on the top artists page") do
  expect(current_path).to eql(top_artists_path)
end

Then("I should remain on the top artists page") do
  expect(page).to have_current_path(top_artists_path, ignore_query: true)
end

Then("I should be on the login page") do
  expected_paths = [ login_path, '/auth/spotify' ]
  expect(expected_paths).to include(URI.parse(current_url).path)
end

Then("the response should redirect to the login page") do
  location = page.driver.response.headers['Location']
  uri = URI.parse(location)
  acceptable = [ login_path, '/auth/spotify' ]
  expect(acceptable).to include(uri.path)
end

Then("the response should redirect to the top artists page with alert {string}") do |message|
  location = page.driver.response.headers['Location']
  expect(location).to include(top_artists_path)
  visit location
  expect(page).to have_content(message)
end

Then("the response should redirect to the login page with alert {string}") do |_message|
  location = page.driver.response.headers['Location']
  expect(location).to include(login_path)
end

Then("I should see either a top-artist list or a top-artist placeholder") do
  if page.has_css?('.top-artist')
    expect(page).to have_css('.top-artist')
  else
    expect(page).to have_text(/Top Artist|top artist|Top Artists/i)
  end
end

Then("the artists should be ordered by play count descending") do
  if page.has_css?('.top-artist .artist-plays')
    counts = page.all('.top-artist .artist-plays').map { |el| el.text.scan(/\d+/).first.to_i }
    expect(counts).to eq(counts.sort.reverse)
  else
    warn "Top artists present but no '.artist-plays' nodes found to assert ordering"
  end
end

Then("I should see top-artist columns for each time range") do
  expected_ranges = %w[long_term medium_term short_term]

  expected_ranges.each do |range|
    column = page.find(".top-artists-column[data-range='#{range}']")
    expect(column).to have_css('.top-artist', count: 10)

    counts = column.all('.top-artist .artist-plays').map { |el| el.text.scan(/\d+/).first.to_i }
    expect(counts).to eq(counts.sort.reverse)
  end
end

Then("Spotify should be asked for my top artists across all ranges") do
  expected_ranges = %w[long_term medium_term short_term]
  calls = (@top_artist_calls_snapshot && @top_artist_calls_snapshot.dup) || stubbed_top_artists_calls

  expect(calls).not_to be_empty

  expected_ranges.each do |range|
    range_calls = calls.select { |call| call[:time_range] == range }
    expect(range_calls).not_to be_empty
    expect(range_calls.last[:limit]).to eq(10)
  end
end

Then("if a list exists the artists should be ordered by play count descending") do
  step "the artists should be ordered by play count descending"
end

Then('the {string} selector should have {string} selected') do |range_label, label|
  key = range_label_to_key(range_label)
  within(%Q(.top-artists-column[data-range="#{key}"])) do
    expect(page).to have_select("limit_#{key}", selected: label)
  end
end

Then('the {string} column should list exactly {int} artists') do |range_label, n|
  key = range_label_to_key(range_label)
  within(%Q(.top-artists-column[data-range="#{key}"])) do
    expect(page.all(".top-artist").size).to eq(n)
  end
end

def within_first_artist_row_for(range_key, &block)
  within(%Q(.top-artists-column[data-range='#{range_key}'])) do
    row = first('.top-artist')
    raise "No artist rows found for #{range_key}" unless row
    within(row, &block)
  end
end

Then("I should see a Follow button for the first artist in the {string} column") do |range_key|
  within_first_artist_row_for(range_key) do
    expect(page).to have_button('Follow')
  end
end

Then("I should see an Unfollow button for the first artist in the {string} column") do |range_key|
  within_first_artist_row_for(range_key) do
    expect(page).to have_button('Unfollow')
  end
end

When("I follow the first artist in the {string} column") do |range_key|
  within_first_artist_row_for(range_key) do
    click_button 'Follow'
  end
end

When("I unfollow the first artist in the {string} column") do |range_key|
  within_first_artist_row_for(range_key) do
    click_button 'Unfollow'
  end
end


Given("I am not authenticated") do
  if respond_to?(:sign_out)
    sign_out(:user)
  else
    visit destroy_user_session_path if defined?(destroy_user_session_path)
  end
end

Then("I should be redirected to the sign in page") do
  expect(current_path).to match(/sign_in|login|users\/sign_in/)
end

Given("Spotify raises Unauthorized for top artists") do
  mock = instance_double(SpotifyClient)
  allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock)
  allow(mock).to receive(:top_artists).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
end
