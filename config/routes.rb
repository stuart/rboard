Rboard::Application.routes.draw do
  root :to => 'forums#index'
  
  match 'login', :to => 'users#login', :as => 'login'
  match 'logout', :to => 'users#logout', :as => 'logout'
  match 'signup', :to => 'users#signup', :as => 'signup'
  
  match 'search', :to => 'search#index', :as => 'search'
  
  namespace :admin do
    root :to => "index#index"
    resources :categories do
      put :move_up, :on => :member
      put :move_down, :on => :member
      put :move_to_top, :on => :member
      put :move_to_bottom, :on => :member
      resources :forums, :permissions
    end
    
    match 'chronic', :to => "chronic#index", :as => 'chronic'
    
    resources :configurations do
      put :update_all, :on => :collection
    end
    
    resources :forums do
      put :move_up, :on => :member
      put :move_down, :on => :member
      put :move_to_top, :on => :member
      put :move_to_bottom, :on => :member
      resources :permissions
    end
    
    resources :groups do
      resources :members
      resources :users
      resources :forums do
        resources :permissions
      end
    end
    
    resources :ips do
      resources :topics, :only => [:index]
      resources :posts, :only => [:index]
      resources :users, :only => [:index]
    end
    
    resources :ranks
    resources :themes do
      put :make_default, :on => :member
    end
    
    resources :users do
      member do
        post :ban       #any ?
        post :ban_ip    #any ?
        post :remove_banned_ip
      end
      collection do 
        post :ban_ip
        get :search
      end
      resources :ips
    end
    
  end
  
  namespace :moderator do
    root :to => "index#index"
    resources :topics do
      member do
        put :lock
        put :sticky
      end          
      
      collection do
        post :moderate
        put :merge
      end
      
      resources :moderations
      resources :posts  do
        member do
         get :split
         post :split
        end
      end
      resources :reports
    end
    
    resources :posts do
      resources :moderations
      resources :reports
    end
    
    resources :moderations
    resources :reports
  end
  

  resources :categories do 
    resources :forums
  end

  resources :forums do
    collection do 
      get :list
    end
    resources :topics do
      member do 
        put :lock
        put :unlock
      end
    end
  end

  resources :messages do
    member do 
      get :reply
    end
    collection do
      get :sent
      put :change
    end
  end  

  resources :posts do
    member do
      delete :destroy
      put :destroy
      post :destroy
      get :destroy
    end
    
    resources :edits
    resources :reports
  end

  resources :subscriptions

  resources :topics do
    member do
     get :reply
     put :unlock
     put :lock
    end
    
    resources :posts do
      member do
        get :reply
      end
    end
    resources :subscriptions
    resources :reports
  end

  resources :users do
    member do 
      get :profile 
    end
    collection do 
      get :signup
      get :ip_is_banned
    end
    resources :posts
  end

  # pretty pagination links
  match 'forums/:forum_id/topics/:id/:page', :to => "topics#show"
  match 'forums/:id/:page', :to => "forums#show"
  match ':controller(/:action(/:id))'
end
