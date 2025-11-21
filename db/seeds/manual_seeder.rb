# Usage:
#   bundle exec rails runner db/seeds/manual_seeder.rb SEED(Integer)

#   example:
#     bundle exec rails runner db/seeds/manual_seeder.rb 121932

require Rails.root.join("db", "seeds", "record_creation_api.rb")

if (ARGV.size < 1)
  seeder = RecordCreator.new() 
else
  begin
    seeder = RecordCreator.new(Integer(ARGV[0]))
  rescue => e
    puts "Failed to convert seed to integer"
    exit(1)
  end
end

puts "The seeder is instantiated in a variable called seeder"

binding.pry

"this is a hack to ensure the script does not encounter a race condition between exiting and binding.pry"
