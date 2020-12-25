abstract class Texture
  def value(u : Float64, v : Float64, p : V3) : V3
    raise "Not Implemented"
  end

  def self.from_yaml(yaml : YAML::Any, textures : Hash(String, Texture))
    texture_type = yaml["type"].as_s
    case texture_type
    when "solid_color"
      color = V3.from_yaml(yaml["color"])
      SolidColor.new(color)
    when "checker"
      odd = yaml["odd"].as_s
      even = yaml["even"].as_s
      Checker.new(textures[odd], textures[even])
    when "noise"
      scale = yaml["scale"].as_f
      Noise.new(scale)
    when "image"
      filename = yaml["filename"].as_s
      ImageTexture.new(filename)
    else
      raise "Invalid texture type #{texture_type}"
    end
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

class ImageTexture < Texture
  getter canvas : StumpyCore::Canvas,
         width : Int32, height : Int32

  def initialize(filename : String)
    @canvas = StumpyPNG.read(filename)
    @width = @canvas.width
    @height = @canvas.height
  end

  COLOR_SCALE = 1.0 / 255.0

  def value(u : Float64, v : Float64, p : V3)
    # Clamp input texture coordinates to [0,1] x [1,0]
    u = u.clamp(0.0, 1.0)
    v = 1.0 - v.clamp(0.0, 1.0);  # Flip V to image coordinates

    i = (u * width).to_i
    j = (v * height).to_i

    # Clamp integer mapping, since actual coordinates should be less than 1.0
    i = width - 1 if i >= width
    i = 0 if i < 0
    j = height - 1 if j >= height
    j = 0 if j < 0

    r, g, b = canvas[i, j].to_rgb8

    V3.new(COLOR_SCALE * r, COLOR_SCALE * g, COLOR_SCALE * b)
  end
end
