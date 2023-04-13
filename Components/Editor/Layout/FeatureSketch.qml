import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
import "../../../MapViewer/controls" as Controls
import "../../../Components"



Item {
    id: featureSketch
    visible: opacity > 0
    opacity: isShown ? 1 : 0
    anchors.fill: parent

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }

    property bool isShown: false
    property bool isPanMode:false
    signal exitShapeEditMode(var action)

    Item {
        x: (parent.width - width) / 2
        y: 16 * scaleFactor
        width:parent.width //topRowLayout.width
        height: 56 * scaleFactor

        MouseArea {
            anchors.fill: parent
            preventStealing: true
        }

        RowLayout {
            id: topRowLayout
            height: parent.height
            width:parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            LayoutMirroring.enabled:isRightToLeft
            LayoutMirroring.childrenInherit: isRightToLeft

            Item {
                Layout.preferredWidth: 16 * scaleFactor
                Layout.fillHeight: true
            }

            Rectangle{
                Layout.preferredWidth: 56 * app.scaleFactor
                Layout.preferredHeight: 56 * scaleFactor
                radius:height/2
                visible:!isPanMode


                Controls.Icon {
                    anchors.fill:parent
                    imageSource: "../../../MapViewer/images/close.png"
                    maskColor:!isPanMode  ?app.darkIconMask :Qt.lighter(app.darkIconMask, 2.5)
                    /* maskColor:{
                        return app.darkIconMask
                    }*/

                }
                MouseArea{
                    anchors.fill:parent
                    onClicked:{
                        if(!isPanMode)
                        {
                            sketchEditorManager.buttonaction = ""
                            exitShapeEditMode("cancel")
                        }
                        //app.isExpandButtonClicked = false
                    }

                }

            }

            Item {
                Layout.preferredWidth: (parent.width - 4 * 56 * scaleFactor - 32 * scaleFactor)/2 //8 * scaleFactor
                Layout.fillHeight: true
            }

            Rectangle{
                Layout.preferredWidth:112 * app.scaleFactor
                Layout.fillHeight: true
                radius:height/2
                color:!isPanMode ? "white":"transparent"
                // visible:!isPanMode
                RowLayout {
                    height: parent.height
                    width:parent.width
                    spacing:0



                    Controls.Icon {
                        Layout.preferredWidth: 56 * scaleFactor
                        //Layout.fillHeight: true
                        Layout.preferredHeight: 56 * scaleFactor
                        imageSource: "../../../MapViewer/images/undo.png"
                        maskColor:sketchEditorManager.canUndo && enabled ?app.darkIconMask :Qt.lighter(app.darkIconMask, 2.5)
                        visible:!isPanMode
                        onClicked: {
                            if(sketchEditorManager.canUndo && enabled){
                                sketchEditorManager.buttonaction = "undo"
                                sketchEditorManager.addToRedoList(sketchEditor.geometry,null)
                                let _geom = sketchEditorManager.removeFromUndoList()
                                if(_geom){
                                    sketchEditor.replaceGeometry(_geom)
                                    sketchEditorManager.existingGeometry = sketchEditor.geometry
                                }
                            }

                        }
                    }



                    Controls.Icon {
                        Layout.preferredWidth: 56 * scaleFactor
                        Layout.preferredHeight: 56 * scaleFactor
                        visible:!isPanMode
                        imageSource: "../../../MapViewer/images/redo.png"
                        maskColor:sketchEditorManager.canRedo && enabled ?app.darkIconMask :Qt.lighter(app.darkIconMask, 2.5)


                        onClicked: {
                            if(sketchEditorManager.canRedo && enabled)
                            {
                                sketchEditorManager.buttonaction = "redo"
                                sketchEditorManager.addToUndoList(sketchEditor.geometry,null)
                                let _geom = sketchEditorManager.removeFromRedoList()
                                if(_geom){
                                    sketchEditor.replaceGeometry(_geom)
                                    sketchEditorManager.existingGeometry = sketchEditor.geometry
                                }
                                sketchEditorManager.redoListCount -=1
                                sketchEditorManager.undoListCount +=1
                            }

                        }
                    }

                }
            }

            Item {
                Layout.preferredWidth: (parent.width - 4 * 56 * scaleFactor - 32 * scaleFactor)/2 //8 * scaleFactor
                Layout.fillHeight: true
            }
            Rectangle{
                Layout.preferredWidth: 56 * app.scaleFactor
                Layout.preferredHeight: 56 * scaleFactor
                radius:height/2
                // visible:!isPanMode
                color:!isPanMode ? "white":"transparent"


                Controls.Icon {
                    id:deleteIcon
                    anchors.fill:parent
                    visible:!isPanMode
                    imageSource: "../../../MapViewer/images/trash.svg"
                    maskColor:sketchEditorManager.canDelete ?app.darkIconMask :Qt.lighter(app.darkIconMask, 2.5)
                    onClicked: {
                        sketchEditorManager.buttonaction = ""

                        if(sketchEditor.selectedVertex)
                            sketchEditor.removeSelectedVertex()

                    }
                }
            }

            Item {
                Layout.preferredWidth: 16 * scaleFactor
                Layout.fillHeight: true
            }

        }

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 1
            verticalOffset: 3 * scaleFactor
            radius: 12 * scaleFactor
            samples: 25
            color: "#25000000"//colors.softShadow
        }
    }

    Item{
        width:parent.width
        height: 42 * scaleFactor
        x: (parent.width - width) / 2
        y: parent.height  - 80

        RowLayout{
            id: bottomRowLayout
            height: parent.height
            anchors.centerIn: parent
            spacing: 0
            LayoutMirroring.enabled:isRightToLeft
            LayoutMirroring.childrenInherit: isRightToLeft


            Rectangle{
                Layout.preferredWidth: 16 * scaleFactor
                Layout.preferredHeight: 40 * scaleFactor
                visible:measurementUnitPanelRect.visible
            }

            Rectangle{
                Layout.preferredHeight: 40 * scaleFactor
                Layout.preferredWidth:16 * scaleFactor
                visible:measurementUnitPanelRect.visible


                Image {
                    id: img
                    width:parent.width
                    height:app.units(24)//parent.height * 0.9//0.6 * units(25)
                    fillMode: Image.PreserveAspectFit
                    source: sketchEditorManager.symbolUrl
                    anchors.top:parent.top
                    //anchors.left:parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: app.units(16)
                    visible:measurementUnitPanelRect.visible
                }

            }

            Rectangle{
                id:measurementUnitPanelRect
                Layout.preferredWidth:measurementUnitPanel.width
                Layout.preferredHeight: 40 * scaleFactor
                Layout.alignment: Qt.AlignVCenter
                visible:measurementUnitPanel._measurementUnit.model.count > 0

                MeasurementUnitPanel{
                    id:measurementUnitPanel
                    maxWidth:featureSketch.width - 32
                    height:parent.height
                    anchors.centerIn: parent
                    _menuBottomMargin: app.units(120)//app.height - measurementUnitPanel.y
                    _menuLeftMargin: -app.units(100)//((app.width - implicitWidth/2))/2
                    selectedIndex:captureType === "Point" ? 0 : sketchEditorManager.selectedmeasurementUnitIndex
                    geometryToMeasure: sketchEditorManager.startedEditing ? (sketchEditorManager._sketchEditor.geometry !== null?sketchEditorManager._sketchEditor.geometry :sketchEditorManager.existingGeometry):sketchEditorManager._sketchEditor.geometry
                    canShowInValidGeometryString:(sketchEditorManager.canUndo || sketchEditorManager.canRedo) && sketchEditor.geometry  && !sketchEditorManager.isSketchValid() && !isInShapeCreateMode

                    onMeasurementUnitChanged: {
                        if(captureType !== "Point")
                            sketchEditorManager.selectedmeasurementUnitIndex = index
                    }
                }

            }

        }
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 1
            verticalOffset: 3 * scaleFactor
            radius: 12 * scaleFactor
            samples: 25
            color: "#25000000"//colors.softShadow
        }
    }

}
