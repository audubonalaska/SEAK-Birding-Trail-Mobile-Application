import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../views"


Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: profileSection.height

    LayoutMirroring.enabled: !app.isLeftToRight
    LayoutMirroring.childrenInherit: !app.isLeftToRight
    //-----------------------------------------------------------------------------------

    property bool isShowProfile: app.isSignedIn //&& !portal.isBusy

    signal clickSignIn()
    signal clickSignOut()

    //-----------------------------------------------------------------------------------


    color:"#F3F3F4"


    function getPlaceHolderName(str) {
        if(str > "") {
            str = str.toUpperCase()
            var arr = str.split(" ");
            if(arr.length > 1) {
                return arr[0].charAt(0) + arr[1].charAt(0);
            } else {
                return arr[0].charAt(0);
            }
        } else {
            return ""
        }
    }

    ColumnLayout {
        id: profileSection

        width: parent.width - (isIphoneXAndLandscape ? 40 * scaleFactor : 0)
        anchors.horizontalCenter: parent.horizontalCenter

        anchors.left: parent.left
        anchors.leftMargin: isIphoneXAndLandscape ? 40 * scaleFactor : 0
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight:  (Qt.platform.os === "ios" ? app.notchHeight : 32 * scaleFactor)
        }

        //-----------------------------------------------------------------------------------



        Label {
            Layout.preferredWidth: parent.width - 32 * scaleFactor

            Layout.preferredHeight: 22 * scaleFactor
            text: qsTr("Not Signed In")
            leftPadding: 16 * scaleFactor
            font.pixelSize: 16 * scaleFactor
            font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
            color: fonts.subtitle.textColor

            visible: !isShowProfile
            font.bold:true
            horizontalAlignment: Label.AlignLeft
        }

        //-----------------------------------------------------------------------------------

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 64 * scaleFactor

            visible: isShowProfile

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.preferredWidth: 16 * scaleFactor
                    Layout.preferredHeight: 64 * scaleFactor
                }

                Rectangle {
                    Layout.preferredWidth: 64 * scaleFactor
                    Layout.preferredHeight: 64 * scaleFactor

                    border.color:"#EAEAEA"//fonts.bodySecondary.textColor //"#EAEAEA"

                    border.width:app.units(1)

                    //color: "transparent"

                    clip: true
                    radius: width / 2

                    Label {
                        id: avatarPlaceHolder
                        width: parent.width - 10
                        height: width
                        anchors.centerIn: parent
                        visible: (isShowProfile && avatarImage.imageStatus !== Image.Ready && avatarImage !== Image.Loading) || (app.userThumbnail >"")

                        background: Rectangle {
                            anchors.fill: parent
                            color:  "#FFFFFF"
                            radius: this.width / 2
                            clip: true
                        }

                        text: portalUserInfo.fullName > ""?getPlaceHolderName(portalUserInfo.fullName):getPlaceHolderName(portalUserInfo.username)
                        font.pixelSize: 28 * scaleFactor
                        font.family: fonts.headerAccent.textFontFamily
                        color: app.primaryColor ? app.primaryColor :"#8F499C"
                        horizontalAlignment: Label.AlignHCenter
                        verticalAlignment: Label.AlignVCenter
                    }

                    RoundImage {
                        id: avatarImage
                        width: parent.width
                        height: parent.height
                        visible: isShowProfile
                        radius: width / 2
                        imageSource: portalUserInfo && portalUserInfo.thumbnailUrl && (portalUserInfo.thumbnailUrl.toString()).indexOf('/info/?') === -1? portalUserInfo.thumbnailUrl:""
                    }

                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64 * scaleFactor
                }
            }
        }

        Item {
            Layout.fillWidth: true

            Layout.preferredHeight: 16 * scaleFactor

            visible: isShowProfile
        }

        Label {
            Layout.preferredWidth: parent.width - 32 * scaleFactor
            Layout.preferredHeight: text > ""?height:0
            Layout.alignment: Qt.AlignHCenter

            text: portalUserInfo && portalUserInfo.fullName? portalUserInfo.fullName:""
            font.pixelSize: fonts.subtitle.textSize

            // font.family: fonts.subtitle.textFontFamily
            font.family:  "%1,%2".arg(baseFontFamily).arg("Helvetica,Avenir")
            color: fonts.subtitle.textColor
            font.bold: true


            leftPadding: 0
            rightPadding: 0

            horizontalAlignment:Label.AlignLeft //isRightToLeft ? Label.AlignRight : Label.AlignLeft

            visible: isShowProfile
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight:portalUserInfo && portalUserInfo.fullName? 8 * scaleFactor:0
            visible: isShowProfile
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 20 * scaleFactor
            visible: isShowProfile

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16 * scaleFactor
                spacing: 8 * scaleFactor


                IconImage {
                    Layout.preferredWidth: 16 * scaleFactor
                    Layout.preferredHeight: 16 * scaleFactor
                    source: "../images/user-16px.png"
                    color: "#6A6A6A"
                }

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.maximumWidth: parent.width - 24 * scaleFactor

                    text: portalUserInfo && portalUserInfo.username? portalUserInfo.username:""
                    font.pixelSize: fonts.bodySecondary.textSize
                    font.family: fonts.bodySecondary.textFontFamily
                    color: fonts.bodySecondary.textColor
                    maximumLineCount: 1
                    elide: Label.ElideRight
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 8 * scaleFactor
            visible: portal?(isShowProfile && portalUserInfo !== null && portalUserInfo.email > ""):""
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 20 * scaleFactor:0
            visible: portal?(isShowProfile && portalUserInfo !== null && portalUserInfo.email > ""):""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16 * scaleFactor
                spacing: 8 * scaleFactor


                IconImage {
                    Layout.preferredWidth: 16 * scaleFactor
                    Layout.preferredHeight: 16 * scaleFactor
                    source: "../images/email-16px.png"
                    color: "#6A6A6A"
                }

                Label {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.maximumWidth: parent.width - 24 * scaleFactor

                    text: portal?(portalUserInfo && portalUserInfo.email ? portalUserInfo.email : ""):""
                    font.pixelSize: fonts.bodySecondary.textSize
                    font.family: fonts.bodySecondary.textFontFamily
                    color: fonts.bodySecondary.textColor
                    maximumLineCount: 1
                    elide: Label.ElideRight
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 8 * scaleFactor
            visible: isShowProfile
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: portalURLLabel.lineCount === 1 ? 16 * scaleFactor : 32 * scaleFactor
            visible: isShowProfile

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16 * scaleFactor
                anchors.rightMargin: 16 * scaleFactor
                spacing: 8 * scaleFactor

                IconImage {
                    Layout.preferredWidth: 16 * scaleFactor
                    Layout.preferredHeight: 16 * scaleFactor
                    source: "../images/portal-16px.png"
                    color: "#6A6A6A"
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 4 * scaleFactor

                }

                 Label {
                    id: portalURLLabel
                    Layout.alignment: Qt.AlignVCenter
                    Layout.maximumWidth: parent.width - 24 * scaleFactor
                    text:portal?"<a href=\"%1\"><font color=%2>%3</font></a><br>".arg(portal.url).arg(app.primaryColor).arg(portal.url):""
                    font.pixelSize: fonts.bodySecondary.textSize
                    font.family: fonts.bodySecondary.textFontFamily
                    color: fonts.bodySecondary.textColor
                    maximumLineCount: 2
                    elide: Label.ElideRight
                    wrapMode: Text.WrapAnywhere
                    onLinkActivated: {
                                Qt.openUrlExternally(link);
                            }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        //-----------------------------------------------------------------------------------

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 16 * scaleFactor
        }

        // sign in button
/*
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36 * scaleFactor

            visible: !isShowProfile

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.preferredWidth: 16 * scaleFactor
                    Layout.fillHeight: true
                }

                GradientRoundButton {
                    Layout.preferredWidth: contentWidth + 48 * scaleFactor
                    Layout.fillHeight: true

                    visible: !isShowProfile
                    enabled: app.isOnline
                    text: strings.sign_in

                    onClicked: {
                        if(app.clientId)
                            clickSignIn();
                        else
                        {
                            messageDialog.show(app.strings.clientID_missing,app.strings.clientID_missing_message)

                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
*/

        // sign out button
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36 * scaleFactor

            visible: isShowProfile

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.preferredWidth: 16 * scaleFactor
                    Layout.fillHeight: true
                }

                Rectangle {
                    Layout.preferredWidth: signOutContentLabel.width + 48 * scaleFactor
                    Layout.fillHeight: true

                    color: "transparent"
                    border.width: 1
                    border.color: "#6A6A6A"

                    radius: 18 * scaleFactor

                    Label {
                        id: signOutContentLabel

                        anchors.centerIn: parent
                        text: qsTr("Sign Out")

                        padding: 0
                        font.pixelSize: fonts.bodyAccent.textSize
                        font.family: fonts.bodyAccent.textFontFamily
                        color: fonts.bodyAccent.textColor
                        opacity: enabled ? 1.0 : 0.3

                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            clickSignOut();
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        Item {
            Layout.fillWidth: true

            Layout.preferredHeight: app.units(28) * scaleFactor

        }
    }
}
