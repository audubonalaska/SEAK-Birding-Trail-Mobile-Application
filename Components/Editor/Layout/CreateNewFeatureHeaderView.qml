
import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1
import ArcGIS.AppFramework 1.0
import "../../../MapViewer/controls" as Controls

ToolBar {
    id: newFeaturePanelHeader
    property real panelHeaderHeight:app.units(50)
    property color headerBackgroundColor: app.backgroundColor//"#CCCCCC"
    property color backgroundColor: "#FFFFFF"
    property string popupTitle:""
    property string symbolUrl
    property bool isFullView:false
    property color titleColor: "#4c4c4c"
    Material.elevation: 0


    signal backButtonClicked()
    signal collapseFullView()
    signal expandFullView()


    height:  panelHeaderHeight

    width:parent.width
    topPadding:0
    bottomPadding: 0

    Material.background: headerBackgroundColor


    FocusScope {
        width:parent.width
        height:parent.height
        // anchors.fill: parent
        focus: true
        Keys.onReleased: {
            if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                event.accepted = true
                if(!isInEditMode)
                    backButtonPressed()
                else
                {
                    back()

                }

            }
        }


        ColumnLayout {
            anchors {
                fill: parent
                margins: 0
            }

            spacing: 0


            RowLayout {
                id: headerBtns
                spacing: 0
                Layout.fillWidth: true
                Layout.preferredHeight: panelHeaderHeight

                Controls.Icon {
                    id: backBtn

                    imageWidth: app.units(24)
                    imageHeight: app.units(24)
                    Material.background: backgroundColor
                    Material.elevation: 0

                    maskColor: "#4c4c4c"
                    imageSource: "../../../MapViewer/images/back.png"
                    rotation:!app.isRightToLeft ? 0 :180

                    onClicked: {
                        backButtonClicked()
                    }
                }


                Controls.BaseText {
                    id: headerText

                    Layout.fillWidth: true

                    font.pixelSize: 15
                    color: titleColor
                    text:popupTitle
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    wrapMode:Text.WordWrap
                    maximumLineCount: 1
                    leftPadding: !app.isRightToLeft ? (app.isLarge?app.units(24):app.units(5)) : 0
                    rightPadding: !app.isRightToLeft ?  0 : (app.isLarge?app.units(24):app.units(5))
                    horizontalAlignment: Label.AlignLeft

                }


                Controls.SpaceFiller { Layout.fillHeight: false }

              /*  Rectangle{
                    id:expandIcon
                    Layout.preferredWidth:app.units(40)
                    Layout.preferredHeight:parent.height
                    color:"transparent"

                    visible:!isLarge

                    RowLayout{
                        anchors.fill:parent
                        spacing:0


                        Rectangle{
                            id:expandrect
                            Layout.preferredWidth:expandBtn.visible? app.units(40):0
                            Layout.fillHeight: true
                            color:"transparent"

                            Controls.Icon {
                                id: expandBtn
                                visible:true
                                anchors.centerIn: parent
                                imageWidth: app.units(30)
                                imageHeight: app.units(30)

                                Material.elevation: 0
                                maskColor: "#4c4c4c"

                                rotation:isFullView ? 0:180
                                imageSource: "../../../MapViewer/images/arrowDown.png"


                                onClicked: {

                                    if(isFullView)
                                    {
                                        collapseFullView()
                                        isFullView = false


                                    }
                                    else{
                                        expandFullView()
                                        isFullView = true

                                    }
                                }
                            }
                        }

                    }



                }
*/

            }


        }

    }
}

