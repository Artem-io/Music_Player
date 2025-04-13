import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import AudioPlayer 1.0

Item {
    id: root
    width: 500
    height: 530
    property color textColor: "#E6E6E6"

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
            playlistDialog.open()
        }
    }

    property var checkedStates: {
        let arr = new Array(audioPlayer.filePaths.length)
        arr.fill(false)
        return arr
    }

    ListModel {
        id: playlistModel
        Component.onCompleted: {
            let initialPlaylists = []
            for (var key in audioPlayer.playlists) {
                initialPlaylists.push(key)
            }
            for (var i = 0; i < initialPlaylists.length; i++) {
                append({ "name": initialPlaylists[i] })
            }
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
                    model: ["Delete", "Add Song", "Remove Song", "Rename"]
                    spacing: 2

                    delegate: ItemDelegate {
                        width: parent.width
                        height: 40

                        contentItem: Text {
                            text: modelData
                            color: textColor
                            font.pointSize: 13
                            anchors.centerIn: parent
                        }

                        background: Rectangle {
                            color: hovered ? "#343840" : "#424752"
                            radius: 16
                        }

                        onClicked: {
                            switch (modelData) {
                            case "Delete":
                                audioPlayer.removePlaylist(name)
                                break

                            case "Add Song":
                                playlistName.text = name
                                let newArr = new Array(audioPlayer.filePaths.length)
                                newArr.fill(false)
                                let currentFiles = audioPlayer.playlists[name]
                                for (let i = 0; i < audioPlayer.filePaths.length; i++)
                                    if (currentFiles.includes(audioPlayer.filePaths[i])) newArr[i] = true
                                root.checkedStates = newArr
                                playlistDialog.open()
                                break

                            case "Remove Song":
                                removeSongDialog.files = audioPlayer.playlists[name]
                                removeSongDialog.open()
                                break

                            case "Rename":
                                renameDialog.oldName = name
                                renameDialog.newName = name
                                renameDialog.open()
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
        id: playlistDialog
        title: "Create/Edit Playlist"
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        anchors.centerIn: parent

        Column {
            spacing: 10
            width: 300

            TextField {
                id: playlistName
                width: parent.width
                placeholderText: "Playlist Name"
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
        }

        onAccepted: {
            let selectedFiles = []
            for (let i = 0; i < audioPlayer.filePaths.length; i++)
                if (root.checkedStates[i]) selectedFiles.push(audioPlayer.filePaths[i])

            if (playlistName.text && selectedFiles.length > 0) {
                audioPlayer.addPlaylist(playlistName.text, selectedFiles)
                let newArr = new Array(audioPlayer.filePaths.length)
                newArr.fill(false)
                root.checkedStates = newArr
            }
        }
    }

    Dialog {
        id: removeSongDialog
        title: "Remove Song"
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        anchors.centerIn: parent

        property var files: []

        Column {
            spacing: 10
            width: 300

            ListView {
                width: parent.width
                height: 200
                model: removeSongDialog.files
                clip: true

                delegate: CheckDelegate {
                    width: parent.width
                    text: modelData.split('/').pop()
                    checked: false
                    onCheckedChanged:
                        if (checked) removeSongDialog.files = removeSongDialog.files.filter(f => f !== modelData)
                }
            }
        }

        onAccepted: audioPlayer.addPlaylist(playlistName.text, removeSongDialog.files)
    }

    Dialog {
        id: renameDialog
        title: "Rename Playlist"
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        anchors.centerIn: parent

        property string oldName: ""
        property string newName: ""

        TextField {
            id: renameField
            width: 300
            text: renameDialog.newName
            placeholderText: "New Playlist Name"
            onTextChanged: renameDialog.newName = text
        }

        onAccepted: {
            if (renameDialog.newName && renameDialog.newName !== renameDialog.oldName) {
                let playlistFiles = audioPlayer.playlists[renameDialog.oldName]
                audioPlayer.removePlaylist(renameDialog.oldName)
                audioPlayer.addPlaylist(renameDialog.newName, playlistFiles)
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
