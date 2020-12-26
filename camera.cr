class Camera
  getter vertical_fov : Float64, aspect_ratio : Float64,
         origin : V3, horizontal : V3, vertical : V3, lower_left_corner : V3,
         u : V3, v : V3, w : V3,
         lens_radius : Float64,
         start_time : Float64,
         end_time : Float64

  def initialize(
       look_from : V3, look_at : V3, view_up : V3,
       vertical_fov : Float64, aspect_ratio : Float64,
       aperture : Float64, focus_distance : Float64,
       start_time : Float64, end_time : Float64
     )
    @vertical_fov = vertical_fov
    @aspect_ratio = aspect_ratio

    theta = Math::PI / 180 * vertical_fov
    h = Math.tan(theta / 2)
    viewport_height = 2.0 * h
    viewport_width = aspect_ratio * viewport_height

    @w = (look_from - look_at).normalize!
    @u = (view_up % @w).normalize!
    @v = @w % @u

    @origin = look_from
    @horizontal = @u * viewport_width * focus_distance
    @vertical = @v * viewport_height * focus_distance
    @lower_left_corner = @origin - @horizontal * 0.5 - @vertical * 0.5 - @w * focus_distance
    @lens_radius = aperture / 2

    @start_time = start_time
    @end_time = end_time
  end

  def ray(s, t) : Ray
    rd = V3.random_in_unit_disk * lens_radius
    offset = u * rd.x + v * rd.y
    Ray.new origin + offset,
            lower_left_corner + horizontal * s + vertical * t - (origin + offset),
            rand(start_time..end_time)
  end
end
