import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import XingChenProj

Item {
    id: rosterPage

    property int editingScoreRow: -1
    property string editingScoreName: ""
    property string addStudentError: ""
    property string editScoreError: ""
    readonly property var headerTitles: ["Name", "Class", "Student ID", "Score"]
    readonly property var sortLabels: ["Name A-Z", "Name Z-A", "Score Low-High", "Score High-Low"]
    readonly property real tableWidth: Math.max(listView.width, 680)

    function columnWidth(column) {
        const widths = [
            Math.round(tableWidth * 0.30),
            Math.round(tableWidth * 0.29),
            Math.round(tableWidth * 0.25)
        ]
        widths.push(tableWidth - widths[0] - widths[1] - widths[2])
        return widths[column]
    }

    function parseScore(text, allowEmptyDefault) {
        const trimmed = text.trim()
        if (trimmed.length === 0 && allowEmptyDefault) {
            return { valid: true, score: 0 }
        }
        if (!/^[-+]?\d+$/.test(trimmed)) {
            return { valid: false, score: 0 }
        }
        return { valid: true, score: parseInt(trimmed, 10) }
    }

    function clearAddStudentForm() {
        nameField.text = ""
        classField.text = ""
        studentIdField.text = ""
        newScoreField.text = "0"
        addStudentError = ""
    }

    function submitNewStudent() {
        const parsedScore = parseScore(newScoreField.text, true)
        if (!parsedScore.valid) {
            addStudentError = "Score must be an integer."
            return
        }

        if (studentModel.addStudent(nameField.text,
                                    classField.text,
                                    studentIdField.text,
                                    parsedScore.score)) {
            addStudentPopup.close()
        } else {
            addStudentError = studentModel.lastError
        }
    }

    function openScoreEditor(row, name, score, reason) {
        editingScoreRow = row
        editingScoreName = name
        editScoreField.text = "0"
        reasonField.text = reason
        editScoreError = ""
        scoreEditPopup.open()
        editScoreField.forceActiveFocus()
    }

    function submitScoreEdit() {
        const parsedScore = parseScore(editScoreField.text, false)
        if (!parsedScore.valid) {
            editScoreError = "Points must be an integer."
            return
        }

        if (studentModel.adjustScore(editingScoreRow, parsedScore.score, reasonField.text)) {
            scoreEditPopup.close()
        } else {
            editScoreError = studentModel.lastError
        }
    }

    StudentModel {
        id: studentModel
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.max(16, Math.min(30, rosterPage.width * 0.04))
        anchors.rightMargin: Math.max(16, Math.min(26, rosterPage.width * 0.04))
        anchors.topMargin: Math.max(18, Math.min(28, rosterPage.height * 0.05))
        anchors.bottomMargin: Math.max(18, Math.min(24, rosterPage.height * 0.04))
        spacing: Math.max(14, Math.min(20, rosterPage.height * 0.035))

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: "Student Roster (" + studentModel.totalCount + ")"
                        color: Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: rosterPage.width < 520 ? 26 : 34
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "View and manage enrolled students for the current academic term."
                        color: Theme.secondaryTextColor
                        font.family: Theme.fontFamily
                        font.pixelSize: rosterPage.width < 520 ? 13 : 16
                        elide: Text.ElideRight
                    }
                }

                Button {
                    id: addStudentButton
                    text: rosterPage.width < 520 ? "Add" : "Add Student"
                    hoverEnabled: true
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    onClicked: {
                        clearAddStudentForm()
                        addStudentPopup.open()
                        nameField.forceActiveFocus()
                    }

                    contentItem: Text {
                        text: addStudentButton.text
                        color: Theme.buttonTextColor
                        font: addStudentButton.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 10
                        color: addStudentButton.hovered ? Theme.buttonHoverColor : Theme.buttonColor
                        border.width: 0
                    }

                    leftPadding: 24
                    rightPadding: 24
                    topPadding: 13
                    bottomPadding: 13
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "Sort"
                    color: Theme.secondaryTextColor
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                }

                ComboBox {
                    id: sortCombo
                    Layout.preferredWidth: 180
                    model: rosterPage.sortLabels
                    currentIndex: studentModel.sortMode
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    onActivated: function(index) {
                        studentModel.sortMode = index
                    }

                    contentItem: Text {
                        leftPadding: 12
                        rightPadding: 30
                        text: sortCombo.displayText
                        color: Theme.textColor
                        font: sortCombo.font
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        radius: 10
                        color: Theme.inputBgColor
                        border.width: sortCombo.activeFocus ? 1 : 0
                        border.color: Theme.focusBorderColor
                    }
                }
            }
        }

        Rectangle {
            id: tableCard
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
                        x: -listView.contentX
                        width: rosterPage.tableWidth
                        height: parent.height
                        Repeater {
                            model: rosterPage.headerTitles

                            delegate: Item {
                                width: rosterPage.columnWidth(index)
                                height: parent.height

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: index === 3 ? 0 : 18
                                    anchors.horizontalCenter: index === 3 ? parent.horizontalCenter : undefined
                                    text: modelData
                                    color: Theme.secondaryTextColor
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.cardBgColor

                    ListView {
                        id: listView
                        anchors.fill: parent
                        anchors.leftMargin: 1
                        anchors.rightMargin: 1
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        clip: true
                        contentWidth: rosterPage.tableWidth
                        model: studentModel
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Item {
                            id: rowDelegate
                            required property int index
                            required property string name
                            required property string className
                            required property string studentId
                            required property int score
                            required property string scoreReason

                            width: listView.contentWidth
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

                                Item {
                                    width: rosterPage.columnWidth(0)
                                    height: parent.height

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 18
                                        anchors.rightMargin: 18
                                        text: rowDelegate.name
                                        color: Theme.textColor
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 17
                                        elide: Text.ElideRight
                                    }
                                }

                                Item {
                                    width: rosterPage.columnWidth(1)
                                    height: parent.height

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 18
                                        anchors.rightMargin: 18
                                        text: rowDelegate.className
                                        color: Theme.textColor
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 17
                                        elide: Text.ElideRight
                                    }
                                }

                                Item {
                                    width: rosterPage.columnWidth(2)
                                    height: parent.height

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 18
                                        anchors.rightMargin: 18
                                        text: rowDelegate.studentId
                                        color: Theme.textColor
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 17
                                        elide: Text.ElideRight
                                    }
                                }

                                Item {
                                    width: rosterPage.columnWidth(3)
                                    height: parent.height

                                    Button {
                                        id: scoreButton
                                        anchors.centerIn: parent
                                        text: String(rowDelegate.score)
                                        hoverEnabled: true
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 16
                                        onClicked: rosterPage.openScoreEditor(rowDelegate.index,
                                                                              rowDelegate.name,
                                                                              rowDelegate.score,
                                                                              rowDelegate.scoreReason)

                                        contentItem: Text {
                                            text: scoreButton.text
                                            color: Theme.textColor
                                            font: scoreButton.font
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        background: Rectangle {
                                            implicitWidth: 74
                                            implicitHeight: 36
                                            radius: 8
                                            color: rowDelegate.score < 0 ? Theme.negativeScoreBgColor : Theme.positiveScoreBgColor
                                            border.width: scoreButton.hovered || scoreButton.activeFocus ? 1 : 0
                                            border.color: Theme.focusBorderColor
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: studentModel.totalCount === 0
                        text: "No students yet. Add your first student to get started."
                        color: Theme.subtleTextColor
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                    }
                }
            }
        }
    }

    Popup {
        id: addStudentPopup
        anchors.centerIn: Overlay.overlay
        modal: true
        focus: true
        width: 420
        height: implicitHeight
        padding: 0
        closePolicy: Popup.CloseOnEscape
        onClosed: clearAddStudentForm()

        Overlay.modal: Rectangle {
            color: Theme.overlayColor
        }

        background: Rectangle {
            radius: 16
            color: Theme.cardBgColor
            border.width: 1
            border.color: Theme.cardBorderColor
        }

        contentItem: ColumnLayout {
            spacing: 16

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                color: Theme.tableHeaderBgColor
                radius: 16

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 16
                    color: Theme.tableHeaderBgColor
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: "Add Student"
                        color: Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: 26
                    }

                    Text {
                        text: "Create a new roster entry."
                        color: Theme.secondaryTextColor
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                Layout.bottomMargin: 22

                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: "Student Name"
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: Theme.textColor
                    background: Rectangle {
                        radius: 10
                        color: Theme.inputBgColor
                        border.width: nameField.activeFocus ? 1 : 0
                        border.color: Theme.focusBorderColor
                    }
                }

                TextField {
                    id: classField
                    Layout.fillWidth: true
                    placeholderText: "Class Name"
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: Theme.textColor
                    background: Rectangle {
                        radius: 10
                        color: Theme.inputBgColor
                        border.width: classField.activeFocus ? 1 : 0
                        border.color: Theme.focusBorderColor
                    }
                }

                TextField {
                    id: studentIdField
                    Layout.fillWidth: true
                    placeholderText: "Student ID"
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: Theme.textColor
                    background: Rectangle {
                        radius: 10
                        color: Theme.inputBgColor
                        border.width: studentIdField.activeFocus ? 1 : 0
                        border.color: Theme.focusBorderColor
                    }
                }

                TextField {
                    id: newScoreField
                    Layout.fillWidth: true
                    placeholderText: "Score"
                    text: "0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: Theme.textColor
                    validator: IntValidator {
                        bottom: -999999
                        top: 999999
                    }
                    onAccepted: rosterPage.submitNewStudent()
                    background: Rectangle {
                        radius: 10
                        color: Theme.inputBgColor
                        border.width: newScoreField.activeFocus ? 1 : 0
                        border.color: Theme.focusBorderColor
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: rosterPage.addStudentError.length > 0
                    text: rosterPage.addStudentError
                    color: Theme.dangerColor
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        id: cancelAddButton
                        text: "Cancel"
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        onClicked: addStudentPopup.close()

                        contentItem: Text {
                            text: cancelAddButton.text
                            color: Theme.mutedButtonTextColor
                            font: cancelAddButton.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 10
                            color: Theme.mutedButtonColor
                        }

                        leftPadding: 18
                        rightPadding: 18
                        topPadding: 11
                        bottomPadding: 11
                    }

                    Button {
                        id: confirmAddButton
                        text: "Save Student"
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        onClicked: rosterPage.submitNewStudent()

                        contentItem: Text {
                            text: confirmAddButton.text
                            color: Theme.buttonTextColor
                            font: confirmAddButton.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 10
                            color: Theme.buttonColor
                        }

                        leftPadding: 18
                        rightPadding: 18
                        topPadding: 11
                        bottomPadding: 11
                    }
                }
            }
        }
    }

    Popup {
        id: scoreEditPopup
        anchors.centerIn: Overlay.overlay
        modal: true
        focus: true
        width: 420
        height: implicitHeight
        padding: 0
        closePolicy: Popup.CloseOnEscape
        onClosed: {
            editingScoreRow = -1
            editingScoreName = ""
            editScoreError = ""
        }

        Overlay.modal: Rectangle {
            color: Theme.overlayColor
        }

        background: Rectangle {
            radius: 16
            color: Theme.cardBgColor
            border.width: 1
            border.color: Theme.cardBorderColor
        }

        contentItem: ColumnLayout {
            spacing: 16

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                color: Theme.tableHeaderBgColor
                radius: 16

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 16
                    color: Theme.tableHeaderBgColor
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.right: parent.right
                    anchors.rightMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: "Adjust Score"
                        color: Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: 26
                    }

                    Text {
                        width: parent.width
                        text: editingScoreName
                        color: Theme.secondaryTextColor
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                Layout.bottomMargin: 22

                TextField {
                    id: editScoreField
                    Layout.fillWidth: true
                    placeholderText: "Points (+/-)"
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: Theme.textColor
                    validator: IntValidator {
                        bottom: -999999
                        top: 999999
                    }
                    onAccepted: rosterPage.submitScoreEdit()
                    background: Rectangle {
                        radius: 10
                        color: Theme.inputBgColor
                        border.width: editScoreField.activeFocus ? 1 : 0
                        border.color: Theme.focusBorderColor
                    }
                }

                TextArea {
                    id: reasonField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 96
                    placeholderText: "Reason"
                    wrapMode: TextArea.Wrap
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: Theme.textColor
                    background: Rectangle {
                        radius: 10
                        color: Theme.inputBgColor
                        border.width: reasonField.activeFocus ? 1 : 0
                        border.color: Theme.focusBorderColor
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: rosterPage.editScoreError.length > 0
                    text: rosterPage.editScoreError
                    color: Theme.dangerColor
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        id: cancelScoreButton
                        text: "Cancel"
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        onClicked: scoreEditPopup.close()

                        contentItem: Text {
                            text: cancelScoreButton.text
                            color: Theme.mutedButtonTextColor
                            font: cancelScoreButton.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 10
                            color: Theme.mutedButtonColor
                        }

                        leftPadding: 18
                        rightPadding: 18
                        topPadding: 11
                        bottomPadding: 11
                    }

                Button {
                    id: confirmScoreButton
                    text: "Apply"
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        onClicked: rosterPage.submitScoreEdit()

                        contentItem: Text {
                            text: confirmScoreButton.text
                            color: Theme.buttonTextColor
                            font: confirmScoreButton.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 10
                            color: Theme.buttonColor
                        }

                        leftPadding: 18
                        rightPadding: 18
                        topPadding: 11
                        bottomPadding: 11
                    }
                }
            }
        }
    }
}
