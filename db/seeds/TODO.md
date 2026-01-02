seed_casa_case_contact_types
  tests
    it "does not count attempting to create an existing association as a failure" do
    end

Flake
    seed_languages
    with valid parameters
      has randomness derived from the seed (FAILED - 1)

      Failures:

        1) RecordCreator seed_languages with valid parameters has randomness derived from the seed
          Failure/Error: model_class.find(id)
          
          ActiveRecord::RecordNotFound:
            Couldn't find Language with 'id'=#<ActiveRecord::RecordInvalid: Validation failed: Name has already been taken>
          Shared Example Group: "has randomness derived from the seed when generating several of the same type of record" called from ./spec/seeds/record_creation_api_spec.rb:808
          # ./spec/seeds/record_creation_api_spec.rb:45:in `block (4 levels) in <top (required)>'
          # ./spec/seeds/record_creation_api_spec.rb:44:in `map'
          # ./spec/seeds/record_creation_api_spec.rb:44:in `block (3 levels) in <top (required)>'
          # ./spec/rails_helper.rb:133:in `block (2 levels) in <top (required)>'
          # ./spec/rails_helper.rb:118:in `block (3 levels) in <top (required)>'
          # ./spec/rails_helper.rb:117:in `block (2 levels) in <top (required)>'

      Finished in 4.93 seconds (files took 5.14 seconds to load)
      65 examples, 1 failure


check if activerecord arg is persisted
  default throws null reference error

  if model_param_object.nil? && model_param_id.nil?
    raise ArgumentError.new("#{model_lowercase_name}: or #{model_lowercase_name}_id: is required")
  elsif !model_param_object.nil? && !model_param_id.nil?
    raise ArgumentError.new("cannot use #{model_lowercase_name}: and #{model_lowercase_name}_id:")
  elsif model_param_id.nil? && !model_param_object.persisted?
    raise ActiveRecord::RecordNotSaved.new("Value for #{model_lowercase_name}: has not been saved to the database")
  end

Display logins
  Org header
    logins
  Password info
