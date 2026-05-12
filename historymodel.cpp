#include "historymodel.h"

#include <algorithm>

HistoryModel::HistoryModel(QObject *parent)
    : QAbstractListModel(parent)
{
    refresh();
}

int HistoryModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_history.size();
}

QVariant HistoryModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_history.size()) {
        return {};
    }

    const StudentHistoryRecord &record = m_history.at(index.row());
    switch (role) {
    case TypeRole:
        return record.type;
    case StudentNameRole:
        return record.studentName;
    case TimestampRole:
        return record.timestamp;
    case PointsDeltaRole:
        return record.pointsDelta;
    case ReasonRole:
        return record.reason;
    case PointsTextRole:
        return pointsText(record);
    case SummaryRole:
        return summary(record);
    default:
        return {};
    }
}

QHash<int, QByteArray> HistoryModel::roleNames() const
{
    return {
        {TypeRole, "type"},
        {StudentNameRole, "studentName"},
        {TimestampRole, "timestamp"},
        {PointsDeltaRole, "pointsDelta"},
        {ReasonRole, "reason"},
        {PointsTextRole, "pointsText"},
        {SummaryRole, "summary"},
    };
}

int HistoryModel::totalCount() const
{
    return m_history.size();
}

QString HistoryModel::lastError() const
{
    return m_lastError;
}

void HistoryModel::refresh()
{
    QString loadError;
    QVector<StudentHistoryRecord> nextHistory = m_repository.loadHistory(&loadError);
    std::reverse(nextHistory.begin(), nextHistory.end());

    const int oldTotalCount = totalCount();
    beginResetModel();
    m_history = nextHistory;
    endResetModel();

    if (oldTotalCount != totalCount()) {
        emit totalCountChanged();
    }

    setLastError(loadError);
}

bool HistoryModel::clearHistory()
{
    QString clearError;
    if (!m_repository.clearHistory(&clearError)) {
        setLastError(clearError);
        return false;
    }

    const int oldTotalCount = totalCount();
    beginResetModel();
    m_history.clear();
    endResetModel();

    if (oldTotalCount != totalCount()) {
        emit totalCountChanged();
    }

    setLastError(QString());
    return true;
}

QString HistoryModel::pointsText(const StudentHistoryRecord &record) const
{
    if (record.pointsDelta > 0) {
        return QStringLiteral("+%1 points").arg(record.pointsDelta);
    }

    return QStringLiteral("%1 points").arg(record.pointsDelta);
}

QString HistoryModel::summary(const StudentHistoryRecord &record) const
{
    if (record.type == QStringLiteral("addStudent")) {
        return QStringLiteral("Add student %1").arg(record.studentName);
    }

    const QString reasonText = record.reason.isEmpty()
        ? QStringLiteral("No reason")
        : record.reason;
    return QStringLiteral("%1, %2, score changed by %3, %4")
        .arg(record.studentName, record.timestamp, pointsText(record), reasonText);
}

void HistoryModel::setLastError(const QString &message)
{
    if (m_lastError == message) {
        return;
    }

    m_lastError = message;
    emit lastErrorChanged();
}
