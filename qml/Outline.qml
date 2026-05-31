import QtQuick
import QtQuick.Window
import XingChenProj

Item {
    id: outlineRoot

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -70
        spacing: 30
        Repeater{
            model: [
                {title:"Roster", captical: "R", num:1},
                {title:"Detail", captical: "D", num:2}
            ]

            delegate: Text{
                id: titleText
                anchors.horizontalCenter: parent.horizontalCenter
                color: modelData.num === root.pageNum ? Theme.selectedColor : Theme.textColor
                text: titleMetrics.width > outlineRoot.width ? modelData.captical : modelData.title
                font.family: Theme.fontFamily
                font.pixelSize: 25

                TextMetrics {
                    id: titleMetrics
                    font: titleText.font
                    text: modelData.title
                }

                Behavior on color {ColorAnimation{ duration:180}}

                MouseArea{
                    anchors.fill:parent

                    onClicked: {
                        root.pageNum = modelData.num
                    }
                }
            }
        }
    }
}
