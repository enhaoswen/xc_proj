#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setOrganizationName(QStringLiteral("XingChen"));
    QGuiApplication::setApplicationName(QStringLiteral("XingChenProj"));

    QQmlApplicationEngine engine;
    engine.loadFromModule("XingChenProj", "Main");

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
