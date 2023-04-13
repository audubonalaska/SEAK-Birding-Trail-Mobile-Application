/*******************************************************************************
 *  Copyright 2012-2018 Esri
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/

import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.15

import "./Controller"

/*!
    \qmltype UserCredentialsView
    \ingroup ArcGISQtToolkit
    \ingroup ArcGISQtToolkitCppApi
    \ingroup ArcGISQtToolkitQmlApi
    \inqmlmodule Esri.ArcGISRuntime.Toolkit.Dialogs
    \since Esri.ArcGISRutime 100.0
    \brief A view for handling username and password authentication challenges.

    When a request is made to access a resource that requires a username and
    password, the AuthenticationView will automatically launch this view. This
    is applicable for:

    \list
      \li ArcGIS Token
      \li HTTP Digest
      \li HTTP Basic
      \li Integrated Windows Authentication (IWA)
    \endlist

    \note In the case of using an IWA secured resource on a Windows system, the
    OS will automatically handle the authentication, and no UI dialog will appear.
*/
Rectangle {
    id: root
    color: "transparent"

    LayoutMirroring.enabled: !app.isLeftToRight
    LayoutMirroring.childrenInherit: !app.isLeftToRight
    /*!
        \brief The AuthenticationChallenge for ArcGIS Token, HTTP Basic, HTTP Digest, and IWA.

        \note If using the AuthenticationView, this is set automatically and
         requires no configuration.
    */
    property AuthenticationController controller: AuthenticationController {}

    property var challenge

    /*! \internal */
    property real displayScaleFactor: (Screen.logicalPixelDensity * 25.4) / (Qt.platform.os === "windows" || Qt.platform.os === "linux" ? 96 : 72)
    /*! \internal */
    property string requestingHost: controller.getAuthenticatingHost()//challenge ? challenge.authenticatingHost : ""
    /*! \internal */
    property string detailText: qsTr("You need to sign in to access the resource at '%1'").arg(requestingHost)

    Keys.onEnterPressed: {
        if (Qt.platform.os !== "android" && Qt.platform.os !== "ios") {
            continueButton.clicked();
        }
    }

    Keys.onReturnPressed: {
        if (Qt.platform.os !== "android" && Qt.platform.os !== "ios") {
            continueButton.clicked();
        }
    }

    RadialGradient {
        anchors.fill: parent
        opacity: 0.7
        gradient: Gradient {
            GradientStop { position: 0.0; color: "lightgrey" }
            GradientStop { position: 1.0; color: "black" }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mouse.accepted = true
        onWheel: wheel.accepted = true
    }

    Rectangle {
        anchors {
            centerIn: parent
        }
        width: app.width>300?300:parent.width
        height:parent.height>300?300:parent.height
        color: "white"
        smooth: true
        clip: true
        antialiasing: true

        Column {
            id: controlsColumn
            anchors {
                fill:parent
                centerIn: parent
                margins: app.defaultMargin
            }
            spacing: 5*scaleFactor


            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Sign In")
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: 20* scaleFactor
                font.family: app.baseFontFamily
            }

            Rectangle {
                color: "#FFCCCC"
                radius: 5
                width: parent.width
                anchors.margins: 10 * displayScaleFactor
                height: 20 * displayScaleFactor
                visible: challenge ? challenge.failureCount > 1 : false

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Invalid username or password.")
                    font {
                        pixelSize: 12 * displayScaleFactor
                        family: "sanserif"
                    }
                    color: "red"
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: detailText
                width: parent.width
                wrapMode: Text.Wrap
                color: "black"
                font.pixelSize: 12 * scaleFactor
                font.family: app.baseFontFamily
            }

            TextField {
                id: usernameTextField
                width: parent.width
                placeholderText: qsTr("username")
                selectByMouse: true
                font.pixelSize: 14 * scaleFactor
                font.family: app.baseFontFamily
                Material.accent: app.primaryColor
            }

            TextField {
                id: passwordTextField
                width: parent.width
                placeholderText: qsTr("password")
                echoMode: TextInput.Password
                selectByMouse: true
                font.pixelSize: 14 * scaleFactor
                font.family: app.baseFontFamily
                Material.accent: app.primaryColor
            }
        }

        RowLayout {
            width: Math.min(parent.width, contentChildren.width)
            height: contentChildren.height
            anchors.right: parent.right
            anchors.rightMargin: 16 * app.scaleFactor
            anchors.bottom: parent.bottom

            Button {
                //width: ((parent.width / 2) - displayScaleFactor)
                text: qsTr("CANCEL")
                enabled: !busyIndicator.visible
                Material.background: "transparent"
                Material.foreground: primaryColor
                onClicked: {
                    // cancel the challenge and let the resource fail to load
                    if (challenge)
                        challenge.cancel();
                    root.visible = false;
                }
            }

            Button {
                id: continueButton
                width: ((parent.width / 2) - displayScaleFactor)
                text: qsTr("OK")
                enabled: !busyIndicator.visible
                Material.background: "transparent"
                Material.foreground: primaryColor
                onClicked: {
                    Qt.callLater(controller.continueWithUsernamePassword,usernameTextField.text,passwordTextField.text);
                    busyIndicator.visible = true
                }
            }
        }
    }

    function reject()
    {
        root.visible = false;
    }

}
