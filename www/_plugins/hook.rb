Jekyll::Hooks.register :pages, :post_init do |page|
  hdr = ""

  page.data["includes"]&.each do |inc|
    hdr += "{% include #{inc} %}\n\n"
  end

  if page.data["abstract"]
    hdr += "# Abstract {#abstract .unnumbered}\n\n#{page.data['abstract']}\n\n"
  end

  page.content = hdr + page.content

  if page.data["appendices"]
    page.content = page.content + "\n\n<div id='appendices'>\n\n"
    for app in page.data["appendices"]
      page.content = page.content + "---\n\n<div class='appendix'>\n\n{% include #{app} %}\n\n</div>\n\n"
    end
    page.content = page.content + "</div>\n"
  end

  institutes = Hash[*(page.data["institute"] || []).collect {
    |inst| [inst["id"], inst["name"]] }.flatten
  ]

  for author in (page.data["author"] || [])
    if author["affiliation"]
      author["institutes"] = (author["affiliation"] || []).map { |aff| institutes[aff] }
    end
  end
end
