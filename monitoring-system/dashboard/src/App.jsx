import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Sidebar from './components/Sidebar'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Submissions from './pages/Submissions'
import SubmissionDetail from './pages/SubmissionDetails'
import Users from './pages/Users'
import AuditLogs from './pages/AuditLogs'
import VisitorForm from './pages/VisitorForm'
import VisitorLog from './pages/VisitorLog'
import VisitorLogDetail from './pages/VisitorLogDetail'
import Programs from './pages/Programs'
import Channels from './pages/Channels'

function ProtectedLayout({ children }) {
  const { user, loading } = useAuth()
  if (loading) return <div className="spinner-wrapper"><div className="spinner" /></div>
  if (!user)   return <Navigate to="/login" replace />
  return (
    <div className="app-layout">
      <Sidebar />
      <main className="main-content">{children}</main>
    </div>
  )
}

function AdminOnly({ children }) {
  const { user } = useAuth()
  if (user?.role !== 'admin') return <Navigate to="/submissions" replace />
  return children
}

function StaffOnly({ children }) {
  const { user } = useAuth()
  if (user?.role !== 'admin' && user?.role !== 'secretary') return <Navigate to="/submissions" replace />
  return children
}

function RoleHome() {
  const { user } = useAuth()
  return <Navigate to={user?.role === 'admin' ? '/dashboard' : '/submissions'} replace />
}

function AppRoutes() {
  const { user } = useAuth()
  return (
    <Routes>
      {/* Public visitor sign-in form — reached by scanning the kiosk's QR code, no login. */}
      <Route path="/visitor-form" element={<VisitorForm />} />

      {/* Admin/Staff routes */}
      <Route path="/login" element={user ? <Navigate to="/dashboard" /> : <Login />} />

      <Route path="/dashboard" element={
        <ProtectedLayout><AdminOnly><Dashboard /></AdminOnly></ProtectedLayout>
      } />
      <Route path="/submissions" element={
        <ProtectedLayout><Submissions /></ProtectedLayout>
      } />
      <Route path="/submissions/:id" element={
        <ProtectedLayout><SubmissionDetail /></ProtectedLayout>
      } />
      <Route path="/visitor-log" element={
        <ProtectedLayout><VisitorLog /></ProtectedLayout>
      } />
      <Route path="/visitor-log/:id" element={
        <ProtectedLayout><VisitorLogDetail /></ProtectedLayout>
      } />
      <Route path="/programs" element={
        <ProtectedLayout><StaffOnly><Programs /></StaffOnly></ProtectedLayout>
      } />
      <Route path="/channels" element={
        <ProtectedLayout><AdminOnly><Channels /></AdminOnly></ProtectedLayout>
      } />
      <Route path="/users" element={
        <ProtectedLayout><AdminOnly><Users /></AdminOnly></ProtectedLayout>
      } />
      <Route path="/audit-logs" element={
        <ProtectedLayout><AdminOnly><AuditLogs /></AdminOnly></ProtectedLayout>
      } />

      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="*" element={<RoleHome />} />
    </Routes>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AppRoutes />
      </AuthProvider>
    </BrowserRouter>
  )
}
