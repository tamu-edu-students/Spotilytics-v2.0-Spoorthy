# System Architecture Diagram

```mermaid
graph TD
  subgraph User_Device["User Browser"]
    UI["Spotilytics UI (Rails views + Turbo / JS)"]
    Cookie["Session Cookie"]
  end

  subgraph Heroku["Heroku Dyno(s)"]
    Rails["Rails App"]
    SClient["SpotifyClient (service)"]
    Views["ERB Views / Partials<br/>Dashboard • Top Artists/Tracks • Library • Recommendations<br/>Saved Shows/Episodes • Playlist Builder"]
    RailsCache["Rails.cache API"]
  end

  subgraph Heroku_Addons["Heroku Add-ons"]
    Redis["Redis (redis_cache_store)\nnamespace: spotilytics-cache\nTTL: 24h"]
  end

  subgraph SpotifyCloud["Spotify Platform"]
    OAuth["Spotify Accounts (OAuth2)"]
    WebAPI["Spotify Web API"]
  end

  %% Browser <> Rails
  User_Device -->|HTTPS| Rails
  Rails -->|Reads/Writes| Cookie
  Rails -->|Server-render views| Views

  %% OAuth
  Rails -->|OAuth redirect| OAuth
  OAuth -->|Auth code / tokens| Rails

  %% App <-> Client <-> API
  Rails --> SClient
  SClient -->|REST| WebAPI

  %% Caching path
  Rails -->|read/write| RailsCache
  RailsCache <--> Redis

  %% Cache flow semantics
  SClient -. "cache_for([...])\nRails.cache.fetch(key)" .-> RailsCache
  RailsCache -. "hit → return data" .-> SClient
  RailsCache -. "miss → fetch via API\nstore in Redis" .-> SClient

  %% Library refresh immediately after mutations
  Rails -. "Library fetch can skip cache after playlist changes" .- SClient

  %% CI
  subgraph CI["GitHub Actions"]
    Lint["Rubocop / Brakeman"]
    Tests["RSpec + Cucumber"]
    Coverage["SimpleCov Collate (RSpec+Cucumber)"]
    Deploy["Heroku Deploy"]
  end

  CI --> Heroku
