# Searcher Micro-Service (port 8083)

require 'bundler'
require 'json'
Bundler.require

set :port, 8083 unless Sinatra::Base.production?

# Initialize RabbitMQ object & connection appropriate to
# the current env (viz., local vs. prod)
if Sinatra::Base.production?
  configure do
    uri = URI.parse(ENV['REDIS_URL'])
    REDIS = Redis.new(host: uri.host, port: uri.port, password: uri.password)
  end
  rabbit = Bunny.new(ENV['CLOUDAMQP_URL'])
else
  REDIS = Redis.new(port: 6387)
  rabbit = Bunny.new(automatically_recover: false)
end
rabbit.start
channel = rabbit.create_channel
RABBIT_EXCHANGE = channel.default_exchange
# author_id, tweet_id, tweet_body
NEW_TWEET = channel.queue('new_tweet.searcher.tweet_data')
SEARCH_HTML = channel.queue('searcher.html')
seed = channel.queue('searcher.data.seed')
cache_purge = channel.queue('cache.purge.searcher')

# Parses & indexes tokens from payload.
seed.subscribe(block: false) do |delivery_info, properties, body|
  seed_from_payload(JSON.parse(body))
end

cache_purge.subscribe(block: false) { REDIS.flushall }

# Extracts Tweet body from payload & indexes its tokens.
NEW_TWEET.subscribe(block: false) do |delivery_info, properties, body|
  parse_tweet_tokens(JSON.parse(body))
end

def parse_tweet_tokens(tweet)
  tweet_id = tweet['tweet_id']
  tokens = tweet['tweet_body'].split.map { |token| token.downcase.gsub(/[^a-z ]/, '') }.uniq
  payload = { tweet_id: tweet_id, tokens: tokens }.to_json
  RABBIT_EXCHANGE.publish(payload, routing_key: SEARCH_HTML.name)
  tokens.each { |token| REDIS.lpush(token, tweet_id) }
  puts "Parsed tweet #{tweet['tweet_id']}"
end

# Parses & indexes tokens from each Tweet body in payload.
def seed_from_payload(body)
  body.each do |tweet|
    parse_tweet_tokens(tweet)
  end
end
