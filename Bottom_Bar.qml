import QtQuick
import QtQuick.Controls
import AudioPlayer 1.0

Item {
    id: root
    width: parent.width
    height: 100
    anchors.bottom: parent.bottom

    property string currentTab: "Library"
    property var activeFilteredFiles: []

    Connections {
        target: contentLoader.item
        function onFilteredFilesChanged() {
            if (contentLoader.item && "filteredFiles" in contentLoader.item) {
                activeFilteredFiles = contentLoader.item.filteredFiles;
            }
        }
    }

    Rectangle {
        id: bottomBar
        anchors.fill: parent
        color: "lightgrey"

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            spacing: 20

            Button {
                id: shuffle
                enabled: activeFilteredFiles.length > 0 || (currentTab === "Favourites" ? audioPlayer.favourites.length > 0 : audioPlayer.filePaths.length > 0)
                text: "Shuffle"
                onClicked: {
                    let songList = activeFilteredFiles.length > 0 ? activeFilteredFiles : (currentTab === "Favourites" ? audioPlayer.favourites : audioPlayer.filePaths);
                    if (songList.length > 0) {
                        let randomIndex = Math.floor(Math.random() * songList.length);
                        let randomFilePath = songList[randomIndex];
                        let originalIndex = audioPlayer.filePaths.indexOf(randomFilePath);
                        audioPlayer.setCurId(originalIndex);
                        audioPlayer.togglePlayPause();
                    }
                }
            }

            Button {
                id: prev
                text: "Previous"
                enabled: {
                    let songList = activeFilteredFiles.length > 0 ? activeFilteredFiles : (currentTab === "Favourites" ? audioPlayer.favourites : audioPlayer.filePaths);
                    let currentIndex = songList.indexOf(audioPlayer.filePaths[audioPlayer.curId]);
                    return currentIndex > 0 && songList.length > 0;
                }
                onClicked: {
                    let songList = activeFilteredFiles.length > 0 ? activeFilteredFiles : (currentTab === "Favourites" ? audioPlayer.favourites : audioPlayer.filePaths);
                    let currentIndex = songList.indexOf(audioPlayer.filePaths[audioPlayer.curId]);
                    if (currentIndex > 0) {
                        let newIndex = currentIndex - 1;
                        let newFilePath = songList[newIndex];
                        audioPlayer.setCurId(audioPlayer.filePaths.indexOf(newFilePath));
                    }
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause();
                }
            }

            Button {
                id: playPause
                text: audioPlayer.isPlaying ? "Pause" : "Play"
                enabled: audioPlayer.filePaths.length > 0
                onClicked: audioPlayer.togglePlayPause()
            }

            Button {
                id: next
                text: "Next"
                enabled: {
                    let songList = activeFilteredFiles.length > 0 ? activeFilteredFiles : (currentTab === "Favourites" ? audioPlayer.favourites : audioPlayer.filePaths);
                    let currentIndex = songList.indexOf(audioPlayer.filePaths[audioPlayer.curId]);
                    return currentIndex < songList.length - 1 && songList.length > 0;
                }
                onClicked: {
                    let songList = activeFilteredFiles.length > 0 ? activeFilteredFiles : (currentTab === "Favourites" ? audioPlayer.favourites : audioPlayer.filePaths);
                    let currentIndex = songList.indexOf(audioPlayer.filePaths[audioPlayer.curId]);
                    if (currentIndex < songList.length - 1) {
                        let newIndex = currentIndex + 1;
                        let newFilePath = songList[newIndex];
                        audioPlayer.setCurId(audioPlayer.filePaths.indexOf(newFilePath));
                    }
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause();
                }
            }
        }

        Slider {
            id: progressSlider
            width: Math.min(550, parent.width * 0.5)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            from: 0
            to: audioPlayer.curId >= 0 ? audioPlayer.fileDurations[audioPlayer.curId] : 0
            value: audioPlayer.position >= 0 ? audioPlayer.position : 0
            onMoved: audioPlayer.setPosition(value)

            Text {
                id: elapsedTime
                text: formatTime(audioPlayer.position)
                anchors.right: progressSlider.left
                anchors.rightMargin: 10
                anchors.verticalCenter: progressSlider.verticalCenter
            }

            Text {
                id: totalTime
                text: audioPlayer.curId >= 0 ? formatTime(audioPlayer.fileDurations[audioPlayer.curId]) : "0:00"
                anchors.left: progressSlider.right
                anchors.leftMargin: 10
                anchors.verticalCenter: progressSlider.verticalCenter
            }
        }

        Slider {
            id: volumeSlider
            width: Math.min(250, parent.width * 0.2)
            anchors.right: parent.right
            anchors.rightMargin: 40
            anchors.verticalCenter: progressSlider.verticalCenter
            from: 0
            to: 1
            value: audioPlayer.volume
            onMoved: audioPlayer.setVolume(value)
        }

        Connections {
            target: audioPlayer
            function onPlayingStateChanged() {
                if (!audioPlayer.isPlaying &&
                    audioPlayer.position >= audioPlayer.fileDurations[audioPlayer.curId] - 100) {
                    let songList = activeFilteredFiles.length > 0 ? activeFilteredFiles : (currentTab === "Favourites" ? audioPlayer.favourites : audioPlayer.filePaths);
                    let currentIndex = songList.indexOf(audioPlayer.filePaths[audioPlayer.curId]);
                    if (currentIndex < songList.length - 1) {
                        let newIndex = currentIndex + 1;
                        let newFilePath = songList[newIndex];
                        audioPlayer.setCurId(audioPlayer.filePaths.indexOf(newFilePath));
                        audioPlayer.togglePlayPause();
                    }
                }
            }
        }
    }

    function formatTime(ms) {
        let seconds = Math.floor(ms / 1000);
        let minutes = Math.floor(seconds / 60);
        seconds = seconds % 60;
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds);
    }
}
