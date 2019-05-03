# Searcher Micro-Service (port 8083)

require 'bundler'
require 'json'
Bundler.require
require './cache_seeder'

set :port, 8083 unless Sinatra::Base.production?

def redis_from_uri(key)
  uri = URI.parse(ENV[key])
  Redis.new(host: uri.host, port: uri.port, password: uri.password)
end

# Initialize RabbitMQ object & connection appropriate to
# the current env (viz., local vs. prod)
if Sinatra::Base.production?
  configure do
    SHARDS = (1..8).to_a.map { |i| redis_from_uri("REDIS_#{i}_URL") }
  end
  rabbit = Bunny.new(ENV['CLOUDAMQP_URL'])
else
  SHARDS = [6387, 6391, 6392, 6393, 6394, 6395, 6396, 6397].map { |i| Redis.new(port: i)}
  rabbit = Bunny.new(automatically_recover: false)
end
rabbit.start
channel = rabbit.create_channel
RABBIT_EXCHANGE = channel.default_exchange
# author_id, tweet_id, tweet_body
NEW_TWEET = channel.queue('new_tweet.searcher.tweet_data')
SEARCH_HTML = channel.queue('searcher.html')

cache_purge = channel.queue('cache.purge.searcher')
cache_purge.subscribe(block: false) { REDIS.flushall }

# Extracts Tweet body from payload & indexes its tokens.
NEW_TWEET.subscribe(block: false) do |delivery_info, properties, body|
  parse_tweet_tokens(JSON.parse(body))
end

def get_shard(token)
  SHARDS[token[0].ord % SHARDS.count]
end

def parse_tweet_tokens(tweet)
  tweet_id = tweet['tweet_id']
  tokens = tweet['tweet_body'].split.map { |token| token.downcase.gsub(/[^a-z ]/, '') }.uniq
  payload = { tweet_id: tweet_id, tokens: tokens }.to_json
  RABBIT_EXCHANGE.publish(payload, routing_key: SEARCH_HTML.name)
  tokens.each { |token| get_shard(token).rpush(token, tweet_id) }
  puts "Parsed tweet #{tweet['tweet_id']}"
end

get '/search' do
  token = params[:token]
  page_num = params[:page_num].to_i
  page_size = params[:page_size].to_i

  start = page_size * (page_num - 1)
  finish = page_size * page_num
  get_shard(token).lrange(token, start, finish - 1).to_json
end
