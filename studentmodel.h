#pragma once

#include "backend/backend.h"

#include <QAbstractListModel>
#include <QString>
#include <QVector>
#include <QtQml/qqmlregistration.h>

class StudentModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(SortMode sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)

public:
    enum StudentRole {
        NameRole = Qt::UserRole + 1,
        ClassNameRole,
        StudentIdRole,
        ScoreRole,
        ScoreReasonRole
    };
    Q_ENUM(StudentRole)

    enum SortMode {
        NameAscending = 0,
        NameDescending,
        ClassAscending,
        ClassDescending,
        ScoreAscending,
        ScoreDescending
    };
    Q_ENUM(SortMode)

    explicit StudentModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int totalCount() const;
    QString lastError() const;
    SortMode sortMode() const;
    void setSortMode(SortMode sortMode);

    Q_INVOKABLE bool addStudent(const QString &name,
                                const QString &className,
                                const QString &studentId,
                                int score);
    Q_INVOKABLE bool updateStudent(int row,
                                   const QString &name,
                                   const QString &className,
                                   int score,
                                   const QString &reason);
    Q_INVOKABLE bool deleteStudent(int row);
    Q_INVOKABLE bool updateScore(int row, int score, const QString &reason);
    Q_INVOKABLE bool adjustScore(int row, int delta, const QString &reason);

signals:
    void totalCountChanged();
    void lastErrorChanged();
    void sortModeChanged();

private:
    QVector<StudentRecord> m_students;
    StudentRepository m_repository;
    QString m_lastError;
    SortMode m_sortMode = NameAscending;

    bool isStudentIdUnique(const QString &studentId) const;
    bool saveStudents(const QVector<StudentRecord> &students);
    void appendHistory(const StudentHistoryRecord &record);
    void setLastError(const QString &message);
    void sortStudents(QVector<StudentRecord> &students) const;
};
