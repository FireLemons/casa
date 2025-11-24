seed_banner
  check prod for actual chance of banner expiration date being nil
seed_banners
  tests

```
  Failures:

    1) RecordCreator seed_languages with valid parameters has randomness derived from the seed
      Failure/Error: object_class.find(id)
      
      ActiveRecord::RecordNotFound:
        Couldn't find Language with 'id'=#<ActiveRecord::RecordInvalid: Validation failed: Name has already been taken>
      # ./spec/seeds/record_creation_api_spec.rb:1295:in `block in test_multi_object_seed_method_seeded'
      # ./spec/seeds/record_creation_api_spec.rb:1294:in `map'
      # ./spec/seeds/record_creation_api_spec.rb:1294:in `test_multi_object_seed_method_seeded'
      # ./spec/seeds/record_creation_api_spec.rb:1057:in `block (4 levels) in <top (required)>'
      # ./spec/rails_helper.rb:133:in `block (2 levels) in <top (required)>'
      # ./spec/rails_helper.rb:118:in `block (3 levels) in <top (required)>'
      # ./spec/rails_helper.rb:117:in `block (2 levels) in <top (required)>'

  Finished in 4.34 seconds (files took 5.28 seconds to load)
  62 examples, 1 failure

  Failed examples:

  rspec ./spec/seeds/record_creation_api_spec.rb:1054 # RecordCreator seed_languages with valid parameters has randomness derived from the seed

  Randomized with seed 38270
```

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
