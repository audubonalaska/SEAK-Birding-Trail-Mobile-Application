import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3



Item {
    id: root

    property alias properties: textField
    property real defaultMargin: app.units(16)
    property var lineCount:1

    signal accepted ()
    signal closeButtonClicked ()
    signal backButtonPressed()

    TextField {
        id: textField

        inputMethodHints: Qt.ImhNoPredictiveText


        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            right: closeBtn.left
            //rightMargin: root.defaultMargin
        }
        selectByMouse: true
        bottomPadding: topPadding
        background: Rectangle {
            color: "transparent"
            border.color: "transparent"
        }
        horizontalAlignment: Text.AlignLeft

        onAccepted: {
            root.accepted()
        }

        Keys.onReleased: {
            if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                event.accepted = true
                backButtonPressed ()
            }
        }
    }

    Icon {
        id: closeBtn

        imageSource: "../images/close.png"
        visible: textField.text > ""
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
        }
        maskColor: app.subTitleTextColor

        onClicked: {
            closeButtonClicked()
            textField.text = ""
        }
        width: app.units(40)
        height: app.units(40)
    }

    Label {
        id: placeholder

        width: textField.width
        text: textField.placeholderText
        anchors {
            left: parent.left
            right: closeBtn.left
        }
        leftPadding: textField.leftPadding
        rightPadding: textField.rightPadding
        topPadding: textField.topPadding
        bottomPadding: textField.bottomPadding
        color: textField.color
        opacity: 0.5
        anchors.verticalCenter: textField.verticalCenter
        font.pixelSize: textField.font.pixelSize
        horizontalAlignment: Label.AlignLeft

    }

    states: [
        State {
            name: "FOCUSSED"
            when: textField.focus || textField.text > ""

            PropertyChanges {
                target: placeholder
                visible: false
            }
        }
    ]
}
