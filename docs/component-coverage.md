# Built-in component coverage

Zui aims to provide a specific Ruby API for the application controls developers expect from
a complete UI framework. A custom `register_component` adapter does not count as built-in coverage.

Each completed component must include a registry schema, named Ruby builder method, native QML
renderer, reactive property support, applicable events, tests, and reference documentation.

## Scope

This catalog targets public, application-facing types from Qt Quick, Qt Quick Controls, Qt Quick
Layouts, Qt Quick Dialogs, Qt Quick Effects, Qt Quick Shapes, and Qt Multimedia, plus useful
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
- [x] clipboard

## Mobile permissions

- [x] bluetooth_permission
- [x] calendar_permission
- [x] camera_permission
- [x] contacts_permission
- [x] location_permission
- [x] microphone_permission

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
- [x] geocode_model
- [x] route_model

## Mobile speech

- [x] text_to_speech

## Mobile web content

- [x] web_view
