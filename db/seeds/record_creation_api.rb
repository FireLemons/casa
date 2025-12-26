# # Seeder API
#
#  Seeding functions satisfy:
#  - each function creates one kind of record
#  - each function's randomness is seeded
#  - 2 functions per model
#   - one to create a single record of the model
#    - if a record requires other records to exist they are passed in as an argument to the function
#     - accepts an active record object or a database id for each required object
#     - an error is thrown when the parameters are invalid
#    - returns the new activerecord object created
#    - throws an error if the record could not be seeded
#   - one to create n records of the model
#    - if a record requires other records to exist they are passed in as an argument to the function
#     - accepts an active record collection or an array of database ids for each required object
#     - an error is thrown when the parameters are invalid
#    - returns an array containing the ids of the records created and exceptions for records that weren't created

class RecordCreator
  DEFAULT_PASSWORD = "12345678"

  def initialize(seed: nil, extra_try_count: 0)
    if ! max_retry_count.is_a? Integer
      raise TypeError.new("param extra_try_count: must be an integer")
    elsif max_retry_count < 0
      raise RangeError.new("param extra_try_count: must be positive")
    end

    Rails.application.eager_load!
    @MAX_RETRY_COUNT = max_retry_count
    @pre_seeding_record_count = get_record_counts
    @random = seed.nil? ? Random.new : Random.new(seed)
    Faker::Config.random = @random
    Faker::Config.locale = "en-US" # only allow US phone numbers
  end

  def getSeededRecordCounts
    seeded_record_count_diff = diffSeededRecordCounts(get_record_counts)

    seeded_record_count_diff.each do |record_type_name, record_count|
      if record_count == 0
        seeded_record_count_diff.delete(record_type_name)
      end
    end
    get_record_counts
  end

  def seed_additional_expense(case_contact: nil, case_contact_id: nil)
    validate_seed_single_record_required_model_params("case_contact", case_contact, case_contact_id)

    other_expense_amount = @random.rand(1..40) + @random.rand.round(2)
    other_expenses_describe = Faker::Commerce.product_name

    if !case_contact.nil?
      AdditionalExpense.create!(other_expense_amount:, other_expenses_describe:, case_contact_id: case_contact.id)
    else
      AdditionalExpense.create!(other_expense_amount:, other_expenses_describe:, case_contact_id:)
    end
  end

  def seed_additional_expenses(case_contacts: nil, case_contact_ids: nil, count: 0)
    validated_case_contacts = validate_seed_n_records_required_model_params("case_contact", "case_contacts", case_contacts, case_contact_ids)
    validated_case_contacts_as_id_array = model_collection_as_id_array(validated_case_contacts)

    try_seed_many(count) do
      seed_additional_expense(case_contact_id: seeded_random_sample(validated_case_contacts_as_id_array))
    end
  end

  def seed_address(user: nil, user_id: nil)
    validate_seed_single_record_required_model_params("user", user, user_id)

    address = Faker::Address.full_address

    if user.nil?
      user = User.find(user_id)
    end

    if user.address.nil?
      Address.create!(content: address, user:)
    else
      user.address.update(content: address)
      user.address
    end
  end

  def seed_addresses(users: nil, user_ids: nil, count: 0)
    validated_users = validate_seed_n_records_required_model_params("user", "users", users, user_ids)
    validated_users_as_model_array = model_collection_as_model_array(validated_users, User)

    users_with_addresses = []
    users_without_addresses = []

    ordered_users = order_users_for_address_seeding(validated_users_as_model_array)

    try_seed_many(count) do |i|
      seed_address(user: ordered_users[i % ordered_users.size])
    end
  end

  def seed_all_casa_admin
    AllCasaAdmin.create!(email: Faker::Internet.email, password: DEFAULT_PASSWORD, password_confirmation: DEFAULT_PASSWORD)
  end

  def seed_all_casa_admins(count: 0)
    try_seed_many(count) do
      seed_all_casa_admin
    end
  end

  def seed_banner(casa_org: nil, casa_org_id: nil, casa_admin: nil, casa_admin_id: nil)
    validate_seed_single_record_required_model_params("casa_admin", casa_admin, casa_admin_id)
    validate_seed_single_record_required_model_params("casa_org", casa_org, casa_org_id)

    if casa_org_id.nil?
      casa_org_id = casa_org.id
    end

    if casa_admin.nil?
      casa_admin = CasaAdmin.find(casa_admin_id)
    elsif !casa_admin.casa_admin?
      raise ArgumentError.new("param casa_admin must be an admin user")
    end

    banner_name = Faker::Lorem.words(number: 2)
    banner_message = Faker::Lorem.sentence
    banner_expiration_date = seeded_random_banner_expiration_date

    existing_active_banner = Banner.where(active: true)
    existing_active_banner.update_all(active: false)

    begin
      new_banner = Banner.create!(active: true, casa_org_id:, content: banner_message, expires_at: banner_expiration_date, name: banner_name, user: casa_admin)
    rescue => exception
      existing_active_banner.update_all(active: true)
      raise exception
    end

    new_banner
  end

  def seed_banners(casa_orgs: nil, casa_org_ids: nil, casa_admins: nil, casa_admin_ids: nil, count: 0)
    validated_casa_admins = validate_seed_n_records_required_model_params("casa_admin", "casa_admins", casa_admins, casa_admin_ids)
    validated_casa_admins_as_id_array = model_collection_as_id_array(validated_casa_admins)
    validated_casa_orgs = validate_seed_n_records_required_model_params("casa_org", "casa_orgs", casa_orgs, casa_org_ids)
    validated_casa_orgs_as_id_array = model_collection_as_id_array(validated_casa_orgs)

    try_seed_many(count) do
      seed_banner(casa_admin_id: seeded_random_sample(validated_casa_admins_as_id_array), casa_org_id: seeded_random_sample(validated_casa_orgs_as_id_array))
    end
  end

  def seed_casa_case(casa_org: nil, casa_org_id: nil)
    validate_seed_single_record_required_model_params("casa_org", casa_org, casa_org_id)

    birth_month = seeded_random_youth_birth_month
    case_number = seeded_random_casa_case_number
    date_in_care = Faker::Date.between(from: birth_month, to: Time.zone.today)

    Faker::Address.full_address

    if casa_org_id.nil?
      casa_org_id = casa_org.id
    end

    CasaCase.create!(birth_month_year_youth: birth_month, case_number:, casa_org_id:, date_in_care:)
  end

  def seed_casa_cases(casa_orgs: nil, casa_org_ids: nil, count: 0)
    validated_casa_orgs = validate_seed_n_records_required_model_params("casa_org", "casa_orgs", casa_orgs, casa_org_ids)
    validated_casa_orgs_as_id_array = model_collection_as_id_array(validated_casa_orgs)

    try_seed_many(count) do
      seed_casa_case(casa_org_id: seeded_random_sample(validated_casa_orgs_as_id_array))
    end
  end

  def seed_casa_case_contact_type(casa_case: nil, casa_case_id: nil, contact_type: nil, contact_type_id: nil)
    validate_seed_single_record_required_model_params("casa_case", casa_case, casa_case_id)
    validate_seed_single_record_required_model_params("contact_type", contact_type, contact_type_id)

    if casa_case_id.nil?
      casa_case_id = casa_case.id
    end

    if contact_type_id.nil?
      contact_type_id = contact_type.id
    end

    CasaCaseContactType.create!(casa_case_id:, contact_type_id:)
  end

  def seed_casa_org
    county = "#{Faker::Name.neutral_first_name} County"

    CasaOrg.create!(address: Faker::Address.full_address, name: county)
  end

  def seed_casa_orgs(count: 0)
    try_seed_many(count) do
      seed_casa_org
    end
  end

  def seed_case_group(casa_cases: nil, casa_case_ids: nil, casa_org: nil, casa_org_id: nil)
    validate_seed_single_record_required_model_params("casa_org", casa_org, casa_org_id)
    validated_casa_cases = validate_seed_n_records_required_model_params("casa_case", "casa_cases", casa_cases, casa_case_ids)

    unless validated_casa_cases.is_a?(ActiveRecord::Relation)
      validated_casa_cases = CasaCase.find(validated_casa_cases)
    end

    name = "The #{Faker::Name.last_name} Siblings"

    if casa_org_id.nil?
      casa_org_id = casa_org.id
    end

    new_case_group = CaseGroup.new(casa_org_id:, name:)

    new_case_group.casa_cases << validated_casa_cases
    new_case_group.save!

    new_case_group
  end

  def seed_case_groups(casa_cases: nil, casa_case_ids: nil, casa_orgs: nil, casa_org_ids: nil, count: 0)
    validated_casa_cases = validate_seed_n_records_required_model_params("casa_case", "casa_cases", casa_cases, casa_case_ids)
    validated_casa_orgs = validate_seed_n_records_required_model_params("casa_org", "casa_orgs", casa_orgs, casa_org_ids)
    validated_casa_cases_as_id_array = model_collection_as_id_array(validated_casa_cases)
    validated_casa_orgs_as_id_array = model_collection_as_id_array(validated_casa_orgs)

    grouped_casa_case_ids = form_case_groups(validated_casa_cases_as_id_array, count)

    try_seed_many(count) do |i|
      seed_case_group(casa_case_ids: grouped_casa_case_ids[i], casa_org_id: seeded_random_sample(validated_casa_orgs_as_id_array))
    end
  end

  def seed_language(casa_org: nil, casa_org_id: nil)
    validate_seed_single_record_required_model_params("casa_org", casa_org, casa_org_id)

    if casa_org_id.nil?
      casa_org_id = casa_org.id
    end

    Language.create!(name: Faker::Nation.language, casa_org_id:)
  end

  def seed_languages(casa_orgs: nil, casa_org_ids: nil, count: 0)
    validated_casa_orgs = validate_seed_n_records_required_model_params("casa_org", "casa_orgs", casa_orgs, casa_org_ids)
    validated_casa_orgs_as_id_array = model_collection_as_id_array(validated_casa_orgs)

    try_seed_many(count) do
      seed_language(casa_org_id: seeded_random_sample(validated_casa_orgs_as_id_array))
    end
  end

  def seed_mileage_rate(casa_org: nil, casa_org_id: nil)
    validate_seed_single_record_required_model_params("casa_org", casa_org, casa_org_id)

    if casa_org_id.nil?
      casa_org_id = casa_org.id
    end

    MileageRate.create!(amount: seeded_random_change_amount, casa_org_id:, effective_date: Faker::Date.backward)
  end

  def seed_mileage_rates(casa_orgs: nil, casa_org_ids: nil, count: 0)
    validated_casa_orgs = validate_seed_n_records_required_model_params("casa_org", "casa_orgs", casa_orgs, casa_org_ids)
    validated_casa_orgs_as_id_array = model_collection_as_id_array(validated_casa_orgs)

    try_seed_many(count) do
      seed_mileage_rate(casa_org_id: seeded_random_sample(validated_casa_orgs_as_id_array))
    end
  end

  private

  def count_cases_available_to_form_groups_with_3_or_more_members(casa_case_array_cursor, casa_case_array_size, unformed_group_count)
    available_cases_for_groups_count = casa_case_array_size - casa_case_array_cursor

    available_cases_for_groups_count - (2 * unformed_group_count)
  end

  def diffSeededRecordCounts(updated_record_counts)
    seeded_record_counts = {}

    updated_record_counts.each do |record_type_name, new_record_count|
      if @pre_seeding_record_count.has_key?(record_type_name)
        old_count = @pre_seeding_record_count[record_type_name]

        seeded_record_counts[record_type_name] = new_record_count - old_count
      end
    end

    seeded_record_counts
  end

  def form_case_groups(casa_case_ids, group_count)
    if casa_case_ids.size < group_count * 2
      form_case_groups_sample(casa_case_ids, group_count)
    else
      form_case_groups_divide(casa_case_ids, group_count)
    end
  end

  def form_case_groups_divide(casa_case_ids, group_count)
    case_groups = []
    shuffled_casa_cases = seeded_random_shuffle(casa_case_ids)

    unconsumed_casa_case_ids_starting_index = 0

    group_count.times do
      group_size = 2
      extra_case_count = count_cases_available_to_form_groups_with_3_or_more_members(unconsumed_casa_case_ids_starting_index, casa_case_ids.size, group_count - case_groups.size)

      # this distribution comes from census data in the US
      # in sibling groups about 50% of the groups have 2 siblings, 30% have 3, 20% have 4 or more
      if extra_case_count > 0
        group_size += @random.rand(2)

        if group_size > 2 && extra_case_count > 1 && @random.rand(5) > 1
          group_size += 1
        end
      end

      casa_case_group = shuffled_casa_cases.slice(unconsumed_casa_case_ids_starting_index, group_size)
      unconsumed_casa_case_ids_starting_index += casa_case_group.size

      case_groups.push(casa_case_group)
    end

    case_groups
  end

  def form_case_groups_sample(casa_case_ids, group_count)
    case_groups = []

    group_count.times do
      case_groups.push(casa_case_ids.sample(2, random: @random))
    end

    case_groups
  end

  def get_record_counts
    record_counts = {}

    ApplicationRecord.descendants.each do |record_type|
      count = record_type.count
      record_name = record_type.name

      next if record_type.abstract_class?

      record_counts[record_name] = count
    end

    record_counts
  end

  def model_collection_as_id_array(model_collection)
    if model_collection.is_a?(ActiveRecord::Relation)
      model_collection.to_a.map do |model|
        model.id
      end
    else
      model_collection.clone
    end
  end

  def model_collection_as_model_array(model_collection, model_class = nil)
    if model_collection.is_a?(ActiveRecord::Relation)
      model_collection.to_a
    else
      if model_class.nil?
        raise ArgumentError.new("param model_class is required when passing an array of ids")
      end

      model_collection.clone.map do |model_id|
        model_class.find(model_id)
      end
    end
  end

  def order_users_for_address_seeding(users)
    users_with_addresses = []
    users_without_addresses = []

    users.each do |user|
      if user.address.nil?
        users_without_addresses.push(user)
      else
        users_with_addresses.push(user)
      end
    end

    seeded_random_shuffle!(users_without_addresses) + seeded_random_shuffle!(users_with_addresses)
  end

  def seeded_random_banner_expiration_date
    (@random.rand < 0.66) ? nil : Faker::Date.between( # chance of being nil measured from prod data Nov 24, 2025
      from: 1.week.from_now,
      to: 6.months.from_now
    )
  end

  def seeded_random_casa_case_number
    "#{Faker::Alphanumeric.alphanumeric(number: 4).upcase}-#{Faker::Alphanumeric.alphanumeric(number: 4).upcase}-#{Faker::Alphanumeric.alphanumeric(number: 4).upcase}"
  end

  def seeded_random_change_amount
    @random.rand(100) * 0.01
  end

  def seeded_random_pop(arr)
    arr.delete_at(@random.rand(arr.size))
  end

  def seeded_random_sample(arr)
    arr.sample(random: @random)
  end

  def seeded_random_shuffle(arr)
    arr.shuffle(random: @random)
  end

  def seeded_random_shuffle!(arr)
    arr.shuffle!(random: @random)
  end

  def seeded_random_youth_birth_month
    (@random.rand(20) < 1) ? Faker::Date.birthday(min_age: 18, max_age: 21) : Faker::Date.birthday(min_age: 0, max_age: 18)
  end

  def try_seed_many(count, &seed_expression)
    seed_results = []

    loop_count = 0
    successful_seed_count = 0

    while loop_count < count + @MAX_RETRY_COUNT && successful_seed_count < count
      begin
        new_record = seed_expression.call(loop_count)
        seed_results.push(new_record.id)
        successful_seed_count += 1
      rescue => exception
        seed_results.push(exception)
      end

      loop_count += 1
    end

    seed_results
  end

  def validate_seed_single_record_required_model_params(model_lowercase_name, model_param_object, model_param_id)
    if model_param_object.nil? && model_param_id.nil?
      raise ArgumentError.new("#{model_lowercase_name}: or #{model_lowercase_name}_id: is required")
    elsif !model_param_object.nil? && !model_param_id.nil?
      raise ArgumentError.new("cannot use #{model_lowercase_name}: and #{model_lowercase_name}_id:")
    end
  end

  def validate_seed_n_records_required_model_params(model_lowercase_name, model_lowercase_plural_name, model_param_object_collection, model_param_id_array)
    if model_param_object_collection.nil? && model_param_id_array.nil?
      raise ArgumentError.new("#{model_lowercase_plural_name}: or #{model_lowercase_name}_ids: is required")
    elsif !model_param_object_collection.nil? && !model_param_id_array.nil?
      raise ArgumentError.new("cannot use #{model_lowercase_plural_name}: and #{model_lowercase_name}_ids:")
    elsif !model_param_object_collection.nil?
      if !model_param_object_collection.is_a?(ActiveRecord::Relation)
        raise TypeError.new("param #{model_lowercase_plural_name}: must be an ActiveRecord::Relation")
      elsif model_param_object_collection.empty?
        raise ArgumentError.new("param #{model_lowercase_plural_name}: must contain at least one #{model_lowercase_name}")
      else
        model_param_object_collection
      end
    elsif !model_param_id_array.is_a?(Array)
      raise TypeError.new("param #{model_lowercase_name}_ids: must be an array")
    elsif model_param_id_array.length === 0
      raise RangeError.new("param #{model_lowercase_name}_ids: must contain at least one element")
    else
      model_param_id_array
    end
  end
end

#
# casa_case_emancipation_categories
# casa_cases_emancipation_options
# case_assignments
# case_contact_contact_types
# case_contacts
# case_court_orders
# case_group_memberships
# checklist_items
# contact_topic_answers
# contact_topics
# contact_type_groups
# contact_types
# court_dates
# delayed_jobs
# emancipation_categories
# emancipation_options
# flipper_features
# flipper_gates
# followups
# fund_requests
# healths
# hearing_types
# judges
# learning_hour_topics
# learning_hour_types
# learning_hours
# login_activities
# notes
# noticed_events
# noticed_notifications
# notifications
# other_duties
# patch_note_groups
# patch_note_types
# patch_notes
# placement_types
# placements
# preference_sets
# sent_emails
# sms_notification_events
# supervisor_volunteers
# task_records
# user_languages
# user_reminder_times
# user_sms_notification_events
# users
