require 'yaml'
require 'date'

module Services
class HomepageMdParser
  FRONT_MATTER_BOUNDARY = /^---\s*$/.freeze

  Result = Struct.new(:metadata, :html)

  def self.parse(io)
    text = io.read.to_s
    fm, body = extract_front_matter(text)
    # Safe‑load YAML front matter but allow common time/date types
    data = {}
    if fm.present?
      data = YAML.safe_load(
        fm,
        permitted_classes: [Time, Date, DateTime],
        permitted_symbols: [],
        aliases: false
      ) || {}
    end
    # Normalize keys to strings for consistent access
    if data.is_a?(Hash)
      data = data.transform_keys { |k| k.to_s }
    end

    # Strip template labels from body and infer caption if provided inline
    body_text, inferred = strip_template_tags(body.to_s)
    if inferred['body_sub_heading'].present? && data['body_sub_heading'].to_s.strip.empty?
      data['body_sub_heading'] = inferred['body_sub_heading']
    end

    html = simple_markdown_to_html(body_text)
    Result.new(data, html)
  end

  def self.extract_front_matter(text)
    lines = text.lines
    return [nil, text] unless lines.first&.match?(FRONT_MATTER_BOUNDARY)
    fm_lines = []
    i = 1
    while i < lines.length && !lines[i].match?(FRONT_MATTER_BOUNDARY)
      fm_lines << lines[i]
      i += 1
    end
    fm = fm_lines.join
    body = lines[(i + 1)..]&.join.to_s
    [fm, body]
  end

  # Minimal Markdown-ish to HTML for MVP (paragraphs, headers, links)
  def self.simple_markdown_to_html(text)
    html = text.gsub(/\r\n?/, "\n")
    # headers
    html = html.gsub(/^###\s*(.+)$/m, '<h3>\\1</h3>')
               .gsub(/^##\s*(.+)$/m, '<h2>\\1</h2>')
               .gsub(/^#\s*(.+)$/m, '<h1>\\1</h1>')
    # links [text](url)
    html = html.gsub(/\[([^\]]+)\]\(([^\)]+)\)/, '<a href="\\2" rel="noopener" target="_blank">\\1</a>')
    # paragraphs
    paragraphs = html.split(/\n{2,}/).map do |chunk|
      if chunk.strip.start_with?('<h') || chunk.strip.start_with?('<ul')
        chunk
      else
        "<p>#{ERB::Util.html_escape(chunk.strip).gsub(/\n/, '<br>')}</p>"
      end
    end
    paragraphs.join("\n")
  end

  # Remove common template labels from the body and capture inline caption.
  def self.strip_template_tags(text)
    lines = text.to_s.lines
    inferred = {}
    kept = []
    lines.each do |line|
      stripped = line.strip
      # Remove plain 'body:' markers
      next if stripped.match?(/^body\s*:?\s*$/i)
      # Capture caption: Body Sub Heading: <value>
      if (m = stripped.match(/^body[ _-]*sub[ _-]*heading\s*:\s*(.+)$/i))
        caption = m[1].to_s.strip
        inferred['body_sub_heading'] = caption if caption.present?
        next
      end
      kept << line
    end
    [kept.join, inferred]
  end
end
end
