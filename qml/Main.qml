import QtQuick
import QtQuick.Window
import XingChenProj

Window {
    width: 1000
    height: 600
    visible: true
    color: "transparent"

    Rectangle{
        id:root
        anchors.fill:parent
        color: Theme.totalBgColor
        property int pageNum: 1
        property int loadedPageNum: 1
        property int pendingPageNum: 1
        readonly property int pageTransitionDuration: 180

        onPageNumChanged: {
            if (pageNum === loadedPageNum) {
                return
            }

            pendingPageNum = pageNum
            pageSwitchAnimation.restart()
        }

        Outline {
            width:mainSplitLine.x
            height: parent.height
        }

        Item {
            id: pageHost
            x: mainSplitLine.x + mainSplitLine.width + 2
            width: parent.width - mainSplitLine.x - mainSplitLine.width - 2
            height: parent.height
            clip: true

            Loader {
                id: pageLoader
                anchors.fill: parent
                sourceComponent: root.loadedPageNum === 1 ? rosterComponent : detailComponent
            }

            SequentialAnimation {
                id: pageSwitchAnimation

                NumberAnimation {
                    target: pageLoader
                    property: "opacity"
                    to: 0
                    duration: root.pageTransitionDuration / 2
                    easing.type: Easing.InOutQuad
                }

                ScriptAction {
                    script: root.loadedPageNum = root.pendingPageNum
                }

                NumberAnimation {
                    target: pageLoader
                    property: "opacity"
                    to: 1
                    duration: root.pageTransitionDuration / 2
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Component {
            id: rosterComponent
            Roster {}
        }

        Component {
            id: detailComponent
            Detail {}
        }

        Rectangle{// main split line
            id:mainSplitLine
            height: parent.height - 60
            width:2
            color: Theme.splitLineColor
            x: 180
            y: 30

            DragHandler {
                target: parent
                xAxis.enabled: true
                yAxis.enabled: false
                xAxis.minimum: 50
                xAxis.maximum: 250
            }

            MouseArea{
                anchors.fill:parent
                cursorShape: Qt.SizeHorCursor
            }
        }
    }
}
