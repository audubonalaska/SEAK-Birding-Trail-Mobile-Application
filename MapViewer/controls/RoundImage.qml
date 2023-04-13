import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0


Item {
    property real radius

    property alias imageSource: image.source
    property alias fillMode: image.fillMode
    property alias mipmap: image.mipmap
    property alias imageStatus: image.status

    property color backgroundColor: "transparent"

    Image {
        id: image
        anchors.fill: parent
        visible: false
        mipmap: true

        Rectangle {
            anchors.fill: parent
            color: backgroundColor
            radius: imageMask.radius
            smooth: true
        }
        onStatusChanged: {
            if (status === Image.Error)
                imageSource = "";
        }
    }

    Rectangle {
        id: imageMask
        anchors.centerIn: parent
        radius: parent.radius
        width: image.width
        height: image.height
        visible: false
    }

    OpacityMask {
        anchors.fill: image
        source: image
        maskSource: imageMask
        cached: true
    }
}
