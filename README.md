# NanoTwitter: Searcher

This microservice is responsible for effectively keeping a map of every token in every tweet to the ID of every tweet it appears in.

Production deployment: https://nano-twitter-searcher.herokuapp.com/

[![Codeship Status for cosi105/searcher](https://app.codeship.com/projects/a08bef20-4aae-0137-111f-3ef76e2b4548/status?branch=master)](https://app.codeship.com/projects/338620)
[![Maintainability](https://api.codeclimate.com/v1/badges/4cc4fb45232fbd957657/maintainability)](https://codeclimate.com/github/cosi105/searcher/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/4cc4fb45232fbd957657/test_coverage)](https://codeclimate.com/github/cosi105/searcher/test_coverage)

## Message Queues

| Relation | Queue Name | Payload | Interaction |
| :------- | :--------- | :------ |:--
| Subscribes to | `searcher.seed`        | `[{tweet_id, tweet_body}, ...]`     | For each Tweet in payload, parses `tweet_body` into tokens, then caches mappings of tokens to `tweet_id`'s containing them.
| Subscribes to | `new_tweet.tweet_data` | `{author_id, tweet_id, tweet_body}` | Parses `tweet_body` into tokens, then caches mappings of tokens to `tweet_id`'s containing them.

## Caches

### word: [tweet_ids]

## Routes

## Seeding

The service is subscribed to a `searcher.seed` queue, which the main NanoTwitter app uses to publish all of the tweets in the database. Searcher then goes through every tweet and generates its cached mapping of tokens to tweet IDs.