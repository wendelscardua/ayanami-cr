#!/usr/bin/ruby

require 'yaml'
require_relative './world-tools.rb'

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
