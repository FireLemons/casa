DRY param validation
  return selected param in validation function for single record param pairs

push errors to seed_plural methods


x.seed_additional_expenses(case_contact_ids: [0], count: 1)
  TRANSACTION (0.5ms)  BEGIN
  CaseContact Load (0.7ms)  SELECT "case_contacts".* FROM "case_contacts" WHERE "case_contacts"."deleted_at" IS NULL AND "case_contacts"."id" = $1 LIMIT $2  [["id", 0], ["LIMIT", 1]]
  TRANSACTION (0.6ms)  ROLLBACK
=> [nil]

Add activerecord.persisted? checks

casa(dev)> x.seed_additional_expense(case_contact_id: 10000)
  TRANSACTION (0.5ms)  BEGIN
  CaseContact Load (1.9ms)  SELECT "case_contacts".* FROM "case_contacts" WHERE "case_contacts"."deleted_at" IS NULL AND "case_contacts"."id" = $1 LIMIT $2  [["id", 10000], ["LIMIT", 1]]
  TRANSACTION (0.5ms)  ROLLBACK
=> 
#<AdditionalExpense:0x00007bfa1788cf60
 id: nil,
 case_contact_id: 10000,
 other_expense_amount: 0.16e1,
 other_expenses_describe: "Intelligent Leather Plate",
 created_at: nil,
 updated_at: nil>

casa(dev)> x.seed_additional_expense(case_contact_id: 'A')
  TRANSACTION (0.3ms)  BEGIN
  CaseContact Load (0.6ms)  SELECT "case_contacts".* FROM "case_contacts" WHERE "case_contacts"."deleted_at" IS NULL AND "case_contacts"."id" = $1 LIMIT $2  [["id", 0], ["LIMIT", 1]]
  TRANSACTION (0.2ms)  ROLLBACK
=> #<AdditionalExpense:0x00007bfa16b4eec0 id: nil, case_contact_id: 0, other_expense_amount: 0.2065e2, other_expenses_describe: "Gorgeous Rubber Coat", created_at: nil, updated_at: nil>
