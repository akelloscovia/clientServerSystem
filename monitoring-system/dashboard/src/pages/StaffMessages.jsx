import { useEffect, useState } from 'react'
import { Send, Bell, CheckCheck } from 'lucide-react'
import Pusher from 'pusher-js'
import { useAuth } from '../context/AuthContext'
import { submissionService } from '../services/submissions'

export default function StaffMessages() {
  const { user } = useAuth()
  const [targets, setTargets] = useState([])
  const [notifications, setNotifications] = useState([])
  const [targetId, setTargetId] = useState('')
  const [message, setMessage] = useState('')
  const [status, setStatus] = useState('')

  const load = async () => {
    const [targetUsers, data] = await Promise.all([
      submissionService.getNotificationTargets(),
      submissionService.getNotifications(),
    ])
    setTargets(targetUsers)
    setNotifications(data.notifications)
    if (!targetId && targetUsers[0]) setTargetId(String(targetUsers[0].id))
  }

  useEffect(() => {
    load().catch(() => setStatus('Could not load staff messages.'))

    const pusherKey = import.meta.env.VITE_PUSHER_KEY || ''
    const pusherCluster = import.meta.env.VITE_PUSHER_CLUSTER || 'mt1'
    if (!user?.id || !pusherKey) return undefined

    try {
      const client = new Pusher(pusherKey, {
        cluster: pusherCluster,
        authEndpoint: '/api/pusher/auth',
        auth: { headers: { Authorization: `Bearer ${localStorage.getItem('access_token')}` } },
      })
      const channel = client.subscribe(`private-user-${user.id}`)
      const onNotification = event => setNotifications(current => [event.notification, ...current])
      channel.bind('notification.created', onNotification)
      return () => { channel.unbind('notification.created', onNotification); client.disconnect() }
    } catch (error) {
      console.error('Pusher initialization failed:', error)
      return undefined
    }
  }, [user?.id])

  const send = async event => {
    event.preventDefault()
    if (!targetId || !message.trim()) return
    try {
      await submissionService.sendNotification(Number(targetId), message.trim())
      setMessage('')
      setStatus('Notification sent.')
    } catch (error) {
      setStatus(error.response?.data?.message || 'Could not send notification.')
    }
  }

  const markRead = async id => {
    await submissionService.markNotificationRead(id)
    setNotifications(items => items.map(item => item.id === id ? { ...item, is_read: true } : item))
  }

  return <section className="page-container">
    <div className="page-header"><div><h1>Staff Messages</h1><p>Send a direct notification to the {user?.role === 'admin' ? 'secretary' : 'admin'} team.</p></div></div>
    <div className="messages-grid">
      <form className="card" onSubmit={send}>
        <h2>New notification</h2>
        <div className="form-group"><label className="form-label" htmlFor="message-recipient">Recipient</label><select id="message-recipient" className="form-select" value={targetId} onChange={event => setTargetId(event.target.value)}><option value="">Select recipient</option>{targets.map(target => <option key={target.id} value={target.id}>{target.name} ({target.email})</option>)}</select></div>
        <div className="form-group"><label className="form-label" htmlFor="staff-message">Message</label><textarea id="staff-message" className="form-textarea" maxLength={1000} value={message} onChange={event => setMessage(event.target.value)} placeholder="Write a notification..." /></div>
        <button className="btn btn-primary" type="submit"><Send size={16} /> Send notification</button>
        {status && <p className="form-status">{status}</p>}
      </form>
      <div className="card"><div className="messages-heading"><h2>Received</h2><Bell size={18} /></div>{notifications.length === 0 ? <p className="empty-state">No notifications yet.</p> : notifications.map(item => <article className={`message-item ${item.is_read ? '' : 'unread'}`} key={item.id}><p>{item.message}</p><small>{new Date(item.created_at).toLocaleString()}</small>{!item.is_read && <button className="message-read" onClick={() => markRead(item.id)}><CheckCheck size={14} /> Mark read</button>}</article>)}</div>
    </div>
  </section>
}