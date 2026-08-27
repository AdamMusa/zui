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

      CORE = QUICK_CONTROLS.merge(QUICK_DIALOGS).merge(QUICK_LAYOUTS).freeze
      ALL = CORE.merge(PERMISSIONS).merge(DEVICE_INFORMATION).merge(SENSORS).merge(POSITIONING).merge(LOCATION)
                .merge(TEXT_TO_SPEECH).merge(WEB).merge(WEB_SOCKETS).merge(LOTTIE)
                .merge(PDF).merge(TOUCH_INTERACTION).freeze
    end
  end
end
