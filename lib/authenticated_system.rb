module AuthenticatedSystem
  # Returns true or false if the user is logged in.
  # Preloads @current_user with the user model if they're logged in.
  
  #Per Page value for paginated sections of the forums,
  def per_page
    logged_in? ? current_user.per_page : PER_PAGE
  end
  
  #how the user has selected they want to display the time
  def time_display
    logged_in? ? current_user.time_display : TIME_DISPLAY
  end
  
  #how the user has selected they want to display the date  
  def date_display
    logged_in? ? current_user.date_display : DATE_DISPLAY
  end
  
  def date_time_display
    date_display + " " + time_display
  end
  
  def is_admin?
    logged_in? && current_user.admin?
  end
  
  def is_moderator?
    logged_in? && (current_user.admin? || current_user.moderator?)
  end
    
  def non_admin_redirect
    if !is_admin?
      flash[:notice] = t(:need_to_be_admin)
      redirect_back_or_default(root_path)
    end
  end
  
  def non_moderator_redirect
    if !is_moderator?
      flash[:notice] = t(:need_to_be_admin_or_moderator)
      redirect_back_or_default(root_path)
    end
  end
  
  def ip_banned?
    @ips = BannedIp.find(:all, :conditions => ["ban_time > ?",Time.now]).select do |ip|
      !Regexp.new(ip.ip).match(request.remote_addr).nil? unless ip.nil?
    end
    flash[:ip] = @ips.first unless @ips.empty?
  end
  
  def ip_banned_redirect
    redirect_to :controller => ip_is_banned_users_path unless params[:action] == "ip_is_banned"  if ip_banned?
  end
  
  def user_banned?
    logged_in? ? !current_user.ban_time.nil? && @current_user.ban_time > Time.now : false
  end
  
  def theme
    (Dir.entries("#{RAILS_ROOT}/public/themes") - ['.svn','..','.']).each { |theme| Theme.create(:name => theme) } if Theme.count == 0   
    theme = logged_in? && !current_user.theme.nil? ? current_user.theme : Theme.find_by_is_default(true)
    theme.nil? ? Theme.first : theme
  end
  
  def active_user
    current_user.update_attribute("login_time",Time.now) if logged_in?
  end
  
  def logged_in?
    current_user != :false
  end
  
  # Accesses the current user from the session.
  def current_user
    @current_user ||= (session[:user] && User.find_by_id(session[:user])) || :false
  end
  
  # Store the given user in the session.
  def current_user=(new_user)
    session[:user] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.id
    @current_user = new_user
  end
  
  # Filter method to enforce a login requirement.
  #
  # To require logins for all actions, use this in your controllers:
  #
  #   before_filter :login_required
  #
  # To require logins for specific actions, use this in your controllers:
  #
  #   before_filter :login_required, :only => [ :edit, :update ]
  #
  # To skip this in a subclassed controller:
  #
  #   skip_before_filter :login_required
  #
  def login_required
    username, passwd = get_auth_data
    self.current_user ||= User.authenticate(username, passwd) || :false if username && passwd
    if !logged_in?
      flash[:notice] = t(:you_must_be_logged_in)
      redirect_to login_path
    end
  end
  
  
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.request_uri
  end
  
  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
    session[:return_to] = nil
  end
  
  # Inclusion hook to make #current_user and #logged_in?
  # available as ActionView helper methods.
  def self.included(base)
    base.send :helper_method, 
              :current_user,
              :logged_in?,
              :is_admin?,
              :is_moderator?,
              :ip_banned?,
              :user_banned?,
              :theme,
              :time_display,
              :date_display,
              :date_time_display,
              :per_page
  end
  
  # When called with before_filter :login_from_cookie will check for an :auth_token
  # cookie and log the user back in if apropriate
  def login_from_cookie
    return unless cookies[:auth_token] && !logged_in?
    user = User.find_by_remember_token(cookies[:auth_token])
    if user && user.remember_token?
      user.remember_me
      self.current_user = user
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
    end
  end
  
  private
  @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
  # gets BASIC auth info
  def get_auth_data
    auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
    auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
    return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
  end
 
end
