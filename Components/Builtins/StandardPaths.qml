import QtQuick
import QtCore as Core

Item {
  id: pathsRoot
  property var renderer: null
  property string handledRequestKey: ""

  function locationType() {
    var name = String(renderer ? renderer.prop("location", "home") : "home")
    var values = {
      desktop: Core.StandardPaths.DesktopLocation, documents: Core.StandardPaths.DocumentsLocation,
      fonts: Core.StandardPaths.FontsLocation, applications: Core.StandardPaths.ApplicationsLocation,
      music: Core.StandardPaths.MusicLocation, movies: Core.StandardPaths.MoviesLocation,
      pictures: Core.StandardPaths.PicturesLocation, temp: Core.StandardPaths.TempLocation,
      home: Core.StandardPaths.HomeLocation, cache: Core.StandardPaths.CacheLocation,
      generic_data: Core.StandardPaths.GenericDataLocation, runtime: Core.StandardPaths.RuntimeLocation,
      config: Core.StandardPaths.ConfigLocation, download: Core.StandardPaths.DownloadLocation,
      generic_cache: Core.StandardPaths.GenericCacheLocation,
      generic_config: Core.StandardPaths.GenericConfigLocation,
      app_data: Core.StandardPaths.AppDataLocation, app_config: Core.StandardPaths.AppConfigLocation
    }
    return values[name] === undefined ? Core.StandardPaths.HomeLocation : values[name]
  }

  function requestKey() {
    if (!renderer) return ""
    return [String(renderer.prop("location", "home")), String(renderer.prop("locate_file", "")),
      String(renderer.prop("executable", "")), Number(renderer.prop("refresh_revision", 0))].join("\u001f")
  }

  function resolve() {
    if (!renderer) return
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key
    var type = locationType()
    var payload = {
      location: String(Core.StandardPaths.writableLocation(type)),
      locations: Core.StandardPaths.standardLocations(type).map(String),
      display_name: Core.StandardPaths.displayName(type)
    }
    var file = String(renderer.prop("locate_file", ""))
    if (file !== "") payload.located = String(Core.StandardPaths.locate(type, file))
    var executable = String(renderer.prop("executable", ""))
    if (executable !== "") payload.executable = String(Core.StandardPaths.findExecutable(executable))
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "resolved", payload)
  }

  Component.onCompleted: resolve()
  Connections { target: renderer; function onNodeChanged() { pathsRoot.resolve() } }
}
