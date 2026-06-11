# Silhouette Chim Lạc — đa giác 2D + mesh phẳng dùng cho stencil và hình mờ trên tường.
extends RefCounted


static func polygon() -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2(-0.50, 0.02))                                          # mỏ
	_quad(pts, Vector2(-0.50, 0.02), Vector2(-0.34, 0.10), Vector2(-0.26, 0.09))  # đầu
	_quad(pts, Vector2(-0.26, 0.09), Vector2(-0.16, 0.22), Vector2(0.02, 0.28))   # mép trước cánh
	_quad(pts, Vector2(0.02, 0.28), Vector2(0.14, 0.30), Vector2(0.26, 0.24))     # chóp cánh
	_quad(pts, Vector2(0.26, 0.24), Vector2(0.12, 0.16), Vector2(0.06, 0.08))     # mép sau cánh
	_quad(pts, Vector2(0.06, 0.08), Vector2(0.26, 0.10), Vector2(0.42, 0.02))     # lưng về đuôi
	pts.append(Vector2(0.50, -0.06))                                          # chóp đuôi
	_quad(pts, Vector2(0.50, -0.06), Vector2(0.36, -0.14), Vector2(0.30, -0.10))  # chẽ đuôi
	_quad(pts, Vector2(0.30, -0.10), Vector2(0.10, -0.16), Vector2(-0.10, -0.12)) # bụng
	_quad(pts, Vector2(-0.10, -0.12), Vector2(-0.32, -0.08), Vector2(-0.44, -0.02)) # ức
	return pts


static func _quad(pts: PackedVector2Array, a: Vector2, c: Vector2, b: Vector2, n: int = 8) -> void:
	for i in range(1, n + 1):
		var t := float(i) / float(n)
		pts.append(a.lerp(c, t).lerp(c.lerp(b, t), t))


static func make_mesh() -> ArrayMesh:
	var poly := polygon()
	var idx := Geometry2D.triangulate_polygon(poly)
	var verts := PackedVector3Array()
	for p in poly:
		verts.append(Vector3(p.x, p.y, 0.0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
