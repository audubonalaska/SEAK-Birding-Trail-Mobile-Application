

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1
import ArcGIS.AppFramework 1.0
import "../../../MapViewer/controls" as Controls

ToolBar {
    id: panelIdentifyHeader
    property real panelHeaderHeight:visible?app.units(50):0
    property color headerBackgroundColor: app.backgroundColor//"#CCCCCC"
    property color backgroundColor: "#FFFFFF"
    property bool isCloseButtonVisible:!isInEditMode && !isInShapeEditMode
    property string popupTitle:""
    property string symbolUrl
    property bool isFullView:false
    property color titleColor: "#4c4c4c"
    Material.elevation: 0



    signal closeButtonClicked()
    signal backButtonClicked()
    signal collapseFullView()
    signal expandFullView()
    signal exitEditing()

    visible:isHeaderVisible


    height:  visible?panelHeaderHeight:0

    width:parent.width
    topPadding:0
    bottomPadding: 0

    Material.background: headerBackgroundColor


    FocusScope {
        width:parent.width
        height:parent.height

        focus: true
        Keys.onReleased: {
            if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                event.accepted = true
                if(!isInEditMode)
                    backButtonPressed()
                else
                {
                    back()
                    /* root.currentPageNumber = identifyBtn.currentPageNumber
                    isInEditMode = false
                    identifyBtn.currentEditTabIndex = 0
                    //panelPage.busyIndicator.visible = true
                    if(app.isExpandButtonClicked)
                    {
                        panelContent.state = "FULL_VIEW"
                        intermediateView = true
                    }

                    mapView.identifyProperties.prepareAfterEditFeature()*/
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
                    id: closeBtn
                    visible:isCloseButtonVisible
                    imageWidth: visible?app.units(24):0
                    imageHeight: app.units(24)

                    // anchors.left:parent.left
                    Material.background: root.backgroundColor
                    Material.elevation: 0
                    maskColor:"#4c4c4c"
                    imageSource: "../../../MapViewer/images/close.png"
                    //leftPadding: 0
                    //anchors.leftMargin: app.units(-2)


                    onClicked: {
                        closeButtonClicked()

                        /* hidePanelPage()
                                app.isExpandButtonClicked = false
                                //exitShapeEditMode("cancel")*/
                    }
                }

               Item{
                id:spacer
                 visible:!closeBtn.visible
                 Layout.preferredWidth: visible?app.units(24):0
                 Layout.preferredHeight: parent.height


                }


               /* Controls.Icon {
                    id: backBtn


                    visible:!closeBtn.visible
                    imageWidth: visible?app.units(24):0
                    imageHeight: app.units(24)
                    Material.background: root.backgroundColor
                    Material.elevation: 0

                    maskColor: "#4c4c4c"
                    imageSource: "../../../MapViewer/images/back.png"
                    rotation:!app.isRightToLeft ? 0 :180

                    onClicked: {
                        backButtonClicked()
                        //back()

                    }
                }
*/

                Rectangle{
                    color:"transparent"
                    Layout.fillHeight: true
                    Layout.preferredWidth: visible && symbolUrl > "" ? 0.6 * units(40) : 0

                    Image {
                        id: img

                        width:parent.width
                        height:0.6 * units(40)
                        fillMode: Image.PreserveAspectFit
                        source: symbolUrl
                        anchors.top:parent.top
                        //anchors.left:parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: app.units(16)
                    }

                }

                Controls.BaseText {
                    id: headerText

                    Layout.fillWidth: true

                    font.pixelSize: 15
                    color: titleColor
                    text:popupTitle//root.title > ""?root.title:(popupTitle > ""? popupTitle.trim() :layerName)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    wrapMode:Text.WordWrap //Text.WrapAnywhere
                    maximumLineCount: 1
                    leftPadding: !app.isRightToLeft ? (app.isLarge?app.units(24):app.units(5)) : 0
                    rightPadding: !app.isRightToLeft ?  0 : (app.isLarge?app.units(24):app.units(5))
                    horizontalAlignment: Label.AlignLeft
                    //anchors.left:img.right
                }


                Controls.SpaceFiller { Layout.fillHeight: false }

                Rectangle{
                    id:expandIcon
                    Layout.preferredWidth:app.units(40)
                    Layout.preferredHeight:parent.height
                    color:"transparent"

                    visible:!isLandscape

                    RowLayout{
                        anchors.fill:parent
                        spacing:0


                        Rectangle{
                            id:expandrect
                            Layout.preferredWidth:expandBtn.visible? app.units(40):0
                            Layout.fillHeight: true
                            color:"transparent"
                            //visible:!app.isInEditMode

                            Controls.Icon {
                                id: expandBtn
                                visible:true
                                anchors.centerIn: parent
                                imageWidth: app.units(30)
                                imageHeight: app.units(30)

                                //Material.background: root.backgroundColor
                                Material.elevation: 0
                                maskColor: "#4c4c4c"
                                rotation:isExpandButtonClicked ? 0:180
                                //rotation:isFullView ? 0:180
                                imageSource: "../../../MapViewer/images/arrowDown.png"


                                onClicked: {

                                    if(isFullView || isExpandButtonClicked)
                                    {
                                        collapseFullView()
                                        isFullView = false
                                       isExpandButtonClicked = false

                                    }
                                    else{
                                        expandFullView()
                                        isFullView = true
                                        isExpandButtonClicked = true


                                    }
                                }
                            }
                        }

                    }



                }


            }


        }

    }
}

