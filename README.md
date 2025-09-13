# godot_material_from_textures
Godot utility EditorScript. Generates godot materials from textures output by Substance Painter. Basic functionality for now, might improve later.
Will work with any other textures as well, they don't have to be from Substance Painter. You will have to change the script to know what file names to look for in case you're working with a different setup from mine.

# Key features
- Looks at the texture files pixel values to determine if the color is uniform -> if it is, does not use the texture but instead just a single Color/float value in the material representing the whole thing. Optimised.
- Does not choke on missing texture types. You can supply only the Base_color and Metallic for example and it'll work just fine.

# Why?
I thought there must be a better way to create materials from textures. There might be a better built-in solution somewhere. My workflow might not be ideal. Made this to solve a problem I currently have. Feel free to let me know if there is a better solution available.

# Usage
Place the gen_materials.gd script anywhere in your godot project and edit the "TEXTURE_DIR" and "OUTPUT_DIR" constants to whatever you need. Run the script. Boom. You will still have to manually assign the materials, but I might later update this to automatically assign the materials to meshes with the same names.

# TODO
- Combine Base_color and Opacity textures into one texture with alpha
- Other types of textures I may need