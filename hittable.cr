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

  def set_face_normal(ray : Ray, normal : V3)
    @front_face = ray.direction.dot(normal) < 0
    @normal = @front_face ? normal : -normal
  end
end

abstract class Hittable
  def hit(ray : Ray, t_min : Float, t_max : Float) : HitRecord?
  end

  def bounding_box : AABB?
  end

  def self.from_yaml(yaml : YAML::Any,
                     materials : Hash(String, Material),
                     primitives : Hash(String, Hittable))
    object_type = yaml["type"].as_s
    case object_type
    when "sphere"
      center = V3.from_yaml(yaml["center"])
      radius = yaml["radius"].as_f
      material = yaml["material"].as_s
      Sphere.new(center, radius, materials[material])
    when "xyrect"
      XYRect.new(yaml["x0"].as_f,
                 yaml["x1"].as_f,
                 yaml["y0"].as_f,
                 yaml["y1"].as_f,
                 yaml["k"].as_f,
                 materials[yaml["material"].as_s])
    when "xzrect"
      XZRect.new(yaml["x0"].as_f,
                 yaml["x1"].as_f,
                 yaml["z0"].as_f,
                 yaml["z1"].as_f,
                 yaml["k"].as_f,
                 materials[yaml["material"].as_s])
    when "yzrect"
      YZRect.new(yaml["y0"].as_f,
                 yaml["y1"].as_f,
                 yaml["z0"].as_f,
                 yaml["z1"].as_f,
                 yaml["k"].as_f,
                 materials[yaml["material"].as_s])
    when "box"
      HittableBox.new(V3.from_yaml(yaml["minimum"]),
                      V3.from_yaml(yaml["maximum"]),
                      materials[yaml["material"].as_s])
    when "translate"
      primitive = if yaml["instance"]?
                    primitives[yaml["instance"].as_s]
                  elsif yaml["inline"]?
                    Hittable.from_yaml(yaml["inline"], materials, primitives)
                  else
                    raise "translate requires instance or inline"
                  end
      Translate.new(primitive,
                    V3.from_yaml(yaml["offset"]))
    when "rotate_y"
      primitive = if yaml["instance"]?
                    primitives[yaml["instance"].as_s]
                  elsif yaml["inline"]?
                    Hittable.from_yaml(yaml["inline"], materials, primitives)
                  else
                    raise "translate requires instance or inline"
                  end
      RotateY.new(primitive,
                  yaml["theta"].as_f)
    when "constant_medium"
      primitive = if yaml["instance"]?
                    primitives[yaml["instance"].as_s]
                  elsif yaml["inline"]?
                    Hittable.from_yaml(yaml["inline"], materials, primitives)
                  else
                    raise "translate requires instance or inline"
                  end
      ConstantMedium.new(primitive,
                         yaml["density"].as_f,
                         materials[yaml["material"].as_s])
    else
      raise "Invalid object type #{object_type}"
    end
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

class MovingSphere < Hittable
  getter start_center, end_center, radius, material,
         start_time, end_time
  
  def initialize(start_center : V3,
                 end_center : V3,
                 start_time : Float64,
                 end_time : Float64,
                 radius : Float64,
                 material : Material)
    super()
    @start_center = start_center
    @start_time = start_time
    @end_center = end_center
    @end_time = end_time
    @radius = radius
    @material = material
  end

  def center(time : Float64) : V3
    start_center + (end_center - start_center) * ((time - start_time) / (end_time - start_time))
  end
  
  def hit(ray, t_min, t_max) : HitRecord?
    oc = ray.origin - center(ray.time)
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

    outward_normal = (p - center(ray.time)) * (1.0 / radius)

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
      AABB.surrounding_box(AABB.new(center(start_time) - r_vector,
                                    center(start_time) + r_vector),
                           AABB.new(center(end_time) - r_vector,
                                    center(end_time) + r_vector))
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

class HittableBox < Hittable
  getter minimum : V3, maximum : V3, material : Material,
         sides : HittableList

  def initialize(minimum : V3, maximum : V3, material : Material)
    @minimum = minimum
    @maximum = maximum
    @material = material
    @sides = HittableList.new

    @sides << XYRect.new(@minimum.x, @maximum.x, @minimum.y, @maximum.y, @maximum.z, @material)
    @sides << XYRect.new(@minimum.x, @maximum.x, @minimum.y, @maximum.y, @minimum.z, @material)

    @sides << XZRect.new(@minimum.x, @maximum.x, @minimum.z, @maximum.z, @maximum.y, @material)
    @sides << XZRect.new(@minimum.x, @maximum.x, @minimum.z, @maximum.z, @minimum.y, @material)

    @sides << YZRect.new(@minimum.y, @maximum.y, @minimum.z, @maximum.z, @maximum.x, @material)
    @sides << YZRect.new(@minimum.y, @maximum.y, @minimum.z, @maximum.z, @minimum.x, @material)
  end

  def hit(ray, t_min, t_max) : HitRecord?
    sides.hit(ray, t_min, t_max)
  end

  def bounding_box
    AABB.new(minimum, maximum)
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

class Translate < Hittable
  getter instance : Hittable, offset : V3

  def initialize(instance : Hittable, offset : V3)
    @instance = instance
    @offset = offset
  end

  def hit(ray, t_min, t_max) : HitRecord?
    moved_ray = Ray.new(ray.origin - offset, ray.direction, ray.time)
    hit_record = instance.hit(moved_ray, t_min, t_max)
    return if hit_record.nil?
    hit_record.p += offset
    hit_record
  end

  def bounding_box
    original_box = instance.bounding_box
    return if original_box.nil?

    AABB.new(original_box.minimum + offset, original_box.maximum + offset)
  end
end

class RotateY < Hittable
  getter instance : Hittable, cos_theta : Float64, sin_theta : Float64,
         box : AABB?

  def initialize(instance : Hittable, theta : Float64)
    theta = theta * Math::PI / 180.0
    @instance = instance
    @cos_theta = Math.cos(theta)
    @sin_theta = Math.sin(theta)
    if bbox = @instance.bounding_box
      min_x = min_y = min_z = Float64::INFINITY
      max_x = max_y = max_z = -Float64::INFINITY
      (0..1).each do |i|
        (0..1).each do |j|
          (0..1).each do |k|
            x = i * bbox.maximum.x + (1 - i) * bbox.minimum.x
            y = j * bbox.maximum.y + (1 - j) * bbox.minimum.y
            z = k * bbox.maximum.z + (1 - k) * bbox.minimum.z

            newx =  cos_theta * x + sin_theta * z;
            newz = -sin_theta * x + cos_theta * z;

            min_x = Math.min(min_x, newx)
            min_y = Math.min(min_y, y)
            min_z = Math.min(min_z, newz)

            max_x = Math.max(max_x, newx)
            max_y = Math.max(max_y, y)
            max_z = Math.max(max_z, newz)
          end
        end
      end
      @box = AABB.new(V3.new(min_x, min_y, min_z),
                      V3.new(max_x, max_y, max_z))
    else
      @box = nil
    end
  end

  def hit(ray, t_min, t_max) : HitRecord?
    rotated_ray = Ray.new(V3.new(cos_theta * ray.origin.x - sin_theta * ray.origin.z,
                                 ray.origin.y,
                                 sin_theta * ray.origin.x + cos_theta * ray.origin.z),
                          V3.new(cos_theta * ray.direction.x - sin_theta * ray.direction.z,
                                 ray.direction.y,
                                 sin_theta * ray.direction.x + cos_theta * ray.direction.z),
                          ray.time)

    hit_record = instance.hit(rotated_ray, t_min, t_max)
    return if hit_record.nil?

    hit_record.p = V3.new(cos_theta * hit_record.p.x + sin_theta * hit_record.p.z,
                          hit_record.p.y,
                          -sin_theta * hit_record.p.x + cos_theta * hit_record.p.z)


    hit_record.set_face_normal(rotated_ray,
                               V3.new(cos_theta * hit_record.normal.x + sin_theta * hit_record.normal.z,
                                      hit_record.normal.y,
                                      -sin_theta * hit_record.normal.x + cos_theta * hit_record.normal.z))
    hit_record
  end

  def bounding_box
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

class ConstantMedium < Hittable
  getter boundary : Hittable,
         negative_inverse_density : Float64,
         phase_function : Material

  def initialize(boundary,
                 density,
                 phase_function)
    @boundary = boundary
    @negative_inverse_density = -1.0 / density
    @phase_function = phase_function
  end

  def hit(ray, t_min, t_max) : HitRecord?
    rec1 = boundary.hit(ray, -Float64::INFINITY, Float64::INFINITY)
    return if rec1.nil?

    rec2 = boundary.hit(ray, rec1.t + 0.0001, Float64::INFINITY)
    return if rec2.nil?

    rec1.t = t_min if rec1.t < t_min
    rec2.t = t_max if rec2.t > t_max

    return if rec1.t >= rec2.t

    rec1.t = 0 if rec1.t < 0

    ray_length = ray.direction.magnitude
    distance_inside_boundary = (rec2.t - rec1.t) * ray_length
    hit_distance = negative_inverse_density * Math.log(rand);

    return if hit_distance > distance_inside_boundary

    rec1.t = rec1.t + hit_distance / ray_length
    rec1.p = ray.at(rec1.t)

    rec1.normal = V3.new(1.0, 0.0, 0.0) # arbitrary
    rec1.front_face = true # arbitrary
    rec1.material = phase_function
    return rec1
  end

  def bounding_box
    boundary.bounding_box
  end
end
