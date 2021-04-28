Gem::Specification.new do |s|
  s.name        = 'nomadic'
  s.version     = '1.2.3'
  s.summary     = "a customizable, atomic, single-page app."
  s.description = "basic usage: nomadic --shell"
  s.authors     = ["Erik Olson"]
  s.email       = 'xorgnak@gmail.com'
  s.homepage    = 'https://vango.me'
  s.files       = ["lib/nomadic.rb", Dir['lib/nomadic/*'], Dir['exe/*']].flatten
end
