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
