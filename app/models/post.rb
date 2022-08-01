require 'uri'
require 'net/http'
require 'openssl'
require 'base64'

class Post < ApplicationRecord

    validates :title,:category_id,:location,:image, :sound, presence: true
    validates :title, format: { with: /\A[a-zA-Z0-9-_]+\Z/, message: 'Title cannot contain whitespace or special characters' }

    belongs_to :user
    belongs_to :category

    has_one_attached :image
    has_one_attached :sound



    public
    # module_function

    def self.text_to_speech(text)
        voice = speech({
        'key' => '6474bf093c804dd6a0fd92ed8aac4519',
        'hl' => 'en-us',
        'v' => 'Linda',
        'src' => "#{text}",
        'r' => '0',
        'c' => 'mp3',
        'f' => '44khz_16bit_stereo',
        'ssml' => 'false',
        'b64' => 'false'
        })
        
        encoded_string = Base64.encode64(voice['response'])

        File.open('app/assets/audios/temp.mp3', "wb") do |file|
            file.write(Base64.decode64(encoded_string))
        end
        
        return "temp.mp3"
    end

    def self.attach_sound(post)
        post.sound.attach(io: File.open("app/assets/audios/temp.mp3"), filename: "#{post.title}.mp3")
    end    
    def self.speech(settings)
      _validate(settings)
      return _request(settings)
    end
    
    private
    
    def self._validate(settings)
      raise 'The settings are undefined' if settings.nil? || settings.empty?
      raise 'The API key is undefined' if settings['key'].nil? || settings['key'].empty?
      raise 'The text is undefined' if settings['src'].nil? || settings['src'].empty?
      raise 'The language is undefined' if settings['hl'].nil? || settings['hl'].empty?
    end
    
    def self._request(settings)
      response = {
        'error' => nil,
        'response' => nil
      }
          
      uri = URI((settings['ssl'] ? 'https' : 'http') + '://api.voicerss.org/')
      req = Net::HTTP::Post.new(uri)
      req.set_form_data(_buildRequest(settings))
        
      res = Net::HTTP.start(uri.hostname, uri.port,
        :use_ssl => uri.scheme == 'https') do |http|
        http.request(req)
      end
      
      case res
      when Net::HTTPSuccess
        if res.body.index('ERROR') == 0
          response['error'] = res.body
        else
          response['response'] = res.body
        end
      else
        response['error'] = res.message
      end
          
      response
    end
    
    def self._buildRequest(settings)
      return {
        'key' => settings['key'],
        'src' => settings['src'],
        'hl' => settings['hl'],
        'v' => settings['v'],
        'r' => settings['r'],
        'c' => settings['c'],
        'f' => settings['f'],
        'ssml' => settings['ssml'],
        'b64' => settings['b64']
      }
    end
end