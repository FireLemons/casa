Tests
  

RecordNotUnique exceptions are misnomers

push errors to seed_plural methods
  Add activerecord.persisted? checks

x.seed_additional_expenses(case_contact_ids: [0], count: 1)
  TRANSACTION (0.5ms)  BEGIN
  CaseContact Load (0.7ms)  SELECT "case_contacts".* FROM "case_contacts" WHERE "case_contacts"."deleted_at" IS NULL AND "case_contacts"."id" = $1 LIMIT $2  [["id", 0], ["LIMIT", 1]]
  TRANSACTION (0.6ms)  ROLLBACK
=> [nil]
  simply move create... to a different line so the exception stops the code execution
