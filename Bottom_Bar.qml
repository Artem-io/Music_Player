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
    property string currentPlayer: "audioPlayer"
    property bool crossfadeStarted: false
    property real userVolume: 0.2
    property alias player2: player2
    property alias audioOutput2: audioOutput2
    property alias fadeOutAudioPlayer: fadeOutAudioPlayer
    property alias fadeInAudioPlayer: fadeInAudioPlayer
    property alias fadeInPlayer2: fadeInPlayer2
    property alias fadeOutPlayer2: fadeOutPlayer2
    property bool repeatEnabled: false
    property bool crossfadeTriggered: false

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
        duration: audioPlayer.crossfadeDuration
        easing.type: Easing.Linear
        onStopped: {
            if (currentPlayer === "audioPlayer") {
                audioPlayer.stop()
                if (audioPlayer.curId + 1 < audioPlayer.curSongList.length) {
                    audioPlayer.setCurId(audioPlayer.curId + 1)
                    currentPlayer = "player2"
                    crossfadeStarted = false
                    crossfadeTriggered = false
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
        duration: audioPlayer.crossfadeDuration
        easing.type: Easing.Linear
    }

    NumberAnimation {
        id: fadeInPlayer2
        target: audioOutput2
        property: "volume"
        from: 0
        to: root.userVolume
        duration: audioPlayer.crossfadeDuration
        easing.type: Easing.Linear
    }

    NumberAnimation {
        id: fadeOutPlayer2
        target: audioOutput2
        property: "volume"
        from: root.userVolume
        to: 0
        duration: audioPlayer.crossfadeDuration
        easing.type: Easing.Linear
        onStopped: {
            if (currentPlayer === "player2") {
                player2.stop()
                if (audioPlayer.curId + 1 < audioPlayer.curSongList.length) {
                    player2.source = audioPlayer.curSongList[audioPlayer.curId + 1]
                    currentPlayer = "audioPlayer"
                    crossfadeStarted = false
                    crossfadeTriggered = false
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
                id: repeat
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: 0.65
                image: root.repeatEnabled ? "assets/icons/repeat.png" : "assets/icons/repeat_dis.png"
                onClicked: {
                    crossfadeStarted = false
                    crossfadeTriggered = false
                    repeatEnabled = !repeatEnabled
                }
            }

            Image_Button {
                id: prev
                enabled: audioPlayer.curId > 0
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: -next.scale
                image: enabled ? "assets/icons/next.png" : "assets/icons/next_un.png"
                onClicked: {
                    let newId
                    if (crossfadeStarted) currentPlayer === "audioPlayer" ? newId = audioPlayer.curId - 1 : newId = audioPlayer.curId - 2
                    else newId = audioPlayer.curId - 1
                    fadeOutAudioPlayer.stop()
                    fadeInPlayer2.stop()
                    fadeOutPlayer2.stop()
                    fadeInAudioPlayer.stop()
                    audioPlayer.setCurId(newId)
                    if (currentPlayer === "audioPlayer") {
                        if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                        player2.stop()
                        audioPlayer.setVolume(root.userVolume)
                        audioOutput2.volume = 0
                    }
                    else {
                        player2.source = audioPlayer.curSongList[newId]
                        if (!player2.playing) player2.play()
                        audioPlayer.stop()
                        audioOutput2.volume = root.userVolume
                        audioPlayer.setVolume(0)
                    }
                    crossfadeStarted = false
                    crossfadeTriggered = false
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
                        if (!enabled) "assets/icons/play_un.png"
                        else if (currentPlayer === "audioPlayer") audioPlayer.isPlaying ? "assets/icons/pause.png" : "assets/icons/play.png"
                        else player2.playing ? "assets/icons/pause.png" : "assets/icons/play.png"
                    }
                    onClicked: {
                        if (crossfadeStarted) {
                            fadeOutAudioPlayer.stop()
                            fadeInAudioPlayer.stop()
                            fadeInPlayer2.stop()
                            fadeOutPlayer2.stop()
                            audioPlayer.stop()
                            player2.stop()
                            audioPlayer.setVolume(root.userVolume)
                            audioOutput2.volume = 0
                            crossfadeStarted = false
                            crossfadeTriggered = false
                            currentPlayer = "audioPlayer"
                        }
                        else {
                            if (currentPlayer === "audioPlayer") audioPlayer.togglePlayPause()
                            else player2.playing? player2.pause() : player2.play()
                        }
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
                    let newId
                    if (crossfadeStarted) currentPlayer === "audioPlayer" ? newId = audioPlayer.curId + 1 : newId = audioPlayer.curId
                    else newId = audioPlayer.curId + 1
                    fadeOutAudioPlayer.stop()
                    fadeInPlayer2.stop()
                    fadeOutPlayer2.stop()
                    fadeInAudioPlayer.stop()
                    audioPlayer.setCurId(newId)
                    if (currentPlayer === "audioPlayer") {
                        if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                        player2.stop()
                        audioPlayer.setVolume(root.userVolume)
                        audioOutput2.volume = 0
                    }
                    else {
                        player2.source = audioPlayer.curSongList[newId]
                        if (!player2.playing) player2.play()
                        audioPlayer.stop()
                        audioOutput2.volume = root.userVolume
                        audioPlayer.setVolume(0)
                    }
                    crossfadeStarted = false
                    crossfadeTriggered = false
                }
            }

            Image_Button {
                id: shuffle
                enabled: audioPlayer.curSongList.length > 0
                width: bottomBar.butWidth
                height: bottomBar.butHeight
                scale: 0.65
                image: enabled ? "assets/icons/shuffle.png" : "assets/icons/shuffle_un.png"
                onClicked: {
                    if (audioPlayer.curSongList.length > 0) {
                        fadeOutAudioPlayer.stop()
                        fadeInAudioPlayer.stop()
                        fadeInPlayer2.stop()
                        fadeOutPlayer2.stop()
                        crossfadeStarted = false
                        crossfadeTriggered = false
                        let randomIndex = Math.floor(Math.random() * audioPlayer.curSongList.length)
                        while (randomIndex === audioPlayer.curId) randomIndex = Math.floor(Math.random() * audioPlayer.curSongList.length)
                        audioPlayer.setCurId(randomIndex)
                        if (currentPlayer === "audioPlayer") {
                            if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                            player2.stop()
                            audioPlayer.setVolume(root.userVolume)
                            audioOutput2.volume = 0
                        }
                        else {
                            player2.source = audioPlayer.curSongList[randomIndex]
                            if (!player2.playing) player2.play()
                            audioPlayer.stop()
                            audioOutput2.volume = root.userVolume
                            audioPlayer.setVolume(0)
                        }
                    }
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
                crossfadeStarted = false
                crossfadeTriggered = false
                if (currentPlayer === "audioPlayer") audioPlayer.setPosition(value)
                else player2.position = value
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
                if (crossfadeStarted || crossfadeTriggered) return

                if (currentPlayer === "audioPlayer") {
                    if (audioPlayer.curId >= 0 && audioPlayer.curId < audioPlayer.curSongList.length) {
                        let index = audioPlayer.filePaths.indexOf(audioPlayer.curSongList[audioPlayer.curId])
                        let duration = index >= 0 ? audioPlayer.fileDurations[index] : 0
                        let remainingTime = (duration - audioPlayer.position) / 1000

                        if (audioPlayer.crossfadeEnabled && remainingTime <= (audioPlayer.crossfadeDuration / 1000) && remainingTime > (audioPlayer.crossfadeDuration / 1000 - 0.1) && !repeatEnabled && audioPlayer.curId + 1 < audioPlayer.curSongList.length) {
                            crossfadeStarted = true
                            crossfadeTriggered = true
                            player2.source = audioPlayer.curSongList[audioPlayer.curId + 1]
                            player2.play()
                            fadeOutAudioPlayer.start()
                            fadeInPlayer2.start()
                        }
                        else if (remainingTime <= 0.3) {
                            if (repeatEnabled) {
                                audioPlayer.setPosition(0)
                                if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                            }
                            else if (audioPlayer.curId + 1 < audioPlayer.curSongList.length) {
                                fadeOutAudioPlayer.stop()
                                fadeInPlayer2.stop()
                                fadeOutPlayer2.stop()
                                fadeInAudioPlayer.stop()
                                audioPlayer.setCurId(audioPlayer.curId + 1)
                                audioPlayer.setVolume(root.userVolume)
                                audioOutput2.volume = 0
                                player2.stop()
                                if (!audioPlayer.isPlaying) audioPlayer.togglePlayPause()
                                currentPlayer = "audioPlayer"
                                crossfadeStarted = false
                                crossfadeTriggered = false
                            }
                            else {
                                audioPlayer.setPosition(0)
                                audioPlayer.stop()
                                currentPlayer = "audioPlayer"
                                crossfadeStarted = false
                                crossfadeTriggered = false
                            }
                        }
                    }
                }
                else {
                    let remainingTime = (player2.duration - player2.position) / 1000
                    if (audioPlayer.crossfadeEnabled && remainingTime <= (audioPlayer.crossfadeDuration / 1000) && remainingTime > (audioPlayer.crossfadeDuration / 1000 - 0.1) && !repeatEnabled && audioPlayer.curId + 1 < audioPlayer.curSongList.length) {
                        crossfadeStarted = true
                        crossfadeTriggered = true
                        audioPlayer.setCurId(audioPlayer.curId + 1)
                        audioPlayer.togglePlayPause()
                        fadeOutPlayer2.start()
                        fadeInAudioPlayer.start()
                    }
                    else if (remainingTime <= 0.3) {
                        if (repeatEnabled) {
                            player2.position = 0
                            if (!player2.playing) player2.play()
                        }
                        else if (audioPlayer.curId + 1 < audioPlayer.curSongList.length) {
                            fadeOutAudioPlayer.stop()
                            fadeInPlayer2.stop()
                            fadeOutPlayer2.stop()
                            fadeInAudioPlayer.stop()
                            audioPlayer.setCurId(audioPlayer.curId + 1)
                            audioPlayer.setVolume(root.userVolume)
                            audioOutput2.volume = 0
                            player2.stop()
                            audioPlayer.togglePlayPause()
                            currentPlayer = "audioPlayer"
                            crossfadeStarted = false
                            crossfadeTriggered = false
                        }
                        else {
                            player2.position = 0
                            player2.stop()
                            currentPlayer = "audioPlayer"
                            crossfadeStarted = false
                            crossfadeTriggered = false
                        }
                    }
                }
            }
        }

        Slider {
            id: volumeSlider
            width: 250 * widthFactor
            anchors.right: parent.right
            anchors.rightMargin: 40 * widthFactor
            anchors.verticalCenter: progressSlider.verticalCenter
            from: 0
            to: 1
            value: root.userVolume
            onMoved: {
                if (!crossfadeStarted) {
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
                        if (volumeSlider.value === 0) "assets/icons/volume_null.png"
                        else volumeSlider.value < 0.5 ? "assets/icons/volume_half.png" : "assets/icons/volume_full.png"
                    }
                    width: 25
                    height: 25
                    anchors.right: parent.left
                    anchors.rightMargin: 20 * widthFactor
                    y: -7
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
