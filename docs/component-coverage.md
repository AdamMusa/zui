# Built-in component coverage

Zui aims to provide a specific Ruby API for the application controls developers expect from
a complete UI framework. A custom `register_component` adapter does not count as built-in coverage.

Each completed component must include a registry schema, named Ruby builder method, native QML
renderer, reactive property support, applicable events, tests, and reference documentation.

## Scope

This catalog targets public, application-facing types from Qt Quick, Qt Quick Controls, Qt Quick
Layouts, Qt Quick Dialogs, Qt Quick Effects, Qt Quick Shapes, Qt Quick 3D, and Qt Multimedia, plus useful
Zui-native controls and charts. Private `impl` types, style implementations, abstract base
classes, QML compiler infrastructure, compositor protocols, and operating-system service objects
are not widgets and are intentionally excluded. Framework concepts such as state, timers,
transitions, and animation groups receive Ruby APIs even though they are not visual widgets.

## Foundation and layout

- [x] control
- [x] container
- [x] row
- [x] column
- [x] grid
- [x] row_layout
- [x] column_layout
- [x] grid_layout
- [x] flow
- [x] stack
- [x] center
- [x] card
- [x] scroll
- [x] rectangle
- [x] border_overlay
- [x] aspect_ratio
- [x] constrained_box
- [x] fitted_box
- [x] wrap
- [x] split_view
- [x] stack_layout
- [x] layout_item_proxy
- [x] loader
- [x] flickable
- [x] focus_scope
- [x] flipable
- [x] border_image
- [x] window
- [x] application_window

## Display, content, and media

- [x] text
- [x] icon
- [x] image
- [x] spacer
- [x] separator
- [x] section_header
- [x] panel_hero
- [x] optical_glyph
- [x] tooltip
- [x] label
- [x] rich_text
- [x] selectable_text
- [x] animated_image
- [x] lottie_animation
- [x] pdf_view
- [x] video
- [x] audio
- [x] avatar
- [x] badge
- [x] chip
- [x] divider
- [x] markdown
- [x] vector_image
- [x] model_view_3d
- [x] font_loader
- [x] text_metrics

## Buttons and input

- [x] abstract_button
- [x] button
- [x] action_button
- [x] bar_icon_button
- [x] bar_indicator
- [x] widget_button
- [x] checkbox
- [x] toggle
- [x] toggle_switch
- [x] text_field
- [x] number_field
- [x] slider
- [x] dropdown
- [x] searchable_dropdown
- [x] multi_select
- [x] button_group
- [x] round_button
- [x] tool_button
- [x] delay_button
- [x] radio_button
- [x] radio_group
- [x] text_area
- [x] search_field
- [x] password_field
- [x] range_slider
- [x] dial
- [x] spin_box
- [x] color_picker
- [x] date_picker
- [x] time_picker
- [x] file_picker
- [x] folder_picker
- [x] font_picker
- [x] double_spin_box
- [x] dialog_button_box
- [x] action
- [x] action_group

## Navigation and structure

- [x] list_view
- [x] key_catcher
- [x] page
- [x] pane
- [x] frame
- [x] group_box
- [x] tabs
- [x] tab_bar
- [x] tab_button
- [x] page_indicator
- [x] stack_view
- [x] swipe_view
- [x] drawer
- [x] navigation_rail
- [x] breadcrumb
- [x] pagination
- [x] expansion_panel
- [x] accordion
- [x] tool_bar
- [x] tool_separator

## Menus, dialogs, and feedback

- [x] confirm_dialog
- [x] progress
- [x] menu
- [x] menu_item
- [x] menu_separator
- [x] menu_bar
- [x] menu_bar_item
- [x] context_menu
- [x] popup
- [x] dialog
- [x] alert_dialog
- [x] message_dialog
- [x] bottom_sheet
- [x] modal_sheet
- [x] snackbar
- [x] banner
- [x] toast
- [x] busy_indicator
- [x] progress_ring
- [x] skeleton

## Data and collections

- [x] item_delegate
- [x] check_delegate
- [x] radio_delegate
- [x] switch_delegate
- [x] swipe_delegate
- [x] grid_view
- [x] table_view
- [x] tree_view
- [x] data_table
- [x] horizontal_header
- [x] vertical_header
- [x] table_view_delegate
- [x] tree_view_delegate
- [x] horizontal_header_delegate
- [x] vertical_header_delegate
- [x] reorderable_list
- [x] carousel
- [x] calendar
- [x] calendar_model
- [x] month_grid
- [x] week_number_column
- [x] day_of_week_row
- [x] tumbler

## Charts and visualization

- [x] line_chart
- [x] area_chart
- [x] bar_chart
- [x] stacked_bar_chart
- [x] pie_chart
- [x] donut_chart
- [x] scatter_chart
- [x] bubble_chart
- [x] radar_chart
- [x] heatmap
- [x] sparkline
- [x] gauge
- [x] radial_gauge
- [x] histogram
- [x] candlestick_chart
- [x] legend

## Drawing and interaction

- [x] canvas
- [x] shape
- [x] line
- [x] path
- [x] circle
- [x] gradient
- [x] shader_effect
- [x] shader_effect_source
- [x] particle_system
- [x] drag_area
- [x] drop_area
- [x] pinch_area
- [x] hover_area
- [x] tap_area
- [x] point_handler
- [x] multi_touch_area
- [x] wheel_area
- [x] safe_area
- [x] selection_rectangle
- [x] scroll_bar
- [x] scroll_indicator

## Animation, state, and timing

- [x] animation
- [x] number_animation
- [x] color_animation
- [x] rotation_animation
- [x] vector_animation
- [x] path_animation
- [x] property_animation
- [x] pause_animation
- [x] script_action
- [x] property_action
- [x] parallel_animation
- [x] sequential_animation
- [x] spring_animation
- [x] smoothed_animation
- [x] anchor_animation
- [x] parent_animation
- [x] opacity_animator
- [x] rotation_animator
- [x] scale_animator
- [x] x_animator
- [x] y_animator
- [x] uniform_animator
- [x] frame_animation
- [x] animation_controller
- [x] behavior
- [x] transition
- [x] state
- [x] state_group
- [x] property_changes
- [x] anchor_changes
- [x] parent_change
- [x] timer

## Effects

- [x] multi_effect
- [x] rectangular_shadow
- [x] opacity_mask
- [x] blur
- [x] drop_shadow
- [x] colorize
- [x] glow

## Multimedia and capture

- [x] media_player
- [x] video_output
- [x] sound_effect
- [x] camera
- [x] capture_session
- [x] image_capture
- [x] media_recorder
- [x] audio_input
- [x] audio_output
- [x] media_devices
- [x] screen_capture
- [x] window_capture

## Models and utilities

- [x] list_model
- [x] delegate_model
- [x] delegate_model_group
- [x] sort_filter_proxy_model
- [x] folder_list_model
- [x] settings
- [x] standard_paths
- [x] system_info
- [x] network_status
- [x] clipboard

## Mobile permissions

- [x] bluetooth_permission
- [x] calendar_permission
- [x] camera_permission
- [x] contacts_permission
- [x] location_permission
- [x] microphone_permission

## Mobile virtual keyboard

- [x] virtual_keyboard
- [x] handwriting_input
- [x] keyboard_context
- [x] keyboard_settings
- [x] keyboard_text_field

## Mobile sensors

- [x] accelerometer
- [x] ambient_light_sensor
- [x] ambient_temperature_sensor
- [x] compass
- [x] gyroscope
- [x] humidity_sensor
- [x] ir_proximity_sensor
- [x] lid_sensor
- [x] light_sensor
- [x] magnetometer
- [x] orientation_sensor
- [x] pressure_sensor
- [x] proximity_sensor
- [x] rotation_sensor
- [x] tap_sensor
- [x] tilt_sensor

## Mobile positioning

- [x] position_source
- [x] satellite_source

## Mobile maps

- [x] map
- [x] map_circle
- [x] map_rectangle
- [x] map_polygon
- [x] map_polyline
- [x] map_route
- [x] map_marker
- [x] map_item_group
- [x] map_item_view
- [x] map_copyright
- [x] geo_json_data
- [x] geocode_model
- [x] route_model
- [x] place_search
- [x] place_suggestions
- [x] place_categories
- [x] place_details
- [x] place_category

## Mobile speech

- [x] text_to_speech

## Mobile web content

- [x] web_view
- [x] web_socket
- [x] web_socket_server

## GPU 3D scene graph

Qt Quick 3D types. A 3D node is declared inside a `view_3d`, which owns the GPU
scene. Resources such as materials and geometries may be declared inside the
node that uses them, or anywhere in the scene and referenced by their Ruby id.

### Viewport and scene graph

- [x] view_3d
- [x] node_3d
- [x] model_3d
- [x] loader_3d
- [x] repeater_3d

### Cameras

A view_3d adopts the first camera declared inside it, or the one named by
its `camera` property.

- [x] perspective_camera
- [x] orthographic_camera
- [x] frustum_camera
- [x] custom_camera

### Lights

Lights are nodes, so a light declared inside a node_3d moves with it. A
light with a `scope` lights only that node and its children.

- [x] directional_light
- [x] point_light
- [x] spot_light

### Materials

A material is declared inside the model that uses it, or anywhere in the
scene and named through the model's `materials`. Texture slots take the
Ruby id of a texture node.

- [x] principled_material
- [x] default_material
- [x] specular_glossy_material
- [x] custom_material

### Textures

A texture is named by the material slot that samples it. TextureData is an
abstract C++ base with no QML-creatable form; its concrete shapes are the
procedural texture data helpers.

- [x] texture_3d
- [x] cube_map_texture
- [x] texture_input

### Scene environment

A view_3d adopts the first scene environment declared inside it. Fog, a
lightmapper and debug settings are declared inside the environment that
uses them.

- [x] scene_environment
- [x] extended_scene_environment
- [x] fog
- [x] debug_settings
- [x] lightmapper
- [x] baked_lightmap
- [x] reflection_probe
- [x] resource_loader

### Skeletal animation and morphing

A model names the skeleton or skin that deforms it, and the morph targets
it can blend towards, either by declaring them inside the model or by
naming nodes declared elsewhere in the scene.

- [x] skeleton_3d
- [x] joint_3d
- [x] skin_3d
- [x] morph_target

### Instancing

A model names the instance table that repeats it, so one mesh is drawn
many times in a single GPU pass.

- [x] instance_list
- [x] instance_list_entry
- [x] random_instancing
- [x] instance_range
- [x] file_instancing

### Custom effects and render passes

An effect belongs to the scene environment that runs it. Its passes,
shaders, buffers and commands are declared inside it, or named by id.

- [x] effect_3d
- [x] pass_3d
- [x] shader_3d
- [x] buffer_3d
- [x] buffer_input
- [x] set_uniform_value

### Helpers: camera controllers

A camera controller is a Qt Quick item that reads input over the viewport,
so it is declared inside the view_3d whose camera it drives and names
that camera by id.

- [x] orbit_camera_controller
- [x] wasd_controller
- [x] look_at_node
- [x] lod_manager

### Helpers: debug, grids and procedural geometry

Qt's helper module. ExtrudedTextGeometry is not part of Qt 6.8.3 and so
has no component here.

- [x] axis_helper
- [x] debug_view_3d
- [x] infinite_grid
- [x] grid_geometry
- [x] height_field_geometry
- [x] procedural_mesh
- [x] procedural_mesh_subset
- [x] procedural_texture_data
- [x] procedural_sky_texture_data
- [x] instance_model
- [x] instance_repeater

### Runtime asset loading

model_view_3d remains the convenience orbit viewer built on this; the
loader itself sits in a view_3d alongside anything else.

- [x] runtime_loader
