Rails.application.routes.draw do
  root 'pages#home'
  resources :posts, only: %i[index show new create]
  post '/posts/:id/repost', to: 'posts#repost', as: :repost_post
  post '/posts/:id/quote', to: 'posts#quote', as: :quote_post
  post '/posts/:id/like', to: 'posts#like', as: :like_post
  delete '/posts/:id/like', to: 'posts#unlike', as: :unlike_post
  post '/posts/:id/comments', to: 'posts#comment', as: :post_comments
  get '/t/:name', to: 'tags#show', as: :tag
  get '/signup', to: 'users#new'
  post '/signup', to: 'users#create'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get '/solutions', to: 'pages#solutions'
  get '/data-coverage', to: 'pages#data_coverage'
  get '/how-it-works', to: 'pages#how_it_works'
  get '/about', to: 'pages#about'
  get '/blog', to: 'pages#blog'
  get '/contact', to: 'pages#contact'

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
