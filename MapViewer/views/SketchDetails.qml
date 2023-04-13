import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0

import QtQuick.Controls.Material 2.2

import ArcGIS.AppFramework 1.0

import "../controls"

Item {
//    property var rowheight
//    property var rowwidth
   id:sketchcontroller


    RowLayout{
        id:tabDetailsScreen
        height:parent.height
        width:parent.width//Math.min(app.units(568), app.width)/2
        //leftMargin: 16



        //--------------------------------------------------------------------------
        Rectangle{
            id: colorController

            Layout.preferredWidth: parent.width//(parent.width - settingsContent.width)/2
            Layout.preferredHeight: parent.height * 0.55//40*AppFramework.displayScaleFactor
            //anchors.bottom: parent.bottom
            //anchors.bottomMargin: 4*AppFramework.displayScaleFactor
            visible: addColorBtn.checked
            color: "white"

            RowLayout{
                anchors.fill:parent
                //height: parent.height
                //width:parent.width




                ListView {
                    id: colorPicker


                    //spacing: app.baseUnit
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    orientation: Qt.Horizontal
                    currentIndex: 0


                    onCurrentIndexChanged: {
                        if (currentIndex >= 0) {
                            colorObject = colorModel.get(currentIndex)
                        } else {
                            colorObject = {"colorName": "#FF0000", "alpha": "#59FF0000"}
                        }
                        sketchPanel.selectedColorIndex = currentIndex
                        canvas.penColor = colorObject.colorName


                        if(addTextBtn.checked) {
                            canvas.textInputColor = colorObject.colorName
                        }
                    }

                    model: ListModel {
                        id: colorModel

                        ListElement {
                            colorName: "#FF0000"
                            alpha: "#59FF0000"
                            isChecked:true
                        }
                        ListElement {
                            colorName: "#F89927"
                            alpha: "#59F89927"
                            isChecked:false
                        }

                        ListElement {
                            colorName: "#FFFF00"
                            alpha: "#59FFFF00"
                            isChecked:false
                        }
                        ListElement {
                            colorName: "#00FF00"
                            alpha: "#5900FF00"
                            isChecked:false
                        }
                        ListElement {
                            colorName: "#0000FF"
                            alpha: "#590000FF"
                            isChecked:false
                        }
                        ListElement {
                            colorName: "#7F00FF"
                            alpha: "#597F00FF"
                            isChecked:false
                        }
                    }

                    delegate: RadioDelegate {
                        id: radioButton
                        //padding: 0
                        leftPadding: app.baseUnit + 10//app.baseUnit/2
                        rightPadding: app.baseUnit + 10//app.baseUnit/2
                        height: 0.9 * parent.height
                        width: (colorController.width - app.defaultMargin)/colorPicker.model.count //(settingsContent.width - 2*app.defaultMargin)/(colorPicker.model.count)

                        indicator: Rectangle {

                            anchors.centerIn: parent
                            height: parent.height //- app.baseUnit/2
                            width: height
                            radius: height/2
                            color: colorName
                            border.color: Qt.darker(color, 1.1)

                            Image {
                                id: image
                                visible:index === colorPicker.currentIndex//radioButton.checked //|| isChecked
                                width: 0.8 * parent.width
                                height: width
                                anchors.centerIn: parent
                                source: "../images/check.png"
                            }

                            ColorOverlay {
                                id: mask

                                visible: image.visible
                                color: colorName === "#FFFF00" ? app.darkIconMask : "white"
                                anchors.fill: image
                                source: image
                            }
                        }


                        onCheckedChanged: {
                            colorPicker.currentIndex = index
                            var colorObject = colorModel.get(index)
                            sketchPanel.selectedColor = colorObject.colorName
                            canvas.textInputColor = colorObject.colorName
                            updateIndex(index)
                            //canvas.removeTextFocus()
                        }


                        Component.onCompleted: {
                            checked = isChecked
                        }
                    }
                }


            }
        }

        // text

        Rectangle {
            id: textController

            Layout.preferredWidth:parent.width //(parent.width - settingsContent.width)/2
            Layout.preferredHeight: parent.height * 0.55//40*AppFramework.displayScaleFactor
            //anchors.bottom: parent.bottom
            //anchors.bottomMargin: 4*AppFramework.displayScaleFactor
            visible: addTextBtn.checked
            color: "white"
            RowLayout{
                height: parent.height
                width:parent.width
                spacing: 0
               // height: parent.height
                //anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    Layout.preferredWidth: 8 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    //Material.background: "#424242"
                    chosen: canvas.textScale === 1.0

                    imageSource: "../images/ic_title_white_48dp.png"
                    imageScale: 0.5

                    onClicked: {
                        canvas.textScale = 1.0;
                    }
                }

                Item {
                    Layout.preferredWidth: 24 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.textScale === 1.5
                    imageScale: 0.65

                    imageSource: "../images/ic_title_white_48dp.png"

                    onClicked: {
                        canvas.textScale = 1.5;
                    }
                }

                Item {
                    Layout.preferredWidth: 24 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.textScale === 2.0

                    imageSource: "../images/ic_title_white_48dp.png"
                    imageScale: 0.9

                    onClicked: {
                        canvas.textScale = 2.0;
                    }
                }

                Item {
                    Layout.preferredHeight: parent.height
                    Layout.fillWidth: true
                }
            }
        }

        //--------------------------------------------------------------------------

        // line
        Rectangle {
            id: lineController

            Layout.preferredWidth: parent.width//(parent.width - settingsContent.width)/2
            Layout.preferredHeight: parent.height * 0.55//40*AppFramework.displayScaleFactor
            //anchors.bottom: parent.bottom
            //anchors.bottomMargin: 4*AppFramework.displayScaleFactor
            visible: drawLineBtn.checked
            color: "white"
            RowLayout{
                height: parent.height
                spacing: 0
                //anchors.horizontalCenter: parent.horizontalCenter
                Item {
                    Layout.preferredWidth: 8 * scaleFactor
                }

                width:parent.width
                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    //Material.background: "#424242"
                    chosen: canvas.selectedLinePenWidth === 1//canvas.penWidth === 1.0

                    imageSource: "../images/curve_1.png"

                    onClicked: {
                        canvas.penWidth = 1.0;
                        canvas.selectedLinePenWidth = 1
                    }
                }

                Item {
                    Layout.preferredWidth: 24 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.selectedLinePenWidth === 3//canvas.penWidth === 3.0

                    imageSource: "../images/curve_3.png"

                    onClicked: {
                        canvas.penWidth = 3.0;
                        canvas.selectedLinePenWidth = 3
                    }
                }

                Item {
                    Layout.preferredWidth: 24 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.selectedLinePenWidth === 5//canvas.penWidth === 5.0

                    imageSource: "../images/curve_5.png"

                    onClicked: {
                        canvas.penWidth = 5.0;
                        canvas.selectedLinePenWidth = 5
                    }
                }

                Item {
                    Layout.preferredWidth: 24 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.selectedLinePenWidth === 10//canvas.penWidth === 10.0

                    imageSource: "../images/curve_10.png"

                    onClicked: {
                        canvas.penWidth = 10.0;
                        canvas.selectedLinePenWidth = 10
                    }
                }

                Item {
                   Layout.fillWidth: true
                   Layout.preferredHeight: parent.height
                }
            }
        }

        //--------------------------------------------------------------------------


        // arrow
        Rectangle {
            id: arrowController

            Layout.preferredWidth: parent.width//(parent.width - settingsContent.width)/2
            Layout.preferredHeight: parent.height * 0.55//40*AppFramework.displayScaleFactor
            //anchors.bottom: parent.bottom
            //anchors.bottomMargin: 4*AppFramework.displayScaleFactor
            visible: drawArrowBtn.checked
            color: "white"

            RowLayout{
                height: parent.height
                //anchors.horizontalCenter: parent.horizontalCenter
                width:parent.width
                spacing: 0

                Item {
                    Layout.preferredWidth: 8 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    //Material.background: "#424242"
                    chosen: canvas.selectedArrowPenWidth === 3//canvas.penWidth === 1.0

                    imageSource: "../images/NewArrow1.png"

                    onClicked: {
                        canvas.penWidth = 3.0;
                        canvas.textMode = false
                        canvas.selectedArrowPenWidth = 3
                    }
                }

                Item {
                    Layout.preferredWidth: 24 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    //Material.background: "#424242"
                    chosen: canvas.selectedArrowPenWidth === 3.1//canvas.penWidth === 3.0

                    imageSource: "../images/NewArrow2.png"

                    onClicked: {
                        canvas.penWidth = 3.0;
                        canvas.textMode = true
                        canvas.selectedArrowPenWidth = 3.1
                    }
                }

                Item {
                    Layout.preferredWidth: 24 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    //Material.background: "#424242"
                    chosen: canvas.selectedArrowPenWidth === 5//canvas.penWidth === 5.0

                    imageSource: "../images/NewArrow3.png"

                    onClicked: {
                        canvas.penWidth = 5.0;
                        canvas.textMode = false
                        canvas.selectedArrowPenWidth = 5
                    }
                }

                Item {
                    Layout.preferredWidth: 24 * scaleFactor
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    //Material.background: "#424242"
                    chosen: canvas.selectedArrowPenWidth === 5.1//canvas.penWidth === 10.0

                    imageSource: "../images/NewArrow4.png"

                    onClicked: {
                        canvas.penWidth = 5.0;
                        canvas.textMode = true
                        canvas.selectedArrowPenWidth = 5.1
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height
                }
            }
        }

    }

   function updateIndex(indx)
   {
       colorPicker.model.setProperty(colorPicker.currentIndex,"isChecked",false)
       colorPicker.currentIndex = indx
       colorPicker.model.setProperty(indx,"isChecked",true)
       //var elem = colorPicker.model.get(indx)
       //elem.isChecked = true
   }

}
