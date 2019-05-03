require 'csv'
require 'open-uri'
post '/seed' do
  puts 'Caching search data...'
  [REDIS_EVEN, REDIS_ODD].each(&:flushall) if params[:csv_url][-5] == '1'
  whole_csv = CSV.parse(open(params[:csv_url]))
  whole_csv.each do |line|
    key = line[0]
    values = line.drop(1)
    get_shard(key).rpush(key, values)
  end
  puts 'Cached search data!'
end
