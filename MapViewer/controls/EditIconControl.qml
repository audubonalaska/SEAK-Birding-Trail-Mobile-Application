import QtQuick 2.0
import QtQuick.Controls.Material 2.1
import "../controls" as Controls


Rectangle{
    width:parent.width
    height:parent.height
    color:"transparent"
    property var delegContent :delegateContent
    property var calendarPicker : null
    signal saveDate(var editObject)
    Controls.Icon {
        id: editBtn
        imageWidth: app.units(16)
        imageHeight: app.units(16)
        anchors.right:parent.right
        visible:canShowEditIcon?canShowEditIcon:false
        anchors.verticalCenter: parent.verticalCenter
        //Material.elevation: 0
        maskColor: app.primaryColor//"#4c4c4c"
        //rotation: 180
        imageSource: "../images/pencil.png"

        onClicked: {
            panelPage.action = "editFeatureAttribute"
            selectedIndex =  index

            editAttributePage.editObject = delegContent.getEditObject()

            editAttributePage.open()

        }
    }
    Controls.Icon {
        id: nextEditField
        visible:canShowDomainIcon?canShowDomainIcon:false
        anchors.right:parent.right
        anchors.verticalCenter: parent.verticalCenter
        imageHeight: app.units(24)
        imageWidth: app.units(24)

        //Material.background:"#FFFFFF"
        //Material.elevation: 0
        maskColor: app.primaryColor//"#4c4c4c"
        //enabled: root.currentPageNumber < root.pageCount
        rotation: app.isLeftToRight ? -90 : 90
        imageSource: "../images/arrowDown.png"
        //Layout.alignment: Qt.AlignHCenter

        onClicked: {

            editAttributePage.editObject = delegContent.getEditObject()

            editAttributePage.open()
        }
    }

    Controls.Icon {
        id: calendarIcon
        visible:canShowCalendarIcon ? canShowCalendarIcon : false
        anchors.right:parent.right
        anchors.verticalCenter: parent.verticalCenter
        imageHeight: app.units(20)
        imageWidth: app.units(20)
        maskColor: app.primaryColor
        imageSource: "../images/ic_calendar_edit_black_24dp.png"

        onClicked: {
            calendarPicker = calendarDialogComponent.createObject(app);
            calendarPicker.attributesId = label
            calendarPicker.swipeViewIndex = 0;

            var defaultDate = new Date()
            if(unformattedValue){
                defaultDate = new Date(unformattedValue)
            }
            calendarPicker.selectedDateAndTime = defaultDate
            calendarPicker.updateDateAndTime();
            calendarPicker.visible = true;
        }
    }


    Connections {
        target: calendarPicker

        function onAccepted() {
            if(calendarPicker.attributesId === label){
                desc.text = calendarPicker.selectedDateAndTime.toLocaleString(Qt.locale(),"MM/dd/yyyy hh:mm AP");               
                let editObject = delegContent.getEditObject()
                editObject.fieldValue = calendarPicker.selectedDateAndTime
                saveDate(editObject)
            }
        }

    }


    Component {
        id: calendarDialogComponent
        Controls.CalendarDialog{
            property var attributesId

            primaryColor:app.primaryColor
            theme:Material.Light

            width: Math.min(panelPage.width*0.8,300)
            height: pageView.state === "anchorbottom"?width * 1.5:width * 1.7
            x: app.isLeftToRight ? (panelPage.width - width)/2 : (app.width - width - app.defaultMargin)
            y:app.headerHeight + (panelPage.height  - height)/2

            visible: false
            padding: 0
            topPadding: 0
            bottomPadding: 0
            //closePolicy: Popup.CloseOnEscape
        }
    }

}
