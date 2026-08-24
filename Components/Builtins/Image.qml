import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Image {
    id: imageRoot

    required property var renderer

    function fillModeValue(value) {
        var mode = String(value || "preserve_aspect_fit");
        if (mode === "stretch")
            return Image.Stretch;

        if (mode === "preserve_aspect_crop" || mode === "crop")
            return Image.PreserveAspectCrop;

        if (mode === "tile")
            return Image.Tile;

        if (mode === "tile_vertically" || mode === "tile_vertical")
            return Image.TileVertically;

        if (mode === "tile_horizontally" || mode === "tile_horizontal")
            return Image.TileHorizontally;

        if (mode === "pad")
            return Image.Pad;

        return Image.PreserveAspectFit;
    }

    function horizontalAlignmentValue(value) {
        var alignment = String(value || "center");
        if (alignment === "left" || alignment === "start")
            return Image.AlignLeft;

        if (alignment === "right" || alignment === "end")
            return Image.AlignRight;

        return Image.AlignHCenter;
    }

    function verticalAlignmentValue(value) {
        var alignment = String(value || "center");
        if (alignment === "top" || alignment === "start")
            return Image.AlignTop;

        if (alignment === "bottom" || alignment === "end")
            return Image.AlignBottom;

        return Image.AlignVCenter;
    }

    function statusName(value) {
        if (value === Image.Ready)
            return "ready";

        if (value === Image.Loading)
            return "loading";

        if (value === Image.Error)
            return "error";

        return "null";
    }

    function send(name, payload) {
        if (renderer.subscribed(name))
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {
        });

    }

    source: renderer.assetUrl(renderer.prop("source", ""))
    width: Number(renderer.prop("width", 120))
    height: Number(renderer.prop("height", 120))
    sourceSize.width: Number(renderer.prop("source_width", -1))
    sourceSize.height: Number(renderer.prop("source_height", -1))
    asynchronous: renderer.prop("asynchronous", true) !== false
    cache: renderer.prop("cache", true) !== false
    smooth: renderer.prop("smooth", true) !== false
    mipmap: renderer.prop("mipmap", false) === true
    mirror: renderer.prop("mirror", false) === true
    autoTransform: renderer.prop("auto_transform", false) === true
    retainWhileLoading: renderer.prop("retain_while_loading", true) !== false
    fillMode: fillModeValue(renderer.prop("fill_mode", "preserve_aspect_fit"))
    horizontalAlignment: horizontalAlignmentValue(renderer.prop("horizontal_alignment", "center"))
    verticalAlignment: verticalAlignmentValue(renderer.prop("vertical_alignment", "center"))
    onProgressChanged: send("progress", {
        "value": imageRoot.progress
    })
    onStatusChanged: {
        var payload = {
            "value": statusName(status),
            "source": String(source),
            "width": implicitWidth,
            "height": implicitHeight
        };
        send("status", payload);
        if (status === Image.Ready)
            send("loaded", payload);
        else if (status === Image.Error)
            renderer.componentError("image_load_failed", "Unable to load the declared image", payload);
    }
}
