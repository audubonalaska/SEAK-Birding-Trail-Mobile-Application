/*
 This footer is to sketch a  feature in map

*/

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls.Material 2.1
import ArcGIS.AppFramework 1.0
import QtGraphicalEffects 1.12

import "../../../MapViewer/controls" as Controls
import "../../../Components"

ToolBar {
    id: panelIdentifyFooter

    height:units(80)//panelHeaderHeight
    width:app.width//parent.width
    Material.elevation: 0
    bottomPadding: app.notchHeight
    Material.background: headerBackgroundColor
    property color headerBackgroundColor: app.backgroundColor
    property real maximumScreenWidth: app.width > 1000 * scaleFactor ? 600 * scaleFactor : 568 * scaleFactor

    signal exitShapeEditMode(var action)
    signal showPopulateFeatureAttributeForm()


    Rectangle{

        width:parent.width
        height:parent.height + app.notchHeight
        color:"transparent"
        RowLayout{
            id:toolRow
            width:Math.min(app.width,372 * scaleFactor)//Math.min(parent.width, app.maximumScreenWidth)
            anchors.centerIn: parent
            //anchors.fill:parent
            spacing:0

            Item{
                Layout.preferredWidth: app.units(20)
                Layout.fillHeight: true

            }

            Rectangle {
                x:app.isRightToLeft ? parent.width - width - 24 * scaleFactor : 24 * scaleFactor
                y: parent.height - height - 24 * scaleFactor
                width: bottomRowLayout.width
                height: 56 * scaleFactor
                color: colors.white
                radius: height / 2
                border.color: "#9D9D9D"
                border.width: 1
                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                }

                RowLayout {
                    id: bottomRowLayout
                    height: parent.height
                    width:112
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    function onSketchIconClicked()
                    {
                        sketchEditorManager.selectedDrawMode = sketchEditorManager._editMode.sketch
                        sketchEditorManager.restartSketchEditor()
                        sketchEditorManager.isSketchValid = sketchEditorManager._sketchEditor.isSketchValid()
                    }


                    Controls.Icon {
                        id:sketchicon
                        Layout.preferredWidth: visible ?56 * scaleFactor : 0
                        Layout.fillHeight: true
                        circleWidth: 56 * scaleFactor
                        checkable:true
                        checked:true
                        visible:!sketchEditicon.visible

                        imageSource:  switch (sketchEditorManager.currentGeometryType) {

                                      case "Point":
                                          return "../../../MapViewer/images/Feature-pointsNP.svg"//sources.sketch_point;

                                      case "Polyline":
                                          return "../../../MapViewer/images/Feature-polylineNP.svg"//sources.sketch_polyline;

                                      case "Polygon":
                                          return "../../../MapViewer/images/Feature-polygonNP.svg"//sources.sketch_polygon;
                                      default:
                                          return "../../../MapViewer/images/pencil2.svg"
                                      }




                        maskColor:{
                            return app.darkIconMask
                        }
                        onCheckedChanged: {

                            panIcon.checked = !sketchicon.checked
                            if(checked && visible)
                            {
                                bottomRowLayout.onSketchIconClicked()
                                sketchEditorManager.canDelete = sketchEditorManager._sketchEditor.selectedVertex !== null
                            }
                        }

                    }

                    Controls.Icon {
                        id:sketchEditicon
                        Layout.preferredWidth: visible ? 56 * scaleFactor : 0
                        Layout.fillHeight: true
                        circleWidth: 56 * scaleFactor
                        checkable:true
                        checked:true
                        visible:!isInShapeCreateMode

                        imageSource:  "../../../MapViewer/images/pencil2.svg"




                        maskColor:{
                            return app.darkIconMask
                        }

                        onCheckedChanged: {
                            panIcon.checked = !sketchEditicon.checked
                            if(checked && visible){
                                bottomRowLayout.onSketchIconClicked()
                                sketchEditorManager.turnOnDelete()
                            }

                        }
                    }

                    Controls.Icon {
                        id:panIcon
                        Layout.preferredWidth: 56 * scaleFactor
                        Layout.fillHeight: true
                        circleWidth: 56 * scaleFactor
                        checkable:true
                        checked:false

                        imageSource: "../../../MapViewer/images/pan2.svg"//sources.pan

                        maskColor:{
                            return app.darkIconMask
                        }

                        onCheckedChanged: {
                            sketchicon.checked = !panIcon.checked
                            sketchEditicon.checked = !panIcon.checked
                            if(checked){
                                sketchEditorManager.selectedDrawMode = sketchEditorManager._editMode.pan
                                canDeleteSketchVertex = false
                                sketchEditorManager.pauseSketchEditor()
                                sketchEditorManager.turnOffDelete()
                                sketchEditor.selectedVertex = null
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


            Item{
                Layout.preferredWidth: app.units(20)
                Layout.fillHeight: true

            }

            Button {
                id:createBtn
                text: isInShapeCreateMode ? strings.done :strings.update
                Material.foreground: "white"
                enabled:!panIcon.checked && sketchEditorManager.isSketchValid

                background: Rectangle {
                    implicitWidth: 200
                    implicitHeight: app.units(40)
                    color: enabled ? (createBtn.pressed ? Qt.lighter(app.primaryColor) : app.primaryColor):"#9D9D9D"
                    radius: 4
                }

                onClicked:{
                    sketchEditorManager.isSketchValid = sketchEditorManager._sketchEditor.isSketchValid()
                    if(sketchEditorManager.isSketchValid)
                    {
                        if(sketchEditorManager.selectedDrawMode !== sketchEditorManager._editMode.pan)
                        {
                            if(!isInShapeCreateMode)
                                sketchComplete()
                            else
                            {
                                showPopulateFeatureAttributeForm()
                            }
                        }
                    }
                    else
                    {
                        app.messageDialog.width = messageDialog.units(300)
                        app.messageDialog.standardButtons =  Dialog.Ok
                        app.messageDialog.show("",strings.sketch_not_valid)
                    }
                }
            }

            Item{
                Layout.preferredWidth: app.units(20)
                Layout.fillHeight: true
            }
        }

    }

}
