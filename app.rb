# Searcher Micro-Service (port 8083)

require 'bundler'
require 'json'
require 'set'
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

# Extracts Tweet body from payload & indexes its tokens.
NEW_TWEET.subscribe(block: false) do |delivery_info, properties, body|
  parse_tweet_tokens(JSON.parse(body))
end

def parse_tweet_tokens(tweet)
  tweet_id = tweet['tweet_id']
  tokens = tweet['tweet_body'].split.map { |token| token.downcase.gsub(/[^a-z ]/, '') }.to_set
  payload = { tweet_id: tweet_id, tokens: tokens }.to_json
  RABBIT_EXCHANGE.publish(payload, routing_key: SEARCH_HTML.name)
  tokens.each { |token| REDIS.lpush(token, tweet_id) }
  puts "Parsed tweet #{tweet['tweet_id']}"
end
