class AABB
  getter minimum : V3, maximum : V3

  def initialize(a : V3, b : V3)
    @minimum = a
    @maximum = b
  end

  def hit(ray : Ray, t_min : Float64, t_max : Float64) : Bool
    inv_d = 1.0 / ray.direction.x
    t0 = (minimum.x - ray.origin.x) * inv_d
    t1 = (maximum.x - ray.origin.x) * inv_d
    t0, t1 = { t1, t0 } if inv_d < 0
    t_min = t0 if t0 > t_min
    t_max = t1 if t1 < t_max

    return false if t_max <= t_min

    inv_d = 1.0 / ray.direction.y
    t0 = (minimum.y - ray.origin.y) * inv_d
    t1 = (maximum.y - ray.origin.y) * inv_d
    t0, t1 = { t1, t0 } if t0 > t1
    t_min = t0 if t0 > t_min
    t_max = t1 if t1 < t_max

    return false if t_max <= t_min

    inv_d = 1.0 / ray.direction.z
    t0 = (minimum.z - ray.origin.z) * inv_d
    t1 = (maximum.z - ray.origin.z) * inv_d
    t0, t1 = { t1, t0 } if t0 > t1
    t_min = t0 if t0 > t_min
    t_max = t1 if t1 < t_max

    return false if t_max <= t_min

    true
  end

  def self.surrounding_box(box0 : AABB, box1 : AABB): AABB
    AABB.new(V3.new([box0.minimum.x, box1.minimum.x].min,
                    [box0.minimum.y, box1.minimum.y].min,
                    [box0.minimum.z, box1.minimum.z].min),
             V3.new([box0.maximum.x, box1.maximum.x].max,
                    [box0.maximum.y, box1.maximum.y].max,
                    [box0.maximum.z, box1.maximum.z].max))
  end
end
