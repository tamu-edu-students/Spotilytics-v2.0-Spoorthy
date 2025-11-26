require "rails_helper"

RSpec.describe RecommendationsController, type: :controller do
    shared_context "logged in user" do
        let(:session_user) do
            {
            "display_name" => "Test Listener",
            "email"        => "listener@example.com",
            "image"        => "http://example.com/user.jpg"
            }
        end

        before do
            session[:spotify_user] = session_user
            session[:spotify_token] = "valid_token"
        end
    end

    describe "Get #recommendations" do
        include_context "logged in user"

        context "when SpotifyClient returns recommendations successfully" do
            render_views

            let(:mock_tracks) do
                [
                OpenStruct.new(
                    id: 1,
                    name: "Track One",
                    artists: "Artist One",
                    album_name: "Album One",
                    album_image_url: "http://img/one.jpg",
                    popularity: 90,
                    preview_url: "https://preview2.com",
                    spotify_url: "https://spotify.com",
                    duration_ms: 60
                ),
                OpenStruct.new(
                    id: 2,
                    name: "Track Two",
                    artists: "Artist Two",
                    album_name: "Album Two",
                    album_image_url: "http://img/two.jpg",
                    popularity: 80,
                    preview_url: "https://preview2.com",
                    spotify_url: "https://spotify.com",
                    duration_ms: 60
                )
                ]
            end

            before do
                mock_client = instance_double(SpotifyClient)

                allow(SpotifyClient).to receive(:new)
                    .with(session: anything)
                    .and_return(mock_client)

                # Recommendations built using top tracks
                allow(mock_client).to receive(:top_tracks)
                .with(limit: 20, time_range: "medium_term")
                .and_return([])

                # Recommendations also fetches top artists
                allow(mock_client).to receive(:top_artists).with(limit: 20, time_range: "medium_term").and_return([])

                allow(mock_client).to receive(:search_tracks)
                    .with("", limit: 15)
                    .and_return(mock_tracks)
            end

            it "correctly assigns tracks to @recommendations" do
                get :recommendations

                expect(assigns(:recommendations)).to eq(mock_tracks)
                expect(response).to have_http_status(:ok)
            end
        end

        context "when recommendations page raises UnauthorizedError while fetching recommendations" do
            before do
                mock_client = instance_double(SpotifyClient)

                allow(SpotifyClient).to receive(:new)
                    .with(session: anything)
                    .and_return(mock_client)

                allow(SpotifyClient).to receive(:new)
                .with(session: anything)
                .and_return(mock_client)

                # Recommendations built using top tracks
                allow(mock_client).to receive(:top_tracks)
                .with(limit: 20, time_range: "medium_term")
                .and_return([])

                # Recommendations also fetches top artists
                allow(mock_client).to receive(:top_artists).with(limit: 20, time_range: "medium_term").and_return([])

                allow(mock_client).to receive(:search_tracks)
                    .with("", limit: 15)
                    .and_raise(SpotifyClient::UnauthorizedError.new("expired token"))
            end

            it "redirects to home with re-auth alert" do
                get :recommendations

                expect(response).to redirect_to(home_path)
                expect(flash[:alert]).to eq(
                'You must log in with spotify to view your recommendations.'
                )
            end
        end

        context "when SpotifyClient raises a generic error while fetching recommendations" do
            before do
                mock_client = instance_double(SpotifyClient)

                allow(SpotifyClient).to receive(:new)
                    .with(session: anything)
                    .and_return(mock_client)

                allow(SpotifyClient).to receive(:new)
                .with(session: anything)
                .and_return(mock_client)

                # Recommendations built using top tracks
                allow(mock_client).to receive(:top_tracks)
                .with(limit: 20, time_range: "medium_term")
                .and_return([])

                # Recommendations also fetches top artists
                allow(mock_client).to receive(:top_artists).with(limit: 20, time_range: "medium_term").and_return([])

                allow(mock_client).to receive(:search_tracks)
                    .with("", limit: 15)
                    .and_raise(SpotifyClient::Error.new("rate limited"))
            end

            it "renders 200, sets flash alert and assigns empty recommendations values" do
                get :recommendations

                expect(assigns(:recommendations)).to eq([])
                expect(flash.now[:alert]).to eq(
                "Failed to fetch recommendations: rate limited"
                )
                expect(response).to have_http_status(:ok)
            end
        end
    end
end
