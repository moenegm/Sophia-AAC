Rails.application.routes.draw do
  devise_for :users
  resources :posts
  get "all_posts", to: 'posts#all_posts'
  get "activities", to: 'posts#activities'
  get "crafts", to: 'posts#crafts'
  get "drinks", to: 'posts#drinks'
  get "feelings", to: 'posts#feelings'
  get "food", to: 'posts#food'
  get "people", to: 'posts#people'
  get "places", to: 'posts#places'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'posts#index'
end
