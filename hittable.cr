class HitRecord
  property p : V3, normal : V3, t : Float64, front_face : Bool, material : Material,
           u : Float64, v : Float64

  def initialize(p : V3, t : Float64, normal : V3, ray : Ray, material : Material,
                 u : Float64, v : Float64)
    @p = p
    @t = t
    @front_face = ray.direction.dot(normal) < 0
    @normal = @front_face ? normal : -normal
    @material = material
    @u = u
    @v = v
  end
end

abstract class Hittable
  def hit(ray : Ray, t_min : Float, t_max : Float) : HitRecord?
  end

  def bounding_box : AABB?
  end
end

class Sphere < Hittable
  getter center, radius, material
  
  def initialize(center : V3, radius : Float64, material : Material)
    super()
    @center = center
    @radius = radius
    @material = material
  end
  
  def hit(ray, t_min, t_max) : HitRecord?
    oc = ray.origin - center
    a = ray.direction.norm_squared
    half_b = oc.dot(ray.direction)
    c = oc.norm_squared - radius * radius

    discriminant = half_b * half_b - a * c
    return nil if discriminant < 0

    sqrtd = Math.sqrt(discriminant)

    # Find the nearest root that lies in the acceptable range.
    root = (-half_b - sqrtd) / a
    if root < t_min || t_max < root
      root = (-half_b + sqrtd) / a
      return nil if root < t_min || t_max < root
    end

    p = ray.at(root)

    outward_normal = (p - center) * (1.0 / radius)

    u, v = get_sphere_uv(outward_normal)
    
    HitRecord.new t: root,
                  p: p,
                  material: material,
                  normal: outward_normal,
                  ray: ray,
                  u: u,
                  v: v
  end

  def bounding_box
    r_vector = V3.new(radius, radius, radius)
    AABB.new(
      center - r_vector,
      center + r_vector
    )
  end

  private def get_sphere_uv(p : V3)
    theta = Math.acos(-p.y)
    phi = Math.atan2(-p.z, p.x) + Math::PI

    { phi / (2 * Math::PI), theta / Math::PI }
  end
end

class XYRect < Hittable
  getter x0 : Float64, x1 : Float64, y0 : Float64, y1 : Float64, k : Float64,
         material : Material

  def initialize(x0, x1, y0, y1, k, material)
    @x0 = x0
    @x1 = x1
    @y0 = y0
    @y1 = y1
    @k = k
    @material = material
  end

  OUTWARD_NORMAL = V3.new(0.0, 0.0, 1.0)

  def hit(ray, t_min, t_max) : HitRecord?
    t = (k - ray.origin.z) / ray.direction.z
    return nil if (t < t_min || t > t_max)

    x = ray.origin.x + t * ray.direction.x
    y = ray.origin.y + t * ray.direction.y

    return nil if (x < x0 || x > x1 || y < y0 || y > y1)

    HitRecord.new t: t,
                  p: ray.at(t),
                  material: material,
                  normal: OUTWARD_NORMAL,
                  ray: ray,
                  u: (x - x0) / (x1 - x0),
                  v: (y - y0) / (y1 - y0)
  end

  def bounding_box
    AABB.new(V3.new(x0, y0, k - 0.0001), V3.new(x1, y1, k + 0.0001))
  end
end

class XZRect < Hittable
  getter x0 : Float64, x1 : Float64, z0 : Float64, z1 : Float64, k : Float64,
         material : Material

  def initialize(x0, x1, z0, z1, k, material)
    @x0 = x0
    @x1 = x1
    @z0 = z0
    @z1 = z1
    @k = k
    @material = material
  end

  OUTWARD_NORMAL = V3.new(0.0, 1.0, 0.0)

  def hit(ray, t_min, t_max) : HitRecord?
    t = (k - ray.origin.y) / ray.direction.y
    return nil if (t < t_min || t > t_max)

    x = ray.origin.x + t * ray.direction.x
    z = ray.origin.z + t * ray.direction.z

    return nil if (x < x0 || x > x1 || z < z0 || z > z1)

    HitRecord.new t: t,
                  p: ray.at(t),
                  material: material,
                  normal: OUTWARD_NORMAL,
                  ray: ray,
                  u: (x - x0) / (x1 - x0),
                  v: (z - z0) / (z1 - z0)
  end

  def bounding_box
    AABB.new(V3.new(x0, k - 0.0001, z0), V3.new(x1, k + 0.0001, z1))
  end
end


class YZRect < Hittable
  getter y0 : Float64, y1 : Float64, z0 : Float64, z1 : Float64, k : Float64,
         material : Material

  def initialize(y0, y1, z0, z1, k, material)
    @y0 = y0
    @y1 = y1
    @z0 = z0
    @z1 = z1
    @k = k
    @material = material
  end

  OUTWARD_NORMAL = V3.new(1.0, 0.0, 0.0)

  def hit(ray, t_min, t_max) : HitRecord?
    t = (k - ray.origin.x) / ray.direction.x
    return nil if (t < t_min || t > t_max)

    y = ray.origin.y + t * ray.direction.y
    z = ray.origin.z + t * ray.direction.z

    return nil if (y < y0 || y > y1 || z < z0 || z > z1)

    HitRecord.new t: t,
                  p: ray.at(t),
                  material: material,
                  normal: OUTWARD_NORMAL,
                  ray: ray,
                  u: (y - y0) / (y1 - y0),
                  v: (z - z0) / (z1 - z0)
  end

  def bounding_box
    AABB.new(V3.new(k - 0.0001, y0, z0), V3.new(k + 0.0001, y1, z1))
  end
end

class HittableList < Hittable
  getter objects
  
  def initialize()
    super()
    @objects = [] of Hittable
  end

  def <<(object) : HittableList
    objects << object
    self
  end

  def hit(ray, t_min, t_max) : HitRecord?
    hit_record = nil
    closest_so_far = t_max
    objects.each do |object|
      if (current_hit_record = object.hit(ray, t_min, closest_so_far))
        hit_record = current_hit_record
        closest_so_far = hit_record.t
      end
    end
    hit_record
  end

  def bounding_box : AABB?
    return nil if objects.empty?

    box = nil
    objects.each do |object|
      object_box = object.bounding_box
      return nil if object_box.nil?

      if box.nil?
        box = object_box
      else
        box = AABB.surrounding_box(box, object_box)
      end
    end

    box
  end
end

class BVHNode < Hittable
  getter left : Hittable, right : Hittable, box : AABB

  def initialize(hittable_list : HittableList)
    initialize(hittable_list.objects)
  end

  def initialize(objects : Array(Hittable))
    axis = rand(0..2)

    if (objects.size  == 1)
      @left = @right = objects[0]
    elsif (objects.size == 2)
      if (comparator(objects[0], objects[1], axis) <= 0)
        @left = objects[0]
        @right = objects[1]
      else
        @left = objects[1]
        @right = objects[0]
      end
    else
      sorted = objects.sort { |a, b| comparator(a, b, axis) }
      mid = (objects.size / 2).to_i
      @left = BVHNode.new(sorted[0...mid])
      @right = BVHNode.new(sorted[mid...sorted.size])
    end

    box_left = @left.bounding_box
    box_right = @right.bounding_box

    if box_left.nil? || box_right.nil?
      raise "No bounding box"
    else
      @box = AABB.surrounding_box(box_left, box_right)
    end
  end

  def hit(ray, t_min, t_max) : HitRecord?
    return nil unless box.hit(ray, t_min, t_max)

    left_hit = left.hit(ray, t_min, t_max)
    right_hit = right.hit(ray, t_min, left_hit ? left_hit.t : t_max)

    right_hit || left_hit
  end
  
  def bounding_box : AABB?
    box
  end

  def comparator(a : Hittable, b : Hittable, axis : Int32) : Int32
    box_a = a.bounding_box
    box_b = b.bounding_box
    if box_a.nil? || box_b.nil?
      raise "Invalid objects"
    elsif axis == 0
      box_a.minimum.x <=> box_b.minimum.x || 0
    elsif axis == 1
      box_a.minimum.y <=> box_b.minimum.y || 0
    else
      box_a.minimum.z <=> box_b.minimum.z || 0
    end
  end
end
