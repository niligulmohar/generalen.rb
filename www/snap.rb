require 'rexml/document'

file = File.new('map2.svg')

doc = REXML::Document.new(file)

doc.elements.each('svg/g/path') do |elt|
  new_d = elt.attributes['d'].gsub(/\d+\.\d+/){ |match| (match.to_f/10).round*10 }
  elt.attributes['d'] = new_d
end

doc.write
