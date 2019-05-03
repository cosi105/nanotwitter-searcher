require 'csv'
require 'open-uri'
post '/seed' do
  puts "Caching search data..."
  REDIS.flushall
  whole_csv = CSV.parse(open(params[:csv_url]))
  whole_csv.each do |line|
    key = line[0]
    values = line.drop(1)
    REDIS.rpush(key, values)
  end
  puts "Cached search data!"
end
