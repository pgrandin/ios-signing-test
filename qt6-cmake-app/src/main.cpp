#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QObject>
#include <QUrl>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/Qt6CmakeApp/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() {
                         QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
