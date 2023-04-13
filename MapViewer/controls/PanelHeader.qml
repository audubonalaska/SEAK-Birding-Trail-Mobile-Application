
import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1
import ArcGIS.AppFramework 1.0


ToolBar {
    id: panelHeader
    property real panelHeaderHeight:app.units(50)
    property color headerBackgroundColor: app.backgroundColor//"#CCCCCC"
    property color backgroundColor: "#FFFFFF"

    property string popupTitle:""

    property bool isFullView:app.isExpandButtonClicked? true:false
    property color titleColor: "#4c4c4c"
    Material.elevation: 0

    signal closeButtonClicked()
    signal backButtonClicked()
    signal collapseFullView()
    signal expandFullView()

    height:  panelHeaderHeight +  app.notchHeight


    width:parent.width

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


                Icon {
                    id: closeBtn

                    imageWidth: visible?app.units(24):0
                    imageHeight: app.units(24)
                    Material.background: root.backgroundColor
                    Material.elevation: 0
                    maskColor:"#4c4c4c"
                    imageSource: "images/close.png"

                    onClicked: {
                        closeButtonClicked()


                    }
                }

                /*Controls.Icon {
                    id: backBtn


                    visible:!closeBtn.visible//true//isInShapeCreateMode //&& !app.isLarge//false && !mapPage.isInShapeEditMode
                    imageWidth: visible?app.units(24):0
                    imageHeight: app.units(24)
                    Material.background: root.backgroundColor
                    Material.elevation: 0

                    maskColor: "#4c4c4c"
                    imageSource: "../../../MapViewer/images/back.png"

                    onClicked: {
                        backButtonClicked()
                        //back()

                    }
                }
                */
                /*Icon {
                            id: cancelBtn

                            visible:isInEditMode && !mapPage.isInShapeEditMode && !backBtn.visible

                            imageWidth: visible?app.units(24):0
                            imageHeight: app.units(24)
                            Material.background: root.backgroundColor
                            Material.elevation: 0
                            //Layout.alignment: Qt.AlignVCenter
                            maskColor: "#4c4c4c"
                            imageSource: "images/back.png"
                            rotation: !app.isRightToLeft ? 0 : 180

                            onClicked: {
                                exitEditModeInProgress = true
                                let pageNumber = identifyBtn.currentlyEditedPageNumber
                                currentPageNumber = pageNumber
                                identifyBtn.currentPageNumber = currentPageNumber
                                root.currentPageNumber = identifyBtn.currentPageNumber

                                isInEditMode = false
                                identifyBtn.currentEditTabIndex = 0
                                tabBar.currentIndex = 0

                                if(app.isExpandButtonClicked)
                                {
                                    panelContent.state = "FULL_VIEW"
                                    intermediateView = true
                                }

                                exitEditModeInProgress = true
                                populateModelAfterEdit()

                            }
                        }*/


                /* Rectangle{
                    color:"transparent"
                    Layout.fillHeight: true
                    Layout.preferredWidth: visible && symbolUrl > "" ? 0.6 * units(40) : 0
                    // visible:!app.isInShapeEditMode


                    Image {
                        id: img
                        //width:0.6 * units(40)
                        width:parent.width
                        height:0.6 * units(40)
                        fillMode: Image.PreserveAspectFit
                        source: symbolUrl
                        anchors.top:parent.top
                        //anchors.left:parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }


                }*/

                BaseText {
                    id: headerText
                    //visible:!mapPage.isInShapeEditMode
                    Layout.fillWidth: true
                    //width:parent.width
                    //height:parent.height
                    font.pixelSize: 15
                    color: titleColor
                    text:popupTitle
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    wrapMode:Text.WordWrap //Text.WrapAnywhere
                    maximumLineCount: 1
                    leftPadding: !app.isRightToLeft ? (app.isLarge?app.units(24):app.units(5)) : 0
                    rightPadding: !app.isRightToLeft ?  0 : (app.isLarge?app.units(24):app.units(5))
                    horizontalAlignment: Label.AlignLeft
                    //anchors.left:img.right
                }


                SpaceFiller { Layout.fillHeight: false }

                Rectangle{
                    id:expandIcon
                    Layout.preferredWidth:app.units(40)//app.units(130)
                    Layout.preferredHeight:parent.height//mapPage.isInShapeEditMode ? 0 : parent.height
                    color:"transparent"
                    // anchors.right:parent.right
                    visible:!isLandscape //!mapPage.isInShapeEditMode

                    RowLayout{
                        anchors.fill:parent
                        spacing:0


                        Rectangle{
                            id:expandrect
                            Layout.preferredWidth:expandBtn.visible? app.units(40):0
                            Layout.fillHeight: true
                            color:"transparent"
                            //visible:expandBtn.visible

                            Icon {
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
                                imageSource: "images/arrowDown.png"


                                onClicked: {

                                    if(isFullView)
                                    {
                                        collapseFullView()
                                        isFullView = false
                                        app.isExpandButtonClicked = false

                                    }
                                    else{
                                        expandFullView()
                                        isFullView = true
                                        app.isExpandButtonClicked = true

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




