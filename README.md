# NanoTwitter: Searcher

This microservice is responsible for effectively keeping a map of every token in every tweet to the ID of every tweet it appears in.

Production deployment: https://nano-twitter-searcher.herokuapp.com/

[![Codeship Status for cosi105/NanoTwitter](https://app.codeship.com/projects/ec59bc70-1c93-0137-a172-0eda4e30ac77/status?branch=master)](https://app.codeship.com/projects/328870)
[![Maintainability](https://api.codeclimate.com/v1/badges/5156885903d76b6a4e64/maintainability)](https://codeclimate.com/github/cosi105/NanoTwitter/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/5156885903d76b6a4e64/test_coverage)](https://codeclimate.com/github/cosi105/NanoTwitter/test_coverage)

## Queues

### new\_tweet.tweet\_data

- author_id
- tweet_id
- tweet_body

## Cache

### word: [tweet_ids]