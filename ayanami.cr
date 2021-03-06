require "crystaledge"
require "stumpy_png"
require "yaml"
require "./aabb"
require "./background"
require "./camera"
require "./hittable"
require "./material"
require "./obj"
require "./perlin"
require "./ray"
require "./texture"
require "./v3-helpers"

alias V3 = CrystalEdge::Vector3
alias V4 = CrystalEdge::Vector4

class PixelOutput
  property i, color

  def initialize(@i : Int32, @color : StumpyPNG::RGBA)
  end
end

class Ayanami
  property width, height, samples_per_pixel, max_depth, world, camera, background

  def initialize(@width : Int32, @height : Int32,
                 @samples_per_pixel : Int32, @max_depth : Int32,
                 @world : Hittable, @camera : Camera,
                 @background : Background)
  end

  def run(output : String, index : Int32? = nil, preview = false)
    canvas = StumpyPNG::Canvas.new(@width, @height)

    (height - 1).downto(0) do |j|
      channel = Channel(PixelOutput).new(@width)
      if j % 50 == 0
        if index.nil?
          puts j
        else
          puts "#{index}: #{j}"
        end
        StumpyPNG.write(canvas, output) if preview && j > 0
      end
      0.upto(width - 1) do |i|
        spawn do
          color = samples_per_pixel.times.map do
            u = (i + rand) / (width - 1)
            v = (j + rand) / (height - 1)
            ray = camera.ray(u, v)
            ray_color(ray, world, max_depth)
          end.sum / samples_per_pixel.to_f

          channel.send(PixelOutput.new(i, StumpyPNG::RGBA.from_rgb_n(clamp_color(color.x),
                                                                     clamp_color(color.y),
                                                                     clamp_color(color.z),
                                                                     8)))
        end
      end
      @width.times {
        pixel_output = channel.receive
        i = pixel_output.i
        canvas[i, @height - j - 1] = pixel_output.color
      }
    end
    StumpyPNG.write(canvas, output)
  end

  def clamp_color(value)
    (Math.sqrt(value.clamp(0.0, 1.0)) * 255.99999).to_i
  end

  BLACK = V3.zero
  WHITE = V3.new(1.0, 1.0, 1.0)
  BLUE  = V3.new(0.5, 0.7, 1.0)

  def ray_color(r : Ray, world : Hittable, depth : Int) : V3
    return BLACK if depth <= 0

    hit_record = world.hit(r, 0.001, Float64::INFINITY)
    if hit_record
      emitted = hit_record.material.emitted(hit_record.u, hit_record.v, hit_record.p)

      scattered_ray, attenuation = hit_record.material.scatter(r, hit_record)
      if scattered_ray && attenuation
        emitted + ray_color(scattered_ray, world, depth - 1) * attenuation
      else
        emitted
      end
    else
      background.value(r)
    end
  end

  def self.from_yaml(config : YAML::Any)
    width = config["options"]["width"].as_i
    height = config["options"]["height"].as_i

    look_from = V3.new(config["camera"]["look_from"][0].as_f,
                       config["camera"]["look_from"][1].as_f,
                       config["camera"]["look_from"][2].as_f)
    look_at = V3.new(config["camera"]["look_at"][0].as_f,
                     config["camera"]["look_at"][1].as_f,
                     config["camera"]["look_at"][2].as_f)
    view_up = V3.new(config["camera"]["view_up"][0].as_f,
                     config["camera"]["view_up"][1].as_f,
                     config["camera"]["view_up"][2].as_f)
    vertical_fov = config["camera"]["vertical_fov"].as_f
    aperture = config["camera"]["aperture"].as_f
    focus_distance_factor = config["camera"]["focus_distance_factor"].as_f
    start_time = config["camera"]["start_time"].as_f
    end_time = config["camera"]["end_time"].as_f

    camera = Camera.new(
      look_from: look_from,
      look_at: look_at,
      view_up: view_up,
      vertical_fov: vertical_fov,
      aperture: aperture,
      focus_distance: (look_from - look_at).magnitude * focus_distance_factor,
      aspect_ratio: width.to_f / height,
      start_time: start_time,
      end_time: end_time
    )

    textures = Hash(String, Texture).new
    if config["textures"]?
      config["textures"].as_h.each do |name, args|
        textures[name.as_s] = Texture.from_yaml(args, textures: textures)
      end
    end

    materials = Hash(String, Material).new
    if config["materials"]?
      config["materials"].as_h.each do |name, args|
        materials[name.as_s] = Material.from_yaml(yaml: args, textures: textures)
      end
    end

    primitives = Hash(String, Hittable).new

    if config["primitives"]?
      config["primitives"].as_h.each do |name, args|
        primitives[name.as_s] = Hittable.from_yaml(yaml: args, materials: materials, primitives: primitives)
      end
    end

    world = HittableList.new

    config["world"].as_a.each do |object|
      world << Hittable.from_yaml(yaml: object, materials: materials, primitives: primitives)
    end

    Ayanami.new width: width, height: height,
                samples_per_pixel: config["options"]["samples_per_pixel"].as_i,
                max_depth: config["options"]["max_depth"].as_i,
                world: BVHNode.new(world, start_time, end_time),
                camera: camera,
                background: Background.from_yaml(config["background"])
  end
end

if ARGV[0] == "--movie"
  # ayanami --movie renders/movies/ movies/foo-*.yaml
  folder = ARGV[1]
  configs = ARGV[2..-1]
  configs.sort.each_with_index do |config, index|
    puts "Starting index #{index}"
    Ayanami.from_yaml(YAML.parse(File.read(config))).run(output: folder + ("/%04d.png" % index), index: index)
    puts "End of index #{index}"
  end
else
  # ayanami input.yaml output.png
  config = YAML.parse(File.read(ARGV[0]))

  Ayanami.from_yaml(config).run(output: ARGV[1], preview: true)
end
