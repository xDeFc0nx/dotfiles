import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

/**
 * Still-frame preview of a video, for wallpaper selectors. The frame is
 * extracted with ffmpeg and cached in the XDG cache dir, keyed by source path,
 * so it is only rendered once per video. Stays invisible if extraction fails.
 */
Image {
    id: root

    required property string sourcePath
    property bool extractionAttempted: false

    readonly property string cacheUrl: `${Directories.genericCache}/video-wallpaper-thumbnails`
    readonly property string cacheDir: FileUtils.trimFileProtocol(cacheUrl)
    readonly property string thumbnailUrl: {
        if (sourcePath.length === 0) return "";
        const cleanPath = FileUtils.trimFileProtocol(`${Qt.resolvedUrl(sourcePath)}`);
        return `${root.cacheUrl}/${Qt.md5(cleanPath)}.jpg`;
    }
    readonly property string thumbnailPath: thumbnailUrl.length === 0 ? "" : FileUtils.trimFileProtocol(root.thumbnailUrl)

    asynchronous: true
    cache: false
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: 512
    sourceSize.height: 512

    opacity: status === Image.Ready ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    function reload() {
        root.source = "";
        if (root.thumbnailUrl.length === 0) return;
        root.source = root.thumbnailUrl;
    }

    onSourcePathChanged: {
        root.extractionAttempted = false;
        root.reload();
    }
    Component.onCompleted: reload()

    onStatusChanged: {
        if (status === Image.Error && !root.extractionAttempted && !extractProc.running) {
            root.extractionAttempted = true;
            extractProc.running = true;
        }
    }

    Process {
        id: extractProc
        command: ["bash", "-c",
            `mkdir -p '${root.cacheDir}' && ffmpeg -y -loglevel error -i '${root.sourcePath}' -frames:v 1 -vf 'scale=512:-2' '${root.thumbnailPath}'`
        ]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.reload();
        }
    }
}
