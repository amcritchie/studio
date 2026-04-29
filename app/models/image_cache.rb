class ImageCache < ApplicationRecord
  belongs_to :owner, polymorphic: true

  validates :purpose, :variant, :s3_key, presence: true
  validates :s3_key, uniqueness: true
  validates :variant, uniqueness: { scope: [:owner_type, :owner_id, :purpose] }

  def url
    Studio::S3.url(key: s3_key)
  end
end
