import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

RoundButton {
    id: roundedButton

    property bool chosen: false
    property url imageSource: ""
    property color overlayColor: app.subTitleTextColor
    property alias imageScale: roundedButtonImage.scale


    background: Rectangle{
        anchors.fill: parent
        color: chosen ? "#d3d3d3":"white" //"#424242"
        radius: parent.width/2
    }

    indicator: Item{
        anchors.fill: parent

        Image {
            id: roundedButtonImage
            width: parent.width * imageScale//0.6
            height: parent.height  * imageScale//0.6
            anchors.centerIn: parent
            source: imageSource
            fillMode: Image.PreserveAspectFit
            mipmap: true
            opacity: roundedButton.enabled? 1.0 : 0.6
        }

        ColorOverlay {

            anchors.fill: roundedButtonImage
            source: roundedButtonImage
            color: overlayColor
            smooth: true
            antialiasing: true
        }
    }


}

