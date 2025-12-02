class SavedEpisodesController < ApplicationController
  before_action :require_spotify_auth!

  def index
    client = SpotifyClient.new(session: session)
    @page = (params[:page] || 1).to_i
    
    # If grouping by show, fetch more items to make grouping useful (effectively disabling pagination for now)
    # Otherwise, use standard pagination
    if params[:group_by] == "show"
      @limit = 50 
    else
      @limit = 5
    end
    
    offset = (@page - 1) * @limit

    begin
      result = client.saved_episodes(limit: @limit, offset: offset)
      @episodes = result.items
      @total = result.total
      @total_pages = (@total.to_f / @limit).ceil

      if params[:group_by] == "show"
        @grouped_episodes = @episodes.group_by(&:show_name)
      end
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in again."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      @error = "Could not load saved episodes."
      @episodes = []
      @total = 0
      @total_pages = 0
    end
  end

  def destroy
    client = SpotifyClient.new(session: session)
    episode_id = params[:id]

    begin
      client.remove_episodes([ episode_id ])
      client.clear_user_cache
      redirect_to saved_episodes_path, notice: "Episode removed from your library."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      redirect_to saved_episodes_path, alert: "Could not remove episode."
    end
  end

  def search
    @query = params[:query]
    @episodes = []
    @page = (params[:page] || 1).to_i
    @limit = 5
    offset = (@page - 1) * @limit

    if @query.present?
      # AI Smart Search
      # If toggle is explicitly on, OR (toggle is not present AND query is complex)
      use_ai = params[:ai_search] == "true" || (params[:ai_search].blank? && @query.split.size > 3)

      if use_ai
        openai_service = OpenaiService.new
        optimized_query = openai_service.generate_search_query(@query)
        Rails.logger.info "AI Search: '#{@query}' -> '#{optimized_query}'"
        search_term = optimized_query
      else
        search_term = @query
      end

      client = SpotifyClient.new(session: session)
      begin
        result = client.search_episodes(search_term, limit: @limit, offset: offset)
        @episodes = result.items
        @total = result.total
        @total_pages = (@total.to_f / @limit).ceil
      rescue SpotifyClient::Error => e
        Rails.logger.error "Spotify error: #{e.message}"
        @error = "Could not search for episodes."
        @total = 0
        @total_pages = 0
      end
    end
  end

  def create
    client = SpotifyClient.new(session: session)
    episode_id = params[:id]

    begin
      client.save_episodes([ episode_id ])
      client.clear_user_cache
      redirect_to saved_episodes_path, notice: "Episode saved to your library."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      redirect_to saved_episodes_path, alert: "Could not save episode."
    end
  end
  def summarize
    client = SpotifyClient.new(session: session)
    episode_id = params[:id]

    begin
      # Fetch episode details from Spotify to get title and description
      episode = client.get_episode(episode_id)
      
      openai_service = OpenaiService.new
      @summary = openai_service.summarize_episode(episode.name, episode.description)
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to saved_episodes_path, notice: "Summary generated." }
      end
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      redirect_to saved_episodes_path, alert: "Could not summarize episode."
    end
  end
  def bulk_recommendations
    client = SpotifyClient.new(session: session)
    
    begin
      # Fetch last 10 saved episodes
      saved_episodes = client.saved_episodes(limit: 10).items
      
      if saved_episodes.empty?
        @error = "You need to save some episodes first!"
        @recommendations = []
        return
      end

      episode_names = saved_episodes.map(&:name)
      
      openai_service = OpenaiService.new
      suggested_names = openai_service.generate_bulk_recommendations(episode_names, "podcast episodes")
      
      @recommendations = []
      suggested_names.each do |name|
        results = client.search_episodes(name, limit: 1)
        if results.items.any?
          @recommendations << results.items.first
        end
      end
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      @error = "Could not generate recommendations."
      @recommendations = []
    end
  end

  def bulk_save
    client = SpotifyClient.new(session: session)
    ids = params[:ids]

    if ids.present?
      begin
        client.save_episodes(ids)
        client.clear_user_cache
        redirect_to saved_episodes_path, notice: "Saved #{ids.size} episodes to your library."
      rescue SpotifyClient::Error => e
        Rails.logger.error "Spotify error: #{e.message}"
        redirect_to saved_episodes_path, alert: "Could not save episodes."
      end
    else
      redirect_to saved_episodes_path, alert: "No episodes selected."
    end
  end
end
