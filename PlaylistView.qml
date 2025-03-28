import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import AudioPlayer 1.0

Item {
    id: root
    width: 500
    height: 400

    property var checkedStates: {
        let arr = new Array(audioPlayer.filePaths.length)
        arr.fill(false)
        return arr
    }

    Connections {
        target: audioPlayer
        function onFilePathsChanged() {
            let newArr = new Array(audioPlayer.filePaths.length)
            newArr.fill(false)
            root.checkedStates = newArr
        }
    }

    Column { // all playlists
        id: playlistListView
        anchors.fill: parent
        spacing: 10
        visible: !playlistFilesView.visible

        Button {
            text: "Add Playlist"
            onClicked: {
                playlistName.text = ""
                let newArr = new Array(audioPlayer.filePaths.length)
                newArr.fill(false)
                root.checkedStates = newArr
                playlistDialog.open()
            }
        }

        ListView {
            width: parent.width
            height: parent.height - 50
            model: Object.keys(audioPlayer.playlists)
            clip: true

            delegate: Rectangle {
                width: parent.width
                height: 40
                color: "white"
                border.color: "gray"

                Row {
                    anchors.fill: parent
                    spacing: 10
                    padding: 5

                    Text {
                        text: modelData
                        width: parent.width - 80
                    }

                    Button {
                        id: del
                        text: "Delete"
                        onClicked: audioPlayer.removePlaylist(modelData)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: {
                        if (!del.hovered) {
                            playlistFilesView.files = audioPlayer.playlists[modelData]
                            audioPlayer.setCurSongList(playlistFilesView.filteredFiles)
                            playlistFilesView.visible = true
                            playlistFilesView.searchQuery = ""
                            mouse.accepted = true
                        }
                        else mouse.accepted = false
                    }
                }
            }
        }
    }

    Dialog {
        id: playlistDialog
        title: "Create New Playlist"
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

    File_List {
        id: playlistFilesView
        visible: false
        anchors.fill: parent
        property var files: []

        filteredFiles: {
            if (searchQuery === "") return files
            else {
                return files.filter(function(filePath) {
                    let fileName = filePath.split('/').pop().toLowerCase()
                    return fileName.includes(searchQuery.toLowerCase())
                })
            }
        }
        onFilteredFilesChanged: audioPlayer.setCurSongList(filteredFiles)

        Button {
            id: backButton
            text: "Back"
            anchors.top: parent.top
            anchors.right: parent.left
            anchors.margins: 10
            onClicked: {
                playlistFilesView.visible = false
                audioPlayer.setCurSongList(audioPlayer.filePaths)
                playlistFilesView.searchQuery = ""
            }
        }
    }
}
