import QtQuick 2.7
import QtQuick.Controls 2.2

import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4
import QtQuick.Controls 2.1 as NewControls
import QtQuick.Controls.Material 2.1 as MaterialStyle

import ArcGIS.AppFramework 1.0


Item {
    property var selectedTime: { return new Date() }
    property var apString: selectedTime ? selectedTime.getHours() < 12 ? Qt.locale().amText : Qt.locale().pmText : ""
    property var minString: selectedTime ? selectedTime.getMinutes() < 10 ? ("0" + selectedTime.getMinutes()) : selectedTime.getMinutes() : ""
    property var hourString: selectedTime ? selectedTime.getHours() === 0 ? 12 : (selectedTime.getHours() > 12 ? (selectedTime.getHours() - 12) : selectedTime.getHours()) : ""
    property bool initial: true
    property bool updating: false

    property color primaryColor: "#009688"

    signal timeChanged(var selectedTime)

    Component {
        id: tumblerDelegateComponent

        Text {
            text: modelData
            color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark ? "#ededed":"#000"
            font.bold: true
            font.pixelSize: (modelData === "AM" && Tumbler.tumbler.currentIndex === 0) || (modelData === "PM" && Tumbler.tumbler.currentIndex === 1)
                            || (parseInt(modelData) === Tumbler.tumbler.currentIndex) ? 15 * AppFramework.displayScaleFactor :  (12 * AppFramework.displayScaleFactor) - Math.abs(Tumbler.displacement) / (Tumbler.tumbler.visibleItemCount / 3)
            opacity: 1.0 - Math.abs(Tumbler.displacement) / (Tumbler.tumbler.visibleItemCount / 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    RowLayout{
        anchors.fill: parent
        anchors.margins: 8 * AppFramework.displayScaleFactor
        spacing: 0
        NewControls.Tumbler{
            id: hoursColumn
            Layout.preferredWidth: parent.width / 3
            Layout.fillHeight: true
            wrap: true
            model: [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
            delegate: tumblerDelegateComponent
            spacing: 0
            MaterialStyle.Material.accent: primaryColor
            currentIndex: selectedTime ? selectedTime.getHours() % 12 : 12
            onCurrentIndexChanged: {
                var selectedHours = hoursColumn.currentIndex;
                if(apColumn.currentIndex === 1) selectedHours += 12;
                selectedTime.setHours(selectedHours);
                updateTime();
            }
        }
        NewControls.Tumbler{
            id: minutesColumn
            Layout.preferredWidth: parent.width / 3
            Layout.fillHeight: true
            wrap: true
            visibleItemCount: 10
            model: new Array(60).join().split(',').map(function(item, index){
                return (index < 10) ? ("0" + index) : index;
            })
            delegate: tumblerDelegateComponent
            spacing: 0
            MaterialStyle.Material.accent: primaryColor
            currentIndex: selectedTime ? selectedTime.getMinutes() : 0
            onCurrentIndexChanged: {
                if ( selectedTime ){
                    selectedTime.setMinutes(currentIndex);
                    updateTime();
                }
            }
        }
        NewControls.Tumbler{
            id: apColumn
            Layout.preferredWidth: parent.width / 3
            Layout.fillHeight: true
            wrap: false
            model: [Qt.locale().amText, Qt.locale().pmText]
            delegate: tumblerDelegateComponent
            spacing: 0
            MaterialStyle.Material.accent: primaryColor
            currentIndex: selectedTime ? selectedTime.getHours() >= 12 ? 1 : 0 :  0
            onCurrentIndexChanged: {
                if(currentIndex === 0){
                    if( selectedTime && selectedTime.getHours() >= 12) selectedTime.setHours(selectedTime.getHours() - 12);
                } else {
                    if( selectedTime && selectedTime.getHours() < 12) selectedTime.setHours(selectedTime.getHours() + 12);
                }

                updateTime();
            }
        }
    }

    function updateTime(){
        apString = apColumn.model[apColumn.currentIndex];
        minString = selectedTime ? selectedTime.getMinutes() < 10 ? ("0"+ selectedTime.getMinutes()) : selectedTime.getMinutes() : ""
        hourString = selectedTime ? selectedTime.getHours() === 0 ? 12 : (selectedTime.getHours() > 12 ? (selectedTime.getHours() - 12) : selectedTime.getHours()) : ""
        timeChanged(selectedTime);
    }
}
