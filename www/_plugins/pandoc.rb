require "jekyll"
require "pandoc-ruby"

module Pandoc
  def pandoc(content)
    acros = content.scan(/\\acrodef\{(.*?)\}\{(.*?)\}/)
    acros.each do |acro|
      content = content.sub(/\\acp?\{(#{acro[0]})\}/){|r| "#{acro[1]}" + (r[3] == "p" ? "s" : "") + " (<span class='abbr'>#{r[$1]}" + (r[3] == "p" ? "s" : "") + "</span>)"}
      content = content.gsub(/\\acs?p?\{(#{acro[0]})\}/){|r| "<abbr title='#{acro[1]}'>#{r[$1]}" + (r[3] == "p" || r[4] == "p" ? "s" : "") + "</abbr>"}
    end

    content = content.gsub(/(\!\[.*?\]\((.+?)(\..+?)?\))\{(((?!darksrc).)*?)\}/){|r|
      darkf = r[$2] + "_dark" + ($3.nil? ? ".svg" : r[$3])
      extra_attr = (File.exists? darkf) ? " data-darksrc='#{darkf}'" : ""
      "#{r[$1]}{#{r[$4]}#{extra_attr}}"
    }

    @converter = PandocRuby.new(content, :from => :"markdown")
    content = @converter.to_html(
      :mathjax,
      :N,
      {
        :bibliography => :"_includes/references.bib",
        :csl => :"_includes/bibstyle.csl",
        :default_image_extension => :"svg",
      },
      "-F pandoc-crossref",
      "--citeproc",
      "-M nameInLink=true",
      "-M link-citations=true",
      "-M linkReferences=true",
      "-M reference-section-title=References",
      "-M figPrefix=Figure",
      "-M eqnPrefix=Equation",
      "-M tblPrefix=Table",
      "-M lstPrefix=List",
      "-M secPrefix=Section",
    )

    content = content.gsub(/<table.*?<\/table>/m){|r| "<div class='table-responsive'>" + r + "</div>"}
    content = content.gsub(/<span class="math display">.*?<\/span>/m){|r| "<span class='math-display-wrap'>" + r + "</span>"}
  end
end

class Jekyll::Converters::Markdown::PandocProcessor
  include Pandoc
  def initialize(config)
    @config = config
  end
  def convert(content)
    pandoc(content)
  end
end

Liquid::Template.register_filter(Pandoc)
