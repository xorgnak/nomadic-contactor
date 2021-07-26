module NOMADIC
  class Badge
    COLORS = {
      0 => 'white',
      1 => 'red',
      2 => 'orange',
      3 => 'yellow',
      4 => 'green',
      5 => 'blue',
      6 => 'indego',
      7 => 'violet',
      8 => 'silver',
      9 => 'gold'
    }
    TEAMS = {
      'circle' => 'circle',
      'bird' => 'flutter_dash',
      'wolf' => 'pets',
      'bug' => 'bug_report',
      'butterfly' => 'emoji_nature',
      'tree' => 'park',
      'flower' => 'spa'
    }
    BADGES = {
      nightlife: 'nightlife',
      food: 'fastfood',
      art: 'color_lens',
      music: 'music_note',
      directions: 'explore',
      party: 'celebration',
      camera: 'photo_camera',
    }
    def initialize u
      @u = User.new(u)
    end
    def [] k
      COLORS[@u.stat[k].to_i]
    end
    def badges
      r = []
      BADGES.each_pair do |b, i|
        r << %[<span class='badge'><input class='tickbox' type='checkbox' id='c-#{b}' name='badge-#{b}'><span id='#{b}' class='material-icons ic'>#{i}</span><span class='bdg'>#{b}</span></span>]
      end
      return r.join('')
    end
    def badges_js
      r = []
      BADGES.each_pair do |b, i|
        r << %[var #{b}s = 0; ]
        r << %[$(document).on('click', '##{b}' , function() { $("#c-#{b}").checked = 'true'; });\n]
      end
      return r.join('')
    end
    def team
      TEAMS[@u.attr[:team]]
    end
    def logo
      @u.attr[:logo]
    end
  end
end
