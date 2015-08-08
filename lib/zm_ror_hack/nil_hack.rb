module ZmRorHack
  module NilClassHack
    def j2h(_type = nil)
      {}.with_indifferent_access
    end

  end
end

class NilClass
  include ZmRorHack::NilClassHack
end