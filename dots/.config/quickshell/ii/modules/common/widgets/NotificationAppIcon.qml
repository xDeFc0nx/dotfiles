import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

MaterialShape { // App icon
    id: root
    property var appIcon: ""
    property var summary: ""
    property var urgency: NotificationUrgency.Normal
    property bool isUrgent: urgency === NotificationUrgency.Critical
    property var image: ""
    property bool imageFailed: false
    property real materialIconScale: 0.57
    property real appIconScale: 0.8
    property real smallAppIconScale: 0.49
    property real materialIconSize: implicitSize * materialIconScale
    property real appIconSize: implicitSize * appIconScale
    property real smallAppIconSize: implicitSize * smallAppIconScale

    implicitSize: 38 * scale
    property list<var> urgentShapes: [
        MaterialShape.Shape.VerySunny,
        MaterialShape.Shape.SoftBurst,
    ]
    shape: isUrgent ? urgentShapes[Math.floor(Math.random() * urgentShapes.length)] : MaterialShape.Shape.Circle

    color: isUrgent ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer

    // Sender-provided images can be stale (an image://qsimage handle dies with the shell
    // process) or simply unreadable, so a failed load must degrade to the app icon or the
    // material symbol rather than leaving the tile empty.
    readonly property bool hasImage: root.imageSource !== "" && !root.imageFailed
    readonly property string imageSource: {
        const url = root.image ? String(root.image) : "";
        if (!url.startsWith("image://icon/"))
            return url;
        // Quickshell turns a sender icon name into image://icon/<name>. When the theme cannot
        // resolve that name the provider answers with its black/magenta placeholder pixmap,
        // which loads successfully and cannot be detected as an error, so validate it here the
        // same way the provider does.
        const target = url.slice("image://icon/".length).split("?")[0];
        if (target.startsWith("/"))
            return url;
        return Quickshell.iconPath(target, true);
    }
    readonly property string appIconSource: {
        const icon = root.appIcon ? String(root.appIcon) : "";
        if (icon.length === 0)
            return "";
        if (/^[a-z][a-z0-9+.-]*:\/\//i.test(icon) || icon.startsWith("/"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }
    onImageChanged: root.imageFailed = false

    Loader {
        id: materialSymbolLoader
        active: !root.hasImage && root.appIconSource === ""
        anchors.fill: parent
        sourceComponent: MaterialSymbol {
            text: {
                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(root.summary)
                return (root.urgency == NotificationUrgency.Critical && guessedIcon === defaultIcon) ?
                    "priority_high" : guessedIcon
            }
            anchors.fill: parent
            color: isUrgent ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
            iconSize: root.materialIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    Loader {
        id: appIconLoader
        active: !root.hasImage && root.appIconSource !== ""
        anchors.centerIn: parent
        sourceComponent: IconImage {
            id: appIconImage
            implicitSize: root.appIconSize
            asynchronous: true
            source: root.appIconSource
        }
    }
    Loader {
        id: notifImageLoader
        active: root.hasImage
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            Connections {
                target: notifImage
                function onStatusChanged() {
                    if (notifImage.status === Image.Error)
                        root.imageFailed = true;
                }
            }
            StyledImage {
                id: notifImage
                anchors.fill: parent
                readonly property int size: parent.width

                source: root.imageSource
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                asynchronous: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: notifImage.size
                        height: notifImage.size
                        radius: Appearance.rounding.full
                    }
                }
            }
            Loader {
                id: notifImageAppIconLoader
                active: root.appIconSource !== ""
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: IconImage {
                    implicitSize: root.smallAppIconSize
                    asynchronous: true
                    source: root.appIconSource
                }
            }
        }
    }
}