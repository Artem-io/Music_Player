import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Controls.Material
import AudioPlayer 1.0

ApplicationWindow {
    width: 1920
    height: 1080
    visible: true
    visibility: Window.Maximized
    title: qsTr("Music Player")
    color: "#262626"

    AudioPlayer {
        id: audioPlayer
    }

    Side_Bar {
        id: sideBar
    }

    Loader {
        anchors.centerIn: parent
        id: contentLoader
        sourceComponent: {
            switch (sideBar.selectedTab) {
            case "Library": return libraryComponent;
            case "Favourites": return likedComponent;
            case "Playlists": return playlistComponent;
            case "Settings": return settings;
            default: return libraryComponent;
            }
        }
    }

    Component {
        id: libraryComponent
        File_List {
            id: library
            anchors.centerIn: parent
            Component.onCompleted: audioPlayer.setCurSongList(filteredFiles)
            onFilteredFilesChanged: audioPlayer.setCurSongList(filteredFiles)
        }
    }

    Component {
        id: likedComponent
        File_List {
            id: liked
            anchors.centerIn: parent
            filteredFiles: {
                if (searchQuery === "") return audioPlayer.favourites;
                else {
                    return audioPlayer.favourites.filter(function(filePath) {
                        let fileName = filePath.split('/').pop().toLowerCase();
                        return fileName.includes(searchQuery.toLowerCase());
                    });
                }
            }
            Component.onCompleted: audioPlayer.setCurSongList(filteredFiles)
            onFilteredFilesChanged: audioPlayer.setCurSongList(filteredFiles)
        }
    }

    Component {
        id: playlistComponent
        PlaylistView {
            anchors.centerIn: parent
        }
    }

    Component {
        id: settings
        Rectangle {
            anchors.fill: parent
            Text {
                anchors.centerIn: parent
                text: "Settings (Not Implemented Yet)"
            }
        }
    }

    Bottom_Bar {
        id: bottomBar
        anchors.bottom: parent.bottom
        width: parent.width
    }

    FileDialog {
        id: fileDialog
        nameFilters: ["Audio Files (*.mp3 *.m4a *.wav *.aac *.opus)"]
        fileMode: FileDialog.OpenFiles
        onAccepted: audioPlayer.setFiles(fileDialog.selectedFiles)
    }

    Button {
        id: addFiles
        text: "Add Files"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        onClicked: fileDialog.open()
    }
}
