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
    filePaths.clear();
    fileDurations.clear();

    for (const QString& url: fileUrls) {
        QString localFile = QUrl(url).toLocalFile();

        if (!localFile.isEmpty()) {
            filePaths.append(localFile);
            player->setSource(QUrl::fromLocalFile(localFile));

            while (player->mediaStatus() != QMediaPlayer::LoadedMedia &&
                   player->mediaStatus() != QMediaPlayer::InvalidMedia)
                QCoreApplication::processEvents();

            fileDurations.append(player->duration());
        }
    }

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

    savePaths(fileUrls);
}

void AudioPlayer::setCurId(int id)
{
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

void AudioPlayer::savePaths(const QStringList &)
{

}



// void AudioPlayer::loadFilesFromFolder(const QString& folderPath)
// {
//     QDir dir(folderPath);
//     if (!dir.exists()) return;

//     QStringList musicFiles = dir.entryList(QStringList() << "*.mp3" << "*.m4a" << "*.wav" << "*.aac" << "*.opus", QDir::Files);
//     if (musicFiles.isEmpty()) return;

//     QStringList fullPaths;
//     for (const QString &file : musicFiles) {
//         fullPaths.append(dir.absoluteFilePath(file));
//     }

//     setFiles(fullPaths);
//     //saveFolderPath(folderPath);
// }
