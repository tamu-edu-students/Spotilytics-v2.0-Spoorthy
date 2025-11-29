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
        let(:uris) { [ "spotify:track:1", "spotify:track:2" ] }

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

    describe "GET #new" do
        context "when user is not logged in" do
            before { session.delete(:spotify_user) }

            it "redirects to root with alert" do
                get :new
                expect(response).to redirect_to(root_path)
                expect(flash[:alert]).to eq("Please sign in with Spotify first.")
            end
        end

        context "when user is logged in" do
            it "loads builder state from params" do
                get :new, params: { tracks: [ { id: "t1", name: "Song 1", artists: "Artist A" } ], playlist_name: "My List" }
                expect(assigns(:builder_tracks)).to be_an(Array)
                expect(assigns(:builder_tracks).size).to eq(1)
                expect(assigns(:playlist_name)).to eq("My List")
            end
        end
    end

    describe "POST #add_song" do
        context "when removing a track" do
            it "removes the track and renders new with notice" do
                post :add_song, params: { tracks: [ { id: "t1", name: "Song 1", artists: "Artist A" } ], remove_track_id: "t1" }
                expect(response).to render_template(:new)
                expect(assigns(:builder_tracks)).to eq([])
                expect(flash[:notice]).to eq("Removed song from list.")
            end
        end

        context "when uploading CSV but no file provided" do
            it "renders new with alert and unprocessable_entity" do
                post :add_song, params: { file_add: '1' }
                expect(response).to have_http_status(:unprocessable_entity)
                expect(flash[:alert]).to eq("Choose a CSV file with columns like title, artist.")
            end
        end

        context "when bulk add has no titles" do
            it "renders new with alert and unprocessable_entity" do
                post :add_song, params: { bulk_add: '1', bulk_songs: '' }
                expect(response).to have_http_status(:unprocessable_entity)
                expect(flash[:alert]).to eq("Enter at least one song title.")
            end
        end

        context "when single add but query blank" do
            it "renders new with alert and unprocessable_entity" do
                post :add_song, params: { single_add: '1', song_query: '' }
                expect(response).to have_http_status(:unprocessable_entity)
                expect(flash[:alert]).to eq("Enter a song name to search and add.")
            end
        end

        context "when single add succeeds" do
            let(:found_track) { double("Track", id: "t100", name: "Found Song", artists: "Artist Z") }

            before do
                allow(spotify_client).to receive(:search_tracks).and_return([ found_track ])
            end

            it "adds the track to builder and renders new with notice" do
                post :add_song, params: { song_query: 'Found Song' }
                expect(response).to render_template(:new)
                expect(flash[:notice]).to eq("Added Found Song by Artist Z.")
                expect(assigns(:builder_tracks).any? { |t| t[:id] == 't100' }).to be true
            end
        end

        context "when uploading CSV with mixed results" do
            let(:csv_text) { "title,artist\nSong A,Artist A\nSong Missing,Artist X\nSong A,Artist A\n" }
            let(:track1) { double("Track", id: "tA", name: "Track One", artists: "Artist A") }

            before do
                allow(spotify_client).to receive(:search_tracks).and_return([ track1 ], [], [ track1 ])
            end

            it "adds found songs, reports duplicates and not found, and renders new" do
                upload = StringIO.new(csv_text)
                allow(controller).to receive(:params).and_return(ActionController::Parameters.new({ 'file_add' => '1', 'tracks_csv' => upload }))

                post :add_song

                expect(response).to render_template(:new)
                expect(flash[:notice]).to include("Added 1 song")
                expect(flash[:notice]).to include("Skipped duplicates: Track One")
                expect(flash[:alert]).to include(%q(track:"Song Missing" artist:"Artist X"))
            end
        end

        context "when bulk add has mixed results and duplicates" do
            let(:existing) { { id: "dup1", name: "Song D", artists: "Artist D" } }
            let(:track_hit) { double("Track", id: "t_hit", name: "Hit Song", artists: "Artist H") }
            let(:track_dup) { double("Track", id: "dup1", name: "Song D", artists: "Artist D") }

            before do
                allow(spotify_client).to receive(:search_tracks).and_return([ track_hit ], [], [ track_dup ])
            end

            it "reports added, duplicates, and no matches appropriately" do
                post :add_song, params: { bulk_add: '1', bulk_songs: 'Hit A, Unknown, Duplicate', tracks: [ existing ] }
                expect(response).to render_template(:new)
                expect(flash[:notice]).to include("Added 1 song")
                expect(flash[:notice]).to include("Skipped duplicates: Song D")
                expect(flash[:alert]).to include("No matches for: Unknown")
            end
        end

        context "when no buttons and no query provided" do
            it "renders new with unprocessable_entity and asks to choose a song" do
                post :add_song, params: {}
                expect(response).to have_http_status(:unprocessable_entity)
                expect(flash[:alert]).to eq("Choose a song to add.")
            end
        end

        context "when spotify raises unauthorized during search" do
            before do
                allow(spotify_client).to receive(:search_tracks).and_raise(SpotifyClient::UnauthorizedError)
            end

            it "redirects to root with alert" do
                post :add_song, params: { song_query: 'x' }
                expect(response).to redirect_to(root_path)
                expect(flash[:alert]).to eq("Session expired. Please sign in with Spotify again.")
            end
        end

        context "when spotify raises generic error during search" do
            before do
                allow(spotify_client).to receive(:search_tracks).and_raise(SpotifyClient::Error.new("whoops"))
            end

            it "renders new with unprocessable_entity and alert" do
                post :add_song, params: { song_query: 'x' }
                expect(response).to have_http_status(:unprocessable_entity)
                expect(flash[:alert]).to eq("Couldn't search Spotify: whoops")
            end
        end
    end

    describe "POST #create_custom" do
        context "when no tracks in builder" do
            it "renders new with unprocessable_entity and alert" do
                post :create_custom, params: { tracks: [] }
                expect(response).to have_http_status(:unprocessable_entity)
                expect(flash[:alert]).to eq("Add at least one song before creating your playlist.")
            end
        end

        context "when creating custom playlist succeeds" do
            before do
                allow(spotify_client).to receive(:create_playlist_for).and_return("pl_1")
                allow(spotify_client).to receive(:add_tracks_to_playlist)
                allow(spotify_client).to receive(:current_user_id).and_return("user123")
            end

            it "creates playlist and redirects with notice" do
                post :create_custom, params: { tracks: [ { id: "t1", name: "Song 1", artists: "Artist A" } ], playlist_name: "Custom" }
                expect(spotify_client).to have_received(:create_playlist_for)
                expect(spotify_client).to have_received(:add_tracks_to_playlist)
                expect(response).to redirect_to(new_playlist_path)
                expect(flash[:notice]).to eq("Playlist created on Spotify: Custom")
            end
        end

        context "when spotify unauthorized during create_custom" do
            before do
                allow(spotify_client).to receive(:create_playlist_for).and_raise(SpotifyClient::UnauthorizedError)
                allow(spotify_client).to receive(:current_user_id).and_return("user123")
            end

            it "redirects to root with alert" do
                post :create_custom, params: { tracks: [ { id: "t1", name: "Song 1", artists: "Artist A" } ], playlist_name: "Custom" }
                expect(response).to redirect_to(root_path)
                expect(flash[:alert]).to eq("Session expired. Please sign in with Spotify again.")
            end
        end

        context "when spotify generic error during create_custom" do
            before do
                allow(spotify_client).to receive(:create_playlist_for).and_raise(SpotifyClient::Error.new("nope"))
                allow(spotify_client).to receive(:current_user_id).and_return("user123")
            end

            it "renders new with unprocessable_entity and shows error message" do
                post :create_custom, params: { tracks: [ { id: "t1", name: "Song 1", artists: "Artist A" } ], playlist_name: "Custom" }
                expect(response).to have_http_status(:unprocessable_entity)
                expect(flash[:alert]).to eq("Couldn't create playlist on Spotify: nope")
            end
        end
    end
end
