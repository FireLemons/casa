# Usage:
#   bundle exec rails runner db/seeds/manual_seeder.rb SEED(Integer)

#   example:
#     bundle exec rails runner db/seeds/manual_seeder.rb 121932

require Rails.root.join("db/seeds/record_creation_api.rb")

if ARGV.size < 1
  seeder = RecordCreator.new
else
  begin
    seeder = RecordCreator.new(Integer(ARGV[0]))
  rescue => e
    Rails.logger.fatal "Failed to convert seed to integer"
    exit(1)
  end
end

Rails.logger.info "The seeder is instantiated in a variable called seeder"

binding.pry # rubocop:disable Lint/Debugger

"this is a hack to ensure the script does not encounter a race condition between exiting and binding.pry"
