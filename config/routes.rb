Rails.application.routes.draw do
  root 'pages#home'
  resources :posts, only: %i[index show new create edit update destroy]
  post '/posts/:id/repost', to: 'posts#repost', as: :repost_post
  post '/posts/:id/quote', to: 'posts#quote', as: :quote_post
  post '/posts/:id/pin', to: 'posts#pin', as: :pin_post
  delete '/posts/:id/pin', to: 'posts#unpin', as: :unpin_post
  post '/posts/:id/like', to: 'posts#like', as: :like_post
  delete '/posts/:id/like', to: 'posts#unlike', as: :unlike_post
  post '/posts/:id/comments', to: 'posts#comment', as: :post_comments
  get '/t/:name', to: 'tags#show', as: :tag
  get '/trending', to: 'trending#index', as: :trending
  get '/signup', to: 'users#new'
  post '/signup', to: 'users#create'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get '/home', to: 'timelines#home', as: :home
  get '/bookmarks', to: 'bookmarks#index', as: :bookmarks
  post '/posts/:id/bookmark', to: 'bookmarks#create', as: :bookmark_post
  delete '/posts/:id/bookmark', to: 'bookmarks#destroy', as: :unbookmark_post

  # Follows (users)
  post '/u/:id/follow', to: 'follows#create', as: :follow_user
  delete '/u/:id/follow', to: 'follows#destroy', as: :unfollow_user

  # Community follows
  post '/c/:slug/follow', to: 'community_follows#create', as: :follow_community
  delete '/c/:slug/follow', to: 'community_follows#destroy', as: :unfollow_community
  get '/solutions', to: 'pages#solutions'
  get '/data-coverage', to: 'pages#data_coverage'
  get '/how-it-works', to: 'pages#how_it_works'
  get '/about', to: 'pages#about'
  get '/blog', to: 'pages#blog'
  get '/contact', to: 'pages#contact'
  get '/search', to: 'search#index', as: :search
  get '/explore', to: 'explore#index', as: :explore

  # Admin imports (UI + API)
  resources :imports, only: %i[new create]

  # Admin dashboard
  get '/admin', to: 'admin#dashboard', as: :admin_dashboard
  # Map
  get '/map', to: 'maps#index', as: :post_map
  get '/map/data', to: 'maps#data'
  get '/map.csv', to: 'maps#csv'
  get '/profile', to: 'profile#show', as: :profile
  get '/profile/edit', to: 'profile#edit', as: :edit_profile
  patch '/profile', to: 'profile#update'
  post '/profile/sessions/sign_out_others', to: 'profile#sign_out_others', as: :sign_out_other_sessions
  post '/profile/sessions/sign_out_all', to: 'profile#sign_out_all', as: :sign_out_all_sessions
  post '/admin/news_crawl', to: 'news_crawl#enqueue'

  # Notifications
  get '/notifications', to: 'notifications#index', as: :notifications
  post '/notifications/:id/read', to: 'notifications#read', as: :read_notification
  get '/notifications/count', to: 'notifications#count', defaults: { format: :json }

  # Auth flows
  get '/password/new', to: 'passwords#new', as: :new_password
  post '/password', to: 'passwords#create', as: :passwords
  get '/password/edit', to: 'passwords#edit', as: :edit_password
  patch '/password/update', to: 'passwords#update', as: :update_password
  get '/confirm', to: 'confirmations#show', as: :confirm_email
  post '/confirm/resend', to: 'confirmations#resend', as: :resend_confirmation

  # Community news
  get '/c/:slug', to: 'communities#show', as: :community
  get '/c/:slug/news', to: 'communities#news', as: :community_news
  get '/c/:slug/trending', to: 'trending#community', as: :community_trending
  get '/c/:slug/t/:name', to: 'tags#community', as: :community_tag
  get '/topics', to: 'topics#index', as: :topics
  get '/c/:slug/topics', to: 'topics#community', as: :community_topics
  get '/c/:slug/topics/:topic_slug', to: 'topics#show', as: :community_topic

  # Public user profile
  get '/u/:id', to: 'users_public#show', as: :user_public
  # Feeds removed; crawling uses predefined sources via rake/jobs

  namespace :admin do
    resources :homepage_articles do
      post :publish, on: :member
      post :retire, on: :member
      post :reparse, on: :member
    end
    resources :communities, only: [:create]
    resources :news_sources do
      post :crawl, on: :member
    end
  end
end
