import { useState } from 'react'
import { visitorService } from '../services/visitors'
import './VisitorForm.css'

function todayISO() {
  return new Date().toISOString().slice(0, 10)
}

function nowHHMM() {
  const d = new Date()
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

const initialForm = {
  name: '',
  company: '',
  visit_date: todayISO(),
  time_in: nowHHMM(),
  reason_for_visit: '',
  description: '',
}

export default function VisitorForm() {
  const [form, setForm] = useState(initialForm)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [ticket, setTicket] = useState(null)

  const set = (key) => (e) => setForm(f => ({ ...f, [key]: e.target.value }))

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const { visitor } = await visitorService.create(form)
      setTicket(visitor)
    } catch (err) {
      const messages = err.response?.data?.errors
      setError(messages ? Object.values(messages).flat().join(' ') : 'Failed to submit. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const startOver = () => {
    setForm(initialForm)
    setTicket(null)
  }

  if (ticket) {
    return (
      <div className="visitor-form-page">
        <div className="visitor-form-card visitor-success">
          <div className="visitor-success-icon">✅</div>
          <h1>You're checked in</h1>
          <p className="text-muted">Thank you, {ticket.name}. Please have a seat — a member of staff will be with you shortly.</p>
          <div className="visitor-ticket">
            <span className="text-muted text-sm">Visit reference</span>
            <div className="visitor-ticket-id">#{ticket.id}</div>
          </div>
          <button className="btn btn-primary btn-lg w-full" onClick={startOver} id="btn-new-visitor">
            Check in another visitor
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="visitor-form-page">
      <form className="visitor-form-card" onSubmit={handleSubmit}>
        <div className="visitor-form-header">
          <h1>Visitor Sign-In</h1>
          <p className="text-muted">Please fill in your details below.</p>
        </div>

        {error && <div className="alert alert-error">{error}</div>}

        <div className="form-group mb-16">
          <label className="form-label">Name</label>
          <input id="field-name" className="form-input" required
            value={form.name} onChange={set('name')} placeholder="Your full name" />
        </div>

        <div className="form-group mb-16">
          <label className="form-label">Company (optional)</label>
          <input id="field-company" className="form-input"
            value={form.company} onChange={set('company')} placeholder="Organization you represent" />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }} className="mb-16">
          <div className="form-group">
            <label className="form-label">Date</label>
            <input id="field-date" type="date" className="form-input" required
              value={form.visit_date} onChange={set('visit_date')} />
          </div>
          <div className="form-group">
            <label className="form-label">Time In</label>
            <input id="field-time" type="time" className="form-input" required
              value={form.time_in} onChange={set('time_in')} />
          </div>
        </div>

        <div className="form-group mb-16">
          <label className="form-label">Reason for Visiting</label>
          <input id="field-reason" className="form-input" required
            value={form.reason_for_visit} onChange={set('reason_for_visit')}
            placeholder="e.g. Meeting with the director" />
        </div>

        <div className="form-group mb-16">
          <label className="form-label">Brief Description</label>
          <textarea id="field-description" className="form-textarea" rows={3}
            value={form.description} onChange={set('description')}
            placeholder="Anything else staff should know..." />
        </div>

        <button type="submit" className="btn btn-primary btn-lg w-full" disabled={loading} id="btn-submit-visitor">
          {loading ? 'Submitting...' : 'Sign In'}
        </button>
      </form>
    </div>
  )
}
