/*
 This footer is for creating a new feature and is dynamically loaded in panel.qml using loader

*/

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
//import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1
import QtQuick.Controls.Styles 1.4

import "../../../MapViewer/controls" as Controls

ToolBar {
    id: panelCreateNewFooter
    property real panelHeaderHeight:app.units(50)//app.units(140)
    property color headerBackgroundColor:app.backgroundColor //"#CCCCCC"
    property bool isValidated:false
    property bool hasEdits:true

    signal editGeometry()
    signal backToSketchMode()
    signal saveFeature()
    signal hidePanelPage()

    height:app.units(72)//panelHeaderHeight
    width:parent.width
    Material.elevation: 0
    bottomPadding: app.notchHeight

    Material.background: headerBackgroundColor

    Connections{
        target:attributeEditorManager
        //function onFeatureEditedChanged(){
        function onAttributesSavedInMemory(feature){
            validateFields()

        }

        function onAttributesSaved(isRelated)
        {
            hasEdits = false

        }
    }

    Connections{
        target:sketchEditorManager
        function onShowErrorMessage(){
            busyPopUp.close()
        }

    }


    function validateFields()
    {
        let currentFeature = sketchEditorManager.newFeatureObject["feature"]
        let requiredFieldsEntryStatus = sketchEditorManager.getFeatureValidStatus()
        let isStatusValid = requiredFieldsEntryStatus.status
        let invalidFields = requiredFieldsEntryStatus.inValidFields
        let validConstraintsType = contingencyValues.validateContingentValues(currentFeature)
        if(!isStatusValid || validConstraintsType === "Error")
            isValidated = false
        else
            isValidated = true

    }

    Component.onCompleted: {
        validateFields()
    }



     RowLayout{
        width:parent.width - 32
        anchors.horizontalCenter: parent.horizontalCenter
        height:parent.height + app.notchHeight
        spacing:10

        Button {
            id:discardBtn
            text: strings.discard
            Material.foreground: pressed ? Qt.lighter(app.primaryColor) : app.primaryColor

            background: Rectangle {
                implicitWidth: (panelCreateNewFooter.width - 42)/2
                implicitHeight: app.units(48)
                border.color: app.primaryColor//"#888"
                radius: 4

            }



            onClicked:{
                app.messageDialog.width = messageDialog.units(300)
                app.messageDialog.standardButtons = Dialog.Cancel | Dialog.Yes
                app.messageDialog.show(strings.discard_edits,strings.cancel_editing)
                app.messageDialog.connectToAccepted(function () {
                    hidePanelPage()
                    app.isExpandButtonClicked = false
                }
                )

            }

        }

        Button {
            id:createBtn
            text: strings.create
            Material.foreground: "white"

            background: Rectangle {
                implicitWidth: (panelCreateNewFooter.width - 42)/2
                implicitHeight: app.units(48)               
                color: createBtn.pressed ? Qt.lighter(app.primaryColor) : app.primaryColor
                radius: 4

            }

            onClicked:{
                if(!savebusyIndicator.visible){
                    let currentFeature = sketchEditorManager.newFeatureObject["feature"]
                    let statusObject = sketchEditorManager.getFeatureValidStatus()
                    let isStatusValid = statusObject.status
                    let invalidFields = statusObject.inValidFields
                    let validConstraintsType = contingencyValues.validateContingentValues(currentFeature)//sketchEditorManager.getFeatureContingencyConstraints()
                    if(!isStatusValid)
                    {
                        app.messageDialog.width = messageDialog.units(300)
                        app.messageDialog.standardButtons = Dialog.Ok
                        app.messageDialog.show(strings.invalid_fields,strings.show_null_fields.arg(invalidFields))

                    }
                    else if(validConstraintsType === "Error")
                    {
                        app.messageDialog.width = messageDialog.units(300)
                        app.messageDialog.standardButtons = Dialog.Ok
                        app.messageDialog.show(strings.invalid_fields,strings.incompatible_fields)
                    }

                    else
                    {
                        busyPopUp.open()
                        sketchEditorManager.saveCurrentFeature()

                    }
                }

            }

        }

    }


    Popup{
        id:busyPopUp

        x:(app.width - implicitWidth)/2
        y:- (app.height - app.headerHeight)/2
        modal: true
        // focus: true
        implicitWidth: app.units(200)
        implicitHeight: app.units(200)
        closePolicy: Popup.NoAutoClose

        contentItem : Pane {
            id: pane
            Material.background: "white"

            // Material.elevation: 16
            ColumnLayout {
                width:parent.width
                anchors.centerIn: parent

                spacing:8
                Item{
                    Layout.fillWidth: true
                    Layout.preferredHeight:app.iconSize

                    BusyIndicator {
                        id: savebusyIndicator
                        width:app.iconSize

                        visible: true
                        height: width

                        anchors.centerIn: parent
                        Material.primary: app.primaryColor
                        Material.accent: app.accentColor
                    }
                }

                Item{
                    Layout.fillWidth: true
                    Layout.preferredHeight:createFeatureText.height

                    Controls.BaseText {
                        id: createFeatureText
                        wrapMode:Text.WrapAnywhere
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: strings.creating_feature
                    }
                }

            }

        }


    }

}
