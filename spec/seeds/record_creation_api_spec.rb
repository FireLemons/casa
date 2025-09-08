require "rails_helper"
require_relative "../../db/seeds/record_creation_api"

RSpec.describe RecordCreator do
  # RSpec.describe RecordCreator, skip: 'disabled by default because this is a rarely used developer feature' do
  subject { RecordCreator.new(0) }

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
        original_case_contact_count = CaseContact.count

        expect {
          subject.seed_additional_expense(case_contact: create(:case_contact))
        }.to change { CaseContact.count }.from(original_case_contact_count).to(original_case_contact_count + 1)
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
      end

      it "returns an array containing an error for each additional expense that could not be created" do
      end

      it "returns an array with length equal to the count argument" do
      end

      it "returns empty array for negative counts" do
      end
    end

    it "throws an error when neither case_contacts or case_contact_ids are used" do
    end

    it "throws an error when both case_contacts and case_contact_ids are used" do
    end

    it "throws an error when case_contacts is not an ActiveRecord::Relation" do
    end

    it "throws an error when case_contacts is an empty ActiveRecord::Relation" do
    end

    it "throws an error when case_contact_ids is not an array" do
    end

    it "throws an error when case_contact_ids is an empty array" do
    end

    it "throws an error when the additional expense fails to persist" do
    end
  end
end
