import QtQuick 2.4
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.1



Flickable
{
    id:root
    anchors.fill: parent
    clip: true
    boundsBehavior:Flickable.StopAtBounds
    contentWidth:maxWidth//accorCol.width
    contentHeight: accorCol.height
    property string fontNameFallbacks: "Helvetica,Avenir"
    property alias model: columnRepeater.model
    readonly property color maskColor: "transparent"
    property int maxWidth:0

    signal zoomTo (string lyrname,string identificationIndex)
    signal checked (string lyrname,bool checked,string identificationIndex)

    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }


    ColumnLayout {
        id:accorCol
        width:Math.max(maxWidth,implicitWidth)
        anchors.left:parent.left

        Repeater {
            id: columnRepeater
            delegate: tree
        }

        Component {
            id: tree

            ColumnLayout {
                Layout.preferredWidth:childrenRect.width
                Layout.alignment: Qt.AlignLeft
                signal collapsed()

                function collapseList()
                {
                    subentryColumn.collapseList()
                    infoRow.expanded = false
                }

                spacing:0


                Item{
                    id:treeItem
                    Layout.preferredHeight: app.units(33)//app.units(43)//35
                    Layout.preferredWidth:childrenRect.width
                    Layout.alignment: Qt.AlignLeft
                    //color:"yellow"
                    property string childname:""
                    property string parentname:""
                    property string _text:name
                    property alias childItem: subentryColumn

                    function disableMouseArea()
                    {
                        _mousearea.enabled = false
                    }

                    MouseArea {
                        id:_mousearea

                        anchors.fill: parent
                        onClicked: {
                            mouse.accepted = true

                            if(treeItem.childItem.opacity === 0)
                                infoRow.expanded = !infoRow.expanded
                            else
                            {
                                treeItem.childItem.collapseList()

                            }

                        }

                    }


                    RowLayout {
                        id: infoRow
                        width:root.maxWidth
                        height:parent.height
                        property bool expanded:columnRepeater.model.count === 1 ? true : false
                        //property bool expanded:columnRepeater.model.count === 1 && lyrIdentificationIndex.split(',').length === 1? true : false
                        property alias _checkbox:chkBox
                        anchors.left:parent.left
                        spacing:0


                        Rectangle{
                            Layout.preferredWidth: lyrIdentificationIndex.split(',').length === 1 ? 8 : 16 * lyrIdentificationIndex.split(',').length
                            Layout.fillHeight: true
                            //color:"red"
                        }

                        Rectangle{
                            id:carotRect
                            Layout.preferredWidth: app.units(36)
                            Layout.preferredHeight: app.units(24)

                           // Layout.fillHeight: true
                            // color:"yellow"
                            Image {
                                id: carot
                                width:app.units(24)
                                height:app.units(24)
                                anchors.centerIn: parent
                                source: '../images/carot_600_48dp.png'

                                mipmap: true

                                transform: Rotation {
                                    origin.x: app.units(12)
                                    origin.y: app.units(12)
                                    angle:app.isLeftToRight ?(infoRow.expanded ? 0 : -90) :(infoRow.expanded ? 0 : 90) //infoRow.expanded ? 0 : -90
                                    Behavior on angle { NumberAnimation { duration: 150 } }
                                }

                            }

                            ColorOverlay {

                                anchors.fill: carot
                                source: carot
                                color: Qt.darker("#F7F8F8")
                                smooth: true
                                antialiasing: true
                                transform: Rotation {
                                    origin.x:app.units(12)
                                    origin.y:app.units(12)

                                    angle: app.isLeftToRight ?(infoRow.expanded ? 0 : -90) :(infoRow.expanded ? 0 : 90)
                                    Behavior on angle { NumberAnimation { duration: 150 } }
                                }


                            }
                        }

                        CheckBox{
                            id: chkBox
                            checked:checkBox
                            visible: legendItems.count === 0 ? true :layerType !== 4
                            Material.theme:Material.Light
                            Material.accent: Qt.lighter(app.primaryColor)
                            Layout.leftMargin:-8

                            onClicked: {

                                checkBox = checked
                                root.checked(name,checked, lyrIdentificationIndex)

                            }
                        }

                        Item{
                            Layout.preferredWidth:!chkBox.visible?app.fontScale * 0.3 * app.iconSize:0
                            Layout.preferredHeight: !chkBox.visible?app.fontScale * 0.3 * app.iconSize:0
                            Image {
                                id: layerimage
                                sourceSize.width: app.fontScale * 0.3 * app.iconSize
                                sourceSize.height: app.fontScale * 0.3 * app.iconSize
                                source: "images/layer.png"
                                asynchronous: true
                                smooth: true
                                fillMode: Image.PreserveAspectCrop
                                mipmap:true
                                visible: !chkBox.visible


                            }

                            ColorOverlay{

                                Layout.fillHeight: true
                                source: layerimage
                                color: maskColor
                                visible: !chkBox.visible

                            }

                        }

                        Rectangle{
                            Layout.fillWidth:true
                            Layout.fillHeight: true
                            //color:"red"
                            Text {

                                font.pointSize: 12
                                visible: parent.visible
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignLeft
                                width:parent.width
                                LayoutMirroring.enabled:app.isLeftToRight ? false:true

                                text: name
                                elide:Text.ElideRight
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                maximumLineCount: 4

                                color: isVisibleAtScale ? root.getAppProperty(app.baseTextColor, "#F7F8F8") : "#D3D3D3"
                                font {
                                    pointSize: root.getAppProperty (app.baseFontSize, 14)
                                    family: "%1,%2".arg(baseFontFamily).arg(fontNameFallbacks)
                                }


                            }

                        }

                        Rectangle{
                            Layout.preferredWidth:16
                            Layout.fillHeight: true
                            // color:"blue"
                        }


                        Rectangle{
                            id:zoomRect
                            Layout.preferredWidth: app.units(60)

                            Layout.fillHeight: true
                            visible:legendItems && legendItems.count > 0
                            //Layout.leftMargin: 16
                            Material.elevation: 99
                            //color:"yellow"

                            Image {
                                id: zoomicon
                                width:24
                                height: 24
                                anchors.centerIn: parent
                                source: '../images/ic_magnify_plus_outline_white_48dp.png'
                                mipmap: true

                            }

                            ColorOverlay {

                                anchors.fill: zoomicon
                                source: zoomicon
                                color: Qt.darker("#F7F8F8")
                                smooth: true
                                antialiasing: true


                            }
                            MouseArea{
                                anchors.fill:parent
                                onClicked: {
                                    zoomTo(name,lyrIdentificationIndex)

                                }
                            }
                        }

                    }


                }

                //add legend here
                RowLayout {
                    id: rendererFieldRow
                    Layout.preferredWidth: legcontent.width
                    Layout.preferredHeight: rendererField  && infoRow.expanded ? app.units(33) :0
                    Layout.leftMargin: 20 * lyrIdentificationIndex.split(',').length
                    Item{
                     Layout.preferredWidth: app.units(64)
                     Layout.fillHeight: true
                    }

                    Item{
                         Layout.fillWidth:true
                        //Layout.preferredWidth: legcontent.width
                        Layout.preferredHeight: parent.height//rendererField  && infoRow.expanded ? app.units(43) :0
                        visible:infoRow.expanded

                        Text {
                            font.pointSize: 12
                            visible: parent.visible
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignLeft
                            width:parent.width
                            LayoutMirroring.enabled:!app.isRightToLeft ? false:true
                            text: rendererField
                            elide:Text.ElideRight
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 4
                            color: isVisibleAtScale ? root.getAppProperty(app.baseTextColor, "#F7F8F8") : "#D3D3D3"
                            font {
                                pointSize: root.getAppProperty (app.baseFontSize, 14)
                                family: "%1,%2".arg(baseFontFamily).arg(fontNameFallbacks)
                            }
                        }
                    }
                }


                ListView{
                    id:legcontent
                    Layout.fillWidth: true
                    Layout.preferredHeight:infoRow.expanded ? getHeight():0
                    model: legendItems && legendItems.count > 0 ? legendItems : null
                    Layout.leftMargin: 20 * lyrIdentificationIndex.split(',').length
                    Layout.rightMargin: 16
                    Layout.topMargin: height > 0 ?16 :0
                    Layout.bottomMargin:infoRow.expanded? 0:16
                    interactive:false
                    boundsBehavior:Flickable.StopAtBounds
                    opacity: infoRow.expanded ? 1 : 0
                    clip: true
                    delegate:Rectangle {
                        id:legendrow

                        color: "transparent"
                        visible: symbolUrl && symbolUrl.toString().length > 1 ? true : false
                        anchors.bottomMargin: 16

                        height:visible ? 48:0

                        width: legcontent.width
                        RowLayout{
                            width:parent.width

                            spacing:16


                            Image {
                                id: img
                                Layout.preferredWidth:0.6 * units(48)
                                Layout.preferredHeight:0.6 * units(48)
                                fillMode: Image.PreserveAspectFit
                                source: symbolUrl
                                Layout.leftMargin: 60

                            }


                            Text {
                                id:legtxt
                                horizontalAlignment: Text.AlignLeft
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth:legcontent.width - img.width - 80//parent.width - img.width
                                visible: parent.visible
                                elide:Text.ElideMiddle
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                font.pointSize: 12
                                //color: 'white'
                                text: legendName
                                font {
                                    pointSize: root.getAppProperty (app.baseFontSize, 14)
                                    family: "%1,%2".arg(baseFontFamily).arg(fontNameFallbacks)
                                }

                            }
                            TextMetrics {
                                id:     t_metrics
                                font:   legtxt.font
                                text:   legtxt.text
                            }
                        }
                    }



                    function getHeight()
                    {
                        let _ht = 0
                        for(let i=0;i<legcontent.contentItem.children.length-1;i++){
                            _ht +=legcontent.contentItem.children[i].height
                        }

                        return (_ht - 16)
                    }
                }

                ListView {
                    id: subentryColumn
                    x: app.units(20)
                    Layout.preferredWidth:contentItem.childrenRect.width
                    Layout.preferredHeight: childrenRect.height * opacity
                    //Layout.topMargin: 8
                    visible: opacity > 0
                    opacity: infoRow.expanded ? 1 : 0
                    delegate: tree
                    model: _children && _children.count > 0 ? _children : null
                    interactive: false
                    boundsBehavior:Flickable.StopAtBounds
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    property var _parent:treeItem
                    signal collapse()

                    function collapseList()
                    {

                        infoRow.expanded = false
                        if(_children){
                            if(_children.count === 0)
                                infoRow.expanded = false
                            else
                            {
                                for (var k=0;k<_children.count; k++)
                                {
                                    let _child = subentryColumn.itemAtIndex(k)
                                    if(_child)
                                        _child.collapseList()

                                }

                            }


                        }
                    }
                }
            }
        }
    }

}
