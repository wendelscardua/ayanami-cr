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
    i = (4 * p.x).to_i & 255;
    j = (4 * p.y).to_i & 255;
    k = (4 * p.z).to_i & 255;

    return ranfloat[perm_x[i] ^ perm_y[j] ^ perm_z[k]]
  end
end
