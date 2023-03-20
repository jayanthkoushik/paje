require "jekyll"
require "pandoc-ruby"
require "nokogiri"
require "katex"

class Jekyll::Converters::Markdown::PajeConverter
  def initialize(config)
    @config = config["paje"]

    Jekyll::Hooks.register :pages, :pre_render do |page|
      add_metadata_content(page)
    end

    Jekyll::Hooks.register :pages, :post_convert do |page|
      convert_acronyms(page)
      convert_pandoc(page)

      content_doc = Nokogiri::HTML.parse(page.content).xpath("//body")
      renumber_appendices(content_doc)
      render_math(content_doc)
      apply_theme(content_doc)
      page.content = content_doc.to_html
    end
  end

  # Dummy convert--all processing happens in other methods with hooks.
  def convert(content)
    content
  end

  def add_metadata_content(page)
    hdr = ""

    page.data["includes"]&.each { |inc| hdr += "{% include #{inc} %}\n\n" }

    if page.data["abstract"]
      hdr +=
        "# Abstract {#abstract .unnumbered}\n\n#{page.data["abstract"]}\n\n"
    end

    page.content = hdr + page.content

    if page.data["appendices"]
      page.content = page.content + "\n\n<div id='appendices'>\n\n"
      for app in page.data["appendices"]
        page.content =
          page.content +
            "---\n\n<div class='appendix'>\n\n{% include #{app} %}\n\n</div>\n\n"
      end
      page.content = page.content + "</div>\n"
    end

    institutes =
      Hash[
        *(page.data["institute"] || [])
          .collect { |inst| [inst["id"], inst["name"]] }
          .flatten
      ]

    for author in (page.data["author"] || [])
      if author["affiliation"]
        author["institutes"] = (author["affiliation"] || []).map do |aff|
          institutes[aff]
        end
      end
    end
  end

  def convert_acronyms(page)
    acros = page.content.scan(/\\acrodef\{(.*?)\}\{(.*?)\}/)
    acros.each do |acro|
      page.content =
        page
          .content
          .sub(/\\acp?\{(#{acro[0]})\}/) do |r|
            "#{acro[1]}" + (r[3] == "p" ? "s" : "") +
              " (<span class='abbr'>#{r[$1]}" + (r[3] == "p" ? "s" : "") +
              "</span>)"
          end

      page.content =
        page
          .content
          .gsub(/\\acs?p?\{(#{acro[0]})\}/) do |r|
            "<abbr title='#{acro[1]}'>#{r[$1]}" +
              (r[3] == "p" || r[4] == "p" ? "s" : "") + "</abbr>"
          end
    end
  end

  def convert_pandoc(page)
    converter = PandocRuby.new(page.content, from: :"markdown")
    page.content =
      converter.to_html(
        :katex,
        :N,
        {
          bibliography: "_includes/references.bib",
          csl: "_includes/bibstyle.csl",
          default_image_extension: @config["default_image_extension"]
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
        "-M equationNumberTeX=\\\\tag"
      )
  end

  def renumber_appendices(doc)
    doc
      .css(".appendix")
      .each_with_index do |appendix, i|
        appno = ((i % 26) + 65).chr * ((i / 26) + 1)

        # Change headings.
        appendix
          .css(".header-section-number")
          .each do |h|
            hparts = h.content.split(".", 2)
            hno = appno + (hparts.length > 1 ? ".#{hparts[1]}" : "")
            h.content = hno

            # Change links that point to this heading.
            hid = h.parent["id"]
            hid = appendix["id"] if hid.nil?
            doc
              .css("*[href='\##{hid}']")
              .each { |a| a.content = "Appendix\u00a0#{hno}" }
          end

        # Change figures.
        j = 0
        appendix
          .xpath(".//figcaption")
          .each do |figcap|
            next if figcap.parent.matches?("figure > figure")
            j += 1
            figno = appno + j.to_s()

            figdesc = figcap.content.split(": ", 2)[1]
            figcap.content = "Figure #{figno}: #{figdesc}"

            # Change links that point to this.
            figid = figcap.parent["id"]
            doc
              .css("*[href='\##{figid}']")
              .each { |a| a.content = "Figure\u00a0#{figno}" }

            # Change links to subfigures.
            figcap
              .parent
              .xpath(".//figure")
              .each do |subfig|
                subfigid = subfig["id"]
                subfigcap = subfig.at_xpath(".//figcaption")
                doc
                  .css("*[href='\##{subfigid}']")
                  .each do |a|
                    a.content = "Figure\u00a0#{figno} (#{subfigcap.content})"
                  end
              end
          end

        # Change tables.
        appendix
          .xpath(".//table")
          .each_with_index do |tab, j|
            tabno = appno + (j + 1).to_s()

            tabcap = tab.at_xpath(".//caption")
            tabdesc = tabcap.content.split(": ", 2)[1]
            tabcap.content = "Table #{tabno}: #{tabdesc}"

            # Change links to this.
            tabid = tab.parent["id"]
            doc
              .css("*[href='\##{tabid}']")
              .each { |a| a.content = "Table\u00a0#{tabno}" }
          end

        # Change equations.
        j = 0
        appendix
          .css(".math.display")
          .each do |eqn|
            neweq =
              eqn
                .content
                .gsub(/(?<=\\tag\{)\([0-9]+\)(?=\})/) do |t|
                  j += 1
                  appno + j.to_s()
                end
            next if neweq == eqn.content
            eqn.content = neweq

            # Change links to this.
            eqnid = eqn.parent["id"]
            eqno = appno + j.to_s()
            doc
              .css("*[href='\##{eqnid}']")
              .each { |a| a.content = "Equation\u00a0#{eqno}" }
          end
      end
  end

  def render_math(doc)
    # Remove extra `()` from equation tags.
    doc
      .css(".math.display")
      .each do |eqn|
        eqn.content = eqn.content.gsub(/(?<=\\tag\{)\(([0-9]+)\)(?=\})/, '\1')
      end

    doc
      .css("span.math")
      .each do |math|
        math.inner_html =
          Katex.render(math.text, display_mode: math.matches?(".display"))
      end
  end

  def apply_theme(doc)
    # Replace h5 with h6, h4 with h5, h3 with h4, h2 with h3.
    (5)
      .downto(2)
      .each do |i|
        hi, hii = "h#{i}", "h#{i + 1}"
        doc.xpath("//#{hi}").each { |h| h.name = hii }
      end
    # Replace non-title h1 with h2.
    doc.css("h1:not(#title)").each { |h| h.name = "h2" }

    # Bootstrap-ify figures.
    doc.css("figure img").wrap("<div style='overflow-x: auto'></div>")
    doc
      .css(".subfigures")
      .each do |subfig|
        figs = subfig > "figure"
        figs.add_class("subfigure")
        div =
          figs
            .last
            .add_next_sibling(
              "<div class='d-md-flex justify-content-md-evenly'></div>"
            )
            .first
        figs.each { |fig| fig.parent = div }
      end
    # Remove 'data-darksrc' from 'figures' (it's also on 'img's).
    doc.css("figure").each { |fig| fig.delete("data-darksrc") }

    # Set dark/light sources for images.
    doc
      .xpath("//img")
      .each do |img|
        src = img["src"]

        if img.key?("data-darksrc")
          # Image has an explicit dark source.
          darksrc = img["data-darksrc"]
          img["data-lightsrc"] = src
          if darksrc.empty?
            img["data-darksrc"] = src
            next
          end
        else
          # Image does not have an explicit dark source. Check if a file with
          # the same name as the source plus '_dark' exists, and if it does,
          # use it as the dark source.
          base, hasdot, ext = src.rpartition(".")
          darksrc = base.empty? ? (src + "_dark.svg") : (base + "_dark." + ext)
          if File.exist? darksrc
            img["data-darksrc"] = darksrc
            img["data-lightsrc"] = src
          else
            next
          end
        end

        # Prevent loading the image before theme is known.
        noscript_img = img.clone() # show default image when JS isn't available
        img.next = noscript_img
        noscript_img.wrap("<noscript></noscript>")
        img.delete("src")
        img.add_class("hidden")
      end

    # Bootstrap-ify tables.
    tables = doc.xpath("//table")
    tables.wrap("<div class='table-responsive'></div>")
    tables.add_class("table table-hover table-borderless mx-auto w-auto")
    tables.each do |table|
      # Add a class to bodies of headless tables, so they can be styled differently.
      if table.at_xpath(".//thead").nil?
        table.at_xpath(".//tbody").add_class("tbody-headless")
      end
      # Add a class to empty rows.
      table
        .xpath(".//tr")
        .each { |tr| tr.add_class("tr-empty") if tr.text.strip() == "" }
    end

    # Replace citation link text with number, and add popover for reference.
    doc
      .css(".citation a")
      .each do |citlink|
        citnum = citlink.at_xpath(".//sup")&.text
        next if citnum.nil?
        citlink.inner_html = citnum
        citlink["tabindex"] = "0"
        citlink["role"] = "button"

        ref = doc.at_css("*[id='#{citlink["href"][1..]}']")
        shortref =
          ref.at_css(".csl-right-inline").inner_html.gsub("\n", " ").strip()

        citlink.add_class("btn-link")
        citlink["data-bs-title"] = shortref
        citlink["data-bs-toggle"] = "tooltip"
        citlink["data-bs-container"] = "body"
        citlink["data-bs-html"] = "true"
      end

    # Remove short references from bibliography.
    doc
      .css("#refs .csl-entry")
      .each do |ref|
        ref.inner_html =
          ref.at_css(".csl-left-margin").inner_html.gsub("\n", " ").strip()
      end

    doc
      .css(".citation")
      .each do |citation|
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
    doc
      .css("a.footnote-ref")
      .each do |footref|
        reftext = doc.at_css("#{footref["href"]}").at_xpath(".//text()")
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
      doc
        .css("#refs div.csl-entry")
        .each do |bibentry|
          bibentry.name = "li"
          bibentry.delete("role")
        end

      # Move appendices to after bibliography.
      appendices = doc.at_css("#appendices")
      refs.after(appendices) unless appendices.nil?
    end

    # Theme block math.
    doc
      .css("span.math.display")
      .each do |math|
        bases = math.css(".base")
        base = bases.last
        next if base.nil?
        basewrap =
          base.add_next_sibling("<span class='mx-auto my-2'></span>").first
        basewrap.wrap(
          "<span class='d-inline-flex w-75 overflow-x-auto'></span>"
        )
        bases.each { |base| base.parent = basewrap }
      end
  end
end
