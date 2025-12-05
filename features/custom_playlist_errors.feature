Feature: Custom Playlist Error Handling
  As a logged-in Spotify user
  I want to be notified if something goes wrong when building a custom playlist
  So that I know why my action failed

  Background:
    Given I am signed in with Spotify

  Scenario: Create custom playlist raises Unauthorized error
    Given I have added a song to the custom playlist builder
    And Spotify API raises an unauthorized error during custom playlist creation
    When I click "Create playlist"
    Then I should be on the home page
    And I should see "Session expired. Please sign in with Spotify again."

  Scenario: Create custom playlist raises Generic error
    Given I have added a song to the custom playlist builder
    And Spotify API raises an error "Creation Failed" during custom playlist creation
    When I click "Create playlist"
    Then I should see "Couldn't create playlist on Spotify: Creation Failed"

  Scenario: Add song raises Unauthorized error
    When I visit the create playlist page
    And Spotify API raises an unauthorized error during track search
    And I fill in "Add a song" with "Error Track"
    And I click "Add song"
    Then I should be on the home page
    And I should see "Session expired. Please sign in with Spotify again."

  Scenario: Add song raises Generic error
    When I visit the create playlist page
    And Spotify API raises an error "Search Failed" during track search
    And I fill in "Add a song" with "Error Track"
    And I click "Add song"
    Then I should see "Couldn't search Spotify: Search Failed"

  Scenario: Add song with no input
    When I visit the create playlist page
    And I click "Add song"
    Then I should see "Enter a song name to search and add."

  Scenario: Create custom playlist with empty list
    When I POST create_custom_playlist with an empty list
    Then I should see "Add at least one song before creating your playlist."

  Scenario: Create custom playlist with missing session user ID
    Given I am logged in for playlists without user id
    And I have added a song to the custom playlist builder
    And Spotify API returns user id "fetched_user_id"
    And Spotify creates playlist "My Custom List" and adds tracks
    When I fill in "Playlist name" with "My Custom List"
    And I click "Create playlist"
    Then I should see "Playlist created on Spotify: My Custom List"
