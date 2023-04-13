import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import Esri.ArcGISRuntime 100.14

import "../controls" as Controls
import "./Controller"


Item {
    id: authenticationView

    anchors.fill: parent
    property var controller: AuthenticationController { }
    Material.primary: app.primaryColor
    Material.accent: app.accentColor


    property var authChallenge
    property var currentView

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
        target: AuthenticationManager

        // onAuthenticationChallenge: {
        function onAuthenticationChallenge(challenge){
            authChallenge = challenge;

            var _type = Number(challenge.authenticationChallengeType);

            switch (_type) {
                // ArcGIS token, HTTP Basic/Digest, IWA
            case 1:
                createView(userCredentialsViewComponent);
                break;

                // OAuth 2
            case 2:
                createView(oAuth2ViewComponent);
                break;

                // Client Certificate
            case 3:
                createView(clientCertificateViewComponent);
                break;

                // SSL Handshake - Self-signed certificate
            case 4:
                createView(oAuth2ViewComponent);
                challenge.continueWithSslHandshake(true, true)
                break;
            }
        }
    }

    Component.onCompleted: {
        console.log("authentication view completed")
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
            //            authChallenge = null;
            authChallenge.cancel();

        authenticationView.destroy();
    }
}
