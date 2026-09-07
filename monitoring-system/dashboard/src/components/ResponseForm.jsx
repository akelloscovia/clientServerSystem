import { useState } from 'react'
import { submissionService } from '../services/submissions'

export default function ResponseForm({ submissionId, onSuccess }) {
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!message.trim()) return
    setLoading(true)
    setError('')
    try {
      await submissionService.addResponse(submissionId, message.trim())
      setMessage('')
      onSuccess?.()
    } catch (err) {
      setError(err.response?.data?.error || err.response?.data?.errors
        ? JSON.stringify(err.response.data.errors)
        : 'Failed to send response.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="card">
      <h3 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '16px', color: 'var(--text-primary)' }}>
        ✍️ Add Response
      </h3>
      {error && <div className="alert alert-error">{error}</div>}
      <form onSubmit={handleSubmit}>
        <div className="form-group" style={{ marginBottom: '16px' }}>
          <label className="form-label">Your Response</label>
          <textarea
            id="response-message"
            className="form-textarea"
            value={message}
            onChange={e => setMessage(e.target.value)}
            placeholder="Type your response to the user..."
            rows={5}
            required
          />
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <button
            id="btn-send-response"
            type="submit"
            className="btn btn-primary"
            disabled={loading || !message.trim()}
          >
            {loading ? '⏳ Sending...' : '📤 Send Response'}
          </button>
        </div>
      </form>
    </div>
  )
}
