abstract struct Background
  def value(ray)
    V3.new(0.0, 0.0, 0.0)
  end

  def self.from_yaml(yaml : YAML::Any)
    bg_type = yaml["type"].as_s
    case bg_type
    when "color"
      Background::Color.new(V3.from_yaml(yaml["color"]))
    when "cubemap"
      Background::CubeMap.new(yaml["folder"].as_s)
    when "sky"
      Background::Sky.new
    else
      raise "Invalid background type #{bg_type}"
    end
  end
end

struct Background::Color < Background
  def initialize(@color : V3)
  end

  def value(ray)
    @color
  end
end

struct Background::CubeMap < Background
  @right : StumpyPNG::Canvas
  @left  : StumpyPNG::Canvas
  @up    : StumpyPNG::Canvas
  @down  : StumpyPNG::Canvas
  @front : StumpyPNG::Canvas
  @back  : StumpyPNG::Canvas

  def initialize(folder)
    @right = StumpyPNG.read("#{folder}/posx.png")
    @left  = StumpyPNG.read("#{folder}/negx.png")
    @up    = StumpyPNG.read("#{folder}/posy.png")
    @down  = StumpyPNG.read("#{folder}/negy.png")
    @front = StumpyPNG.read("#{folder}/posz.png")
    @back  = StumpyPNG.read("#{folder}/negz.png")    
  end

  def value(ray)
    dir = ray.direction

    if dir.x.abs >= dir.y.abs && dir.x.abs >= dir.z.abs
      if dir.x >= 0.0
        u = 1.0 - (dir.z / dir.x + 1.0) / 2
        v = 1.0 - (dir.y / dir.x + 1.0) / 2
        read_texture(@right, u, v)
      else
        u = (dir.z / dir.x + 1.0) / 2
        v = (dir.y / dir.x + 1.0) / 2
        read_texture(@left, u, v)
      end
    elsif dir.y.abs >= dir.x.abs && dir.y.abs >= dir.z.abs
      if dir.y >= 0.0
        u = (dir.x / dir.y + 1.0) / 2
        v = (dir.z / dir.y + 1.0) / 2
        read_texture(@up, u, v)
      else
        u = 1.0 - (dir.x / dir.y + 1.0) / 2
        v = 1.0 - (dir.z / dir.y + 1.0) / 2
        read_texture(@down, u, v)
      end
    else
      if dir.z >= 0.0
        u = (dir.x / dir.z + 1.0) / 2
        v = 1.0 - (dir.y / dir.z + 1.0) / 2
        read_texture(@front, u, v)
      else
        u = (dir.x / dir.z + 1.0) / 2
        v = (dir.y / dir.z + 1.0) / 2
        read_texture(@back, u, v)
      end
    end
  end

  COLOR_SCALE = 1.0 / 255.0

  private def read_texture(texture, u, v)
    i = (u * texture.width).to_i
    j = (v * texture.height).to_i
    r, g, b = texture[i, j].to_rgb8
    V3.new(COLOR_SCALE * r, COLOR_SCALE * g, COLOR_SCALE * b)
  end
end

struct Background::Sky < Background
  BLUE = V3.new(0.5, 0.7, 1.0)
  WHITE = V3.new(1.0, 1.0, 1.0)

  def value(ray)
    t = 0.5 * (ray.direction.normalize.y + 1.0)
    BLUE * t + WHITE * (1.0 - t)
  end
end
