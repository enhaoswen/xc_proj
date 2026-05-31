#include "studentmodel.h"

#include <QDateTime>

#include <algorithm>

namespace {
int compareStudentIdentity(const StudentRecord &left, const StudentRecord &right)
{
    return QString::compare(left.name, right.name, Qt::CaseInsensitive);
}

int compareStudentClass(const StudentRecord &left, const StudentRecord &right)
{
    const int classCompare = QString::compare(left.className, right.className, Qt::CaseInsensitive);
    if (classCompare != 0) {
        return classCompare;
    }

    return compareStudentIdentity(left, right);
}
}

StudentModel::StudentModel(QObject *parent)
    : QAbstractListModel(parent)
{
    QString loadError;
    m_students = m_repository.load(&loadError);
    sortStudents(m_students);
    setLastError(loadError);
}

int StudentModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_students.size();
}

QVariant StudentModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_students.size()) {
        return {};
    }

    const StudentRecord &student = m_students.at(index.row());
    switch (role) {
    case NameRole:
        return student.name;
    case ClassNameRole:
        return student.className;
    case ScoreRole:
        return student.score;
    case ScoreReasonRole:
        return student.scoreReason;
    default:
        return {};
    }
}

QHash<int, QByteArray> StudentModel::roleNames() const
{
    return {
        {NameRole, "name"},
        {ClassNameRole, "className"},
        {ScoreRole, "score"},
        {ScoreReasonRole, "scoreReason"},
    };
}

int StudentModel::totalCount() const
{
    return m_students.size();
}

QString StudentModel::lastError() const
{
    return m_lastError;
}

StudentModel::SortMode StudentModel::sortMode() const
{
    return m_sortMode;
}

void StudentModel::setSortMode(SortMode sortMode)
{
    if (sortMode < NameAscending || sortMode > ScoreDescending || m_sortMode == sortMode) {
        return;
    }

    m_sortMode = sortMode;
    emit sortModeChanged();

    beginResetModel();
    sortStudents(m_students);
    endResetModel();
}

bool StudentModel::addStudent(const QString &name,
                              const QString &className,
                              int score)
{
    StudentRecord student;
    student.name = name.trimmed();
    student.className = className.trimmed();
    student.score = score;

    if (student.name.isEmpty() || student.className.isEmpty()) {
        setLastError(QStringLiteral("All fields are required."));
        return false;
    }

    QVector<StudentRecord> nextStudents = m_students;
    nextStudents.append(student);
    sortStudents(nextStudents);

    if (!saveStudents(nextStudents)) {
        return false;
    }

    StudentHistoryRecord history;
    history.type = QStringLiteral("addStudent");
    history.studentName = student.name;
    history.timestamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd hh:mm:ss"));
    appendHistory(history);

    const int oldTotalCount = totalCount();
    beginResetModel();
    m_students = nextStudents;
    endResetModel();

    if (oldTotalCount != totalCount()) {
        emit totalCountChanged();
    }

    setLastError(QString());
    return true;
}

bool StudentModel::updateStudent(int row,
                                 const QString &name,
                                 const QString &className,
                                 int scoreDelta,
                                 const QString &reason)
{
    if (row < 0 || row >= m_students.size()) {
        setLastError(QStringLiteral("Unable to update the selected student."));
        return false;
    }

    StudentRecord editedStudent = m_students.at(row);
    const StudentRecord oldStudent = editedStudent;
    editedStudent.name = name.trimmed();
    editedStudent.className = className.trimmed();
    editedStudent.score = oldStudent.score + scoreDelta;
    editedStudent.scoreReason = reason.trimmed();

    if (editedStudent.name.isEmpty() || editedStudent.className.isEmpty()) {
        setLastError(QStringLiteral("Name and grade are required."));
        return false;
    }

    if (oldStudent.name == editedStudent.name
        && oldStudent.className == editedStudent.className
        && oldStudent.score == editedStudent.score
        && oldStudent.scoreReason == editedStudent.scoreReason) {
        setLastError(QString());
        return true;
    }

    QVector<StudentRecord> nextStudents = m_students;
    nextStudents[row] = editedStudent;
    sortStudents(nextStudents);

    if (!saveStudents(nextStudents)) {
        return false;
    }

    if (oldStudent.score != editedStudent.score || oldStudent.scoreReason != editedStudent.scoreReason) {
        StudentHistoryRecord history;
        history.type = QStringLiteral("scoreChange");
        history.studentName = editedStudent.name;
        history.timestamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd hh:mm:ss"));
        history.pointsDelta = editedStudent.score - oldStudent.score;
        history.reason = editedStudent.scoreReason;
        appendHistory(history);
    }

    beginResetModel();
    m_students = nextStudents;
    endResetModel();

    setLastError(QString());
    return true;
}

bool StudentModel::deleteStudent(int row)
{
    if (row < 0 || row >= m_students.size()) {
        setLastError(QStringLiteral("Unable to delete the selected student."));
        return false;
    }

    QVector<StudentRecord> nextStudents = m_students;
    nextStudents.removeAt(row);

    if (!saveStudents(nextStudents)) {
        return false;
    }

    const int oldTotalCount = totalCount();
    beginResetModel();
    m_students = nextStudents;
    endResetModel();

    if (oldTotalCount != totalCount()) {
        emit totalCountChanged();
    }

    setLastError(QString());
    return true;
}

bool StudentModel::adjustScore(int row, int delta, const QString &reason)
{
    if (row < 0 || row >= m_students.size()) {
        setLastError(QStringLiteral("Unable to update the selected score."));
        return false;
    }

    const StudentRecord oldStudent = m_students.at(row);
    const int newScore = oldStudent.score + delta;

    if (oldStudent.score == newScore && oldStudent.scoreReason == reason.trimmed()) {
        setLastError(QString());
        return true;
    }

    QVector<StudentRecord> nextStudents = m_students;
    nextStudents[row].score = newScore;
    nextStudents[row].scoreReason = reason.trimmed();
    sortStudents(nextStudents);

    if (!saveStudents(nextStudents)) {
        return false;
    }

    StudentHistoryRecord history;
    history.type = QStringLiteral("scoreChange");
    history.studentName = oldStudent.name;
    history.timestamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd hh:mm:ss"));
    history.pointsDelta = newScore - oldStudent.score;
    history.reason = reason.trimmed();
    appendHistory(history);

    beginResetModel();
    m_students = nextStudents;
    endResetModel();

    setLastError(QString());
    return true;
}

bool StudentModel::saveStudents(const QVector<StudentRecord> &students)
{
    QString saveError;
    if (!m_repository.save(students, &saveError)) {
        setLastError(saveError);
        return false;
    }

    return true;
}

void StudentModel::appendHistory(const StudentHistoryRecord &record)
{
    QString historyError;
    if (!m_repository.appendHistory(record, &historyError)) {
        setLastError(historyError);
    }
}

void StudentModel::setLastError(const QString &message)
{
    if (m_lastError == message) {
        return;
    }

    m_lastError = message;
    emit lastErrorChanged();
}

void StudentModel::sortStudents(QVector<StudentRecord> &students) const
{
    std::stable_sort(students.begin(), students.end(), [this](const StudentRecord &left, const StudentRecord &right) {
        switch (m_sortMode) {
        case NameAscending:
            return compareStudentIdentity(left, right) < 0;
        case NameDescending:
            return compareStudentIdentity(left, right) > 0;
        case ClassAscending:
            return compareStudentClass(left, right) < 0;
        case ClassDescending:
            return compareStudentClass(left, right) > 0;
        case ScoreAscending:
            if (left.score != right.score) {
                return left.score < right.score;
            }
            return compareStudentIdentity(left, right) < 0;
        case ScoreDescending:
            if (left.score != right.score) {
                return left.score > right.score;
            }
            return compareStudentIdentity(left, right) < 0;
        }

        return compareStudentIdentity(left, right) < 0;
    });
}
