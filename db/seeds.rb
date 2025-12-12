Post.find_or_create_by!(title: 'Guide: Building High‑Quality B2B Audiences') do |p|
  p.body = <<~BODY
    Translate your ICP into concrete filters and signals. Start with industry, company size, and geography, then add technographics and intent. Validate early with small campaigns and iterate on match/response rates.
  BODY
  p.published_at = Time.now
end

Post.find_or_create_by!(title: 'Case Study: 27% Lower CPL with Enrichment') do |p|
  p.body = <<~BODY
    See how enrichment improved routing and conversion for a SaaS team by filling contact gaps, normalizing company names, and scoring leads for SDR prioritization.
  BODY
  p.published_at = Time.now - 7.days
end

