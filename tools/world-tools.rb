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
