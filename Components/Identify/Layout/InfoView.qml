import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1

import "../../../MapViewer/controls" as Controls

Flickable {
    id: infoView

    property string titleText
    property string ownerText
    property string modifiedDateText
    property string snippetText
    property string descriptionText
    property string customDesc
    property string welcomeText: ""
    property real minContentHeight: 0

    clip: true
    contentHeight: content.height + 16 * scaleFactor

    ColumnLayout {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: app.defaultMargin
        }
        spacing: app.baseUnit

        Controls.BaseText {
            id: itemTitle
            text: titleText
            visible: customDesc === "" && titleText > ""
            Layout.alignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            Layout.preferredHeight: visible ? itemTitle.contentHeight : 0
            Layout.fillWidth: true
            font.bold:true
            color:"black"
            font.weight:Font.Black
        }

        Controls.BaseText {
            id: itemOwner
            visible: ownerText > ""
            text: "Owner: "+ ownerText
            Layout.alignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            Layout.preferredHeight: visible ? itemOwner.contentHeight : 0
            Layout.fillWidth: true
            font.weight: Font.Bold
        }

        Controls.BaseText {
            id: itemModifiedDate
            visible: modifiedDateText > ""
            text: "Modified Date: "+ modifiedDateText
            Layout.alignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            Layout.preferredHeight: visible ? itemModifiedDate.contentHeight : 0
            Layout.fillWidth: true
            font.weight: Font.Bold
        }

        Controls.BaseText {
            id: itemWelcomeText
            visible: customDesc === "" && welcomeText > ""
            text: welcomeText
            Layout.alignment: Qt.AlignTop
            horizontalAlignment: Qt.AlignLeft
            Layout.preferredHeight: visible ? itemWelcomeText.contentHeight : 0
            Layout.fillWidth: true
            font.bold:true
            color:"black"
            font.weight:Font.Black
            onLinkActivated: {
                mapViewerCore.openUrlInternally(link)
            }
        }

        Rectangle {
            id: item
            visible: customDesc > ""
            Layout.preferredHeight: visible ? text1.height : 0
            Layout.preferredWidth: parent.width

            Text {
                id: text1
                text: customDesc > "" ? customDesc : ""
                anchors.left: parent.left
                anchors.right: parent.right
                leftPadding: app.units(8)
                horizontalAlignment: Qt.AlignLeft
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                visible: customDesc > ""
                onLinkActivated: mapViewerCore.openUrlInternally(link)
            }
        }      
    }
}
