module PostsHelper

    def square(photo)
        photo.variant(:gravity=>"Center", resize: "500x500^", crop: "500x500+0+0")
    end

    def title(string)
        string = string.gsub(" ", "-")
    end

end


