module PostsHelper
    def square(photo)
        photo.variant(resize_to_limit: [100, 100])
    end
end
