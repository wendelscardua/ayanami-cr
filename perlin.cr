class Perlin
  getter ranvec : Array(V3),
         perm_x : Array(Int32),
         perm_y : Array(Int32),
         perm_z : Array(Int32)

  def initialize
    @ranvec = (0..255).map { V3.random_vector(-1.0, 1.0).normalize! }
    @perm_x = (0..255).to_a.shuffle
    @perm_y = (0..255).to_a.shuffle
    @perm_z = (0..255).to_a.shuffle
  end

  def turbulence(p : V3, depth = 7)
    accum = 0.0
    temp_p = p
    weight = 1.0

    depth.times do
      accum += weight * noise(temp_p)
      weight *= 0.5
      temp_p *= 2.0
    end

    accum.abs
  end

  def noise(p : V3) : Float64
    u = p.x - p.x.floor
    v = p.y - p.y.floor
    w = p.z - p.z.floor

    i = p.x.floor.to_i
    j = p.y.floor.to_i
    k = p.z.floor.to_i

    z = V3.zero
    c = Array.new(2) { Array.new(3) { Array.new(3) { z } } }

    (0..1).each do |di|
      (0..1).each do |dj|
        (0..1).each do |dk|
          c[di][dj][dk] = ranvec[perm_x[(i + di) & 255] ^
                                 perm_y[(j + dj) & 255] ^
                                 perm_z[(k + dk) & 255]]
        end
      end
    end

    perlin_interp(c, u, v, w)
  end

  def perlin_interp(c, u, v, w)
    # Hermitian smoothing
    uu = u * u * (3 - 2 * u)
    vv = v * v * (3 - 2 * v)
    ww = w * w * (3 - 2 * w)

    acc = 0.0
    (0..1).each do |i|
      (0..1).each do |j|
        (0..1).each do |k|
          weight_v = V3.new(u - i, v - j, w - k)
          acc += (i * uu + (1 - i) * (1 - uu)) *
                 (j * vv + (1 - j) * (1 - vv)) *
                 (k * ww + (1 - k) * (1 - ww)) *
                 c[i][j][k].dot(weight_v)
        end
      end
    end
    acc
  end
end
