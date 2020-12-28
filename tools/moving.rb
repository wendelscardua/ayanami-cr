#!/usr/bin/ruby

require 'yaml'

template = YAML.safe_load(File.read(ARGV[0]))

# constants
start_t = 0.0
end_t = 1.0
samples = 60
delta_t = (end_t - start_t) / samples

# moving stuff

get = lambda do |path|
  path.split('.').reduce(template) { |a,e| a[e] }
end

look_radius = 5.0

t_function = lambda do |t|
  center = get.('camera.look_at')
  look_from = [
    center[0] + look_radius * Math.cos(2 * t * Math::PI),
    center[1] + 0.25 * Math.sin(2 * t * Math::PI),
    center[2] + look_radius * Math.sin(2 * t * Math::PI)
  ]
  template['camera']['look_from'] = look_from
end

t = start_t
fc = 0
while t <= end_t
  t_function.(t)
  File.write(ARGV[1] + ("-%04d.yaml" % fc), template.to_yaml)
  t += delta_t
  fc += 1
end
