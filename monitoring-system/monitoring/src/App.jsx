import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Sidebar from './components/Sidebar'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Submissions from './pages/Submissions'
import SubmissionDetail from './pages/SubmissionDetails'
import Users from './pages/Users'
import AuditLogs from './pages/AuditLogs'

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
  if (user?.role !== 'admin') return <Navigate to="/dashboard" replace />
  return children
}

function AppRoutes() {
  const { user } = useAuth()
  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to="/dashboard" /> : <Login />} />

      <Route path="/dashboard" element={
        <ProtectedLayout><Dashboard /></ProtectedLayout>
      } />
      <Route path="/submissions" element={
        <ProtectedLayout><Submissions /></ProtectedLayout>
      } />
      <Route path="/submissions/:id" element={
        <ProtectedLayout><SubmissionDetail /></ProtectedLayout>
      } />
      <Route path="/users" element={
        <ProtectedLayout><AdminOnly><Users /></AdminOnly></ProtectedLayout>
      } />
      <Route path="/audit-logs" element={
        <ProtectedLayout><AdminOnly><AuditLogs /></AdminOnly></ProtectedLayout>
      } />

      <Route path="*" element={<Navigate to="/dashboard" replace />} />
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
