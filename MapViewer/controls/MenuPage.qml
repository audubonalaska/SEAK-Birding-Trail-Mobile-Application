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
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

Drawer {
    id: root

    property var menuItems: []
    property real defaultMargin: root.getAppProperty(app.defaultMargin, root.units(16))
    property real delegateHeight: root.units(56)
    property real iconSize: root.units(16)
    property color backgroundColor: "white"
    property color highlightColor: Qt.darker(root.getAppProperty(app.backgroundColor, "#F7F8F8"), 1.1)
    property color textColor: root.getAppProperty(app.baseTextColor, "#F7F8F8")
    property color primaryColor: root.getAppProperty(app.primaryColor, "#166DB2")
    property color iconColor: "#4C4C4C"

    property bool isCompact: false
    property bool showUserDetail: false

    property real fontScale: 1.0
    property real controlsFontSize: 16
    property string fontFamilyName: ""

    property QtObject contentHeader

    signal menuItemSelected (string itemLabel)

    edge: app.isLeftToRight ? Qt.LeftEdge : Qt.RightEdge
    Material.background: "yellow"//root.backgroundColor
    width: parent.width
    height: parent.height
    padding: 0

    contentItem: BasePage {
        id: menu

        padding: 0
        anchors {
            fill: parent
            margins: 0
        }
        Material.background:"white"

        contentItem: Pane {
            padding: 0
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            ColumnLayout{
                id: sideMenuLayout
                width: parent.width
                height:parent.height
                spacing: 0


                UserProfileSection {
                    visible:showUserDetail
                    onClickSignIn: {

                        sideMenu.close();
                        app.focus = true;
                        if(app.clientId || app.isIWAorPKI)
                        {
                            app.isWebMapsLoaded = false;
                            app.isMMPKsLoaded = false;
                            app.createSignInPage()
                        }
                        else
                            messageDialog.show(qsTr("Missing Client ID"),qsTr("ArcGIS Client ID is missing. Please upload your app and go to Settings > Licensing to register a Client ID."))
                    }

                    onClickSignOut: {
                        app.signOut();
                        app.isMMPKsLoaded = false;
                        app.isWebMapsLoaded = false;
                        close();
                    }
                }

                ListView {
                    id: menuView

                    clip: true
                    spacing: 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    interactive:false
                    model: menuModel

                    header: root.contentHeader

                    delegate: Card {
                        id: menuItem

                        headerHeight: 0
                        footerHeight: 0
                        padding: 0
                        borderColor: backgroundColor
                        clickable: !control.length
                        highlightColor: root.highlightColor
                        backgroundColor: root.backgroundColor
                        height: root.delegateHeight * fontScale
                        propagateComposedEvents: false
                        preventStealing: false
                        Material.elevation: 0
                        width: Math.min(menuView.width, root.units(600))

                        content: Pane {
                            anchors.fill: parent
                            leftPadding: app.isLeftToRight ? app.widthOffset : root.defaultMargin
                            rightPadding: app.isLeftToRight ? root.defaultMargin : app.widthOffset
                            width: parent.width
                            height: parent.height
                            topPadding: 0
                            bottomPadding: 0

                            LayoutMirroring.enabled: !app.isLeftToRight
                            LayoutMirroring.childrenInherit: !app.isLeftToRight
                            RowLayout {
                                id: itemRow

                                anchors.fill: parent
                                spacing: 0

                                Item{
                                    Layout.fillHeight: true
                                    Layout.preferredWidth:app.units(16)
                                }

                                BaseText {
                                    id: label

                                    text: itemLabel
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.preferredWidth: {
                                        var controlWidth = control === "switch" ? switchControl.width : (control === "spinBox" ? spinBox.width : 0)
                                        return parent.width - controlWidth - app.units(16)
                                    }

                                    color: root.textColor
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    horizontalAlignment: Label.AlignLeft
                                    Layout.alignment: Qt.AlignLeft
                                }

                                CustomSwitch {
                                    id: switchControl

                                    size: 0.8 * iconSize
                                    opacity: control === "switch" ? 1 : 0
                                    visible: !spinBox.visible
                                    primaryColor: root.primaryColor
                                    backgroundColor: root.backgroundColor
                                }

                                SpinBox {
                                    id: spinBox

                                    visible: control === "spinBox"
                                    from: app.isDesktop?100:80
                                    Layout.maximumWidth: 0.40 * parent.width
                                    to:app.isDesktop?140:120
                                    stepSize: isCompact ? 10 : 20
                                    value: fontScale * 100
                                    font.family: fontFamilyName
                                    font.pointSize: root.controlsFontSize

                                    textFromValue: function(value, locale) {
                                        return value + "%"
                                    }

                                    valueFromText: function(text, locale) {
                                        return Number.fromLocaleString(locale, text.replace("%", ""))
                                    }

                                    onValueChanged: {
                                        fontScale = value/100


                                    }

                                    contentItem: Text {
                                        z: 8
                                        text: qsTr("%L1\%").arg(spinBox.value)
                                        font: spinBox.font
                                        fontSizeMode: Text.Fit
                                        elide: Text.ElideRight
                                        color: root.textColor
                                        horizontalAlignment: Qt.AlignHCenter
                                        verticalAlignment: Qt.AlignVCenter
                                        anchors.centerIn: parent
                                        width: spinBox.width - (upButton.width + downButton.width)
                                        minimumPointSize: 1
                                    }

                                    up.indicator: Rectangle {
                                        id: upButton

                                        x: spinBox.mirrored ? 0 : parent.width - width
                                        height: parent.height
                                        implicitWidth: units(32)
                                        implicitHeight: units(32)
                                        color: "transparent"
                                        border.color: Qt.darker(root.backgroundColor, 1.1)

                                        Text {
                                            text: "+"
                                            font.pixelSize: spinBox.font.pixelSize * 2
                                            color: enabled ? root.textColor : Qt.lighter(root.textColor, 3.0)
                                            anchors.fill: parent
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    down.indicator: Rectangle {
                                        id: downButton

                                        x: spinBox.mirrored ? parent.width - width : 0
                                        height: parent.height
                                        implicitWidth: units(32)
                                        implicitHeight: units(32)
                                        color: "transparent"
                                        border.color: Qt.darker(root.backgroundColor, 1.1)

                                        Text {
                                            text: "-"
                                            font.pixelSize: spinBox.font.pixelSize * 2
                                            color:  enabled ? root.textColor : Qt.lighter(root.textColor, 3.0)
                                            anchors.fill: parent
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    background: Rectangle {
                                        implicitWidth: units(140)
                                        border.color: Qt.darker(root.backgroundColor, 1.1)
                                    }
                                }
                            }


                            Rectangle {
                                width: root.width
                                height: app.units(1)
                                color: "#EAEAEA"
                                visible:index !== menuModel.count
                            }
                        }

                        onClicked: {
                            if (!control.length) {
                                menuItemSelected(itemLabel)
                            }
                        }
                    }
                }
            }
            ListModel {
                id: menuModel
            }
        }
    }

    onMenuItemSelected: {
        close()
    }

    onVisibleChanged: {
        menuModel.clear()
        if (visible) {
            updateMenu()
        }
    }

    function updateMenu () {
         menuModel.clear()
        for (var i=0; i<root.menuItems.length; i++) {
            menuModel.append(root.menuItems[i])
        }
    }

    function toggle () {
        return visible ? close () : open ()
    }

    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }

    function appendItemsToMenuList (items) {
        root.menuItems = items.concat(root.menuItems)
    }

    function insertItemToMenuList (idx, item) {
        root.menuItems.splice(idx, 0, item)
    }

    function removeItemsFromMenuListByAttribute (attr, value) {
        var newArr = []
        for (var i=0; i<menuItems.length; i++) {
            if (menuItems[i][attr] !== value) {
                newArr.push(menuItems[i])
            }
        }
        menuItems = newArr
    }

    function removeItemsFromMenuListByString (str) {
        var newArr = []
        for (var i=0; i<menuItems.length; i++) {
            var hasString = false
            for (var key in menuItems[i]) {
                if (menuItems[i].hasOwnProperty(key)) {
                    if (key.includes(str) || menuItems[i][key].includes(str)) {
                        hasString = true
                        break
                    }
                }
            }
            if (!hasString) newArr.push(menuItems[i])
        }
        menuItems = newArr
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }
}
