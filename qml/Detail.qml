import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import XingChenProj

Item {
    id: detailPage

    readonly property var headerTitles: ["Event", "Student", "Time", "Points", "Reason / Detail"]
    readonly property real tableWidth: Math.max(historyList.width, 820)

    function columnWidth(column) {
        const widths = [
            Math.round(tableWidth * 0.15),
            Math.round(tableWidth * 0.20),
            Math.round(tableWidth * 0.20),
            Math.round(tableWidth * 0.13)
        ]
        widths.push(tableWidth - widths[0] - widths[1] - widths[2] - widths[3])
        return widths[column]
    }

    function eventText(type) {
        return type === "addStudent" ? "Add Student" : "Score Change"
    }

    function detailText(type, summary, reason) {
        if (type === "addStudent") {
            return summary
        }
        return reason.length > 0 ? reason : "No reason"
    }

    onVisibleChanged: {
        if (visible) {
            historyModel.refresh()
        }
    }

    HistoryModel {
        id: historyModel
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.max(16, Math.min(30, detailPage.width * 0.04))
        anchors.rightMargin: Math.max(16, Math.min(26, detailPage.width * 0.04))
        anchors.topMargin: Math.max(18, Math.min(28, detailPage.height * 0.05))
        anchors.bottomMargin: Math.max(18, Math.min(24, detailPage.height * 0.04))
        spacing: Math.max(14, Math.min(20, detailPage.height * 0.035))

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: "Detail (" + historyModel.totalCount + ")"
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: detailPage.width < 520 ? 26 : 34
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: "History of student additions and score changes."
                    color: Theme.secondaryTextColor
                    font.family: Theme.fontFamily
                    font.pixelSize: detailPage.width < 520 ? 13 : 16
                    elide: Text.ElideRight
                }
            }

            Button {
                id: clearHistoryButton
                text: detailPage.width < 520 ? "Clear" : "Clear History"
                enabled: historyModel.totalCount > 0
                hoverEnabled: true
                font.family: Theme.fontFamily
                font.pixelSize: 15
                onClicked: historyModel.clearHistory()

                contentItem: Text {
                    text: clearHistoryButton.text
                    color: clearHistoryButton.enabled ? Theme.buttonTextColor : Theme.subtleTextColor
                    font: clearHistoryButton.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 10
                    color: clearHistoryButton.enabled
                           ? (clearHistoryButton.hovered ? Theme.buttonHoverColor : Theme.buttonColor)
                           : Theme.mutedButtonColor
                    border.width: 0
                }

                leftPadding: 18
                rightPadding: 18
                topPadding: 11
                bottomPadding: 11
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Theme.cardBgColor
            border.width: 1
            border.color: Theme.cardBorderColor
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    color: Theme.tableHeaderBgColor
                    clip: true

                    Row {
                        x: -historyList.contentX
                        width: detailPage.tableWidth
                        height: parent.height

                        Repeater {
                            model: detailPage.headerTitles

                            delegate: Item {
                                width: detailPage.columnWidth(index)
                                height: parent.height

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    text: modelData
                                    color: Theme.secondaryTextColor
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.cardBgColor
                    clip: true

                    ListView {
                        id: historyList
                        anchors.fill: parent
                        anchors.leftMargin: 1
                        anchors.rightMargin: 1
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        clip: true
                        contentWidth: detailPage.tableWidth
                        model: historyModel
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Item {
                            id: historyRow
                            required property string type
                            required property string studentName
                            required property string timestamp
                            required property string pointsText
                            required property string reason
                            required property string summary

                            width: historyList.contentWidth
                            height: 58

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Theme.componentBgColor
                            }

                            Row {
                                anchors.fill: parent

                                Repeater {
                                    model: 5

                                    delegate: Item {
                                        width: detailPage.columnWidth(index)
                                        height: parent.height

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            text: index === 0
                                                  ? detailPage.eventText(historyRow.type)
                                                  : (index === 1
                                                     ? historyRow.studentName
                                                     : (index === 2
                                                        ? historyRow.timestamp
                                                        : (index === 3
                                                           ? (historyRow.type === "addStudent" ? "-" : historyRow.pointsText)
                                                           : detailPage.detailText(historyRow.type, historyRow.summary, historyRow.reason))))
                                            color: index === 3 && historyRow.type !== "addStudent"
                                                   ? Theme.selectedColor
                                                   : Theme.textColor
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 15
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: historyModel.totalCount === 0
                        text: "No detail history yet."
                        color: Theme.subtleTextColor
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                    }
                }
            }
        }
    }
}
