#!/usr/bin/ruby

require 'yaml'

@config = YAML.safe_load <<-YAML
  camera:
    look_from:
      - 478.0
      - 278.0
      - -600.0
    look_at:
      - 278.0
      - 278.0
      - 0.0
    view_up:
      - 0.0
      - 1.0
      - 0.0
    vertical_fov: 40.0
    aperture: 0.1
    focus_distance_factor: 1.0
    start_time: 0.0
    end_time: 1.0
  options:
    width: 800
    height: 800
    samples_per_pixel: 64
    max_depth: 50
    background:
      - 0.0
      - 0.0
      - 0.0
YAML

def tex(name, type, **args)
  @config['textures'] ||= {}
  @config['textures'][name] = {
    'type' => type
  }.merge(args.transform_keys(&:to_s))
  name
end

def color(r, g, b)
  tex("color#{rand}", 'solid_color', color: [r, g, b])
end

def mat(name, type, **args)
  @config['materials'] ||= {}
  @config['materials'][name] = {
    'type' => type
  }.merge(args.transform_keys(&:to_s))
  name
end

def box(minimum, maximum, material)
  {
    'type' => 'box',
    'minimum' => minimum,
    'maximum' => maximum,
    'material' => material
  }
end

def sphere(c, r, m)
  {
    'type' => 'sphere',
    'center' => c,
    'radius' => r,
    'material' => m
  }
end

def moving_sphere(c1, c2, t1, t2, r, material)
  {
    'type' => 'moving_sphere',
    'start_center' => c1,
    'end_center' => c2,
    'start_time' => t1,
    'end_time' => t2,
    'radius' => r,
    'material' => material
  }
end

def bvh(list, t0, t1)
  {
    'type' => 'bvh',
    'objects' => list,
    'start_time' => t0,
    'end_time' => t1
  }
end

def xz_rect(x0, x1, z0, z1, k, material)
  {
    'type' => 'xzrect',
    'x0' => x0,
    'x1' => x1,
    'z0' => z0,
    'z1' => z1,
    'k' => k,
    'material' => material
  }
end

def translate(p, offset)
  {
    'type' => 'translate',
    'offset' => offset,
    'inline' => p
  }
end

def rotate_y(p, theta)
  {
    'type' => 'rotate_y',
    'theta' => theta,
    'inline' => p
  }
end

def constant_medium(boundary, density, iso_albedo)
  {
    'type' => 'constant_medium',
    'inline' => boundary,
    'density' => density,
    'material' => mat("iso#{rand}", 'isotropic', albedo: iso_albedo)
  }
end

mat 'ground', 'lambertian', albedo: color(0.48, 0.83, 0.53)

boxes1 = []

(0...20).each do |i|
  (0...20).each do |j|
    w = 100.0
    x0 = -1000.0 + i * w
    z0 = -1000.0 + j * w
    y0 = 0.0
    x1 = x0 + w
    y1 = rand(1.0..101.0)
    z1 = z0 + w

    boxes1 << box([x0, y0, z0], [x1, y1, z1], 'ground')
  end
end

objects = []

objects << bvh(boxes1, 0.0, 1.0)

mat 'light', 'diffuse_light', texture: color(7.0, 7.0, 7.0)

objects << xz_rect(123.0, 423.0, 147.0, 412.0, 554.0, 'light')

mat 'moving_sphere_material', 'lambertian', albedo: color(0.7, 0.3, 0.1)
objects << moving_sphere([400.0, 400.0, 200.0],
                         [400.0 + 30.0, 400.0 + 0.0, 200.0 + 0.0],
                         0.0, 1.0,
                         50.0,
                         'moving_sphere_material')

objects << sphere([260.0, 150.0, 45.0], 50.0, mat('glass', 'dielectric', refraction_index: 1.5))
objects << sphere([0.0, 150.0, 145.0], 50.0, mat('metal', 'metal', albedo: [0.8, 0.8, 0.9], fuzz: 1.0))

boundary = sphere([360.0, 150.0, 145.0], 70.0, 'glass')
objects << boundary
objects << constant_medium(boundary, 0.2, color(0.2, 0.4, 0.9))

boundary = sphere([0.0, 0.0, 0.0], 5000.0, 'glass')
objects << constant_medium(boundary, 0.0001, color(1.0, 1.0, 1.0))

mat 'emat', 'lambertian', albedo: tex('etex', 'image', filename: 'textures/earthmap.png')
objects << sphere([400.0, 200.0, 400.0], 100.0, 'emat')
tex 'pertext', 'noise', scale: 0.1
objects << sphere([220.0, 280.0, 300.0], 80.0, mat('perlin', 'lambertian', albedo: 'pertext'))

boxes2 = []
mat 'white', 'lambertian', albedo: color(0.73, 0.73, 0.73)

1000.times do
  boxes2 << sphere([rand(0.0..165.0), rand(0.0..165.0), rand(0.0..165.0)], 10.0, 'white')
end

objects <<
  translate(
    rotate_y(
      bvh(boxes2, 0.0, 1.0),
      15.0
    ),
    [-100.0, 270.0, 395.0]
  )

@config['world'] = objects

puts @config.to_yaml
