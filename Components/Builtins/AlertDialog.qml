import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.Dialog {
    id: alertRoot

    required property var renderer
    readonly property bool requestedOpen: renderer.prop("opened", false) === true && renderer.prop("visible", true) !== false
    readonly property string severity: String(renderer.prop("severity", "info"))
    readonly property string imageSource: String(renderer.prop("image", renderer.prop("image_source", "")))
    readonly property var buttonNames: normalizedButtonNames()
    readonly property bool centered: renderer.prop("centered", true) !== false
    readonly property bool hasExplicitX: renderer.node && renderer.node.props && renderer.node.props.x !== undefined
    readonly property bool hasExplicitY: renderer.node && renderer.node.props && renderer.node.props.y !== undefined

    function severityIcon() {
        var requested = String(renderer.prop("icon", ""));
        if (requested !== "")
            return requested;

        if (severity === "success")
            return "check";

        if (severity === "warning")
            return "warning";

        if (severity === "error" || severity === "critical")
            return "xmark";

        return "info";
    }

    function severityColor() {
        if (severity === "success")
            return renderer.prop("success_color", renderer.prop("accent", Color.accent));

        if (severity === "warning")
            return renderer.prop("warning_color", "#d8a657");

        if (severity === "error" || severity === "critical")
            return renderer.prop("error_color", Color.urgent);

        return renderer.prop("accent", Color.accent);
    }

    function normalizedButtonNames() {
        var requested = renderer.prop("standard_buttons", ["ok"]);
        var values = Array.isArray(requested) ? requested : [requested];
        return values.map(function(value) {
            return String(value || "").toLowerCase();
        }).filter(function(value) {
            return value !== "";
        });
    }

    function buttonText(name) {
        var labels = renderer.prop("button_labels", {
        });
        if (labels && labels[name] !== undefined)
            return String(labels[name]);

        var names = {
            "ok": "OK",
            "save": "Save",
            "save_all": "Save All",
            "open": "Open",
            "yes": "Yes",
            "yes_to_all": "Yes to All",
            "no": "No",
            "no_to_all": "No to All",
            "abort": "Abort",
            "retry": "Retry",
            "ignore": "Ignore",
            "close": "Close",
            "cancel": "Cancel",
            "discard": "Discard",
            "help": "Help",
            "apply": "Apply",
            "reset": "Reset",
            "restore_defaults": "Restore Defaults"
        };
        return names[name] || name;
    }

    function isPrimaryButton(name) {
        return ["ok", "save", "save_all", "open", "yes", "yes_to_all", "retry", "apply"].indexOf(name) >= 0;
    }

    function activateButton(name) {
        if (name === "apply") {
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "apply", {
            });
        } else if (name === "reset" || name === "restore_defaults") {
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reset", {
            });
        } else if (name === "help") {
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "help", {
            });
        } else if (name === "discard") {
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "discard", {
            });
            close();
        } else if (["no", "no_to_all", "abort", "close", "cancel"].indexOf(name) >= 0) {
            reject();
        } else {
            accept();
        }
    }

    function fillModeValue(value) {
        var mode = String(value || "preserve_aspect_fit");
        if (mode === "stretch")
            return Image.Stretch;

        if (mode === "preserve_aspect_crop" || mode === "crop" || mode === "cover")
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

    function closePolicyValue(value) {
        var names = Array.isArray(value) ? value : [value || "escape"];
        var result = 0;
        for (var index = 0; index < names.length; index++) {
            var name = String(names[index]);
            if (name === "escape")
                result |= QQC.Popup.CloseOnEscape;

            if (name === "outside")
                result |= QQC.Popup.CloseOnPressOutside;

            if (name === "outside_parent")
                result |= QQC.Popup.CloseOnPressOutsideParent;

        }
        return result;
    }

    function syncOpenState() {
        if (requestedOpen === opened)
            return ;

        if (requestedOpen)
            open();
        else
            close();
    }

    title: String(renderer.prop("title", ""))
    standardButtons: QQC.Dialog.NoButton
    parent: QQC.Overlay.overlay
    x: hasExplicitX ? Number(renderer.prop("x", 0)) : (centered && parent ? Math.round((parent.width - width) / 2) : 0)
    y: hasExplicitY ? Number(renderer.prop("y", 0)) : (centered && parent ? Math.round((parent.height - height) / 2) : 0)
    width: Number(renderer.prop("width", 500))
    height: Number(renderer.prop("height", 360))
    modal: renderer.prop("modal", true) !== false
    dim: renderer.prop("dim", modal) !== false
    focus: renderer.prop("focus", true) !== false
    closePolicy: closePolicyValue(renderer.prop("close_policy", "escape"))
    enabled: renderer.prop("enabled", true) !== false
    padding: Number(renderer.prop("padding", Style.spacing.lg))
    font.family: String(renderer.prop("font_family", renderer.fontFamily))
    font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    Component.onCompleted: syncOpenState()
    onRequestedOpenChanged: syncOpenState()
    onAccepted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", {
    })
    onRejected: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {
    })
    onOpened: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open", {
    })
    onClosed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {
    })
    onAboutToShow: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_show", {
    })
    onAboutToHide: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_hide", {
    })
    onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, visible ? "show" : "hide", {
    })
    onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, activeFocus ? "focus" : "blur", {
    })

    background: Rectangle {
        color: renderer.prop("background", Color.background)
        radius: Number(renderer.prop("radius", Style.cornerRadius))
        border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
        border.color: renderer.prop("border_color", "transparent")
    }

    header: Rectangle {
        implicitHeight: alertRoot.title.length > 0 ? Number(renderer.prop("header_height", 48)) : 0
        color: renderer.prop("header_background", renderer.prop("background", Color.background))
        radius: Number(renderer.prop("radius", Style.cornerRadius))

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Number(renderer.prop("padding", Style.spacing.lg))
            anchors.rightMargin: Number(renderer.prop("padding", Style.spacing.lg))
            anchors.verticalCenter: parent.verticalCenter
            text: alertRoot.title
            color: renderer.prop("foreground", renderer.foreground)
            font.family: String(renderer.prop("font_family", renderer.fontFamily))
            font.pixelSize: Number(renderer.prop("title_size", Style.font.body))
            font.bold: true
            elide: Text.ElideRight
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Style.normalBorderWidth
            color: renderer.prop("border_color", Qt.rgba(renderer.foreground.r, renderer.foreground.g, renderer.foreground.b, 0.2))
        }

    }

    contentItem: Column {
        spacing: Number(renderer.prop("spacing", Style.spacing.md))

        Row {
            id: messageRow

            width: parent.width
            height: Math.max(iconFrame.visible ? iconFrame.height : 0, messageText.implicitHeight)
            spacing: Number(renderer.prop("spacing", Style.spacing.md))

            Item {
                id: iconFrame

                width: Number(renderer.prop("icon_size", 32))
                height: width
                visible: renderer.prop("show_icon", true) !== false
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: alertRoot.severityColor()
                }

                Text {
                    anchors.centerIn: parent
                    text: renderer.iconGlyph(alertRoot.severityIcon())
                    color: renderer.prop("icon_foreground", Color.background)
                    font.family: renderer.iconFontFamily
                    font.pixelSize: Math.max(10, parent.width * 0.5)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

            }

            Text {
                id: messageText

                width: Math.max(0, parent.width - (iconFrame.visible ? iconFrame.width + parent.spacing : 0))
                anchors.verticalCenter: parent.verticalCenter
                text: String(renderer.prop("message", ""))
                color: renderer.prop("foreground", renderer.foreground)
                font.family: String(renderer.prop("font_family", renderer.fontFamily))
                font.pixelSize: Number(renderer.prop("message_size", Style.font.heading))
                font.bold: true
                wrapMode: Text.Wrap
            }

        }

        Rectangle {
            id: imageFrame

            width: {
                var requested = Number(renderer.prop("image_width", 0));
                return requested > 0 ? Math.min(parent.width, requested) : parent.width;
            }
            height: Number(renderer.prop("image_height", 160))
            anchors.horizontalCenter: parent.horizontalCenter
            visible: alertRoot.imageSource !== ""
            color: "transparent"
            radius: Number(renderer.prop("image_radius", renderer.prop("radius", Style.cornerRadius)))
            clip: true

            Image {
                anchors.fill: parent
                source: renderer.assetUrl(alertRoot.imageSource)
                fillMode: alertRoot.fillModeValue(renderer.prop("image_fill_mode", "preserve_aspect_fit"))
                asynchronous: renderer.prop("image_asynchronous", true) !== false
                cache: renderer.prop("image_cache", true) !== false
                smooth: true
                onStatusChanged: {
                    if (status === Image.Error)
                        renderer.componentError("alert_dialog_image_failed", "Unable to load the declared alert dialog image", {
                            "source": String(source)
                        });
                }
            }

        }

        Text {
            width: parent.width
            visible: text.length > 0
            text: String(renderer.prop("informative_text", ""))
            color: renderer.prop("muted", Color.muted)
            font.family: String(renderer.prop("font_family", renderer.fontFamily))
            font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
            wrapMode: Text.Wrap
        }

        QQC.ScrollView {
            width: parent.width
            height: Number(renderer.prop("details_height", 120))
            visible: String(renderer.prop("detailed_text", "")).length > 0
            clip: true

            QQC.TextArea {
                text: String(renderer.prop("detailed_text", ""))
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                color: renderer.prop("foreground", renderer.foreground)
                font.family: String(renderer.prop("font_family", renderer.fontFamily))
                font.pixelSize: Number(renderer.prop("details_size", Style.font.caption))
            }

        }

    }

    footer: Rectangle {
        implicitHeight: alertRoot.buttonNames.length > 0 ? Number(renderer.prop("footer_height", 62)) : 0
        color: renderer.prop("footer_background", renderer.prop("background", Color.background))

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Style.normalBorderWidth
            color: renderer.prop("border_color", Qt.rgba(renderer.foreground.r, renderer.foreground.g, renderer.foreground.b, 0.2))
        }

        Row {
            id: buttonRow

            readonly property string alignment: String(renderer.prop("button_alignment", "right"))

            anchors.left: alignment === "left" || alignment === "start" ? parent.left : undefined
            anchors.right: alignment === "right" || alignment === "end" ? parent.right : undefined
            anchors.horizontalCenter: alignment === "center" ? parent.horizontalCenter : undefined
            anchors.leftMargin: Number(renderer.prop("padding", Style.spacing.lg))
            anchors.rightMargin: Number(renderer.prop("padding", Style.spacing.lg))
            anchors.verticalCenter: parent.verticalCenter
            spacing: Number(renderer.prop("button_spacing", Style.spacing.sm))

            Repeater {
                model: alertRoot.buttonNames

                delegate: ZuiControls.Button {
                    required property string modelData
                    readonly property bool primary: alertRoot.isPrimaryButton(modelData)

                    text: alertRoot.buttonText(modelData)
                    iconText: primary && modelData === "ok" ? renderer.iconGlyph("check") : ""
                    foreground: renderer.prop("button_foreground", renderer.prop("foreground", renderer.foreground))
                    background: primary ? renderer.prop("button_background", "transparent") : "transparent"
                    accent: renderer.prop("button_accent", renderer.prop("accent", Color.accent))
                    fontFamily: String(renderer.prop("font_family", renderer.fontFamily))
                    iconFontFamily: renderer.iconFontFamily
                    fontSize: Number(renderer.prop("font_size", Style.font.body))
                    focusable: true
                    bordered: !primary
                    active: primary
                    horizontalPadding: Number(renderer.prop("button_horizontal_padding", Style.spacing.controlPaddingX))
                    verticalPadding: Number(renderer.prop("button_vertical_padding", Style.spacing.controlPaddingY))
                    onClicked: alertRoot.activateButton(modelData)
                }

            }

        }

    }

}
