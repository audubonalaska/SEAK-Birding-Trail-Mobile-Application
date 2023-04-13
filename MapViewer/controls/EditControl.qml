/* Copyright 2022 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.14


import "../images"

Column {
    id: column
    spacing: 3 * app.scaleFactor

    width: parent.width
    LayoutMirroring.enabled: !app.isLeftToRight
    LayoutMirroring.childrenInherit: !app.isLeftToRight
    Item{
        width:parent.width
        height:app.units(16)
    }


    RowLayout{
        anchors {
            left: parent.left
            right: parent.right
        }
        height: aliasText.height
        //top label
        Text {
            id: aliasText
            text:editObject.label
            verticalAlignment: Text.AlignBottom
            color:editAttributePage.isInputValidated?app.primaryColor:"#FFC7461A"
            font.pixelSize:app.baseFontSize

            font.family: app.baseFontFamily

            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 1

        }
        Text {
            id: nullableicon
            text:"*"
            verticalAlignment: Text.AlignTop

            font{
                pixelSize: app.subtitleFontSize

            }
            color: "#FFC7461A"
            visible: !editObject.nullableValue

        }


        Item{
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        Text{
            id: fieldlimitText
            text: editObject.length? textArea.text.trim().length+"/"+ editObject.length : ""
            visible: editObject.fieldType === Enums.FieldTypeText
            width:parent.width * 2
            //Layout.preferredWidth: parent.width*0.2
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignBottom
            fontSizeMode: Text.HorizontalFit
            color: app.baseTextColor//app.titleTextColor
            font{
                pixelSize:app.baseFontSize //app.subtitleFontSize*0.8
                //family: app.customTextFont.name
            }
            opacity: 0.4
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }

    }


    Item {
        id:textItem

        height: childrenRect.height
        width:parent.width
        anchors {
            left: parent.left
            right: parent.right
        }

        IntValidator {
            id: smallIntValidator
            bottom: editObject.minValue !== editObject.maxValue ?editObject.minValue:-32768
            top: editObject.minValue !== editObject.maxValue ?editObject.maxValue:32767
        }

        IntValidator {
            id: defaultIntValidator
            bottom: editObject.minValue !== editObject.maxValue ?editObject.minValue:-2147483648
            top: editObject.minValue !== editObject.maxValue ?editObject.maxValue:2147483647
        }

        DoubleValidator {
            id: doubleValidator
            bottom:editObject.minValue !== editObject.maxValue ?editObject.minValue: -2.2E38
            top:editObject.minValue !== editObject.maxValue ?editObject.maxValue: 1.8E38
            decimals: 6
        }

        Rectangle{
            id: textFieldContainer
            width: parent.width - app.units(40)
            height: textField.height
            visible:editObject.fieldType !== Enums.FieldTypeText
            anchors.left: parent.left
            //color:"green"

            TextField {
                id: textField
                padding:3 * scaleFactor
                topPadding: 10 * scaleFactor
                bottomPadding: 5 * scaleFactor
                height:implicitHeight
                width: parent.width
                font.pixelSize:app.baseFontSize
                //font.pixelSize: app.units(14) //* scaleFactor
                font.family: app.baseFontFamily
                horizontalAlignment: Text.AlignLeft


                font {
                    bold: false
                }

                background: null


                color: acceptableInput ? "black" : "#FFC7461A"//"red"

                validator: setValidator()

                maximumLength: editObject.length > 0 ? editObject.fieldType === Enums.FieldTypeDate? Number.MAX_VALUE:editObject.length: editObject.fieldType === Enums.FieldTypeInt32? 18: Number.MAX_VALUE


                text:editObject.fieldValue

                inputMethodHints: (editObject.fieldType === Enums.FieldTypeText || editObject.fieldType === Enums.FieldTypeDate) ? Qt.ImhNone : Qt.ImhFormattedNumbersOnly

                enabled: editObject.fieldType === Enums.FieldTypeDate ? false : true
                onTextChanged: {
                    if(text !== editObject.originalFieldValue)
                        hasEdits = true
                    else
                        hasEdits = false
                    if(canResetValidator)
                    {
                        //validator


                        var vald = setValidator()
                        validator = vald
                        editAttributePage.canResetValidator = false

                    }

                    if(acceptableInput)
                    {
                        editObject.fieldValue = text

                        editAttributePage.isInputValidated = true
                        color =  "black"
                    }
                    else
                    {
                        if(!editObject.nullableValue && !text > "")
                        {
                            editAttributePage.isInputValidated = false
                            color = "#FFC7461A"//"red"
                        }
                        else
                        {
                            if(text > "")
                            {
                                editAttributePage.isInputValidated = false
                                color = "#FFC7461A"//"red"
                            }
                            else
                                editObject.fieldValue = ""
                        }

                    }

                }

                onEditingFinished: {
                    textField.focus = false;
                }

                Keys.onPressed: {
                    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                        event.accepted = true
                        editAttributePage.close()

                    }
                }


                onFocusChanged: {
                    if(focus){
                        if(editObject.fieldType === Enums.FieldTypeText && maximumLength > 249){
                            textAreaContainer.visible = true;
                            textAreaContainer.height =  Math.min(textArea.lineCount, textArea.maxLineCount) * textArea.lineHeight //+ textArea.bottomPadding

                            textField.focus = false;
                            textField.visible = false
                            textArea.focus = true;
                        } else if(editObject.fieldType === Enums.FieldTypeText && maximumLength > 49){
                            textAreaContainer.visible = true;
                            //textAreaContainer.height = textField.height*2;
                            textField.focus = false;
                            textField.visible = false//true
                            textArea.focus = true;
                        } else {
                            textArea.focus = false;
                            textAreaContainer.visible = false
                        }
                    }
                }

                function setValidator()
                {
                    if(Enums.FieldTypeInt16 === editObject.fieldType) {
                        return smallIntValidator
                    }
                    if(Enums.FieldTypeInt32 === editObject.fieldType) {
                        return defaultIntValidator
                    }
                    if(Enums.FieldTypeFloat64 === editObject.fieldType) {
                        return doubleValidator
                    }
                    return null
                }



                Component.onCompleted: {

                }



            }


        }


        Flickable{
            id: textAreaContainer
            width:textField.width - frame.width
            height: visible?Math.min(textArea.lineCount, textArea.maxLineCount) * textArea.lineHeight + textArea.topPadding:0 //+ textArea.bottomPadding
            anchors.left: parent.left
            boundsBehavior: Flickable.StopAtBounds
            interactive: true
            //color:"red"
            visible:editObject.fieldType === Enums.FieldTypeText//false
            clip:true
            onVisibleChanged:
            {

                textArea.cursorPosition = textArea.text.length
                textArea.forceActiveFocus()
                textField.text = editObject.fieldValue
            }

            TextArea {
                id: textArea
                width: parent.width
                height: lineCount >1?Math.max(implicitHeight, 36 * scaleFactor):36 * scaleFactor

                anchors.left: parent.left
                anchors.top: parent.top
                bottomPadding: app.units(0)
                topPadding: 12
                padding:0//3 * scaleFactor
                property real lineHeight:lineCount > 1? height /lineCount:30 * scaleFactor//lineCount > 1? 19 * scaleFactor : 20 * scaleFactor
                property int maxLineCount: 40
                horizontalAlignment: Text.AlignLeft

                property string previousText: editObject.fieldValue//text
                // property int maximumLength:255//Number.MAX_VALUE
                property int maximumLength:editObject.length > 0 ? editObject.length:Number.MAX_VALUE

                wrapMode: TextEdit.Wrap
                text:  editObject.fieldType === Enums.FieldTypeDate ? (editObject.fieldValue > "" ? new Date ().toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate) : "") : (editObject.fieldValue || "")
                focus: false

                background: Rectangle{
                    anchors.fill: parent

                }
                color: "black"
                font.pixelSize:app.baseFontSize
                //font.pixelSize: app.units(14) //* scaleFactor
                font.family: app.baseFontFamily
                font {
                    bold: false

                }


                onEditingFinished: {
                    resetTextArea();
                }

                Keys.onPressed: {
                    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                        event.accepted = true
                        editAttributePage.close()

                    }
                }

                Connections{
                    target:app
                    function onScreenHeightChanged(){
                        if (textAreaContainer.visible){
                            let ht = textArea.lineCount  * textArea.lineHeight
                            if(((Qt.platform.os === "ios"))){
                                if((ht + 250) > app.height)
                                {
                                    //console.log("height:",app.height - 200)
                                    textAreaContainer.height = app.height - 400
                                }
                                else
                                {
                                    textAreaContainer.height = textArea.lineCount  * textArea.lineHeight //Math.min(textArea.lineCount, textArea.maxLineCount) * textArea.lineHeight
                                    //console.log("appheight:",app.height,"ht:",ht,"heightC:",textAreaContainer.height)
                                }
                            }
                            else
                            {
                                if((ht + 150 * scaleFactor) > app.height)
                                {
                                    //console.log("height:",app.height - 200)
                                    textAreaContainer.height = app.height - 200
                                }
                                else
                                {
                                    textAreaContainer.height = textArea.lineCount  * textArea.lineHeight //Math.min(textArea.lineCount, textArea.maxLineCount) * textArea.lineHeight
                                    //console.log("appheight:",app.height,"ht:",ht,"heightC:",textAreaContainer.height)
                                }
                            }

                            // if(ht > app.height)
                            if((app.height - ht) > 50)
                                textAreaContainer.contentHeight =  Math.min(textArea.lineCount, textArea.maxLineCount) * textArea.lineHeight
                            else
                                textAreaContainer.contentHeight =  Math.max(textArea.lineCount, textArea.maxLineCount) * textArea.lineHeight



                        }
                    }

                }


                onTextChanged: {
                    //if(editObject.length > 0 )
                    // maximumLength = editObject.length
                    if(textAreaContainer.visible){
                        let ht = textArea.lineCount  * textArea.lineHeight
                        let offset = 0
                        let bottomspace = 250
                        if(Qt.platform.os === "ios")
                        {
                            offset = 150 * scaleFactor
                            bottomspace = 200 * scaleFactor
                        }

                        if(ht  + offset > app.height)
                            textAreaContainer.height = app.height - bottomspace
                        else
                            textAreaContainer.height = textArea.lineCount  * textArea.lineHeight //Math.min(textArea.lineCount, textArea.maxLineCount) * textArea.lineHeight


                        if((app.height - ht) > 50)
                            textAreaContainer.contentHeight =  Math.min(textArea.lineCount, textArea.maxLineCount) * textArea.lineHeight
                        else
                            textAreaContainer.contentHeight =  Math.max(textArea.lineCount, textArea.maxLineCount) * textArea.lineHeight



                    }
                    if(text !== editObject.originalFieldValue)
                    {
                        hasEdits = true
                        //let editedTable = editObject.currentFeatureEdited.featureTable.tableName
                    }
                    else
                        hasEdits = false

                    if(!text && !editObject.nullableValue)
                    {
                        isInputValidated = false

                    }
                    else
                    {
                        isInputValidated  = true

                        if(previousText === text)
                            cursorPosition = text.length

                        var maximumLength = Number.MAX_VALUE
                        if(editObject.length > 0)
                        {
                            maximumLength = editObject.length
                        }

                        if(text.length >= maximumLength && previousText !== text)
                        {
                            text = text.substring(0, maximumLength)
                            cursorPosition = text.length
                        }
                        if (editObject.fieldType !== Enums.FieldTypeDate){
                            editObject.fieldValue = text;

                        }
                    }
                }



                function resetTextArea(){
                    //textAreaContainer.height = textField.height
                    // textAreaContainer.visible = false;
                    //textField.visible = true
                }
            }


        }


        Rectangle{
            id:frame
            height:textField.height
            width: textField.height - 5 * scaleFactor
            anchors.right: parent.right
            anchors.rightMargin: 1 * scaleFactor
            anchors.top: textItem.top

            radius: width/2
            color:"transparent"
            visible: textField.text.length>0 && editObject.fieldType !== Enums.FieldTypeDate && (textAreaContainer.visible || textField.focus)

            Rectangle{
                height: parent.height*0.6
                width: parent.height*0.6
                anchors.centerIn: parent
                radius: width/2
                color: "#EBEBEB"
                opacity: 0.8

                Image{
                    anchors.fill: parent
                    source:"../images/ic_clear_white_48dp.png"
                    fillMode: Image.PreserveAspectFit
                }
            }

            MouseArea{
                anchors.fill: parent
                onClicked: {

                    if(!textArea.visible)
                    {
                        textField.text = ""
                    }
                    else
                    {

                        textArea.text=""
                    }
                }
            }
        }

        Component.onCompleted: {
            if(editObject.fieldType !== Enums.FieldTypeText)
                textField.focus = true
            else
            {
                textArea.cursorPosition = textArea.text.length
                textArea.forceActiveFocus()
            }
        }


    }

    Rectangle{
        width:parent.width
        height:2
        color:isInputValidated ?app.primaryColor:"#FFC7461A"
    }


    Rectangle{
        width:parent.width
        height:100
        color:"transparent"
        Text{
            id: limitText1
            text:editObject.fieldType === Enums.FieldTypeText ? strings.enter_text : (editObject.minValue !== editObject.maxValue?strings.enter_number_x_y.arg(editObject.minValue).arg(editObject.maxValue): strings.enter_number)
            visible:true
            width:parent.width

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignBottom
            fontSizeMode: Text.HorizontalFit
            color:editAttributePage.isInputValidated?app.baseTextColor:"#FFC7461A"

            font{
                pixelSize: app.baseFontSize //app.subtitleFontSize*0.8

            }
            opacity: editAttributePage.isInputValidated?0.4:1
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }

    }

}
