require "jekyll"
require "pandoc-ruby"

module Jekyll
    module PandocFilter
        def self.convert(content)
            acropat = /\\acrodef\{(.*?)\}\{(.*?)\}/
            acros = content.scan(acropat)
            acros.each do |acro|
                pat = /\\acp?\{(#{acro[0]})\}/
                content = content.sub(pat){|r| "#{acro[1]}" + (r[3] == "p" ? "s" : "") + " (<span class='abbr'>#{r[$1]}" + (r[3] == "p" ? "s" : "") + "</span>)"}
                pat = /\\acs?p?\{(#{acro[0]})\}/
                content = content.gsub(pat){|r| "<abbr title='#{acro[1]}'>#{r[$1]}" + (r[3] == "p" || r[4] == "p" ? "s" : "") + "</abbr>"}
            end

            @converter = PandocRuby.new(
                content,
                :from => :"markdown"
            )
            @converter.to_html(
                :mathjax,
                :N,
                {
                    :bibliography => :"_includes/references.bib",
                    :csl => :"_includes/bibstyle.csl",
                    :"default-image-extension" => :"png",
                },
                "-F pandoc-crossref -F pandoc-citeproc",
                "-M reference-section-title=References -M link-citations=true -M linkReferences=true -M figPrefix=Figure -M eqnPrefix=Equation -M tblPrefix=Table -M lstPrefix=List -M secPrefix=Section -M nameInLink=true"
            )
        end

        def pandoc(content)
            Jekyll::PandocFilter::convert(content)
        end
    end

    class Converters::Markdown::PandocProcessor
        include Jekyll::PandocFilter
        def initialize(config)
            @config = config
        end
        def convert(content)
            Jekyll::PandocFilter::convert(content)
        end
    end
end

Liquid::Template.register_filter(Jekyll::PandocFilter)
