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
      "-M equationNumberTeX=\\\\tag",
    )

    doc = Nokogiri::HTML.parse(content).xpath("//body")

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

    # Set dark/light sources for images.
    doc.xpath("//img").each do |img|
      src = img["src"]

      if img.key?("data-darksrc")
        # Image has an explicit dark source.
        darksrc = img["data-darksrc"]
        if darksrc.empty?
          img["data-darksrc"] = src
        else
          # Prevent loading the image before theme is known.
          img.wrap("<noscript class='img-noscript'></noscript>")
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
          img.wrap("<noscript class='img-noscript'></noscript>")
        end
      end
    end

    # Bootstrap-ify tables.
    tables = doc.xpath("//table")
    tables.wrap("<div class='table-responsive'></div>")
    tables.add_class("table mx-auto w-auto")
    doc.xpath("//tbody").add_class("table-group-divider")

    # Replace citation link text with number, and add popover for reference.
    doc.css(".citation a").each do |citlink|
      citnum = citlink.at_xpath(".//sup")&.text
      if citnum.nil?
        next
      end
      citlink.inner_html = citnum
      citlink["tabindex"] = "0"
      citlink["role"] = "button"

      ref = doc.at_css("*[id='#{citlink['href'][1..]}']")
      shortref = ref.at_css(".csl-right-inline").inner_html.gsub("\n", " ").strip()

      citlink.add_class("btn-link")
      citlink["data-bs-title"] = shortref
      citlink["data-bs-toggle"] = "tooltip"
      citlink["data-bs-container"] = "body"
      citlink["data-bs-html"] = "true"
    end

    # Remove short references from bibliography.
    doc.css("#refs .csl-entry").each do |ref|
      ref.inner_html = ref.at_css(".csl-left-margin").inner_html.gsub("\n", " ").strip()
    end

    doc.css(".citation").each do |citation|
      cittext = citation.at_xpath(".//text()").to_s()
      citlinks = citation.xpath(".//a")
      # Superscript citation numbers.
      sup_citlinks = "<sup>" + citlinks.map(&:to_s).join(",") + "</sup>"
      if cittext != citlinks[0].text.to_s()
        # Remove extra space from long citations.
        citation.inner_html = cittext.rstrip() + sup_citlinks
      else
        citation.inner_html = sup_citlinks
      end
    end

    # Add popovers for footnote references.
    doc.css("a.footnote-ref").each do |footref|
      reftext = doc.at_css("#{footref['href']}").at_xpath(".//text()")
      footref.add_class("btn-link")
      footref["tabindex"] = "0"
      footref["role"] = "button"
      footref["data-bs-title"] = reftext
      footref["data-bs-toggle"] = "tooltip"
      footref["data-bs-container"] = "body"
      footref["data-bs-html"] = "true"
    end

    # Convert footnotes section to div.
    doc.at_css("#footnotes")&.name = "div"

    # Convert bibliography to list.
    refs = doc.at_css("#refs")
    unless refs.nil?
      refs.name = "ol"
      refs.delete("role")
      doc.css("#refs div.csl-entry").each do |bibentry|
        bibentry.name = "li"
        bibentry.delete("role")
      end

      # Move appendices to after bibliography.
      appendices = doc.at_css("#appendices")
      unless appendices.nil?
        refs.after(appendices)
      end
    end

    # Renumber appendices.
    doc.css(".appendix").each_with_index do |appendix, i|
      appno = ((i % 26) + 65).chr * ((i / 26) + 1)

      # Change headings.
      appendix.css(".header-section-number").each do |h|
        hparts = h.content.split(".", 2)
        hno = appno + (hparts.length > 1 ? ".#{hparts[1]}" : "")
        h.content = hno

        # Change links that point to this heading.
        hid = h.parent["id"]
        if hid.nil?
          hid = appendix["id"]
        end
        doc.css("*[href='\##{hid}']").each do |a|
          a.content = "Appendix #{hno}"
        end
      end

      # Change figures.
      j = 0
      appendix.xpath(".//figcaption").each do |figcap|
        if figcap.parent.matches?(".subfigure")
          next
        end
        j += 1
        figno = appno + j.to_s()

        figdesc = figcap.content.split(": ", 2)[1]
        figcap.content = "Figure #{figno}: #{figdesc}"

        # Change links that point to this.
        figid = figcap.parent["id"]
        doc.css("*[href='\##{figid}']").each do |a|
          a.content = "Figure #{figno}"
        end

        # Change links to subfigures.
        figcap.parent.css(".subfigure").each do |subfig|
          subfigid = subfig["id"]
          subfigcap = subfig.at_xpath(".//figcaption")
          doc.css("*[href='\##{subfigid}']").each do |a|
            a.content = "Figure #{figno} (#{subfigcap.content})"
          end
        end
      end

      # Change tables.
      appendix.xpath(".//table").each_with_index do |tab, j|
        tabno = appno + (j + 1).to_s()

        tabcap = tab.at_xpath(".//caption")
        tabdesc = tabcap.content.split(": ", 2)[1]
        tabcap.content = "Table #{tabno}: #{tabdesc}"

        # Change links to this.
        tabid = tab.parent.parent["id"]
        doc.css("*[href='\##{tabid}']").each do |a|
          a.content = "Table #{tabno}"
        end
      end

      # Change equations.
      j = 0
      appendix.css(".math.display").each do |eqn|
        neweq = eqn.content.gsub(/(?<=\\tag\{)\([0-9]+\)(?=\})/) { |t|
          j += 1
          appno + j.to_s()
        }
        if neweq == eqn.content
          next
        end
        eqn.content = neweq

        # Change links to this.
        eqnid = eqn.parent["id"]
        eqno = appno + j.to_s()
        doc.css("*[href='\##{eqnid}']").each do |a|
          a.content = "Equation #{eqno}"
        end
      end
    end

    # Remove extra `()` from equation tags.
    doc.css(".math.display").each do |eqn|
      eqn.content = eqn.content.gsub(/(?<=\\tag\{)\(([0-9]+)\)(?=\})/, '\1')
    end

    # Render math with Katex.
    doc.css("span.math").each do |math|
      math.inner_html = Katex.render(math.text, :display_mode => math.matches?(".display"))
      if math.matches?(".display")
        bases = math.css(".base")
        base = bases.last
        if base.nil?
          next
        end
        basewrap = base.add_next_sibling("<span class='mx-auto my-2'></span>").first
        basewrap.wrap("<span class='d-inline-flex w-75 overflow-x-auto'></span>")
        bases.each do |base|
          base.parent = basewrap
        end
      end
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
