require "jekyll"
require "pandoc-ruby"
require "nokogiri"
require "katex"

class Jekyll::Converters::Markdown::PajeConverter
  def initialize(config)
    @config = config["paje"]

    Jekyll::Hooks.register :pages, :pre_render do |page|
      puts "\nrunning pre render hooks for page '#{page.data["title"]}'"
      add_metadata_content(page)
    end

    Jekyll::Hooks.register :pages, :post_convert do |page|
      puts "\nrunning post convert hooks for page '#{page.data["title"]}'"
      convert_acronyms(page)
      convert_pandoc(page)

      content_doc = Nokogiri::HTML.parse(page.content).at_xpath("//body")
      next if content_doc.nil?

      # Wrap content in div.
      content_doc.name = "div"
      content_doc["id"] = "content"
      content_doc.wrap("<body></body>")
      content_doc = content_doc.parent

      renumber_appendices(content_doc)
      render_math(content_doc)
      move_appendix_ids(content_doc)
      sanitize_hids(content_doc)
      move_appendices(content_doc)
      add_toc(content_doc) if !page.data["notoc"]
      apply_theme(content_doc)
      page.content = content_doc.inner_html
    end
  end

  # Dummy convert--all processing happens in other methods with hooks.
  def convert(content)
    content
  end

  def add_metadata_content(page)
    puts "+ updating metadata"
    hdr = ""

    page.data["includes"]&.each do |inc|
      hdr += "{% include #{inc} %}\n\n"
      puts "|- added include statement for '#{inc}'"
    end

    if page.data["abstract"]
      hdr +=
        "# Abstract {#abstract .unnumbered}\n\n#{page.data["abstract"]}\n\n"
      puts "|- added abstract"
    end

    page.content = hdr + page.content

    page.data["sections"]&.each do |sec|
      page.content += "\n\n{% include #{sec} %}"
    end

    if page.data["appendices"]
      page.content = page.content + "\n\n<div id='appendices'>\n\n"
      for app in page.data["appendices"]
        page.content =
          page.content +
            "---\n\n<div class='appendix'>\n\n{% include #{app} %}\n\n</div>\n\n"
        puts "|- added appendix '#{app}'"
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
    puts "|- updated author list metadata with institute names"
  end

  def convert_acronyms(page)
    puts "+ converting acronyms"
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
      puts "|- converted '#{acro[0]}'"
    end
  end

  def convert_pandoc(page)
    puts "+ converting markdown"
    converter = PandocRuby.new(page.content, from: :"markdown")
    cfg_args = {}
    if page.data["bibliography"]
      cfg_args["bibliography"] = File.join(
        "_includes",
        page.data["bibliography"]
      )
      puts "|- included bibliography from '#{cfg_args["bibliography"]}'"
      cfg_args["csl"] = "_includes/bibstyle.csl"
    end
    if page.data["default_image_extension"]
      cfg_args["default_image_extension"] = page.data["default_image_extension"]
    else
      cfg_args["default_image_extension"] = @config["default_image_extension"]
    end
    puts "|- set default image extension to '#{cfg_args["default_image_extension"]}'"
    page.content =
      converter.to_html(
        :katex,
        :N,
        cfg_args,
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
    puts "|- converted markdown to html with pandoc"
  end

  def renumber_appendices(doc)
    puts "+ renumbering appendices"
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
        puts "|- updated appendix: '#{i}'->'#{appno}'"
      end
  end

  def render_math(doc)
    puts "+ rendering math"
    # Remove extra '()' from equation tags.
    doc
      .css(".math.display")
      .each do |eqn|
        eqn.content = eqn.content.gsub(/(?<=\\tag\{)\(([0-9]+)\)(?=\})/, '\1')
      end
    puts "|- removed extra '()' from equation tags"

    doc
      .css("span.math")
      .each do |math|
        math.inner_html =
          Katex.render(math.text, display_mode: math.matches?(".display"))
      end
    puts "|- converted math with katex"
  end

  def apply_theme(doc)
    puts "+ applying theme"

    # Theme toc sidebar.
    sidebar = doc.at_css("#toc-sidebar")
    content = doc.at_css("#content")
    if sidebar
      # Add col classes to sidebar and content.
      content.add_class("order-3")
      sidebar.add_class(
        "col-11 col-sm-10 col-md-2 order-2 order-md-4 mt-2 mb-4 my-md-0"
      )
      sidebar.wrap(
        "<div class='row justify-content-center justify-content-md-start'></div>"
      )

      # Style toc.
      toc = sidebar.at_css("#toc")
      toc.add_class("collapse d-md-block pt-2 pt-md-0 text-nowrap")
      toc.css("ul").add_class("list-unstyled")

      # Add toggle button.
      tocbtn =
        toc.add_previous_sibling(
          "<button type='button'>On this page</button>"
        ).first
      tocbtn[
        "class"
      ] = "btn btn-link text-decoration-none d-md-none collapsed dropdown-toggle border border-secondary rounded-1 text-body-secondary"
      tocbtn["data-bs-toggle"] = "collapse"
      tocbtn["data-bs-target"] = "#toc"

      # Add toc title.
      tocbtn.add_next_sibling("<hr class='d-none d-md-block ms-3'>")
      tocbtn.add_next_sibling(
        "<strong class='d-none d-md-block ms-3'>On this page</strong>"
      )

      # Add dummy col.
      sidebar.add_next_sibling(
        "<div class='col-2 order-1 d-none d-md-block'></div>"
      )
      puts "|- themed toc sidebar"
    end

    # Replace h5 with h6, h4 with h5, h3 with h4, h2 with h3.
    (5)
      .downto(2)
      .each do |i|
        hi, hii = "h#{i}", "h#{i + 1}"
        doc.xpath("//#{hi}").each { |h| h.name = hii }
        puts "|- replaced '#{hi}'s with '#{hii}'s"
      end
    # Replace non-title h1 with h2.
    doc.css("h1:not(#title)").each { |h| h.name = "h2" }
    puts "|- replaced non-title 'h1's with 'h2's"

    # Bootstrap-ify figures.
    doc.css("figure img").wrap("<div style='overflow-x: auto'></div>")
    doc
      .css(".subfigures")
      .each do |subfig|
        figs = subfig > "figure"
        figs.add_class("subfigure px-2")
        div =
          figs
            .last
            .add_next_sibling(
              "<div class='d-md-flex flex-wrap justify-content-md-center'></div>"
            )
            .first
        figs.each { |fig| fig.parent = div }
      end
    # Remove 'data-darksrc' from 'figures' (it's also on 'img's).
    doc.css("figure").each { |fig| fig.delete("data-darksrc") }
    puts "|- themed figures"

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
            puts "|- empty 'darksrc' for '#{src}': set to 'src'"
            next
          end
        else
          # Image does not have an explicit dark source. Check if a file with
          # the same name as the source plus '_dark' exists, and if it does,
          # use it as the dark source.
          base, hasdot, ext = src.rpartition(".")
          darksrc = base.empty? ? (src + "_dark.svg") : (base + "_dark." + ext)
          if File.exist? darksrc
            puts "|- found dark source for '#{src}': '#{darksrc}'"
            img["data-darksrc"] = darksrc
            img["data-lightsrc"] = src
          else
            puts "|- no dark source for '#{src}'"
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
    puts "|- themed tables"

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
    puts "|- added popovers for citations"

    # Remove short references from bibliography.
    doc
      .css("#refs .csl-entry")
      .each do |ref|
        ref.inner_html =
          ref.at_css(".csl-left-margin").inner_html.gsub("\n", " ").strip()
      end
    puts "|- removed short references from bibliography"

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
    puts "|- converted citations to superscripts"

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
    puts "|- added popovers for footnotes"

    # Convert footnotes section to div.
    doc.at_css("#footnotes")&.name = "div"
    puts "|- converted footnotes section to div"

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
    end
    puts "|- converted bibliography to list"

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
    puts "|- themed block math"

    # Add col classes to content elements.
    doc
      .css("#content, .appendix")
      .each do |section|
        section.add_class("row justify-content-center")
        section.children.each do |child|
          if child.matches?("h1, h2, h3, h4, h5, h6, p")
            child.add_class(
              "col-11 col-sm-10 col-md-8 col-lg-7 col-xl-7 col-xxl-7"
            )
          elsif child.matches?("ul, ol")
            child.wrap(
              "<div class='col-11 col-sm-10 col-md-8 col-lg-7 col-xl-7 col-xxl-7'></div>"
            )
          end
        end
      end
    puts "|- added 'col-' classes to content elements"

    doc
      .css("#appendices hr")
      .each do |hr|
        hr.add_class(
          "mx-auto col-11 col-sm-10 col-md-8 col-lg-7 col-xl-7 col-xxl-7"
        )
      end
    puts "|- added 'col-' classes to appendix 'hr's"
    # Make figures into rows so they can expand beyond the content container.
    doc.css("figure").add_class("row")
    # Figure captions are still constrained.
    doc.css("figcaption").add_class(
      "mx-auto col-11 col-sm-10 col-md-8 col-lg-7 col-xl-7 col-xxl-7"
    )
    puts "|- added 'row' and 'col-' classes to figures"
  end

  def add_toc(doc)
    puts "+ adding table of contents"
    content = doc.at_css("#content")
    if content.nil?
      puts "|- nothing to add: no content"
      return
    end

    sidebar = content.add_previous_sibling("<div id='toc-sidebar'></div>").first
    toc = sidebar.add_child("<div id='toc'></div>").first
    nav = toc.add_child("<nav id='toc-body'></nav>").first
    navlist = nav.add_child("<ul></ul>").first
    doc
      .xpath("//h1")
      .each do |h1|
        li = navlist.add_child("<li></li>").first
        htext =
          h1
            .at_xpath(
              ".//text()[not(parent::span[@class='header-section-number'])]"
            )
            .content
            .strip()
        a = li.add_child("<a href='\##{h1["id"]}'>#{htext}</a>").first
        puts "|- linked '\##{h1["id"]}' ('#{htext}')"

        # Create a sub list for h2 elements below this h1, and up to the next h1.
        h2s =
          h1.xpath(
            "following-sibling::h2[preceding-sibling::h1[1][@id='#{h1["id"]}']]"
          )
        if h2s
          subnavlist = li.add_child("<ul></ul>").first
          h2s.each do |h2|
            subli = subnavlist.add_child("<li></li>").first
            subhtext =
              h2
                .at_xpath(
                  ".//text()[not(parent::span[@class='header-section-number'])]"
                )
                .content
                .strip()
            suba =
              subli.add_child("<a href='\##{h2["id"]}'>#{subhtext}</a>").first
            puts "   - linked '\##{h2["id"]}' ('#{subhtext}')"
          end
        end
      end
  end

  def move_appendix_ids(doc)
    # Move appendix ids from sections to headers.
    puts "+ moving appendix ids"
    doc
      .css(".appendix")
      .each do |app|
        appid = app["id"]
        app.delete("id")
        app.at_css("h1")["id"] = appid
        puts "|- updated '\##{appid}'"
      end
  end

  def sanitize_hids(doc)
    puts "+ sanitizing h1/h2 ids"
    doc
      .css("h1, h2")
      .each do |h|
        oldid = h["id"]
        newid = oldid.gsub(/[:.&]/, "-")
        next if newid == oldid
        if doc.at_css("\##{newid}")
          puts "ERROR: id clash sanitizing '#{oldid}'"
          exit 1
        end
        h["id"] = newid
        doc
          .css("a[href='\##{oldid}']")
          .each do |a|
            a["href"] = "\##{newid}"
            puts "|- updated '\##{oldid}'->'\##{newid}'"
          end
      end
  end

  def move_appendices(doc)
    refs = doc.at_css("#refs")
    appendices = doc.at_css("#appendices")
    unless appendices.nil? || refs.nil?
      puts "+ moving appendices to after bibliography"
      refs.after(appendices)
    end
  end
end
