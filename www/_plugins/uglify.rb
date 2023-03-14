require "uglifier"

module Uglify
  def uglify(content)
    Uglifier.new(harmony: true).compile(content)
  end
end

Liquid::Template.register_filter(Uglify)
