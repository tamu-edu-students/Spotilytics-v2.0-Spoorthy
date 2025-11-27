require "rails_helper"
require "set"

RSpec.describe PlaylistsController, type: :controller do
    shared_context "logged in user" do
        let(:session_user) do
        {
            "display_name" => "Test Listener",
            "email"        => "listener@example.com",
            "image"        => "http://example.com/user.jpg"
        }
        end

        before { session[:spotify_user] = session_user }
    end

    include_context "logged in user"

    let(:spotify_client) { instance_double(SpotifyClient) }
    let(:spotify_id) { "artist123" }

    before do
        allow(SpotifyClient).to receive(:new).and_return(spotify_client)
    end

    describe "POST #create" do
        let(:time_range) { "medium_term" }

        context "when user is not logged in" do
            before { session.delete(:spotify_user) }

            it "redirects to root with alert" do
                post :create, params: { time_range: time_range }
                expect(response).to redirect_to(root_path)
                expect(flash[:alert]).to eq("Please sign in with Spotify first.")
            end
        end

        context "when time_range is invalid" do
            it "redirects to top_tracks_path with alert" do
                post :create, params: { time_range: "invalid_range" }
                expect(response).to redirect_to(top_tracks_path)
                expect(flash[:alert]).to eq("Invalid time range.")
            end
        end

        context "when time_range is valid" do
            let(:tracks) do
                [
                double("Track", id: "track1"),
                double("Track", id: "track2")
                ]
            end

            before do
                allow(spotify_client).to receive(:current_user_id).and_return("user123")
                allow(spotify_client).to receive(:top_tracks).and_return(tracks)
                allow(spotify_client).to receive(:create_playlist_for).and_return("playlist_123")
                allow(spotify_client).to receive(:add_tracks_to_playlist)
            end

            it "creates a playlist and redirects with notice" do
                post :create, params: { time_range: time_range }

                expect(spotify_client).to have_received(:create_playlist_for).with(
                user_id: "user123",
                name: "Your Top Tracks - Last 6 Months",
                description: "Auto-created from Spotilytics • Last 6 Months",
                public: false
                )

                expect(spotify_client).to have_received(:add_tracks_to_playlist).with(
                playlist_id: "playlist_123",
                uris: [ "spotify:track:track1", "spotify:track:track2" ]
                )

                expect(response).to redirect_to(top_tracks_path)
                expect(flash[:notice]).to eq("Playlist created on Spotify: Your Top Tracks - Last 6 Months")
            end

            context "when top_tracks returns empty" do
                before { allow(spotify_client).to receive(:top_tracks).and_return([]) }

                it "redirects with alert about no tracks" do
                    post :create, params: { time_range: time_range }
                    expect(response).to redirect_to(top_tracks_path)
                    expect(flash[:alert]).to eq("No tracks available for Last 6 Months.")
                end
            end

            context "when SpotifyClient raises UnauthorizedError" do
                before { allow(spotify_client).to receive(:top_tracks).and_raise(SpotifyClient::UnauthorizedError) }

                it "redirects to root_path with alert" do
                    post :create, params: { time_range: time_range }
                    expect(response).to redirect_to(root_path)
                    expect(flash[:alert]).to eq("Session expired. Please sign in with Spotify again.")
                end
            end

            context "when SpotifyClient raises generic Error" do
                before { allow(spotify_client).to receive(:top_tracks).and_raise(SpotifyClient::Error.new("Something broke")) }

                it "redirects to top_tracks_path with alert" do
                    post :create, params: { time_range: time_range }
                    expect(response).to redirect_to(top_tracks_path)
                    expect(flash[:alert]).to eq("Couldn't create playlist on Spotify.")
                end
            end
        end
    end

    describe "POST #create_from_recommendations" do
        let(:uris) { ["spotify:track:1", "spotify:track:2"] }

        context "when user is not logged in" do
            before { session.delete(:spotify_user) }

            it "redirects to root with alert" do
                post :create_from_recommendations, params: { uris: uris }
                expect(response).to redirect_to(root_path)
                expect(flash[:alert]).to eq("Please sign in with Spotify first.")
            end
        end

        context "when no uris provided" do
            it "redirects back with no tracks alert" do
                post :create_from_recommendations, params: { uris: [] }
                expect(response).to redirect_to(recommendations_path)
                expect(flash[:alert]).to eq("No tracks to add to playlist.")
            end
        end

        context "when spotify creates playlist successfully" do
            before do
                allow(spotify_client).to receive(:current_user_id).and_return("user123")
                allow(spotify_client).to receive(:create_playlist_for).and_return("playlist_abc")
                allow(spotify_client).to receive(:add_tracks_to_playlist).and_return(true)
            end

            it "creates playlist and redirects with notice" do
                post :create_from_recommendations, params: { uris: uris, playlist_name: "My Recs" }

                expect(spotify_client).to have_received(:create_playlist_for).with(
                    user_id: "user123",
                    name: "My Recs",
                    description: "Auto-created from Spotilytics • Your Recommendations",
                    public: false
                )

                expect(spotify_client).to have_received(:add_tracks_to_playlist).with(
                    playlist_id: "playlist_abc",
                    uris: uris
                )

                expect(response).to redirect_to(recommendations_path)
                expect(flash[:notice]).to eq("Playlist created on Spotify: My Recs")
            end
        end

        context "when spotify raises unauthorized" do
            before do
                allow(spotify_client).to receive(:current_user_id).and_return("user123")
                allow(spotify_client).to receive(:create_playlist_for).and_raise(SpotifyClient::UnauthorizedError)
            end

            it "redirects to root with alert" do
                post :create_from_recommendations, params: { uris: uris }
                expect(response).to redirect_to(root_path)
                expect(flash[:alert]).to eq("Session expired. Please sign in with Spotify again.")
            end
        end

        context "when spotify raises generic error" do
            before do
                allow(spotify_client).to receive(:current_user_id).and_return("user123")
                allow(spotify_client).to receive(:create_playlist_for).and_raise(SpotifyClient::Error.new("boom"))
            end

            it "redirects back with error message" do
                post :create_from_recommendations, params: { uris: uris }
                expect(response).to redirect_to(recommendations_path)
                expect(flash[:alert]).to eq("Couldn't create playlist on Spotify: boom")
            end
        end
    end
end