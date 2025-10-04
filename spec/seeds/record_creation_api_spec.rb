require "rails_helper"
require_relative "../../db/seeds/record_creation_api"

RSpec.describe RecordCreator do
  # RSpec.describe RecordCreator, skip: 'disabled by default because this is a rarely used developer feature' do
  subject { RecordCreator.new(RSpec.configuration.seed) }

  describe "getSeededRecordCounts" do
    it "includes the counts of all models created since the RecordCreator's initialization" do
      # trigger lazy init
      subject

      create(:casa_org)
      create(:casa_org)
      create(:casa_org)
      create(:casa_admin)

      seeded_record_counts = subject.getSeededRecordCounts

      expect(seeded_record_counts[CasaOrg.name]).to eq 3
      expect(seeded_record_counts[User.name]).to eq 1
      expect(seeded_record_counts[CasaCase.name]).to eq 0
    end
  end

  describe "seed_additional_expense" do
    describe "with valid parameters" do
      it "creates an additional expense" do
        original_additional_expense_count = AdditionalExpense.count

        expect {
          subject.seed_additional_expense(case_contact: create(:case_contact))
        }.to change { AdditionalExpense.count }.from(original_additional_expense_count).to(original_additional_expense_count + 1)
      end

      it "returns the newly created additional expense" do
        new_additional_expense = subject.seed_additional_expense(case_contact: create(:case_contact))

        expect(new_additional_expense).to be_a(AdditionalExpense)
      end

      it "has randomness derived from the seed" do
        create(:case_contact)

        test_single_object_seed_method_seeded("other_expense_amount", "other_expenses_describe") do |subject|
          subject.seed_additional_expense(case_contact: CaseContact.first)
        end
      end
    end

    describe "with invalid parameters" do
      it "throws an error when neither case_contact or case_contact_id are used" do
        expect {
          subject.seed_additional_expense
        }.to raise_error(ArgumentError, /case_contact: or case_contact_id: is required/)
      end

      it "throws an error when both case_contact and case_contact_id are used" do
        case_contact = create(:case_contact)

        expect {
          subject.seed_additional_expense(case_contact:, case_contact_id: case_contact.id)
        }.to raise_error(ArgumentError, /cannot use case_contact: and case_contact_id:/)
      end
    end
  end

  describe "seed_additional_expenses" do
    describe "with valid parameters" do
      it "creates the specified number of additional expenses" do
        create(:case_contact)
        original_additional_expense_count = AdditionalExpense.count
        additional_expense_seed_count = 2

        expect {
          subject.seed_additional_expenses(case_contacts: CaseContact.all, count: additional_expense_seed_count)
        }.to change { AdditionalExpense.count }.from(original_additional_expense_count).to(original_additional_expense_count + additional_expense_seed_count)
      end

      it "returns an array containing the ids of the additional expenses created" do
        create(:case_contact)

        subject.seed_additional_expenses(case_contacts: CaseContact.all, count: 2).each do |additional_expense_id|
          expect {
            AdditionalExpense.find(additional_expense_id)
          }.not_to raise_error
        end
      end

      it "returns an array containing an error for each additional expense that could not be created" do
        error_array = subject.seed_additional_expenses(case_contact_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(StandardError)
        end
      end

      it "returns empty array for negative counts" do
        expect(subject.seed_additional_expenses(case_contact_ids: [1], count: -1)).to eq([])
      end

      it "has randomness derived from the seed" do
        create(:case_contact)
        additional_expense_seed_count = 2

        test_multi_object_seed_method_seeded(AdditionalExpense, "other_expense_amount", "other_expenses_describe") do |subject|
          subject.seed_additional_expenses(case_contacts: CaseContact.all, count: additional_expense_seed_count)
        end
      end
    end

    describe "with invalid parameters" do
      it "throws an error when neither case_contacts or case_contact_ids are used" do
        expect {
          subject.seed_additional_expenses
        }.to raise_error(ArgumentError, /case_contacts: or case_contact_ids: is required/)
      end

      it "throws an error when both case_contacts and case_contact_ids are used" do
        expect {
          subject.seed_additional_expenses(case_contacts: CaseContact.all, case_contact_ids: [1, 2])
        }.to raise_error(ArgumentError, /cannot use case_contacts: and case_contact_ids:/)
      end

      it "throws an error when case_contacts is not an ActiveRecord::Relation" do
        expect {
          subject.seed_additional_expenses(case_contacts: 2)
        }.to raise_error(TypeError, /param case_contacts: must be an ActiveRecord::Relation/)
      end

      it "throws an error when case_contacts is an empty ActiveRecord::Relation" do
        expect {
          subject.seed_additional_expenses(case_contacts: CaseContact.where(id: -1))
        }.to raise_error(ArgumentError, /param case_contacts: must contain at least one case_contact/)
      end

      it "throws an error when case_contact_ids is not an array" do
        expect {
          subject.seed_additional_expenses(case_contact_ids: 2)
        }.to raise_error(TypeError, /param case_contact_ids: must be an array/)
      end

      it "throws an error when case_contact_ids is an empty array" do
        expect {
          subject.seed_additional_expenses(case_contact_ids: [])
        }.to raise_error(RangeError, /param case_contact_ids: must contain at least one element/)
      end
    end
  end

  describe "seed_address" do
    describe "with valid parameters" do
      it "creates an address" do
        original_address_count = Address.count

        expect {
          subject.seed_address(user: create(:user))
        }.to change { Address.count }.from(original_address_count).to(original_address_count + 1)
      end

      it "updates an address if the user already has an address" do
        user = create(:user)
        Address.create(user:, content: "")

        subject.seed_address(user:)
        expect(user.address.content).not_to eq("")
      end

      it "returns the newly created address" do
        new_address = subject.seed_address(user: create(:user))

        expect(new_address).to be_a(Address)
      end

      it "has randomness derived from the seed" do
        create(:user)

        test_single_object_seed_method_seeded("content") do |subject|
          subject.seed_address(user: User.first)
        end
      end
    end

    it "throws an error when neither user or user_id are used" do
      expect {
        subject.seed_address
      }.to raise_error(ArgumentError, /user: or user_id: is required/)
    end

    it "throws an error when both user and user_id are used" do
      user = create(:user)

      expect {
        subject.seed_address(user:, user_id: user.id)
      }.to raise_error(ArgumentError, /cannot use user: and user_id:/)
    end
  end

  describe "seed_addresses" do
    describe "with valid parameters" do
      it "creates the specified number of addresses" do
        create(:user)
        create(:user)
        original_address_count = Address.count
        address_seed_count = 2

        expect {
          subject.seed_addresses(users: User.all, count: address_seed_count)
        }.to change { Address.count }.from(original_address_count).to(original_address_count + address_seed_count)
      end

      it "overwrites an existing address if a user already has an address" do
        user_with_address = create(:user)
        create(:user)
        overridden_address = create(:address, content: "", user: user_with_address)

        subject.seed_addresses(users: User.all, count: 2)
        overridden_address.reload

        expect(overridden_address.content).not_to eq("")
      end

      it "returns an array containing the ids of the addresses seeded" do
        create(:user)
        create(:user)

        subject.seed_addresses(users: User.all, count: 2).each do |address_id|
          expect {
            Address.find(address_id)
          }.not_to raise_error
        end
      end

      it "returns an array containing an error for each address that could not be created" do
        error_array = subject.seed_addresses(user_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(Exception)
        end
      end

      it "returns empty array for negative counts" do
        expect(subject.seed_addresses(user_ids: [1], count: -1)).to eq([])
      end

      it "has randomness derived from the seed" do
        create(:user)
        create(:user)
        address_seed_count = 2

        # The string address has to be preserved because reseeding the addresses will overwrite the strings of the addresses first seeded first
        first_pass_generated_addresses = subject.seed_addresses(users: User.all, count: address_seed_count).map do |id|
          address = Address.find(id)
          address.content
        end
        subject = RecordCreator.new(RSpec.configuration.seed)
        second_pass_generated_addresses = subject.seed_addresses(users: User.all, count: address_seed_count).map do |id|
          address = Address.find(id)
          address.content
        end

        expect(first_pass_generated_addresses).to eq(second_pass_generated_addresses)
      end
    end

    describe "with invalid parameters" do
      it "throws an error when neither users or user_ids are used" do
        expect {
          subject.seed_addresses
        }.to raise_error(ArgumentError, /users: or user_ids: is required/)
      end

      it "throws an error when both users and user_ids are used" do
        expect {
          subject.seed_addresses(users: User.all, user_ids: [1, 2])
        }.to raise_error(ArgumentError, /cannot use users: and user_ids:/)
      end

      it "throws an error when users is not an ActiveRecord::Relation" do
        expect {
          subject.seed_addresses(users: 2)
        }.to raise_error(TypeError, /param users: must be an ActiveRecord::Relation/)
      end

      it "throws an error when users is an empty ActiveRecord::Relation" do
        expect {
          subject.seed_addresses(users: User.where(id: -1))
        }.to raise_error(ArgumentError, /param users: must contain at least one user/)
      end

      it "throws an error when user_ids is not an array" do
        expect {
          subject.seed_addresses(user_ids: 2)
        }.to raise_error(TypeError, /param user_ids: must be an array/)
      end

      it "throws an error when user_ids is an empty array" do
        expect {
          subject.seed_addresses(user_ids: [])
        }.to raise_error(RangeError, /param user_ids: must contain at least one element/)
      end
    end
  end

  describe "seed_all_casa_admin" do
    it "creates an all casa admin" do
      original_all_casa_admin_count = AllCasaAdmin.count

      expect {
        subject.seed_all_casa_admin
      }.to change { AllCasaAdmin.count }.from(original_all_casa_admin_count).to(original_all_casa_admin_count + 1)
    end

    it "returns the newly created all casa admin" do
      new_all_casa_admin = subject.seed_all_casa_admin

      expect(new_all_casa_admin).to be_a(AllCasaAdmin)
    end

    it "has randomness derived from the seed" do
      test_single_object_seed_method_seeded("email") do |subject|
        subject.seed_all_casa_admin
      end
    end
  end

  describe "seed_all_casa_admins" do
    it "creates the specified number of all casa admins" do
      original_all_casa_admin_count = AllCasaAdmin.count
      all_casa_admin_seed_count = 2

      expect {
        subject.seed_all_casa_admins(count: all_casa_admin_seed_count)
      }.to change { AllCasaAdmin.count }.from(original_all_casa_admin_count).to(original_all_casa_admin_count + all_casa_admin_seed_count)
    end

    it "returns an array containing the all casa admins created" do
      subject.seed_all_casa_admins(count: 2).each do |all_casa_admin_id|
        expect {
          AllCasaAdmin.find(all_casa_admin_id)
        }.not_to raise_error
      end
    end

    it "returns an array containing an error for each all casa admin that could not be created" do
      subject.seed_all_casa_admins(count: 2)
      subject = RecordCreator.new(RSpec.configuration.seed)

      # Resetting the RecordCreator with the same seed
      # should result in all casa admins with duplicate emails
      # but all casa admins require unique emails
      # thus causing the errors
      error_array = subject.seed_all_casa_admins(count: 2)

      error_array.each do |error|
        expect(error).to be_a(Exception)
      end
    end

    it "returns empty array for negative counts" do
      expect(subject.seed_all_casa_admins(count: -1)).to eq([])
    end

    it "has randomness derived from the seed" do
      subject.seed_all_casa_admins(count: 2)
      subject = RecordCreator.new(RSpec.configuration.seed)

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

  describe "seed_casa_case" do
    describe "with valid parameters" do
      it "creates a casa case" do
        original_casa_case_count = CasaCase.count

        expect {
          subject.seed_casa_case(casa_org: create(:casa_org))
        }.to change { CasaCase.count }.from(original_casa_case_count).to(original_casa_case_count + 1)
      end

      it "returns the newly created casa case" do
        new_casa_case = subject.seed_casa_case(casa_org: create(:casa_org))

        expect(new_casa_case).to be_a(CasaCase)
      end

      it "automatically generates values for fields birth_month_year_youth and date_in_care" do
        new_casa_case = subject.seed_casa_case(casa_org: create(:casa_org))

        expect(new_casa_case.birth_month_year_youth).not_to be_nil
        expect(new_casa_case.date_in_care).not_to be_nil
      end

      it "has randomness derived from the seed" do
        create(:casa_org)

        test_single_object_seed_method_seeded("birth_month_year_youth", "case_number", "date_in_care") do |subject|
          subject.seed_casa_case(casa_org: CasaOrg.first)
        end
      end
    end

    describe "with invalid parameters" do
      it "throws an error when neither casa_org or casa_org_id are used" do
        expect {
          subject.seed_casa_case
        }.to raise_error(ArgumentError, /casa_org: or casa_org_id: is required/)
      end

      it "throws an error when both casa_org and casa_org_id are used" do
        casa_org = create(:casa_org)

        expect {
          subject.seed_casa_case(casa_org:, casa_org_id: casa_org.id)
        }.to raise_error(ArgumentError, /cannot use casa_org: and casa_org_id:/)
      end
    end
  end

  describe "seed_casa_cases" do
    describe "with valid parameters" do
      it "creates the specified number of casa cases" do
        create(:casa_org)

        original_casa_case_count = CasaCase.count
        casa_case_seed_count = 2

        expect {
          subject.seed_casa_cases(casa_orgs: CasaOrg.all, count: casa_case_seed_count)
        }.to change { CasaCase.count }.from(original_casa_case_count).to(original_casa_case_count + casa_case_seed_count)
      end

      it "returns an array containing the ids of the casa cases created" do
        create(:casa_org)

        subject.seed_casa_cases(casa_orgs: CasaOrg.all, count: 2).each do |casa_case_id|
          expect {
            CasaCase.find(casa_case_id)
          }.not_to raise_error
        end
      end

      it "returns an array containing an error for each casa case that could not be created" do
        error_array = subject.seed_casa_cases(casa_org_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error).to be_a(Exception)
        end
      end

      it "returns empty array for negative counts" do
        expect(subject.seed_casa_cases(casa_org_ids: [1], count: -1)).to eq([])
      end

      it "has randomness derived from the seed" do
        create(:casa_org)

        subject.seed_casa_cases(casa_orgs: CasaOrg.all, count: 2)
        subject = RecordCreator.new(RSpec.configuration.seed)

        # Resetting the RecordCreator with the same seed
        # should result in casa cases with duplicate numbers
        # but casa cases require unique numbers
        # thus causing the errors
        error_array = subject.seed_casa_cases(casa_orgs: CasaOrg.all, count: 2)

        error_array.each do |error|
          expect(error).to be_a(Exception)
        end
      end
    end

    describe "with invalid parameters" do
      it "throws an error when neither casa_orgs or casa_org_ids are used" do
        expect {
          subject.seed_casa_cases
        }.to raise_error(ArgumentError, /casa_orgs: or casa_org_ids: is required/)
      end

      it "throws an error when both casa_orgs or casa_org_ids are used" do
        expect {
          subject.seed_casa_cases(casa_orgs: CasaOrg.all, casa_org_ids: [1, 2])
        }.to raise_error(ArgumentError, /cannot use casa_orgs: and casa_org_ids:/)
      end

      it "throws an error when casa_orgs is not an ActiveRecord::Relation" do
        expect {
          subject.seed_casa_cases(casa_orgs: 2)
        }.to raise_error(TypeError, /param casa_orgs: must be an ActiveRecord::Relation/)
      end

      it "throws an error when casa_orgs is an empty ActiveRecord::Relation" do
        expect {
          subject.seed_casa_cases(casa_orgs: CasaOrg.where(id: -1))
        }.to raise_error(ArgumentError, /param casa_orgs: must contain at least one casa_org/)
      end

      it "throws an error when casa_org_ids is not an array" do
        expect {
          subject.seed_casa_cases(casa_org_ids: 2)
        }.to raise_error(TypeError, /param casa_org_ids: must be an array/)
      end

      it "throws an error when casa_org_ids is an empty array" do
        expect {
          subject.seed_casa_cases(casa_org_ids: [])
        }.to raise_error(RangeError, /param casa_org_ids: must contain at least one element/)
      end
    end
  end

  describe "seed_casa_org" do
    it "creates a casa org" do
      original_casa_org_count = CasaOrg.count

      expect {
        subject.seed_casa_org
      }.to change { CasaOrg.count }.from(original_casa_org_count).to(original_casa_org_count + 1)
    end

    it "returns the newly created casa org" do
      new_casa_org = subject.seed_casa_org

      expect(new_casa_org).to be_a(CasaOrg)
    end

    it "has randomness derived from the seed" do
      test_single_object_seed_method_seeded("address", "name") do |subject|
        subject.seed_casa_org
      end
    end
  end

  describe "seed_casa_orgs" do
    it "creates the specified number of casa orgs" do
      original_casa_org_count = CasaOrg.count
      casa_org_seed_count = 2

      expect {
        subject.seed_casa_orgs(count: casa_org_seed_count)
      }.to change { CasaOrg.count }.from(original_casa_org_count).to(original_casa_org_count + casa_org_seed_count)
    end

    it "returns an array containing the casa orgs created" do
      subject.seed_casa_orgs(count: 2).each do |casa_org_id|
        expect {
          CasaOrg.find(casa_org_id)
        }.not_to raise_error
      end
    end

    it "returns an array containing an error for each casa org that could not be created" do
      subject.seed_casa_orgs(count: 2)
      subject = RecordCreator.new(RSpec.configuration.seed)

      # Resetting the RecordCreator with the same seed
      # should result in casa orgs with duplicate names
      # but casa orgs require unique names
      # thus causing the errors
      error_array = subject.seed_casa_orgs(count: 2)

      error_array.each do |error|
        expect(error).to be_a(Exception)
      end
    end

    it "returns empty array for negative counts" do
      expect(subject.seed_casa_orgs(count: -1)).to eq([])
    end

    it "has randomness derived from the seed" do
      subject.seed_casa_orgs(count: 2)
      subject = RecordCreator.new(RSpec.configuration.seed)

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
    describe "with valid parameters" do
      it "creates a case group" do
        create(:casa_org)
        create(:casa_case)
        original_case_group_count = CaseGroup.count

        expect {
          subject.seed_case_group(casa_cases: CasaCase.all, casa_org: CasaOrg.first)
        }.to change { CaseGroup.count }.from(original_case_group_count).to(original_case_group_count + 1)
      end

      it "returns the newly created case group" do
        create(:casa_org)
        create(:casa_case)
        new_case_group = subject.seed_case_group(casa_cases: CasaCase.all, casa_org: CasaOrg.first)

        expect(new_case_group).to be_a(CaseGroup)
      end

      it "has randomness derived from the seed" do
        create(:casa_org)
        create(:casa_case)

        test_single_object_seed_method_seeded("name") do |subject|
          subject.seed_case_group(casa_cases: CasaCase.all, casa_org: CasaOrg.first)
        end
      end
    end

    describe "with invalid parameters" do
      it "throws an error when neither casa_org or casa_org_id are used" do
        expect {
          subject.seed_case_group
        }.to raise_error(ArgumentError, /casa_org: or casa_org_id: is required/)
      end

      it "throws an error when both casa_org and casa_org_id are used" do
        casa_org = create(:casa_org)

        expect {
          subject.seed_case_group(casa_org:, casa_org_id: casa_org.id)
        }.to raise_error(ArgumentError, /cannot use casa_org: and casa_org_id:/)
      end
    end
  end

  describe "seed_case_groups" do
    describe "with valid parameters" do
      it "creates the specified number of case groups" do
        # create(:casa_org)
        # original_case_group_count = CaseGroup.count
        # case_group_seed_count = 2

        # expect {
        #   subject.seed_case_groups(casa_orgs: CasaOrg.all, count: case_group_seed_count)
        # }.to change { CaseGroup.count }.from(original_case_group_count).to(original_case_group_count + case_group_seed_count)
      end

      it "returns an array containing the ids of the case groups created" do
        create(:casa_org)

        # subject.seed_casa_cases(casa_orgs: CasaOrg.all, count: 2).each do |casa_case_id|
        #   expect {
        #     CasaCase.find(casa_case_id)
        #   }.not_to raise_error
        # end
      end

      it "returns an array containing an error for each case group that could not be created" do
        # error_array = subject.seed_casa_cases(casa_org_ids: [-1], count: 2)

        # error_array.each do |error|
        #   expect(error).to be_a(Exception)
        # end
      end

      it "returns empty array for negative counts" do
        # expect(subject.seed_casa_cases(casa_org_ids: [1], count: -1)).to eq([])
      end

      it "has randomness derived from the seed" do
        create(:casa_org)

        # subject.seed_casa_cases(casa_orgs: CasaOrg.all, count: 2)
        # subject = RecordCreator.new(RSpec.configuration.seed)

        # # Resetting the RecordCreator with the same seed
        # # should result in casa cases with duplicate numbers
        # # but casa cases require unique numbers
        # # thus causing the errors
        # error_array = subject.seed_casa_cases(casa_orgs: CasaOrg.all, count: 2)

        # error_array.each do |error|
        #   expect(error).to be_a(Exception)
        # end
      end
    end

    describe "with invalid parameters" do
      it "throws an error when neither casa_orgs or casa_org_ids are used" do
        # expect {
        #   subject.seed_casa_cases
        # }.to raise_error(ArgumentError, /casa_orgs: or casa_org_ids: is required/)
      end

      it "throws an error when both casa_orgs or casa_org_ids are used" do
        # expect {
        #   subject.seed_casa_cases(casa_orgs: CasaOrg.all, casa_org_ids: [1, 2])
        # }.to raise_error(ArgumentError, /cannot use casa_orgs: and casa_org_ids:/)
      end

      it "throws an error when casa_orgs is not an ActiveRecord::Relation" do
        # expect {
        #   subject.seed_casa_cases(casa_orgs: 2)
        # }.to raise_error(TypeError, /param casa_orgs: must be an ActiveRecord::Relation/)
      end

      it "throws an error when casa_orgs is an empty ActiveRecord::Relation" do
        # expect {
        #   subject.seed_casa_cases(casa_orgs: CasaOrg.where(id: -1))
        # }.to raise_error(ArgumentError, /param casa_orgs: must contain at least one casa_org/)
      end

      it "throws an error when casa_org_ids is not an array" do
        # expect {
        #   subject.seed_casa_cases(casa_org_ids: 2)
        # }.to raise_error(TypeError, /param casa_org_ids: must be an array/)
      end

      it "throws an error when casa_org_ids is an empty array" do
        # expect {
        #   subject.seed_casa_cases(casa_org_ids: [])
        # }.to raise_error(RangeError, /param casa_org_ids: must contain at least one element/)
      end
    end
  end

  # Helper Methods

  def test_models_equal(model1, model2, *business_data_field_names)
    if model1.is_a?(Class) && model1 < ActiveRecord::Base
      raise TypeError.new("param model1 must be an ActiveRecord object")
    end

    if model2.is_a?(Class) && model2 < ActiveRecord::Base
      raise TypeError.new("param model2 must be an ActiveRecord object")
    end

    unless business_data_field_names.all? { |field_name| field_name.is_a?(String) }
      raise TypeError, "All business_data_field_names must be strings"
    end

    expect(model1.attributes.slice(*business_data_field_names)).to eq(model2.attributes.slice(*business_data_field_names))
  end

  def test_model_arrays_equal(model_array_1, model_array_2, *business_data_field_names)
    unless model_array_1.is_a?(Array)
      raise TypeError.new("param model_id_array_1 must be an array")
    end

    unless model_array_2.is_a?(Array)
      raise TypeError.new("param model_id_array_2 must be an array")
    end

    unless business_data_field_names.all? { |field_name| field_name.is_a?(String) }
      raise TypeError, "All business_data_field_names must be strings"
    end

    model_array_1_as_hash_array = model_array_1.map do |model|
      model.attributes.slice(*business_data_field_names)
    end

    model_array_2_as_hash_array = model_array_2.map do |model|
      model.attributes.slice(*business_data_field_names)
    end

    expect(model_array_1_as_hash_array).to eq(model_array_2_as_hash_array)
  end

  def test_multi_object_seed_method_seeded(object_class, *business_data_field_names, &seed_expression)
    unless business_data_field_names.all? { |field_name| field_name.is_a?(String) }
      raise TypeError, "All business_data_field_names must be strings"
    end

    model_id_array = seed_expression.call(subject)
    model_array = model_id_array.map do |id|
      object_class.find(id)
    end

    model_array.each do |model|
      model.destroy
    end

    reset_subject = RecordCreator.new(RSpec.configuration.seed)

    reseeded_model_id_array = seed_expression.call(reset_subject)
    reseeded_model_array = reseeded_model_id_array.map do |id|
      object_class.find(id)
    end

    test_model_arrays_equal(model_array, reseeded_model_array, *business_data_field_names)
  end

  def test_single_object_seed_method_seeded(*business_data_field_names, &seed_expression)
    unless business_data_field_names.all? { |field_name| field_name.is_a?(String) }
      raise TypeError, "All business_data_field_names must be strings"
    end

    model = seed_expression.call(subject)
    model.destroy

    reset_subject = RecordCreator.new(RSpec.configuration.seed)

    reseeded_model = seed_expression.call(reset_subject)

    test_models_equal(model, reseeded_model, *business_data_field_names)
  end
end
