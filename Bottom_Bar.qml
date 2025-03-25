import QtQuick
import QtQuick.Controls
import AudioPlayer 1.0

Item {
    id: root
    width: parent.width
    height: 100
    anchors.bottom: parent.bottom

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
                enabled: audioPlayer.curSongList.length > 1
                text: "Shuffle"
                onClicked: {
                    let randomIndex;
                    do randomIndex = Math.floor(Math.random() * audioPlayer.curSongList.length);
                    while (randomIndex === audioPlayer.curId)
                    audioPlayer.setCurId(randomIndex);
                    audioPlayer.togglePlayPause();
                }
            }

            Button {
                id: prev
                text: "Previous"
                enabled: audioPlayer.curId > 0
                onClicked: {
                    audioPlayer.setCurId(audioPlayer.curId - 1);
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause();
                }
            }

            Button {
                id: playPause
                text: audioPlayer.isPlaying ? "Pause" : "Play"
                enabled: audioPlayer.curSongList.length > 0
                onClicked: audioPlayer.togglePlayPause()
            }

            Button {
                id: next
                text: "Next"
                enabled: audioPlayer.curId < audioPlayer.curSongList.length - 1 &&
                         audioPlayer.curSongList.length > 0
                onClicked: {
                    audioPlayer.setCurId(audioPlayer.curId + 1);
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
            to: audioPlayer.curId >= 0 ?
                    audioPlayer.fileDurations[audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])] : 0
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
                text: audioPlayer.curId >= 0 ?
                          formatTime(audioPlayer.fileDurations[audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])]) : "0:00"
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
                if (!audioPlayer.isPlaying && audioPlayer.curSongList.length > 0 &&
                        audioPlayer.position >= audioPlayer.fileDurations[audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])] - 100) {
                    if (audioPlayer.curId < audioPlayer.curSongList.length - 1) {
                        audioPlayer.setCurId(audioPlayer.curId + 1);
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
