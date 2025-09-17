Wrong test logic for several methods
  it "returns an array containing the casa orgs created" do
    original_casa_org_count = CasaOrg.count
    casa_org_seed_count = 2

    expect {
      subject.seed_casa_orgs(count: casa_org_seed_count)
    }.to change { CasaOrg.count }.from(original_casa_org_count).to(original_casa_org_count + casa_org_seed_count)
  end

seed_casa_case
seed_casa_cases