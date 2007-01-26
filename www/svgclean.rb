require 'rexml/document'

doc = REXML::Document.new(File.new('map4.svg'))

doc.delete_element('svg/defs')
doc.delete_element('svg/metadata')
doc.delete_element('svg/sodipodi:namedview')
nil while doc.delete_element('//tspan')
nil while doc.delete_element('//text()')
nil while doc.delete_element('//comment()')

doc.elements.each('//*') do |elt|
  elt.attributes.each do |att, val|
    if att.match(/:/) or (att == 'id' and val.length > 3) and not att.match(/^xmlns(:i|:so|$)/)
      elt.delete_attribute(att)
    end
  end
  elt.delete_attribute('inkscape:version')
  elt.delete_attribute('sodipodi:version')
  if elt.attributes['style']
    style = {}
    elt.attributes['style'].split(';').each do |pair|
      key, val = pair.split(':')
      style[key] = val
      if style['stroke'] == 'none' or style['stroke-width'] == '1px'
        style.delete_if{ |key, value| key.match(/^stroke/) }
      end
      if style['stroke-dasharray'] == 'none'
        style.delete('stroke-dasharray')
      end
    end
    %w[stroke fill stroke-width stroke-linejoin stroke-linecap stroke-dasharray stroke-dashoffset].each do |key|
      if style.has_key?(key) and not %w[miter butt].include?(style[key])
        elt.add_attribute(key, style[key])
      end
    end
    elt.delete_attribute('style')
  end
  %w[d x y stroke-width stroke-dasharray stroke-dashoffset].each do |attname|
    if elt.attributes[attname]
      new_att = elt.attributes[attname].gsub(/\d+\.\d+/){ |match| match.to_f.round.to_i }
      elt.attributes[attname] = new_att
    end
  end
  if elt.attributes['id'] and elt.attributes['id'].match(/^[ct]\d+$/)
    elt.add_attribute('onclick', 'c(%s)' % elt.attributes['id'][1..-1])
  end
end
doc.elements.each('//text'){ |elt| elt.add_text('?') }
doc.elements.each('//*[@id="w"]') do |elt|
  elt.add_attribute('font-weight', 'bold')
  elt.add_attribute('font-size', '24px')
  elt.add_attribute('font-family', 'Verdana, Helvetica, sans-serif')
  elt.add_attribute('text-align', 'center')
  elt.add_attribute('text-anchor', 'middle')
end
doc.elements.each('svg') do |elt|
  elt.add_attribute('onload', 'ol()')
  e = elt.add_element('script')
  e.add_attribute('type', 'text/ecmascript')
  e.add_text(REXML::CData.new( <<END_JS

var bgs = ['#00f','#f00','#0f0','#ff0','#f0f','#d80'];
var fgs = ['#fff','#fff','#000','#000','#000','#fff'];
function e(id) { return document.getElementById(id); }
function esa(id, a, v) { e(id).setAttribute(a, v); }
function o(n, o) { esa('c'+n, 'fill', bgs[o]); esa('t'+n, 'fill', fgs[o]); }
function a(n, a) { var t = e('t'+n);
                   while(t.hasChildNodes()) { t.removeChild(t.firstChild); }
                   t.appendChild(document.createTextNode(a)); }
function r(n) { return Math.floor(Math.random() * n); }
function c(n) { o(n, r(6)); a(n, r(11)+1); }
function ol() { if(document.location.hash) { alert('hej'); } }
END_JS
));
end

doc.write($stdout, 0)
