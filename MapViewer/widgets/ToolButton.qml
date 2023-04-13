import QtQuick 2.9
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3

import QtQuick.Controls.Material 2.2

import ArcGIS.AppFramework 1.0


ToolButton {
    id: root

    property color color

    property alias source: icon.source
    property alias iconColor: icon.indicatorColor
    property alias iconRotation: icon.rotation

    property real iconSize: 24 * constants.scaleFactor

    indicator: Icon {
        id: icon

        width: iconSize
        height: this.width
        anchors.centerIn: parent
        opacity: root.enabled ? 1 : 0.38
    }
}
