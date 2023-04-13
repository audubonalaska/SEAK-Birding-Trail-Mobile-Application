import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
//import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import "../../../MapViewer/controls" as Controls

ToolBar {
    id: panelIdentifyFooter
    property real panelHeaderHeight:isInEditMode ?app.units(80):app.units(50)
    property color headerBackgroundColor: app.backgroundColor//"#CCCCCC"
    property alias editorOptionsPopup:editorOptionsPopup
    property bool isValidated:false


    height:((editbtnRect.visible || pageCounter.visible)  || isInEditMode) ? panelHeaderHeight : 0
    width:parent.width
    Material.elevation: 0
    // bottomPadding: app.notchHeight//panelPage.fullView && app.isInShapeEditMode? app.notchHeight : 0

    Material.background: headerBackgroundColor
    property bool showPageCount: false
    property int pageCount: 1
    property int currentPageNumber: 1
    property bool isInputValidated:true
    property bool hasEdits:false//identifyManager.editedFeatures.length > 0
    property var editedTables:[]


    signal expandButtonClicked ()
    signal previousButtonClicked ()
    signal nextButtonClicked ()
    signal backButtonPressed ()
    signal hidePanelPage()
    signal editCurrentFeature(var pageNumber)
    signal changePageNumber(var newPageNumber)
    signal showEditorTrackingInfo(var pageNumber)
    signal populateModelAfterEdit()
    signal showEditorOptionsPopup(var pageNumber)
    signal editAttribute()
    signal editGeometry()
    signal exitShapeEditMode(var action)
    signal sketchComplete()
    signal deleteCurrentFeature()
    signal backButtonClicked()

    Connections{
        target:attributeEditorManager

        function onAttributesSavedInMemory(updatedFeature){
            let fldValueChanged = false
            attributeEditorManager.editedFieldValues.forEach(function(fieldObj){
                if(fieldObj.oldValue !== fieldObj.newValue)
                    fldValueChanged = true

            })
            if(fldValueChanged)
            {
                hasEdits = true
                let editedTableName = updatedFeature.featureTable.tableName
                if(!editedTables.includes(editedTableName))
                    editedTables.push(editedTableName)
            }
            else
                hasEdits = false

            let featureValidationErrorType = contingencyValues.validateContingentValues(updatedFeature)
            if(featureValidationErrorType !== "Error")
                isValidated = true


        }

        function onAttributesSaved(isRelated)
        {
            hasEdits = false

        }
    }


    Rectangle{
        width:parent.width
        height:parent.height
        color:"transparent"
        // visible:!app.isInEditMode
        Button {
            id: _cancel
            text:strings.cancel
            visible:isInEditMode
            Material.foreground: pressed ? Qt.lighter(app.primaryColor) : app.primaryColor
            anchors.left:parent.left
            anchors.leftMargin: app.units(10)
            anchors.verticalCenter: parent.verticalCenter

            background: Rectangle {
                implicitWidth: (panelIdentifyFooter.width - 42)/2
                implicitHeight: app.units(48)
                //color:app.primaryColor
                border.color: app.primaryColor//"#888"
                radius: 4

            }




            onClicked:{

                if(hasEdits)
                {
                    app.messageDialog.width = messageDialog.units(300)
                    app.messageDialog.standardButtons = Dialog.Cancel | Dialog.Yes

                    app.messageDialog.show(strings.discard_edits,strings.cancel_editing)

                    app.messageDialog.connectToAccepted(function () {
                        backButtonClicked()

                    })
                    app.messageDialog.connectToRejected(function () {
                        identifyManager.editedFeatures = []
                        identifyManager.featureEdited = false

                    })
                }
                else
                    backButtonClicked()

            }

        }


        Button {
            id: _applyBtn
            text:strings.update//strings.apply
            visible:isInEditMode
            Material.foreground: "white"
            anchors.right:parent.right
            anchors.rightMargin: app.units(10)
            anchors.verticalCenter: parent.verticalCenter

            background: Rectangle {
                implicitWidth: (panelIdentifyFooter.width - 42)/2
                implicitHeight: app.units(48)
                //color:app.primaryColor
                color: _applyBtn.pressed ? Qt.lighter(app.primaryColor) : app.primaryColor

                radius: 4

            }




            onClicked:{
                let _editedfeatureArray = []


                if(hasEdits)
                {

                    let currentFeature = identifyManager.currentFeature
                    if(editedTables.includes(currentFeature.featureTable.tableName))
                        _editedfeatureArray.push(currentFeature)

                    //we are saving a related feature
                    let _relatedfeatureList = identifyManager.relatedFeatures[identifyBtn.currentPageNumber -1]
                    if(_relatedfeatureList && _relatedfeatureList.length > 0)
                    {
                        let _relatedFeature = _relatedfeatureList[0].feature
                        if(editedTables.includes(_relatedFeature.featureTable.tableName))
                            _editedfeatureArray.push(_relatedFeature)

                    }

                    attributeEditorManager.saveExistingFeature(_editedfeatureArray,false)

                }
                else
                {
                    if(!attributeEditorManager.isAttachmentEdited)
                        toastMessage.show(strings.no_edits_to_save)
                    backButtonClicked()

                }

            }

        }


        Rectangle{
            id:editbtnRect
            width:app.units(28)
            height:app.units(28)
            radius: app.units(14)
            anchors.right:parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: app.units(16)
            //anchors.rightMargin: app.units(24)
            border.color: "#4c4c4c"//app.separatorColor
            color:"transparent"
            visible:supportEditing  && app.isWebMap  && app.isOnline && !isInEditMode

            Controls.Icon {
                id: editBtn                
                enabled:isOnline
                visible:parent.visible && !isInEditMode
                anchors.centerIn:parent
                //anchors.right:parent.right
                imageWidth: visible?app.units(16):0
                imageHeight: app.units(16)                
                Material.elevation: 0
                maskColor:"#4c4c4c"

                imageSource: "../../../MapViewer/images/pencil2.svg"

                onClicked: {
                    hasEdits = false
                    identifyManager.editedFeatures = []
                    attributeEditorManager.isAttachmentEdited = false

                    showEditorOptionsPopup(currentPageNumber)
                }
            }



        }

        RowLayout{
            id:pageCounter
            anchors.centerIn: parent
            Layout.fillHeight: true
            spacing: 0
            visible:!isInEditMode && showPageCount &&  !mapPage.isInShapeEditMode

            Controls.Icon {
                id: previousPage

                Material.background: backgroundColor
                Material.elevation: 0
                maskColor: "#4c4c4c"
                enabled: currentPageNumber > 1
                rotation: !app.isRightToLeft ? 90 : -90
                imageSource: "../../../MapViewer/images/arrowDown.png"


                onClicked: {
                    previousButtonClicked()
                }
            }

            Controls.BaseText {
                id: countText
                text: qsTr("%L1 of %L2").arg(currentPageNumber).arg(pageCount)
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: titleFontFamily
                verticalAlignment: Text.AlignVCenter


            }

            Controls.Icon {
                id: nextPage
                Material.background: backgroundColor
                Material.elevation: 0
                maskColor: "#4c4c4c"
                enabled: currentPageNumber < pageCount
                rotation: !app.isRightToLeft ? -90 : 90
                imageSource: "../../../MapViewer/images/arrowDown.png"


                onClicked: {
                    nextButtonClicked()
                }
            }
        }

    }


    Menu {
        id: editorOptionsPopup
        property real menuItemHeight: app.units(48)
        property real colorPaletteHeight: 1.4 * menuItemHeight
        modal: true
        width:editcontentCol.width
        height:editcontentCol.height + app.baseUnit//+ defaultMargin
        x:!app.isRightToLeft ? parent.width - 2 * app.defaultMargin - editcontentCol.width : app.defaultMargin
        padding: 0
        bottomMargin: 2* app.units(8)//defaultMargin
        topMargin: 0
        topPadding: 0

        property alias listView: editoptionslist

        contentItem: Item {
            id: editoptionslist
            anchors.fill: parent
            LayoutMirroring.enabled: isRightToLeft//!isLeftToRight
            LayoutMirroring.childrenInherit:isRightToLeft //!isLeftToRight
            ColumnLayout{
                id:editcontentCol
                width:(editattribute.width > editShape.width)? editattribute.width +  app.defaultMargin: editShape.width + app.defaultMargin
                anchors.right: parent.right

                spacing:0//app.units(8)


                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight: editattribute.height
                    color:"transparent"
                    Controls.BaseText {
                        id:editattribute
                        fontsize:16 //app.textFontSize
                        color:app.baseTextColor
                        maximumLineCount: 1
                        anchors.left: parent.left
                        elide: Text.ElideRight
                        text: strings.edit_attribute
                        wrapMode: Text.Wrap
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: !app.isRightToLeft ? app.defaultMargin : 0
                        rightPadding: !app.isRightToLeft ? 0 : app.defaultMargin

                        topPadding: app.baseUnit
                    }

                    MouseArea{
                        anchors.fill:parent
                        onClicked: {

                            isInEditMode = true
                            currentPageNumber = currentPageNumber
                            attributeEditorManager.editedFieldValues = []
                            //isFooterVisible = false
                            identifyBtn.currentlyEditedPageNumber = currentPageNumber
                            mapView.identifyProperties.isModelBindingInProgress = true
                            editCurrentFeature(currentPageNumber)
                            newFeatureEditBtn.checked = false
                            identifyBtn.currentPageNumber = currentPageNumber
                        }

                    }
                }

                Rectangle{
                    Layout.fillWidth: true
                    //Layout.preferredWidth: parent.width + defaultMargin
                    Layout.preferredHeight:app.units(8)
                    color:"transparent"
                }
                Rectangle{
                    Layout.fillWidth: true
                    //Layout.preferredWidth: parent.width + defaultMargin
                    Layout.preferredHeight: 1
                    color:app.separatorColor
                }

                Rectangle{
                    Layout.fillWidth: true
                    //Layout.preferredWidth: parent.width + defaultMargin
                    Layout.preferredHeight:app.units(8)
                    color:"transparent"
                }

                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight:editShape.height
                    color:"transparent"
                    Controls.BaseText {
                        id: editShape
                        fontsize:16 //app.textFontSize
                        color:identifyManager.canEditGeometry ?app.baseTextColor : app.subTitleTextColor//app.subTitleTextColor
                        anchors.left: parent.left

                        maximumLineCount: 1
                        elide: Text.ElideRight
                        text:strings.edit_geometry
                        wrapMode: Text.Wrap
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: !app.isRightToLeft ? app.defaultMargin : 0
                        rightPadding: !app.isRightToLeft ? 0 : app.defaultMargin
                    }
                    MouseArea{
                        anchors.fill:parent

                        onClicked: {
                            if(identifyManager.canEditGeometry){
                                currentPageNumber = currentPageNumber
                                //sketchEditorManager.sketchStarted = false
                                mapPage.isInShapeEditMode = true
                                newFeatureEditBtn.checked = false


                                editGeometry()
                                editorOptionsPopup.close()
                            }

                        }
                    }

                }

                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight:app.units(8)
                    color:"transparent"
                }

                Rectangle{
                    Layout.fillWidth: true
                    //Layout.preferredWidth: parent.width + defaultMargin
                    Layout.preferredHeight: 1
                    color:app.separatorColor
                }

                Rectangle{
                    Layout.fillWidth: true
                    //Layout.preferredWidth: parent.width + defaultMargin
                    Layout.preferredHeight:app.units(8)
                    color:"transparent"
                }

                Rectangle{
                    Layout.fillWidth: true
                    Layout.preferredHeight:deleteFeature.height
                    color:"transparent"
                    Controls.BaseText {
                        id: deleteFeature
                        fontsize:16//app.textFontSize
                        color:identifyManager.canDeleteFeature ?"red" : app.subTitleTextColor
                        anchors.left: parent.left
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        text:strings.delete_feature
                        wrapMode: Text.Wrap
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: !app.isRightToLeft ? app.defaultMargin : 0
                        rightPadding: !app.isRightToLeft ? 0 : app.defaultMargin
                    }
                    MouseArea{
                        anchors.fill:parent

                        onClicked: {
                            if(identifyManager.canDeleteFeature)

                                deleteCurrentFeature()


                        }
                    }

                }





            }

        }
    }




    //end popup

    onCurrentPageNumberChanged: {
        nextPage.enabled = currentPageNumber < pageCount
        previousPage.enabled = currentPageNumber > 1
    }

    onPageCountChanged: {
        nextPage.enabled = currentPageNumber < pageCount
        previousPage.enabled = currentPageNumber > 1
    }

    onNextButtonClicked: {
        if (currentPageNumber < pageCount) {
            currentPageNumber += 1
            //console.log("currentpagenumber is :",currentPageNumber)
            changePageNumber(currentPageNumber)
            //isCurrentFeatureHighlighted = false
        }
    }

    onPreviousButtonClicked: {
        if (currentPageNumber > 1) {
            currentPageNumber -= 1
            //console.log("currentpagenumber is :",currentPageNumber)
            changePageNumber(currentPageNumber)

        }
    }

    onShowEditorOptionsPopup:{

        editorOptionsPopup.open()
    }

}


