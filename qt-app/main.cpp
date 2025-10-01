#include <QApplication>
#include <QLabel>
#include <QVBoxLayout>
#include <QWidget>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QWidget window;
    window.setWindowTitle("Qt6 Hello World");

    QVBoxLayout *layout = new QVBoxLayout(&window);

    QLabel *label = new QLabel("Hello World from Qt6 on iOS!");
    label->setAlignment(Qt::AlignCenter);
    label->setStyleSheet("font-size: 24px; padding: 20px;");

    layout->addWidget(label);

    window.resize(300, 200);
    window.show();

    return app.exec();
}
