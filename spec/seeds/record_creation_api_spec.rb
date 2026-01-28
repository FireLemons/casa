require "rails_helper"
require_relative "../../db/seeds/record_creation_api"

RSpec.describe RecordCreator do
  shared_examples "creates the record" do |model_class:, model_name:|
    it "creates one #{model_name}" do
      original_record_count = model_class.count

      expect {
        subject.public_send(method_name, **minimal_valid_params)
      }.to change { model_class.count }.from(original_record_count).to(original_record_count + 1)
    end
  end

  shared_examples "creates the specified number of records" do |model_class:, model_plural_name:|
    it "creates the specified number of #{model_plural_name}" do
      record_generation_count = 2
      params = minimal_valid_params.merge({count: record_generation_count})

      original_record_count = model_class.count

      expect {
        subject.public_send(method_name, **params)
      }.to change { model_class.count }.from(original_record_count).to(original_record_count + record_generation_count)
    end
  end

  shared_examples "has randomness derived from the seed when generating a record" do |*business_data_field_names|
    it "has randomness derived from the seed" do
      record = subject.public_send(method_name, **minimal_valid_params)
      record.destroy

      reset_seeder = RecordCreator.new(seed: RSpec.configuration.seed)

      reseeded_record = reset_seeder.public_send(method_name, **minimal_valid_params)

      test_records_equal(record, reseeded_record, *business_data_field_names)
    end
  end

  shared_examples "has randomness derived from the seed when generating several of the same type of record" do |*business_data_field_names, model_class:|
    it "has randomness derived from the seed" do
      record_id_array = subject.public_send(method_name, **minimal_valid_params)
      record_array = record_id_array.map do |id|
        model_class.find(id)
      end

      record_array.each do |record|
        record.destroy
      end

      reset_subject = RecordCreator.new(seed: RSpec.configuration.seed)

      reseeded_record_id_array = reset_subject.public_send(method_name, **minimal_valid_params)

      reseeded_record_array = reseeded_record_id_array.map do |id|
        model_class.find(id)
      end

      test_record_arrays_equal(record_array, reseeded_record_array, *business_data_field_names)
    end
  end

  shared_examples "multi-record generation returns empty list when requesting to generate a negative number of records" do
    it "returns empty array for negative counts" do
      params = minimal_valid_params.merge({count: -1})

      expect(subject.public_send(method_name, **params)).to eq([])
    end
  end

  shared_examples "returns the generated record" do |model_class:, model_name:|
    it "returns the newly created #{model_name}" do
      new_record = subject.public_send(method_name, **minimal_valid_params)

      expect(new_record).to be_a(model_class)
    end
  end

  shared_examples "returns the ids of the generated records" do |model_class:, model_plural_name:|
    it "returns an array containing the ids of the #{model_plural_name} created" do
      subject.public_send(method_name, **minimal_valid_params).each do |record_id|
        expect {
          model_class.find(record_id)
        }.not_to raise_error
      end
    end
  end

  shared_examples "returns an Exception for each record that failed to generate" do |record_param_name:|
    it "returns an array containing an error for each #{record_param_name} that could not be created" do
      nonexistant_id_params = minimal_valid_params

      if nonexistant_id_params.key?(:count) && nonexistant_id_params.size == 1
      else
        nonexistant_id_params.transform_values! { [-1] }
        nonexistant_id_params[:count] = 2
        error_array = subject.public_send(method_name, **nonexistant_id_params)

        error_array.each do |error|
          expect(error).to be_a(Exception)
        end
      end
    end
  end

  shared_examples "the reference to a required record is present and unambiguous" do |record_param_name:, record_id_param_name:|
    it "throws an error when neither #{record_param_name} or #{record_id_param_name} is used" do
      params = minimal_valid_params.except(*all_record_params.keys)

      expect {
        subject.public_send(method_name, **params)
      }.to raise_error(ArgumentError, /#{record_param_name}: or #{record_id_param_name}: is required/)
    end

    it "throws an error when both #{record_param_name} and #{record_id_param_name} are used" do
      params = minimal_valid_params.merge(all_record_params)

      expect {
        subject.public_send(method_name, **params)
      }.to raise_error(ArgumentError, /cannot use #{record_param_name}: and #{record_id_param_name}:/)
    end
  end

  shared_examples "the reference to a required set of records is present and unambiguous" do |model_name:, records_param_name:, record_id_array_param_name:|
    it "throws an error when both #{records_param_name} and #{record_id_array_param_name} are used" do
      params = minimal_valid_params.merge(all_record_params)

      expect {
        subject.public_send(method_name, **params)
      }.to raise_error(ArgumentError, /cannot use #{records_param_name}: and #{record_id_array_param_name}:/)
    end

    it "throws an error when #{record_id_array_param_name} is an empty array" do
      params = minimal_valid_params.except(records_param_name).merge({record_id_array_param_name => []})

      expect {
        subject.public_send(method_name, **params)
      }.to raise_error(RangeError, /param #{record_id_array_param_name}: must contain at least one element/)
    end

    it "throws an error when #{record_id_array_param_name} is not an array" do
      params = minimal_valid_params.except(records_param_name).merge({record_id_array_param_name => 2})

      expect {
        subject.public_send(method_name, **params)
      }.to raise_error(TypeError, /param #{record_id_array_param_name}: must be an array/)
    end

    it "throws an error when #{records_param_name} is an empty ActiveRecord::Relation" do
      params = minimal_valid_params.except(record_id_array_param_name).merge({records_param_name => all_record_params[records_param_name].none})

      expect {
        subject.public_send(method_name, **params)
      }.to raise_error(ArgumentError, /param #{records_param_name}: must contain at least one #{model_name}/)
    end

    it "throws an error when #{records_param_name} is not an ActiveRecord::Relation" do
      params = minimal_valid_params.except(record_id_array_param_name).merge({records_param_name => 2})

      expect {
        subject.public_send(method_name, **params)
      }.to raise_error(TypeError, /param #{records_param_name}: must be an ActiveRecord::Relation/)
    end

    it "throws an error when neither #{records_param_name} or #{record_id_array_param_name} are used" do
      params = minimal_valid_params.except(*all_record_params.keys)

      expect {
        subject.public_send(method_name, **params)
      }.to raise_error(ArgumentError, /#{records_param_name}: or #{record_id_array_param_name}: is required/)
    end
  end

  subject { RecordCreator.new(seed: RSpec.configuration.seed) }

  describe "constructor" do
    describe "the seed: parameter" do
      it "sets the seed for randomness" do
        record_creator = RecordCreator.new(seed: 1)

        record = record_creator.seed_all_casa_admin
        record.destroy

        reset_seeder = RecordCreator.new(seed: 2)

        record_generated_with_different_seed = reset_seeder.seed_all_casa_admin

        expect(record.attributes.slice("email")).to_not eq(record_generated_with_different_seed.attributes.slice("email"))
      end
    end

    describe "the extra_try_count: parameter" do
      it "sets the extra try count for multi-record creation functions" do
        extra_try_count = 3
        record_creation_count = 4

        record_creator = RecordCreator.new(extra_try_count:)

        record_creation_results = record_creator.seed_additional_expenses(case_contact_ids: [-1], count: record_creation_count)

        expect(record_creation_results.size).to eq(record_creation_count + extra_try_count)
      end

      it "throws an error if the argument is not an integer" do
        expect {
          RecordCreator.new(extra_try_count: "a")
        }.to raise_error(TypeError, /param extra_try_count: must be an integer/)
      end

      it "throws an error if the argument is negative" do
        expect {
          RecordCreator.new(extra_try_count: -1)
        }.to raise_error(RangeError, /param extra_try_count: must be positive/)
      end
    end
  end

  describe "get_record_creation_counts_since_initialization" do
    it "includes the counts of all records created since the RecordCreator's initialization" do
      # trigger lazy init
      subject

      create(:casa_org)
      create(:casa_org)
      create(:casa_org)
      create(:casa_admin)

      seeded_record_counts = subject.get_record_creation_counts_since_initialization

      expect(seeded_record_counts[CasaOrg.name]).to eq 3
      expect(seeded_record_counts[User.name]).to eq 1
      expect(seeded_record_counts[CasaCase.name]).to eq 0
    end
  end

  describe "seed_additional_expense" do
    let(:method_name) { :seed_additional_expense }

    let(:case_contact) { create(:case_contact) }
    let(:minimal_valid_params) { {case_contact:} }

    describe "with valid parameters" do
      include_examples("creates the record", model_class: AdditionalExpense, model_name: "additional expense")
      include_examples("has randomness derived from the seed when generating a record", "other_expense_amount", "other_expenses_describe")
      include_examples("returns the generated record", model_class: AdditionalExpense, model_name: "additional expense")
    end

    describe "with invalid parameters" do
      let(:all_record_params) { {case_contact:, case_contact_id: case_contact.id} }

      include_examples("the reference to a required record is present and unambiguous", record_param_name: :case_contact, record_id_param_name: :case_contact_id)
    end
  end

  describe "seed_additional_expenses" do
    let(:method_name) { :seed_additional_expenses }

    let(:case_contact) { create(:case_contact) }
    let(:minimal_valid_params) {
      case_contact # triggers lazy load

      {case_contacts: CaseContact.all, count: 2}
    }

    describe "with valid parameters" do
      include_examples("creates the specified number of records", model_class: AdditionalExpense, model_plural_name: "additional expenses")
      include_examples("has randomness derived from the seed when generating several of the same type of record", "other_expense_amount", "other_expenses_describe", model_class: AdditionalExpense)
      include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
      include_examples("returns the ids of the generated records", model_class: AdditionalExpense, model_plural_name: "additional expenses")

      it "returns an array containing an error for each additional expense that could not be created" do
        error_array = subject.seed_additional_expenses(case_contact_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(StandardError)
        end
      end
    end

    describe "with invalid parameters" do
      let(:all_record_params) {
        {case_contacts: CaseContact.all, case_contact_ids: case_contact.id}
      }

      include_examples("the reference to a required set of records is present and unambiguous", model_name: "case_contact", records_param_name: :case_contacts, record_id_array_param_name: :case_contact_ids)
    end
  end

  describe "seed_address" do
    let(:method_name) { :seed_address }

    let(:user) { create(:user) }
    let(:minimal_valid_params) { {user_id: user.id} }

    describe "with valid parameters" do
      include_examples("creates the record", model_class: Address, model_name: "address")
      include_examples("has randomness derived from the seed when generating a record", "content")
      include_examples("returns the generated record", model_class: Address, model_name: "address")

      it "updates an address if the user already has an address" do
        user = create(:user)
        Address.create(user:, content: "")

        subject.seed_address(user:)
        expect(user.address.content).not_to eq("")
      end
    end

    describe "with invalid parameters" do
      let(:all_record_params) { {user:, user_id: user.id} }

      include_examples("the reference to a required record is present and unambiguous", record_param_name: :user, record_id_param_name: :user_id)
    end
  end

  describe "seed_addresses" do
    let(:method_name) { :seed_addresses }

    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }
    let(:minimal_valid_params) { {user_ids: [user_a.id, user_b.id], count: 2} }

    describe "with valid parameters" do
      include_examples("creates the specified number of records", model_class: Address, model_plural_name: "addresses")
      include_examples("has randomness derived from the seed when generating several of the same type of record", "content", model_class: Address)
      include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
      include_examples("returns the ids of the generated records", model_class: Address, model_plural_name: "addresses")

      it "associates the new addresses with users without addresses when possible" do
        create(:address, user: create(:user))
        create(:address, user: create(:user))

        users_without_address_count = 4

        users_without_addresses = create_list(:user, users_without_address_count)

        subject.seed_addresses(users: User.all, count: users_without_address_count)

        users_without_address_count.times do |i|
          expect(users_without_addresses[i].address).not_to be_nil
        end
      end

      it "overwrites an existing address if a user already has an address" do
        user_with_address = create(:user)
        create(:user)
        overridden_address = create(:address, content: "", user: user_with_address)

        subject.seed_addresses(users: User.all, count: 2)
        overridden_address.reload

        expect(overridden_address.content).not_to eq("")
      end
    end

    describe "with invalid parameters" do
      let(:all_record_params) {
        {users: User.all, user_ids: [user_a.id, user_b.id]}
      }

      include_examples("the reference to a required set of records is present and unambiguous", model_name: "user", records_param_name: :users, record_id_array_param_name: :user_ids)
    end
  end

  describe "seed_all_casa_admin" do
    let(:method_name) { :seed_all_casa_admin }
    let(:minimal_valid_params) { {} }

    include_examples("creates the record", model_class: AllCasaAdmin, model_name: "all casa admin")
    include_examples("has randomness derived from the seed when generating a record", "email")
    include_examples("returns the generated record", model_class: AllCasaAdmin, model_name: "all casa admin")
  end

  describe "seed_all_casa_admins" do
    let(:method_name) { :seed_all_casa_admins }

    let(:minimal_valid_params) { {} }

    include_examples("creates the specified number of records", model_class: AllCasaAdmin, model_plural_name: "all casa admins")
    include_examples("has randomness derived from the seed when generating several of the same type of record", "email", model_class: AllCasaAdmin)
    include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
    include_examples("returns the ids of the generated records", model_class: AllCasaAdmin, model_plural_name: "all casa admins")

    it "returns an array containing an error for each all casa admin that could not be created" do
      subject.seed_all_casa_admins(count: 2)

      subject = RecordCreator.new(seed: RSpec.configuration.seed)

      # Resetting the RecordCreator with the same seed
      # should result in all casa admins with duplicate emails
      # but all casa admins require unique emails
      # thus causing the errors
      error_array = subject.seed_all_casa_admins(count: 2)

      error_array.each do |error|
        expect(error).to be_a(Exception)
      end
    end
  end

  describe "seed_banner" do
    let(:method_name) { :seed_banner }

    let(:casa_admin) { create(:casa_admin) }
    let(:casa_org) { create(:casa_org) }
    let(:minimal_valid_params) { {casa_admin:, casa_org:} }

    describe "with valid parameters" do
      include_examples("creates the record", model_class: Banner, model_name: "banner")
      include_examples("has randomness derived from the seed when generating a record", "content", "expires_at", "name")
      include_examples("returns the generated record", model_class: Banner, model_name: "banner")

      it "marks all existing active banners as inactive" do
        casa_org = create(:casa_org)
        banner_creator = create(:casa_admin, casa_org:)

        existing_active_banner = create(:banner, active: true, casa_org:, user: banner_creator)

        subject.seed_banner(casa_admin: banner_creator, casa_org:)

        expect(existing_active_banner.active).to be(true)
      end

      it "sets the new banner as active" do
        casa_org = create(:casa_org)
        banner_creator = create(:casa_admin, casa_org:)

        expect(subject.seed_banner(casa_admin: banner_creator, casa_org:).active).to be(true)
      end
    end

    describe "with invalid parameters" do
      describe "with invalid casa_admin parameters" do
        let(:all_record_params) { {casa_admin:, casa_admin_id: casa_admin.id} }

        include_examples("the reference to a required record is present and unambiguous", record_param_name: :casa_admin, record_id_param_name: :casa_admin_id)

        it "throws an error when a user who is not an admin is used" do
          casa_org = create(:casa_org)
          banner_creator = create(:supervisor, casa_org:)

          expect {
            subject.seed_banner(casa_admin: banner_creator, casa_org:)
          }.to raise_error { |e|
            expect(e).to be_a(ArgumentError).or be_a(ActiveRecord::RecordNotFound)
          }
        end
      end

      describe "with invalid casa_org parameters" do
        let(:all_record_params) { {casa_org:, casa_org_id: casa_org.id} }

        include_examples("the reference to a required record is present and unambiguous", record_param_name: :casa_org, record_id_param_name: :casa_org_id)
      end
    end
  end

  describe "seed_banners" do
    let(:method_name) { :seed_banners }

    let(:casa_org) { create(:casa_org) }
    let(:casa_admin) { create(:casa_admin, casa_org:) }
    let(:minimal_valid_params) {
      casa_admin # triggers lazy load

      {casa_admins: CasaAdmin.all, casa_orgs: CasaOrg.all, count: 2}
    }

    describe "with valid parameters" do
      include_examples("creates the specified number of records", model_class: Banner, model_plural_name: "banners")
      include_examples("has randomness derived from the seed when generating several of the same type of record", "content", "expires_at", "name", model_class: Banner)
      include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
      include_examples("returns the ids of the generated records", model_class: Banner, model_plural_name: "banners")

      it "returns an array containing an error for each banner that could not be created" do
        error_array = subject.seed_banners(casa_admin_ids: [-1], casa_org_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(StandardError)
        end
      end
    end

    describe "with invalid parameters" do
      describe "with invalid parameters for a set of casa_admins" do
        let(:all_record_params) {
          {casa_admins: CasaAdmin.all, casa_admin_ids: casa_admin.id}
        }

        include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_admin", records_param_name: :casa_admins, record_id_array_param_name: :casa_admin_ids)
      end

      describe "with invalid parameters for a set of casa_orgs" do
        let(:all_record_params) {
          {casa_orgs: CasaOrg.all, casa_org_ids: [casa_org.id]}
        }

        include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_org", records_param_name: :casa_orgs, record_id_array_param_name: :casa_org_ids)
      end
    end
  end

  describe "seed_casa_case" do
    let(:method_name) { :seed_casa_case }

    let(:casa_org) { create(:casa_org) }
    let(:minimal_valid_params) { {casa_org:} }

    describe "with valid parameters" do
      include_examples("creates the record", model_class: CasaCase, model_name: "casa case")
      include_examples("has randomness derived from the seed when generating a record", "birth_month_year_youth", "case_number", "date_in_care")
      include_examples("returns the generated record", model_class: CasaCase, model_name: "casa case")

      it "generates values for fields birth_month_year_youth and date_in_care" do
        new_casa_case = subject.seed_casa_case(casa_org: create(:casa_org))

        expect(new_casa_case.birth_month_year_youth).not_to be_nil
        expect(new_casa_case.date_in_care).not_to be_nil
      end
    end

    describe "with invalid parameters" do
      let(:all_record_params) { {casa_org:, casa_org_id: casa_org.id} }

      include_examples("the reference to a required record is present and unambiguous", record_param_name: :casa_org, record_id_param_name: :casa_org_id)
    end
  end

  describe "seed_casa_cases" do
    let(:method_name) { :seed_casa_cases }

    let(:casa_org) { create(:casa_org) }
    let(:minimal_valid_params) {
      casa_org # triggers lazy load

      {casa_orgs: CasaOrg.all, count: 2}
    }

    describe "with valid parameters" do
      include_examples("creates the specified number of records", model_class: CasaCase, model_plural_name: "casa cases")
      include_examples("has randomness derived from the seed when generating several of the same type of record", "birth_month_year_youth", "case_number", "date_in_care", model_class: CasaCase)
      include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
      include_examples("returns the ids of the generated records", model_class: CasaCase, model_plural_name: "banners")

      it "returns an array containing an error for each casa case that could not be created" do
        error_array = subject.seed_casa_cases(casa_org_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(Exception)
        end
      end
    end

    describe "with invalid parameters" do
      let(:all_record_params) {
        {casa_orgs: CasaOrg.all, casa_org_ids: casa_org.id}
      }

      include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_org", records_param_name: :casa_orgs, record_id_array_param_name: :casa_org_ids)
    end
  end

  describe "seed_casa_case_contact_type" do
    let(:method_name) { :seed_casa_case_contact_type }

    let(:casa_case) { create(:casa_case) }
    let(:contact_type) { create(:contact_type) }
    let(:minimal_valid_params) { {casa_case:, contact_type:} }

    describe "with valid parameters" do
      include_examples("creates the record", model_class: CasaCaseContactType, model_name: "casa_case_contact_type")
      include_examples("returns the generated record", model_class: CasaCaseContactType, model_name: "casa_case_contact_type")
    end

    describe "with invalid parameters" do
      describe "with invalid casa case parameters" do
        let(:all_record_params) { {casa_case:, casa_case_id: casa_case.id} }

        include_examples("the reference to a required record is present and unambiguous", record_param_name: :casa_case, record_id_param_name: :casa_case_id)
      end

      describe "with invalid contact type parameters" do
        let(:all_record_params) { {contact_type:, contact_type_id: contact_type.id} }

        include_examples("the reference to a required record is present and unambiguous", record_param_name: :contact_type, record_id_param_name: :contact_type_id)
      end
    end
  end

  describe "seed_casa_case_contact_types" do
    let(:method_name) { :seed_casa_case_contact_types }

    let(:casa_cases) { create_list(:casa_case, 3) }
    let(:contact_types) { create_list(:contact_type, 4) }
    let(:minimal_valid_params) {
      {casa_case_ids: casa_cases.map(&:id), contact_type_ids: contact_types.map(&:id), count: 2}
    }

    describe "with valid parameters" do
      include_examples("creates the specified number of records", model_class: CasaCaseContactType, model_plural_name: "casa case contact types")
      include_examples("has randomness derived from the seed when generating several of the same type of record", "casa_case_id", "contact_type_id", model_class: CasaCaseContactType)
      include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
      include_examples("returns the ids of the generated records", model_class: CasaCaseContactType, model_plural_name: "casa case contact types")

      it "returns an array containing an error for each casa case contact type that could not be created" do
        error_array = subject.seed_casa_case_contact_types(casa_case_ids: [-1], contact_type_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(Exception)
        end
      end

      it "does not count attempting to create an existing association as a failure" do
        record_id_array = subject.seed_casa_case_contact_types(casa_case_ids: casa_cases.map(&:id), contact_type_ids: contact_types.map(&:id), count: 2)

        expect(record_id_array.count { |seed_result| seed_result.is_a?(Integer) }).to be >= 2

        reset_seeder = RecordCreator.new(seed: RSpec.configuration.seed)

        reseeded_record_id_array = reset_seeder.seed_casa_case_contact_types(casa_case_ids: casa_cases.map(&:id), contact_type_ids: contact_types.map(&:id), count: 2)

        expect(reseeded_record_id_array.count { |seed_result| seed_result.is_a?(Integer) }).to be >= 2
      end

      it "adds a special exception to the results when no more casa case contact type combinations are available" do
        seed_results = subject.seed_casa_case_contact_types(casa_case_ids: [casa_cases[0].id], contact_type_ids: [contact_types[0].id], count: 2)

        expect(seed_results).to include(have_attributes(message: "There are no more casa case and contact type id combinations available to make more casa_case_contact_types"))
      end
    end

    describe "with invalid parameters" do
      describe "with invalid parameters for a set of casa_cases" do
        let(:all_record_params) {
          {casa_cases: CasaCase.all, casa_case_ids: casa_cases.map(&:id)}
        }

        include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_case", records_param_name: :casa_cases, record_id_array_param_name: :casa_case_ids)
      end

      describe "with invalid parameters for a set of contact_types" do
        let(:all_record_params) {
          {contact_types: ContactType.all, contact_type_ids: contact_types.map(&:id)}
        }

        include_examples("the reference to a required set of records is present and unambiguous", model_name: "contact_type", records_param_name: :contact_types, record_id_array_param_name: :contact_type_ids)
      end
    end
  end

  describe "seed_casa_case_emancipation_category" do
    let(:method_name) { :seed_casa_case_emancipation_category }

    let(:casa_case) { create(:casa_case) }
    let(:emancipation_category) { create(:emancipation_category) }
    let(:minimal_valid_params) { {casa_case:, emancipation_category:} }

    describe "with valid parameters" do
      include_examples("creates the record", model_class: CasaCaseEmancipationCategory, model_name: "casa_case_emancipation_category")
      include_examples("returns the generated record", model_class: CasaCaseEmancipationCategory, model_name: "casa_case_emancipation_category")

      it "raises an error when the casa_case is not of transition age" do
        casa_case = create(:casa_case, :pre_transition)

        expect {
          subject.seed_casa_case_emancipation_category(casa_case:, emancipation_category:)
        }.to raise_error(RangeError, /Casa cases under the transition age should not be associated with emancipation categories/)
      end
    end

    describe "with invalid parameters" do
      describe "with invalid casa case parameters" do
        let(:all_record_params) { {casa_case:, casa_case_id: casa_case.id} }

        include_examples("the reference to a required record is present and unambiguous", record_param_name: :casa_case, record_id_param_name: :casa_case_id)
      end

      describe "with invalid contact type parameters" do
        let(:all_record_params) { {emancipation_category:, emancipation_category_id: emancipation_category.id} }

        include_examples("the reference to a required record is present and unambiguous", record_param_name: :emancipation_category, record_id_param_name: :emancipation_category_id)
      end
    end
  end

  describe "seed_casa_case_emancipation_categories" do
    let(:method_name) { :seed_casa_case_emancipation_categories }

    let(:casa_cases) { create_list(:casa_case, 3) }
    let(:emancipation_categories) { create_list(:emancipation_category, 4) }
    let(:minimal_valid_params) {
      {casa_case_ids: casa_cases.map(&:id), emancipation_category_ids: emancipation_categories.map(&:id), count: 2}
    }

    describe "with valid parameters" do
      include_examples("creates the specified number of records", model_class: CasaCaseEmancipationCategory, model_plural_name: "casa case emancipation categories")
      include_examples("has randomness derived from the seed when generating several of the same type of record", "casa_case_id", "emancipation_category_id", model_class: CasaCaseEmancipationCategory)
      include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
      include_examples("returns the ids of the generated records", model_class: CasaCaseEmancipationCategory, model_plural_name: "casa case emancipation categories")
      include_examples("returns an Exception for each record that failed to generate", record_param_name: "casa case emancipation category")

      it "adds a special exception to the results when no more casa case contact type combinations are available" do
        seed_results = subject.seed_casa_case_emancipation_categories(casa_case_ids: [casa_cases[0].id], emancipation_category_ids: [emancipation_categories[0].id], count: 2)

        expect(seed_results).to include(have_attributes(message: "There are no more casa case and emancipation category id combinations available to make more casa_case_emancipation_categories"))
      end

      it "adds an error to the results for each non transitioning casa case" do
      end

      it "adds a unique error to the results when there are no available tranitioning cases" do
      end

      it "does not count attempting to create an existing association as a failure" do
        #     record_id_array = subject.seed_casa_case_contact_types(casa_case_ids: casa_cases.map(&:id), contact_type_ids: contact_types.map(&:id), count: 2)

        #     expect(record_id_array.count { |seed_result| seed_result.is_a?(Integer) }).to be >= 2

        #     reset_seeder = RecordCreator.new(seed: RSpec.configuration.seed)

        #     reseeded_record_id_array = reset_seeder.seed_casa_case_contact_types(casa_case_ids: casa_cases.map(&:id), contact_type_ids: contact_types.map(&:id), count: 2)

        #     expect(reseeded_record_id_array.count { |seed_result| seed_result.is_a?(Integer) }).to be >= 2
      end

      it "only uses transitioning casa cases" do
      end
    end

    describe "with invalid parameters" do
      describe "with invalid parameters for a set of casa_cases" do
        let(:all_record_params) {
          {casa_cases: CasaCase.all, casa_case_ids: casa_cases.map(&:id)}
        }

        include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_case", records_param_name: :casa_cases, record_id_array_param_name: :casa_case_ids)
      end

      describe "with invalid parameters for a set of emancipation_categories" do
        let(:all_record_params) {
          {emancipation_categories: EmancipationCategory.all, emancipation_category_ids: emancipation_categories.map(&:id)}
        }

        include_examples("the reference to a required set of records is present and unambiguous", model_name: "emancipation_category", records_param_name: :emancipation_categories, record_id_array_param_name: :emancipation_category_ids)
      end
    end
  end

  describe "seed_casa_org" do
    let(:method_name) { :seed_casa_org }
    let(:minimal_valid_params) { {} }

    include_examples("creates the record", model_class: CasaOrg, model_name: "casa org")
    include_examples("has randomness derived from the seed when generating a record", "address", "name")
    include_examples("returns the generated record", model_class: CasaOrg, model_name: "casa org")
  end

  describe "seed_casa_orgs" do
    let(:method_name) { :seed_casa_orgs }
    let(:minimal_valid_params) { {} }

    include_examples("creates the specified number of records", model_class: CasaOrg, model_plural_name: "casa orgs")
    include_examples("has randomness derived from the seed when generating several of the same type of record", "address", "name", model_class: CasaOrg)
    include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
    include_examples("returns the ids of the generated records", model_class: CasaOrg, model_plural_name: "casa orgs")

    it "returns an array containing an error for each casa org that could not be created" do
      subject.seed_casa_orgs(count: 2)
      subject = RecordCreator.new(seed: RSpec.configuration.seed)

      # Resetting the RecordCreator with the same seed
      # should result in casa orgs with duplicate names
      # but casa orgs require unique names
      # thus causing the errors
      error_array = subject.seed_casa_orgs(count: 2)

      error_array.each do |error|
        expect(error).to be_a(Exception)
      end
    end
  end

  describe "seed_case_group" do
    let(:method_name) { :seed_case_group }

    let(:casa_case) { create(:casa_case) }
    let(:casa_org) { create(:casa_org) }
    let(:minimal_valid_params) {
      casa_case

      {casa_cases: CasaCase.all, casa_org:}
    }

    describe "with valid parameters" do
      include_examples("creates the record", model_class: CaseGroup, model_name: "case group")
      include_examples("has randomness derived from the seed when generating a record", "name")
      include_examples("returns the generated record", model_class: CaseGroup, model_name: "case group")
    end

    describe "with invalid parameters" do
      describe "with invalid casa_org parameters" do
        let(:all_record_params) { {casa_org:, casa_org_id: casa_org.id} }

        include_examples("the reference to a required record is present and unambiguous", record_param_name: :casa_org, record_id_param_name: :casa_org_id)
      end

      describe "with invalid parameters for a set of casa_cases" do
        let(:all_record_params) {
          {casa_cases: CasaCase.all, casa_case_ids: [casa_case.id]}
        }

        include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_case", records_param_name: :casa_cases, record_id_array_param_name: :casa_case_ids)
      end
    end
  end

  describe "seed_case_groups" do
    let(:method_name) { :seed_case_groups }

    let(:casa_org) { create(:casa_org) }
    let(:casa_case) { create(:casa_case, casa_org:) }
    let(:minimal_valid_params) {
      casa_case # triggers lazy load

      {casa_cases: CasaCase.all, casa_orgs: CasaOrg.all, count: 2}
    }

    describe "with valid parameters" do
      include_examples("creates the specified number of records", model_class: CaseGroup, model_plural_name: "case groups")
      include_examples("has randomness derived from the seed when generating several of the same type of record", "name", model_class: CaseGroup)
      include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
      include_examples("returns the ids of the generated records", model_class: CaseGroup, model_plural_name: "case groups")

      it "does not add the same case to multiple groups when there are there are enough cases for each group" do
        create(:casa_case)
        create(:casa_case)
        create(:casa_case)
        create(:casa_case)
        create(:casa_org)

        case_group_ids = subject.seed_case_groups(casa_cases: CasaCase.all, casa_orgs: CasaOrg.all, count: 2)

        case_group_1_casa_cases = CaseGroup.find(case_group_ids[0])&.casa_cases
        case_group_2_casa_cases = CaseGroup.find(case_group_ids[1])&.casa_cases

        expect(case_group_1_casa_cases).not_to include(*case_group_2_casa_cases)
      end

      it "forms casa case groups with at least 2 cases when able" do
        create(:casa_case)
        create(:casa_case)
        create(:casa_org)

        case_group_ids = subject.seed_case_groups(casa_cases: CasaCase.all, casa_orgs: CasaOrg.all, count: 3)

        case_group_1_casa_cases = CaseGroup.find(case_group_ids[0])&.casa_cases
        case_group_2_casa_cases = CaseGroup.find(case_group_ids[1])&.casa_cases
        case_group_3_casa_cases = CaseGroup.find(case_group_ids[2])&.casa_cases

        expect(case_group_1_casa_cases.size).to be >= 2
        expect(case_group_2_casa_cases.size).to be >= 2
        expect(case_group_3_casa_cases.size).to be >= 2
      end

      it "returns an array containing an error for each case group that could not be created" do
        error_array = subject.seed_case_groups(casa_case_ids: [-1], casa_org_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(Exception)
        end
      end
    end

    describe "with invalid parameters" do
      describe "with invalid parameters for a set of casa_cases" do
        let(:all_record_params) {
          {casa_cases: CasaCase.all, casa_case_ids: [casa_case.id]}
        }

        include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_case", records_param_name: :casa_cases, record_id_array_param_name: :casa_case_ids)
      end

      describe "with invalid parameters for a set of casa_orgs" do
        let(:all_record_params) {
          {casa_orgs: CasaOrg.all, casa_org_ids: [casa_org.id]}
        }

        include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_org", records_param_name: :casa_orgs, record_id_array_param_name: :casa_org_ids)
      end
    end
  end

  describe "seed_language" do
    let(:method_name) { :seed_language }

    let(:casa_org) { create(:casa_org) }
    let(:minimal_valid_params) { {casa_org:} }

    describe "with valid parameters" do
      include_examples("creates the record", model_class: Language, model_name: "language")
      include_examples("has randomness derived from the seed when generating a record", "name")
      include_examples("returns the generated record", model_class: Language, model_name: "language")
    end

    describe "with invalid parameters" do
      let(:all_record_params) { {casa_org:, casa_org_id: casa_org.id} }

      include_examples("the reference to a required record is present and unambiguous", record_param_name: :casa_org, record_id_param_name: :casa_org_id)
    end
  end

  describe "seed_languages" do
    let(:method_name) { :seed_languages }

    let(:casa_org) { create(:casa_org) }
    let(:minimal_valid_params) {
      casa_org # triggers lazy load

      {casa_orgs: CasaOrg.all, count: 2}
    }

    describe "with valid parameters" do
      include_examples("creates the specified number of records", model_class: Language, model_plural_name: "languages")
      include_examples("has randomness derived from the seed when generating several of the same type of record", "name", model_class: Language)
      include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
      include_examples("returns the ids of the generated records", model_class: Language, model_plural_name: "languages")

      it "returns an array containing an error for each language that could not be created" do
        error_array = subject.seed_languages(casa_org_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(Exception)
        end
      end
    end

    describe "with invalid parameters" do
      let(:all_record_params) {
        {casa_orgs: CasaOrg.all, casa_org_ids: casa_org.id}
      }

      include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_org", records_param_name: :casa_orgs, record_id_array_param_name: :casa_org_ids)
    end
  end

  describe "seed_mileage_rate" do
    let(:method_name) { :seed_mileage_rate }

    let(:casa_org) { create(:casa_org) }
    let(:minimal_valid_params) { {casa_org:} }

    describe "with valid parameters" do
      include_examples("creates the record", model_class: MileageRate, model_name: "mileage rate")
      include_examples("has randomness derived from the seed when generating a record", "amount", "effective_date")
      include_examples("returns the generated record", model_class: MileageRate, model_name: "mileage rate")

      it "generates a value for effective_date" do
        create(:casa_org)
        new_mileage_rate = subject.seed_mileage_rate(casa_org: CasaOrg.first)

        expect(new_mileage_rate).to be_a(MileageRate)

        expect(new_mileage_rate.effective_date).not_to be_nil
      end
    end

    describe "with invalid parameters" do
      let(:all_record_params) { {casa_org:, casa_org_id: casa_org.id} }

      include_examples("the reference to a required record is present and unambiguous", record_param_name: :casa_org, record_id_param_name: :casa_org_id)
    end
  end

  describe "seed_mileage_rates" do
    let(:method_name) { :seed_mileage_rates }

    let(:casa_org) { create(:casa_org) }
    let(:minimal_valid_params) {
      casa_org # triggers lazy load

      {casa_orgs: CasaOrg.all, count: 2}
    }

    describe "with valid parameters" do
      include_examples("creates the specified number of records", model_class: MileageRate, model_plural_name: "mileage rates")
      include_examples("has randomness derived from the seed when generating several of the same type of record", "amount", "effective_date", model_class: MileageRate)
      include_examples("multi-record generation returns empty list when requesting to generate a negative number of records")
      include_examples("returns the ids of the generated records", model_class: MileageRate, model_plural_name: "mileage rates")

      it "returns an array containing an error for each mileage rate that could not be created" do
        error_array = subject.seed_mileage_rates(casa_org_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(Exception)
        end
      end
    end

    describe "with invalid parameters" do
      let(:all_record_params) {
        {casa_orgs: CasaOrg.all, casa_org_ids: casa_org.id}
      }

      include_examples("the reference to a required set of records is present and unambiguous", model_name: "casa_org", records_param_name: :casa_orgs, record_id_array_param_name: :casa_org_ids)
    end
  end

  # Helper Methods

  def test_records_equal(record1, record2, *business_data_field_names)
    if record1.is_a?(Class) && record1 < ActiveRecord::Base
      raise TypeError.new("param record1 must be an ActiveRecord object")
    end

    if record2.is_a?(Class) && record2 < ActiveRecord::Base
      raise TypeError.new("param record2 must be an ActiveRecord object")
    end

    unless business_data_field_names.all? { |field_name| field_name.is_a?(String) }
      raise TypeError, "All business_data_field_names must be strings"
    end

    expect(record1.attributes.slice(*business_data_field_names)).to eq(record2.attributes.slice(*business_data_field_names))
  end

  def test_record_arrays_equal(record_array_1, record_array_2, *business_data_field_names)
    unless record_array_1.is_a?(Array)
      raise TypeError.new("param record_id_array_1 must be an array")
    end

    unless record_array_2.is_a?(Array)
      raise TypeError.new("param record_id_array_2 must be an array")
    end

    unless business_data_field_names.all? { |field_name| field_name.is_a?(String) }
      raise TypeError, "All business_data_field_names must be strings"
    end

    record_array_1_as_hash_array = record_array_1.map do |record|
      record.attributes.slice(*business_data_field_names)
    end

    record_array_2_as_hash_array = record_array_2.map do |record|
      record.attributes.slice(*business_data_field_names)
    end

    expect(record_array_1_as_hash_array).to eq(record_array_2_as_hash_array)
  end
end
