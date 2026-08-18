import { useEffect, useState, useCallback } from 'react'
import { submissionService } from '../services/submissions'
import SubmissionTable from '../components/SubmissionTable'
import { useAuth } from '../context/AuthContext'

const STATUSES   = ['', 'pending', 'under_review', 'assigned', 'resolved', 'closed']
const CATEGORIES = ['', 'complaint', 'inquiry', 'report', 'request', 'other']

export default function Submissions() {
  const { user } = useAuth()
  const [submissions, setSubmissions] = useState([])
  const [loading, setLoading]         = useState(true)
  const [page, setPage]               = useState(1)
  const [total, setTotal]             = useState(0)
  const [pages, setPages]             = useState(1)
  const [statusFilter, setStatusFilter]     = useState('')
  const [categoryFilter, setCategoryFilter] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await submissionService.list({
        page,
        per_page: 15,
        ...(statusFilter   && { status: statusFilter }),
        ...(categoryFilter && { category: categoryFilter }),
      })
      setSubmissions(res.submissions)
      setTotal(res.total)
      setPages(res.pages)
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [page, statusFilter, categoryFilter])

  useEffect(() => { load() }, [load])

  const handleFilter = () => { setPage(1); load() }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">📋 Submissions</h1>
          <p className="page-subtitle">{total} total cases</p>
        </div>
      </div>

      {/* Filters */}
      <div className="card" style={{ marginBottom: '20px' }}>
        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'flex-end' }}>
          <div className="form-group" style={{ minWidth: '160px' }}>
            <label className="form-label">Status</label>
            <select
              id="filter-status"
              className="form-select"
              value={statusFilter}
              onChange={e => { setStatusFilter(e.target.value); setPage(1) }}
            >
              {STATUSES.map(s => (
                <option key={s} value={s}>{s ? s.replace('_', ' ') : 'All Statuses'}</option>
              ))}
            </select>
          </div>
          <div className="form-group" style={{ minWidth: '160px' }}>
            <label className="form-label">Category</label>
            <select
              id="filter-category"
              className="form-select"
              value={categoryFilter}
              onChange={e => { setCategoryFilter(e.target.value); setPage(1) }}
            >
              {CATEGORIES.map(c => (
                <option key={c} value={c}>{c || 'All Categories'}</option>
              ))}
            </select>
          </div>
          <button id="btn-refresh" className="btn btn-ghost" onClick={load}>
            🔄 Refresh
          </button>
        </div>
      </div>

      {loading
        ? <div className="spinner-wrapper"><div className="spinner" /></div>
        : <SubmissionTable submissions={submissions} userRole={user?.role} />
      }

      {/* Pagination */}
      {pages > 1 && (
        <div className="flex items-center justify-between mt-16">
          <span className="text-muted">Page {page} of {pages}</span>
          <div className="flex gap-8">
            <button
              className="btn btn-ghost btn-sm"
              disabled={page <= 1}
              onClick={() => setPage(p => p - 1)}
              id="btn-prev-page"
            >← Prev</button>
            <button
              className="btn btn-ghost btn-sm"
              disabled={page >= pages}
              onClick={() => setPage(p => p + 1)}
              id="btn-next-page"
            >Next →</button>
          </div>
        </div>
      )}
    </div>
  )
}
