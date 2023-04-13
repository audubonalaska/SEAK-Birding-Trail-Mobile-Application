import QtQuick 2.5
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import "../controls" as Controls


ItemDelegate {
    id: spatialSearchResultsDelegate
    // property var _index : 0
    property string title: ""
    property string description: ""
    property real expandBtnWidth: app.units(40)
    property int currentIndex: ListView.view.currentIndex
    //property bool showNavigationIcon: hasNavigationInfo
    LayoutMirroring.enabled: !app.isLeftToRight
    LayoutMirroring.childrenInherit: !app.isLeftToRight
    signal clicked ()
    //height:showInView ? app.units(56) : 0
    height: showInView ? (separatorRect.visible ? app.units(82) : app.units(66)):(separatorRect.visible ? 16:0)
    width: ListView.view.width
    visible: !heightAnimation.running
    topPadding: index === 0 ? app.baseUnit : 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    //ButtonGroup.group: listView.buttonGroup

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
        //checked:spatialSearchResultsDelegate.checked //|| listView.model.currentIndex === initialIndex
        clickable: true
        visible: showInView
        propagateComposedEvents: false
        Material.elevation: 0

        content: Pane {
            anchors.fill: parent
            rightPadding:app.defaultMargin //app.isLeftToRight ? app.defaultMargin : (navigationIcon.visible ? 0 : (1/2) * app.baseUnit)
            leftPadding: 6 * scaleFactor
            topPadding: 0
            bottomPadding: 0



            Controls.BaseText {
                id: label

                text: title
                maximumLineCount: 1
                elide: Text.ElideRight
                width: parent.width
                height: 66 * scaleFactor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 12 * scaleFactor
            }


        }

        onClicked: {
            spatialSearchResultsDelegate.clicked()
            spatialSearchResultsDelegate.checked = index === currentIndex
        }
    }

    //

     Rectangle {
        id:separatorRect
        visible:resultsListView.model.count > 0 ?(resultsListView.model.count > index + 1 && resultsListView.model.get(index).layerName !==  listView.model.get(index + 1).layerName):false//index !== mapView.featuresModel.count - 1  //&& parent.height
        //width: sectionPropertyAttr > ""? parent.width - app.defaultMargin :parent.width
        width: parent.width
        height: visible?app.units(16):0
        color: "#F4F4F4"//app.separatorColor
        opacity: 0.5
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
    }


    Rectangle {
     visible:resultsListView.model.count > 0 ?(!separatorRect.visible && resultsListView.model.count > index + 1 && resultsListView.model.get(index).layerName ===  resultsListView.model.get(index + 1).layerName): false//index !== mapView.featuresModel.count - 1  //&& parent.height

        //visible: index && parent.height
        width: parent.width - app.defaultMargin
        height: app.units(1)
        color: app.separatorColor
        opacity: 0.5
        anchors {
            bottom: parent.bottom
            right:parent.right

        }



    }

    Rectangle {
        id:separatorRect2
        visible:separatorRect.visible//!separatorRect.visible && listView.model.count > index + 1 && listView.model.get(index).layerName ===  listView.model.get(index + 1).layerName//index !== mapView.featuresModel.count - 1  //&& parent.height
        width: parent.width//sectionPropertyAttr > ""? parent.width - app.defaultMargin :parent.width
        height: visible?app.units(1):0
        color: app.separatorColor
        opacity: 0.5
        anchors {
            bottom:separatorRect.top //parent.bottom
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

