Then("I should see top tracks alert {string}") do |msg|
  expect(page).to have_content(msg)
end
# features/step_definitions/hide_unhide_top_tracks_steps.rb

Given("I am logged in with Spotify") do
  step "I am logged in with Spotify for the top tracks page"
end

Given("I am on the top tracks page") do
  visit Rails.application.routes.url_helpers.top_tracks_path
end


Given("I am not logged in for top tracks") do
  if page.respond_to?(:set_rack_session)
    page.set_rack_session(spotify_user: nil)
  else
    visit Rails.application.routes.url_helpers.root_path
    page.driver.request.session[:spotify_user] = nil if page.driver.respond_to?(:request)
  end
end




Given("the track {string} is hidden from my short term list") do |track_id|
  user_id = page.driver.request.session[:spotify_user]&.fetch('id', nil) || 'user_123'
  session_hash = page.driver.request.session[:hidden_top_tracks] || {}
  session_hash[user_id] ||= { 'short_term' => [], 'medium_term' => [], 'long_term' => [] }
  session_hash[user_id]['short_term'] << track_id unless session_hash[user_id]['short_term'].include?(track_id)
  page.driver.request.session[:hidden_top_tracks] = session_hash
end



Given("I have already hidden 5 tracks from my short term list") do
  %w[a b c d e].each do |track_id|
    page.driver.submit :post, Rails.application.routes.url_helpers.hide_top_track_path,
                       { time_range: "short_term", track_id: track_id }
  end
end


When("I hide the track {string} from the {string} list") do |track_id, range|
  visit Rails.application.routes.url_helpers.top_tracks_path
  page.driver.submit :post, Rails.application.routes.url_helpers.hide_top_track_path, { time_range: range, track_id: track_id }
end

When("I unhide the track {string} from the {string} list") do |track_id, range|
  visit Rails.application.routes.url_helpers.top_tracks_path
  page.driver.submit :post, Rails.application.routes.url_helpers.unhide_top_track_path, { time_range: range, track_id: track_id }
end



Then("I should see top tracks message {string}") do |msg|
  toast = page.find('.toast-container', match: :first, visible: :all)
  expect(toast).to have_content(msg)
end


Then("the track {string} should be hidden from my short term list") do |track_id|
  user_id = page.driver.request.session[:spotify_user]&.fetch('id', nil) || 'user_123'
  hidden_hash = page.driver.request.session[:hidden_top_tracks] || {}
  hidden = hidden_hash[user_id] ? hidden_hash[user_id]['short_term'] : []
  expect(hidden).to include(track_id)
end

Then("the track {string} should not be hidden from my short term list") do |track_id|
  user_id = page.driver.request.session[:spotify_user]&.fetch('id', nil) || 'user_123'
  hidden_hash = page.driver.request.session[:hidden_top_tracks] || {}
  hidden = hidden_hash[user_id] ? hidden_hash[user_id]['short_term'] : []
  expect(hidden).not_to include(track_id)
end
