# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  # A singular `resource` silently drops :index, which is why the previous
  # `resource :landings, only: %i[index create]` never generated one.
  root "landings#index"
  post "/messages", to: "landings#create", as: :messages

  # Liveness probe for the container healthcheck. Does not touch the database
  # or any third party, so it answers while dependencies are still coming up.
  get "/up", to: "rails/health#show", as: :rails_health_check
end
