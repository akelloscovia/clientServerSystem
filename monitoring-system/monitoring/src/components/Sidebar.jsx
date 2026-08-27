import { NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './Sidebar.css'

const NAV_ITEMS = [
  { path: '/dashboard', label: 'Dashboard', icon: '📊', roles: ['admin'] },
  { path: '/submissions', label: 'Submissions', icon: '📋', roles: ['admin', 'secretary'] },
  { path: '/visitor-log', label: 'Visitor Log', icon: '🧾', roles: ['admin', 'secretary'] },
  { path: '/programs', label: 'Programs', icon: '📅', roles: ['admin', 'secretary'] },
  { path: '/channels', label: 'TV Channels', icon: '📺', roles: ['admin'] },
  { path: '/users', label: 'Users', icon: '👥', roles: ['admin'] },
  { path: '/audit-logs', label: 'Audit Logs', icon: '🔍', roles: ['admin'] },
]

export default function Sidebar() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const visibleItems = NAV_ITEMS.filter(item => item.roles.includes(user?.role))

  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <div className="logo-icon">⚡</div>
        <div>
          <div className="logo-name">MonitorSys</div>
          <div className="logo-sub">Control Panel</div>
        </div>
      </div>

      {/* User info */}
      <div className="sidebar-user">
        <div className="user-avatar">{user?.name?.[0]?.toUpperCase()}</div>
        <div className="user-info">
          <div className="user-name">{user?.name}</div>
          <span className={`badge badge-${user?.role}`}>{user?.role}</span>
        </div>
      </div>

      <div className="sidebar-divider" />

      {/* Navigation */}
      <nav className="sidebar-nav">
        {visibleItems.map(item => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
          >
            <span className="nav-icon">{item.icon}</span>
            <span className="nav-label">{item.label}</span>
          </NavLink>
        ))}
      </nav>

      {/* Logout */}
      <div className="sidebar-footer">
        <button className="btn btn-ghost w-full" onClick={handleLogout} id="btn-logout">
          <span>🚪</span> Sign Out
        </button>
      </div>
    </aside>
  )
}
