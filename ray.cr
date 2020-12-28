struct Ray
  property origin, direction, time

  def initialize(origin : V3, direction : V3, time : Float64)
    @origin = origin
    @direction = direction
    @time = time
  end

  def at(t) : V3
    origin + direction * t
  end
end
