import { useEffect, useState } from 'react'
import { submissionService } from '../services/submissions'
import {
  AreaChart, Area, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, PieChart, Pie, Cell, Legend
} from 'recharts'

const COLORS = ['#3b82f6','#10b981','#f59e0b','#ef4444','#8b5cf6']

const STAT_CARDS = [
  { key: 'total',        label: 'Total Cases',    icon: '📋', color: '#3b82f6' },
  { key: 'pending',      label: 'Pending',         icon: '⏳', color: '#f59e0b' },
  { key: 'under_review', label: 'Under Review',    icon: '🔍', color: '#6366f1' },
  { key: 'assigned',     label: 'Assigned',        icon: '👤', color: '#3b82f6' },
  { key: 'resolved',     label: 'Resolved',        icon: '✅', color: '#10b981' },
  { key: 'closed',       label: 'Closed',          icon: '🔒', color: '#64748b' },
  { key: 'total_users',  label: 'Registered Users',icon: '👥', color: '#8b5cf6' },
  { key: 'secretaries',  label: 'Secretaries',     icon: '🗂️', color: '#06b6d4' },
]

export default function Dashboard() {
  const [stats, setStats]   = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    submissionService.getStats()
      .then(setStats)
      .catch(console.error)
      .finally(() => setLoading(false))
  }, [])

  if (loading) return (
    <div className="spinner-wrapper"><div className="spinner" /></div>
  )

  const overview   = stats?.overview || {}
  const daily      = stats?.daily_trend || []
  const byCategory = Object.entries(stats?.by_category || {}).map(([name, value]) => ({ name, value }))
  const byPriority = Object.entries(stats?.by_priority || {}).map(([name, value]) => ({ name, value }))

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">📊 Dashboard</h1>
          <p className="page-subtitle">Real-time overview of all submissions and cases</p>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="stat-grid">
        {STAT_CARDS.map(card => (
          <div className="stat-card" key={card.key}
            style={{ '--card-accent': card.color }}>
            <div className="stat-icon">{card.icon}</div>
            <div className="stat-label">{card.label}</div>
            <div className="stat-value">{overview[card.key] ?? 0}</div>
          </div>
        ))}
      </div>

      {/* Charts Row */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '24px' }}>
        {/* Daily trend */}
        <div className="card">
          <h3 style={{ fontSize: '15px', fontWeight: 600, marginBottom: '20px' }}>
            📈 Submissions — Last 7 Days
          </h3>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={daily}>
              <defs>
                <linearGradient id="grad1" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#3b82f6" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="date" tick={{ fill: '#64748b', fontSize: 11 }}
                tickFormatter={d => d.slice(5)} />
              <YAxis tick={{ fill: '#64748b', fontSize: 11 }} />
              <Tooltip
                contentStyle={{ background: '#1a2235', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px' }}
                labelStyle={{ color: '#94a3b8' }}
                itemStyle={{ color: '#60a5fa' }}
              />
              <Area type="monotone" dataKey="count" stroke="#3b82f6"
                fill="url(#grad1)" strokeWidth={2} name="Submissions" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* By Category */}
        <div className="card">
          <h3 style={{ fontSize: '15px', fontWeight: 600, marginBottom: '20px' }}>
            🗂️ By Category
          </h3>
          <ResponsiveContainer width="100%" height={220}>
            <PieChart>
              <Pie data={byCategory} cx="50%" cy="50%" innerRadius={55}
                outerRadius={85} paddingAngle={4} dataKey="value" label={false}>
                {byCategory.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{ background: '#1a2235', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px' }}
              />
              <Legend wrapperStyle={{ fontSize: '12px', color: '#94a3b8' }} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* By Priority */}
      <div className="card">
        <h3 style={{ fontSize: '15px', fontWeight: 600, marginBottom: '20px' }}>
          🚨 By Priority
        </h3>
        <ResponsiveContainer width="100%" height={160}>
          <BarChart data={byPriority} layout="vertical">
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
            <XAxis type="number" tick={{ fill: '#64748b', fontSize: 11 }} />
            <YAxis type="category" dataKey="name" tick={{ fill: '#94a3b8', fontSize: 12 }} width={65} />
            <Tooltip
              contentStyle={{ background: '#1a2235', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px' }}
            />
            <Bar dataKey="value" radius={[0, 6, 6, 0]} name="Cases">
              {byPriority.map((entry, i) => (
                <Cell key={i} fill={
                  entry.name === 'urgent' ? '#ef4444' :
                  entry.name === 'high'   ? '#f59e0b' :
                  entry.name === 'medium' ? '#6366f1' : '#10b981'
                } />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
