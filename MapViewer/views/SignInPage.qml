import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

import Esri.ArcGISRuntime 100.14

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Authentication 1.0

import "../controls" as Controls
import "./Controller"

Controls.PopupPage {
    id: signInPage

    property string portalUrl: ""
    property string clientId: ""
    property bool closeButtonClicked: false
    property Portal portal // Takes a secured portal i.e. A portal that has a Credential object. This is the only way an authentication challenge is created
    property real iconSize: 48
   // property bool isSignedIn: portal ? portal.loadStatus === Enums.LoadStatusLoaded && (forceSignIn || portal.credential.token > "" ): false
     property bool isSignedIn: portal ? portal.loadStatus === Enums.LoadStatusLoaded && (portal.credential && portal.credential.username > ""): false

    property real headerHeight: 56
    property var authChallenge

    signal succeed()
    signal failed()
    signal back()
    signal cancelSignIn()

    contentItem: Page {
        id: content

        header: ToolBar {
            id: pageHeader

            height:app.isNotchAvailable()? app.headerHeight + app.notchHeight : app.headerHeight
            topPadding:app.isNotchAvailable() ? app.notchHeight:0
            Material.primary: getAppProperty(app.primaryColor, "#166DB2")

            RowLayout {
                anchors.fill: parent
                LayoutMirroring.enabled: !app.isLeftToRight
                LayoutMirroring.childrenInherit: !app.isLeftToRight

                Controls.Icon {
                    imageSource: "../images/close.png"
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: app.widthOffset

                    onClicked: {
                        cancelSignIn()
                        app.portal.credential = null
                        signInPage.closeButtonClicked = true;
                        isSignInPageOpened = false
                    }
                }
            }
        }

        contentItem: Pane {
            id: pageContent

            clip: true
            anchors {
                top: pageHeader.bottom
                left: signInPage.left
                right: signInPage.right
                bottom: signInPage.bottom
            }
            padding: 0

            focus: true
            Keys.onReleased: {
                if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
                    event.accepted = true
                    signInPage.close()
                }
            }
        }
    }

    Component {
        id: signInComponent


        Item {
            id: authenticationView

            anchors.fill: parent
            property var controller: AuthenticationController { }

            //            property var authChallenge
            property var currentView

            Connections{
                target:signInPage

                function onCancelSignIn(){
                    authenticationView.destroy();
                    signInPage.close()
                }
            }

            Component {
                id: userCredentialsViewComponent

                UserCredentialsView {
                    controller: authenticationView.controller
                }
            }

            Component {
                id: oAuth2ViewComponent

                OAuth2View {
                    controller: authenticationView.controller
                }
            }

            Component {
                id: clientCertificateViewComponent

                ClientCertificateView {
                    controller: authenticationView.controller
                }
            }

            //    Component {
            //        id: sslHandshakeViewComponent

            //        SslHandshakeView {}
            //    }


            Connections {
                target: controller
                function onAuthenticationChallenge(challenge){
                    if(!isSignInPageOpened)
                    {
                        challenge.cancel()
                        return

                    }
                    authChallenge = challenge;

                    var _type = Number(challenge.authenticationChallengeType);

                    switch (_type) {
                        // ArcGIS token, HTTP Basic/Digest, IWA
                    case 1:
                        authenticationView.createView(userCredentialsViewComponent);
                        break;

                        // OAuth 2
                    case 2:
                        if(!app.clientId) {
                            messageDialog.show(qsTr("Missing Client ID"),qsTr("ArcGIS Client ID is missing. Please upload your app and go to Settings > Licensing to register a Client ID."))
                            app.isClientIDNeeded = true;
                            authChallenge.cancel();
                            //                            authenticationView.destroy();
                            if (app.hasVisibleSignInPage()) {
                                app.destroySignInPage()
                            }
                            loadPublicPortal()
                        }
                        else
                            authenticationView.createView(oAuth2ViewComponent);
                        break;

                        // Client Certificate
                    case 3:
                        authenticationView.createView(clientCertificateViewComponent);
                        break;

                        // SSL Handshake - Self-signed certificate
                    case 4:
                        authenticationView.createView(oAuth2ViewComponent);
                        challenge.continueWithSslHandshake(true, true)
                        break;
                    }

                }


            }



            function createView(component) {
                if (currentView)
                    currentView.destroy();

                currentView = component.createObject(authenticationView);
                currentView.challenge = authChallenge;
                currentView.anchors.fill = authenticationView;
                busyIndicator.visible=false;
            }

            function clear() {
                if (authChallenge)                   
                    authChallenge.cancel();

                authenticationView.destroy();
            }
        }


    }

    BusyIndicator {
        id: busyIndicator

        anchors.centerIn: parent
        width: iconSize
        height: width
        visible:true
        Material.accent: getAppProperty(app.accentColor)
    }

    Component.onCompleted: {        
        if(app.portal)
          app.portal.destroy()
        app.portal = null
        app.loadSecuredPortal();
    }

    onIsSignedInChanged: {
        if (isSignedIn) {
            cancelSignIn()
            signInPage.close();
        }
    }



    function reset() {
        authenticationView.clear();
    }

    function backButtonPressed() {
        stackView.pop();
    }

    function getAppProperty (appProperty, fallback) {
        if (!fallback) fallback = ""
        try {
            return appProperty ? appProperty : fallback
        } catch (err) {
            return fallback
        }
    }

    onCloseButtonClickedChanged: {
        if (closeButtonClicked) {
            if(typeof authChallenge !== "undefined")
                authChallenge.cancel()
            if(typeof authenticationView !== "undefined")
                authenticationView.destroy();
        }
    }

    onVisibleChanged: {
        if (visible) {
            busyIndicator.visible = true;
            closeButtonClicked = false;
            isSignInPageOpened = true
            pageContent.contentItem = signInComponent.createObject(null);
        }
    }
}
