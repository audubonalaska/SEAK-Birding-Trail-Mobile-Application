import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root

    radius: width / 2
    color: colors.transparent

    property alias buttonText: label.text
    property alias textColor: label.color

    property bool preventStealing: false

    signal clicked()

    Label {
        id: label

        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        padding: 0

        //font.family: fonts.demi_fontFamily
        font.pixelSize: 14 * scaleFactor
        font.bold: true
        font.letterSpacing: 0.75 * scaleFactor

        horizontalAlignment: Label.AlignHCenter
        verticalAlignment: Label.AlignVCenter
        elide: Label.ElideMiddle
    }

    RippleMouseArea {
        enabled: root.enabled
        hoverEnabled: app.isDesktop

        anchors.fill: parent

        radius: parent.radius

        preventStealing: root.preventStealing

        onClicked: {
            root.clicked();
        }
    }
}
