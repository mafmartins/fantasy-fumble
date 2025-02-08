desc "Fetches data from the ESPN NFL API and upserts it to the database"
task fetch_nfl_data: [ :environment ]  do
  puts "Starting to fetch data from ESPN NFL API..."
  updater = EspnNfl::Updater.new
  result = updater.fetch_and_upsert_all
  puts "Finished fetching data from ESPN NFL API. Result count: #{result.length}"
end
