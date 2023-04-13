import QtQuick 2.5
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import "../controls" as Controls


ItemDelegate {
    id: searchResultsDelegate

    property string title: ""
    property string description: ""
    property real expandBtnWidth: app.units(40)
    property int currentIndex: ListView.view.currentIndex
    property bool showNavigationIcon: hasNavigationInfo
    LayoutMirroring.enabled: !app.isLeftToRight
    LayoutMirroring.childrenInherit: !app.isLeftToRight
    signal clicked ()
    height: showInView ? (separatorRect.visible ? app.units(66) + separatorRect.height : app.units(66)):(separatorRect.visible ? separatorRect.height:0)
    width: ListView.view.width
    visible: !heightAnimation.running
    topPadding: index === 0 ? app.baseUnit : 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    ButtonGroup.group: listView.buttonGroup

    Behavior on height {
        NumberAnimation {
            id: heightAnimation
            duration: 200
        }
    }



    Controls.Card {
        id: card

        headerHeight: 0
        footerHeight: 0
        padding: 0
        anchors.fill: parent
        highlightColor: Qt.darker(app.backgroundColor, 1.1)
        backgroundColor: "#FFFFFF"
        hoverAllowed: false // disable hover since it is interferring with the radiodelegate's ability to selectively highlight
        checked: searchResultsDelegate.checked || listView.model.currentIndex === initialIndex

        propagateComposedEvents: false
        Material.elevation: 0
        visible: showInView

        content: Pane {
            anchors.fill: parent
            rightPadding: app.isLeftToRight ? app.defaultMargin : (navigationIcon.visible ? 0 : (1/2) * app.baseUnit)
            leftPadding: app.isLeftToRight ? (navigationIcon.visible ? 0 : (1/2) * app.baseUnit) : app.defaultMargin
            topPadding: 0
            bottomPadding: 0

            Row {
                anchors {
                    fill: parent
                    leftMargin: app.baseUnit
                    rightMargin: app.baseUnit
                }
                spacing: 0.8 * app.baseUnit

                ColumnLayout {
                    id: navigationIcon

                    visible: showNavigationIcon
                    width: Math.min(parent.height, app.units(40))
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0.5 * app.baseUnit

                    Image {
                        visible:distance && !distance.startsWith("100+")
                        Layout.preferredWidth: 0.4 * app.iconSize
                        Layout.preferredHeight: width
                        Layout.alignment: Qt.AlignHCenter
                        source: "../images/navigation.png"
                        rotation: navigationIcon.visible ? degrees : 0
                        opacity: 0.4
                        mipmap: true
                    }

                    Controls.BaseText {
                        text: navigationIcon.visible ? distance : ""
                        Layout.preferredWidth: parent.width
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.pointSize: 0.8 * desc.font.pointSize
                        opacity: 0.5
                    }
                }


                ColumnLayout {

                    //height: parent.height
                    width: navigationIcon.visible ? parent.width - navigationIcon.width : parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Controls.BaseText {
                        id: label

                        text: title
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        Layout.preferredWidth: parent.width
                        //Layout.preferredHeight: desc.text > "" ? (desc.lineCount > 1 ? (1/3) * parent.height : (1/2) * parent.height) : parent.height
                        //verticalAlignment:Text.AlignVCenter //desc.text > "" ? Text.AlignBottom : Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                    }
                    Item{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                    }

                    Controls.BaseText {
                        id: desc

                        text: description
                        maximumLineCount: 2
                        font.pointSize: app.textFontSize
                        elide: Text.ElideRight
                        //Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: parent.width
                        visible: desc.text > ""
                        opacity: 0.7
                        // Layout.preferredHeight: desc.text > "" ? (lineCount > 1 ? (2/3) * parent.height : (1/2) * parent.height) : parent.height
                        //verticalAlignment:Text.AlignVCenter //lineCount > 1 ? Text.AlignVCenter : Text.AlignTop
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }
        }

        onClicked: {
            searchResultsDelegate.clicked()
            searchResultsDelegate.checked = true
        }
    }


    Rectangle {
        id:separatorRect
        visible:listView.model.count > index + 1 && listView.model.get(index).layerName !==  listView.model.get(index + 1).layerName

        width: parent.width
        height: visible?app.units(8):0
        color: "#F4F4F4"//app.separatorColor

        opacity: 0.5
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

    }
    Rectangle {
        id:separatorRect1
        visible:!separatorRect.visible && listView.model.count > index + 1 && listView.model.get(index).layerName ===  listView.model.get(index + 1).layerName//index !== mapView.featuresModel.count - 1  //&& parent.height
        width: sectionPropertyAttr > ""? parent.width - app.defaultMargin :parent.width
        height: visible?app.units(1):0
        color: app.separatorColor
        opacity: 0.5
        anchors {
            bottom:separatorRect.bottom
            horizontalCenter: parent.horizontalCenter
        }
    }
    Rectangle {
        id:separatorRect2
        visible:separatorRect.visible
        width: parent.width
        height: visible?app.units(1):0
        color: app.separatorColor
        opacity: 0.5
        anchors {
            bottom:separatorRect.top
            horizontalCenter: parent.horizontalCenter
        }
    }

    onClicked: {
        ListView.view.currentIndex = index
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
        onClicked: card.clicked()
    }
}
