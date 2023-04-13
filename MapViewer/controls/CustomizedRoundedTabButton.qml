import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

TabButton {
    id: tabButton

    property bool highlighted: checked
    //property url imageSource: ""
    property color selectedColor: app.subTitleTextColor

    indicator: Item{
        anchors.fill: parent
        //border.color: Qt.darker(color, 1.1)

        RoundButton {
            width: parent.height  * 0.5
            height: parent.height  * 0.5
            anchors.centerIn: parent

            //Material.background: selectedColor
            background: Rectangle {
                        anchors.fill:parent
                        color: selectedColor
                        width:parent.width
                        height:parent.height
                        border.color: Qt.darker(color, 1.5)
                        border.width: 1
                        radius: parent.height  * 0.5
            }





            //visible: (modelData === canvas.penColor.toString() || colorController.isSelecting)
        }
        MouseArea{
            anchors.fill: parent
            onClicked: {
                checked = true
            }
        }


    }
}

