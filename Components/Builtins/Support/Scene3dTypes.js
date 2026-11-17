.pragma library

// Groups of Zui component names a Qt Quick 3D property will accept, so an
// adapter can collect the right declared children without each file repeating
// the list. A name whose component has not been registered simply never
// matches, which keeps a group stable as the 3D surface grows.

var materials = ["principled_material", "default_material", "specular_glossy_material",
                 "custom_material"]

var textures = ["texture_3d", "cube_map_texture"]

var textureData = ["procedural_texture_data", "procedural_sky_texture_data"]

var geometries = ["grid_geometry", "height_field_geometry", "procedural_mesh"]

var cameras = ["perspective_camera", "orthographic_camera", "frustum_camera", "custom_camera"]

var lights = ["directional_light", "point_light", "spot_light"]

var environments = ["scene_environment", "extended_scene_environment"]

var effects = ["effect_3d", "additive_color_gradient", "blur_3d", "brush_strokes",
               "chromatic_aberration", "color_master", "depth_of_field_hq_blur", "desaturate",
               "distortion_ripple", "distortion_sphere", "distortion_spiral", "edge_detect",
               "emboss", "flip", "fxaa", "gaussian_blur", "hdr_bloom_tonemap", "motion_blur",
               "s_curve_tonemap", "scatter", "tilt_shift", "vignette_3d"]

var instancing = ["instance_list", "random_instancing", "file_instancing"]

var particles = ["sprite_particle_3d", "model_particle_3d", "model_blend_particle_3d",
                 "line_particle_3d"]

var particleShapes = ["particle_shape_3d", "particle_model_shape_3d", "particle_custom_shape_3d"]

var particleDirections = ["target_direction_3d", "vector_direction_3d"]

var particleBursts = ["emit_burst_3d", "dynamic_burst_3d"]

var particleSystems = ["particle_system_3d"]
