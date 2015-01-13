class User < ActiveRecord::Base
  extend FriendlyId
  include HasZone

  class_attribute :invalid_usernames
  attr_accessor :skip_password
  store_accessor :metadata
  self.invalid_usernames = Set.new CONFIG[:user][:excluded_usernames]

  has_many :accounts, dependent: :destroy
  has_many :bookmark_imports, dependent: :destroy
  has_many :folders, dependent: :destroy
  has_many :links, dependent: :destroy
  has_many :sharings, dependent: :destroy # Sharings from other Users.
  has_many :created_sharings, foreign_key: 'creator_id', class_name: 'Sharing', dependent: :destroy # Sharings created by the User.

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :confirmable, :omniauthable,
         :async

  has_zone with: :time_zone
  auto_strip_attributes :name, :username, :email
  friendly_id :username

  validates :email,
    presence: true,
    email: true
  validates :username,
    presence: true,
    uniqueness: {case_sensitive: false},
    format: {with:/\A[A-Za-z0-9]+\z/},
    length: {in: 4..200},
    exclusion: {in: lambda {|*args| self.invalid_usernames}}

  class << self

    # Public: Finds or builds User with OmniAuth auth_hash. It also updates the account with auth_hash.
    #
    # provider - OmniAuth provider.
    # auth_hash - OmniAuth auth_hash.
    # signed_in_resource - Current logged in user if user is signed in (default: nil).
    #
    # Returns User.
    #
    def find_for_omniauth(provider, auth_hash, signed_in_resource=nil)
      user = nil
      if signed_in_resource
        user = signed_in_resource
        user.apply_omniauth!(auth_hash)
      elsif account = Account.where(auth_hash.slice(:provider, :uid)).first
        user = account.user
        user.apply_omniauth!(auth_hash)
      elsif auth_hash["info"]["email"] and (user = self.where(email: auth_hash["info"]["email"]).first)
        user.apply_omniauth!(auth_hash)
      else
        user = User.new
        user.apply_omniauth(auth_hash)
        user.save
      end
      user
    end

    # Public: Used by Devise to build new User.
    #
    # Returns User.
    #
    def new_with_session(params, session)
      super.tap do |user|
        if auth_hash = session['devise.omniauth']
          user.apply_omniauth(auth_hash)
        end
      end
    end

    # Public: Used by Devise to login using username or email.
    # from https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign-in-using-their-username-or-email-address
    #
    def find_first_by_auth_conditions(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
      else
        where(conditions).first
      end
    end
  end

  # Public: Sets login.
  #
  # login: login of the User, it could be either the username or email address.
  #
  def login=(login)
    @login = login
  end

  # Public: Gets the login for the User.
  #
  # Returns the login for the User.
  #
  def login
    @login || self.username || self.email
  end

  # Public: Gets the email of the user, either the email is confirmed or not
  #
  # Override to return unconfirmed_email if no other email address has been confirmed previously
  #
  # Returns the email of the user.
  #
  def email
    confirmed_email = read_attribute(:email)
    return confirmed_email.present? ? confirmed_email : unconfirmed_email
  end

  # Used by Devise. If the user has an Account, password is not required.
  def password_required?
    return false if @skip_password
    accounts.empty? and super
  end

  # Public: Returns true if user has set up a password.
  def has_password?
    self.encrypted_password.present?
  end

  # Public: Returns number of seconds before User has no access.
  #
  # It raises an exception if the user is confirmed.
  #
  def confirmation_period_expires_in
    raise "User is confirmed" if self.confirmed?
    confirmation_sent_at.utc + self.class.allow_unconfirmed_access_for - Time.now.utc
  end

  # Public: Assigns data from auth_hash to User and Account.
  #
  # auth_hash - OmniAuth auth_hash.
  #
  # Returns Account.
  #
  def apply_omniauth(auth_hash)
    return if auth_hash.nil?

    auth_hash = auth_hash.with_indifferent_access

    Rails.logger.debug "\n\n\n***auth_hash:\n#{auth_hash.to_yaml}\n\n"
    info = auth_hash['info']

    self.email      ||= info["email"] if info["email"].present?
    self.name       ||= info["name"]  if info["name"].present?
    self.image_url  ||= info["image"] if info["image"].present?

    account =
      self.accounts.where(auth_hash.slice(:provider, :uid)).first ||
      self.accounts.new(auth_hash.slice(:provider, :uid))
    account.assign_attributes(auth_hash: auth_hash, info: info, credentials: auth_hash["credentials"], user: self)
    account
  end

  # Public: Assigns data from auth_hash to User and Account and save.
  #
  # auth_hash - OmniAuth auth_hash.
  #
  # Returns Account.
  #
  def apply_omniauth!(auth_hash)
    account = apply_omniauth(auth_hash)
    self.transaction do
      save!
      account.save!
    end if account
    account
  end

  # Public: Returns the IDs of the Folders that shared to the User.
  def share_folder_ids
    Sharing.where(user_id: self.id).pluck(:folder_id)
  end

  # Public: Returns true if User is an admin.
  def admin?
    confirmed? and CONFIG[:user][:admin_emails].include?(self.email)
  end
end
