import { NavLink, useNavigate } from 'react-router-dom'
import { useEffect, useState } from 'react'
import {
  LayoutDashboard, ClipboardList, ScrollText, Calendar,
  Megaphone, Tv, Users, Search, LogOut,
} from 'lucide-react'
import Pusher from 'pusher-js'
import { useAuth } from '../context/AuthContext'
import { submissionService } from '../services/submissions'
import ministryLogo from '../assets/ministry_logo.jpg'
import './Sidebar.css'

const NAV_ITEMS = [
  { path: '/dashboard', label: 'Dashboard', icon: LayoutDashboard, roles: ['admin'] },
  { path: '/submissions', label: 'Submissions', icon: ClipboardList, roles: ['admin', 'secretary'] },
  { path: '/visitor-log', label: 'Visitor Log', icon: ScrollText, roles: ['admin', 'secretary'] },
  { path: '/programs', label: 'Programs', icon: Calendar, roles: ['admin', 'secretary'] },
  { path: '/advertisements', label: 'Advertisements', icon: Megaphone, roles: ['admin', 'secretary'] },
  { path: '/channels', label: 'TV Channels', icon: Tv, roles: ['admin'] },
  { path: '/users', label: 'Users', icon: Users, roles: ['admin'] },
  { path: '/audit-logs', label: 'Audit Logs', icon: Search, roles: ['admin'] },
  { path: '/messages', label: 'Staff Messages', icon: Search, roles: ['admin', 'secretary'] },
]

export default function Sidebar() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [unread, setUnread] = useState(0)

  useEffect(() => {
    let channel
    let client
    submissionService.getNotifications().then(data => setUnread(data.unread_count || 0)).catch(() => {})

    const pusherKey = import.meta.env.VITE_PUSHER_KEY || ''
    const pusherCluster = import.meta.env.VITE_PUSHER_CLUSTER || 'mt1'

    if (!user?.id || !pusherKey) return undefined

    try {
      client = new Pusher(pusherKey, {
        cluster: pusherCluster,
        authEndpoint: '/api/pusher/auth',
        auth: { headers: { Authorization: `Bearer ${localStorage.getItem('access_token')}` } },
      })
      channel = client.subscribe(`private-user-${user.id}`)
      channel.bind('notification.created', () => setUnread(value => value + 1))
    } catch (error) {
      console.error('Pusher initialization failed:', error)
    }

    return () => {
      channel?.unbind_all()
      client?.disconnect()
    }
  }, [user?.id])

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const visibleItems = NAV_ITEMS.filter(item => item.roles.includes(user?.role))

  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <div className="logo-icon">
          <img src={ministryLogo} alt="Ministry crest" />
        </div>
        <div>
          <div className="logo-name">Ministry of Planning and Investment</div>
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
            <item.icon className="nav-icon" size={18} strokeWidth={2} />
            <span className="nav-label">{item.label}</span>
            {item.path === '/messages' && unread > 0 && <span className="nav-badge">{unread}</span>}
          </NavLink>
        ))}
      </nav>

      {/* Logout */}
      <div className="sidebar-footer">
        <button className="btn btn-ghost w-full" onClick={handleLogout} id="btn-logout">
          <LogOut size={16} strokeWidth={2} /> Sign Out
        </button>
      </div>
    </aside>
  )
}
