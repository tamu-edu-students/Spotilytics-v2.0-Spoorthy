# Error Handling Steps

Given("Spotify API raises an error {string}") do |error_message|
  stub_request(:get, /https:\/\/api\.spotify\.com\/v1\/me\/shows/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API raises an unauthorized error") do
  stub_request(:get, /https:\/\/api\.spotify\.com\/v1\/me\/shows/)
    .to_return(status: 401, body: { error: { message: "Unauthorized" } }.to_json)
end

Given("Spotify API raises an error {string} during search") do |error_message|
  stub_request(:get, /https:\/\/api\.spotify\.com\/v1\/search/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API raises an error {string} during show save") do |error_message|
  stub_request(:put, /https:\/\/api\.spotify\.com\/v1\/me\/shows/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API raises an error {string} during show remove") do |error_message|
  stub_request(:delete, /https:\/\/api\.spotify\.com\/v1\/me\/shows/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

# AI Search Steps

When("I check {string}") do |label|
  check label
end

Given("Spotify API raises an error {string} during recommendation") do |error_message|
  stub_request(:get, "https://api.spotify.com/v1/shows/1")
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API raises an error {string} during similar") do |error_message|
  allow_any_instance_of(SpotifyClient).to receive(:get_show).and_raise(SpotifyClient::Error.new(error_message))
end

When("I click the button {string}") do |button_text|
  click_button button_text
end

When("I click the bulk recommendations link") do
  # Stub OpenAI for bulk recommendations
  allow_any_instance_of(OpenaiService).to receive(:generate_bulk_recommendations).and_return(["Bulk Rec 1"])
  
  # Stub search for bulk rec
  stub_request(:get, /search/)
    .to_return(status: 200, body: {
      shows: {
        items: [
          { id: "bulk_1", name: "Bulk Rec 1", publisher: "Pub", images: [], external_urls: { spotify: "url" }, total_episodes: 10 }
        ],
        total: 1
      }
    }.to_json)

  click_link "AI Recommendations"
end

Given("Spotify API raises an error {string} during bulk recommendations") do |error_message|
  stub_request(:get, /https:\/\/api\.spotify\.com\/v1\/me\/shows/)
    .with(query: hash_including(limit: "10"))
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Given("Spotify API returns success for bulk save") do
  stub_request(:put, /https:\/\/api\.spotify\.com\/v1\/me\/shows/)
    .to_return(status: 200)
end

Given("Spotify API raises an error {string} during bulk save") do |error_message|
  stub_request(:put, /https:\/\/api\.spotify\.com\/v1\/me\/shows/)
    .to_return(status: 500, body: { error: { message: error_message } }.to_json)
end

Before do
  # Stub OpenAI globally for these tests to avoid WebMock errors
  stub_request(:post, "https://api.openai.com/v1/chat/completions")
    .to_return(status: 200, body: {
      choices: [
        { message: { content: "optimized query" } }
      ]
    }.to_json)
end
