import QtQuick
import QtQuick.Pdf

Item {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  function statusName(value){return ["null","loading","ready","unloading","error"][Number(value)]||"unknown"}
  function processCommand(){var revision=Number(renderer.prop("command_revision",0));if(revision===handledCommandRevision)return;var first=handledCommandRevision<0;handledCommandRevision=revision;if(first){var initial=Number(renderer.prop("page",0));if(initial>0)Qt.callLater(function(){nativeView.goToPage(initial)});if(revision<=0)return}var command=String(renderer.prop("command",""));if(command==="next")nativeView.goToPage(Math.min(nativeDocument.pageCount-1,nativeView.currentPage+1));else if(command==="previous")nativeView.goToPage(Math.max(0,nativeView.currentPage-1));else if(command==="page")nativeView.goToPage(Number(renderer.prop("page",0)));else if(command==="back")nativeView.back();else if(command==="forward")nativeView.forward();else if(command==="zoom_in")nativeView.renderScale*=1.2;else if(command==="zoom_out")nativeView.renderScale/=1.2;else if(command==="reset_zoom")nativeView.resetScale();else if(command==="select_all")nativeView.selectAll();else if(command==="copy")nativeView.copySelectionToClipboard()}
  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 720))
  visible: renderer.prop("visible", true) !== false
  PdfDocument {
    id: nativeDocument
    source: String(root.renderer.prop("source", ""))
    password: String(root.renderer.prop("password", ""))
    onStatusChanged: {var name=root.statusName(status);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"status",{value:name,native_status:Number(status),title:title,page_count:pageCount});if(name==="error")renderer.componentError("pdf_load_failed",error,{source:String(source)})}
    onPageCountChanged: renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"page_count",{value:pageCount})
    onPasswordRequired: renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"password_required",{})
  }
  PdfMultiPageView {
    id: nativeView
    anchors.fill: parent
    document: nativeDocument
    renderScale: Number(root.renderer.prop("zoom", 1))
    pageRotation: Number(root.renderer.prop("rotation", 0))
    searchString: String(root.renderer.prop("search", ""))
    onCurrentPageChanged: renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"page_change",{value:currentPage,page_count:nativeDocument.pageCount})
    onSelectedTextChanged: renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"selection",{text:selectedText})
    onSearchStringChanged: renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"search_change",{value:searchString})
  }
  Component.onCompleted: processCommand()
  Connections { target: renderer; function onNodeChanged(){root.processCommand()} }
}
