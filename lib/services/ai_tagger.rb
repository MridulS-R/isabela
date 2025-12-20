module Services
class AiTagger
  STOPWORDS = %w[the and for with from this that have will your our you are was were has had not into over under into about by of to in on at a an or as it its it’s we us them they he she his her theirs our’s].freeze

  def suggest_tags(text, limit: 5)
    tokens = text.to_s.downcase.scan(/[a-z0-9_]{3,}/)
    freq = Hash.new(0)
    tokens.each do |t|
      next if STOPWORDS.include?(t)
      freq[t] += 1
    end
    freq.sort_by { |(_, c)| -c }.map(&:first).take(limit)
  end
end
end

