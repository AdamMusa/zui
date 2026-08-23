import QtQuick
import QtCore

Item {
  id:pathsRoot;property var renderer:null
  function locationType(){var name=String(renderer?renderer.prop("location","home"):"home");var values={desktop:StandardPaths.DesktopLocation,documents:StandardPaths.DocumentsLocation,fonts:StandardPaths.FontsLocation,applications:StandardPaths.ApplicationsLocation,music:StandardPaths.MusicLocation,movies:StandardPaths.MoviesLocation,pictures:StandardPaths.PicturesLocation,temp:StandardPaths.TempLocation,home:StandardPaths.HomeLocation,cache:StandardPaths.CacheLocation,generic_data:StandardPaths.GenericDataLocation,runtime:StandardPaths.RuntimeLocation,config:StandardPaths.ConfigLocation,download:StandardPaths.DownloadLocation,generic_cache:StandardPaths.GenericCacheLocation,generic_config:StandardPaths.GenericConfigLocation,app_data:StandardPaths.AppDataLocation,app_config:StandardPaths.AppConfigLocation};return values[name]===undefined?StandardPaths.HomeLocation:values[name]}
  function resolve(){if(!renderer)return;var type=locationType();var payload={location:String(StandardPaths.writableLocation(type)),locations:StandardPaths.standardLocations(type).map(String),display_name:StandardPaths.displayName(type)};var file=String(renderer.prop("locate_file",""));if(file!=="")payload.located=String(StandardPaths.locate(type,file));var executable=String(renderer.prop("executable",""));if(executable!=="")payload.executable=String(StandardPaths.findExecutable(executable));renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"resolved",payload)}
  Component.onCompleted:resolve();Connections{target:renderer;function onNodeChanged(){pathsRoot.resolve()}}
}
