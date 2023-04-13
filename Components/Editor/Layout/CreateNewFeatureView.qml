/*
This is the UI for selecting a type for creating a new feature from map.


*/


import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.3
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import Esri.ArcGISRuntime 100.14

import "../../../MapViewer/controls" as Controls

Page {
    id: createNewFeatureView
    width: parent.width

    height: isInShapeEditMode ? 0 : parent.height
    objectName: "createNewFeature"
    property MapView _mapView:null
    property var _model:null
    property bool isFilterVisible:false
    property string fontNameFallbacks: "Helvetica,Avenir"
    property string rightButtonImage: "../../../MapViewer/images/arrowDown.png"
    property string accentColor: app.accentColor
    property string searchText:""

    signal drawNewSketch(var geometryType,var layerName,var layerId,var subtype)
    signal editGeometry()
    signal updateSketchLayersList(var searchTxt)

    ColumnLayout{
        width:parent.width
        height:parent.height

        Rectangle{
            Layout.fillWidth:true
            Layout.preferredHeight:visible ? 8  * app.scaleFactor : 0
            visible:filterField.visible
        }

        Rectangle{
            id:filterField
            Layout.preferredWidth: parent.width - 24 * app.scaleFactor
            Layout.preferredHeight: visible ? 48 :0
            Layout.alignment: Qt.AlignHCenter
            visible : isFilterVisible
            radius: 10
            color: "#EFEFEF"
            RowLayout{
                width:parent.width
                spacing: 0
                 Controls.Icon {
                    id: searchIcon
                    iconSize: 6 * app.baseUnit

                    imageSource: "../../../MapViewer/images/search.png"
                    checkable: false
                    maskColor: app.subTitleTextColor

                }

                TextField{
                    id:filterTypeField                 
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    placeholderText:strings.kSearch
                    //readOnly: true
                    hoverEnabled: false
                    verticalAlignment: Text.AlignBottom
                    horizontalAlignment: Text.AlignLeft
                    placeholderTextColor: "grey"
                    color:"#2b2b2b"
                    font.pixelSize: 14 * app.scaleFactor
                    font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    Material.accent: "#EFEFEF"
                    focus: false
                    Layout.alignment: Qt.AlignVCenter
                    text:searchText
                    inputMethodHints: Qt.ImhSensitiveData
                    onDisplayTextChanged: {

                        updateSketchLayersList(text)
                    }


                    onVisibleChanged: {
                        //filterTypeField.forceActiveFocus()
                    }

                }


            }
        }

        Rectangle{
            Layout.fillWidth:true
            Layout.preferredHeight:visible ? 8  * app.scaleFactor : 0
            visible:filterField.visible
        }

        Rectangle{
            Layout.fillWidth:true
            Layout.preferredHeight:visible ?1  * app.scaleFactor:0
            color:app.backgroundColor
            visible:filterField.visible
        }

        ListView {
            id: layerListView
            Layout.fillHeight: true
            Layout.fillWidth: true
            //anchors.fill: parent
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: true
            contentHeight:createNewFeatureView.height
            spacing: 0
            clip: true
            visible:!app.isInShapeEditMode
            model: _model// "name":layer.name,"id":layer.layerId,"geometryType":_geometryType,"symbols":symbolItemArray})
            delegate: Item {
                id:layerItem
                width: layerListView.width
                height:  app.isInShapeEditMode ? 0 : layerSubTypesColumn.height
                visible:!app.isInShapeEditMode
                property bool isCollapsed:false
                ColumnLayout {
                    id: layerSubTypesColumn
                    width: parent.width
                    spacing: 12
                    Rectangle{
                        Layout.preferredWidth: parent.width
                        Layout.preferredHeight:layerHeader1.height

                        RowLayout{
                            id:layerHeader1
                            width: parent.width
                            height:layerHeader.height
                            spacing:0

                            ColumnLayout{
                                id:layerHeader
                                Layout.preferredWidth: parent.width - 50 * scaleFactor
                                Rectangle{
                                    Layout.fillWidth:true
                                    Layout.preferredHeight:index > 0 ? 1  * app.scaleFactor:0
                                    color:app.backgroundColor
                                }

                                Rectangle{
                                    Layout.fillWidth:true
                                    Layout.preferredHeight:8  * app.scaleFactor
                                }

                                Item{
                                    Layout.preferredWidth:parent.width - 24 * app.scaleFactor
                                    Layout.preferredHeight: layerNameText.height

                                    Label {
                                        id: layerNameText
                                        elide: Text.ElideRight
                                        width:parent.width
                                        horizontalAlignment: Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        text: modelData.name
                                        font.pixelSize: 14 * app.scaleFactor
                                        font.bold: false
                                        font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                                        color: colors.blk_200
                                        wrapMode: Text.WrapAnywhere
                                        leftPadding: app.defaultMargin
                                        rightPadding: app.defaultMargin
                                    }
                                }

                                Item{
                                    Layout.fillWidth:true
                                    Layout.preferredHeight:2  * app.scaleFactor

                                }

                            }


                        }
                    }
                    Repeater {
                        id: expressionRepeater
                        model: modelData.symbols

                        delegate: Item {
                            id: lyrsubtype
                            Layout.preferredWidth: layerListView.width -  24 * app.scaleFactor
                            Layout.preferredHeight: layerItem.isCollapsed ? 0 : expressColumn.height
                            Layout.alignment: Qt.AlignHCenter
                            visible:layerItem.isCollapsed ? false : true
                            ColumnLayout {
                                id: expressColumn
                                width: parent.width
                                anchors.centerIn: parent
                                spacing: 0
                                Rectangle{
                                    Layout.preferredWidth: parent.width//layerListView.width
                                    Layout.preferredHeight: 40
                                    //color: "#EFEFEF"

                                    RowLayout{
                                        height: parent.height
                                        width: parent.width
                                        Item{
                                            Layout.fillHeight: true
                                            Layout.preferredWidth:14
                                        }


                                        Rectangle{
                                            id:_icon
                                            color:"transparent"
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 0.6 * units(40)
                                            //visible:!app.isInShapeEditMode
                                            Layout.alignment: Qt.AlignVCenter


                                            Image {
                                                id: img
                                                width:parent.width
                                                height:0.6 * units(40)
                                                fillMode: Image.PreserveAspectFit
                                                source: modelData.symbolUrl
                                                anchors.top:parent.top
                                                anchors.verticalCenter: parent.verticalCenter
                                            }


                                        }

                                        Text {
                                            id: text1
                                            text: modelData.name !== undefined && modelData.name > ""? modelData.name :""
                                            //anchors.left: parent.left
                                            //anchors.right: parent.right
                                            leftPadding: app.units(7)

                                            horizontalAlignment: Label.AlignLeft
                                            Layout.alignment: Qt.AlignVCenter || Qt.AlignLeft

                                        }

                                        Item{
                                            Layout.fillHeight: true
                                            Layout.fillWidth: true

                                        }

                                    }

                                    Controls.Ink {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: parent.color = Qt.darker(app.backgroundColor, 1.1)
                                        onExited: parent.color = 'white'

                                        onReleased: {
                                            canShowFooter = true
                                            //isInShapeEditMode = true
                                            sketchEditorManager.symbolUrl = modelData.symbolUrl
                                            //sketchEditorManager.sketchStarted = false
                                            //mapPage.isInShapeEditMode = true
                                            mapPage.isInShapeCreateMode = true
                                            identifyManager.attrListModel.clear()
                                            //editGeometry()
                                            drawNewSketch(modelData.geometryType, modelData.layerName,modelData.layerId,modelData.name)

                                        }
                                    }

                                }
                            }

                        }
                    }

                }
            }
            Controls.BaseText {
                id: message

                visible:!_model ||_model.length === 0
                maximumLineCount: 5
                elide: Text.ElideRight
                width: parent.width
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: strings.no_editable_layers
            }

        }


    }
    Component.onCompleted: {
        if(filterTypeField.focus) filterTypeField.focus = false;
        if(Qt.inputMethod.visible===true) Qt.inputMethod.hide();

    }



}
