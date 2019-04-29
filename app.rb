require 'bundler'
require 'json'
Bundler.require

set :port, 8083 unless Sinatra::Base.production?

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
SEARCH_HTML = channel.queue('searcher.html')
seed = channel.queue('timeline.data.seed')

# Parses & indexes tokens from payload.
seed.subscribe(block: false) do |delivery_info, properties, body|
  seed_from_payload(JSON.parse(body))
end

# Extracts Tweet body from payload & indexes its tokens.
NEW_TWEET.subscribe(block: false) do |delivery_info, properties, body|
  parse_tweet_tokens(JSON.parse(body))
end

def parse_tweet_tokens(tweet)
  tweet_id = tweet['tweet_id']
  tokens = tweet['tweet_body'].split.map { |token| token.downcase.gsub(/[^a-z ]/, '') }
  payload = { tweet_id: tweet_id, tokens: tokens }.to_json
  RABBIT_EXCHANGE.publish(payload, routing_key: SEARCH_HTML.name)
end

# Parses & indexes tokens from each Tweet body in payload.
def seed_from_payload(payload)
  tweet_ids = Set.new
  payload.each do |timeline|
    tweets = timeline['sorted_tweets']
    tweets.each do |tweet|
      parse_tweet_tokens(tweet) unless tweet_ids.add?(tweet['tweet_id']).nil?
    end
  end
end
