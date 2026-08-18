import { useEffect, useState, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { submissionService } from '../services/submissions'
import SubmissionDetails from '../components/SubmissionDetails'
import ResponseForm from '../components/ResponseForm'
import { useAuth } from '../context/AuthContext'

const STATUSES = ['pending', 'under_review', 'assigned', 'resolved', 'closed']

export default function SubmissionDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [submission, setSubmission] = useState(null)
  const [responses,  setResponses]  = useState([])
  const [secretaries, setSecretaries] = useState([])
  const [loading, setLoading]       = useState(true)
  const [assigning, setAssigning]   = useState(false)
  const [selectedSec, setSelectedSec] = useState('')
  const [assignNotes, setAssignNotes] = useState('')
  const [statusChanging, setStatusChanging] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [sub, resps] = await Promise.all([
        submissionService.get(id),
        submissionService.getResponses(id),
      ])
      setSubmission(sub)
      setResponses(resps)
    } catch (e) {
      setError('Failed to load submission.')
    } finally {
      setLoading(false)
    }
  }, [id])

  useEffect(() => {
    load()
    if (user?.role === 'admin') {
      submissionService.getSecretaries().then(setSecretaries).catch(() => {})
    }
  }, [load, user])

  const handleStatusChange = async (newStatus) => {
    setStatusChanging(true)
    setError(''); setSuccess('')
    try {
      await submissionService.updateStatus(id, newStatus)
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
    if (!selectedSec) return
    setError(''); setSuccess('')
    try {
      await submissionService.assign(parseInt(id), parseInt(selectedSec), assignNotes)
      setSuccess('Submission assigned successfully!')
      setAssigning(false)
      load()
    } catch {
      setError('Failed to assign submission.')
    }
  }

  if (loading) return <div className="spinner-wrapper"><div className="spinner" /></div>

  const formatDate = (iso) => iso
    ? new Date(iso).toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })
    : '—'

  return (
    <div>
      <div className="page-header">
        <div>
          <button className="btn btn-ghost btn-sm" onClick={() => navigate(-1)} id="btn-back">
            ← Back
          </button>
          <h1 className="page-title" style={{ marginTop: '8px' }}>Case #{id}</h1>
        </div>
        {/* Status changer */}
        {user?.role !== 'user' && (
          <div className="flex gap-8 items-center flex-wrap">
            <span className="text-muted text-sm">Change Status:</span>
            {STATUSES.map(s => (
              <button
                key={s}
                id={`btn-status-${s}`}
                className={`btn btn-sm ${submission?.status === s ? 'btn-primary' : 'btn-ghost'}`}
                disabled={statusChanging || submission?.status === s}
                onClick={() => handleStatusChange(s)}
                style={{ textTransform: 'capitalize' }}
              >
                {s.replace('_', ' ')}
              </button>
            ))}
          </div>
        )}
      </div>

      {error   && <div className="alert alert-error">{error}</div>}
      {success && <div className="alert alert-success">{success}</div>}

      {/* Submission detail */}
      <SubmissionDetails submission={submission} />

      {/* Assign (admin only) */}
      {user?.role === 'admin' && (
        <div className="card" style={{ marginBottom: '24px' }}>
          <div className="flex items-center justify-between" style={{ marginBottom: assigning ? '16px' : '0' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 600 }}>👤 Assignment</h3>
            <button
              id="btn-toggle-assign"
              className="btn btn-ghost btn-sm"
              onClick={() => setAssigning(!assigning)}
            >
              {assigning ? 'Cancel' : '+ Assign to Secretary'}
            </button>
          </div>
          {assigning && (
            <form onSubmit={handleAssign}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
                <div className="form-group">
                  <label className="form-label">Secretary</label>
                  <select id="select-secretary" className="form-select" value={selectedSec}
                    onChange={e => setSelectedSec(e.target.value)} required>
                    <option value="">Select secretary...</option>
                    {secretaries.map(s => (
                      <option key={s.id} value={s.id}>{s.name} ({s.email})</option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Notes (optional)</label>
                  <input id="assign-notes" className="form-input" value={assignNotes}
                    onChange={e => setAssignNotes(e.target.value)}
                    placeholder="Assignment instructions..." />
                </div>
              </div>
              <button id="btn-confirm-assign" type="submit" className="btn btn-primary btn-sm">
                ✅ Confirm Assignment
              </button>
            </form>
          )}
        </div>
      )}

      {/* Responses thread */}
      <div className="card" style={{ marginBottom: '24px' }}>
        <h3 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '16px' }}>
          💬 Response Thread ({responses.length})
        </h3>
        {responses.length === 0
          ? <p className="text-muted">No responses yet.</p>
          : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {responses.map(r => (
                <div key={r.id} style={{
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-md)',
                  padding: '14px 16px',
                }}>
                  <div className="flex items-center justify-between" style={{ marginBottom: '8px' }}>
                    <div className="flex items-center gap-8">
                      <div style={{
                        width: '30px', height: '30px',
                        background: 'linear-gradient(135deg, var(--accent), #8b5cf6)',
                        borderRadius: '50%',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: '13px', fontWeight: 700, color: '#fff',
                      }}>
                        {r.responder?.[0]?.toUpperCase()}
                      </div>
                      <span style={{ fontWeight: 600, fontSize: '14px' }}>{r.responder}</span>
                      <span className={`badge badge-${r.responder_role}`}>{r.responder_role}</span>
                    </div>
                    <span className="text-muted text-sm">{formatDate(r.created_at)}</span>
                  </div>
                  <p style={{ fontSize: '14px', color: 'var(--text-secondary)', lineHeight: '1.6' }}>
                    {r.message}
                  </p>
                </div>
              ))}
            </div>
          )
        }
      </div>

      {/* Response form (staff only) */}
      {user?.role !== 'user' && (
        <ResponseForm submissionId={parseInt(id)} onSuccess={load} />
      )}
    </div>
  )
}
