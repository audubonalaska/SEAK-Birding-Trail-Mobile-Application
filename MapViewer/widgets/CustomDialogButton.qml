import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQml 2.15
import QtQuick.Controls.Material 2.1 as MaterialStyle

import ArcGIS.AppFramework 1.0

Button {
    id: customDialogButton

    property string customText: "default"
    property string primaryColor: "#009688"
    property double parentHeight: 18 * AppFramework.displayScaleFactor

    text: customText

    contentItem: Text {
        text: customDialogButton.text
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? Qt.lighter(app.backgroundColor, 1.2) : primaryColor
        font {
            pixelSize: AppFramework.systemInformation.family === "phone" ? parentHeight * 0.235 : parentHeight * 0.225
            bold: true
        }
    }

    background: Rectangle {
        color: "transparent"
    }
}
