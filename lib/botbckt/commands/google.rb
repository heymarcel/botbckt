module Botbckt #:nodoc:

  # Sends a query to Google via the JSON API and returns output in-channel:
  #
  #  < user> ~google ruby
  #  < botbckt> First out of 93900000 results:
  #  < botbckt> Ruby Programming Language
  #  < botbckt> http://www.ruby-lang.org/
  #
  # Inspired by Clojurebot: http://github.com/hiredman/clojurebot
  #
  class Google < Command
  
    trigger :google
    
    def call(sender, channel, query)
      result = google(query)
      say "First out of #{result.first} results:", channel
      say result.last['titleNoFormatting'], channel
      say result.last['unescapedUrl'], channel
    end
  
    private
  
    def google(term) #:nodoc:
      json     = open("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=#{CGI.escape(term)}")
      response = JSON.parse(json.read)

      [
        response['responseData']['cursor']['estimatedResultCount'],
        response['responseData']['results'].first
      ]
    end

  end
end