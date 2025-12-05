# Error Handling Steps

Given("Spotify API raises an error {string} for episodes") do |error_message|
  stub_request(:get, /https:\/\/api\.spotify\.com\/v1\/me\/episodes/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API raises an unauthorized error for episodes") do
  stub_request(:get, /https:\/\/api\.spotify\.com\/v1\/me\/episodes/)
    .to_return(status: 401, body: { error: { message: "Unauthorized" } }.to_json)
end

Given("Spotify API raises an error {string} during episode search") do |error_message|
  stub_request(:get, /https:\/\/api\.spotify\.com\/v1\/search/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API raises an error {string} during episode save") do |error_message|
  stub_request(:put, /https:\/\/api\.spotify\.com\/v1\/me\/episodes/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API raises an error {string} during episode remove") do |error_message|
  stub_request(:delete, /https:\/\/api\.spotify\.com\/v1\/me\/episodes/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

# AI Search Steps





# Summarize Steps

When("I click the button {string} for the first episode") do |button_title|
  # Stub episode details fetch
  stub_request(:get, "https://api.spotify.com/v1/episodes/1")
    .to_return(status: 200, body: { id: "1", name: "Saved Episode", description: "Desc" }.to_json)

  # Stub OpenAI
  allow_any_instance_of(OpenaiService).to receive(:summarize_episode).and_return("Episode Summary")

  # Click button by title
  click_button button_title
end

When("I click the button {string} for the first episode without stubbing") do |button_title|
  click_button button_title
end

When("I click {string} for the first episode without stubbing") do |button_text|
  first(:button, title: button_text).click
end

Given("Spotify API raises an error {string} during summary") do |error_message|
  stub_request(:get, "https://api.spotify.com/v1/episodes/1")
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

# Bulk Actions Steps

When("I click the episode bulk recommendations link") do
  # Stub OpenAI for bulk recommendations
  allow_any_instance_of(OpenaiService).to receive(:generate_bulk_recommendations).and_return(["Bulk Rec 1"])
  
  # Stub search for bulk rec
  stub_request(:get, /search/)
    .to_return(status: 200, body: {
      episodes: {
        items: [
          { id: "bulk_1", name: "Bulk Rec 1", show: { name: "Show" }, images: [], external_urls: { spotify: "url" }, duration_ms: 60000, release_date: "2023-01-01" }
        ],
        total: 1
      }
    }.to_json)

  click_link "AI Recommendations"
end



Given("Spotify API raises an error {string} during episode bulk recommendations") do |error_message|
  stub_request(:get, /https:\/\/api\.spotify\.com\/v1\/me\/episodes/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API raises an error {string} during episode bulk save") do |error_message|
  stub_request(:put, /https:\/\/api\.spotify\.com\/v1\/me\/episodes/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API returns success for bulk episode save") do
  stub_request(:put, /https:\/\/api\.spotify\.com\/v1\/me\/episodes/)
    .to_return(status: 200)
end

Given("Spotify API raises an error {string} during bulk episode save") do |error_message|
  stub_request(:put, /https:\/\/api\.spotify\.com\/v1\/me\/episodes/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

# Grouping Steps

Then("I should see episodes grouped by show") do
  expect(page).to have_selector("h3", text: "Show")
end
