require "stumpy_png"
require "crystaledge"
require "yaml"
require "./v3-helpers"
require "./camera"
require "./ray"
require "./hittable"
require "./material"

alias V3 = CrystalEdge::Vector3

class Ayanami
  property width, height, samples_per_pixel, max_depth, world, camera

  def initialize(width : Int32, height : Int32, samples_per_pixel : Int32, max_depth : Int32, world : Hittable, camera : Camera)
    @width = width
    @height = height
    @samples_per_pixel = samples_per_pixel
    @max_depth = max_depth
    @world = world
    @camera = camera
  end

  def run(output : String)
    canvas = StumpyPNG::Canvas.new(@width, @height)

    (height - 1).downto(0) do |j|
      puts j if j % 50 == 0
      0.upto(width - 1) do |i|
        color = samples_per_pixel.times.map do
          u = (i + rand) / (width - 1)
          v = (j + rand) / (height - 1)
          ray = camera.ray(u, v)
          ray_color(ray, world, max_depth)
        end.sum / samples_per_pixel.to_f

        canvas[i, height - j - 1] = StumpyPNG::RGBA.from_rgb_n((Math.sqrt(color.x) * 255.99999).to_i,
                                                               (Math.sqrt(color.y) * 255.99999).to_i,
                                                               (Math.sqrt(color.z) * 255.99999).to_i,
                                                               8)
      end
    end
    StumpyPNG.write(canvas, output)
  end

  BLACK = V3.zero
  WHITE = V3.new(1.0, 1.0, 1.0)
  BLUE = V3.new(0.5, 0.7, 1.0)

  def ray_color(r : Ray, world : Hittable, depth : Int) : V3
    return BLACK if depth <= 0
    
    hit_record = world.hit(r, 0.001, Float64::INFINITY)
    if hit_record
      scattered_ray, attenuation = hit_record.material.scatter(r, hit_record)
      if scattered_ray && attenuation
        return ray_color(scattered_ray, world, depth - 1) * attenuation
      end
      return V3.zero
    end
    unit_direction = r.direction.normalize
    t = 0.5 * (unit_direction.y + 1.0)
    WHITE * (1.0 - t) + BLUE * t
  end
end

config = YAML.parse(File.read(ARGV[0]))

width = config["options"]["width"].as_i
height = config["options"]["height"].as_i

camera = Camera.new(vertical_fov: config["camera"]["vertical_fov"].as_f,
                    aspect_ratio: width.to_f / height)

materials = Hash(String, Material).new

config["materials"].as_h.each do |name, args|
  material_type = args["type"].as_s
  materials[name.as_s] = case material_type
                         when "lambertian"
                           albedo = V3.new(args["albedo"][0].as_f,
                                           args["albedo"][1].as_f,
                                           args["albedo"][2].as_f)
                           Lambertian.new(albedo)
                         when "dielectric"
                           refraction_index = args["refraction_index"].as_f
                           Dielectric.new(refraction_index)
                         when "metal"
                           albedo = V3.new(args["albedo"][0].as_f,
                                           args["albedo"][1].as_f,
                                           args["albedo"][2].as_f)
                           fuzz = args["fuzz"].as_f
                           Metal.new(albedo, fuzz)
                         else
                           raise "Invalid material type #{material_type}"
                         end
end

world = HittableList.new

config["world"].as_a.each do |object|
  object_type = object["type"].as_s
  object = case object_type
           when "sphere"
             center = V3.new(object["center"][0].as_f,
                             object["center"][1].as_f,
                             object["center"][2].as_f)
             radius = object["radius"].as_f
             material = object["material"].as_s
             Sphere.new(center, radius, materials[material])
           else
             raise "Invalid object type #{object_type}"
           end
  world << object
end

ayanami = Ayanami.new width: width, height: height,
                      samples_per_pixel: config["options"]["samples_per_pixel"].as_i,
                      max_depth: config["options"]["max_depth"].as_i,
                      world: world,
                      camera: camera

ayanami.run(output: ARGV[1])
