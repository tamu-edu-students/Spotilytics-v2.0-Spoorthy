Feature: Hide and Unhide Top Tracks
  As a Spotify user
  I want to hide and unhide tracks from my top tracks lists
  So I can customize what I see on my dashboard

  Background:
    Given I am logged in with Spotify
    And I am on the top tracks page

  Scenario: Hide a track from the short term list
    When I hide the track "track_123" from the "short_term" list
    Then I should see top tracks message "Track hidden from short term list."
    And the track "track_123" should be hidden from my short term list

  Scenario: Unhide a previously hidden track
    Given the track "track_123" is hidden from my short term list
    When I unhide the track "track_123" from the "short_term" list
    Then I should see top tracks message "Track restored to short term list."
    And the track "track_123" should not be hidden from my short term list

  Scenario: Hide more than 5 tracks in a list
    Given I have already hidden 5 tracks from my short term list
    When I hide the track "track_999" from the "short_term" list
    Then I should see top tracks alert "Could not hide track — you can hide at most 5 tracks per list."

  Scenario: Hide a track with an invalid time range
    When I hide the track "track_123" from the "invalid" list
    Then I should see top tracks message "Invalid time range."

