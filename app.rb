require 'bundler'
require 'json'
Bundler.require

set :port, 8080 unless Sinatra::Base.production?

# Initialize RabbitMQ object & connection appropriate to
# the current env (viz., local vs. prod)
if Sinatra::Base.production?
  rabbit = Bunny.new(ENV['CLOUDAMQP_URL'])
else
  rabbit = Bunny.new(automatically_recover: false)
end
rabbit.start
channel = rabbit.create_channel
RABBIT_EXCHANGE = channel.default_exchange

# author_id, tweet_id, tweet_body
NEW_TWEET = channel.queue('new_tweet.tweet_data')

NEW_TWEET.subscribe(block: false) do |delivery_info, properties, body|
  parse_tweet_tokens(JSON.parse(body)['tweet_body'])
end

def parse_tweet_tokens(tweet_body)
  puts tweet_body.split
end
