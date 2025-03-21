import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: parent.width
    height: Math.min(100, parent.height * 0.15)
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
                id: prev
                text: "Previous"
                enabled: audioPlayer.curId > 0
                onClicked: {
                    audioPlayer.curId--
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause();
                }
            }

            Button {
                id: playPause
                text: audioPlayer.isPlaying ? "Pause" : "Play"
                enabled: audioPlayer.curId >= 0 && audioPlayer.curId < audioPlayer.filePaths.length
                onClicked: {
                    audioPlayer.togglePlayPause();
                    //console.log("play/pause clicked. audioPlayer.isPlaying:", audioPlayer.isPlaying);
                    //console.log("File path length: ", audioPlayer.filePaths.length)
                }
            }

            Button {
                id: next
                text: "Next"
                enabled: audioPlayer.curId < audioPlayer.filePaths.length-1
                onClicked: {
                    audioPlayer.curId++
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause(); // [Add] Ensure playback
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
            to: audioPlayer.duration
            value: audioPlayer.position
            onMoved: audioPlayer.setPosition(value)
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

        Text {
            id: elapsedTime
            text: formatTime(audioPlayer.position)
            anchors.right: progressSlider.left
            anchors.rightMargin: 10
            anchors.verticalCenter: progressSlider.verticalCenter
        }

        Text {
            id: totalTime
            text: formatTime(audioPlayer.duration)
            anchors.left: progressSlider.right
            anchors.leftMargin: 10
            anchors.verticalCenter: progressSlider.verticalCenter
        }
    }

    function formatTime(ms) {
        let seconds = Math.floor(ms / 1000);
        let minutes = Math.floor(seconds / 60);
        seconds = seconds % 60;
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds);
    }
}
