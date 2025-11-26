RSpec.describe "Dashboard Page Request", type: :request do
    describe "Dashboard" do
        it "correctly redirects when the user is not logged in" do
            get dashboard_path
            expect(response).to redirect_to(root_path)
        end
        it "correctly has a popup on home page when the user is not logged in" do
            get dashboard_path
            follow_redirect!
            expect(response.body).to include("Please sign in with Spotify first.")
        end
    end
end
