import { useNavigate } from 'react-router-dom'

const STATUS_ORDER = ['pending', 'under_review', 'assigned', 'resolved', 'closed']
const PRIORITY_ORDER = ['urgent', 'high', 'medium', 'low']

export default function SubmissionTable({ submissions, onStatusChange, showAssign, userRole }) {
  const navigate = useNavigate()

  if (!submissions?.length) {
    return (
      <div className="card" style={{ textAlign: 'center', padding: '60px' }}>
        <div style={{ fontSize: '48px', marginBottom: '12px' }}>📭</div>
        <p className="text-muted">No submissions found.</p>
      </div>
    )
  }

  const formatDate = (iso) => {
    if (!iso) return '—'
    return new Date(iso).toLocaleString('en-GB', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    })
  }

  return (
    <div className="table-wrapper">
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Title</th>
            <th>Submitter</th>
            <th>Category</th>
            <th>Priority</th>
            <th>Status</th>
            <th>Date</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {submissions.map(sub => (
            <tr key={sub.id} onClick={() => navigate(`/submissions/${sub.id}`)}>
              <td style={{ color: 'var(--text-muted)', fontFamily: 'monospace' }}>
                #{sub.id}
              </td>
              <td>
                <div style={{ fontWeight: 600, maxWidth: '220px' }} className="truncate">
                  {sub.title}
                </div>
              </td>
              <td className="text-muted">{sub.submitter || `User #${sub.user_id}`}</td>
              <td>
                <span style={{
                  textTransform: 'capitalize',
                  fontSize: '13px',
                  color: 'var(--text-secondary)',
                }}>
                  {sub.category}
                </span>
              </td>
              <td>
                <span className={`badge badge-${sub.priority}`}>{sub.priority}</span>
              </td>
              <td>
                <span className={`badge badge-${sub.status}`}>
                  {sub.status.replace('_', ' ')}
                </span>
              </td>
              <td className="text-muted text-sm">{formatDate(sub.created_at)}</td>
              <td onClick={e => e.stopPropagation()}>
                <button
                  className="btn btn-ghost btn-sm"
                  id={`btn-view-${sub.id}`}
                  onClick={() => navigate(`/submissions/${sub.id}`)}
                >
                  View →
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
