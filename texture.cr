abstract class Texture
  def value(u : Float64, v : Float64, p : V3) : V3
    raise "Not Implemented"
  end
end

class SolidColor < Texture
  getter color : V3

  def initialize(color : V3)
    @color = color
  end

  def initialize(r : Float64, g : Float64, b : Float64)
    @color = V3.new(r, g, b)
  end

  def value(u : Float64, v : Float64, p : V3)
    color
  end
end
