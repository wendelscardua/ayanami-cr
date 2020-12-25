class Perlin
  getter ranfloat : Array(Float64),
         perm_x : Array(Int32),
         perm_y : Array(Int32),
         perm_z : Array(Int32)

  def initialize
    @ranfloat = (0..255).map { rand }
    @perm_x = (0..255).to_a.shuffle
    @perm_y = (0..255).to_a.shuffle
    @perm_z = (0..255).to_a.shuffle
  end

  def noise(p : V3) : Float64
    u = p.x - p.x.floor
    v = p.y - p.y.floor
    w = p.z - p.z.floor

    # Hermitian smoothing
    u = u * u * (3 - 2 * u)
    v = v * v * (3 - 2 * v)
    w = w * w * (3 - 2 * w)

    i = p.x.floor.to_i
    j = p.y.floor.to_i
    k = p.z.floor.to_i

    c = Array.new(2) { Array.new(3) { Array.new(3) { 0.0 } } }

    (0..1).each do |di|
      (0..1).each do |dj|
        (0..1).each do |dk|
          c[di][dj][dk] = ranfloat[perm_x[(i + di) & 255] ^
                                   perm_y[(j + dj) & 255] ^
                                   perm_z[(k + dk) & 255]]
        end
      end
    end

    trilinear_interp(c, u, v, w)
  end

  def trilinear_interp(c, u, v, w)
    acc = 0.0
    (0..1).each do |i|
      (0..1).each do |j|
        (0..1).each do |k|
          acc += (i * u + (1 - i) * (1 - u)) *
                 (j * v + (1 - j) * (1 - v)) *
                 (k * w + (1 - k) * (1 - w)) * c[i][j][k]

        end
      end
    end
    acc
  end
end
