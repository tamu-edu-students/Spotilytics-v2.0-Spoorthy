# Class Diagram

```mermaid
classDiagram
  class ApplicationController

  class PagesController {
    +home()
    +dashboard()
    +top_artists()
    +top_tracks()
    +library()
    +view_profile()
    -spotify_client()
    -fetch_followed_artists(limit)
    -fetch_user_playlists_all(skip_cache = true)
    -fetch_top_artists(limit, time_range = "long_term")
    -fetch_top_tracks(limit)
    -fetch_saved_shows(limit)
    -fetch_saved_episodes(limit)
    -build_genre_chart!(artists)
  }

  class TopTracksController {
    +index()
    +hide()
    +unhide()
    -normalize_limit(param)
    -require_spotify_auth!()
  }

  class PlaylistsController {
    +create()
    +create_from_recommendations()
    +add_song()
    +create_custom()
    +rename()
    +update_description()
    +update_collaborative()
    -require_spotify_auth!()
  }

  class SavedShowsController {
    +index()
    +search()
    +create()
    +destroy()
    +bulk_save()
  }

  class SavedEpisodesController {
    +index()
    +search()
    +create()
    +destroy()
    +bulk_save()
  }

  class ArtistFollowsController {
    +create()
    +destroy()
  }

  class RecommendationsController {
    +recommendations()
  }

  class SessionsController {
    +create()  /* /auth/spotify/callback */
    +destroy() /* logout */
  }

  class SpotifyClient {
    +initialize(session:)
    +top_tracks(limit:, time_range:)
    +top_artists(limit:, time_range:)
    +follow_artists(ids)
    +unfollow_artists(ids)
    +followed_artist_ids(ids)
    +followed_artists(limit:)
    +search_tracks(query, limit:)
    +search_shows(query, limit:, offset:)
    +search_episodes(query, limit:, offset:)
    +new_releases(limit:)
    +user_playlists(limit:, offset:, skip_cache:)
    +user_playlists_all(page_size:, skip_cache:)
    +update_playlist_name(playlist_id:, name:)
    +update_playlist_description(playlist_id:, description:)
    +update_playlist_collaborative(playlist_id:, collaborative:)
    +saved_shows(limit:, offset:)
    +saved_episodes(limit:, offset:)
    +save_shows(ids)
    +save_episodes(ids)
    +remove_shows(ids)
    +remove_episodes(ids)
    +current_user_id()
    +create_playlist_for(user_id:, name:, description:, public:)
    +add_tracks_to_playlist(playlist_id:, uris:)
    +clear_user_cache()
    -cache_for(key_parts, expires_in)
    -ensure_access_token!()
    -refresh_access_token!()
    -get(path, token, params)
    -post_json(path, token, body)
    -request_with_json(klass, path, token, params, body)
  }

  class RailsCache {
    <<framework>>
    +fetch(key, expires_in, &block)
    +delete_matched(pattern)
  }

  class Track {
    +id : String
    +name : String
    +artists : String
    +album_name : String
    +album_image_url : String
    +popularity : Integer
    +preview_url : String
    +spotify_url : String
    +rank : Integer
    +duration_ms : Integer
  }

  class Artist {
    +id : String
    +name : String
    +image_url : String
    +genres : String[]
    +popularity : Integer
    +playcount : Integer
    +spotify_url : String
    +rank : Integer
  }

  class RedisStore {
    <<Heroku Add-on>>
    +GET/SET keys
    +TTL 24h
    +namespace "spotilytics-cache"
  }

  ApplicationController <|-- PagesController
  ApplicationController <|-- TopTracksController
  ApplicationController <|-- PlaylistsController
  ApplicationController <|-- SavedShowsController
  ApplicationController <|-- SavedEpisodesController
  ApplicationController <|-- ArtistFollowsController
  ApplicationController <|-- RecommendationsController
  ApplicationController <|-- SessionsController

  PagesController --> SpotifyClient
  TopTracksController --> SpotifyClient
  PlaylistsController --> SpotifyClient
  SavedShowsController --> SpotifyClient
  SavedEpisodesController --> SpotifyClient
  ArtistFollowsController --> SpotifyClient
  RecommendationsController --> SpotifyClient

  SpotifyClient --> Track
  SpotifyClient --> Artist

  %% Caching collaboration
  SpotifyClient --> RailsCache : uses (Rails.cache)
  RailsCache --> RedisStore : backed by
