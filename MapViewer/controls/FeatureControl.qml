import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import "../../Components/Identify/Layout" as EditControls


Pane {
    id: delegateContent
    width: this.visible ? identifyFeaturesView.width : 0
    height:contentColumn.height
    //height: this.visible ? contentItem.height : 0
    padding: 0
    spacing: 0
    clip: true
    property var _layerName
    property var _editableFeature
    property var _fieldName
    property var _label
    property var _domainName
    property var _fieldValue
    property var _domainCode
    property var _minValue
    property var _maxValue
    property var _length
    property var _fieldType
    property var _nullableValue
    property var _unformattedValue
    property var _description
    property var _formattedValue:null
    property bool displayName:false
    property var _currentFeature
    property bool _isInEditMode:false
    property string _fieldValidType:""

    signal saveDateField(var editObject)
    // signal updateField(var editObject)
    signal updateFieldObject(var editObject)
    //signal updateRelatedFieldObject(var editObject)

    signal trigger(var editObject)
    function getEditObject()
    {
        let editObject = {}
        editObject.layerName = _layerName
        editObject.fieldName = _fieldName
        editObject.label = _label
        editObject.fieldValue = _domainName.count > 0? _fieldValue:_unformattedValue
        editObject.originalFieldValue = _domainName.count > 0? _fieldValue:_unformattedValue
        editObject.domainName = _domainName
        editObject.domainCode = _domainCode
        editObject.minValue = _minValue
        editObject.maxValue = _maxValue
        editObject.length = _length
        editObject.fieldType = _fieldType
        editObject.nullableValue = _nullableValue
        editObject.feature = _editableFeature//identifyRelatedFeaturesViewlst1.feature
        editObject.currentFeatureEdited = identifyManager.currentFeature//_currentFeature

        return editObject
    }




    contentItem: Item {
        width: parent.width - app.units(16)
        //anchors.right:parent.right

        height:contentColumn.height

       /* Connections{
            target:delegateContent
            function updateFieldObject(editObject){
                desc.text =  ((typeof _formattedValue !== "undefined" && _formattedValue !== null) ? (_formattedValue ? _formattedValue : " ") : (typeof _fieldValue !== "undefined" ? (_fieldValue ? _fieldValue : " ") : " ")).replace(/(http:\/\/[^\s]+)/gi , '<a href="$1">$1</a>').replace(/(https:\/\/[^\s]+)/gi , '<a href="$1">$1</a>');

            }
        }*/



        Rectangle{
            width:parent.width - app.units(16)
            height:1
            color:app.separatorColor//"#6E6E6E"
            anchors.top:parent.top
            anchors.right:parent.right
            visible:index > 0
        }

        RowLayout{
            width:panelPage.width //- app.units(16)
            height:contentColumn.height -1

            ColumnLayout {
                id: contentColumn
                Layout.preferredWidth:parent.width //- editIcon.width

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: app.units(6)
                }

                Rectangle{
                    id: item
                    Layout.preferredWidth: parent.width - app.units(32)
                    Layout.preferredHeight: text1.height
                    visible:_description > ""
                    Layout.alignment: Qt.AlignCenter

                    Text {
                        id: text1
                        text: _description !== undefined ? _description : ""
                        anchors.left: parent.left
                        anchors.right: parent.right
                        leftPadding: app.units(7)
                        wrapMode: Text.WordWrap
                        textFormat: Text.RichText
                        visible:_description > ""
                        horizontalAlignment: Label.AlignLeft
                        onLinkActivated: Qt.openUrlExternally(link)
                    }

                }


                RowLayout{
                    Layout.fillWidth: true
                    Layout.preferredHeight:lbl.height
                    Layout.leftMargin: app.defaultMargin
                    Layout.rightMargin: app.defaultMargin


                    SubtitleText {
                        id: lbl
                        objectName: "label1"
                        text:!displayName?((typeof _label !== "undefined" && _label !== null) ? _label :  (typeof _fieldName !== "undefined" && _fieldName !== null? _fieldName : "")):(typeof _fieldName !== "undefined" ? (_fieldName ? _fieldName : "") : "")
                        Layout.preferredHeight: implicitHeight
                        elide: Text.ElideMiddle
                        horizontalAlignment: Label.AlignLeft
                        wrapMode: Text.WrapAnywhere
                    }

                    Text{

                        horizontalAlignment: Label.AlignLeft
                        text:"*"
                        color:"red"
                        visible:(_isInEditMode && _nullableValue !== "undefined") ? !_nullableValue : false //&& isInShapeCreateMode

                    }
                    Item{
                        Layout.fillWidth: true
                        Layout.fillHeight:true
                    }
                }

                BaseText {

                    id: desc

                    objectName: "description"
                    Layout.fillWidth: true
                    Layout.preferredHeight: this.implicitHeight
                    Layout.leftMargin: app.defaultMargin
                    Layout.rightMargin: app.defaultMargin
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.StyledText
                    Material.accent: app.accentColor
                    horizontalAlignment: Label.AlignLeft
                     text : ((typeof _fieldValue !== "undefined" ? (_fieldValue ? _fieldValue : " ") : " ")).replace(/(http:\/\/[^\s]+)/gi , '<a href="$1">$1</a>').replace(/(https:\/\/[^\s]+)/gi , '<a href="$1">$1</a>');

                    onLinkActivated: {
                        mapViewerCore.openUrlInternally(link)
                    }



                    Component.onCompleted: {
                       // text = ((typeof _formattedValue !== "undefined" && _formattedValue !== null) ? (_formattedValue ? _formattedValue : " ") : (typeof _fieldValue !== "undefined" ? (_fieldValue ? _fieldValue : " ") : " ")).replace(/(http:\/\/[^\s]+)/gi , '<a href="$1">$1</a>').replace(/(https:\/\/[^\s]+)/gi , '<a href="$1">$1</a>');
                        // text = _fieldValue//(_formattedValue !== null ? _formattedValue : (typeof _fieldValue !== "undefined" ? (_fieldValue ? _fieldValue : " ") : " ")).replace(/(http:\/\/[^\s]+)/gi , '<a href="$1">$1</a>').replace(/(https:\/\/[^\s]+)/gi , '<a href="$1">$1</a>');

                    }

                }

                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight: _fieldValidType !== "undefined" && _fieldValidType > ""? app.units(16) : 0
                    //color:"green"

                    RowLayout {
                        id: errorBtns
                        spacing: 0
                        anchors.fill: parent
                        anchors.leftMargin: app.defaultMargin
                        anchors.rightMargin: app.defaultMargin

                        Rectangle {
                            color: "transparent"
                            visible: errorText.visible
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: app.units(14)
                            Layout.alignment: Qt.AlignVCenter
                            Layout.margins: 0

                            Image {
                                id: img

                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                source: "../../MapViewer/images/exclamation-mark-triangle.svg"
                            }


                        }


                        BaseText {
                            id: errorText
                            font.pixelSize: 12
                            color: _fieldValidType === "Error" ? "red" : "orange"
                            text:strings.incompatible_fields//qsTr("Value is incompatible with other selected values")
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            wrapMode:Text.WordWrap
                            maximumLineCount: 1
                            leftPadding: !app.isRightToLeft ? (app.isLarge?app.units(24):app.units(5)) : 0
                            rightPadding: !app.isRightToLeft ?  0 : (app.isLarge?app.units(24):app.units(5))
                            horizontalAlignment: Label.AlignLeft
                            visible:_fieldValidType !== "undefined" && _fieldValidType > "" ? true:false

                        }


                        SpaceFiller { Layout.fillHeight: true }

                    }
                }
                Rectangle {
                    Layout.fillWidth: true

                    Layout.preferredHeight: desc.lineCount > 1? app.units(10):app.units(6)
                }
            }


            Item{
                Layout.preferredWidth: visible?app.units(20):0
                Layout.preferredHeight: contentColumn.height
                //Layout.fillHeight: true

                EditControls.EditIconControl{
                    delegContent: delegateContent
                    onSaveDate: {
                        //save the current Feature in memory
                        attributeEditorManager.saveAttributes_object(editObject)
                        //update the model
                        updateFieldObject(editObject)

                    }
                    onSaveDataField: {
                        //update the model
                         let editedTable = editObject.currentFeatureEdited.featureTable.tableName
                        updateFieldObject(editObject)
                    }

                }
            }

        }

    }


}

