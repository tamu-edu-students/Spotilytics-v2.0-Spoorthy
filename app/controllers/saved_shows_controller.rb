class SavedShowsController < ApplicationController
  before_action :require_spotify_auth!

  def index
    client = SpotifyClient.new(session: session)
    @page = (params[:page] || 1).to_i
    @limit = 5
    offset = (@page - 1) * @limit

    begin
      result = client.saved_shows(limit: @limit, offset: offset)
      @shows = result.items
      @total = result.total
      @total_pages = (@total.to_f / @limit).ceil
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in again."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      @error = "Could not load saved shows."
      @shows = []
      @total = 0
      @total_pages = 0
    end
  end

  def destroy
    client = SpotifyClient.new(session: session)
    show_id = params[:id]

    begin
      client.remove_shows([ show_id ])
      client.clear_user_cache
      redirect_to saved_shows_path, notice: "Show removed from your library."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      redirect_to saved_shows_path, alert: "Could not remove show."
    end
  end

  def search
    @query = params[:query]
    @shows = []
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
        result = client.search_shows(search_term, limit: @limit, offset: offset)
        @shows = result.items
        @total = result.total
        @total_pages = (@total.to_f / @limit).ceil
      rescue SpotifyClient::Error => e
        Rails.logger.error "Spotify error: #{e.message}"
        @error = "Could not search for shows."
        @total = 0
        @total_pages = 0
      end
    end
  end

  def create
    client = SpotifyClient.new(session: session)
    show_id = params[:id]

    begin
      client.save_shows([ show_id ])
      client.clear_user_cache
      redirect_to saved_shows_path, notice: "Show saved to your library."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      redirect_to saved_shows_path, alert: "Could not save show."
    end
  end
  def recommendation
    client = SpotifyClient.new(session: session)
    show_id = params[:id]

    begin
      # Fetch target show details
      target_show = client.get_show(show_id)
      
      # Fetch user's saved shows for context
      saved_shows = client.saved_shows(limit: 5).items
      
      openai_service = OpenaiService.new
      @recommendation = openai_service.generate_recommendation(saved_shows, target_show.name, target_show.publisher)
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to saved_shows_path, notice: "Recommendation generated." }
      end
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      redirect_to saved_shows_path, alert: "Could not generate recommendation."
    end
  end

  def similar
    client = SpotifyClient.new(session: session)
    show_id = params[:id]

    begin
      target_show = client.get_show(show_id)
      openai_service = OpenaiService.new
      suggested_names = openai_service.suggest_similar_shows(target_show.name, target_show.publisher)
      
      @similar_shows = []
      suggested_names.each do |name|
        # Search for each suggested show to get its Spotify details
        # We take the first result that matches loosely
        results = client.search_shows(name, limit: 1)
        if results.items.any?
          @similar_shows << results.items.first
        end
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to saved_shows_path, notice: "Found #{@similar_shows.size} similar shows." }
      end
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      redirect_to saved_shows_path, alert: "Could not find similar shows."
    end
  end

  def bulk_recommendations
    client = SpotifyClient.new(session: session)
    
    begin
      # Fetch last 10 saved shows for context
      saved_shows = client.saved_shows(limit: 10).items
      
      if saved_shows.empty?
        @error = "You need to save some shows first!"
        @recommendations = []
        return
      end

      show_names = saved_shows.map(&:name)
      
      openai_service = OpenaiService.new
      suggested_names = openai_service.generate_bulk_recommendations(show_names, "podcasts")
      
      @recommendations = []
      suggested_names.each do |name|
        results = client.search_shows(name, limit: 1)
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
        client.save_shows(ids)
        client.clear_user_cache
        redirect_to saved_shows_path, notice: "Saved #{ids.size} shows to your library."
      rescue SpotifyClient::Error => e
        Rails.logger.error "Spotify error: #{e.message}"
        redirect_to saved_shows_path, alert: "Could not save shows."
      end
    else
      redirect_to saved_shows_path, alert: "No shows selected."
    end
  end
end
