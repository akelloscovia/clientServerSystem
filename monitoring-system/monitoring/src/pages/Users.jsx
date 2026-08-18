import { useEffect, useState, useCallback } from 'react'
import { submissionService } from '../services/submissions'

export default function Users() {
  const [users, setUsers]     = useState([])
  const [loading, setLoading] = useState(true)
  const [roleFilter, setRoleFilter] = useState('')
  const [actionLoading, setActionLoading] = useState(null)
  const [msg, setMsg] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const data = await submissionService.getUsers(roleFilter ? { role: roleFilter } : {})
      setUsers(data)
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [roleFilter])

  useEffect(() => { load() }, [load])

  const changeRole = async (userId, newRole) => {
    setActionLoading(userId + '_role')
    try {
      await submissionService.updateUserRole(userId, newRole)
      setMsg(`Role updated to ${newRole}`)
      load()
    } catch { setMsg('Failed to update role.') }
    finally { setActionLoading(null) }
  }

  const toggleActive = async (userId) => {
    setActionLoading(userId + '_active')
    try {
      await submissionService.toggleUserActive(userId)
      load()
    } catch { setMsg('Failed to toggle status.') }
    finally { setActionLoading(null) }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">👥 User Management</h1>
          <p className="page-subtitle">Manage user accounts and roles</p>
        </div>
      </div>

      {msg && <div className="alert alert-info" style={{ marginBottom: '16px' }}>{msg}</div>}

      {/* Filter */}
      <div className="card" style={{ marginBottom: '20px' }}>
        <div className="flex gap-8 items-center">
          <span className="text-muted">Filter by role:</span>
          {['', 'user', 'secretary', 'admin'].map(r => (
            <button
              key={r}
              id={`filter-role-${r || 'all'}`}
              className={`btn btn-sm ${roleFilter === r ? 'btn-primary' : 'btn-ghost'}`}
              onClick={() => setRoleFilter(r)}
              style={{ textTransform: 'capitalize' }}
            >
              {r || 'All'}
            </button>
          ))}
        </div>
      </div>

      {loading
        ? <div className="spinner-wrapper"><div className="spinner" /></div>
        : (
          <div className="table-wrapper">
            <table>
              <thead>
                <tr>
                  <th>#</th>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>Status</th>
                  <th>Joined</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map(u => (
                  <tr key={u.id}>
                    <td style={{ color: 'var(--text-muted)', fontFamily: 'monospace' }}>{u.id}</td>
                    <td style={{ fontWeight: 600 }}>{u.name}</td>
                    <td className="text-muted">{u.email}</td>
                    <td><span className={`badge badge-${u.role}`}>{u.role}</span></td>
                    <td>
                      <span className={`badge ${u.is_active ? 'badge-resolved' : 'badge-closed'}`}>
                        {u.is_active ? 'Active' : 'Disabled'}
                      </span>
                    </td>
                    <td className="text-muted text-sm">
                      {new Date(u.created_at).toLocaleDateString('en-GB')}
                    </td>
                    <td onClick={e => e.stopPropagation()}>
                      <div className="flex gap-8">
                        {/* Role change */}
                        <select
                          id={`role-select-${u.id}`}
                          className="form-select"
                          style={{ fontSize: '12px', padding: '4px 8px', width: 'auto' }}
                          value={u.role}
                          onChange={e => changeRole(u.id, e.target.value)}
                          disabled={actionLoading === u.id + '_role'}
                        >
                          <option value="user">user</option>
                          <option value="secretary">secretary</option>
                          <option value="admin">admin</option>
                        </select>
                        <button
                          id={`btn-toggle-${u.id}`}
                          className={`btn btn-sm ${u.is_active ? 'btn-danger' : 'btn-success'}`}
                          onClick={() => toggleActive(u.id)}
                          disabled={actionLoading === u.id + '_active'}
                        >
                          {u.is_active ? 'Disable' : 'Enable'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )
      }
    </div>
  )
}
