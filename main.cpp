#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include "audioplayer.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    //QQuickStyle::setStyle("Material");
    QCoreApplication::setOrganizationName("Artemio");
    QCoreApplication::setApplicationName("MusicPlayer");

    qmlRegisterType<AudioPlayer>("AudioPlayer", 1, 0, "AudioPlayer");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Music_Player_2", "Main");

    return app.exec();
}
