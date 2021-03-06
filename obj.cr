# based on l3kn/raytracer

module OBJ
  def self.parse(filename, mat, interpolated = false, textured = false, materials = {} of String => Material)
    obj = File.read(filename)

    hittables = HittableList.new
    vertices = [] of V3
    normals = [] of V3
    texture_coords = [] of V3

    material = mat

    obj.lines.each do |line|
      tokens = line.split
      next if tokens.empty?

      case tokens[0]
      when "usemtl"
        name = tokens[1]
        if materials.has_key?(name)
          material = materials[name]
        else
          puts "Error, Missing material #{name}"
          material = mat
        end
      when "v"
        cords = tokens[1, 3].map(&.to_f)
        vertices << V3.new(cords[0], cords[1], cords[2])
      when "vn"
        cords = tokens[1, 3].map(&.to_f)
        normals << V3.new(cords[0], cords[1], cords[2]).normalize!
      when "vt"
        cords = tokens[1, 3].map(&.to_f)
        texture_coords << V3.new(cords[0], cords.size >= 2 ? cords[1] : 0.0, cords.size == 3 ? cords[2] : 0.0)
      when "f"
        vs = tokens[1..-1].map { |i| i.split("/") }

        (1..(vs.size - 2)).each do |i|
          a = vertices[vs[0][0].to_i - 1]
          b = vertices[vs[i][0].to_i - 1]
          c = vertices[vs[i + 1][0].to_i - 1]

          if interpolated
            raise "Error, there are no normals in this .obj file" if normals.empty?

            na = normals[vs[0][2].to_i - 1]
            nb = normals[vs[i][2].to_i - 1]
            nc = normals[vs[i + 1][2].to_i - 1]
            if textured
              raise "Error, there are no texture coords in this .obj file" if materials.empty?
              ta = texture_coords[vs[0][1].to_i - 1]
              tb = texture_coords[vs[i][1].to_i - 1]
              tc = texture_coords[vs[i + 1][1].to_i - 1]

              hittables << TexturedTriangle.new(a, b, c, na, nb, nc, ta, tb, tc, material)
            else
              hittables << InterpolatedTriangle.new(a, b, c, na, nb, nc, material)
            end
          else
            hittables << Triangle.new(a, b, c, material)
          end
        end
      end
    end
    puts "Parsed #{vertices.size} vertices"
    puts "Parsed #{vertices.size} normals"
    puts "Parsed #{texture_coords.size} texture coords"
    puts "Parsed #{hittables.objects.size} faces"

    hittables
  end
end
