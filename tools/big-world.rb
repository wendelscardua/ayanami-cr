#!/usr/bin/ruby

require 'yaml'

config = YAML.load <<-YAML
  materials:
    ground:
      type: lambertian
      albedo:
        - 0.5
        - 0.5
        - 0.5
    mat1:
      type: dielectric
      refraction_index: 1.5
    mat2:
      type: lambertian
      albedo:
        - 0.4
        - 0.2
        - 0.1
    mat3:
      type: metal
      albedo:
        - 0.7
        - 0.6
        - 0.5
      fuzz: 0.0
  world:
    - type: sphere
      center:
        - 0.0
        - -1000.0
        - 0.0
      radius: 1000.0
      material: ground
    - type: sphere
      center:
        - 0.0
        - 1.0
        - 0.0
      radius: 1.0
      material: mat1
    - type: sphere
      center:
        - -4.0
        - 1.0
        - 0.0
      radius: 1.0
      material: mat2
    - type: sphere
      center:
        - 4.0
        - 1.0
        - 0.0
      radius: 1.0
      material: mat3
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
  options:
    width: 1920
    height: 1080
    samples_per_pixel: 64
    max_depth: 50
YAML

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
      config['materials'][mat_name] = {
        'type' => 'lambertian',
        'albedo' => [
          rand**2,
          rand**2,
          rand**2
        ]
      }
    elsif choose_mat < 0.95
      # metal
      config['materials'][mat_name] = {
        'type' => 'metal',
        'albedo' => [
          rand(0.5...1.0),
          rand(0.5...1.0),
          rand(0.5...1.0)
        ],
        'fuzz' => rand(0.0...0.5)
      }
    else
      # glass
      config['materials'][mat_name] = {
        'type' => 'dielectric',
        'refraction_index' => 1.5
      }
    end
    
    config['world'] << {
      'type' => 'sphere',
      'center' => [x, y, z],
      'radius' => 0.2,
      'material' => mat_name
    }
  end
end

puts config.to_yaml
