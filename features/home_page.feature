Feature: Home Page
  As a visitor to the app
  I want to see a clear and informative home page that explains the app’s purpose and lists the contributors
  so that I can understand what the app does and who built it before signing up or logging in

  Background:
    Given OmniAuth is in test mode

  Scenario: Successful Home Page Access
    Given I am on the home page
    And I should see "Spotilytics"
    And I should see "Discover Your Sound"
    And I should see "Aurora Jitrskul"
    And I should see "Aditya Vellampalli"
    And I should see "Spoorthy Raghavendra"
    And I should see "Pablo Pineda"

  Scenario: I want to login from the home page
    Given I am on the home page
    Then I should see "Get Started Now"
    When I click "Get Started Now"
    Then I should be on the home page
    And I should see "Signed in with Spotify"
    And I should see "Test User"
    And I should see "Log out"

  Scenario: I want to go to my dashboard form the home page
    Given I am signed in with Spotify
    And the dashboard API is available
    Then I should see "My Dashboard"
    When I click "My Dashboard"
    Then I should be on the dashboard page
