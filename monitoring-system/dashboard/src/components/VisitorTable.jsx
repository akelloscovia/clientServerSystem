import { useNavigate } from 'react-router-dom'

export default function VisitorTable({ visitors }) {
  const navigate = useNavigate()

  if (!visitors?.length) {
    return (
      <div className="card" style={{ textAlign: 'center', padding: '60px' }}>
        <div style={{ fontSize: '48px', marginBottom: '12px' }}>🧾</div>
        <p className="text-muted">No visitor entries found.</p>
      </div>
    )
  }

  const formatDate = (iso) => {
    if (!iso) return '—'
    return new Date(iso).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
  }

  return (
    <div className="table-wrapper">
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Name</th>
            <th>Company</th>
            <th>Reason</th>
            <th>Date</th>
            <th>Time In</th>
            <th>Assigned To</th>
            <th>Status</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {visitors.map(v => (
            <tr key={v.id} onClick={() => navigate(`/visitor-log/${v.id}`)}>
              <td style={{ color: 'var(--text-muted)', fontFamily: 'monospace' }}>#{v.id}</td>
              <td style={{ fontWeight: 600 }}>{v.name}</td>
              <td className="text-muted">{v.company || '—'}</td>
              <td>
                <div style={{ maxWidth: '220px' }} className="truncate">{v.reason_for_visit}</div>
              </td>
              <td className="text-muted text-sm">{formatDate(v.visit_date)}</td>
              <td className="text-muted text-sm">{v.time_in}</td>
              <td className="text-muted text-sm">{v.assignee || '—'}</td>
              <td>
                <span className={`badge badge-${v.status}`}>{v.status}</span>
              </td>
              <td onClick={e => e.stopPropagation()}>
                <button
                  className="btn btn-ghost btn-sm"
                  id={`btn-view-visitor-${v.id}`}
                  onClick={() => navigate(`/visitor-log/${v.id}`)}
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
