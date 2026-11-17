# frozen_string_literal: true

module Zui
  module Mobile
    module ComponentCatalog
      QUICK_CONTROLS = {
        "AbstractButton" => :abstract_button, "Action" => :action, "ActionGroup" => :action_group,
        "ApplicationWindow" => :application_window, "BusyIndicator" => :busy_indicator,
        "Button" => :button, "ButtonGroup" => :button_group, "CheckBox" => :checkbox,
        "CheckDelegate" => :check_delegate, "ComboBox" => :dropdown, "Container" => :container,
        "Control" => :control, "DelayButton" => :delay_button, "Dial" => :dial,
        "Dialog" => :dialog, "DialogButtonBox" => :dialog_button_box, "Drawer" => :drawer,
        "Frame" => :frame, "GroupBox" => :group_box, "HorizontalHeaderView" => :horizontal_header,
        "ItemDelegate" => :item_delegate, "Label" => :label, "Menu" => :menu,
        "MenuBar" => :menu_bar, "MenuBarItem" => :menu_bar_item, "MenuItem" => :menu_item,
        "MenuSeparator" => :menu_separator, "Page" => :page, "PageIndicator" => :page_indicator,
        "Pane" => :pane, "Popup" => :popup, "ProgressBar" => :progress,
        "RadioButton" => :radio_button, "RadioDelegate" => :radio_delegate,
        "RangeSlider" => :range_slider, "RoundButton" => :round_button,
        "ScrollBar" => :scroll_bar, "ScrollIndicator" => :scroll_indicator,
        "ScrollView" => :scroll, "SelectionRectangle" => :selection_rectangle,
        "Slider" => :slider, "SpinBox" => :spin_box, "SplitView" => :split_view,
        "StackView" => :stack_view, "SwipeDelegate" => :swipe_delegate,
        "Switch" => :toggle_switch, "SwitchDelegate" => :switch_delegate,
        "SwipeView" => :swipe_view, "TabBar" => :tab_bar, "TabButton" => :tab_button,
        "TextArea" => :text_area, "TextField" => :text_field, "ToolBar" => :tool_bar,
        "ToolButton" => :tool_button, "ToolSeparator" => :tool_separator,
        "ToolTip" => :tooltip, "Tumbler" => :tumbler,
        "VerticalHeaderView" => :vertical_header, "CalendarModel" => :calendar_model,
        "DayOfWeekRow" => :day_of_week_row, "MonthGrid" => :month_grid,
        "WeekNumberColumn" => :week_number_column, "TreeViewDelegate" => :tree_view_delegate
      }.freeze

      QUICK_DIALOGS = {
        "ColorDialog" => :color_picker, "FileDialog" => :file_picker,
        "FolderDialog" => :folder_picker, "FontDialog" => :font_picker,
        "MessageDialog" => :message_dialog
      }.freeze

      QUICK_LAYOUTS = {
        "RowLayout" => :row_layout, "ColumnLayout" => :column_layout,
        "GridLayout" => :grid_layout, "StackLayout" => :stack_layout,
        "LayoutItemProxy" => :layout_item_proxy
      }.freeze

      PERMISSIONS = {
        "BluetoothPermission" => :bluetooth_permission,
        "CalendarPermission" => :calendar_permission,
        "CameraPermission" => :camera_permission,
        "ContactsPermission" => :contacts_permission,
        "LocationPermission" => :location_permission,
        "MicrophonePermission" => :microphone_permission
      }.freeze

      DEVICE_INFORMATION = {
        "SystemInformation" => :system_info,
        "NetworkInformation" => :network_status
      }.freeze

      VIRTUAL_KEYBOARD = {
        "InputPanel" => :virtual_keyboard,
        "HandwritingInputPanel" => :handwriting_input,
        "InputContext" => :keyboard_context,
        "VirtualKeyboardSettings" => :keyboard_settings,
        "EnterKeyAction" => :keyboard_text_field,
        "VirtualKeyboard" => :keyboard_context
      }.freeze

      SENSORS = {
        "Accelerometer" => :accelerometer,
        "AmbientLightSensor" => :ambient_light_sensor,
        "AmbientTemperatureSensor" => :ambient_temperature_sensor,
        "Compass" => :compass,
        "Gyroscope" => :gyroscope,
        "HumiditySensor" => :humidity_sensor,
        "IRProximitySensor" => :ir_proximity_sensor,
        "LidSensor" => :lid_sensor,
        "LightSensor" => :light_sensor,
        "Magnetometer" => :magnetometer,
        "OrientationSensor" => :orientation_sensor,
        "PressureSensor" => :pressure_sensor,
        "ProximitySensor" => :proximity_sensor,
        "RotationSensor" => :rotation_sensor,
        "TapSensor" => :tap_sensor,
        "TiltSensor" => :tilt_sensor
      }.freeze

      POSITIONING = {
        "PositionSource" => :position_source,
        "SatelliteSource" => :satellite_source
      }.freeze

      LOCATION = {
        "Map" => :map, "MapView" => :map, "MapCircle" => :map_circle,
        "MapRectangle" => :map_rectangle, "MapPolygon" => :map_polygon,
        "MapPolyline" => :map_polyline, "MapRoute" => :map_route,
        "MapQuickItem" => :map_marker, "MapItemGroup" => :map_item_group,
        "MapItemView" => :map_item_view, "Plugin" => :map,
        "PluginParameter" => :map, "GeocodeModel" => :geocode_model,
        "RouteModel" => :route_model, "RouteQuery" => :route_model,
        "MapCopyrightNotice" => :map_copyright, "GeoJsonData" => :geo_json_data,
        "PlaceSearchModel" => :place_search,
        "PlaceSearchSuggestionModel" => :place_suggestions,
        "CategoryModel" => :place_categories, "Place" => :place_details,
        "Category" => :place_category
      }.freeze

      TEXT_TO_SPEECH = {
        "TextToSpeech" => :text_to_speech,
        "VoiceSelector" => :text_to_speech
      }.freeze

      WEB = { "WebView" => :web_view }.freeze
      WEB_SOCKETS = { "WebSocket" => :web_socket, "WebSocketServer" => :web_socket_server }.freeze
      LOTTIE = { "LottieAnimation" => :lottie_animation }.freeze
      PDF = %w[PdfDocument PdfMultiPageView PdfPageView PdfScrollablePageView PdfPageImage
               PdfPageNavigator PdfSearchModel PdfSelection].to_h { |name| [name, :pdf_view] }.freeze

      TOUCH_INTERACTION = {
        "TapHandler" => :tap_area, "PointHandler" => :point_handler,
        "MultiPointTouchArea" => :multi_touch_area, "WheelHandler" => :wheel_area,
        "DragHandler" => :drag_area, "PinchHandler" => :pinch_area,
        "HoverHandler" => :hover_area, "DropArea" => :drop_area
      }.freeze

      # Qt Quick 3D. The GPU scene graph is a module surface of its own, so
      # every group below keeps one QtQuick3D submodule alive through mobile
      # tree-shaking.
      QUICK3D_SCENE = {
        "View3D" => :view_3d, "Node" => :node_3d, "Model" => :model_3d,
        "Loader3D" => :loader_3d, "Repeater3D" => :repeater_3d
      }.freeze

      # Qt Quick 3D cameras.
      QUICK3D_CAMERAS = {
        "PerspectiveCamera" => :perspective_camera, "OrthographicCamera" => :orthographic_camera,
        "FrustumCamera" => :frustum_camera, "CustomCamera" => :custom_camera
      }.freeze

      # Qt Quick 3D lights.
      QUICK3D_LIGHTS = {
        "DirectionalLight" => :directional_light, "PointLight" => :point_light,
        "SpotLight" => :spot_light
      }.freeze

      # Qt Quick 3D materials.
      QUICK3D_MATERIALS = {
        "PrincipledMaterial" => :principled_material, "DefaultMaterial" => :default_material,
        "SpecularGlossyMaterial" => :specular_glossy_material, "CustomMaterial" => :custom_material
      }.freeze

      # Qt Quick 3D textures.
      QUICK3D_TEXTURES = {
        "Texture" => :texture_3d, "CubeMapTexture" => :cube_map_texture,
        "TextureInput" => :texture_input
      }.freeze

      # Qt Quick 3D scene environment and rendering settings.
      QUICK3D_ENVIRONMENT = {
        "SceneEnvironment" => :scene_environment, "ExtendedSceneEnvironment" => :extended_scene_environment,
        "Fog" => :fog, "DebugSettings" => :debug_settings,
        "Lightmapper" => :lightmapper, "BakedLightmap" => :baked_lightmap,
        "ReflectionProbe" => :reflection_probe, "ResourceLoader" => :resource_loader
      }.freeze

      # Qt Quick 3D skeletal animation and morphing.
      QUICK3D_SKINNING = {
        "Skeleton" => :skeleton_3d, "Joint" => :joint_3d,
        "Skin" => :skin_3d, "MorphTarget" => :morph_target
      }.freeze

      # Qt Quick 3D instanced rendering.
      QUICK3D_INSTANCING = {
        "InstanceList" => :instance_list, "InstanceListEntry" => :instance_list_entry,
        "RandomInstancing" => :random_instancing, "InstanceRange" => :instance_range,
        "FileInstancing" => :file_instancing
      }.freeze

      # Qt Quick 3D custom post-processing effects.
      QUICK3D_CUSTOM_EFFECTS = {
        "Effect" => :effect_3d, "Pass" => :pass_3d,
        "Shader" => :shader_3d, "Buffer" => :buffer_3d,
        "BufferInput" => :buffer_input, "SetUniformValue" => :set_uniform_value
      }.freeze

      # Qt Quick 3D camera controllers and level of detail.
      QUICK3D_HELPER_CONTROLLERS = {
        "OrbitCameraController" => :orbit_camera_controller, "WasdController" => :wasd_controller,
        "LookAtNode" => :look_at_node, "LodManager" => :lod_manager
      }.freeze

      # Qt Quick 3D debug, grid and procedural geometry helpers.
      QUICK3D_HELPERS = {
        "AxisHelper" => :axis_helper, "DebugView" => :debug_view_3d,
        "InfiniteGrid" => :infinite_grid, "GridGeometry" => :grid_geometry,
        "HeightFieldGeometry" => :height_field_geometry, "ProceduralMesh" => :procedural_mesh,
        "ProceduralMeshSubset" => :procedural_mesh_subset, "ProceduralTextureData" => :procedural_texture_data,
        "ProceduralSkyTextureData" => :procedural_sky_texture_data, "InstanceModel" => :instance_model,
        "InstanceRepeater" => :instance_repeater
      }.freeze

      # Qt Quick 3D runtime asset loading.
      QUICK3D_ASSETS = {
        "RuntimeLoader" => :runtime_loader
      }.freeze

      # Qt Quick 3D GPU particles.
      QUICK3D_PARTICLES = {
        "ParticleSystem3D" => :particle_system_3d, "SpriteParticle3D" => :sprite_particle_3d,
        "LineParticle3D" => :line_particle_3d, "ModelParticle3D" => :model_particle_3d,
        "ModelBlendParticle3D" => :model_blend_particle_3d, "SpriteSequence3D" => :sprite_sequence_3d,
        "ParticleEmitter3D" => :particle_emitter_3d, "TrailEmitter3D" => :trail_emitter_3d,
        "EmitBurst3D" => :emit_burst_3d, "DynamicBurst3D" => :dynamic_burst_3d,
        "ParticleShape3D" => :particle_shape_3d, "ParticleModelShape3D" => :particle_model_shape_3d,
        "ParticleCustomShape3D" => :particle_custom_shape_3d, "VectorDirection3D" => :vector_direction_3d,
        "TargetDirection3D" => :target_direction_3d
      }.freeze

      CORE = QUICK_CONTROLS.merge(QUICK_DIALOGS).merge(QUICK_LAYOUTS).freeze
      ALL = CORE.merge(PERMISSIONS).merge(DEVICE_INFORMATION).merge(VIRTUAL_KEYBOARD)
                .merge(SENSORS).merge(POSITIONING).merge(LOCATION)
                .merge(TEXT_TO_SPEECH).merge(WEB).merge(WEB_SOCKETS).merge(LOTTIE)
                .merge(PDF).merge(TOUCH_INTERACTION).merge(QUICK3D_SCENE)
                .merge(QUICK3D_CAMERAS)
                .merge(QUICK3D_LIGHTS)
                .merge(QUICK3D_MATERIALS)
                .merge(QUICK3D_TEXTURES)
                .merge(QUICK3D_ENVIRONMENT)
                .merge(QUICK3D_SKINNING)
                .merge(QUICK3D_INSTANCING)
                .merge(QUICK3D_CUSTOM_EFFECTS)
                .merge(QUICK3D_HELPER_CONTROLLERS)
                .merge(QUICK3D_HELPERS)
                .merge(QUICK3D_ASSETS)
                .merge(QUICK3D_PARTICLES).freeze
    end
  end
end
