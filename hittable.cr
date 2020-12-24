class HitRecord
  property p : V3, normal : V3, t : Float64, front_face : Bool, material : Material

  def initialize(p : V3, t : Float64, normal : V3, ray : Ray, material : Material)
    @p = p
    @t = t
    @front_face = ray.direction.dot(normal) < 0
    @normal = @front_face ? normal : -normal
    @material = material
  end
end

abstract class Hittable
  def hit(ray : Ray, t_min : Float, t_max : Float) : HitRecord?
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
    half_b = oc.dot(ray.direction).to_f
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
    
    HitRecord.new t: root,
                  p: p,
                  material: material,
                  normal: (p - center) * (1.0 / radius),
                  ray: ray
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
end


