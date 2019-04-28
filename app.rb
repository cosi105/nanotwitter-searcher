require 'bundler'
require 'json'
Bundler.require

set :port, 8080 unless Sinatra::Base.production?

# Initialize RabbitMQ object & connection appropriate to
# the current env (viz., local vs. prod)
if Sinatra::Base.production?
  configure do
    redis_uri = URI.parse(ENV['REDISCLOUD_URL'])
    REDIS = Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password)
  end
  rabbit = Bunny.new(ENV['CLOUDAMQP_URL'])
else
  REDIS = Redis.new
  rabbit = Bunny.new(automatically_recover: false)
end
rabbit.start
channel = rabbit.create_channel
RABBIT_EXCHANGE = channel.default_exchange
# author_id, tweet_id, tweet_body
NEW_TWEET = channel.queue('new_tweet.tweet_data')
seed = channel.queue('searcher.seed')

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
  tokens = tweet['tweet_body'].split.map(&:downcase)
  tokens.each do |token|
    REDIS.lpush(token, tweet_id)
  end
end

# Parses & indexes tokens from each Tweet body in payload.
def seed_from_payload(payload)
  payload.each do |tweet_body|
    parse_tweet_tokens(tweet_body)
  end
end
