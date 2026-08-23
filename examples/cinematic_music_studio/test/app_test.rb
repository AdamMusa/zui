# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "stringio"
require_relative "../app"

class CinematicMusicStudioTest < Minitest::Test
  def all(node)
    [node] + node.fetch("children", []).flat_map { |child| all(child) }
  end

  def event(id, name = "click", payload = {})
    JSON.generate("v" => Zui::PROTOCOL_VERSION, "type" => "event", "surface" => "main",
                  "id" => id, "event" => name, "seq" => 1, "payload" => payload)
  end


  def test_transport_can_seek_and_navigate_the_real_queue
    app = CinematicMusicStudio.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("track_progress", "change", "value" => 14.25))
    assert_equal 14.25, app.state.position
    assert_equal 1, app.state.seek_revision
    app.receive(event("next_track"))
    assert_equal "yo", app.state.track_id
    assert_equal 30, app.state.duration
    assert_equal 0, app.state.position
    app.receive(event("previous_track"))
    assert_equal "residuals", app.state.track_id
    assert_equal 30, app.state.duration
  ensure
    app&.stop
  end

  def test_builds_the_spatial_music_surface
    app = CinematicMusicStudio.build
    nodes = all(app.tree.fetch("main"))
    ids = nodes.map { |node| node["id"] }
    %w[music_player album_cover music_shader track_progress track_queue spectrum_chart open_apple_music master_dialog].each do |id|
      assert_includes ids, id
    end
    shader = nodes.find { |node| node["id"] == "music_shader" }
    assert_equal "wave", shader.dig("props", "shader")
    assert_equal "gradient", shader.dig("children", 0, "type")
    player = nodes.find { |node| node["id"] == "music_player" }
    assert_equal "audio", player.fetch("type")
    assert_match(%r{\Ahttps://audio-ssl\.itunes\.apple\.com/}, player.dig("props", "source"))
    store = nodes.find { |node| node["id"] == "open_apple_music" }
    assert_match(%r{\Ahttps://music\.apple\.com/}, store.dig("props", "url"))
    queue = nodes.find { |node| node["id"] == "track_queue" }
    assert_equal 13, queue.dig("props", "item_padding")
    assert_equal 190, queue.dig("props", "drag_transition_duration")
  end

  def test_native_audio_events_drive_position_duration_and_track_advance
    app = CinematicMusicStudio.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("music_player", "loaded", "duration" => 30_019))
    app.receive(event("music_player", "position", "value" => 12_340, "duration" => 30_019))
    assert_equal true, app.state.audio_ready
    assert_equal 30, app.state.duration
    assert_in_delta 12.34, app.state.position
    app.receive(event("music_player", "end", "duration" => 30_019))
    assert_equal "yo", app.state.track_id
    assert_equal true, app.state.playing
  ensure
    app&.stop
  end

  def test_transport_and_mastering_update_state
    app = CinematicMusicStudio.build
    app.start(output: StringIO.new, error: StringIO.new)
    app.receive(event("play_toggle"))
    app.receive(event("master_track"))
    assert_equal false, app.state.playing
    assert_equal true, app.state.master_dialog
  ensure
    app&.stop
  end
end
