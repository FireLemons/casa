Tests
  add seed test for each method
push errors to seed_plural methods
  Add activerecord.persisted? checks

helper methods for seeded comparisons of activerecord objects
  def expect_models_to_match_on(model1, model2, *fields)
    expect(model1.attributes.slice(*fields.map(&:to_s))).to eq(model2.attributes.slice(*fields.map(&:to_s)))
  end
    used like expect_models_to_match_on(user1, user2, :name, :email)

  def id_array_to_hash
    ... slice
