import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0
//import Esri.ArcGISRuntime 100.14

import "../controls" as Controls

Item{

    id:sectionItem
    width:parent.width
    height:40 * scaleFactor

    signal checked (bool checked)

    RowLayout{
        anchors {
            fill: parent
            leftMargin:0
            rightMargin: 0.5 * app.defaultMargin
        }


        spacing:0

        CheckBox {
            id: chkBox

            checkState:sectionItem.getCheckedValue(section)

            Material.accent: app.accentColor//root.accentColor
            Material.primary: app.primaryColor//root.primaryColor
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Material.theme:Material.Light

            onClicked: {

              /*  if(checked)
                    checkState = Qt.Checked
                else
                    checkState = Qt.Unchecked*/

                rootLayerSelected(section,checked)

                valueChanged = true
                sectionItem.checked(checked)

            }
            onCheckStateChanged:{


            }

            Connections{
                target:spatialsearchView
                function onLegendSelected(layerName,name,checked)
                {
                    if(layerName === section)
                    {
                        if(itemClicked === "")
                            chkBox.checkState = sectionItem.getCheckedValue(section)
                        else

                            chkBox.checkState = sectionItem.setCheckedValue(section)

                    }
                }

                function onResetLegend(isValueChanged)
                {
                    chkBox.checkState = sectionItem.getCheckedValue(section)
                }


            }

        }

        Controls.BaseText {
            //id: lbl

            objectName: "label"
            text: section
            Layout.fillWidth: true
            Layout.preferredHeight: 40 * scaleFactor
            elide: Text.ElideRight
            wrapMode:Label.Wrap

            horizontalAlignment: Label.AlignLeft
            verticalAlignment: Label.AlignVCenter
            color:"#6A6A6A"
            fontsize: 12 * scaleFactor
            Layout.leftMargin: 0
            maximumLineCount: 2
            Layout.alignment: Qt.AlignVCenter
            //clip: true

        }

        Item{

            Layout.preferredWidth: 16 * scaleFactor
            Layout.fillHeight: true

        }


    }

    function computeTextWidth (maxWidth, parentItem) {
        var textWidth = maxWidth,
        ommit = ["label", "spaceFiller", "ink"]
        for (var i=0; i<parentItem.children.length; i++) {
            if (ommit.indexOf(parentItem.children[i].objectName) === -1 && parentItem.children[i].visible) {
                textWidth -= parentItem.children[i].width
            }
        }
        return textWidth - app.defaultMargin
    }

    function setCheckedValue(displayName)
    {
        var isChecked = Qt.Checked
        var uncheckCount = 0
        var nolegend = 0
        for(var k=0;k<spatialsearchView.model.count; k++)
        {
            var item = spatialsearchView.model.get(k)
            if(item.displayName === displayName)
            {
                nolegend +=1
                if(item.name > "" && item.name !== "<all other values>" && item.isSelected)
                {

                    uncheckCount +=1

                }
                else
                {
                    if(item.name === "<all other values>" || item.name === "")
                        nolegend -=1
                }

            }

        }
        if(uncheckCount === nolegend)
            isChecked = Qt.Unchecked
        else if ((nolegend - uncheckCount) < nolegend)
            isChecked = Qt.PartiallyChecked


        return isChecked



    }


    function getCheckedValue(displayName)
    {
        var isChecked = Qt.Checked

        var uncheckCount = 0

        var nolegend = 0
        if(spatialsearchView.model.count > 0){
            for(var k=0;k<spatialsearchView.model.count; k++)
            {
                var item = spatialsearchView.model.get(k)
                if(item.displayName === displayName)
                {
                    nolegend +=1
                    if(item.name > "" && item.name !== "<all other values>" && !item.isSelected)
                    {
                        uncheckCount +=1

                    }
                    else
                    {
                        if(item.name === "<all other values>" || item.name === "")
                            nolegend -=1
                    }

                }

            }
            if(uncheckCount === 0 && nolegend === 0)
            {

                if(spatialsearchView.model.count > 0){

                    for(var k1=0;k1<spatialsearchView.model.count; k1++)
                    {
                        var item1 = spatialsearchView.model.get(k1)

                        if(item1.displayName === displayName)
                        {

                            if(!item1.isSelected)
                                isChecked = Qt.Unchecked
                            break


                        }
                    }
                }
                else
                {
                    for(var k2=0;k2<legendManager.unOrderedLegendInfos.count; k2++)
                    {
                        var item2 = legendManager.unOrderedLegendInfos.get(k2)

                        if(item2.displayName === displayName)
                        {

                            if(!item2.isSelected)
                                isChecked = Qt.Unchecked
                            break


                        }
                    }

                }


            }
            else
            {

                if(uncheckCount > 0 && uncheckCount === nolegend)
                    isChecked = Qt.Unchecked
                else if ((nolegend - uncheckCount) < nolegend)
                    isChecked = Qt.PartiallyChecked
            }
        }
        return isChecked

    }



}
