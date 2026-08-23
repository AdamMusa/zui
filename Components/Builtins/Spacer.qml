import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import QtMultimedia
import QtQuick.VectorImage
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      implicitWidth: Number(renderer.prop("width", 0))
      implicitHeight: Number(renderer.prop("height", Style.space(8)))
    }
