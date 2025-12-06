# 🎧 Spotilytics v2.0

Spotilytics v2.0 is a Ruby on Rails web application that uses Spotify OAuth 2.0 (omniauth / rspotify) to authenticate users and fetch live data from the Spotify Web API. It delivers a personalized, on-demand “Spotify Wrapped” experience — Top Tracks and Top Artists across multiple time ranges, interactive genre analytics, personalized recommendations, and follow/unfollow management that syncs directly to the user’s Spotify account. It also allows custom playlist creation from top tracks and CSV imports. It has also been integrated with user's top podcasts and saved shows and provides AI generated summaries and search.

---

## Useful URLs

- **Heroku Dashboard:** [https://spotilytics-version2-c80381d23acb.herokuapp.com/home](https://spotilytics-version2-c80381d23acb.herokuapp.com/home)
- **GitHub Projects Dashboard:** [https://github.com/orgs/tamu-edu-students/projects/176](https://github.com/orgs/tamu-edu-students/projects/176)
- **Slack Group** (to track Scrum Events) - #606-project3-team1 - [https://tamu.slack.com/archives/C09RYTFDDFX](https://tamu.slack.com/archives/C09RYTFDDFX)
- **Spotify Developer Dashboard:** [https://developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
- **User Stories List:** [https://docs.google.com/document/d/1jVv2fd3zgR0hf0M2sIa5QTSD2Ow-P9SO1jITTCoR7os/edit?pli=1&tab=t.0](https://docs.google.com/document/d/1jVv2fd3zgR0hf0M2sIa5QTSD2Ow-P9SO1jITTCoR7os/edit?pli=1&tab=t.0)
- **Sprint Meeting Notes:** [https://docs.google.com/document/d/1HktE-eT2kkafAEvjenOyCFEh3vEZeHGoUPehkiv7BvY/edit?usp=sharing](https://docs.google.com/document/d/1HktE-eT2kkafAEvjenOyCFEh3vEZeHGoUPehkiv7BvY/edit?usp=sharing)

## New Features in Spotilytics v2.0
1. Recommendations Tab:
    - Personalized track and album recommendations based on your listening history
    - Create playlists from your recommended songs
2. Custom Playist Creation:
    - Import your top tracks into a new Spotify playlist with a single click
    - Upload a CSV file of song and artist data to create a playlist
    - Add songs individually or add a list of songs
    - Review the playlist before saving it to your Spotify account
3. Customize your Dashboard:
    - Hide or show specific songs on your Top Tracks list
    - Hide tracks you don’t want to see on your Spotilytics dashboard
4. Podcast and Saved Shows Integration:
    - View your top podcasts and saved shows alongside music data
    - Get AI-generated summaries of your favorite podcasts
5. Search Functionality:
    - Search your top tracks, artists, and podcasts directly within the app
    - Quickly find specific songs or artists from your listening history
    

## Getting Started — From Zero to Deployed

Follow these steps to take Spotilytics from a fresh clone to a deployed, working application on Heroku.

### 1️⃣ Prerequisites

Make sure you have the following installed:

| Tool | Install Command |
|------|------------------|
| Ruby | `rbenv install 3.x.x` |
| Bundler | `gem install bundler` |
| Git | `sudo apt install git` |
| Heroku CLI | [Install guide](https://devcenter.heroku.com/articles/heroku-cli) |

---

### 2️⃣ Clone the Repository

```bash
git clone https://github.com/tamu-edu-students/Spotilytics-v2.0.git
cd Spotilytics-v2.0
```

---

### 3️⃣ Install Dependencies

```bash
bundle install
```

--- 

### 4️⃣ Spotify Developer Setup

To access your spotify data, you must have a Spotify account and create a Spotify Developer App to get your Client ID and Client Secret.
1.	Go to the Spotify Developer Dashboard : https://developer.spotify.com/dashboard
2.	Click on "Create App"
3.  Fill in the App name and description
4.	Under Redirect URIs, add:
    1. https://localhost:3000/auth/spotify/callback
    2. http://127.0.0.1:3000/auth/spotify/callback
    3. https://spotilytics-version2-c80381d23acb.herokuapp.com/auth/spotify/callback (for production)
5. Select the "Web API" option.
6. Accept the terms and Click "Save"
7. In User Management add your Name and Spotify mail ID. If you need to add more users for testing, add their Spotify mail IDs here as well.
--- 

### 5️⃣ Environment Configuration

Create a .env file in the project root to store your credentials:
```bash
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
```
Do not commit .env files to Git

--- 

### 6️⃣ Run Locally

```bash
rails server
```

Visit: http://127.0.0.1:3000

You can log in using your Spotify mail ID with which you created the app or added in User Management:
1. Click Log in with Spotify
2. Approve permissions
3. You’ll be redirected to the Home Page where you can see different tabs

--- 

### 7️⃣ Run the Test Suite

#### This project uses both RSpec (for unit testing) and Cucumber (for feature/BDD testing)

**RSpec (unit & request tests):**

```bash
bundle exec rspec
```

**Cucumber (feature tests):**

```bash
bundle exec cucumber
```

**View Coverage Report (Coverage is generated after test runs):**

```bash
open coverage/index.html
```

---

### 8️⃣ Setup Heroku Deployment (CD)

#### Step 1: Create a Heroku App

```bash
heroku login
heroku create <your-app-name>  # in this case 'heroku create spotilytics-version2'
```

#### Step 2: Set GitHub Secrets/ Heroku Secrets

In **GitHub** → **Settings → Secrets and Variables → Actions**, add the following secrets in Repository Secrets section:

| Secret | Description |
|--------|--------------|
| `HEROKU_API_KEY` | Your Heroku API key (run `heroku auth:token` to get it) |
| `HEROKU_APP_NAME` | Your Heroku app name (spotilytics in this case) |
| `SPOTIFY_CLIENT_ID` | Your Spotify Client ID |
| `SPOTIFY_CLIENT_SECRET` | Your Spotify Client Secret |

#### Step 3: To manually deploy using the Heroku CLI if you’re not using GitHub Actions:
```bash
git push heroku main
heroku open
```

### Step 4: Access the App

Once deployed, visit your live Heroku URL (for example):
https://spotilytics-version2-demo.herokuapp.com/home

### Step 5: Update user management in Spotify Developer Dashboard to add new users for testing.
On the Spotify Developer Dashboard, navigate to your app, then go to "User Management" and add the Spotify email IDs of users you want to authorize for testing. These users will then be able to log in to the Spotilytics app using their Spotify accounts.


You’ll be able to:
1. Log in with Spotify
2. View your top artists and tracks by timeframe
3. Explore your genre breakdowns
4. Generate playlists from your top songs
5. Access recommendations based on your listening history
6. Create custom playlists or import songs
7. View your top podcasts and saved shows with AI summaries

## Useful Commands

| **Task**     | **Command** |
|----------------|------------------|
| **start server**  | `rails server` |
| **run rspec tests**    | `bundle exec rspec` |
| **run single RSpec test**    | `bundle exec rspec spec/controllers/playlist_controller_spec.rb` |
| **run cucumber tests**    | `bundle exec cucumber` |
| **run single Cucumber scenario**    | `bundle exec cucumber features/top_tracks.feature` |
| **check test coverage**       | `open coverage/index.html` |
| **check last few lines of error log messages from Heroku**       | `heroku logs` |

# User Guide — Spotilytics

Welcome to Spotilytics, your personalized Spotify analytics dashboard!
Spotilytics lets you view your listening history, top artists, top tracks, and genres anytime - like having Spotify Wrapped on demand.

---

### Getting Started

1. **Access the App**  
   Visit your deployed app [https://spotilytics-version2-c80381d23acb.herokuapp.com/home](https://spotilytics-version2-c80381d23acb.herokuapp.com/home)

   Requirements
	- A Spotify account (Free or Premium)
    - Access to the Spotilytics app (added as a tester in the Spotify Developer Dashboard)
	- Internet connection and a browser
	- Permission to connect Spotilytics to your Spotify account

2. **Logging In with Spotify**
	1.	Visit the Spotilytics home page.
	2.	Click “Log in with Spotify”.
	3.	You’ll be redirected to Spotify’s secure authorization page.
	4.	Click “Agree” to give Spotilytics access to:
	    - Your top tracks and artists
	    - Permission to create playlists on your behalf
	5.	You’ll be redirected back to the Home Page once authentication succeeds.

    Spotilytics uses Spotify OAuth 2.0, so:
    - Your credentials are never stored by us.
    - Only temporary tokens are used per session.
    - Tokens automatically expire for security.

3. **Home Page Overview**

    After logging in, you’ll see the Home Page featuring:
        - The Spotilytics logo and Spotify branding
        - A short description of what the app does
        - A “My Dashboard” button that takes you to your personalized analytics
        This page acts as your entry point to explore your listening statistics.

4. **Dashboard Overview**

    Your dashboard provides a snapshot of your listening habits.
    It’s divided into four main sections:

    *Top Tracks This Year*
    - Displays your most-listened-to songs over the past year.
    - Shows the top 5 tracks with:
        - Rank number
        - Track name and artist
        - Album name and popularity (out of 100)

    *Top Artists This Year*
    - Displays your most-played artists this year.
    - Shows:
        - Rank and artist photo
        - Total plays count
        - Includes a “View Top Artists” button to explore more.

    *Top Genres*
    - A pie chart visualization of your most-listened-to genres.
    - The chart includes both major genres and an “Other” category for lesser-played types.

    *Followed Artists & New Releases*
    - Lists artists you follow on Spotify, with profile images and “View on Spotify” links.
    - Shows recent releases from your favorite artists, including:
        - Album art
        - Artist name
        - Track count and release date
        - Direct link to the album on Spotify

5. **Top Tracks Page**

    Navigate to Top Tracks using the navigation bar or via the dashboard.

    This page lets you view your top tracks over different time periods.

    *Time Ranges*:
    - Last 4 Weeks
    - Last 6 Months
    - Last 1 Year

    *Track Details*:

    For each time range, Spotilytics shows:
    - Song title
    - Artist name
    - Album title
    - Popularity score
    - “Play on Spotify” button

    *Adjustable Limits*:

    Use the dropdown menu under any of the time range to switch between:
    - Top 10
    - Top 25
    - Top 50

    Your results update automatically when you change the selection.

6. **Hide / Show Top Tracks**

    You can customize your Top Tracks list by hiding songs you don’t want to see. This will also remove it from your spotilytics dashboard.

    How to Hide a Track:
    1.	Click the “Hide” button next to any track in your Top Tracks list.
    2.	The track will be removed from view immediately.
    3.	To unhide, go to the “Hidden Tracks” section at the bottom of the page.
    4.	Click “Show” next to any hidden track to restore it to your main list.

    This feature helps you hide songs that you don't think represent your listening taste accurately.

7. **Top Artists Page**

    The Top Artists page provides detailed insights into your most-played artists.

    *Time Ranges*

    You can view:
    - Past Year
    - Past 6 Months
    - Past 4 Weeks

    *Artist Details*

    Each section lists:
    - Rank (1–50)
    - Artist image and name
    - Estimated play count

    Follow / Unfollow Artists
    - Next to each artist, you’ll see a Follow / Unfollow button.
    - Click to modify your followed artists directly through Spotilytics.
    - Changes reflect instantly in your Spotify account.

7. **Playlist Creation**

    You can instantly turn your top tracks into a Spotify playlist.

    How to Create a Playlist:
    1.	Go to the Top Tracks page.
    2.	Choose a time range (e.g. “Last 6 Months”).
    3.	Click the “Create Playlist” button.
    4.	Spotilytics will:
        - Generate a new playlist in your Spotify account
        - Named like “Your Top Tracks – Last 6 Months”
        - Add your top 10 songs automatically

    You can also create a custom playlist by uploading a CSV file or adding songs individually.
    How to Create a Custom Playlist:
    1. Navigate to the Playlist Creation tab.
    2. Choose to either:
        - Upload a CSV file with song and artist data
        - Add songs using a csv list
        - Add songs one by one using the search bar
    3. Review the generated playlist preview.
    4. Give your playlist a name and description.
    5. Make any final adjustments (add/remove songs).
    6. Click “Save to Spotify” to create the playlist in your account.


8. **Recommendations Page**

    The Recommendations tab generates personalized music recommendations based on your recent listening history and top artists.

    What You’ll See:
    - A curated grid of recommended tracks and albums.

    Each recommendation includes:
    - Album artwork
    - Song or album title
    - Artist name(s)
    - “Open in Spotify” button to play directly.

9. **Podcasts and Saved Shows**

    Spotilytics now integrates your top podcasts and saved shows.

    What You’ll See:
    - A list of your most-listened-to podcasts.
    - AI-generated summaries for each podcast episode.
    - Direct links to open episodes in Spotify.
    - A section for your saved shows with details and links.
    - Use AI search to find specific podcasts or episodes quickly.

---

### Tips for Best Use

- Log in regularly - Refresh your Spotify connection every few days to keep recommendations and stats up to date.
- Use “Refresh Data” button on the nav bar after major listening changes (e.g. a new playlist binge) to see updated top tracks instantly.
- Try different time ranges (4 weeks / 6 months / 1 year) to compare your short-term and long-term listening trends.
- Explore Recommendations often — they’re dynamically personalized based on your recent activity and top artists.

---

### Troubleshooting Guide

- Login issues? -> Log out, clear your browser cache, then log back in via Spotify.
- Data not updating? -> Click Refresh Data or revoke and reauthorize the app in your Spotify account settings.
- Blank dashboard or missing stats? -> Ensure your Spotify account has at least a few weeks of listening history.
- Playlist creation failing? -> Check that your Spotify session hasn’t expired — re-login to fix this instantly.

---

# Architecture Decision Records (ADRs)

## ADR 001 – Allow Individual Song Addition, Batch Addition and File Upload for Playlist Creation
**Status:** Accepted

**Context**  
Spotilytics allows users to create custom playlists from their top tracks. We needed to decide how to give users flexibility in adding songs to their playlists.

**Decision**  
They should be able to add individual songs, add multiple songs at once, or upload a CSV file containing song and artist data. A user might have a list of favorite songs they want to include, or they might want to upload a pre-prepared CSV file exported from another source.

**Consequences**  
- Advantage: Flexible user experience  
- Advantage: Supports various user workflows 
- Advantage: CSV upload simplifies bulk additions
- Downside: CSV must be correctly formatted

## ADR 002 – Reuse and Modularize Existing Spotify Client Functionality
**Status:** Accepted

**Context**  
Spotilytics v2.0 is being developed as an extension of an earlier Spotilytics application. We wanted to leverage existing code for Spotify API interactions to avoid duplication and ensure consistency. 

**Decision**  
Reuse and modularize the existing Spotify client functionality from the original Spotilytics app. This includes authentication, token management, and API request handling. We will encapsulate this logic in a dedicated service class that can be easily reused across different controllers and views.

**Consequences**  
- Advantage: Reduces code duplication  
- Advantage: Easier maintenance and updates
- Advantage: Faster development time 

## ADR 003 – Query Normalization for Cache Key Generation
**Status:** Accepted

**Context**  
Spotilytics caches Spotify API responses (e.g., top tracks, top artists) using composite cache keys that include user ID, query parameters, and time ranges.  
We observed cache misses for semantically identical queries due to differences in parameter ordering, whitespace, or casing (e.g., `limit=20&time_range=short_term` vs. `time_range=short_term&limit=20`).  
This led to redundant API calls and inconsistent cache utilization.


**Decision**  
Normalize query parameters before generating cache keys by:
- Sorting parameter keys alphabetically
- Stripping extraneous whitespace
- Converting values to a canonical format (e.g., downcasing strings)
- Serializing parameters in a stable, predictable order

**Consequences**  
- Advantage: Eliminates cache misses for equivalent queries with different parameter orderings or formatting
- Advantage: Improves cache hit rate and reduces unnecessary Spotify API calls
- Advantage: Simplifies debugging and cache invalidation
- Downside: Slight overhead in key generation logic
- Downside: Requires all cache consumers to use the normalization helper for consistency

---

# Postmortem: 

## Incident 001 – Cache Key Collisions Due to Incomplete Query Normalization

Date: 2025-18-11
Status: Closed

### Impact

Some users saw incorrect analytics data on their dashboard, with top tracks and artists mismatched between time ranges. This led to confusion and inaccurate recommendations. Showing and Hiding tracks also malfunctioned intermittently.

### Root Cause

Cache keys were generated using raw query parameters without normalization. When parameters were passed in different orders or with varying whitespace/casing, semantically identical queries produced different cache keys, causing cache misses and, in rare cases, collisions.


### Actions Taken
- Implemented query normalization: parameters are now sorted, stripped of whitespace, and downcased before cache key generation.
- Added unit tests to verify cache key uniqueness and stability for equivalent queries.


### Follow-Up
- Periodically audit cache usage and key generation logic.
- Document cache key normalization in developer onboarding materials.

## Incident 002 – Unconfigured Routes Caused Application Errors

Date: 2025-01-12
Status: Closed

### Impact

When users manually entered or navigated to undefined routes (URLs not mapped in `routes.rb`), the application crashed and displayed a generic Rails error page. This resulted in a poor user experience and confusion, as users expected to be redirected to the dashboard or a helpful page.


### Root Cause

The Rails router did not have a catch-all route to handle undefined paths. Any request to an unconfigured route triggered a routing error, which was not gracefully handled by the application.


### Actions Taken
- Added a catch-all route at the end of `config/routes.rb` to redirect all undefined paths to the dashboard (`/dashboard`).
- Verified that navigating to any invalid URL now redirects users to a familiar dashboard view.

### Follow-Up
- Periodically review route configuration after adding new features.
- Add integration tests to ensure undefined routes are handled gracefully.

## Incident 004 – Coverage Reports Not Merging in CI

Date: 2025-03-11
Status: Resolved

### Impact

GitHub Actions showed 0% line coverage for Cucumber tests even though all scenarios passed locally.
This created confusion and reduced visibility into real test health.

### Root Cause

SimpleCov for Cucumber was writing to the default coverage/ folder, while RSpec wrote to coverage/rspec/.
CI didn’t collate both result sets before report upload.

### Actions Taken
- Updated features/support/env.rb to set:
```bash
    SimpleCov.command_name 'Cucumber'
    SimpleCov.coverage_dir 'coverage/cucumber'
```

- Updated CI workflow to run:
```bash
    bundle exec ruby bin/coverage_merge
```

- Verified merged report includes both RSpec and Cucumber.

---

# Debug Pointers

This section provides **useful context for developers** trying to debug issues in the codebase — including fixes that worked, workarounds that were tested and common dead ends to avoid.

| Issue / Area | Tried Solutions | Final Working Fix / Recommendation |
|---------------|----------------|------------------------------------|
|Spotify OAuth login failing (“invalid_client” or “redirect_uri_mismatch”)| Tried re-authenticating and restarting server — didn’t help. | Added the exact callback URLs (/auth/spotify/callback) for both localhost and Heroku to the Spotify Developer Dashboard and verified SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET were set in GitHub Actions and Heroku config vars. Also ensured that the user was whitelisted in development mode |
| Empty dashboard for inactive Spotify users | Tried switching to long_term time range only - data still missing. | Added friendly empty-state messages when Spotify returns insufficient top tracks/artists. |
| Playlist creation failing with “Invalid time range” | Tried re-sending POST requests from UI — no success. | Ensured time_range parameter matches one of the valid keys: short_term, medium_term, long_term. |
| Recommendations tab returning no results | Verified API keys — still empty. | Confirmed the app had user-top-read and user-read-recently-played scopes enabled in Spotify Developer Dashboard |
| Top Tracks limits not persisting across columns | Only the changed column updated — others reset to default. | Preserved other range limits via hidden fields (limit_short_term, limit_medium_term, limit_long_term) in the form before submission.|
| Playlist creation failing with “Invalid time range” | Tried re-sending POST requests from UI — no success. | Ensured time_range parameter matches one of the valid keys: short_term, medium_term, long_term. |
| Recommendations tab returning no results | Verified API keys — still empty. | Confirmed the app had user-top-read and user-read-recently-played scopes enabled in Spotify Developer Dashboard |
| Top Tracks limits not persisting across columns | Only the changed column updated — others reset to default. | Preserved other range limits via hidden fields (limit_short_term, limit_medium_term, limit_long_term) in the form before submission.|
| SSL Certificate Error | Tried updating gems and restarting server — no effect. | Add http.verify_mode = OpenSSL::SSL::VERIFY_NONE in `spotify_client.rb` or add http.ca_file = path pointing to the CA certificates file. |

---

# Debugging Common Issues

| Problem | Likely Cause | Fix |
|----------|---------------|-----|
| OAuth callback fails on Heroku | Missing redirect URI or wrong environment variables | Add exact production callback to Spotify Developer Dashboard and check SPOTIFY_CLIENT_ID / SPOTIFY_CLIENT_SECRET in Heroku/ Github config|
| “You are not registered for this app” during login / Login works locally but not in production
 | Spotify app still in Development Mode | Add test users under User Management in Spotify Dashboard or request Production access |
| Follow/Unfollow buttons randomly fail | Rate limit hit | Batch or throttle API requests; respect Spotify’s rate limits; avoid repeated clicks |

# Summary

**Spotilytics** lets Spotify users:
- Explore personalized listening stats and Spotify Wrapped-style insights anytime
- View top tracks, artists, and genres across different time ranges
- Get smart recommendations based on your listening patterns
- Create and save custom playlists directly to your Spotify account
- Manage your profile — including following and unfollowing artists — all in one place

# Developed by Team 1 - CSCE 606 (Fall 2025)
## Team Members
- **Pablo Pineda**
- **Pradeep Periyasamy**
- **Vanessa Lobo**

> “Discover Your Sound”







