require "rails_helper"
require "stringio"

RSpec.describe "Additional coverage", type: :controller do
  describe ApplicationController do
    controller(ApplicationController) do
      def index
        render plain: hidden_top_track_count_for(params[:range])
      end
    end

    it "counts hidden tracks for a user" do
      session[:spotify_user] = { "id" => "user-1" }
      session[:hidden_top_tracks] = {
        "user-1" => { "short_term" => %w[a b], "medium_term" => [], "long_term" => [] }
      }

      get :index, params: { range: "short_term" }

      expect(response.body).to eq("2")
    end
  end

  describe PagesController do
    controller(PagesController) do; end

    before do
      routes.draw { get "top_tracks" => "pages#top_tracks" }
      session[:spotify_token] = "token"
      session[:spotify_user] = { "id" => "user-1" }
    end

    it "redirects to home when top_tracks raises UnauthorizedError" do
      allow_any_instance_of(SpotifyClient).to receive(:top_tracks).and_raise(SpotifyClient::UnauthorizedError)

      get :top_tracks

      expect(response).to redirect_to(home_path)
    end

    it "shows an alert when top_tracks raises a Spotify error" do
      allow_any_instance_of(SpotifyClient).to receive(:top_tracks).and_raise(SpotifyClient::Error.new("boom"))
      allow(controller).to receive(:default_render).and_return(nil)

      get :top_tracks

      expect(assigns(:top_tracks)).to eq([])
      expect(flash.now[:alert]).to include("unable to load your top tracks")
    end

    it "delegates playlist fetch with offset" do
      client = instance_double(SpotifyClient)
      allow(controller).to receive(:spotify_client).and_return(client)
      expect(client).to receive(:user_playlists).with(limit: 3, offset: 2).and_return(:playlists)

      expect(controller.send(:fetch_user_playlists, limit: 3, offset: 2)).to eq(:playlists)
    end

    it "returns empty saved shows when Spotify errors" do
      client = instance_double(SpotifyClient)
      allow(controller).to receive(:spotify_client).and_return(client)
      allow(client).to receive(:saved_shows).and_raise(SpotifyClient::Error.new("bad"))

      expect(controller.send(:fetch_saved_shows, limit: 1)).to eq([])
    end

    it "returns empty saved episodes when Spotify errors" do
      client = instance_double(SpotifyClient)
      allow(controller).to receive(:spotify_client).and_return(client)
      allow(client).to receive(:saved_episodes).and_raise(SpotifyClient::Error.new("bad"))

      expect(controller.send(:fetch_saved_episodes, limit: 1)).to eq([])
    end
  end

  describe PlaylistsController do
    controller(PlaylistsController) do; end

    before do
      routes.draw do
        post "create" => "playlists#create"
        post "create_from_recommendations" => "playlists#create_from_recommendations"
        post "add_song" => "playlists#add_song"
      end
      session[:spotify_user] = { "present" => true }
      session[:spotify_token] = "token"
    end

    let(:client) { instance_double(SpotifyClient) }

    before do
      allow(SpotifyClient).to receive(:new).and_return(client)
    end

    it "stores user id in session when creating a playlist" do
      allow(client).to receive(:current_user_id).and_return("user-abc")
      allow(client).to receive(:top_tracks).and_return([OpenStruct.new(id: "t1")])
      allow(client).to receive(:create_playlist_for).and_return("pl-1")
      allow(client).to receive(:add_tracks_to_playlist).and_return(true)

      post :create, params: { time_range: "short_term" }

      expect(session[:spotify_user]["id"]).to eq("user-abc")
      expect(response).to redirect_to(top_tracks_path)
    end

    it "stores user id in session when creating playlist from recommendations" do
      allow(client).to receive(:current_user_id).and_return("user-xyz")
      allow(client).to receive(:create_playlist_for).and_return("pl-2")
      allow(client).to receive(:add_tracks_to_playlist).and_return(true)

      post :create_from_recommendations, params: { uris: ["spotify:track:1"] }

      expect(session[:spotify_user]["id"]).to eq("user-xyz")
      expect(response).to redirect_to(recommendations_path)
    end

    it "uses fallback assignment when session object cannot merge" do
      class SessionProxy
        def initialize; @store = {}; end
        def []=(k, v); @store[k] = v; end
        def [](k); @store[k]; end
        def respond_to?(name, include_private = false); name == :[] || name == :[]= || super; end
      end

      session[:spotify_user] = SessionProxy.new
      allow(client).to receive(:current_user_id).and_return("user-proxy")
      allow(client).to receive(:top_tracks).and_return([OpenStruct.new(id: "t1")])
      allow(client).to receive(:create_playlist_for).and_return("pl-3")
      allow(client).to receive(:add_tracks_to_playlist).and_return(true)

      post :create, params: { time_range: "short_term" }

      expect(session[:spotify_user]["id"]).to eq("user-proxy")
    end

    it "uses fallback assignment when creating playlist from recommendations" do
      session[:spotify_user] = SessionProxy.new
      allow(client).to receive(:current_user_id).and_return("user-fallback")
      allow(client).to receive(:create_playlist_for).and_return("pl-4")
      allow(client).to receive(:add_tracks_to_playlist).and_return(true)

      post :create_from_recommendations, params: { uris: ["spotify:track:3"] }

      expect(session[:spotify_user]["id"]).to eq("user-fallback")
    end

    it "handles malformed CSV uploads" do
      allow(client).to receive(:search_tracks).and_return([])
      allow(CSV).to receive(:new).and_raise(CSV::MalformedCSVError.new("bad", 1))
      upload = Rack::Test::UploadedFile.new(StringIO.new("bad"), "text/csv", original_filename: "bad.csv")

      post :add_song, params: { file_add: "1", tracks_csv: upload }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash.now[:alert]).to include("Could not read that CSV file")
    end

    it "adds a single song and sets notice" do
      track = OpenStruct.new(id: "t1", name: "Song", artists: "Artist")
      allow(client).to receive(:search_tracks).and_return([track])

      post :add_song, params: { single_add: "1", song_query: "Song" }

      expect(flash.now[:notice]).to include("Added Song by Artist")
      expect(response).to have_http_status(:ok)
    end

    it "sets notice when adding a duplicate track" do
      track = OpenStruct.new(id: "t2", name: "Song 2", artists: "Artist")
      allow(client).to receive(:search_tracks).and_return([track])
      allow(controller).to receive(:add_track_to_builder).and_return(false)

      post :add_song, params: { single_add: "1", song_query: "Song 2" }

      expect(flash.now[:notice]).to include("Song 2 is already in your list.")
    end

    it "shows alert when no tracks are found" do
      allow(client).to receive(:search_tracks).and_return([])

      post :add_song, params: { single_add: "1", song_query: "Missing Song" }

      expect(flash.now[:alert]).to include('No songs found for "Missing Song"')
    end

    it "parses track params from ActionController::Parameters" do
      controller.params[:tracks] = ActionController::Parameters.new("one" => { id: "1", name: "N", artists: "A" })

      result = controller.send(:parse_tracks_params)

      expect(result).to eq([ { id: "1", name: "N", artists: "A" } ])
    end

    it "parses track params from a Hash" do
      raw = { "two" => { id: "2", name: "N2", artists: "A2" } }
      allow(controller).to receive(:params).and_return({ tracks: raw })

      result = controller.send(:parse_tracks_params)

      expect(result).to eq([ { id: "2", name: "N2", artists: "A2" } ])
    end
  end

  describe SavedShowsController do
    controller(SavedShowsController) do; end

    before do
      routes.draw do
        get "saved_shows" => "saved_shows#index"
        post "saved_shows/bulk_save" => "saved_shows#bulk_save"
      end
      session[:spotify_user] = { "id" => "user-1" }
      session[:spotify_token] = "token"
    end

    it "redirects to root when saved shows are unauthorized" do
      client = instance_double(SpotifyClient)
      allow(SpotifyClient).to receive(:new).and_return(client)
      allow(client).to receive(:saved_shows).and_raise(SpotifyClient::UnauthorizedError)

      get :index

      expect(response).to redirect_to(root_path)
    end

    it "alerts when no show ids are provided to bulk_save" do
      allow(SpotifyClient).to receive(:new).and_return(instance_double(SpotifyClient, save_shows: true, clear_user_cache: true))

      post :bulk_save

      expect(response).to redirect_to(saved_shows_path)
      expect(flash[:alert]).to eq("No shows selected.")
    end
  end

  describe TopTracksController do
    controller(TopTracksController) do; end

    before do
      routes.draw do
        get "top_tracks" => "top_tracks#index"
        post "top_tracks/hide" => "top_tracks#hide"
        post "top_tracks/unhide" => "top_tracks#unhide"
      end
      session[:spotify_user] = { "id" => "user-1" }
      session[:spotify_token] = "token"
    end

    let(:client) { instance_double(SpotifyClient) }

    it "recovers when hidden track lookups fail" do
      call = 0
      allow(SpotifyClient).to receive(:new).and_return(client)
      allow(client).to receive(:top_tracks) do
        call += 1
        case call
        when 1 then [OpenStruct.new(id: "s1")]
        when 2 then [OpenStruct.new(id: "m1")]
        when 3 then [OpenStruct.new(id: "l1")]
        else
          raise SpotifyClient::Error.new("boom")
        end
      end

      session[:hidden_top_tracks] = { "user-1" => { "short_term" => ["x"], "medium_term" => [], "long_term" => [] } }

      get :index

      expect(assigns(:hidden_short)).to eq([])
    end

    it "redirects hide when user id is missing" do
      session[:spotify_user] = { "name" => "NoId" }

      post :hide, params: { time_range: "short_term", track_id: "t1" }

      expect(response).to redirect_to(root_path)
    end

    it "redirects unhide when user id is missing" do
      session[:spotify_user] = { "name" => "NoId" }

      post :unhide, params: { time_range: "short_term", track_id: "t1" }

      expect(response).to redirect_to(root_path)
    end
  end
end
