class Post < ApplicationRecord
    validates :title,:category_id,:location,:image,:sound, presence: true
    validates :title, format: { with: /\A[a-zA-Z0-9-_]+\Z/, message: 'Title cannot contain whitespace or special characters' }

    belongs_to :user
    belongs_to :category

    has_one_attached :image
    has_one_attached :sound


end
