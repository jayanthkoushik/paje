Jekyll::Hooks.register :pages, :post_init do |page|
  if page.data["abstract"] then
    page.content = "# Abstract {#abstract .unnumbered}\n\n#{page.data['abstract']}\n\n" + page.content
  end

  if page.data["includes"] then
    for inc in page.data["includes"].reverse
      page.content = "{% include #{inc} %}\n\n" + page.content
    end
  end

  if page.data["appendices"] then
    page.content = page.content + "\n\n<div id='appendices'>\n\n"
    for app in page.data["appendices"]
      page.content = page.content + "---\n\n<div class='appendix'>\n\n{% include #{app} %}\n\n</div>\n\n"
    end
    page.content = page.content + "</div>\n"
  end
end
