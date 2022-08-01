class Category < ApplicationRecord

    has_one_attached :image
    has_one_attached :sound

    has_many :posts
    belongs_to :user

end
