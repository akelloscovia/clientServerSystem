import { useEffect, useState, useCallback } from 'react'
import { channelService } from '../services/channels'

const STREAM_TYPES = ['hls', 'youtube', 'mp4', 'other']

const emptyForm = {
  name: '', stream_url: '', logo_url: '', stream_type: 'hls', sort_order: 0, is_active: true,
}

export default function Channels() {
  const [channels, setChannels] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    try {
      setChannels(await channelService.list())
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const openCreate = () => {
    setForm({ ...emptyForm, sort_order: channels.length })
    setEditingId(null)
    setError('')
    setShowModal(true)
  }

  const openEdit = (c) => {
    setForm({
      name: c.name, stream_url: c.stream_url, logo_url: c.logo_url || '',
      stream_type: c.stream_type, sort_order: c.sort_order, is_active: c.is_active,
    })
    setEditingId(c.id)
    setError('')
    setShowModal(true)
  }

  const set = (key) => (e) => {
    let value = e.target.type === 'checkbox' ? e.target.checked : e.target.value
    if (key === 'sort_order') value = parseInt(value) || 0
    setForm(f => ({ ...f, [key]: value }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSaving(true)
    setError('')
    try {
      if (editingId) await channelService.update(editingId, form)
      else await channelService.create(form)
      setShowModal(false)
      load()
    } catch (err) {
      const messages = err.response?.data?.errors
      setError(messages ? Object.values(messages).flat().join(' ') : 'Failed to save channel.')
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (c) => {
    if (!window.confirm(`Remove "${c.name}"?`)) return
    try {
      await channelService.remove(c.id)
      load()
    } catch (e) {
      console.error(e)
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">📺 TV Channels</h1>
          <p className="page-subtitle">Channels available on the reception kiosk — pick existing ones or add your own URL</p>
        </div>
        <button id="btn-add-channel" className="btn btn-primary" onClick={openCreate}>+ Add Channel</button>
      </div>

      {loading
        ? <div className="spinner-wrapper"><div className="spinner" /></div>
        : !channels.length
          ? (
            <div className="card" style={{ textAlign: 'center', padding: '60px' }}>
              <div style={{ fontSize: '48px', marginBottom: '12px' }}>📺</div>
              <p className="text-muted">No channels added yet.</p>
            </div>
          )
          : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>#</th><th>Name</th><th>Stream URL</th><th>Type</th><th>Status</th><th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {channels.map(c => (
                    <tr key={c.id}>
                      <td className="text-muted">{c.sort_order}</td>
                      <td style={{ fontWeight: 600 }}>{c.name}</td>
                      <td className="text-muted text-sm truncate" style={{ maxWidth: '280px' }}>{c.stream_url}</td>
                      <td className="text-muted" style={{ textTransform: 'uppercase' }}>{c.stream_type}</td>
                      <td>
                        <span className={`badge ${c.is_active ? 'badge-resolved' : 'badge-closed'}`}>
                          {c.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td>
                        <div className="flex gap-8">
                          <button id={`btn-edit-channel-${c.id}`} className="btn btn-ghost btn-sm" onClick={() => openEdit(c)}>Edit</button>
                          <button id={`btn-delete-channel-${c.id}`} className="btn btn-danger btn-sm" onClick={() => handleDelete(c)}>Delete</button>
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
              {editingId ? 'Edit Channel' : 'Add Channel'}
            </h2>
            {error && <div className="alert alert-error">{error}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-group mb-16">
                <label className="form-label">Channel Name</label>
                <input id="form-name" className="form-input" required value={form.name} onChange={set('name')} placeholder="e.g. NTV, KTN, Parliament" />
              </div>
              <div className="form-group mb-16">
                <label className="form-label">Stream URL</label>
                <input id="form-url" className="form-input" required value={form.stream_url} onChange={set('stream_url')}
                  placeholder="https://.../stream.m3u8 or a YouTube live link" />
              </div>
              <div className="form-group mb-16">
                <label className="form-label">Logo URL (optional)</label>
                <input id="form-logo" className="form-input" value={form.logo_url} onChange={set('logo_url')} />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }} className="mb-16">
                <div className="form-group">
                  <label className="form-label">Stream Type</label>
                  <select id="form-type" className="form-select" value={form.stream_type} onChange={set('stream_type')}>
                    {STREAM_TYPES.map(t => <option key={t} value={t}>{t.toUpperCase()}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Sort Order</label>
                  <input id="form-sort" type="number" className="form-input" value={form.sort_order} onChange={set('sort_order')} />
                </div>
              </div>
              <div className="form-group mb-16">
                <label className="flex items-center gap-8" style={{ cursor: 'pointer' }}>
                  <input id="form-active" type="checkbox" checked={form.is_active} onChange={set('is_active')} />
                  <span className="text-muted">Active (selectable on kiosk)</span>
                </label>
              </div>
              <div className="flex gap-8 justify-between">
                <button type="button" className="btn btn-ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button id="btn-save-channel" type="submit" className="btn btn-primary" disabled={saving}>
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
