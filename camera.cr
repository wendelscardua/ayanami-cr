class Camera
  getter vertical_fov : Float64, aspect_ratio : Float64,
         origin : V3, horizontal : V3, vertical : V3, lower_left_corner : V3

  def initialize(vertical_fov : Float64, aspect_ratio : Float64)
    @vertical_fov = vertical_fov
    @aspect_ratio = aspect_ratio

    theta = Math::PI / 180 * vertical_fov
    h = Math.tan(theta / 2)
    viewport_height = 2.0 * h
    viewport_width = aspect_ratio * viewport_height
    focal_length = 1.0

    @origin = V3.new(0.0, 0.0, 0.0)
    @horizontal = V3.new(viewport_width, 0.0, 0.0)
    @vertical = V3.new(0.0, viewport_height, 0.0)
    @lower_left_corner = @origin - @horizontal * 0.5 - @vertical * 0.5 - V3.new(0.0, 0.0, focal_length)
  end

  def ray(u, v) : Ray
    Ray.new @origin, @lower_left_corner + @horizontal * u + @vertical * v - @origin
  end
end
