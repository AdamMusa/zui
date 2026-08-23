import QtQuick
import "Support" as Support
Support.AnimationGroupDriver { renderer: null; sequential: false; onRendererChanged: if(renderer){renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"start",{from:renderer.prop("from_state",""),to:renderer.prop("to_state","")})} }
