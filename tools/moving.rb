#!/usr/bin/ruby

require 'yaml'

template = YAML.load(File.read(ARGV[0]))

# constants
start_t = 0.0
end_t = 1.0
samples = 60
delta_t = (end_t - start_t) / samples

# moving stuff

get = lambda do |path|
  path.split('.').reduce(template) { |a,e| a[e] }
end


t_function =
  case ARGV[0]
  when 'worlds/ballroom.yaml'
    look_radius = 5.0
    lambda do |t|
      center = get.('camera.look_at')
      look_from = [
        center[0] + look_radius * Math.cos(2 * t * Math::PI),
        center[1] + 0.25 * Math.sin(2 * t * Math::PI),
        center[2] + look_radius * Math.sin(2 * t * Math::PI)
      ]
      template['camera']['look_from'] = look_from
    end
  when 'worlds/final-scene.yaml'
    look_radius = ((200.0**2) + (600.0**2))**0.5
    lambda do |t|
      center = get.('camera.look_at')
      look_from = [
        center[0] + look_radius * Math.cos(2 * t * Math::PI),
        center[1] + 50 * Math.sin(2 * t * Math::PI),
        center[2] + look_radius * Math.sin(2 * t * Math::PI)
      ]
      template['camera']['look_from'] = look_from
    end
  when 'worlds/quadjulia.yaml'
    lambda do |t|
      template['world'][0]['estimator']['slice'] = t * 2.0 - 1.0
    end
  when 'worlds/juliabulb.yaml'
    lambda do |t|
      template['world'][0]['estimator']['c'] = [2.0 * t - 1.0, 2.0 * t - 1.0, 0.15]
    end
  when 'worlds/mandelbulb.yaml'
    lambda do |t|
      template['world'][0]['estimator']['power'] = t * 7.0 + 1.0
    end
  when 'worlds/teapots.yaml'
    look_radius = ((1.5**2) + (3.0**2))**0.5
    lambda do |t|
      center = get.('camera.look_at')
      look_from = [
        center[0] + look_radius * Math.cos(2 * t * Math::PI),
        1.5,
        center[2] + look_radius * Math.sin(2 * t * Math::PI)
      ]
      template['camera']['look_from'] = look_from
    end
  end

t = start_t
fc = 0
while t <= end_t
  t_function.(t)
  File.write(ARGV[1] + ("-%04d.yaml" % fc), template.to_yaml)
  t += delta_t
  fc += 1
end
