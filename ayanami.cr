require "stumpy_png"
require "crystaledge"
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
        end.sum(V3.new(0.0, 0.0, 0.0)) / samples_per_pixel.to_f

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

width = 640
height = 480

camera = Camera.new(vertical_fov: 90.0, aspect_ratio: width.to_f / height)

mat_ground = Lambertian.new(V3.new(0.8, 0.8, 0.0))
mat_solid = Lambertian.new(V3.new(0.1, 0.2, 0.5))
mat_glass = Dielectric.new(1.7)
mat_metal = Metal.new(V3.new(0.8, 0.5, 0.1), 0.0)

world = HittableList.new
world << Sphere.new(V3.new(0.0, -100.5, -1.0), 100.0, mat_ground)
world << Sphere.new(V3.new(0.0, 0.0, -1.5), 0.5, mat_solid)
world << Sphere.new(V3.new(-1.0, 0.0, -1.0), 0.5, mat_glass)
world << Sphere.new(V3.new(1.0, 0.0, -1.0), 0.5, mat_metal)

ayanami = Ayanami.new width: width, height: height,
                      samples_per_pixel: 64,
                      max_depth: 32,
                      world: world,
                      camera: camera

ayanami.run(output: "ayanami.png")
