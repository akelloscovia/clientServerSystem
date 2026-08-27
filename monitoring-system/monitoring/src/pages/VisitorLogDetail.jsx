import { useEffect, useState, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { visitorService } from '../services/visitors'
import { submissionService } from '../services/submissions'
import { useAuth } from '../context/AuthContext'

const STATUSES = ['pending', 'assigned', 'attended', 'closed']

export default function VisitorLogDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [visitor, setVisitor] = useState(null)
  const [staff, setStaff] = useState([])
  const [loading, setLoading] = useState(true)
  const [assigning, setAssigning] = useState(false)
  const [selectedStaff, setSelectedStaff] = useState('')
  const [statusChanging, setStatusChanging] = useState(false)
  const [replyMessage, setReplyMessage] = useState('')
  const [replying, setReplying] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [confirmingDelete, setConfirmingDelete] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const v = await visitorService.get(id)
      setVisitor(v)
    } catch {
      setError('Failed to load visitor entry.')
    } finally {
      setLoading(false)
    }
  }, [id])

  useEffect(() => {
    load()
    if (user?.role === 'admin') {
      // Staff pool for assignment: secretaries handle visitor follow-ups too.
      submissionService.getSecretaries().then(setStaff).catch(() => {})
    }
  }, [load, user])

  const formatDate = (iso) => iso
    ? new Date(iso).toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })
    : '—'

  const handleStatusChange = async (newStatus) => {
    setStatusChanging(true)
    setError(''); setSuccess('')
    try {
      await visitorService.updateStatus(id, newStatus)
      setSuccess(`Status updated to "${newStatus}"`)
      load()
    } catch {
      setError('Failed to update status.')
    } finally {
      setStatusChanging(false)
    }
  }

  const handleAssign = async (e) => {
    e.preventDefault()
    if (!selectedStaff) return
    setError(''); setSuccess('')
    try {
      await visitorService.assign(id, parseInt(selectedStaff))
      setSuccess('Visitor assigned successfully!')
      setAssigning(false)
      load()
    } catch {
      setError('Failed to assign visitor.')
    }
  }

  const handleReply = async (e) => {
    e.preventDefault()
    if (!replyMessage.trim()) return
    setReplying(true)
    setError(''); setSuccess('')
    try {
      await visitorService.reply(id, replyMessage.trim())
      setReplyMessage('')
      load()
    } catch {
      setError('Failed to send reply.')
    } finally {
      setReplying(false)
    }
  }

  const handleDelete = async () => {
    setDeleting(true)
    setError('')
    try {
      await visitorService.remove(id)
      navigate('/visitor-log')
    } catch {
      setError('Failed to delete visitor entry.')
      setDeleting(false)
    }
  }

  if (loading) return <div className="spinner-wrapper"><div className="spinner" /></div>
  if (!visitor) return <div className="alert alert-error">{error || 'Not found.'}</div>

  return (
    <div>
      <div className="page-header">
        <div>
          <button className="btn btn-ghost btn-sm" onClick={() => navigate(-1)} id="btn-back">← Back</button>
          <h1 className="page-title" style={{ marginTop: '8px' }}>Visitor #{id}</h1>
        </div>
        <div className="flex gap-8 items-center flex-wrap">
          <span className="text-muted text-sm">Change Status:</span>
          {STATUSES.map(s => (
            <button
              key={s}
              id={`btn-status-${s}`}
              className={`btn btn-sm ${visitor.status === s ? 'btn-primary' : 'btn-ghost'}`}
              disabled={statusChanging || visitor.status === s}
              onClick={() => handleStatusChange(s)}
              style={{ textTransform: 'capitalize' }}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      {error && <div className="alert alert-error">{error}</div>}
      {success && <div className="alert alert-success">{success}</div>}

      {/* Visitor details */}
      <div className="card" style={{ marginBottom: '24px' }}>
        <div className="flex items-center justify-between" style={{ marginBottom: '16px' }}>
          <h3 style={{ fontSize: '18px', fontWeight: 700 }}>{visitor.name}</h3>
          <span className={`badge badge-${visitor.status}`}>{visitor.status}</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '16px' }}>
          <div>
            <div className="text-muted text-sm">Company</div>
            <div>{visitor.company || '—'}</div>
          </div>
          <div>
            <div className="text-muted text-sm">Assigned To</div>
            <div>{visitor.assignee || 'Unassigned'}</div>
          </div>
          <div>
            <div className="text-muted text-sm">Visit Date</div>
            <div>{visitor.visit_date}</div>
          </div>
          <div>
            <div className="text-muted text-sm">Time In</div>
            <div>{visitor.time_in}</div>
          </div>
        </div>
        <div style={{ marginBottom: '12px' }}>
          <div className="text-muted text-sm">Reason for Visiting</div>
          <div>{visitor.reason_for_visit}</div>
        </div>
        {visitor.description && (
          <div>
            <div className="text-muted text-sm">Description</div>
            <div style={{ color: 'var(--text-secondary)', lineHeight: 1.6 }}>{visitor.description}</div>
          </div>
        )}
      </div>

      {/* Assign (admin only) */}
      {user?.role === 'admin' && (
        <div className="card" style={{ marginBottom: '24px' }}>
          <div className="flex items-center justify-between" style={{ marginBottom: assigning ? '16px' : '0' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 600 }}>👤 Assignment</h3>
            <button id="btn-toggle-assign" className="btn btn-ghost btn-sm" onClick={() => setAssigning(!assigning)}>
              {assigning ? 'Cancel' : '+ Assign to Staff'}
            </button>
          </div>
          {assigning && (
            <form onSubmit={handleAssign}>
              <div className="form-group" style={{ marginBottom: '12px' }}>
                <label className="form-label">Staff Member</label>
                <select id="select-staff" className="form-select" value={selectedStaff}
                  onChange={e => setSelectedStaff(e.target.value)} required>
                  <option value="">Select staff...</option>
                  {staff.map(s => (
                    <option key={s.id} value={s.id}>{s.name} ({s.email})</option>
                  ))}
                </select>
              </div>
              <button id="btn-confirm-assign" type="submit" className="btn btn-primary btn-sm">
                ✅ Confirm Assignment
              </button>
            </form>
          )}
        </div>
      )}

      {/* Reply thread */}
      <div className="card" style={{ marginBottom: '24px' }}>
        <h3 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '16px' }}>
          💬 Replies ({visitor.replies?.length || 0})
        </h3>
        {!visitor.replies?.length
          ? <p className="text-muted">No replies yet.</p>
          : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {visitor.replies.map(r => (
                <div key={r.id} style={{
                  background: 'var(--bg-surface)', border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-md)', padding: '14px 16px',
                }}>
                  <div className="flex items-center justify-between" style={{ marginBottom: '8px' }}>
                    <span style={{ fontWeight: 600, fontSize: '14px' }}>{r.responder}</span>
                    <span className="text-muted text-sm">{formatDate(r.created_at)}</span>
                  </div>
                  <p style={{ fontSize: '14px', color: 'var(--text-secondary)', lineHeight: '1.6' }}>{r.message}</p>
                </div>
              ))}
            </div>
          )}
      </div>

      <div className="card" style={{ marginBottom: '24px' }}>
        <h3 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '16px' }}>✍️ Add Reply</h3>
        <form onSubmit={handleReply}>
          <div className="form-group" style={{ marginBottom: '16px' }}>
            <textarea id="reply-message" className="form-textarea" rows={4}
              value={replyMessage} onChange={e => setReplyMessage(e.target.value)}
              placeholder="Write a reply for this visitor..." required />
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button id="btn-send-reply" type="submit" className="btn btn-primary" disabled={replying || !replyMessage.trim()}>
              {replying ? '⏳ Sending...' : '📤 Send Reply'}
            </button>
          </div>
        </form>
      </div>

      {/* Delete (admin only) */}
      {user?.role === 'admin' && (
        <div className="card" style={{ borderColor: 'var(--danger)' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '12px', color: 'var(--danger)' }}>
            🗑️ Delete Visitor Entry
          </h3>
          {!confirmingDelete ? (
            <button id="btn-delete-visitor" className="btn btn-danger btn-sm" onClick={() => setConfirmingDelete(true)}>
              Delete this entry
            </button>
          ) : (
            <div className="flex items-center gap-8">
              <span className="text-muted text-sm">Are you sure? This cannot be undone.</span>
              <button id="btn-confirm-delete" className="btn btn-danger btn-sm" disabled={deleting} onClick={handleDelete}>
                {deleting ? 'Deleting...' : 'Yes, delete'}
              </button>
              <button id="btn-cancel-delete" className="btn btn-ghost btn-sm" onClick={() => setConfirmingDelete(false)}>
                Cancel
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
