import { useEffect, useState } from 'react'
import { submissionService } from '../services/submissions'

export default function AuditLogs() {
  const [logs, setLogs]   = useState([])
  const [loading, setLoading] = useState(true)
  const [page, setPage]   = useState(1)
  const [pages, setPages] = useState(1)
  const [total, setTotal] = useState(0)

  const load = async (p = page) => {
    setLoading(true)
    try {
      const data = await submissionService.getAuditLogs({ page: p, per_page: 30 })
      setLogs(data.logs)
      setPages(data.pages)
      setTotal(data.total)
    } catch (e) { console.error(e) }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [page])

  const formatDate = (iso) => iso
    ? new Date(iso).toLocaleString('en-GB', {
        day: '2-digit', month: 'short', year: 'numeric',
        hour: '2-digit', minute: '2-digit', second: '2-digit',
      })
    : '—'

  const actionColor = (action) => {
    if (action.includes('DELETE'))   return 'var(--danger)'
    if (action.includes('CREATE'))   return 'var(--success)'
    if (action.includes('UPDATE') || action.includes('STATUS')) return 'var(--warning)'
    if (action.includes('LOGIN'))    return 'var(--accent)'
    if (action.includes('ASSIGN'))   return 'var(--info)'
    return 'var(--text-muted)'
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">🔍 Audit Logs</h1>
          <p className="page-subtitle">{total} total audit entries</p>
        </div>
        <button className="btn btn-ghost" id="btn-refresh-logs" onClick={() => load(page)}>
          🔄 Refresh
        </button>
      </div>

      {loading
        ? <div className="spinner-wrapper"><div className="spinner" /></div>
        : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr>
                  <th>Timestamp</th>
                  <th>Actor</th>
                  <th>Action</th>
                  <th>Entity</th>
                  <th>Details</th>
                  <th>IP</th>
                </tr>
              </thead>
              <tbody>
                {logs.map(log => (
                  <tr key={log.id}>
                    <td className="text-sm text-muted" style={{ whiteSpace: 'nowrap' }}>
                      {formatDate(log.timestamp)}
                    </td>
                    <td style={{ fontWeight: 500 }}>{log.actor || 'System'}</td>
                    <td>
                      <span style={{
                        fontFamily: 'monospace',
                        fontSize: '12px',
                        color: actionColor(log.action),
                        fontWeight: 600,
                      }}>
                        {log.action}
                      </span>
                    </td>
                    <td className="text-muted text-sm">
                      {log.entity_type && `${log.entity_type} #${log.entity_id}`}
                    </td>
                    <td className="text-muted text-sm truncate" style={{ maxWidth: '260px' }}>
                      {log.details || '—'}
                    </td>
                    <td className="text-muted text-sm" style={{ fontFamily: 'monospace' }}>
                      {log.ip_address || '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )
      }

      {pages > 1 && (
        <div className="flex items-center justify-between mt-16">
          <span className="text-muted">Page {page} of {pages}</span>
          <div className="flex gap-8">
            <button className="btn btn-ghost btn-sm" id="btn-logs-prev"
              disabled={page <= 1} onClick={() => setPage(p => p - 1)}>← Prev</button>
            <button className="btn btn-ghost btn-sm" id="btn-logs-next"
              disabled={page >= pages} onClick={() => setPage(p => p + 1)}>Next →</button>
          </div>
        </div>
      )}
    </div>
  )
}
