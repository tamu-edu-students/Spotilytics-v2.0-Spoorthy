require 'rails_helper'
require 'ostruct'

RSpec.describe ApplicationController, type: :controller do
  # Define an anonymous controller that inherits from ApplicationController
  # This allows us to test the methods in isolation without needing a real route.
  controller do
    # We add a before_action to test the auth barrier
    before_action :require_spotify_auth!, only: [:protected_action]

    # A public action to test helper methods
    def public_action
      render plain: "Current User: #{current_user.try(:display_name)}, Logged In: #{logged_in?}"
    end

    # A protected action to test require_spotify_auth!
    def protected_action
      render plain: "You are authorized!"
    end
  end

  # We need to draw custom routes for this anonymous controller to work
  before do
    routes.draw do
      get 'public_action' => 'anonymous#public_action'
      get 'protected_action' => 'anonymous#protected_action'
    end
  end

  describe "#current_user" do
    context "when session[:spotify_user] is missing" do
      it "returns nil" do
        get :public_action
        # Access the controller instance to check the helper method directly
        expect(controller.current_user).to be_nil
      end
    end

    context "when session[:spotify_user] is present" do
      let(:user_data) { { "display_name" => "RSpec User", "id" => "123" } }

      before do
        session[:spotify_user] = user_data
      end

      it "returns an OpenStruct with the user data" do
        get :public_action
        user = controller.current_user
        
        expect(user).to be_an(OpenStruct)
        expect(user.display_name).to eq("RSpec User")
      end

      it "memoizes the result (returns the exact same object instance)" do
        get :public_action
        first_call = controller.current_user
        second_call = controller.current_user
        
        # Ensure object_id is the same, meaning it didn't recreate the OpenStruct
        expect(first_call.object_id).to eq(second_call.object_id)
      end
    end
  end

  describe "#logged_in?" do
    context "when user is not in session" do
      it "returns false" do
        get :public_action
        expect(controller.logged_in?).to be false
      end
    end

    context "when user is in session" do
      before do
        session[:spotify_user] = { "id" => "1" }
      end

      it "returns true" do
        get :public_action
        expect(controller.logged_in?).to be true
      end
    end
  end

  describe "#require_spotify_auth!" do
    context "when session token is missing" do
      it "redirects to root path with an alert" do
        get :protected_action
        
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please sign in with Spotify first.")
      end
    end

    context "when session token is present" do
      before do
        session[:spotify_token] = "valid_token"
      end

      it "allows the action to proceed" do
        get :protected_action
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("You are authorized!")
      end
    end
  end
end
