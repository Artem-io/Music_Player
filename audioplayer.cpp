#include "audioplayer.h"

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent), curId(-1)
{
    audioOutput = new QAudioOutput(this);
    player = new QMediaPlayer(this);
    player->setAudioOutput(audioOutput);
    audioOutput->setVolume(0.2);

    connect(player, &QMediaPlayer::playbackStateChanged, this, &AudioPlayer::playingStateChanged);
    connect(player, &QMediaPlayer::positionChanged, this, &AudioPlayer::positionChanged);
}

void AudioPlayer::setFiles(const QStringList& fileUrls)
{
    //qDebug() << "setFiles() called with URLs:" << fileUrls;
    filePaths.clear();
    fileDurations.clear();

    QMediaPlayer tempPlayer;

    for (const QString &url : fileUrls) {
        QString localFile = QUrl(url).toLocalFile();

        if (!localFile.isEmpty()) {
            filePaths.append(localFile);
            tempPlayer.setSource(QUrl::fromLocalFile(localFile));
            // Wait for metadata to load synchronously
            while (tempPlayer.mediaStatus() != QMediaPlayer::LoadedMedia &&
                   tempPlayer.mediaStatus() != QMediaPlayer::InvalidMedia) {
                QCoreApplication::processEvents();
            }
            int duration = tempPlayer.duration();
            fileDurations.append(duration);
            //qDebug() << "Loaded duration for" << localFile << ":" << duration << "ms";
        }
    }

    // qDebug() << "Files set:" << filePaths;
    // qDebug() << "Durations set:" << fileDurations;


    if (!filePaths.isEmpty()) {
        curId = 0;
        player->setSource(QUrl::fromLocalFile(filePaths[curId]));
        emit filePathsChanged();
        emit fileDurationsChanged();
        emit curIdChanged();
    }

    else {
        curId = -1;
        emit filePathsChanged();
        emit fileDurationsChanged();
        emit curIdChanged();
    }
}

void AudioPlayer::setCurId(int id) {
    if (curId != id) {
        curId = id;
        if (curId >= 0 && curId < filePaths.size()) {
            player->setSource(QUrl::fromLocalFile(filePaths[curId]));
            emit curIdChanged();
        }
    }
}

void AudioPlayer::togglePlayPause()
{
    if (player->playbackState() == QMediaPlayer::PlayingState) player->pause();
    else player->play();
    emit playingStateChanged();
}

void AudioPlayer::setPosition(int pos)
{
    player->setPosition(pos);
    emit positionChanged(pos);
}

void AudioPlayer::setVolume(float vol)
{
    audioOutput->setVolume(vol);
    emit volumeChanged();
}
