#!/usr/bin/ruby

require 'yaml'
require_relative './world-tools.rb'

@config = YAML.load <<-YAML
  camera:
    look_from:
      - 13.0
      - 2.0
      - 3.0
    look_at:
      - 0.0
      - 0.0
      - 0.0
    view_up:
      - 0.0
      - 1.0
      - 0.0
    vertical_fov: 20.0
    aperture: 0.1
    focus_distance_factor: 1.0
    start_time: 0.0
    end_time: 1.0
  options:
    width: 1920
    height: 1080
    samples_per_pixel: 64
    max_depth: 50
    background:
      - 0.7
      - 0.8
      - 1.0
YAML

world = []

mat 'ground', 'lambertian', albedo: color(0.5, 0.5, 0.5)

world << sphere([0.0, -1000.0, 0.0], 1000.0, 'ground')

(-11..11).each do |a|
  (-11..11).each do |b|
    x = a + rand(0...0.9)
    y = 0.2
    z = b + rand(0...0.9)

    next unless (x - 4)**2 + (y - 0.2)**2 + (z - 0)**2 > 0.9**2

    mat_name = "mat_#{a + 11}_#{b + 11}"

    choose_mat = rand

    if choose_mat < 0.8
      # diffuse
      mat mat_name, 'lambertian', albedo: color(rand**2, rand**2, rand**2)
    elsif choose_mat < 0.95
      # metal
      mat mat_name,
          'metal',
          albedo: [
            rand(0.5...1.0),
            rand(0.5...1.0),
            rand(0.5...1.0)
          ],
          fuzz: rand(0.0...0.5)
    else
      # glass
      mat mat_name,
          'dielectric',
          refraction_index: 1.5
    end
    
    world << sphere([x, y, z], 0.2, mat_name)
  end
end

world << sphere(
  [0.0, 1.0, 0.0],
  1.0,
  mat('mat1', 'dielectric', refraction_index: 1.5)
)

world << sphere(
  [-4.0, 1.0, 0.0],
  1.0,
  mat('mat2', 'lambertian', albedo: color(0.4, 0.2, 0.1))
)

world <<  sphere(
  [4.0, 1.0, 0.0],
  1.0,
  mat('mat3', 'metal', albedo: [0.7, 0.6, 0.5], fuzz: 0.0)
)

@config['world'] = world

puts @config.to_yaml
