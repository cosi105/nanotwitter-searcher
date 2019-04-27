# This file is a DRY way to set all of the requirements
# that our tests will need, as well as a before statement
# that purges the database and creates fixtures before every test

ENV['APP_ENV'] = 'test'
require 'simplecov'
SimpleCov.start
require 'minitest/autorun'
require './app'
require 'pry-byebug'

def app
  Sinatra::Application
end

def publish_tweet(tweet)
  RABBIT_EXCHANGE.publish(tweet, routing_key: NEW_TWEET.name)
  sleep 3
end

describe 'NanoTwitter' do
  include Rack::Test::Methods
  before do
    REDIS.flushall
    @tweet_id = 0
    @tweet_body = 'scalability is the best'
    @tweet = { tweet_id: @tweet_id, tweet_body: @tweet_body }.to_json
  end

  it 'can tokenize a single tweet' do
    parse_tweet_tokens(JSON.parse(@tweet))
    @tweet_body.split.each do |token|
      REDIS.lrange(token, 0, -1).must_equal ['0']
    end
  end

  it 'can tokenize multiple tweets' do
    parse_tweet_tokens(JSON.parse(@tweet))
    tweet2 = {
      tweet_id: 1,
      tweet_body: 'i love scalability'
    }.to_json
    parse_tweet_tokens(JSON.parse(tweet2))
    target_hash = {
      scalability: %w[1 0],
      is: ['0'],
      the: ['0'],
      best: ['0'],
      i: ['1'],
      love: ['1']
    }
    actual_hash = Hash.new
    REDIS.keys.each { |token| actual_hash[token.to_sym] = REDIS.lrange(token, 0, -1) }
    target_hash.must_equal actual_hash
  end

  it 'can parse a tweet from the queue' do
    publish_tweet(@tweet)
    @tweet_body.split.each do |token|
      REDIS.lrange(token, 0, -1).must_equal ['0']
    end
  end

  it 'can parse multiple tweets from the queue' do
    publish_tweet(@tweet)
    tweet2 = {
      tweet_id: 1,
      tweet_body: 'i love scalability'
  }.to_json
    publish_tweet(tweet2)
    target_hash = {
      scalability: %w[1 0],
      is: ['0'],
      the: ['0'],
      best: ['0'],
      i: ['1'],
      love: ['1']
    }
    actual_hash = Hash.new
    REDIS.keys.each { |token| actual_hash[token.to_sym] = REDIS.lrange(token, 0, -1) }
    target_hash.must_equal actual_hash
  end

  it 'can parse multiple tweets from the queue' do
    publish_tweet(@tweet)
    tweet2 = {
      tweet_id: 1,
      tweet_body: 'i love SCALABILITY'
    }.to_json
    publish_tweet(tweet2)
    target_hash = {
      scalability: %w[1 0],
      is: ['0'],
      the: ['0'],
      best: ['0'],
      i: ['1'],
      love: ['1']
    }
    actual_hash = Hash.new
    REDIS.keys.each { |token| actual_hash[token.to_sym] = REDIS.lrange(token, 0, -1) }
    target_hash.must_equal actual_hash
  end

end
