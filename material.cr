abstract class Material
  def scatter(ray : Ray, hit_record : HitRecord) : {Ray?, V3?}
    {nil,nil}
  end

  def reflect(v : V3, n : V3) : V3
    v - n * 2 * v.dot(n)
  end

  def refract(uv : V3, n : V3, etai_over_etat : Float64, cos_theta : Float64) : V3
    r_out_perp = (uv + n * cos_theta) * etai_over_etat
    r_out_parallel = n * -Math.sqrt((1.0 - r_out_perp.norm_squared).abs)
    r_out_perp + r_out_parallel
  end

  # Use Schlick's approximation for reflectance.
  def reflectance(cosine : Float64, refraction_index : Float64) : Float64
    r0 = (1 - refraction_index) / (1 + refraction_index)
    r0 *= r0
    r0 + (1 - r0) * (1 - cosine)**5
  end
end

class Lambertian < Material
  getter albedo : Texture

  def initialize(albedo : Texture)
    super()
    @albedo = albedo
  end

  def initialize(albedo : V3)
    super()
    @albedo = SolidColor.new(albedo)
  end

  def scatter(ray, hit_record)
    scatter_direction = hit_record.normal + V3.random_unit_vector
    if scatter_direction.near_zero
      scatter_direction = hit_record.normal
    end
    ray.origin = hit_record.p
    ray.direction = scatter_direction
    { ray, albedo.value(hit_record.u, hit_record.v, hit_record.p) }
  end
end

class Metal < Material
  getter albedo, fuzz

  def initialize(albedo : V3, fuzz : Float64)
    super()
    @albedo = albedo
    @fuzz = fuzz < 1.0 ? fuzz : 1.0
  end

  def scatter(ray, hit_record)
    reflected = reflect(ray.direction.normalize, hit_record.normal)
    ray.origin = hit_record.p
    ray.direction = reflected + V3.random_in_unit_sphere * fuzz
    if ray.direction.dot(hit_record.normal) > 0
      {ray, albedo}
    else
      {nil, nil}
    end
  end
end

class Dielectric < Material
  getter refraction_index

  def initialize(refraction_index : Float64)
    super()
    @refraction_index = refraction_index
  end

  WHITE = V3.new(1.0, 1.0, 1.0)

  def scatter(ray, hit_record)
    refraction_ratio = hit_record.front_face ? (1.0 / refraction_index) : refraction_index

    unit_direction = ray.direction.normalize
    cos_theta = (-unit_direction).dot(hit_record.normal)
    cos_theta = 1.0 if cos_theta > 1.0
    sin_theta = Math.sqrt(1.0 - cos_theta * cos_theta)

    if (refraction_ratio * sin_theta > 1.0) ||
       reflectance(cos_theta, refraction_ratio) > rand
      # cannot refract
      ray.direction = reflect(unit_direction, hit_record.normal)
    else
      ray.direction = refract(unit_direction, hit_record.normal, refraction_ratio, cos_theta)
    end
    ray.origin = hit_record.p
    {ray, WHITE}
  end
end
