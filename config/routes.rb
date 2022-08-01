Rails.application.routes.draw do
  
  resources :categories
  devise_for :users
  resources :posts

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'posts#index'
end
