import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
    id: root

    property alias imageColor: colorOverlay.color
    property alias imageRotation: image.rotation

    property string imageSource: ""

    signal clicked()

    Image {
        id: image

        width: parent.width / 2
        height: width
        anchors.centerIn: parent

        source: imageSource
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectFit
        mipmap: true

        onStatusChanged: {
            if (status === Image.Error)
                source = "";
        }
    }

    ColorOverlay {
        id: colorOverlay

        anchors.fill: image

        source: image
        rotation: image.rotation
    }

    RippleMouseArea {
        enabled: parent.enabled
        hoverEnabled: app.isDesktop

        width: parent.width
        height: width
        anchors.centerIn: parent

        radius: width / 2

        onClicked: {
            root.clicked();
        }
    }
}
