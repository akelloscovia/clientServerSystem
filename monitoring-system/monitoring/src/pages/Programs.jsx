import { useEffect, useState, useCallback } from 'react'
import { programService } from '../services/programs'
import { useAuth } from '../context/AuthContext'

const DAYS = ['daily', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']

const emptyForm = {
  title: '', description: '', day: 'daily',
  start_time: '09:00', end_time: '10:00', location: '', is_active: true,
}

export default function Programs() {
  const { user } = useAuth()
  const isAdmin = user?.role === 'admin'
  const [programs, setPrograms] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    try {
      setPrograms(await programService.list())
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const openCreate = () => {
    setForm(emptyForm)
    setEditingId(null)
    setError('')
    setShowModal(true)
  }

  const openEdit = (p) => {
    setForm({
      title: p.title, description: p.description || '', day: p.day,
      start_time: p.start_time, end_time: p.end_time,
      location: p.location || '', is_active: p.is_active,
    })
    setEditingId(p.id)
    setError('')
    setShowModal(true)
  }

  const set = (key) => (e) => {
    const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value
    setForm(f => ({ ...f, [key]: value }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSaving(true)
    setError('')
    try {
      if (editingId) await programService.update(editingId, form)
      else await programService.create(form)
      setShowModal(false)
      load()
    } catch (err) {
      const messages = err.response?.data?.errors
      setError(messages ? Object.values(messages).flat().join(' ') : 'Failed to save program.')
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (p) => {
    if (!window.confirm(`Delete "${p.title}"?`)) return
    try {
      await programService.remove(p.id)
      load()
    } catch (e) {
      console.error(e)
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">📅 Daily Programs</h1>
          <p className="page-subtitle">Schedule shown on the reception kiosk</p>
        </div>
        <button id="btn-add-program" className="btn btn-primary" onClick={openCreate}>+ Add Program</button>
      </div>

      {loading
        ? <div className="spinner-wrapper"><div className="spinner" /></div>
        : !programs.length
          ? (
            <div className="card" style={{ textAlign: 'center', padding: '60px' }}>
              <div style={{ fontSize: '48px', marginBottom: '12px' }}>📅</div>
              <p className="text-muted">No programs scheduled yet.</p>
            </div>
          )
          : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>Title</th><th>Day</th><th>Start</th><th>End</th><th>Location</th><th>Status</th><th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {programs.map(p => (
                    <tr key={p.id}>
                      <td style={{ fontWeight: 600 }}>{p.title}</td>
                      <td className="text-muted" style={{ textTransform: 'capitalize' }}>{p.day}</td>
                      <td className="text-muted">{p.start_time}</td>
                      <td className="text-muted">{p.end_time}</td>
                      <td className="text-muted">{p.location || '—'}</td>
                      <td>
                        <span className={`badge ${p.is_active ? 'badge-resolved' : 'badge-closed'}`}>
                          {p.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td>
                        <div className="flex gap-8">
                          <button id={`btn-edit-program-${p.id}`} className="btn btn-ghost btn-sm" onClick={() => openEdit(p)}>Edit</button>
                          {isAdmin && (
                            <button id={`btn-delete-program-${p.id}`} className="btn btn-danger btn-sm" onClick={() => handleDelete(p)}>Delete</button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )
      }

      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h2 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '20px' }}>
              {editingId ? 'Edit Program' : 'Add Program'}
            </h2>
            {error && <div className="alert alert-error">{error}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-group mb-16">
                <label className="form-label">Title</label>
                <input id="form-title" className="form-input" required value={form.title} onChange={set('title')} />
              </div>
              <div className="form-group mb-16">
                <label className="form-label">Description</label>
                <textarea id="form-description" className="form-textarea" rows={3} value={form.description} onChange={set('description')} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }} className="mb-16">
                <div className="form-group">
                  <label className="form-label">Day</label>
                  <select id="form-day" className="form-select" value={form.day} onChange={set('day')}>
                    {DAYS.map(d => <option key={d} value={d}>{d}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Start Time</label>
                  <input id="form-start" type="time" className="form-input" required value={form.start_time} onChange={set('start_time')} />
                </div>
                <div className="form-group">
                  <label className="form-label">End Time</label>
                  <input id="form-end" type="time" className="form-input" required value={form.end_time} onChange={set('end_time')} />
                </div>
              </div>
              <div className="form-group mb-16">
                <label className="form-label">Location</label>
                <input id="form-location" className="form-input" placeholder="e.g. Seminar Room" value={form.location} onChange={set('location')} />
              </div>
              <div className="form-group mb-16">
                <label className="flex items-center gap-8" style={{ cursor: 'pointer' }}>
                  <input id="form-active" type="checkbox" checked={form.is_active} onChange={set('is_active')} />
                  <span className="text-muted">Active (visible on kiosk)</span>
                </label>
              </div>
              <div className="flex gap-8 justify-between">
                <button type="button" className="btn btn-ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button id="btn-save-program" type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving...' : 'Save'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
