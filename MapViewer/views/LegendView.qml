import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.12

import Esri.ArcGISRuntime 100.14

import "../controls" as Controls


ListView {
    id: legendView

    anchors.fill:parent
    footer:Rectangle{
        height:isIphoneX?36 * scaleFactor :16 * scaleFactor
        width:legendView.width
        color:"transparent"
    }

    clip: true

    delegate: LegendDelegate {
        showLegend: true
        width:legendView.width
    }

    section {
        property: "layerHeaderName"//"displayName"
        delegate:
            ColumnLayout{
            width: parent.width

            Item{
                Layout.fillWidth: true
                Layout.preferredHeight: legendLyrName.height


                Label {
                    id:legendLyrName
                    property string fontNameFallbacks: "Helvetica,Avenir"
                    leftPadding: units(16)
                    rightPadding: leftPadding
                    topPadding:units(16)
                    bottomPadding:units(16)
                    horizontalAlignment: Qt.AlignLeft
                    width: parent.width
                    text: section
                    font.pointSize: 12
                    font {
                        pointSize: getAppProperty (app.baseFontSize, 14)
                        family: "%1,%2".arg(baseFontFamily).arg(fontNameFallbacks)
                    }
                    //font.family: titleFontFamily

                    wrapMode: Label.Wrap
                    clip: true
                    color: getAppProperty(app.baseTextColor, Qt.darker("#F7F8F8"))
                }
            }


        }
    }

    Controls.BaseText {
        id: message

        visible: model.count <= 0 && text > ""
        maximumLineCount: 5
        elide: Text.ElideRight
        width: parent.width
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: qsTr("There are no legends to show.")
    }

    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }
}
