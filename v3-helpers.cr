struct CrystalEdge::Vector3
  def norm_squared
    dot(self)
  end

  def near_zero
    x.abs < 1e-8 &&
      y.abs < 1e-8 &&
      z.abs < 1e-8
  end

  def self.random_vector(min = 0.0, max = 1.0)
    x = rand(min...max)
    y = rand(min...max)
    z = rand(min...max)
    V3.new(x, y, z)
  end

  def self.random_in_unit_sphere
    loop do
      p = self.random_vector(-1.0, 1.0)
      return p if p.norm_squared <= 1.0
    end
  end

  def self.random_in_unit_disk
    loop do
      p = V3.new(rand(-1.0...1.0), rand(-1.0...1.0), 0.0)
      return p if p.norm_squared <= 1.0
    end
  end

  def self.random_unit_vector
    self.random_in_unit_sphere.normalize!
  end

  def self.from_yaml(yaml : YAML::Any)
    V3.new(yaml[0].as_f, yaml[1].as_f, yaml[2].as_f)
  end
end
