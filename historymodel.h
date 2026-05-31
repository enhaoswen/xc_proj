#pragma once

#include "backend/backend.h"

#include <QAbstractListModel>
#include <QString>
#include <QVector>
#include <QtQml/qqmlregistration.h>

class HistoryModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    enum HistoryRole {
        TypeRole = Qt::UserRole + 1,
        StudentNameRole,
        TimestampRole,
        PointsDeltaRole,
        ReasonRole,
        PointsTextRole,
        SummaryRole
    };
    Q_ENUM(HistoryRole)

    explicit HistoryModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int totalCount() const;
    QString lastError() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool clearHistory();

signals:
    void totalCountChanged();
    void lastErrorChanged();

private:
    QVector<StudentHistoryRecord> m_history;
    StudentRepository m_repository;
    QString m_lastError;

    QString pointsText(const StudentHistoryRecord &record) const;
    QString summary(const StudentHistoryRecord &record) const;
    void setLastError(const QString &message);
};
