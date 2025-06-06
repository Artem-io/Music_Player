#include "audioplayer.h"

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent), curId(-1), m_crossfadeEnabled(false)
{
    audioOutput = new QAudioOutput(this);
    player = new QMediaPlayer(this);
    player->setAudioOutput(audioOutput);
    audioOutput->setVolume(0.2);

    connect(player, &QMediaPlayer::playbackStateChanged, this, &AudioPlayer::playingStateChanged);
    connect(player, &QMediaPlayer::positionChanged, this, &AudioPlayer::positionChanged);

    qRegisterMetaType<PlayCountMap>("PlayCountMap");
    qRegisterMetaType<LastPlayedMap>("LastPlayedMap");

    loadLastFiles();
    loadFavourites();
    loadPlaylists();
    loadPlayData();

    if (!filePaths.isEmpty()) {
        curSongList = filePaths;
    } else {
        curSongList.clear();
    }

    QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());
    m_crossfadeEnabled = settings.value("crossfadeEnabled", false).toBool();
    m_crossfadeDuration = settings.value("crossfadeDuration", 5000).toInt();
}

QStringList AudioPlayer::getPlaylistSongs(const QString& playlistName) const
{
    if (playlists.contains(playlistName)) {
        return playlists[playlistName].toStringList();
    }
    return QStringList();
}

void AudioPlayer::setFolder(const QString& folderPath)
{
    QString localFolder;
    if (folderPath.startsWith("file:")) {
        localFolder = QUrl(folderPath).toLocalFile();
    } else {
        localFolder = folderPath;
    }

    if (localFolder.isEmpty() || !QDir(localFolder).exists()) {
        qDebug() << "AudioPlayer: Invalid or non-existent folder:" << localFolder;
        return;
    }

    m_lastFolderPath = localFolder;
    saveLastFolderPath(localFolder);

    filePaths.clear();
    fileDurations.clear();

    QStringList nameFilters = {"*.mp3", "*.m4a", "*.wav", "*.aac", "*.opus"};
    QDir dir(localFolder);
    dir.setNameFilters(nameFilters);
    dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);

    QStringList audioFiles = dir.entryList();
    for (const QString& fileName : audioFiles) {
        QString filePath = dir.absoluteFilePath(fileName);
        if (QFileInfo(filePath).exists()) {
            filePaths.append(filePath);
            player->setSource(QUrl::fromLocalFile(filePath));
            while (player->mediaStatus() != QMediaPlayer::LoadedMedia &&
                   player->mediaStatus() != QMediaPlayer::InvalidMedia) {
                QCoreApplication::processEvents();
            }
            fileDurations.append(player->duration());
        } else {
            qDebug() << "AudioPlayer: Skipped invalid or missing file:" << filePath;
        }
    }

    if (!filePaths.isEmpty()) {
        curId = 0;
        curSongList = filePaths;
        player->setSource(QUrl::fromLocalFile(filePaths[curId]));
        saveFilePaths(filePaths);
        emit filePathsChanged();
        emit fileDurationsChanged();
        emit curIdChanged();
        emit curSongListChanged();
    } else {
        curId = -1;
        curSongList.clear();
        emit filePathsChanged();
        emit fileDurationsChanged();
        emit curIdChanged();
        emit curSongListChanged();
    }
}

void AudioPlayer::setCrossfadeEnabled(bool enabled)
{
    if (m_crossfadeEnabled != enabled) {
        m_crossfadeEnabled = enabled;
        QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());
        settings.setValue("crossfadeEnabled", m_crossfadeEnabled);
        emit crossfadeStateChanged();
    }
}

void AudioPlayer::setCrossfadeDuration(int duration)
{
    if (m_crossfadeDuration != duration && duration >= 1000 && duration <= 10000) {
        m_crossfadeDuration = duration;
        QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());
        settings.setValue("crossfadeDuration", m_crossfadeDuration);
        emit crossfadeDurationChanged();
    }
}

void AudioPlayer::setFiles(const QStringList& fileUrls)
{
    filePaths.clear();
    fileDurations.clear();

    for (const QString &url : fileUrls) {
        QString localFile;
        if (url.startsWith("file:")) localFile = QUrl(url).toLocalFile();
        else localFile = url;

        if (!localFile.isEmpty() && QFileInfo(localFile).exists()) {
            filePaths.append(localFile);
            player->setSource(QUrl::fromLocalFile(localFile));
            while (player->mediaStatus() != QMediaPlayer::LoadedMedia &&
                   player->mediaStatus() != QMediaPlayer::InvalidMedia) {
                QCoreApplication::processEvents();
            }
            fileDurations.append(player->duration());
        }
        else qDebug() << "AudioPlayer: Skipped invalid or missing file:" << url;
    }

    if (!filePaths.isEmpty()) {
        curId = 0;
        curSongList = filePaths;
        player->setSource(QUrl::fromLocalFile(filePaths[curId]));
        saveFilePaths(filePaths);
        emit filePathsChanged();
        emit fileDurationsChanged();
        emit curIdChanged();
        emit curSongListChanged();
    }
    else {
        curId = -1;
        curSongList.clear();
        emit filePathsChanged();
        emit fileDurationsChanged();
        emit curIdChanged();
        emit curSongListChanged();
    }
}

void AudioPlayer::setCurId(int id)
{
    if (curId != id && id >= 0 && id < curSongList.size()) {
        curId = id;
        QUrl newSource = QUrl::fromLocalFile(curSongList[curId]);
        if (player->source() != newSource) player->setSource(newSource);
        playCounts[curSongList[curId]] = playCounts.value(curSongList[curId], 0) + 1;
        lastPlayed[curSongList[curId]] = QDateTime::currentDateTime();
        savePlayData();
        emit curIdChanged();
    }
}

void AudioPlayer::setCurSongList(const QStringList& playlist)
{
    if (curSongList != playlist) {
        curSongList = playlist;
        emit curSongListChanged();
    }
}

void AudioPlayer::togglePlayPause()
{
    if (player->playbackState() == QMediaPlayer::PlayingState) {
        player->pause();
    }
    else {
        player->play();
        if (curId >= 0 && curId < curSongList.size()) {
            playCounts[curSongList[curId]] = playCounts.value(curSongList[curId], 0) + 1;
            lastPlayed[curSongList[curId]] = QDateTime::currentDateTime();
            savePlayData();
        }
    }
    emit playingStateChanged();
}

void AudioPlayer::stop()
{
    player->stop();
    emit playingStateChanged();
}

QStringList AudioPlayer::sortMost()
{
    QStringList sortedList = filePaths;
    std::sort(sortedList.begin(), sortedList.end(), [&](const QString& a, const QString& b) {
        return playCounts.value(a, 0) > playCounts.value(b, 0);
    });
    return sortedList;
}

QStringList AudioPlayer::sortLast()
{
    QStringList sortedList = filePaths;
    std::sort(sortedList.begin(), sortedList.end(), [&](const QString& a, const QString& b) {
        return lastPlayed.value(a, QDateTime()) > lastPlayed.value(b, QDateTime());
    });
    return sortedList;
}

QStringList AudioPlayer::sortLength(bool ascending)
{
    QStringList sortedList = filePaths;
    std::sort(sortedList.begin(), sortedList.end(), [&](const QString& a, const QString& b) {
        int indexA = filePaths.indexOf(a);
        int indexB = filePaths.indexOf(b);
        int durationA = (indexA >= 0 && indexA < fileDurations.size()) ? fileDurations[indexA] : 0;
        int durationB = (indexB >= 0 && indexB < fileDurations.size()) ? fileDurations[indexB] : 0;
        return ascending ? (durationA < durationB) : (durationA > durationB);
    });
    return sortedList;
}

void AudioPlayer::savePlayData()
{
    QSettings settings;
    settings.beginGroup("playData");
    settings.setValue("playCounts", QVariant::fromValue(playCounts));
    settings.setValue("lastPlayed", QVariant::fromValue(lastPlayed));
    settings.endGroup();
}

void AudioPlayer::loadPlayData()
{
    QSettings settings;
    settings.beginGroup("playData");

    QVariant playCountsVariant = settings.value("playCounts");
    if (playCountsVariant.isValid() && playCountsVariant.canConvert<PlayCountMap>()) {
        playCounts = playCountsVariant.value<PlayCountMap>();
    }
    else {
        playCounts.clear();
    }

    QVariant lastPlayedVariant = settings.value("lastPlayed");
    if (lastPlayedVariant.isValid() && lastPlayedVariant.canConvert<LastPlayedMap>()) {
        lastPlayed = lastPlayedVariant.value<LastPlayedMap>();
    }
    else {
        lastPlayed.clear();
    }

    settings.endGroup();
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
    QStringList validFiles;
    QList<int> validDurations;
    QString folderPath = getLastFolderPathFromSettings();

    for (const QString& filePath : lastFiles) {
        if (QFileInfo(filePath).exists()) {
            validFiles.append(filePath);
            player->setSource(QUrl::fromLocalFile(filePath));
            while (player->mediaStatus() != QMediaPlayer::LoadedMedia &&
                   player->mediaStatus() != QMediaPlayer::InvalidMedia) {
                QCoreApplication::processEvents();
            }
            validDurations.append(player->duration());
        } else {
            qDebug() << "AudioPlayer: Removed invalid file path from lastFiles:" << filePath;
        }
    }

    if (!folderPath.isEmpty() && QDir(folderPath).exists()) {
        m_lastFolderPath = folderPath;
        QStringList nameFilters = {"*.mp3", "*.m4a", "*.wav", "*.aac", "*.opus"};
        QDir dir(folderPath);
        dir.setNameFilters(nameFilters);
        dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);

        QStringList audioFiles = dir.entryList();
        for (const QString& fileName : audioFiles) {
            QString filePath = dir.absoluteFilePath(fileName);
            if (QFileInfo(filePath).exists() && !validFiles.contains(filePath)) {
                validFiles.append(filePath);
                player->setSource(QUrl::fromLocalFile(filePath));
                while (player->mediaStatus() != QMediaPlayer::LoadedMedia &&
                       player->mediaStatus() != QMediaPlayer::InvalidMedia) {
                    QCoreApplication::processEvents();
                }
                validDurations.append(player->duration());
                qDebug() << "AudioPlayer: Added new file:" << filePath;
            }
        }
    }

    filePaths = validFiles;
    fileDurations = validDurations;

    if (filePaths != lastFiles || !folderPath.isEmpty()) {
        saveFilePaths(filePaths);
    }

    if (!filePaths.isEmpty()) {
        curSongList = filePaths;
        if (curId < 0 || curId >= filePaths.size()) {
            curId = 0;
            player->setSource(QUrl::fromLocalFile(filePaths[curId]));
        }
    }
    else {
        curSongList.clear();
        curId = -1;
    }

    emit filePathsChanged();
    emit fileDurationsChanged();
    emit curSongListChanged();
    emit curIdChanged();
}

void AudioPlayer::saveFilePaths(const QStringList &filePaths)
{
    QSettings settings;
    settings.setValue("lastFiles", filePaths);
}

QStringList AudioPlayer::getLastFilePaths()
{
    QSettings settings;
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
    QSettings settings;
    settings.setValue("favourites", favourites);
}

void AudioPlayer::addPlaylist(const QString& name, const QStringList& files)
{
    playlists[name] = files;
    savePlaylists();
    emit playlistsChanged();
}

void AudioPlayer::removePlaylist(const QString& name)
{
    playlists.remove(name);
    savePlaylists();
    emit playlistsChanged();
}

void AudioPlayer::savePlaylists()
{
    QSettings settings;
    settings.beginGroup("playlists");
    settings.remove("");
    for (const QString& name : playlists.keys()) {
        settings.setValue(name, playlists[name].toStringList());
    }
    settings.endGroup();
}
void AudioPlayer::loadFavourites()
{
    QSettings settings;
    QStringList loadedFavourites = settings.value("favourites", QStringList()).toStringList();
    QStringList validFavourites;

    for (const QString& filePath : loadedFavourites) {
        if (QFileInfo(filePath).exists() && filePaths.contains(filePath)) {
            validFavourites.append(filePath);
        }
        else {
            qDebug() << "AudioPlayer: Removed invalid favourite:" << filePath;
        }
    }

    favourites = validFavourites;

    if (favourites != loadedFavourites) {
        saveFavourites();
    }

    if (curSongList == loadedFavourites) {
        curSongList = favourites;
        if (!curSongList.isEmpty()) {
            if (curId >= curSongList.size()) {
                curId = 0;
                player->setSource(QUrl::fromLocalFile(curSongList[curId]));
            }
        }
        else {
            curId = -1;
        }
        emit curSongListChanged();
        emit curIdChanged();
    }

    emit favouritesChanged();
}

void AudioPlayer::loadPlaylists()
{
    QSettings settings;
    settings.beginGroup("playlists");
    QStringList playlistNames = settings.childKeys();
    QVariantMap validPlaylists;

    for (const QString& name : playlistNames) {
        QStringList files = settings.value(name).toStringList();
        QStringList validFiles;

        for (const QString& filePath : files) {
            if (QFileInfo(filePath).exists() && filePaths.contains(filePath)) {
                validFiles.append(filePath);
            } else {
                qDebug() << "AudioPlayer: Removed invalid file from playlist" << name << ":" << filePath;
            }
        }

        if (!validFiles.isEmpty()) {
            validPlaylists[name] = QVariant(validFiles);
        } else {
            qDebug() << "AudioPlayer: Removed empty playlist:" << name;
        }
    }

    playlists = validPlaylists;

    if (!playlistNames.isEmpty() || !playlists.isEmpty()) {
        savePlaylists();
    }

    if (!curSongList.isEmpty()) {
        bool foundMatch = false;
        for (const QString& name : validPlaylists.keys()) {
            QStringList playlistSongs = validPlaylists[name].toStringList();
            if (curSongList == playlistSongs) {
                foundMatch = true;
                if (curSongList != playlistSongs) {
                    curSongList = playlistSongs;
                    if (!curSongList.isEmpty()) {
                        if (curId >= curSongList.size()) {
                            curId = 0;
                            player->setSource(QUrl::fromLocalFile(curSongList[curId]));
                        }
                    }
                    else {
                        curId = -1;
                    }
                    emit curSongListChanged();
                    emit curIdChanged();
                }
                break;
            }
        }
        if (!foundMatch && curSongList != filePaths) {
            curSongList = filePaths;
            if (!curSongList.isEmpty()) {
                if (curId >= curSongList.size()) {
                    curId = 0;
                    player->setSource(QUrl::fromLocalFile(curSongList[curId]));
                }
            }
            else {
                curId = -1;
            }
            emit curSongListChanged();
            emit curIdChanged();
        }
    }

    settings.endGroup();
    emit playlistsChanged();
}

void AudioPlayer::saveLastFolderPath(const QString& folderPath)
{
    QSettings settings;
    settings.setValue("lastFolderPath", folderPath);
}

QString AudioPlayer::getLastFolderPathFromSettings()
{
    QSettings settings;
    return settings.value("lastFolderPath", QString()).toString();
}
