## DB 定義

```mermaid
erDiagram
  users {
    string user_id PK
    string username
    string password
    string profile
    boolean is_wink
    string location
    boolean is_ai
  }
  search_histories {
    string search_histories_id PK
    string user_id FK
    string search_word
    datetime searched_at
  }
  recipe_histories {
    string id PK
    string user_id FK
    string recipe_id FK
    datetime read_at
  }
  notices {
    string notice_id PK
    string user_id FK
    string title
    string content
    boolean is_read
  }
  recipes {
    string recipe_id PK
    string chef_id FK
    string status
    string title
    string picture_url
    string point
  }
  recipe_content {
    string recipe_content_id PK
    string recipe_id FK
    string picture
    string step
    string description
  }
  favorites {
    string favorite_id PK
    string user_id FK
    string recipe_id FK
  }
  dining_plans {
    string dining_plan_id PK
    string user_id FK
    string recipe_id FK
    date dining_day
  }
  follows {
    string follow_id PK
    string follower_id FK
    string followed_id FK
  }
  comments {
    string comment_id PK
    string user_id FK
    string recipe_id FK
    string content
  }
  blocks {
    string block_id PK
    string blocker_id FK
    string blocked_id FK
  }
  
  users ||--o{ search_histories : "searches"
  users ||--o{ recipe_histories : "views"
  users ||--o{ notices : "receives"
  users ||--o{ favorites : "adds"
  users ||--o{ dining_plans : "plans"
  users ||--o{ follows : "follows"
  users ||--o{ follows : "followed_by"
  users ||--o{ comments : "writes"
  users ||--o{ blocks : "blocks"
  users ||--o{ blocks : "blocked_by"
  users ||--o{ recipes : "creates"
  recipes ||--o{ favorites : "favorited_by"
  recipes ||--o{ dining_plans : "scheduled_in"
  recipes ||--o{ comments : "receives"
  recipes ||--o{ recipe_histories : "viewed_in"
  recipes ||--|{ recipe_content : "has_steps"
```