require 'digest/sha1'
class User < ActiveRecord::Base
  include Permissions
  attr_accessor :password
  
  named_scope :recent, lambda { { :conditions => ["login_time > ?", 15.minutes.ago] } }
  
  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  validates_uniqueness_of   :display_name, :allow_nil => true
  
  has_many :banned_ips, :foreign_key => "banned_by"
  has_many :edits
  has_many :group_users
  has_many :groups, :through => :group_users
  has_many :inbox_messages, :class_name => "Message", :foreign_key => "to_id", :conditions => ["to_deleted = ?", false], :order => "id DESC"
  has_many :ip_users
  has_many :ips, :through => :ip_users, :order => "ips.updated_at DESC"
  has_many :outbox_messages, :class_name => "Message", :foreign_key => "from_id", :conditions => ["from_deleted = ?", false], :order => "id DESC"
  has_many :moderations
  has_many :permissions, :through => :groups, :source => :permissions
  has_many :posts
  has_many :reports
  has_many :sent_messages, :class_name => "Message", :foreign_key => "from_id"
  has_many :subscriptions
  has_many :subscribed_topics, :through => :subscriptions
  has_many :topics
  has_many :unread_messages, :class_name => "Message", :foreign_key => "to_id", :conditions => ["to_read = ? AND to_deleted = ?", false, false]
  
      
  
  has_attached_file :avatar, :styles => { :thumbnail => "100>" }

  belongs_to :banned_by, :class_name => "User", :foreign_key => "banned_by"
  belongs_to :style
  belongs_to :theme
  
  before_create :encrypt_password
  before_create :set_theme
  before_save :set_permalink
  
  def self.anonymous
    find_by_login("anonymous")
  end
  
  def anonymous?
    login == "anonymous"
  end
  
  def set_permalink
    self.permalink = to_s.parameterize
  end
  
  def set_theme
    self.theme = Theme.find(:first)
  end
  
  before_save :set_permalink
  before_save :set_default_group_if_none

  def to_s
    output = display_name unless display_name.blank?
    output ||= login
  end
  
  def to_param
    to_s.parameterize
  end
  
  #misc. user information
  def rank
    rank = Rank.find_by_id(rank_id)
	  rank = Rank.find_by_custom(false, :conditions => ["posts_required <= ?", posts.size], :order => "posts_required DESC") if rank.nil?
	  rank.nil? ? groups.first.name : rank.name
  end
  
  def banned?
    ban_time.nil? ? false : ban_time > Time.now
  end
  
  def has_avatar?
    !avatar_file_name.blank?
  end
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end
  
  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end
  
  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end
  
  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end
  
  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  def online?
    login_time > Time.now - 15.minutes
  end
  
  protected
  def encrypt_password
    if new_record?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--")
      self.crypted_password = encrypt(password)
    end
  end
  
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  private
  
  def set_permalink
    self.permalink = to_s.parameterize
  end
  
  def set_theme
    self.theme = Theme.find(:first)
  end
  
  def set_default_group_if_none
    #TODO
  end
end
