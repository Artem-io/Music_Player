import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Effects
import QtMultimedia
import AudioPlayer 1.0

Item {
    id: root
    width: parent.width
    height: 100
    anchors.bottom: parent.bottom
    property color textColor: "#D9D9D9"
    property real widthFactor: Window.width / 1536
    property int crossfadeDuration: 5000
    property string currentPlayer: "audioPlayer"
    property bool crossfadeStarted: false
    property real userVolume: 0.2

    MediaPlayer {
        id: player2
        audioOutput: AudioOutput {
            id: audioOutput2
            volume: 0
        }
    }

    NumberAnimation {
        id: fadeOutAudioPlayer
        target: audioPlayer
        property: "volume"
        from: root.userVolume
        to: 0
        duration: root.crossfadeDuration
        easing.type: Easing.Linear
        onStopped: {
            if (currentPlayer === "audioPlayer") {
                audioPlayer.stop()
                if (audioPlayer.curId +1 < audioPlayer.curSongList.length) {
                    audioPlayer.setCurId(audioPlayer.curId + 1)
                    currentPlayer = "player2"
                    crossfadeStarted = false
                }
            }
        }
    }

    NumberAnimation {
        id: fadeInAudioPlayer
        target: audioPlayer
        property: "volume"
        from: 0
        to: root.userVolume
        duration: root.crossfadeDuration
        easing.type: Easing.Linear
    }

    NumberAnimation {
        id: fadeInPlayer2
        target: audioOutput2
        property: "volume"
        from: 0
        to: root.userVolume
        duration: root.crossfadeDuration
        easing.type: Easing.Linear
    }

    NumberAnimation {
        id: fadeOutPlayer2
        target: audioOutput2
        property: "volume"
        from: root.userVolume
        to: 0
        duration: root.crossfadeDuration
        easing.type: Easing.Linear
        onStopped: {
            if (currentPlayer === "player2") {
                player2.stop()
                if (audioPlayer.curId +1 < audioPlayer.curSongList.length) {
                    player2.source = audioPlayer.curSongList[audioPlayer.curId + 1]
                    currentPlayer = "audioPlayer"
                    crossfadeStarted = false
                }
            }
        }
    }

    Rectangle {
        id: bottomBar
        anchors.fill: parent
        color: "#272A2E"
        property int butWidth: 30
        property int butHeight: 32

        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            spacing: 27 * widthFactor

            Image_Button {
                id: prev
                enabled: audioPlayer.curId > 0
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: -next.scale
                image: enabled ? "assets/icons/next.png" : "assets/icons/next_un.png"
                onClicked: {
                    audioPlayer.setCurId(audioPlayer.curId - 1)
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                    player2.stop()
                    audioOutput1.volume = 0.2
                    audioOutput2.volume = 0
                    currentPlayer = "audioPlayer"
                    crossfadeStarted = false
                }
            }

            Item {
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                MultiEffect {
                    id: glowEffect
                    anchors.fill: playPause
                    source: playPause
                    blurEnabled: true
                    blurMax: 25
                    blur: 2.0
                    colorization: 1.0
                    colorizationColor: "#E63555"
                    brightness: audioPlayer.isPlaying ? 0.5 : 0.35
                    opacity: playPause.enabled ? 1 : 0
                }

                Image_Button {
                    id: playPause
                    enabled: audioPlayer.curSongList.length > 0
                    width: bottomBar.butWidth
                    height: bottomBar.butHeight
                    scale: 1.4
                    image: {
                        if(!enabled) "assets/icons/play_un.png"
                        else if(currentPlayer === "audioPlayer") audioPlayer.isPlaying? "assets/icons/pause.png" : "assets/icons/play.png"
                        else player2.playing? "assets/icons/pause.png" : "assets/icons/play.png"
                    }
                    onClicked: {
                        if(currentPlayer === "audioPlayer") audioPlayer.togglePlayPause()
                        else player2.playing? player2.pause() : player2.play()
                    }
                }
            }

            Image_Button {
                id: next
                enabled: audioPlayer.curId < audioPlayer.curSongList.length - 1 && audioPlayer.curSongList.length > 0
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: 0.8
                image: enabled ? "assets/icons/next.png" : "assets/icons/next_un.png"
                onClicked: {
                    audioPlayer.setCurId(audioPlayer.curId + 1)
                    if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                    player2.stop()
                    audioOutput1.volume = 0.2
                    audioOutput2.volume = 0
                    currentPlayer = "audioPlayer"
                    crossfadeStarted = false
                }
            }
        }

        Slider {
            id: progressSlider
            width: 550 * widthFactor
            anchors {
                left: parent.left
                leftMargin: 500 * widthFactor
                bottom: parent.bottom
                bottomMargin: 20
            }
            from: 0
            to: {
                if (audioPlayer.curId >= 0 && audioPlayer.curId < audioPlayer.curSongList.length) {
                    let index = audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])
                    return index >= 0 ? audioPlayer.fileDurations[index] : 0
                }
                return 0
            }
            value: currentPlayer === "audioPlayer" ? audioPlayer.position : player2.position
            onMoved: {
                if (currentPlayer === "audioPlayer") audioPlayer.setPosition(value)
                else player2.position = value
                crossfadeStarted = false
            }

            background: Rectangle {
                x: progressSlider.leftPadding
                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                width: progressSlider.availableWidth
                height: 8
                radius: 20
                color: "#0D0D0D"

                Rectangle {
                    width: progressSlider.visualPosition * parent.width
                    height: parent.height
                    color: "#D9D9D9"
                    radius: 20
                }
            }

            handle: Rectangle {
                color: "transparent"
            }

            Text {
                id: elapsedTime
                color: textColor
                text: formatTime(currentPlayer === "audioPlayer" ? audioPlayer.position : player2.position)
                font.bold: true
                font.pointSize: 11
                anchors.right: progressSlider.left
                anchors.rightMargin: 10 * widthFactor
                anchors.verticalCenter: progressSlider.verticalCenter
            }

            Text {
                id: totalTime
                color: textColor
                font.pointSize: 11
                font.bold: true
                text: audioPlayer.curId >= 0 && audioPlayer.curId < audioPlayer.curSongList.length ?
                          formatTime(audioPlayer.fileDurations[audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])]) : "0:00"
                anchors.left: progressSlider.right
                anchors.leftMargin: 10 * widthFactor
                anchors.verticalCenter: progressSlider.verticalCenter
            }

            onValueChanged: {
                if (crossfadeStarted) return

                else if (currentPlayer === "audioPlayer") {
                    if (audioPlayer.curId >= 0 && audioPlayer.curId < audioPlayer.curSongList.length) {
                        let index = audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])
                        let duration = index >= 0 ? audioPlayer.fileDurations[index] : 0
                        let remainingTime = (duration - audioPlayer.position) / 1000
                        if (remainingTime <= 5 && audioPlayer.curId + 1 < audioPlayer.curSongList.length) {
                            crossfadeStarted = true
                            player2.source = audioPlayer.curSongList[audioPlayer.curId + 1]
                            player2.play()
                            fadeOutAudioPlayer.start()
                            fadeInPlayer2.start()
                        }
                    }
                }
                else {
                    let remainingTime = (player2.duration - player2.position) / 1000
                    if (remainingTime <= 5 && audioPlayer.curId + 1 < audioPlayer.curSongList.length) {
                        crossfadeStarted = true
                        audioPlayer.setCurId(audioPlayer.curId + 1)
                        audioPlayer.togglePlayPause()
                        fadeOutPlayer2.start()
                        fadeInAudioPlayer.start()
                    }
                }
            }
        }

        Slider {
            id: volumeSlider
            width: 250
            anchors.right: parent.right
            anchors.rightMargin: 40
            anchors.verticalCenter: progressSlider.verticalCenter
            from: 0
            to: 1
            value: root.userVolume
            onMoved: {
                if(!crossfadeStarted) {
                    root.userVolume = value
                    audioOutput2.volume = value
                    audioPlayer.setVolume(value)
                }
            }

            background: Rectangle {
                x: volumeSlider.leftPadding
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                width: volumeSlider.availableWidth
                height: 8
                radius: 20
                color: "#0D0D0D"

                Rectangle {
                    width: volumeSlider.visualPosition * parent.width
                    height: parent.height
                    color: "#D9D9D9"
                    radius: 20
                }

                Image_Button {
                    image: {
                        if(volumeSlider.value === 0) "assets/icons/volume_null.png"
                        else volumeSlider.value<0.5? "assets/icons/volume_half.png" : "assets/icons/volume_full.png"
                    }
                    width: 25
                    height: 25
                    anchors.right: parent.left
                    anchors.rightMargin: 20
                    y: -7

                    onClicked: audioPlayer.volume? audioPlayer.setVolume(0) : audioPlayer.setVolume(0.2)
                }
            }

            handle: Rectangle {
                color: "transparent"
            }
        }
    }

    function formatTime(ms) {
        if (isNaN(ms) || ms <= 0) return "0:00"
        let seconds = Math.floor(ms / 1000)
        let minutes = Math.floor(seconds / 60)
        seconds = seconds % 60
        return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
    }
}
