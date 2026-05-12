#include "backend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QSaveFile>
#include <QStandardPaths>

namespace {
bool ensureParentDirectory(const QString &path, QString *errorMessage)
{
    const QFileInfo fileInfo(path);
    QDir directory = fileInfo.absoluteDir();
    if (directory.exists() || directory.mkpath(QStringLiteral("."))) {
        return true;
    }

    if (errorMessage) {
        *errorMessage = QStringLiteral("Unable to create the data folder.");
    }
    return false;
}
}

StudentRepository::StudentRepository(const QString &studentStoragePath,
                                     const QString &historyStoragePath)
    : m_storagePath(studentStoragePath.isEmpty() ? defaultStoragePath() : studentStoragePath)
    , m_historyPath(historyStoragePath.isEmpty() ? defaultHistoryPath() : historyStoragePath)
{
}

QVector<StudentRecord> StudentRepository::load(QString *errorMessage) const
{
    if (errorMessage) {
        errorMessage->clear();
    }

    QFile file(m_storagePath);
    if (!file.exists()) {
        return {};
    }

    if (!file.open(QIODevice::ReadOnly)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Unable to open saved students.");
        }
        return {};
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isArray()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Saved students file is not valid JSON.");
        }
        return {};
    }

    QVector<StudentRecord> students;
    const QJsonArray records = document.array();
    students.reserve(records.size());

    for (const QJsonValue &value : records) {
        if (!value.isObject()) {
            continue;
        }

        const QJsonObject object = value.toObject();
        StudentRecord student;
        student.name = object.value(QStringLiteral("name")).toString().trimmed();
        student.className = object.value(QStringLiteral("className")).toString().trimmed();
        student.studentId = object.value(QStringLiteral("studentId")).toString().trimmed();
        student.score = object.value(QStringLiteral("score")).toInt(0);
        student.scoreReason = object.value(QStringLiteral("scoreReason")).toString().trimmed();

        if (!student.name.isEmpty() && !student.className.isEmpty() && !student.studentId.isEmpty()) {
            students.append(student);
        }
    }

    return students;
}

bool StudentRepository::save(const QVector<StudentRecord> &students, QString *errorMessage) const
{
    if (errorMessage) {
        errorMessage->clear();
    }

    if (!ensureParentDirectory(m_storagePath, errorMessage)) {
        return false;
    }

    QJsonArray records;
    for (const StudentRecord &student : students) {
        QJsonObject object;
        object.insert(QStringLiteral("name"), student.name);
        object.insert(QStringLiteral("className"), student.className);
        object.insert(QStringLiteral("studentId"), student.studentId);
        object.insert(QStringLiteral("score"), student.score);
        object.insert(QStringLiteral("scoreReason"), student.scoreReason);
        records.append(object);
    }

    QSaveFile file(m_storagePath);
    if (!file.open(QIODevice::WriteOnly)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Unable to open the student data file for saving.");
        }
        return false;
    }

    const QJsonDocument document(records);
    file.write(document.toJson(QJsonDocument::Indented));
    if (!file.commit()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Unable to save student data.");
        }
        return false;
    }

    return true;
}

QVector<StudentHistoryRecord> StudentRepository::loadHistory(QString *errorMessage) const
{
    if (errorMessage) {
        errorMessage->clear();
    }

    QFile file(m_historyPath);
    if (!file.exists()) {
        return {};
    }

    if (!file.open(QIODevice::ReadOnly)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Unable to open saved history.");
        }
        return {};
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isArray()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Saved history file is not valid JSON.");
        }
        return {};
    }

    QVector<StudentHistoryRecord> history;
    const QJsonArray records = document.array();
    history.reserve(records.size());

    for (const QJsonValue &value : records) {
        if (!value.isObject()) {
            continue;
        }

        const QJsonObject object = value.toObject();
        StudentHistoryRecord record;
        record.type = object.value(QStringLiteral("type")).toString().trimmed();
        record.studentName = object.value(QStringLiteral("studentName")).toString().trimmed();
        record.timestamp = object.value(QStringLiteral("timestamp")).toString().trimmed();
        record.pointsDelta = object.value(QStringLiteral("pointsDelta")).toInt(0);
        record.reason = object.value(QStringLiteral("reason")).toString().trimmed();

        if (!record.type.isEmpty() && !record.studentName.isEmpty()) {
            history.append(record);
        }
    }

    return history;
}

bool StudentRepository::saveHistory(const QVector<StudentHistoryRecord> &history, QString *errorMessage) const
{
    if (errorMessage) {
        errorMessage->clear();
    }

    if (!ensureParentDirectory(m_historyPath, errorMessage)) {
        return false;
    }

    QJsonArray records;
    for (const StudentHistoryRecord &record : history) {
        QJsonObject object;
        object.insert(QStringLiteral("type"), record.type);
        object.insert(QStringLiteral("studentName"), record.studentName);
        object.insert(QStringLiteral("timestamp"), record.timestamp);
        object.insert(QStringLiteral("pointsDelta"), record.pointsDelta);
        object.insert(QStringLiteral("reason"), record.reason);
        records.append(object);
    }

    QSaveFile file(m_historyPath);
    if (!file.open(QIODevice::WriteOnly)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Unable to open the history file for saving.");
        }
        return false;
    }

    const QJsonDocument document(records);
    file.write(document.toJson(QJsonDocument::Indented));
    if (!file.commit()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Unable to save history.");
        }
        return false;
    }

    return true;
}

bool StudentRepository::appendHistory(const StudentHistoryRecord &record, QString *errorMessage) const
{
    QString loadError;
    QVector<StudentHistoryRecord> history = loadHistory(&loadError);
    if (!loadError.isEmpty()) {
        if (errorMessage) {
            *errorMessage = loadError;
        }
        return false;
    }

    history.append(record);
    return saveHistory(history, errorMessage);
}

bool StudentRepository::clearHistory(QString *errorMessage) const
{
    return saveHistory({}, errorMessage);
}

QString StudentRepository::storagePath() const
{
    return m_storagePath;
}

QString StudentRepository::historyPath() const
{
    return m_historyPath;
}

QString StudentRepository::defaultStoragePath()
{
    const QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    return QDir(dataPath).filePath(QStringLiteral("students.json"));
}

QString StudentRepository::defaultHistoryPath()
{
    const QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    return QDir(dataPath).filePath(QStringLiteral("history.json"));
}
