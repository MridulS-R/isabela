Rails.application.routes.draw do
  root 'pages#home'
  get '/solutions', to: 'pages#solutions'
  get '/data-coverage', to: 'pages#data_coverage'
  get '/how-it-works', to: 'pages#how_it_works'
  get '/about', to: 'pages#about'
  get '/blog', to: 'pages#blog'
  get '/contact', to: 'pages#contact'
end

