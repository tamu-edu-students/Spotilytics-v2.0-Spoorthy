class OpenaiService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  def generate_search_query(natural_query)
    prompt = <<~PROMPT
      Convert the following natural language query into a simple, effective Spotify search query string.
      Return ONLY the query string, no other text.
      
      Examples:
      Input: "funny history podcasts"
      Output: history comedy
      
      Input: "true crime episodes under 30 mins"
      Output: true crime
      
      Input: "#{natural_query}"
      Output:
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3
      }
    )

    response.dig("choices", 0, "message", "content")&.strip || natural_query
  rescue StandardError => e
    Rails.logger.error("OpenAI Error: #{e.message}")
    natural_query
  end

  def summarize_episode(title, description)
    prompt = <<~PROMPT
      Summarize the following podcast episode in 2-3 sentences and extract 3-5 relevant tags (hashtags).
      
      Title: #{title}
      Description: #{description}
      
      Format:
      Summary: [Your summary]
      Tags: #Tag1 #Tag2 #Tag3
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.5
      }
    )

    response.dig("choices", 0, "message", "content")&.strip
  rescue StandardError => e
    Rails.logger.error("OpenAI Error: #{e.message}")
    nil
  end

  def generate_recommendation(user_shows, target_show_name, target_show_publisher)
    user_show_names = user_shows.map(&:name).take(5).join(", ")
    
    prompt = <<~PROMPT
      The user likes these podcasts: #{user_show_names}.
      Explain in 1 sentence why they might like the podcast "#{target_show_name}" by #{target_show_publisher}.
      Start with "Since you like..." or "Based on your interest in..."
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")&.strip
  rescue StandardError => e
    Rails.logger.error("OpenAI Error: #{e.message}")
    nil
  end
  def suggest_similar_shows(show_name, publisher)
    prompt = <<~PROMPT
      Suggest 5 podcasts that are similar to "#{show_name}" by #{publisher}.
      Return ONLY the names of the podcasts, separated by commas. No numbering, no other text.
      
      Example Output:
      Podcast A, Podcast B, Podcast C, Podcast D, Podcast E
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")&.strip
    return [] unless content

    content.split(",").map(&:strip)
  rescue StandardError => e
    Rails.logger.error("OpenAI Error: #{e.message}")
    []
  end

  def generate_bulk_recommendations(items_list, type)
    prompt = <<~PROMPT
      Based on this list of #{type} the user likes:
      #{items_list.join(", ")}
      
      Suggest 5 NEW #{type} they might enjoy.
      Return ONLY the names, separated by commas. No numbering.
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")&.strip
    return [] unless content

    content.split(",").map(&:strip)
  rescue StandardError => e
    Rails.logger.error("OpenAI Error: #{e.message}")
    []
  end
end
