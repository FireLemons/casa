class RecordCreator
  NONSEEDED_RECORD_TABLES = {
    "ApiCredential" => true,
    "LoginActivity" => true,
    "SentEmail" => true,
    "SmsNotificationEvent" => true
  }

  DEFAULT_PASSWORD = "12345678"

  def initialize(seed = nil)
    Rails.application.eager_load!
    @pre_seeding_record_count = getRecordCounts
    @random = seed.nil? ? Random.new : Random.new(seed)
    Faker::Config.random = @random
    Faker::Config.locale = "en-US" # only allow US phone numbers
  end

  def getSeededRecordCounts
    seeded_record_count_diff = diffSeededRecordCounts(getCreatedRecordCounts)

    seeded_record_count_diff.each do |record_type_name, record_count|
      if record_count == 0
        seeded_record_count_diff.delete(record_type_name)
      end
    end

    seeded_record_count_diff
  end

  def seed_additional_expense(case_contact: nil, case_contact_id: nil)
    if case_contact.nil? && case_contact_id.nil?
      raise ArgumentError.new("case_contact: or case_contact_id: is required")
    elsif !case_contact.nil? && !case_contact_id.nil?
      raise ArgumentError.new("cannot use case_contact: and case_contact_id:")
    end

    other_expense_amount = @random.rand(1..40) + @random.rand.round(2)
    other_expenses_describe = Faker::Commerce.product_name

    if !case_contact.nil?
      AdditionalExpense.create(other_expense_amount:, other_expenses_describe:, case_contact:)
    else
      AdditionalExpense.create(other_expense_amount:, other_expenses_describe:, case_contact_id:)
    end
  end

  def seed_additional_expenses(case_contacts: nil, case_contact_ids: nil, count: 0)
    if case_contacts.nil? && case_contact_ids.nil?
      raise ArgumentError.new("case_contacts: or case_contact_ids: is required")
    elsif !case_contacts.nil? && !case_contact_ids.nil?
      raise ArgumentError.new("cannot use case_contacts: and case_contact_ids:")
    end

    created_additional_expense_ids = []

    if !case_contacts.nil?
      if !case_contacts.is_a?(ActiveRecord::Relation)
        raise TypeError.new("param case_contacts must be an ActiveRecord::Relation")
      elsif case_contacts.empty?
        raise ArgumentError.new("param case_contacts must contain at least one case contact")
      end

      case_contact_ids = case_contacts.to_a.map do |case_contact|
        case_contact.id
      end
    end

    if !case_contact_ids.is_a?(Array)
      raise TypeError.new("param case_contact_ids: must be an array")
    elsif case_contact_ids.length === 0
      raise RangeError.new("param case_contact_ids: must contain at least one element")
    end

    count.times do
      created_additional_expense_ids.push(seed_additional_expense(case_contact_id: pick_random_element(case_contact_ids)).id)
    end

    created_additional_expense_ids
  end

  def seed_address(user: nil, user_id: nil)
    if user.nil? && user_id.nil?
      raise ArgumentError.new("user: or user_id: is required")
    elsif !user.nil? && !user_id.nil?
      raise ArgumentError.new("cannot use user: and user_id:")
    end

    address = Faker::Address.full_address

    if user.nil?
      user = User.find(user_id)
    end

    unless user.address.nil?
      raise ActiveRecord::RecordNotUnique.new("The specified user already has an address")
    end

    Address.create(content: address, user:)
  end

  def seed_addresses(users: nil, user_ids: nil, count: 0)
    if users.nil? && user_ids.nil?
      raise ArgumentError.new("users: or user_ids: is required")
    elsif !users.nil? && !user_ids.nil?
      raise ArgumentError.new("cannot use users: and user_ids:")
    end

    if count <= 0
      return []
    end

    created_address_ids = []

    if !users.nil?
      if !users.is_a?(ActiveRecord::Relation)
        raise TypeError.new("param users must be an ActiveRecord::Relation")
      elsif users.empty?
        raise ArgumentError.new("param users must contain at least one user")
      end

      user_ids_copy = users.to_a.map do |user|
        user.id
      end
    elsif !user_ids.is_a?(Array)
      raise TypeError.new("param user_ids: must be an array")
    elsif user_ids.length === 0
      raise RangeError.new("param user_ids: must contain at least one element")
    else
      user_ids_copy = user_ids.clone
    end

    while count > 0 && user_ids_copy.size > 0
      begin
        new_address = seed_address(user_id: pop_random(user_ids_copy))
        created_address_ids.push(new_address.id) if new_address.persisted?
        count -= 1
      rescue
        # do nothing
      end
    end

    if created_address_ids.size == 0
      raise ActiveRecord::RecordNotUnique.new("Failed to create any address. See output above for more details.")
    end

    created_address_ids
  end

  def seed_casa_org
    county = "#{Faker::Name.neutral_first_name} County"

    CasaOrg.create(address: Faker::Address.full_address, name: county)
  end

  def seed_casa_orgs(count: 0)
    if count <= 0
      return []
    end

    seeded_casa_orgs = []

    count.times do
      begin
        new_org = seed_casa_org
        seeded_casa_orgs.push(new_org) if new_org.persisted?
      rescue
        # do nothing
      end
    end

    if seeded_casa_orgs.size == 0
      raise ActiveRecord::RecordNotUnique.new("Failed to create any casa org. See output above for more details.")
    end

    seeded_casa_orgs
  end

  private

  def diffSeededRecordCounts(updated_record_counts)
    seeded_record_counts = {}

    updated_record_counts.each do |record_type_name, new_record_count|
      next if NonSeededRecordTables.has_key?(record_type_name)

      if @pre_seeding_record_count.has_key?(record_type_name)
        old_count = @pre_seeding_record_count[record_type_name]

        seeded_record_counts[record_type_name] = new_record_count - old_count
      end
    end

    seeded_record_counts
  end

  def getRecordCounts
    record_counts = {}

    ApplicationRecord.descendants.each do |record_type|
      count = record_type.count
      record_name = record_type.name

      next if record_type.abstract_class?
      record_counts[record_name] = count
    end

    record_counts
  end

  def pick_random_element(arr)
    arr.sample(random: @random)
  end

  def pop_random(arr)
    arr.delete_at(@random.rand(arr.size))
  end
end

# # Seeder API
#
#  A File containing functions that satisfy:
#  - each function creates only one kind of record
#  - each function's randomness is seeded
#  - 2 functions per relevant model
#   - one to create a single record of the model
#    - if a record requires other records to exist they are passed in as an argument to the function
#     - accepts an active record object or a database id for each required object
#     - error checking to make sure each of the required objects is present
#     - returns the new activerecord object created
#   - one to create n records of the model
#    - if a record requires other records to exist they are passed in as an argument to the function
#    - the collection(s) are completely error checked so no partial record creation is possible
#    - returns an array of the ids of the records created

#
# all_casa_admins
# banners
# casa_case_contact_types
# casa_case_emancipation_categories
# casa_cases
# casa_cases_emancipation_options
# case_assignments
# case_contact_contact_types
# case_contacts
# case_court_orders
# case_group_memberships
# case_groups
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
# languages
# learning_hour_topics
# learning_hour_types
# learning_hours
# login_activities
# mileage_rates
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
