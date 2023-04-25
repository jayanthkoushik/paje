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
      acronyms = extract_acronyms(page)
      convert_pandoc(page)
      convert_acronyms(page, acronyms)

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
      add_permalinks(content_doc)
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

  def extract_acronyms(page)
    puts "+ extracting acronyms"
    # First, get all acronym definitions and store them in a hash.
    acronyms = {}
    acrodefs = page.content.scan(/\\acrodef\{([^{]+)\}\{([^{]+)\}/)
    acrodefs.each do |short, long|
      puts "|- found '#{short}' => '#{long}'"
      acronyms[short] = long
      # Now, replace all occurrences of this acronym with a placeholder.
      # Acronyms are not directly converted here because that messes up
      # the formatting of tables.
      page.content =
        page
          .content
          .gsub(/\\ac(s?)(p?)\{#{short}\}/) do |r|
            # Replace with a placeholder of the same length.
            # The base placeholder character if '\ufdd0' ('@' in this comment from now).
            # '\ac{xyz}' -> 'xyz@@@@@'  (5 extra characters correponding to '\ac{}')
            # '\acs{xyz}' -> 'xyz@@@@@s'
            # '\acp{xyz}' -> 'xyz@@@@@p'
            # '\acsp{xyz}' -> 'xyz@@@@@sp'
            repl = short + ("\ufdd0" * 5)
            if r[3] == "s" || r[3] == "p"
              repl += r[3]
              repl += "p" if r[4] == "p"
            end
            repl
          end
    end
    acronyms
  end

  def convert_acronyms(page, acronyms)
    puts "+ converting acronyms"
    # All acronyms have been replaced with placeholders. Now, we can
    # safely replace them with the actual HTML.
    acronyms.each do |short, long|
      long_shown = false
      page.content =
        page
          .content
          # The placeholder is of the form '<short>@@@@@[s][p]' where
          # '@' is '\ufdd0'.
          .gsub(/#{short}\ufdd0{5}(s?)(p?)/) do |r|
            is_short = r[$1] == "s"
            is_plural = r[$2] == "p"
            abbr_inner = short + (is_plural ? "s" : "")
            if !is_short && !long_shown
              abbr = "<span class='abbr'>#{abbr_inner}</span> (#{long})"
              long_shown = true
            else
              abbr = "<abbr title='#{long}'>#{abbr_inner}</abbr>"
            end
            puts "|- converted '\\ac#{r[$1]}#{r[$2]}{#{short}}' -> '#{abbr}'"
            abbr
          end
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
        "-M crossrefYaml=_includes/crossref.yml"
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

            figdesc = figcap.inner_html.split(": ", 2)[1]
            figcap.inner_html = "Figure #{figno}: #{figdesc}"

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
                    a.inner_html =
                      "Figure\u00a0#{figno}&nbsp;#{subfigcap.inner_html}"
                  end
              end
          end

        # Change tables.
        appendix
          .xpath(".//table")
          .each_with_index do |tab, j|
            tabno = appno + (j + 1).to_s()

            tabcap = tab.at_xpath(".//caption")
            tabdesc = tabcap.inner_html.split(": ", 2)[1]
            tabcap.inner_html = "Table #{tabno}: #{tabdesc}"

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
      sidebar.add_class("col-11 col-sm-10 col-md-2 mt-2 mb-4 my-md-0")
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
      tocbtn["aria-expanded"] = "false"
      tocbtn["aria-controls"] = "toc"

      # Add toc title.
      tocbtn.add_next_sibling(
        "<p id='toc-title' class='d-none d-md-block ms-3 pb-3 text-nowrap'></p>"
      )

      tocbtn.wrap("<p class='my-0'></p>")

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
        figs.add_class("subfigure px-1")
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

    # Create popovers for citation links.
    puts "|- + fixing citations"
    doc
      .css(".citation")
      .each do |cit|
        cit.inner_html = cit.inner_html.gsub("\n", " ").strip()
        long_cit_author_lists = []
        cit
          .css("a")
          .each do |citlink|
            puts "   |- + fixing citation link '#{citlink.inner_html}'"
            # Extract citation number from inside '<sup></sup>'.
            citnum = citlink.at_xpath(".//sup")&.text
            puts "      |- no citation number found: skipping" if citnum.nil?
            puts "      |- found citation number '#{citnum}'"

            # Extract locator wrapped between '\uFDD0' characters.
            locator =
              citlink
                .inner_html
                .match(/\uFDD0(.+)\uFDD0/)
                &.captures
                &.first
                .to_s
                .strip()
            puts "      |- found locator '#{locator}'"

            # Find reference corresponding to citation link.
            ref = doc.at_css("*[id='#{citlink["href"][1..]}']")
            ref.inner_html = ref.inner_html.gsub("\n", " ").strip()
            shortref =
              ref
                .at_css(".csl-right-inline")
                .inner_html
                .gsub("\uFDD1", "")
                .strip()
            puts "      |- found citation reference '#{shortref}'"

            # Check if it is a long citation. For long citation, the author list is
            # moved outside the link by pandoc, so the marker '\uFDD1' is not present.
            if citlink.inner_html.include? "\uFDD1"
              puts "      |- identified as short citation"
            else
              puts "      |- identified as long citation"
              # Get the author list from the reference, wrapped between '\uFDD1' characters.
              authorlist =
                ref.inner_html.match(/\uFDD1(.+)\uFDD1/)&.captures&.first
              puts "      |- found author list '#{authorlist}'"
              long_cit_author_lists << authorlist
            end

            # Add attributes for bootstrap popover.
            citlink.add_class("btn-link")
            citlink["tabindex"] = "0"
            citlink["role"] = "button"
            citlink["data-bs-title"] = shortref
            citlink["data-bs-toggle"] = "tooltip"
            citlink["data-bs-container"] = "body"
            citlink["data-bs-html"] = "true"
            puts "      |- added popover attributes"

            # Replace citation link text with number.
            citlink.inner_html = citnum
            puts "      |- replaced citation link text with number '#{citlink.inner_html}'"

            # Add locator as a sibling to the citation link.
            unless locator.nil? || locator.empty?
              loc =
                citlink.add_next_sibling(
                  "<span class='locator'>(#{locator})</span>"
                ).first
              puts "      |- added locator '#{loc}'"
            end
          end

        # Wrap long citation author lists in spans.
        next if long_cit_author_lists.empty?
        puts "   |- + wrapping author lists inside '#{cit.inner_html}'"
        long_cit_author_lists.uniq.each do |author_list|
          puts "      |- wrapping author list '#{author_list}'"
          cit.inner_html =
            cit.inner_html.sub(
              / ?#{author_list} ?/,
              "<span class='authors'>#{author_list}</span>"
            )
        end
        puts "   |- + wrapped author lists: new inner html is '#{cit.inner_html}'"
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

    # Convert citations to superscripts.
    doc
      .css(".citation")
      .each do |citation|
        citation.wrap("<span class='citation-wrapper'></span>")
        # Move author list, previously wrapped into a span, outside the citation.
        citation
          .css(".authors")
          &.reverse
          .each { |author_list| citation.add_previous_sibling(author_list) }
        # Convert the citation to a superscript.
        citation.name = "sup"
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
      .css(".math.display .katex-html")
      .each do |math|
        math.add_class("d-flex flex-wrap justify-content-center")
        tag = math.at_css(".tag")
        bases = math.css(".base")
        baseswrap =
          bases
            .first
            .add_previous_sibling(
              "<span class='overflow-x-auto px-2 py-2'></span>"
            )
            .first
        bases.each { |base| base.parent = baseswrap }
        next if tag.nil?
        tag.add_class("flex-grow-1 text-end mb-2")
        dummy =
          bases
            .first
            .parent
            .add_previous_sibling(
              "<span class='flex-grow-1 dummy-math-tag'></span>"
            )
            .first
        dummy.inner_html = tag.inner_html
      end
    doc.css(".katex-display").remove_class("katex-display")
    puts "|- themed block math"

    # Add col classes to content elements.
    col_classes = "col-11 col-sm-10 col-md-8 offset-md-1 col-lg-7 offset-lg-0"
    doc
      .css("#content, .appendix")
      .each do |section|
        section.add_class("row justify-content-center")
        section.children.each do |child|
          if child.matches?("h1, h2, h3, h4, h5, h6, p, .math.display")
            child.add_class(col_classes)
          elsif child.matches?("ul, ol")
            child.wrap("<div class='#{col_classes}'></div>")
          end
        end
      end
    doc.css("#footnotes").add_class(col_classes)
    puts "|- added 'col-' classes to content elements"

    doc
      .css("#appendices hr")
      .each { |hr| hr.add_class("mx-auto #{col_classes}") }
    puts "|- added 'col-' classes to appendix 'hr's"

    # Put tables and figures in larger max size columns.
    doc.css("figure").add_class(
      "col-11 col-sm-10 col-md-8 offset-md-1 offset-lg-0"
    )
    doc
      .css(".table-responsive")
      .each do |table|
        table.parent.add_class(
          "col-11 col-sm-10 col-md-8 offset-md-1 offset-lg-0"
        )
      end
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

  def add_permalinks(doc)
    puts "+ adding permalinks"
    doc
      .css("h1, h2, h3")
      .each do |h|
        next if h["id"].nil?
        h.add_child("<a class='header-link' href='\##{h["id"]}'></a>")
        puts "|- added permalink to '\##{h["id"]}'"
      end
  end
end
