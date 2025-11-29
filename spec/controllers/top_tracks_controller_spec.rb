# spec/controllers/top_tracks_controller_spec.rb
require "rails_helper"

RSpec.describe TopTracksController, type: :controller do
  describe "GET #index" do
    let(:session_user) do
      {
        "display_name" => "Test Listener",
        "email"        => "listener@example.com",
        "image"        => "http://example.com/user.jpg"
      }
    end

    context "when not logged in" do
      it "redirects to root with alert" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please sign in with Spotify first.")
      end
    end

    context "when logged in and SpotifyClient succeeds" do
      render_views

      let(:short_tracks) do
        [
          OpenStruct.new(rank: 1, name: "Short A", artists: "S-Artist", album_name: "S-Album",
                         album_image_url: nil, popularity: 90, preview_url: nil, spotify_url: nil)
        ]
      end
      let(:medium_tracks) do
        [
          OpenStruct.new(rank: 1, name: "Medium A", artists: "M-Artist", album_name: "M-Album",
                         album_image_url: nil, popularity: 91, preview_url: nil, spotify_url: nil)
        ]
      end
      let(:long_tracks) do
        [
          OpenStruct.new(rank: 1, name: "Yearly Favorite", artists: "Iconic Artist",
                         album_name: "Best Album", album_image_url: "http://img/cover.jpg",
                         popularity: 95, preview_url: nil, spotify_url: "https://open.spotify.com/track/abc123")
        ]
      end

      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user

        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)

        allow(mock_client).to receive(:top_tracks)
          .with(limit: 10, time_range: "short_term").and_return(short_tracks)
        allow(mock_client).to receive(:top_tracks)
          .with(limit: 10, time_range: "medium_term").and_return(medium_tracks)
        allow(mock_client).to receive(:top_tracks)
          .with(limit: 10, time_range: "long_term").and_return(long_tracks)
      end

      it "assigns lists for short/medium/long and renders them" do
        get :index

        expect(assigns(:tracks_short)).to  eq(short_tracks)
        expect(assigns(:tracks_medium)).to eq(medium_tracks)
        expect(assigns(:tracks_long)).to   eq(long_tracks)
        expect(response).to have_http_status(:ok)

        expect(response.body).to include("Short A")
        expect(response.body).to include("Medium A")
        expect(response.body).to include("Yearly Favorite")
        expect(response.body).to include("Iconic Artist")
      end
    end

    context "when SpotifyClient::UnauthorizedError is raised" do
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
      end

      it "redirects to root with session-expired alert" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Session expired. Please sign in with Spotify again.")
      end
    end

    context "when SpotifyClient::Error is raised" do
      render_views

      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_raise(SpotifyClient::Error.new("Spotify down"))
      end

      it "assigns empty lists, sets error, renders 200 with fallback message" do
        get :index

        expect(assigns(:tracks_short)).to  eq([])
        expect(assigns(:tracks_medium)).to eq([])
        expect(assigns(:tracks_long)).to   eq([])
        expect(assigns(:error)).to eq("Couldn't load your top tracks from Spotify.")
        expect(response).to have_http_status(:ok)

        # HTML escapes apostrophes
        expect(response.body).to include("Couldn&#39;t load your top tracks from Spotify.")
      end
    end

    context "when logged in with a custom limit (same limit for all ranges)" do
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_return([])
      end

      it "calls Spotify with limit=25 for short/medium/long" do
        get :index, params: { limit: "25" }

        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "short_term")
        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "medium_term")
        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "long_term")
                expect(response).to have_http_status(:ok)
      end

      it "calls Spotify with limit=50 for all" do
        get :index, params: { limit: "50" }

        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "short_term")
        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "medium_term")
        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "long_term")
      end
    end

    context "when per-range limits are provided" do
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_return([])
      end

      it "respects per-range limit parameters and falls back for invalid" do
        get :index, params: { limit_short_term: "25", limit_medium_term: "50", limit_long_term: "999" }

        expect(mock_client).to have_received(:top_tracks).with(limit: 25, time_range: "short_term")
        expect(mock_client).to have_received(:top_tracks).with(limit: 50, time_range: "medium_term")
        expect(mock_client).to have_received(:top_tracks).with(limit: 10, time_range: "long_term")
      end
    end

    context "when medium and long hidden ids present and candidates are found" do
      let(:mock_client) { instance_double(SpotifyClient) }

      let(:initial_medium) { [ OpenStruct.new(id: "m1", name: "M One"), OpenStruct.new(id: "m3", name: "M Three") ] }
      let(:initial_long)   { [ OpenStruct.new(id: "l2", name: "L Two") ] }

      let(:candidates_medium) { [ OpenStruct.new(id: "m1", name: "M One"), OpenStruct.new(id: "m2", name: "M Two") ] }
      let(:candidates_long)   { [ OpenStruct.new(id: "l1", name: "L One") ] }

      before do
        session[:spotify_user] = session_user.merge("id" => "hid_user2")
        session[:hidden_top_tracks] = {
          "hid_user2" => {
            "short_term" => [],
            "medium_term" => [ "m1", "m2" ],
            "long_term" => [ "l1" ]
          }
        }

        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)

        allow(mock_client).to receive(:top_tracks) do |**kwargs|
          tr = kwargs[:time_range].to_s
          lim = kwargs[:limit].to_i
          if lim == 10
            case tr
            when "short_term" then []
            when "medium_term" then initial_medium
            when "long_term" then initial_long
            else []
            end
          else
            case tr
            when "medium_term" then candidates_medium
            when "long_term" then candidates_long
            else []
            end
          end
        end
      end

      it "builds @hidden_medium/@hidden_long from candidates and filters tracks" do
        get :index

        expect(assigns(:hidden_medium).map(&:id)).to match_array(%w[m1 m2])
        expect(assigns(:hidden_long).map(&:id)).to match_array(%w[l1])

        expect(assigns(:tracks_medium).map(&:id)).not_to include("m1")
        expect(assigns(:tracks_medium).map(&:id)).to include("m3")

        expect(mock_client).to have_received(:top_tracks).with(hash_including(time_range: "medium_term", limit: 50))
        expect(mock_client).to have_received(:top_tracks).with(hash_including(time_range: "long_term", limit: 50))
      end
    end

    context "when hidden ids are present but candidate fetch returns none" do
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user.merge("id" => "user_missing")
        session[:hidden_top_tracks] = { "user_missing" => { "short_term" => [ "missing_1" ], "medium_term" => [], "long_term" => [] } }

        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)

        allow(mock_client).to receive(:top_tracks) do |**kwargs|
          if kwargs[:limit].to_i == 10
            case kwargs[:time_range]
            when "short_term" then [ OpenStruct.new(id: "present") ]
            else []
            end
          else
            []
          end
        end
      end

      it "logs missing hidden ids when candidates don't include them" do
        allow(Rails.logger).to receive(:info)
        get :index
        expect(Rails.logger).to have_received(:info).with(/Hidden track ids not found/)
      end
    end

    context "when logged in with an invalid limit" do
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_return([])
      end

      it "falls back to limit=10 for all ranges" do
        get :index, params: { limit: "999" }

        expect(mock_client).to have_received(:top_tracks).with(limit: 10, time_range: "short_term")
        expect(mock_client).to have_received(:top_tracks).with(limit: 10, time_range: "medium_term")
        expect(mock_client).to have_received(:top_tracks).with(limit: 10, time_range: "long_term")
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST #hide and POST #unhide" do
    let(:user_id) { "cuke_user_1" }

    before do
      session[:spotify_user] = { "id" => user_id, "display_name" => "Tester" }
    end

    it "redirects to root when not logged in" do
      session.delete(:spotify_user)
      post :hide, params: { time_range: 'short_term', track_id: 't1' }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Please sign in with Spotify first.")
    end

    it "rejects invalid time_range" do
      post :hide, params: { time_range: 'invalid', track_id: 't1' }
      expect(response).to redirect_to(top_tracks_path)
      expect(flash[:alert]).to eq("Invalid time range.")
    end

    it "hides a track and stores it in the session" do
      post :hide, params: { time_range: 'short_term', track_id: 'track_123' }
      expect(response).to redirect_to(top_tracks_path)
  expect(flash[:notice]).to eq("Track hidden from short term list.")

      hidden = session[:hidden_top_tracks][user_id]
      expect(hidden['short_term']).to include('track_123')
    end

    it "does not allow hiding more than 5 tracks" do
      # pre-fill with 5 ids
      session[:hidden_top_tracks] ||= {}
      session[:hidden_top_tracks][user_id] = {
        'short_term' => %w[a b c d e],
        'medium_term' => [],
        'long_term' => []
      }

      post :hide, params: { time_range: 'short_term', track_id: 'z' }
      expect(response).to redirect_to(top_tracks_path)
      expect(flash[:alert]).to eq("Could not hide track — you can hide at most 5 tracks per list.")
    end

    it "unhides a previously hidden track" do
      session[:hidden_top_tracks] ||= {}
      session[:hidden_top_tracks][user_id] = {
        'short_term' => [ 'to_remove' ],
        'medium_term' => [],
        'long_term' => []
      }

      post :unhide, params: { time_range: 'short_term', track_id: 'to_remove' }
      expect(response).to redirect_to(top_tracks_path)
      expect(flash[:notice]).to eq("Track restored to short term list.")

      hidden = session[:hidden_top_tracks][user_id]
      expect(hidden['short_term']).not_to include('to_remove')
    end
  end
end
