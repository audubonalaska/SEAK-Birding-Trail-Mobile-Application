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
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import Esri.ArcGISRuntime 100.14

//import "../controls" as Controls

ListView {
    id: domain_codedValue
    model:editObject?editObject.domainName:null

    property real minDelegateHeight: 2 * app.units(56)
    property real headerHeight:0.8 * app.headerHeight
    property string rightButtonImage: "../images/arrowDown.png"
    property var expandedsections:[]
    property string novalueSection: model.count > 0?model.get(0)[sectionPropertyAttr]:""//(count && sectionPropertyAttr > "") ? resultsListView.model.get(0)[sectionPropertyAttr] : ""
    property string firstSection: model.count > 0?model.get(1)[sectionPropertyAttr]:""//(count && sectionPropertyAttr > "") ? resultsListView.model.get(0)[sectionPropertyAttr] : ""

    property string sectionPropertyAttr: "category"
    currentIndex: getCurrentIndex()
    boundsBehavior: Flickable.StopAtBounds
    LayoutMirroring.enabled: app.isRightToLeft
    LayoutMirroring.childrenInherit: app.isRightToLeft
    clip: true
    spacing: 0
    topMargin: 0
    width:parent.width
    height:parent.height

    function collapseAllSections () {

        expandedsections.forEach(section =>
                                 {
                                     domain_codedValue.collapseSection(sectionPropertyAttr, section, false)
                                     var filtered = domain_codedValue.expandedsections.filter(item => item !== section)
                                     domain_codedValue.expandedsections = filtered
                                 })


    }
    function expandSection (sectionProperty, section, expand) {
        expandedsections.push(section)
        for (var i=0; i<model.count; i++) {
            var item = model.get(i)
            if (item[sectionProperty] === section) {

                item["showInView"] = expand
            }
        }
    }

    function collapseSection (sectionProperty, section, expand) {
        if(model){
            expandedsections = []
            //check if there are more than 2 sections. If more than 2 section collapse the third section
            var _item = model.get(1)
            if(_item[sectionProperty] !== section)
            {
                for (var i=0; i<model.count; i++) {
                    var item = model.get(i)
                    if (item[sectionProperty] === section) {
                        item["showInView"] = expand
                    }
                }
            }
        }
    }


    function setIndex()
    {
        currentIndex = 2

    }
    function getCurrentIndex()
    {
        let _currentIndex = 0
        if(editObject && editObject.domainName)
        {
            for(var i=0; i<editObject.domainName.count;i++){
                var name1 = editObject.domainName.get(i).name;
                if(editObject.fieldValue === name1){
                    _currentIndex = i;
                    //console.log("comboBox.currentIndex", comboBox.currentIndex, name, attributesArray[fieldName])
                    break;
                }
            }
        }
        return _currentIndex

    }


    footer:Rectangle{
        height:isIphoneX?36 * scaleFactor :16 * scaleFactor
        width:identifyFeaturesView.width
        color:"transparent"
    }
    delegate: Pane {
        id: delegateContent

        //visible: (lbl.text > "" && desc.text > "")
        width: parent ? parent.width - app.units(16) : 0
        // height:app.units(50)
        height: showInView ? app.units(44) : 0//(separatorRect.visible ? app.units(82) : app.units(66)):(separatorRect.visible ? 16:0)
        padding: 0
        spacing: 0
        clip: true
        Material.background: "white"
        // property var isCollapsed:collapsedState


        contentItem: Item {
            width: parent.width //- app.units(16)
            height: parent.height//contentColumn.height



            RowLayout{
                id:rowedit
                width:parent.width //- app.units(16)
                height:parent.height //- 2



                Label{
                    id: lbl

                    objectName: "label1"
                    text:name
                    Layout.preferredWidth: parent.width - app.units(66)
                    Layout.preferredHeight: implicitHeight
                    Layout.leftMargin: app.units(6)
                    horizontalAlignment: Label.AlignLeft
                    verticalAlignment: Label.AlignVCenter
                    topPadding: 10
                    // Layout.alignment: Qt.AlignVCenter

                    elide: Text.ElideMiddle
                    wrapMode: Text.WrapAnywhere
                    color:app.baseTextColor
                    //color: Qt.darker("#F7F8F8")//getAppProperty(app.baseTextColor, Qt.darker("#F7F8F8"))
                    font.italic: name === strings.no_value?true : false

                    font.bold: index === currentIndex?true:false
                    font.pointSize: 12
                    //font.pixelSize:app.baseFontSize
                    //font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
                    Material.accent: accentColor
                    maximumLineCount: 2

                }
                Item{
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Rectangle{
                    id:editicon
                    //color:"red"
                    Layout.preferredWidth: app.units(50)

                    Layout.fillHeight: true
                    color:"transparent"
                    visible:index === currentIndex //name === editObject.fieldValue
                    Icon {
                        id: editBtn1
                        Material.elevation: 0
                        maskColor: app.primaryColor//"#4c4c4c"
                        imageSource: "../images/check.png"
                    }

                }

            }

            /* Rectangle{
                width:parent.width
                height:1
                color:app.separatorColor
                anchors.top:rowedit.bottom
            }*/

            MouseArea {
                anchors.fill:parent
                onClicked: {
                    editObject.fieldValue = name
                    if(editObject.fieldValue !== editObject.originalFieldValue)
                        hasEdits = true
                    else
                        hasEdits = false
                    domain_codedValue.currentIndex = getCurrentIndex()


                }
            }
        }

    }

    section {
        property: "category"
        delegate:Pane{
            id: sectionDelegate
            property var isExpanded:false
            clip:true
            height:domain_codedValue.firstSection !== strings.others_text ? (domain_codedValue.firstSection !== section && domain_codedValue.novalueSection !== section ? app.units(106) :app.units(56)): 0
            width:parent.width - 16
            z: app.baseUnit
            leftPadding: 6
            Material.background:"white"
            MouseArea {

                anchors.fill: parent
                enabled:iconrect.visible
                onClicked: {
                    sectionDelegate.toggle()
                }
            }
            ColumnLayout{
                width: parent.width


                Rectangle{
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight: 1
                    color:app.separatorColor

                    opacity: 0.5
                    visible:domain_codedValue.novalueSection !== section
                }



                RowLayout{
                    Layout.fillWidth: parent
                    Layout.preferredHeight:categoryHeader.height


                    ColumnLayout{
                        id:categoryHeader
                        Layout.fillWidth: parent //- 100 * scaleFactor
                        spacing:0

                        Item{
                            Layout.fillWidth:parent
                            Layout.preferredHeight:categoryName.height
                            //color://app.backgroundColor



                            Label {
                                id:categoryName
                                property string fontNameFallbacks: "Helvetica,Avenir"
                                leftPadding: 0//units(6)
                                rightPadding: leftPadding
                                topPadding:units(16)
                                bottomPadding:units(16)
                                horizontalAlignment: Qt.AlignLeft
                                width: parent.width
                                text: section
                                font.pixelSize:app.baseFontSize

                                font {
                                    pointSize: getAppProperty (app.baseFontSize, 14)
                                    family: "%1,%2".arg(baseFontFamily).arg(fontNameFallbacks)
                                }
                                //font.family: titleFontFamily

                                wrapMode: Label.Wrap
                                clip: true
                                color:Qt.darker("#F7F8F8")//app.baseTextColor

                                //color: "black"//getAppProperty(app.baseTextColor, Qt.darker("#F7F8F8"))
                            }
                        }

                    }


                    Item{
                        id:iconrect
                        Layout.preferredWidth: 32 * scaleFactor
                        Layout.preferredHeight: 32 * scaleFactor
                        Layout.alignment: Qt.AlignVCenter
                        visible:domain_codedValue.firstSection !== section && domain_codedValue.novalueSection !== section


                        Icon {
                            id: rightButton
                            objectName: "rightButton"
                            maskColor: "#8D8D8D"
                            imageSource: rightButtonImage
                            rotation: expandedsections.includes(section)?180:0//iconrect.isCollapsed ? 0:180
                            anchors.centerIn: parent
                            onClicked: {
                                sectionDelegate.toggle()
                                // iconrect.isCollapsed = !iconrect.isCollapsed
                            }
                        }

                    }
                }
                Label {
                    id:invalidwarning
                    property string fontNameFallbacks: "Helvetica,Avenir"
                    leftPadding: 0//units(6)
                    rightPadding: leftPadding
                    //topPadding:units(8)
                    bottomPadding:units(16)
                    horizontalAlignment: Qt.AlignLeft
                    Layout.fillWidth:parent
                    text: strings.show_invalid_constraints
                    font.pixelSize:app.baseFontSize
                    //maximumLineCount: 3
                    //elide: Text.ElideRight
                    //wrapMode:Text.WordWrap
                    visible:expandedsections.includes(section)
                    Layout.preferredHeight: visible ? implicitHeight : 0


                    /*font {
                        pointSize: getAppProperty (app.baseFontSize, 14)
                        family: "%1,%2".arg(baseFontFamily).arg(fontNameFallbacks)
                    }*/

                    wrapMode: Label.Wrap
                    //clip: true
                    color:Qt.darker("#F7F8F8")//app.baseTextColor


                }

            }


            function toggle () {
                if(expandedsections.includes(section))
                {
                    collapseSection(sectionPropertyAttr, section, false)
                    var filtered = expandedsections.filter(item => item !== section)
                    expandedsections = filtered
                }
                else
                {
                    expandSection(sectionPropertyAttr, section, true)
                    expandedsections.push(section)
                }


            }

        }



    }


    Component.onCompleted: {
        //console.log("refreshed")


    }
    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }

}
