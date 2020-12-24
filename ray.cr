class Ray
  property origin, direction

  def initialize(origin : V3, direction : V3)
    @origin = origin
    @direction = direction
  end

  def at(t) : V3
    origin + direction * t
  end
end
