import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1
import QtQuick.Dialogs 1.2

import Esri.ArcGISRuntime 100.14

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0


import ArcGIS.AppFramework.Notifications 1.0
import "../../../MapViewer/controls" as Controls


Flickable{
    id:identifyAttachmentsView
    anchors.fill:parent
    clip:true
    contentHeight: identifyAttachmentsColView.height
    property var _model
    property bool canAddAttachment:false
    property bool editAttachmentInProgress:false
    property real delegateHeight: app.headerHeight
    property real headerHeight: (_model && _model.count > 0) ? 0.8 * app.headerHeight : 0
    property string layerName: ""
    property string popupTitle: ""
    property var tasksInProgress:[]
    property alias timeOut:timeOut
    property color backgroundColor: "#FFFFFF"
    property string attachmentstorageBasePath: "~/ArcGIS/AppStudio/Cache/Attachments/"
    property var attachmentfileInfo : AppFramework.fileInfo(attachmentstorageBasePath);
    property var tempFolder:attachmentfileInfo.folder

    signal fileDeleted()
    signal attachmentAdded(var fileSize)

    onAttachmentAdded:{
        attributeEditorManager.isAttachmentEdited = true

        if(fileSize > 1024 * 1024)
        {
            toastMessage.display(strings.successfully_uploaded, strings.large_file_uploaded)

        }
        else
            toastMessage.show(strings.successfully_uploaded)

        let attachmentstorageBasePath = "~/ArcGIS/AppStudio/Cache/Attachments/"
        let attachmentfileInfo = AppFramework.fileInfo(attachmentstorageBasePath);
        let tempFolder = attachmentfileInfo.folder

        let tempfiles = tempFolder.fileNames()
        tempfiles.forEach(_fileName => {
                              if(tempFolder.fileExists(_fileName))
                              tempFolder.removeFile(_fileName)
                          })
    }






    onFileDeleted:{
        if(panelPage){
            panelPage.action = "deleteAttachment"
            toastMessage.show(qsTr("Successfully deleted."))
            timeOut.start()
            attributeEditorManager.isAttachmentEdited = true
        }
    }

    SelectFolderTypeForAttachment
    {
        id:selectFolderTypeForAttachment
        width:Math.min(app.units(280),identifyAttachmentsView.width - 64)
        onSelectFiles: {
            selectFolderTypeForAttachment.close()
            let _folderType = folderType
            if(_folderType === "photos")
            {

                fileDialog.folder = "file:assets-library://"
                fileDialog.open()
            }
            else
            {
                fileDialog.folder = AppFramework.resolvedPathUrl(AppFramework.standardPaths.standardLocations(StandardPaths.PicturesLocation)[0])
                fileDialog.open()
            }
        }

    }

    BusyIndicator {
        id: busyIndicator

        width: app.iconSize
        visible: editAttachmentInProgress
        height: width
        //anchors.centerIn: identifyAttachmentsView
        Material.primary: app.primaryColor
        Material.accent: app.accentColor
        Material.elevation:2
        y:identifyAttachmentsView.height/2
        //y:identifyAttachmentsView.height/2 - app.units(40)
        x:identifyAttachmentsView.width/2

    }

    Timer {
        id: timeOut

        interval: 2000
        running: false
        repeat: false
        triggeredOnStart: true
        property int count:0

        onTriggered: {
            count +=1

            if(count >= 2)
            {
                count = 0
                editAttachmentInProgress = false
                //busyIndicator.visible = false
            }

        }
    }

    DocumentDialog{
        id: fileDialog
        folder: AppFramework.resolvedPathUrl(AppFramework.standardPaths.standardLocations(StandardPaths.PicturesLocation)[0])

        function doAddAttachment(){
            let fileInfo = AppFramework.fileInfo(fileDialog.fileUrl)
            let fileName = fileInfo.fileName

            var selectedFeature = identifyManager.features[currentPageNumber-1]
            if (selectedFeature.loadStatus === Enums.LoadStatusLoaded) {
                selectedFeature.onLoadStatusChanged.disconnect(doAddAttachment);
                if(Qt.platform.os === "android")
                {
                    let tempfileurl = tempFolder.fileUrl(fileName)
                    addAttachment(tempfileurl,fileName)
                }
                else
                {
                    addAttachment(fileDialog.fileUrl,fileInfo.fileName)

                }

            }

        }

        function fetchAttachments(){
            attachementsView.refreshAttachments()

        }



        //In case of Android since fileUrl returns contentUri,
        //we need to copy the file to a tempFolder
        // and then use the fileUrl for adding attachment
        function addAtachment_Android(fileUrl,fileName,fileSize){

            let fileInfo = AppFramework.fileInfo(fileUrl);
            let fileFolder = fileInfo.folder;
            if(!tempFolder.exists){
                tempFolder.makeFolder(attachmentstorageBasePath);
            }

            let tempFilePath = tempFolder.filePath(fileInfo.fileName);

            if(tempFolder.fileExists(fileInfo.fileName))
                tempFolder.removeFile(fileInfo.fileName)

            fileFolder.copyFile(fileInfo.fileName, tempFilePath);
            let tempfileurl = tempFolder.fileUrl(fileName)

            addAttachment(tempfileurl,fileName,fileSize)

        }

        function addFileAsAttachment(selectedFeature,fileUrl,fileName,fileSize)
        {
            let attachmentaddingStarted = true
            selectedFeature.attachments.addAttachmentStatusChanged.connect(function(){
                if(selectedFeature.attachments.addAttachmentStatus === Enums.TaskStatusCompleted)
                {
                    if(attachmentaddingStarted)
                    {
                        attachmentaddingStarted = false


                        attachmentAdded(fileSize)

                        //clear the tempfolder
                        let tempfiles = identifyAttachmentsView.tempFolder.fileNames()
                        tempfiles.forEach(_fileName => {
                                              if(identifyAttachmentsView.tempFolder.fileExists(_fileName))
                                              identifyAttachmentsView.tempFolder.removeFile(_fileName)
                                          })

                        timeOut.start()
                    }

                }
            }
            )

            attachmentsUpdated = true
            var addTask = selectedFeature.attachments.addAttachment(fileUrl, "application/octet-stream", fileName);
            tasksInProgress.push(addTask)
        }


        function addAttachment(fileUrl,fileName,fileSize)
        {
            //console.log(fileUrl.toString())
            var attachmentaddingStarted = true

            editAttachmentInProgress = true
            let selectedFeature = null
            if(isInShapeCreateMode)
                selectedFeature = sketchEditorManager.newFeatureObject["feature"]
            else
                selectedFeature = identifyManager.features[identifyBtn.currentPageNumber-1]

            if (selectedFeature.loadStatus === Enums.LoadStatusLoaded) {

                addFileAsAttachment(selectedFeature,fileUrl,fileName,fileSize)


            } else {
                selectedFeature.onLoadStatusChanged.connect(doAddAttachment);
                selectedFeature.load();
            }

        }


        onAccepted: {
            // add the attachment to the feature table
            //fileInfo.url = fileDialog.fileUrl;
            //var selectedFeature = mapView.identifyProperties.features[currentPageNumber-1]
            let fileInfo = AppFramework.fileInfo(fileDialog.fileUrl)

            let fileName = fileInfo.fileName

            let suffix = fileInfo.suffix
            if(Qt.platform.os === "ios")
            {
                let pictureUrlInfo = AppFramework.urlInfo(fileDialog.fileUrl)

                let path = pictureUrlInfo.path

                if((path.toLowerCase()).indexOf("assets-library") > -1)
                {

                    let picturePath = pictureUrlInfo.localFile;
                    let assetInfo = AppFramework.urlInfo(picturePath);
                    suffix = assetInfo.queryParameters.ext

                    if(!suffix)
                        suffix="jpg"

                    fileName = assetInfo.queryParameters.id + "." + assetInfo.queryParameters.ext;
                }

            }

            let filesallowed = "7Z, AIF, AVI, BMP, DOC, DOCX, DOT, ECW, EMF, EPA, GIF, GML, GTAR, GZ, IMG, J2K,HEIC," +
                "JP2, JPC, JPE, JPEG, JPF, JPG, JSON, MDB, MID, MOV, MP2, MP3, MP4, MPA, MPE, MPEG, MPG, MPV2, PDF, PNG, PPT," +
                "PPTX, PS, PSD, QT, RA, RAM, RAW, RMI, SID, TAR, TGZ, TIF, TIFF, TXT, VRML, WAV, WMA, WMF, WPS, XLS, XLSX, XLT, XML, ZIP"

            let indx = -1
            if(suffix.length > 0)
                indx = filesallowed.toUpperCase().indexOf(suffix.toUpperCase())



            if(indx < 0)
            {
                messageDialog.text = qsTr("File not supported.")
                messageDialog.open()
            }
            else
            {

                if(Qt.platform.os === "android")
                {
                    editAttachmentInProgress = true

                    addAtachment_Android(fileDialog.fileUrl,fileInfo.fileName,fileInfo.size)
                }
                else
                {
                    editAttachmentInProgress = true

                    addAttachment(fileDialog.fileUrl,fileName,fileInfo.size)
                }
            }

        }
    }


    ColumnLayout{
        id: identifyAttachmentsColView
        width:parent.width

        Rectangle{
            Layout.preferredHeight: app.units(4)
            Layout.fillWidth: true
            //color:"red"
        }

        Repeater{
            model:_model
            delegate: Item{

                Layout.preferredHeight:delegateHeight//(lbl.text > "") ? delegateHeight : 0
                // visible: (lbl.text > "")
                Layout.preferredWidth: identifyAttachmentsView.width
                MouseArea{
                    anchors.fill:parent
                    onClicked: {
                        if (attachmentUrl > "") {
                            AppFramework.openUrlExternally(attachmentUrl)
                        }
                    }
                }


                RowLayout {
                    id:atachmentRow
                    spacing: 0



                    anchors {
                        fill: parent
                    }

                    Rectangle {
                        id:iconRect
                        clip: true
                        color: "transparent" //app.backgroundColor
                        Layout.preferredWidth: Math.min(parent.height, 0.6*app.iconSize)
                        Layout.preferredHeight: parent.height
                        Layout.leftMargin: app.defaultMargin

                        Image {
                            id: img

                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: {
                                if (typeof contentType === "undefined") {
                                    return ""
                                } else if (!contentType) {
                                    return "../../../MapViewer/images/file.png"
                                } else if (contentType.split("/")[0] === "image") {
                                    return "../../../MapViewer/images/image.png"
                                } else if (contentType.split("/")[0] === "text") {
                                    return "../../../MapViewer/images/note.png"
                                } else if (contentType.endsWith(".sheet")) {
                                    return "../../../MapViewer/images/excel.png"
                                } else if (contentType.endsWith("pdf")) {
                                    return "../../../MapViewer/images/ic_file_pdf_grey600_48dp.png"
                                }
                                return "../../../MapViewer/images/file.png"
                            }
                        }

                        ColorOverlay {
                            id: mask

                            anchors.fill: img
                            source: img
                            color: app.subTitleTextColor//app.primaryColor
                        }
                    }

                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.rightMargin: app.defaultMargin
                        Layout.leftMargin: app.defaultMargin
                        //Layout.fillWidth: true
                        Layout.preferredWidth: parent.width - iconRect.width - moreicon.width - 3 * app.defaultMargin

                        Controls.SpaceFiller {}

                        Controls.BaseText {
                            id: lbl

                            objectName: "label"
                            visible: (lbl.text > "")
                            text: typeof name !== "undefined" ? (name ? name : "") : ""
                            Layout.preferredHeight: contentHeight
                            Layout.preferredWidth: parent.width
                            verticalAlignment: sz.text > "" ? Text.AlignBottom : Text.AlignVCenter
                            horizontalAlignment: Label.AlignLeft
                            elide: Text.ElideMiddle
                            wrapMode: Text.NoWrap
                        }

                        Controls.BaseText {
                            id: sz

                            property bool isDefined: (typeof size !== "undefined" && lbl.text > "")

                            function getSize(size,attachmentUrl)
                            {

                                if(size > 0)
                                {
                                    return mapViewerCore.getFileSize(size)

                                }
                                else
                                {
                                    let attachfileInfo = AppFramework.fileInfo(attachmentUrl)
                                    return mapViewerCore.getFileSize(attachfileInfo.size)

                                }

                            }

                            visible: isDefined
                            text: isDefined ? getSize(size,attachmentUrl) : ""//isDefined ? "%1 KB".arg((size/1000).toFixed(1)) : ""
                            color: app.subTitleTextColor
                            Layout.preferredHeight: contentHeight
                            Layout.preferredWidth: parent.width
                            verticalAlignment: Text.AlignTop
                            horizontalAlignment: Label.AlignLeft
                            elide: Text.ElideMiddle
                            wrapMode: Text.NoWrap
                        }

                        Controls.SpaceFiller {}
                    }

                    Rectangle{
                        id:moreicon
                        Layout.preferredHeight: 50 * scaleFactor
                        Layout.preferredWidth: 50 * scaleFactor
                        Layout.alignment: Qt.AlignCenter

                        Controls.Icon {
                            anchors.fill: parent

                            id: moreBtn
                            visible: isInEditMode
                            imageSource: "../../../MapViewer/images/more.png"
                            enabled: true
                            anchors.centerIn: parent
                            maskColor: app.subTitleTextColor//app.primaryColor
                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    if(attachmentUrl)
                                        var modPath1 = attachmentUrl.toString();

                                    more.close()
                                    //more.y = moreicon.y
                                    more.open()
                                }



                            }
                        }

                    }

                    Controls.PopupMenu {
                        id: more
                        isInteractive: false

                        defaultMargin: app.defaultMargin
                        backgroundColor: "#FFFFFF"
                        highlightColor: Qt.darker(app.backgroundColor, 1.1)
                        textColor: app.baseTextColor
                        primaryColor: app.primaryColor

                        property  var deleteTask:null


                        menuItems:canAddAttachment ? [
                                                         {"itemLabel": qsTr("Preview"),"lcolor":""},

                                                         {"itemLabel": qsTr("Delete"),"lcolor":"red"},

                                                     ]:[
                                                         {"itemLabel": qsTr("Preview"),"lcolor":""}

                                                     ]

                        Material.primary: app.primaryColor
                        Material.background: backgroundColor

                        height: app.units(88)

                        x: !app.isRightToLeft ? (parent.width - width - app.baseUnit) : app.baseUnit
                        y: 0

                        function previewAttachment()
                        {
                            if (attachmentUrl > "") {
                                AppFramework.openUrlExternally(attachmentUrl)
                            }
                        }

                        onMenuItemSelected: {
                            switch (itemLabel) {

                            case qsTr("Delete"):
                                if(!canAddAttachment)
                                {
                                    app.messageDialog.width = messageDialog.units(300)
                                    app.messageDialog.standardButtons = Dialog.Ok


                                    app.messageDialog.show("",strings.cannot_edit_attachment)

                                }
                                else
                                {
                                    attachmentsUpdated = true
                                    //editAttachmentInProgress = true
                                    deleteAttachment()
                                }


                                break

                            case qsTr("Preview"):

                                previewAttachment()


                            }



                        }

                        function deleteAttachment() {

                            app.messageDialog.width = messageDialog.units(300)
                            app.messageDialog.standardButtons = Dialog.Cancel | Dialog.Yes

                            app.messageDialog.show("",strings.delete_this_attachment)

                            app.messageDialog.connectToAccepted(function () {
                                let feature = null

                                if(isInShapeCreateMode)
                                    feature = sketchEditorManager.newFeatureObject["feature"]
                                else
                                    feature = identifyManager.features[identifyBtn.currentPageNumber-1]


                                //let attachments = feature.attachments//mapView.identifyProperties.features[currentPageNumber-1].attachments
                                feature.attachments.deleteAttachmentStatusChanged.connect(function(){
                                    if(feature.attachments.deleteAttachmentStatus === Enums.TaskStatusCompleted) {

                                        if(identifyAttachmentsView)
                                            identifyAttachmentsView.fileDeleted()


                                    }
                                    if(feature.attachments.deleteAttachmentStatus === Enums.TaskStatusReady){
                                        //console.log("job ready")
                                    }

                                })

                                if(feature.attachments.deleteAttachmentsStatus === Enums.TaskStatusReady)// && feature.attachments.addAttachmentStatus === Enums.TaskStatusReady)
                                {
                                    //console.log("deleting",feature.attachments.count,JSON.stringify(feature.attachments.error))
                                    editAttachmentInProgress = true
                                    var attachmentToDelete = feature.attachments.get(index)
                                    feature.attachments.deleteAttachment(attachmentToDelete)
                                }
                                else
                                {
                                    tasksInProgress = []
                                }

                            })


                        }


                    }



                }


            }


        }

        Item{
            Layout.fillWidth: true

            Layout.preferredHeight:isInEditMode && _model.count === 0 ?
                                       (identifyAttachmentsView.height/2- 6 * app.baseUnit) :(_model.count === 0 ? identifyAttachmentsView.height/2 - 3 * app.baseUnit:0)
        }



        Rectangle{
            id:addAttachmentBtnContainer
            Layout.preferredWidth: app.units(45) + app.units(100)//headerText.width
            Layout.preferredHeight:addIconItem.height//visible?addIconItem.height:0//visible ?6 * app.baseUnit + headerText.height + app.units(10):0
            Layout.alignment: Qt.AlignHCenter
            //color:"blue"
            visible:!busyIndicator.visible


            //visible:isInEditMode && identifyAttachmentsView.canAddAttachment
            ColumnLayout{
                id:addIconItem
                width:app.units(45) + app.units(100)//headerText.width
                spacing:10
                Controls.Icon {
                    id: addAttachmentBtn

                    imageWidth: app.units(45)
                    imageHeight: app.units(45)
                    Layout.alignment: Qt.AlignHCenter
                    //anchors.horizontalCenter: parent.horizontalCenter
                    Material.background: backgroundColor
                    Material.elevation: 0
                    checkable: true
                    visible:isInEditMode && identifyAttachmentsView.canAddAttachment

                    maskColor: pressed ? Qt.lighter(app.primaryColor) : app.primaryColor//"#4c4c4c"
                    imageSource: "../../../MapViewer/images/plus-circle.svg"


                    onClicked: {
                        if (HapticFeedback.supported === true) { HapticFeedback.send(1)}

                        if(identifyAttachmentsView.canAddAttachment)
                        {
                            if(Qt.platform.os !== "ios")

                                fileDialog.open()
                            else
                            {

                                selectFolderTypeForAttachment.open()

                            }

                        }
                        else
                        {
                            app.messageDialog.width = messageDialog.units(300)
                            app.messageDialog.standardButtons = Dialog.Ok

                            app.messageDialog.show("",strings.cannot_edit_attachment)

                        }
                    }
                }

                Controls.BaseText {
                    id: headerText

                    //Layout.fillWidth: true

                    font.pixelSize: 15
                    color: titleColor
                    text:strings.add_attachment
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    wrapMode:Text.WordWrap
                    maximumLineCount: 2

                    horizontalAlignment: Label.AlignHCenter//Label.AlignLeft
                    visible: addAttachmentBtn.visible
                    Layout.alignment: Qt.AlignHCenter


                }

                Controls.BaseText {
                    id: message
                    visible:_model && _model.count === 0 && !addAttachmentBtn.visible && !busyIndicator.visible && !isInEditMode
                    maximumLineCount: 5
                    elide: Text.ElideRight
                    //width: parent.width
                    //height: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.alignment: Qt.AlignHCenter
                    text: strings.no_attachments

                }

            }

        }



    }


}

