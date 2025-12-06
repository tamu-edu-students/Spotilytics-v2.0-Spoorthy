Feature: Library page
  As a Spotify user
  I want to browse my playlists
  So I can view everything in my library

  Background:
    Given OmniAuth is in test mode

  Scenario: Viewing playlists in the library
    Given Spotify playlists API returns the following playlists:
      | name        | owner | tracks_total |
      | Morning Mix | Me    | 20           |
      | Workout     | Me    | 15           |
    And I am signed in with Spotify
    When I visit "/library"
    Then I should see "Your Library"
    And I should see "Morning Mix"
    And I should see "Workout"

  Scenario: Handling an error from Spotify playlists API
    Given Spotify playlists API returns an error
    And I am signed in with Spotify
    When I visit "/library"
    Then I should see "We were unable to load your playlists from Spotify. Please try again later."

  Scenario: Updating my playlist description
    Given Spotify playlists API returns the following playlists:
      | id  | name    | owner_id        | owner | tracks_total | public | description     |
      | pl4 | Chill V | spotify-uid-123 | Me    | 12           | true   | Old description |
    And Spotify playlist description API succeeds for "pl4"
    And I am signed in with Spotify
    When I visit "/library"
    And I fill in "description" with "New vibes for studying"
    And I click "Save description"
    Then I should see "Playlist description updated."

  Scenario: Toggling playlist collaboration
    Given Spotify playlists API returns the following playlists:
      | id  | name    | owner_id        | owner | tracks_total | public | description | collaborative |
      | pl5 | Collab1 | spotify-uid-123 | Me    | 8            | false  | Study set   | false         |
    And Spotify playlist collaboration API succeeds for "pl5"
    And I am signed in with Spotify
    When I visit "/library"
    And I click "Enable collaboration"
    Then I should see "Collaboration enabled."
