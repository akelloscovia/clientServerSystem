import { useCallback, useEffect, useState } from 'react'
import { advertisementService } from '../services/advertisements'

const emptyForm = { title: '', description: '', image_data: '', link_url: '', is_active: true }

function readImage(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result)
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

export default function Advertisements() {
  const [ads, setAds] = useState([])
  const [form, setForm] = useState(emptyForm)
  const [editingId, setEditingId] = useState(null)
  const [showModal, setShowModal] = useState(false)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    try { setAds(await advertisementService.list(true)) } catch (e) { setError(e.response?.data?.message || 'Failed to load advertisements.') }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  const openCreate = () => { setForm(emptyForm); setEditingId(null); setError(''); setShowModal(true) }
  const openEdit = (ad) => {
    setForm({ title: ad.title, description: ad.description || '', image_data: ad.image_data || '', link_url: ad.link_url || '', is_active: ad.is_active })
    setEditingId(ad.id); setError(''); setShowModal(true)
  }
  const set = (key) => (e) => setForm((current) => ({ ...current, [key]: e.target.type === 'checkbox' ? e.target.checked : e.target.value }))
  const selectImage = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    if (!file.type.startsWith('image/')) { setError('Please choose an image file.'); return }
    if (file.size > 3 * 1024 * 1024) { setError('Image must be smaller than 3 MB.'); return }
    const imageData = await readImage(file)
    setForm((current) => ({ ...current, image_data: String(imageData) }))
  }

  const submit = async (e) => {
    e.preventDefault(); setSaving(true); setError('')
    try {
      if (editingId) await advertisementService.update(editingId, form)
      else await advertisementService.create(form)
      setShowModal(false); await load()
    } catch (err) {
      const messages = err.response?.data?.errors
      setError(messages ? Object.values(messages).flat().join(' ') : 'Failed to save advertisement.')
    } finally { setSaving(false) }
  }

  const remove = async (ad) => {
    if (!window.confirm(`Remove "${ad.title}"?`)) return
    try { await advertisementService.remove(ad.id); await load() } catch { setError('Failed to remove advertisement.') }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">📣 Advertisements</h1>
          <p className="page-subtitle">Manage the adverts shown below the reception TV display.</p>
        </div>
        <button className="btn btn-primary" onClick={openCreate}>+ Add Advertisement</button>
      </div>
      {error && !showModal && <div className="alert alert-error">{error}</div>}
      {loading ? <div className="spinner-wrapper"><div className="spinner" /></div> : !ads.length ? (
        <div className="card" style={{ textAlign: 'center', padding: '60px' }}><div style={{ fontSize: 48 }}>📣</div><p className="text-muted">No advertisements published yet.</p></div>
      ) : (
        <div className="table-wrapper"><table><thead><tr><th>Preview</th><th>Title</th><th>Link</th><th>Status</th><th>Actions</th></tr></thead><tbody>
          {ads.map((ad) => <tr key={ad.id}><td>{ad.image_data ? <img src={ad.image_data} alt="" style={{ width: 100, height: 54, objectFit: 'cover', borderRadius: 6 }} /> : <span className="text-muted">Text</span>}</td><td style={{ fontWeight: 600 }}>{ad.title}</td><td className="text-muted text-sm">{ad.link_url || 'No link'}</td><td><span className={`badge ${ad.is_active ? 'badge-resolved' : 'badge-closed'}`}>{ad.is_active ? 'Active' : 'Inactive'}</span></td><td><div className="flex gap-8"><button className="btn btn-ghost btn-sm" onClick={() => openEdit(ad)}>Edit</button><button className="btn btn-danger btn-sm" onClick={() => remove(ad)}>Delete</button></div></td></tr>)}
        </tbody></table></div>
      )}
      {showModal && <div className="modal-overlay" onClick={() => setShowModal(false)}><div className="modal" onClick={(e) => e.stopPropagation()}><h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20 }}>{editingId ? 'Edit Advertisement' : 'Add Advertisement'}</h2>{error && <div className="alert alert-error">{error}</div>}<form onSubmit={submit}>
        <div className="form-group mb-16"><label className="form-label">Title</label><input className="form-input" required maxLength="150" value={form.title} onChange={set('title')} placeholder="Advertiser or campaign name" /></div>
        <div className="form-group mb-16"><label className="form-label">Message</label><textarea className="form-input" rows="3" maxLength="500" value={form.description} onChange={set('description')} placeholder="Short message shown on the kiosk" /></div>
        <div className="form-group mb-16"><label className="form-label">Image</label><input type="file" accept="image/*" onChange={selectImage} />{form.image_data && <img src={form.image_data} alt="Preview" style={{ display: 'block', width: '100%', maxHeight: 150, objectFit: 'cover', marginTop: 10, borderRadius: 8 }} />}</div>
        <div className="form-group mb-16"><label className="form-label">Link URL (optional)</label><input className="form-input" type="url" maxLength="500" value={form.link_url} onChange={set('link_url')} placeholder="https://example.com" /></div>
        <label className="flex items-center gap-8 mb-16"><input type="checkbox" checked={form.is_active} onChange={set('is_active')} /> <span className="text-muted">Publish on kiosk</span></label>
        <div className="flex gap-8 justify-between"><button type="button" className="btn btn-ghost" onClick={() => setShowModal(false)}>Cancel</button><button type="submit" className="btn btn-primary" disabled={saving}>{saving ? 'Saving...' : 'Save Advertisement'}</button></div>
      </form></div></div>}
    </div>
  )
}
