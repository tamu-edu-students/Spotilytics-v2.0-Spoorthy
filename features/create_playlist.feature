Feature: Build a custom playlist
  As a logged-in Spotify user
  I want to add songs in different ways and build a playlist
  So I can save it to my Spotify account

  Background:
    Given I am signed in with Spotify

  Scenario: Add a single song and create the playlist
    And Spotify search returns track "Yellow" by "Coldplay" with id "t_yellow"
    And Spotify creates playlist "My Custom List" and adds tracks
    When I visit the create playlist page
    And I fill in "Playlist name" with "My Custom List"
    And I fill in "Add a song" with "Yellow"
    And I click "Add song"
    Then I should see "Yellow"
    And I should see "Coldplay"
    When I click "Create playlist"
    Then I should see "Playlist created on Spotify: My Custom List"

  Scenario: Upload a CSV of songs to add them to the list
    And Spotify search returns tracks:
      | query     | name       | artists    | id    |
      | Track One | Track One  | Artist One | t1    |
      | Track Two | Track Two  | Artist Two | t2    |
    When I visit the create playlist page
    And I upload the CSV file "features/fixtures/create_playlist_tracks.csv"
    And I click "Upload CSV"
    Then I should see "Track One"
    And I should see "Track Two"

  Scenario: Bulk add requires at least one title
    When I visit the create playlist page
    And I click "Add songs"
    Then I should see "Enter at least one song title."

  Scenario: Bulk add with duplicate and missing songs
    And Spotify search returns tracks:
      | query  | name  | artists | id  |
      | Hello  | Hello | Adele   | t10 |
    When I visit the create playlist page
    And I fill in "Add multiple songs" with "Hello, Unknown Song, Hello"
    And I click "Add songs"
    Then I should see "Added 1 song."
    And I should see "Skipped duplicates: Hello."
    And I should see "No matches for: Unknown Song."

  Scenario: Single add requires a query
    When I visit the create playlist page
    And I click "Add song"
    Then I should see "Enter a song name to search and add."

  Scenario: Single add with no match
    And Spotify search returns no results
    When I visit the create playlist page
    And I fill in "Add a song" with "NoMatchTrack"
    And I click "Add song"
    Then I should see "No songs found for \"NoMatchTrack\"."

  Scenario: Remove a song from the list
    And Spotify search returns track "Yellow" by "Coldplay" with id "t_yellow"
    When I visit the create playlist page
    And I fill in "Add a song" with "Yellow"
    And I click "Add song"
    Then I should see "Yellow"
    When I click "Remove"
    Then I should not see "Yellow"

  Scenario: CSV upload requires a file
    When I visit the create playlist page
    And I click "Upload CSV"
    Then I should see "Choose a CSV file with columns like title, artist."

  Scenario: CSV upload handles malformed file
    When I visit the create playlist page
    And I upload the CSV file "features/fixtures/create_playlist_malformed.csv"
    And I click "Upload CSV"
    Then I should see "Could not read that CSV file. Please check the formatting."

  Scenario: CSV upload with duplicates and missing songs
    And Spotify search returns tracks:
      | query     | name       | artists    | id    |
      | Track One | Track One  | Artist One | t1    |
    And Spotify search returns no results for "Unknown Track"
    When I visit the create playlist page
    And I upload the CSV file "features/fixtures/create_playlist_mixed.csv"
    And I click "Upload CSV"
    Then I should see "Added 1 song."
    And I should see "Skipped duplicates: Track One."
    And I should see "No matches for: track:\"Unknown Track\" artist:\"Unknown Artist\"."
