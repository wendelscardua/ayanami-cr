class AABB
  getter minimum : V3, maximum : V3

  def initialize(a : V3, b : V3)
    @minimum = a
    @maximum = b
  end

  def hit(ray : Ray, t_min : Float64, t_max : Float64) : Bool
    inv_d = 1.0 / r.direction.x
    t0 = (minimum.x - r.origin.x) * inv_d
    t1 = (maximum.x - r.origin.x) * inv_d
    t0, t1 = { t1, t0 } if t0 > t1
    t_min = t0 if t0 > t_min
    t_max = t1 if t1 < t_max

    return false if t_max <= t_min

    inv_d = 1.0 / r.direction.y
    t0 = (minimum.y - r.origin.y) * inv_d
    t1 = (maximum.y - r.origin.y) * inv_d
    t0, t1 = { t1, t0 } if t0 > t1
    t_min = t0 if t0 > t_min
    t_max = t1 if t1 < t_max

    return false if t_max <= t_min

    inv_d = 1.0 / r.direction.z
    t0 = (minimum.z - r.origin.z) * inv_d
    t1 = (maximum.z - r.origin.z) * inv_d
    t0, t1 = { t1, t0 } if t0 > t1
    t_min = t0 if t0 > t_min
    t_max = t1 if t1 < t_max

    return false if t_max <= t_min

    true
  end
end
