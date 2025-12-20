module Services
class ContentScorer
  TOXIC_KEYWORDS = %w[hate kill threat violence abuse slur insult dumb stupid idiot loser trash garbage worthless].freeze
  NSFW_KEYWORDS = %w[nsfw porn nude xxx sex sexual explicit].freeze

  def initialize(text)
    @text = text.to_s.downcase
  end

  def toxicity_score
    return 0.0 if @text.empty?
    tokens = @text.scan(/[a-z0-9']{2,}/)
    return 0.0 if tokens.empty?
    toxic_hits = tokens.count { |t| TOXIC_KEYWORDS.include?(t) }
    (toxic_hits.to_f / tokens.length).clamp(0.0, 1.0)
  end

  def nsfw_score
    return 0.0 if @text.empty?
    tokens = @text.scan(/[a-z0-9']{2,}/)
    return 0.0 if tokens.empty?
    nsfw_hits = tokens.count { |t| NSFW_KEYWORDS.include?(t) }
    (nsfw_hits.to_f / tokens.length).clamp(0.0, 1.0)
  end
end
end

