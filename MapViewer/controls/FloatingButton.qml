import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
//import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12

import ArcGIS.AppFramework 1.0


RoundButton {
    id: menuFloatButton
    readonly property real scaleFactor: AppFramework.displayScaleFactor

    width: 68 * scaleFactor
    height: width
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 32 * scaleFactor
    anchors.right: parent.right
    anchors.rightMargin: 6 * scaleFactor

    Material.background: menuFloatButton.checked ? colors.white : app.primaryColor
    radius: width / 2

    contentItem: IconImage {
        anchors.fill: parent
        anchors.margins: 16 * scaleFactor

        source: "../images/add-white-24dp.svg"
        color: menuFloatButton.checked ? colors.black_54 : colors.white

    }

    checkable: !checked ? true : false
    checked: false

}
