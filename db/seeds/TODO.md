try to create new addresses when possible

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
