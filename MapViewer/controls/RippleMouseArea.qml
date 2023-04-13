import QtQuick 2.15
import QtGraphicalEffects 1.12
import QtQuick.Controls.Material 2.15
import QtQuick.Controls.Material.impl 2.15

MouseArea {
    id: root

    hoverEnabled: true
    pressAndHoldInterval: 500
    preventStealing: true
    clip: true

    property real radius: parent.radius || 0

    property color color: colors.ripple

    property bool isHovered: false
    property bool rippleEnabled: true

    Item {
        visible: rippleEnabled

        anchors.fill: parent

        Rectangle {
            id: mask

            visible: false

            anchors.fill: parent

            radius: root.radius
            color: colors.white
        }

        Item {
            anchors.fill: parent
            clip: true

            Ripple {
                width: parent.width
                height: parent.height

                anchor: root
                clipRadius: 2 * scaleFactor
                pressed: root.pressed
                active: root.pressed || root.activeFocus || root.isHovered
                color: root.color
            }

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: mask
            }
        }
    }

    onHoverEnabledChanged: {
        if (!hoverEnabled)
            isHovered = false;
    }

    onContainsMouseChanged: {
        if (!containsMouse)
            isHovered = false;
    }

    onEntered: {
        if (hoverEnabled)
            isHovered = true;
    }

    onExited: {
        if (hoverEnabled)
            isHovered = false;
    }

    onCanceled: {
        if (hoverEnabled)
            isHovered = false;
    }
}
