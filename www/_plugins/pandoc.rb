require "jekyll"
require "pandoc-ruby"
require "nokogiri"
require "katex"

module Pandoc
  def pandoc(content)
    acros = content.scan(/\\acrodef\{(.*?)\}\{(.*?)\}/)
    acros.each do |acro|
      content = content.sub(/\\acp?\{(#{acro[0]})\}/){|r| "#{acro[1]}" + (r[3] == "p" ? "s" : "") + " (<span class='abbr'>#{r[$1]}" + (r[3] == "p" ? "s" : "") + "</span>)"}
      content = content.gsub(/\\acs?p?\{(#{acro[0]})\}/){|r| "<abbr title='#{acro[1]}'>#{r[$1]}" + (r[3] == "p" || r[4] == "p" ? "s" : "") + "</abbr>"}
    end

    @converter = PandocRuby.new(content, :from => :"markdown")
    content = @converter.to_html(
      :katex,
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

    doc = Nokogiri::HTML.parse(content)

    # Replace h5 with h6, h4 with h5, h3 with h4, h2 with h3.
    (5).downto(2).each do |i|
      hi, hii = "h#{i}", "h#{i + 1}"
      doc.xpath("//#{hi}").each do |h|
        h.name = hii
      end
    end
    # Replace non-title h1 with h2.
    doc.css("h1:not(#title)").each do |h|
      h.name = "h2"
    end
    # Change footnote wrapper from section to div.
    doc.css("section#footnotes").each do |sec|
      sec.name = "div"
    end

    # Set dark/light sources for images.
    doc.xpath("//img").each do |img|
      src = img["src"]

      if img.key?("data-darksrc")
        # Image has an explicit dark source.
        darksrc = img["data-darksrc"]
        if darksrc.empty?
          img["data-darksrc"] = src
        end
        img["data-lightsrc"] = src
      else
        # Image does not have an explicit dark source. Check if a file with
        # the same name as the source plus '_dark' exists, and if it does,
        # use it as the dark source.
        base, hasdot, ext = src.rpartition(".")
        darksrc = base.empty? ? (src + "_dark.svg") : (base + "_dark." + ext)
        if File.exists? darksrc
          img["data-darksrc"] = darksrc
          img["data-lightsrc"] = src
        end
      end
    end

    # Render math with Katex.
    doc.css("span.math").each do |math|
      math.inner_html = Katex.render(math.text, :display_mode => math.matches?(".display"))
      if math.matches?(".display")
        math.wrap("<span class='math-display-wrap'></span>")
      end
    end

    # Bootstrap-ify tables.
    tables = doc.xpath("//table")
    tables.wrap("<div class='table-responsive'></div>")
    tables.add_class("table mx-auto w-auto")
    doc.xpath("//tbody").add_class("table-group-divider")

    # Bootstrap-ify figures.
    doc.css("figure img").wrap("<div style='overflow-x: auto'></div>")
    doc.css(".subfigures").each do |subfig|
      figs = subfig > "figure"
      figs.add_class("subfigure")
      div = figs.last.add_next_sibling("<div class='d-md-flex justify-content-md-evenly'></div>").first
      figs.each do |fig|
        fig.parent = div
      end
    end

    # Add popovers for foornote references.
    doc.css("a.footnote-ref").each do |footref|
      if footref.parent.matches?("span.citation")
        # If reference is a citation, replace ibids with the actual value.
        cits = doc.css("#{footref['href']} a[role='doc-biblioref']")
        reftexts = cits.map { |cit|
          bib = cit["href"]
          loop do
            txt = cit.inner_html.gsub("\n", " ")
            break txt if txt != "Ibid."
            cit = cit.parent.parent.previous_element.css("a[href='#{bib}']").first
          end
        }
        reftext = reftexts.join("<br><br>")
      else
        # If reference is a footnote, get the footnote text.
        reftext = doc.css("#{footref['href']}").xpath(".//text()")[0]
      end
      footref["data-bs-title"] = reftext
      footref["data-bs-toggle"] = "tooltip"
      footref["data-bs-container"] = "body"
      footref["data-bs-html"] = "true"
    end

    content = doc.to_html
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
