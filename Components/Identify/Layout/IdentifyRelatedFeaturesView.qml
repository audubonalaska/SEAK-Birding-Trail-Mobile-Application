import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import Esri.ArcGISRuntime 100.14

import "../../../MapViewer/controls" as Controls

Flickable
{
    width:parent.width//panelPage.width
    height:parent.height - 100 * scaleFactor//panelPage.height - 100 * scaleFactor
    contentWidth: parent.width//panelPage.width
    contentHeight: relatedview.height + 16 * scaleFactor

    id: root1
    property var featureList: ListModel{}
    property var showFeatureClassName:({})
    property var calendarPicker:null
    //property alias relatedattrListModel:identifyManager.relatedattrListModel

    property var servicestate: ({})
    signal showDetailsPage(var relatedDetailsObject)
    clip:true


    ColumnLayout{
        id:relatedview

        width:parent.width//panelPage.width
        spacing:0



        RowLayout{
            spacing:0
            Layout.preferredHeight:0.8 * app.headerHeight
            Controls.BaseText {

                text:qsTr("Items:")
                color: app.black_87

                elide: Text.ElideRight
                textFormat: Text.StyledText
                Material.accent: app.accentColor

                leftPadding: !app.isRightToLeft ? 16 * scaleFactor : 0
                rightPadding:!app.isRightToLeft ? 0 : 16 * scaleFactor
            }
            Controls.BaseText {

                text:featureList.count
                color: app.black_87


                elide: Text.ElideRight
                textFormat: Text.StyledText
                Material.accent: app.accentColor
                Layout.leftMargin: 5 * scaleFactor


            }
        }

        ColumnLayout{
            id:featureFieldsCol
            Layout.preferredWidth:parent.width//panelPage.width

            spacing:44 * scaleFactor



            Repeater{
                id:repeaterFeatureList

                model:featureList //get the list of featureClasses

                Item{
                    Layout.preferredWidth:featureFieldsCol.width//panelPage.width//parent.width
                    Layout.preferredHeight:showInView === true?(Qt.platform.os === "osx"?features.count * 30 * scaleFactor:features.count * 35 * scaleFactor):0
                    Layout.bottomMargin: showInView === true?app.units(10):0
                    ColumnLayout{
                        id:featurelistrows
                        spacing:0
                        width:parent.width
                        Rectangle{
                            Layout.preferredWidth:parent.width
                            Layout.preferredHeight:1
                            color:app.separatorColor


                        }

                        Rectangle{
                            Layout.fillWidth: true

                            Layout.preferredHeight: 0.8 * app.headerHeight
                            color:"#EDEDED"

                            RowLayout{
                                width:parent.width
                                height:parent.height

                                Rectangle{
                                    id:servicename
                                    Layout.preferredWidth: parent.width - expandIcon.width - featurescount.width - 20 * scaleFactor //- layerIcon.width - app.defaultMargin
                                    Layout.preferredHeight:0.8 * app.headerHeight
                                    color:"#EDEDED"


                                    Controls.BaseText {

                                        width:parent.width

                                        text:serviceLayerName
                                        color: app.black_87
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                        textFormat: Text.StyledText
                                        Material.accent: app.accentColor
                                        anchors.verticalCenter: parent.verticalCenter


                                        leftPadding: app.units(16)
                                        rightPadding: leftPadding
                                        horizontalAlignment: Label.AlignLeft

                                    }
                                }


                                Rectangle {
                                    id: featurescount


                                    color:"transparent"

                                    border.color: Qt.darker(app.backgroundColor, 1.9)

                                    Layout.preferredWidth: 0.7 * expandIcon.Layout.preferredWidth
                                    Layout.preferredHeight: Layout.preferredWidth
                                    radius: Layout.preferredWidth
                                    visible:true
                                    Layout.rightMargin: app.units(10)

                                    Controls.BaseText {
                                        text: features.count
                                        anchors.centerIn: parent
                                    }
                                }


                                Controls.Icon {
                                    id: expandIcon
                                    Layout.preferredWidth: app.units(40)
                                    Layout.preferredHeight:app.units(40)
                                    Layout.rightMargin: app.units(10)

                                    maskColor: app.subTitleTextColor
                                    imageSource: "../../../MapViewer/images/arrowDown.png"
                                    rotation:showInView === true? 180:0
                                    visible:!(featureList.count === 1 && features.count === 1)

                                }

                            }


                            Rectangle{
                                width:parent.width
                                height:1
                                color:app.separatorColor
                                anchors.bottom: parent.bottom
                            }

                            MouseArea {

                                anchors.fill: parent
                                onClicked: {
                                    root1.toggle(serviceLayerName)
                                }
                            }

                        }


                        ListView {
                            id: identifyRelatedFeaturesViewlst1
                            Layout.preferredWidth:relatedview.width //parent.width // - 10 * scaleFactor
                            Layout.preferredHeight:root1.height - 1.8 * app.headerHeight - panelHeaderHeight
                            boundsBehavior: Flickable.StopAtBounds

                            property var feature:null
                            property bool canEdit:false


                            model:app.isInEditMode && visible?((typeof editableFeature !== 'undefined')?editableFeature.editFields:null):features.get(0).fields
                            visible:featureList.count === 1 && features.count === 1
                            footer:Rectangle{
                                height:100 * scaleFactor
                                width:identifyRelatedFeaturesViewlst1.width
                                color:"transparent"
                            }


                            clip: true

                            delegate:Item {
                                width: identifyRelatedFeaturesViewlst1.width //- app.units(16)
                                //anchors.right:identifyRelatedFeaturesViewlst1.right

                                height:relatedFeatureControl.height//contentColumn.height
                                Controls.FeatureControl{
                                    id:relatedFeatureControl
                                    width:parent.width
                                    _layerName:serviceLayerName
                                    _editableFeature: typeof editableFeature !== "undefined" ? editableFeature: null

                                    _fieldName:typeof FieldName !== "undefined" ? FieldName : null
                                    _label:typeof label !== "undefined" ? label : null
                                    _domainName:typeof domainName !== "undefined" ? domainName : null
                                    _fieldValue:typeof FieldValue !== "undefined" ? FieldValue : null
                                    _domainCode:typeof domainCode != "undefined" ? domainCode : null
                                    _minValue:typeof minValue !== "undefined" ? minValue : -1
                                    _maxValue:typeof maxValue !== "undefined" ? maxValue : -1
                                    _length:typeof length !== "undefined" ? length:0
                                    _fieldType:typeof fieldType !== "undefined" ? fieldType:null
                                    _nullableValue:typeof nullableValue !== "undefined" ? nullableValue:null
                                    _unformattedValue:typeof unformattedValue !== "undefined" ? unformattedValue:null
                                    _isInEditMode:app.isInEditMode


                                    onSaveDateField: {
                                        attributeEditorManager.saveAttributesRelatedObject(editObject)
                                        //identifyManager.saveAttributesRelatedObject(editObject)

                                    }


                                }


                            }

                        }



                        ColumnLayout{
                            Layout.preferredWidth: parent.width  - 10 * scaleFactor


                            visible: showInView === true && (featureList.count > 1 || featureList.get(0).features.count > 1)
                            Layout.preferredHeight:showInView === true?implicitHeight:0

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: app.units(6)

                            }
                            Repeater{
                                model:features

                                Controls.BaseText {
                                    id:display
                                    Layout.preferredWidth: panelPage.width - 16 * scaleFactor

                                    text:displayFieldName
                                    color:primaryColor
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                    verticalAlignment: Qt.AlignVCenter

                                    textFormat: Text.StyledText
                                    Material.accent: app.accentColor

                                    leftPadding: app.units(20)
                                    rightPadding: leftPadding
                                    bottomPadding: app.units(6)
                                    Layout.bottomMargin: app.units(6)
                                    MouseArea{
                                        anchors.fill: parent
                                        onClicked: {
                                            let _editorinfo = null
                                            if (isEditorTrackingEnabled)
                                                _editorinfo  = editorInfo

                                            let relatedDetailsObject = identifyManager.populateRelatedDetailsObject(serviceLayerName,objectid,isEditorTrackingEnabled,_editorinfo,displayFieldName,fields)
                                            showDetailsPage(relatedDetailsObject)

                                            if(geometry)
                                            {
                                                let relatedFeatures = identifyManager.relatedFeatures[identifyBtn.currentPageNumber-1]
                                                let _feature = identifyManager.getFeatureFromLayer(serviceLayerName,objectid,relatedFeatures)
                                                mapView.identifyProperties.showInMap(_feature ,false)
                                            }



                                        }
                                    }

                                }


                            }


                        }



                    }


                }



            }

            Rectangle{
                Layout.preferredWidth:parent.width
                Layout.preferredHeight:app.units(20)
                color:"transparent"



            }
        }
    }



    function toggle (serviceLayerName) {
        if(servicestate[serviceLayerName]){
            state = servicestate[serviceLayerName]
        }
        else
        {
            servicestate[serviceLayerName] = "NOTEXPANDED"
            state = "NOTEXPANDED"
        }

        state = state === "EXPANDED" ? "NOTEXPANDED" : "EXPANDED"
        if (state === "EXPANDED") {

            root1.expandSection(serviceLayerName, true)
        } else {

            root1.collapseSection(serviceLayerName, false)
        }
        servicestate[serviceLayerName] = state
    }

    function expandSection (serviceLayerName,expand) {

        for (var i=0; i<repeaterFeatureList.model.count; i++) {
            var item = repeaterFeatureList.model.get(i)
            if (item.serviceLayerName === serviceLayerName) {


                item["showInView"] = expand
                repeaterFeatureList.model.set(i,{"showInView":expand})

            }
        }
    }

    function collapseSection (serviceLayerName,expand) {
        for (var i=0; i<repeaterFeatureList.model.count; i++) {
            var item = repeaterFeatureList.model.get(i)
            if (item.serviceLayerName === serviceLayerName) {

                item["showInView"] = expand

                repeaterFeatureList.model.set(i,{"showInView":expand})
            }
        }
    }




}




