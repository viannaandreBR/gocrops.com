class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:facebook]

  has_many :crops, dependent: :destroy
  # validates :farm_location, presence: true
  mount_uploader :avatar, PictureUploader
  mount_uploader :farm_picture, PictureUploader

  geocoded_by :farm_location
  after_validation :geocode, if: :farm_location_changed?

  def self.find_for_facebook_oauth(auth)
     user_params = auth.slice(:provider, :uid)
     user_params.merge! auth.info.slice(:email, :first_name, :last_name)
     user_params[:facebook_picture_url] = auth.info.image
     user_params[:token] = auth.credentials.token
     user_params[:token_expiry] = Time.at(auth.credentials.expires_at)
     user_params = user_params.to_h

     user = User.find_by(provider: auth.provider, uid: auth.uid)
     user ||= User.find_by(email: auth.info.email) # User did a regular sign up in the past.
     if user
       user.update(user_params)
     else
       user = User.new(user_params)
       user.password = Devise.friendly_token[0,20]  # Fake password for validation
       user.save
     end

     return user
   end

  def user_avatar
    self.avatar_url || self.facebook_picture_url || "http://via.placeholder.com/50x50"
  end

end
