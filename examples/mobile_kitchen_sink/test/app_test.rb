# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class MobileKitchenSinkTest < Minitest::Test
  def all(node)
    [node] + node.fetch("children", []).flat_map { |child| all(child) }
  end

  def event(id, name = "click", payload = {})
    JSON.generate("v" => Zui::PROTOCOL_VERSION, "type" => "event", "surface" => "main",
                  "id" => id, "event" => name, "seq" => 1, "payload" => payload)
  end

  def test_builds_the_complete_native_mobile_acceptance_surface
    application = MobileKitchenSink.build
    nodes = all(application.tree.fetch("main"))
    ids = nodes.map { |node| node.fetch("id") }

    %w[device_safe_area kitchen_feed camera_permission microphone_permission location_permission
       bluetooth_permission contacts_permission calendar_permission studio_session photo_capture
       audio_recorder recording_player motion_sensor motion_chart tap_test drag_test gps_source
       kitchen_map current_position trust_gauge service_chart speech_service native_keyboard_field
       qt_keyboard welcome_web network_probe system_probe paths_probe settings_probe diagnostic_log
       report_clipboard].each do |id|
      assert_includes ids, id
    end
    assert_equal "responsive_view", nodes.find { |node| node["id"] == "kitchen_feed" }.fetch("type")
    assert_equal "capture_session", nodes.find { |node| node["id"] == "studio_session" }.fetch("type")
  end

  def test_controls_update_permission_media_and_camera_state
    application = MobileKitchenSink.build
    application.start(output: StringIO.new, error: StringIO.new)

    application.receive(event("permission.camera"))
    application.receive(event("camera_toggle"))
    application.receive(event("record_audio"))

    assert_equal 1, application.state.camera_permission_rev
    assert_equal false, application.state.camera_active
    assert_equal true, application.state.audio_input_enabled
    assert_equal "record", application.state.record_command
    assert_equal 1, application.state.record_revision
  ensure
    application&.stop
  end

  def test_motion_events_drive_the_shake_chart
    application = MobileKitchenSink.build
    application.start(output: StringIO.new, error: StringIO.new)
    application.receive(event("motion_sensor", "reading", "x" => 22.0, "y" => 2.0, "z" => 1.0))

    assert_equal 1, application.state.shake_count
    assert_equal 7, application.state.motion_values.length
    assert_operator application.state.motion_magnitude, :>, 20
  ensure
    application&.stop
  end

  def test_platform_overlays_declare_every_protected_capability
    ios = File.read(File.expand_path("../ios/Info.plist.in", __dir__))
    android = File.read(File.expand_path("../android/AndroidManifest.xml", __dir__))

    %w[NSCameraUsageDescription NSMicrophoneUsageDescription NSLocationWhenInUseUsageDescription
       NSBluetoothAlwaysUsageDescription NSContactsUsageDescription NSCalendarsFullAccessUsageDescription
       NSCalendarsUsageDescription].each do |key|
      assert_includes ios, key
    end
    %w[CAMERA RECORD_AUDIO ACCESS_FINE_LOCATION BLUETOOTH_SCAN READ_CONTACTS READ_CALENDAR].each do |permission|
      assert_includes android, "android.permission.#{permission}"
    end
    assert_includes android, 'android:maxSdkVersion="30"'
  end
end
