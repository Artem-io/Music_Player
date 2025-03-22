#ifndef AUDIOPLAYER_H
#define AUDIOPLAYER_H

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QDebug>
#include <QList>
#include <QFileInfo>
#include <QCoreApplication>
#include <QSettings>
#include <QDir>

class AudioPlayer: public QObject
{
    Q_OBJECT
    QMediaPlayer *player;
    QAudioOutput *audioOutput;
    QStringList filePaths;
    QList<int> fileDurations;
    int curId;

    Q_PROPERTY(QStringList filePaths READ getFilePaths NOTIFY filePathsChanged)
    Q_PROPERTY(QList<int> fileDurations READ getFileDurations NOTIFY fileDurationsChanged)
    Q_PROPERTY(int position READ getPosition WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(float volume READ getVolume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playingStateChanged)
    Q_PROPERTY(int curId READ getCurId WRITE setCurId NOTIFY curIdChanged)

public:
    explicit AudioPlayer(QObject *parent = nullptr);

    QStringList getFilePaths() { return filePaths; }
    QList<int> getFileDurations() { return fileDurations; }
    int getPosition() { return player->position(); }
    float getVolume() { return audioOutput->volume(); }
    bool isPlaying() { return player->playbackState() == QMediaPlayer::PlayingState; }
    int getCurId() { return curId; }

public slots:
    void setFiles(const QStringList&);
    void setCurId(int);
    void togglePlayPause();
    void setPosition(int);
    void setVolume(float);
    void loadFilesFromFolder(const QString&);

signals:
    void filePathsChanged();
    void fileDurationsChanged();
    void positionChanged(int);
    void volumeChanged();
    void playingStateChanged();
    void curIdChanged();

private:
    void savePaths(const QStringList&);
    QStringList getLastFolderPath();
};

#endif
