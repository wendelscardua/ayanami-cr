class Camera
  getter vertical_fov : Float64, aspect_ratio : Float64,
         origin : V3, horizontal : V3, vertical : V3, lower_left_corner : V3

  def initialize(
       look_from : V3, look_at : V3, view_up : V3,
       vertical_fov : Float64, aspect_ratio : Float64
     )
    @vertical_fov = vertical_fov
    @aspect_ratio = aspect_ratio

    theta = Math::PI / 180 * vertical_fov
    h = Math.tan(theta / 2)
    viewport_height = 2.0 * h
    viewport_width = aspect_ratio * viewport_height

    w = (look_from - look_at).normalize!
    u = (view_up % w).normalize!
    v = w % u

    @origin = look_from
    @horizontal = u * viewport_width
    @vertical = v * viewport_height
    @lower_left_corner = @origin - @horizontal * 0.5 - @vertical * 0.5 - w
  end

  def ray(u, v) : Ray
    Ray.new @origin, @lower_left_corner + @horizontal * u + @vertical * v - @origin
  end
end
