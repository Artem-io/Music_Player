import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import AudioPlayer 1.0

Window {
    width: 1920
    height: 1080
    visible: true
    visibility: Window.Maximized
    title: qsTr("Music Player")

    AudioPlayer {
        id: audioPlayer
    }

    Bottom_Bar {
        id: bottomBar
    }

    File_List {
        id: fileList
        anchors.centerIn: parent
    }

    FileDialog {
        id: fileDialog
        nameFilters: ["MP3 Files (*.mp3 *.m4a *.wav *.aac *.opus)"]
        fileMode: FileDialog.OpenFiles
        onAccepted: audioPlayer.setFiles(fileDialog.selectedFiles);
    }

    Button {
        id: addFilesButton
        text: "Add Files"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        onClicked: fileDialog.open();
    }
}
