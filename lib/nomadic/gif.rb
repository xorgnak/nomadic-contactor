module NOMADIC
  module Gif
    def self.images u, k
     Redis.new.publish "GIF", `convert -delay 100 -loop 0 public/#{u}/#{k}*.jpeg public/#{u}-#{k}.gif`
    end
    def self.video u, f, k
      `ffmpeg -i public/#{u}/#{f} public/#{u}#{k}.gif`
    end
  end
end
