import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.PanelHero {
  required property var renderer
      title: renderer.escapeAutoText(renderer.prop("title", "")); meta: renderer.escapeAutoText(renderer.prop("meta", "")); detail: renderer.escapeAutoText(renderer.prop("detail", ""))
      iconSize: Number(renderer.prop("icon_size", Style.font.display)); iconOpacity: Number(renderer.prop("icon_opacity", 1))
      metaOpacity: Number(renderer.prop("meta_opacity", 1)); foreground: renderer.prop("foreground", renderer.foreground)
      fontFamily: String(renderer.prop("font_family", renderer.fontFamily))
    }
