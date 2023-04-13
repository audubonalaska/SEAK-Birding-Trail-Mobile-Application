import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0




Item {
    property alias source: image.source
    property alias color: imageColorOverLay.color
    property alias image: image
    property real padding: 0
    property bool isSVGImage:source.toString() > ""? (source.toString()).split('.')[1].toUpperCase() === "SVG":false


    Image {
        id: image
        anchors.fill: parent
        anchors.margins: parent.padding
        sourceSize: isSVGImage ? Qt.size(width, height) : undefined
        mipmap: true
    }

    ColorOverlay {
        id: imageColorOverLay
        anchors.fill: image
        source: image
    }
}
