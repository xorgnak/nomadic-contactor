# coding: utf-8
require 'victor'
require 'rqrcode_core'

module NOMADIC
  class Logo
    def initialize index, h={}

      if h[:branded]
        he = 1536
      else
        he = 1360
      end
      svg = Victor::SVG.new viewBox: "0 0 1024 #{he}"
      
      svg.rect x: 0, y: 0, width: 1024, height: he, fill: h[:bg] || '#fff'
      
      svg.rect x: 0, y: 0, width: 804, height: 200, fill: h[:fg] || '#000'
      
      svg.text "#{h[:object].upcase}x#{index}", x: 20, y: 160, font_family: 'monospace', font_weight: 'bold', font_size: 180, fill: h[:bg] || '#fff'
      
      svg.rect x: 824, y: 0, width: 200, height: 200, fill: h[:fg] || '#000'
      start = 260
      qr = RQRCodeCore::QRCode.new("https://#{ENV['DOMAIN']}/q/#{h[:method]}?#{h[:object]}=#{h[:object].upcase}x#{index}")
      ex = qr.to_s.gsub(' ', '_').gsub('x', '█')
      ex.split("\n").each do |e|
        svg.text e, x: 25, y: start, font_family: 'monospace', font_weight: 'bold', font_size: 44, fill: h[:fg] || '#000'
        start += 30
      end
      if h[:object] == 'i'
        svg. polygon points: "848,180 924,24 1000,180", fill: h[:bg] || '#fff'
      else
        if h[:lvl].to_i > 0
          if h[:object] == 'u'
            svg.rect x: 844, y: 20, width: 160, height: 160, fill: h[:bg] || '#fff'
          else
            svg.circle cx: 924, cy: 100, r: 80, fill: h[:bg] || '#fff'
          end
        end
        if h[:lvl].to_i > 1
          if h[:object] == 'u'
            svg.rect x: 864, y: 40, width: 120, height: 120, fill: h[:fg] || '#000'
          else
            svg.circle cx: 924, cy: 100, r: 60, fill: h[:fg] || '#000'
          end
        end
        if h[:lvl].to_i > 2
          if h[:object] == 'u'
            svg.rect x: 884, y: 60, width: 80, height: 80, fill: h[:bg] || '#fff'
          else
            svg.circle cx: 924, cy: 100, r: 40, fill: h[:bg] || '#fff'
          end
        end
        if h[:lvl].to_i > 3
          if h[:object] == 'u'
            svg.rect x: 904, y: 80, width: 40, height: 40, fill: h[:fg] || '#000'
          else
            svg.circle cx: 924, cy: 100, r: 20, fill: h[:fg] || '#000'
          end
        end
      end

      if h[:branded]
        svg.rect x: 0, y: 1370, width: 1024, height: 200, fill: h[:fg] || '#000'
        svg.text ENV['DOMAIN'], x: 5, y: 1500, font_family: 'monospace', font_weight: 'bold', font_size: 120, fill: h[:bg] || '#fff'
      end

      
      svg.save "public/#{index}"
    end
  end
end
