module NOMADIC
  class Fields
    def initialize
      puts "Fields: #{Dir['./*']}"
      @f = JSON.parse File.read('form.json')
    end
    def to_json
      JSON.generate(@f)
    end
    def map &b
      @f.each_pair do |k,v|
        e = { name: k, type: v[0], text: v[1] }
        b.call(e)
      end
    end
  end
end
