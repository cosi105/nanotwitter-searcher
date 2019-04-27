# NanoTwitter: Searcher

This microservice is responsible for effectively keeping a map of every token in every tweet to the ID of every tweet it appears in.

Production deployment: https://nano-twitter-searcher.herokuapp.com/

[![Codeship Status for cosi105/searcher](https://app.codeship.com/projects/a08bef20-4aae-0137-111f-3ef76e2b4548/status?branch=master)](https://app.codeship.com/projects/338620)
[![Maintainability](https://api.codeclimate.com/v1/badges/4cc4fb45232fbd957657/maintainability)](https://codeclimate.com/github/cosi105/searcher/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/4cc4fb45232fbd957657/test_coverage)](https://codeclimate.com/github/cosi105/searcher/test_coverage)

## Subscribed Queues

### new\_tweet.tweet\_data

- author_id
- tweet_id
- tweet_body

## Caches

### word: [tweet_ids]

## Routes
