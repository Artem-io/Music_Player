import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import AudioPlayer 1.0

Item {
    id: root
    width: 500
    height: 530
    property color textColor: "#E6E6E6"
    property var checkedStates: {
        let arr = new Array(audioPlayer.filePaths.length)
        arr.fill(false)
        return arr
    }
    property bool isEditing: false
    property string originalPlaylistName: ""

    Image_Button {
        id: addPlaylistButton
        width: 30
        height: 30
        x: -150
        rotation: 45
        visible: !playlistFilesView.visible
        image: "assets/icons/cross.png"
        onClicked: {
            playlistName.text = ""
            let newArr = new Array(audioPlayer.filePaths.length)
            newArr.fill(false)
            root.checkedStates = newArr
            isEditing = false
            playlistDialog.open()
        }
    }

    ListModel {
        id: playlistModel
        Component.onCompleted: {
            let initialPlaylists = []
            for (var key in audioPlayer.playlists)
                initialPlaylists.push(key)

            for (var i = 0; i < initialPlaylists.length; i++)
                append({ "name": initialPlaylists[i] })
        }
    }

    Connections {
        target: audioPlayer
        function onFilePathsChanged() {
            let newArr = new Array(audioPlayer.filePaths.length)
            newArr.fill(false)
            root.checkedStates = newArr
        }

        function onPlaylistsChanged() {
            let currentNames = []
            for (var i = 0; i < playlistModel.count; i++)
                currentNames.push(playlistModel.get(i).name)

            let newNames = []
            for (var key in audioPlayer.playlists)
                newNames.push(key)

            for (var i = playlistModel.count - 1; i >= 0; i--)
                if (!newNames.includes(currentNames[i])) playlistModel.remove(i)

            for (var j = 0; j < newNames.length; j++)
                if (!currentNames.includes(newNames[j])) playlistModel.append({ "name": newNames[j] })
        }
    }

    GridView {
        id: playlistGrid
        visible: !playlistFilesView.visible
        model: playlistModel
        width: 1000
        height: parent.height
        anchors.left: addPlaylistButton.right
        anchors.leftMargin: 80
        cellHeight: 190
        cellWidth: 170
        clip: true

        delegate: Rectangle {
            height: playlistGrid.cellHeight - 40
            width: playlistGrid.cellWidth - 20
            color: "#2B2B2B"
            border.color: "gray"
            radius: 15

            Text {
                anchors.top: parent.bottom
                font.pointSize: 12
                text: name
                color: textColor
                width: parent.width - 10
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    playlistFilesView.files = audioPlayer.playlists[name]
                    audioPlayer.setCurSongList(playlistFilesView.filteredFiles)
                    playlistFilesView.visible = true
                    playlistFilesView.searchQuery = ""
                }
            }

            Image_Button {
                id: moreIcon
                image: "assets/icons/options.png"
                width: 25
                height: 25
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    rightMargin: 10
                    bottomMargin: 10
                }
                onClicked: optionsPopup.open()
            }

            Popup {
                id: optionsPopup
                x: moreIcon.x - width + moreIcon.width
                y: moreIcon.y - height
                width: 150
                implicitHeight: contentItem.implicitHeight + 10
                padding: 5

                contentItem: ListView {
                    id: popupList
                    clip: true
                    implicitHeight: contentHeight
                    model: ["Edit Playlist", "Delete"]
                    spacing: 2

                    delegate: ItemDelegate {
                        width: parent.width
                        height: 40

                        contentItem: Text {
                            text: modelData
                            color: textColor
                            font.pointSize: 13
                            anchors.centerIn: parent
                            scale: hovered ? 1.05 : 1.0

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }

                        background: Rectangle {
                            color: hovered ? "#343840" : "#424752"
                            radius: 16
                        }

                        onClicked: {
                            switch (modelData) {
                            case "Delete":
                                deleteConfirmationDialog.name = name
                                deleteConfirmationDialog.open()
                                break

                            case "Edit Playlist":
                                playlistName.text = name
                                originalPlaylistName = name
                                let newArr = new Array(audioPlayer.filePaths.length)
                                newArr.fill(false)
                                let currentFiles = audioPlayer.playlists[name]
                                for (let i = 0; i < audioPlayer.filePaths.length; i++)
                                    if (currentFiles.includes(audioPlayer.filePaths[i])) newArr[i] = true
                                root.checkedStates = newArr
                                isEditing = true
                                playlistDialog.open()
                                break
                            }
                            optionsPopup.close()
                        }
                    }
                }

                background: Rectangle {
                    color: "#424752"
                    radius: 20
                }
            }
        }
    }

    Dialog {
        id: deleteConfirmationDialog
        title: "Delete playlist?"
        modal: true
        anchors.centerIn: parent
        property string name: ""

        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                text: "Yes"
                font.pointSize: 11
                flat: true
                onClicked: {
                    audioPlayer.removePlaylist(deleteConfirmationDialog.name)
                    deleteConfirmationDialog.accept()
                }
            }

            Button {
                text: "No"
                font.pointSize: 11
                flat: true
                onClicked: deleteConfirmationDialog.reject()
            }
        }
    }

    Dialog {
        id: playlistDialog
        title: isEditing ? "Edit Playlist" : "Create Playlist"
        modal: true
        anchors.centerIn: parent
        property bool showError: false

        Column {
            spacing: 10
            width: 300

            TextField {
                id: playlistName
                width: parent.width
                placeholderText: "Playlist Name"
                onTextChanged: playlistDialog.showError = false
            }

            Text {
                id: errorText
                width: parent.width
                text: "Please enter a playlist name."
                color: "red"
                font.pointSize: 10
                visible: playlistDialog.showError
            }

            ListView {
                id: songSelector
                width: parent.width
                height: 200
                model: audioPlayer.filePaths
                clip: true

                delegate: CheckDelegate {
                    width: parent.width
                    text: modelData.split('/').pop()
                    checked: index < root.checkedStates.length ? root.checkedStates[index] : false
                    onCheckedChanged: if (index < root.checkedStates.length) root.checkedStates[index] = checked
                }
            }

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: "OK"
                    flat: true
                    onClicked: {
                        let selectedFiles = []
                        for (let i = 0; i < audioPlayer.filePaths.length; i++)
                            if (root.checkedStates[i]) selectedFiles.push(audioPlayer.filePaths[i])

                        if (!playlistName.text) {
                            playlistDialog.showError = true
                            return
                        }

                        if (selectedFiles.length > 0) {
                            if (isEditing && originalPlaylistName !== "") {
                                audioPlayer.removePlaylist(originalPlaylistName)
                                audioPlayer.addPlaylist(playlistName.text, selectedFiles)
                            }
                            else audioPlayer.addPlaylist(playlistName.text, selectedFiles)
                            let newArr = new Array(audioPlayer.filePaths.length)
                            newArr.fill(false)
                            root.checkedStates = newArr
                            isEditing = false
                            originalPlaylistName = ""
                            playlistDialog.accept()
                        }
                    }
                }

                Button {
                    text: "Cancel"
                    flat: true
                    onClicked: {
                        isEditing = false
                        originalPlaylistName = ""
                        playlistDialog.showError = false
                        playlistDialog.reject()
                    }
                }
            }
        }
    }

    File_List {
        id: playlistFilesView
        visible: false
        anchors.fill: parent
        baseSource: files
        property var files: []
        onFilteredFilesChanged: audioPlayer.setCurSongList(filteredFiles)

        Image_Button {
            id: backButton
            image: "assets/icons/back.png"
            anchors {
                right: parent.left
                rightMargin: 15
                top: parent.top
                topMargin: 5
            }
            onClicked: {
                playlistFilesView.visible = false
                audioPlayer.setCurSongList(audioPlayer.filePaths)
                playlistFilesView.searchQuery = ""
            }
        }
    }
}
