export default function SubmissionDetails({ submission }) {
  if (!submission) return null

  const formatDate = (iso) => iso
    ? new Date(iso).toLocaleString('en-GB', {
        day: '2-digit', month: 'long', year: 'numeric',
        hour: '2-digit', minute: '2-digit',
      })
    : '—'

  const fields = [
    { label: 'Submission ID', value: `#${submission.id}` },
    { label: 'Submitted By', value: submission.submitter || `User #${submission.user_id}` },
    { label: 'Category', value: submission.category },
    { label: 'Priority', value: <span className={`badge badge-${submission.priority}`}>{submission.priority}</span> },
    { label: 'Status', value: <span className={`badge badge-${submission.status}`}>{submission.status?.replace('_', ' ')}</span> },
    { label: 'Created', value: formatDate(submission.created_at) },
    { label: 'Last Updated', value: formatDate(submission.updated_at) },
  ]

  return (
    <div className="card" style={{ marginBottom: '24px' }}>
      <h2 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '20px', color: 'var(--text-primary)' }}>
        {submission.title}
      </h2>

      {/* Meta grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
        gap: '16px',
        marginBottom: '20px',
      }}>
        {fields.map(f => (
          <div key={f.label}>
            <div className="form-label" style={{ marginBottom: '4px' }}>{f.label}</div>
            <div style={{ fontSize: '14px', color: 'var(--text-primary)', textTransform: 'capitalize' }}>
              {f.value}
            </div>
          </div>
        ))}
      </div>

      {/* Description */}
      <div style={{
        background: 'var(--bg-surface)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius-md)',
        padding: '16px',
        lineHeight: '1.7',
        color: 'var(--text-secondary)',
        fontSize: '14px',
      }}>
        {submission.description}
      </div>
    </div>
  )
}
