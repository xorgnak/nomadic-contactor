module NOMADIC
  class Venmo
    def initialize h={}
      @h = h
    end
    def to_link
      return "<a class='material-icons nav i' id='pig' href='#{to_s}'>savings</a>"
    end
    def to_s
      r = ["venmo://paycharge?"]
      a = []
      if @h.has_key? :invoice
        a << "txn=charge"
      else
        a << "txn=pay"
      end
      a << "recipients=#{@h[:to]}"
      a << "amount=#{@h[:amt]}"
      a << "note=#{@h[:note]}"
      r << a.join('&')
      return r.join('')
    end
  end
end
