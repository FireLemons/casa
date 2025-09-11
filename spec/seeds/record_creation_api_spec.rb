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
    end

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

    it "throws an error when the additional expense fails to persist" do
      expect {
        subject.seed_additional_expense(case_contact_id: "invalid id")
      }.to raise_error(ActiveRecord::RecordNotSaved, /AdditionalExpense failed to save/)
    end
  end

  describe "seed_additional_expenses" do
    describe "with valid parameters" do
      it "returns an array containing the additional expenses created" do
        create(:case_contact)
        original_additional_expense_count = AdditionalExpense.count
        additional_expense_seed_count = 2

        expect {
          subject.seed_additional_expenses(case_contacts: CaseContact.all, count: additional_expense_seed_count)
        }.to change { AdditionalExpense.count }.from(original_additional_expense_count).to(original_additional_expense_count + additional_expense_seed_count)
      end

      it "returns an array containing an error for each additional expense that could not be created" do
        error_array = subject.seed_additional_expenses(case_contact_ids: [-1], count: 2)

        error_array.each do |error|
          expect(error.message).to include("AdditionalExpense failed to save")
        end
      end

      it "returns empty array for negative counts" do
        expect(subject.seed_additional_expenses(case_contact_ids: [1], count: -1)).to eq([])
      end
    end

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
      it "returns an array containing the addresses created" do
        #create(:case_contact)
        #original_additional_expense_count = AdditionalExpense.count
        #additional_expense_seed_count = 2

        #expect {
        #  subject.seed_additional_expenses(case_contacts: CaseContact.all, count: additional_expense_seed_count)
        #}.to change { AdditionalExpense.count }.from(original_additional_expense_count).to(original_additional_expense_count + additional_expense_seed_count)
      end

      it "returns an array containing an error for each address that could not be created" do
        # error_array = subject.seed_additional_expenses(case_contact_ids: [-1], count: 2)

        # error_array.each do |error|
        #   expect(error.message).to include("AdditionalExpense failed to save")
        # end
      end

      it "returns empty array for negative counts" do
        # expect(subject.seed_additional_expenses(case_contact_ids: [1], count: -1)).to eq([])
      end
    end

    it "throws an error when neither users or user_ids are used" do
      # expect {
      #   subject.seed_additional_expenses
      # }.to raise_error(ArgumentError, /case_contacts: or case_contact_ids: is required/)
    end

    it "throws an error when both users and user_ids are used" do
      # expect {
      #   subject.seed_additional_expenses(case_contacts: CaseContact.all, case_contact_ids: [1, 2])
      # }.to raise_error(ArgumentError, /cannot use case_contacts: and case_contact_ids:/)
    end

    it "throws an error when users is not an ActiveRecord::Relation" do
      # expect {
      #   subject.seed_additional_expenses(case_contacts: 2)
      # }.to raise_error(TypeError, /param case_contacts: must be an ActiveRecord::Relation/)
    end

    it "throws an error when users is an empty ActiveRecord::Relation" do
      # expect {
      #   subject.seed_additional_expenses(case_contacts: CaseContact.where(id: -1))
      # }.to raise_error(ArgumentError, /param case_contacts: must contain at least one case_contact/)
    end

    it "throws an error when user_ids is not an array" do
      # expect {
      #   subject.seed_additional_expenses(case_contact_ids: 2)
      # }.to raise_error(TypeError, /param case_contact_ids: must be an array/)
    end

    it "throws an error when user_ids is an empty array" do
      # expect {
      #   subject.seed_additional_expenses(case_contact_ids: [])
      # }.to raise_error(RangeError, /param case_contact_ids: must contain at least one element/)
    end
  end
end
