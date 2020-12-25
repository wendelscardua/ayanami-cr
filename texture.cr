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

class Checker < Texture
  getter odd : Texture, even : Texture

  def initialize(odd, even)
    @odd = odd
    @even = even
  end

  def value(u : Float64, v : Float64, p : V3)
    sines = Math.sin(10 * p.x) * Math.sin(10 * p.y) * Math.sin(10 * p.z);
    if sines < 0
      odd.value(u, v, p)
    else
      even.value(u, v, p)
    end
  end
end

class Noise < Texture
  WHITE = V3.new(1.0, 1.0, 1.0)

  getter perlin, scale

  def initialize(scale : Float64)
    @scale = scale
    @perlin = Perlin.new
  end

  def value(u : Float64, v : Float64, p : V3)
    WHITE * 0.5 * (1.0 + Math.sin(scale * p.z + 10 * perlin.turbulence(p)))
  end
end
