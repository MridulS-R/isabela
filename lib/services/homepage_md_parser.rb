require 'yaml'

class HomepageMdParser
  FRONT_MATTER_BOUNDARY = /^---\s*$/.freeze

  Result = Struct.new(:metadata, :html)

  def self.parse(io)
    text = io.read.to_s
    fm, body = extract_front_matter(text)
    data = (fm.present? ? YAML.safe_load(fm) : {}) || {}
    html = simple_markdown_to_html(body.to_s)
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
end

