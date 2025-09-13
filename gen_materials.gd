@tool
extends EditorScript

const TEXTURE_DIR := "" # "res://<your_textures_directory>" source texture dir
const OUTPUT_DIR := "" # "res://<your_materials_directory>" target materials dir

# Which suffixes map to which material property names
const MAPS := {
	"Base_color": "albedo_texture",
	"Normal_OpenGL": "normal_texture",
	"Roughness": "roughness_texture",
	"Metallic": "metallic_texture",
	"Mixed_AO": "ao_texture",
	"Height": "height_texture"
}

func _run():
	var dir := DirAccess.open(TEXTURE_DIR)
	if not dir:
		push_error("Could not open textures directory")
		return

	# Group by <material_name>
	var materials := {}

	for file in dir.get_files():
		if file.ends_with(".png"):
			var file_name = file.get_basename()
			var matched_suffix = ""
			var mat_name = ""
			
			var suffixes = MAPS.keys() # Base_color, Metallic, Mixed_AO etc.
			for s in suffixes:
				if file_name.ends_with(s):
					matched_suffix = s
					mat_name = file_name.substr(0, file_name.length() - s.length() - 1) # remove trailing "_"
					break
			
			if matched_suffix == "":
				push_warning("Skipping unknown texture suffix (file): %s" % file)
				continue
			
			if mat_name.strip_edges() == "":
				push_warning("skipping file with empty material name: %s" % file)
				continue
			
			if not materials.has(mat_name):
				materials[mat_name] = {}
			materials[mat_name][matched_suffix] = TEXTURE_DIR + "/" + file
	
	# Make sure output directory exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	for mat_name in materials.keys():
		_create_material(mat_name, materials[mat_name])

	print("Material generation complete.")


func _create_material(mat_name: String, textures: Dictionary) -> void:
	var mat := StandardMaterial3D.new()

	for suffix in textures.keys():
		if not MAPS.has(suffix):
			continue
		var prop_name = MAPS[suffix]
		var img := Image.new()
		var err := img.load(textures[suffix])
		if err != OK: 
			continue

		# Check if uniform
		var debug = false
		if prop_name == "metallic_texture":
			debug = true
		var uniform = _is_image_uniform(img, 0.01, 20000, false, debug)
		if uniform != null:
			# If uniform: set the value property instead of using a texture
			match prop_name:
				"albedo_texture": mat.albedo_color = Color(uniform.r, uniform.g, uniform.b)
				"roughness_texture": mat.roughness = uniform.r
				"metallic_texture": mat.metallic = uniform.r
				# AO, height, normal are usually not used as scalar if uniform, so just skip
		else:
			# Use as texture
			var tex := load(textures[suffix]) as Texture2D
			if tex:
				match prop_name:
					"normal_texture":
						mat.normal_enabled = true
						mat.normal_texture = tex
					"roughness_texture":
						mat.roughness_texture = tex
					"metallic_texture":
						mat.metallic_texture = tex
					"ao_texture":
						mat.ao_enabled = true
						mat.ao_texture = tex
					"height_texture":
						mat.heightmap_enabled = true
						mat.heightmap_scale = 1.0 # Defaults to 5.0 for some reason
						mat.heightmap_texture = tex
					"albedo_texture":
						mat.albedo_texture = tex
	
	# Save material
	var save_path = OUTPUT_DIR + "/" + mat_name + ".tres"
	ResourceSaver.save(mat, save_path)


# Returns a Color if the image is approximately uniform, otherwise null.
# tol: tolerance per channel (0..1). Increase if compression/noise creates tiny variations.
# max_samples: maximum number of pixels to test (speeds up large images).
# check_alpha: if true, also require alpha channel to be uniform.
# debug: prints first mismatch when debug is true.
func _is_image_uniform(img: Image, tol: float = 0.01, max_samples: int = 20000, check_alpha: bool = false, debug: bool = false):
	if not img:
		return null
	var w := img.get_width()
	var h := img.get_height()
	if w == 0 or h == 0:
		return null
	
	# sample step calculation (1 = every pixel). If image is large, we sample a grid.
	var area := w * h
	var step := 1
	if area > max_samples:
		step = int(ceil(sqrt(float(area) / float(max_samples))))
		if step < 1:
			step = 1
	
	# reference pixel (top-left)
	var ref := img.get_pixel(0, 0)
	
	# sample grid
	for y in range(0, h, step):
		for x in range(0, w, step):
			var p := img.get_pixel(x, y)
			if abs(p.r - ref.r) > tol or abs(p.g - ref.g) > tol or abs(p.b - ref.b) > tol:
				if debug:
					print("Uniform check fail at (%d,%d): ref=%s got=%s tol=%f" % [x, y, ref, p, tol])
				return null
			if check_alpha and abs(p.a - ref.a) > tol:
				if debug:
					print("Alpha mismatch at (%d,%d): ref.a=%f got.a=%f tol=%f" % [x, y, ref.a, p.a, tol])
				return null
	
	# all sampled pixels matched
	return ref
