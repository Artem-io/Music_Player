#include "audioplayer.h"

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent), curId(-1)
{
    audioOutput = new QAudioOutput(this);
    player = new QMediaPlayer(this);
    player->setAudioOutput(audioOutput);
    audioOutput->setVolume(0.2);

    connect(player, &QMediaPlayer::playbackStateChanged, this, &AudioPlayer::playingStateChanged);
    connect(player, &QMediaPlayer::positionChanged, this, &AudioPlayer::positionChanged);

    loadLastFiles();
    loadFavourites();
}

void AudioPlayer::setFiles(const QStringList& fileUrls)
{
    filePaths.clear();
    fileDurations.clear();

    for (const QString &url : fileUrls) {
        QString localFile;
        if (url.startsWith("file://")) localFile = QUrl(url).toLocalFile();
        else localFile = url;

        if (!localFile.isEmpty() && QFileInfo(localFile).exists()) {
            filePaths.append(localFile);
            player->setSource(QUrl::fromLocalFile(localFile));
            while (player->mediaStatus() != QMediaPlayer::LoadedMedia &&
                   player->mediaStatus() != QMediaPlayer::InvalidMedia) {
                QCoreApplication::processEvents();
            }
            fileDurations.append(player->duration());
            //qDebug() << "Added file:" << localFile << "Duration:" << player->duration();
        }
        else qDebug() << "Skipped invalid or missing file:" << url;
    }

    if (!filePaths.isEmpty()) {
        curId = 0;
        player->setSource(QUrl::fromLocalFile(filePaths[curId]));
        saveFilePaths(filePaths);
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

void AudioPlayer::loadLastFiles()
{
    QStringList lastFiles = getLastFilePaths();
    if (!lastFiles.isEmpty()) setFiles(lastFiles);
}

void AudioPlayer::saveFilePaths(const QStringList &filePaths)
{
    QSettings settings("YourName", "MusicPlayer");
    settings.setValue("lastFiles", filePaths);
}

QStringList AudioPlayer::getLastFilePaths()
{
    QSettings settings("YourName", "MusicPlayer");
    QStringList lastFiles = settings.value("lastFiles", QStringList()).toStringList();
    return lastFiles;
}

void AudioPlayer::toggleFavourite(const QString& filePath)
{
    if (favourites.contains(filePath)) favourites.removeAll(filePath);
    else favourites.append(filePath);

    saveFavourites();
    emit favouritesChanged();
}

void AudioPlayer::saveFavourites()
{
    QSettings settings("YourName", "MusicPlayer");
    settings.setValue("favourites", favourites);
}

void AudioPlayer::loadFavourites()
{
    QSettings settings("YourName", "MusicPlayer");
    favourites = settings.value("favourites", QStringList()).toStringList();
}
