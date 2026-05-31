#pragma once

#include <QString>
#include <QVector>

struct StudentRecord {
    QString name;
    QString className;
    int score = 0;
    QString scoreReason;
};

struct StudentHistoryRecord {
    QString type;
    QString studentName;
    QString timestamp;
    int pointsDelta = 0;
    QString reason;
};

class StudentRepository
{
public:
    explicit StudentRepository(const QString &studentStoragePath = QString(),
                               const QString &historyStoragePath = QString());

    QVector<StudentRecord> load(QString *errorMessage = nullptr) const;
    bool save(const QVector<StudentRecord> &students, QString *errorMessage = nullptr) const;
    QVector<StudentHistoryRecord> loadHistory(QString *errorMessage = nullptr) const;
    bool saveHistory(const QVector<StudentHistoryRecord> &history, QString *errorMessage = nullptr) const;
    bool appendHistory(const StudentHistoryRecord &record, QString *errorMessage = nullptr) const;
    bool clearHistory(QString *errorMessage = nullptr) const;
    QString storagePath() const;
    QString historyPath() const;

private:
    QString m_storagePath;
    QString m_historyPath;

    static QString defaultStoragePath();
    static QString defaultHistoryPath();
};
