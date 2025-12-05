Feature: Create a Spotify playlist from recommendations
  As a logged-in Spotify user
  I want to save recommended tracks to a playlist
  So I can listen to them later

  Scenario: Not logged in redirects home
    When I POST create_playlist_from_recommendations with name "Any Playlist" and uris:
      | spotify:track:1 |
    Then I should be on the home page
    And I should see "Please sign in with Spotify first."

  Scenario: No URIs provided shows an alert
    Given I am logged in for playlists
    When I POST create_playlist_from_recommendations without uris
    Then I should be on the recommendations page
    And I should see "No tracks to add to playlist."

  Scenario: Successful creation with session user id
    Given I am logged in for playlists with user id "user_123"
    And Spotify creates playlist "My Rec Mix" and adds tracks
    When I POST create_playlist_from_recommendations with name "My Rec Mix" and uris:
      | spotify:track:1 |
      | spotify:track:2 |
    Then I should be on the recommendations page
    And I should see "Playlist created on Spotify: My Rec Mix"

  Scenario: Successful creation with missing session user id
    Given I am logged in for playlists without user id
    And Spotify API returns user id "fetched_rec_user"
    And Spotify creates playlist "Rec Mix 2" and adds tracks
    When I POST create_playlist_from_recommendations with name "Rec Mix 2" and uris:
      | spotify:track:3 |
    Then I should be on the recommendations page
    And I should see "Playlist created on Spotify: Rec Mix 2"

  Scenario: Spotify unauthorized during recommendations playlist creation
    Given I am logged in for playlists
    And Spotify raises Unauthorized on any call
    When I POST create_playlist_from_recommendations with name "Unauthorized Mix" and uris:
      | spotify:track:99 |
    Then I should be on the home page
    And I should see "Session expired. Please sign in with Spotify again."

  Scenario: Spotify generic error when creating recommendations playlist
    Given I am logged in for playlists
    And Spotify raises Error on any call
    When I POST create_playlist_from_recommendations with name "Broken Mix" and uris:
      | spotify:track:77 |
    Then I should be on the recommendations page
    And I should see "Couldn't create playlist on Spotify: rate limited"
