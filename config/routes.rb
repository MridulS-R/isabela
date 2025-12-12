Rails.application.routes.draw do
  root 'pages#home'
  resources :posts, only: %i[index show new create]
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
end
