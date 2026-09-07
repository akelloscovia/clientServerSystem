import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './Login.css'

/** Pull the most useful message out of an axios error / thrown Error. */
function extractError(err) {
  const res = err.response
  if (res?.data?.error) return res.data.error
  if (res?.data?.errors) {
    const flat = Object.values(res.data.errors).flat()
    if (flat.length) return flat.join(' ')
  }
  if (res?.status === 423) return 'Account locked after too many failed attempts. Try again later.'
  if (res?.status === 429) return 'Too many attempts. Please wait a minute and try again.'
  // Errors thrown by AuthContext (e.g. role denied) carry a plain message;
  // axios's own "Request failed with status code N" is not useful, so skip it.
  if (err.message && !/request failed with status code/i.test(err.message)) return err.message
  return 'Login failed. Please try again.'
}

export default function Login() {
  const [email, setEmail]     = useState('')
  const [password, setPassword] = useState('')
  const [error, setError]     = useState('')
  const [loading, setLoading] = useState(false)
  const { login } = useAuth()
  const navigate  = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await login(email, password)
      navigate('/dashboard')
    } catch (err) {
      setError(extractError(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-page">
      {/* Background glow */}
      <div className="login-glow glow-1" />
      <div className="login-glow glow-2" />

      <div className="login-card">
        {/* Logo */}
        <div className="login-logo">
          <div className="login-logo-icon">⚡</div>
          <h1 className="login-title">Ministry of Planning and Investment</h1>
          <p className="login-subtitle">Admin &amp; Secretary Portal</p>
        </div>

        {error && (
          <div className="alert alert-error" role="alert">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} noValidate>
          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label className="form-label" htmlFor="login-email">Email Address</label>
            <input
              id="login-email"
              type="email"
              className="form-input"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="admin@system.com"
              required
              autoFocus
            />
          </div>

          <div className="form-group" style={{ marginBottom: '24px' }}>
            <label className="form-label" htmlFor="login-password">Password</label>
            <input
              id="login-password"
              type="password"
              className="form-input"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>

          <button
            id="btn-login"
            type="submit"
            className="btn btn-primary btn-lg w-full"
            disabled={loading}
            style={{ justifyContent: 'center' }}
          >
            {loading ? '⏳ Signing in...' : '🔐 Sign In'}
          </button>
        </form>

        <p className="login-hint">
          🔒 This portal is restricted to administrators and secretaries only.
        </p>
      </div>
    </div>
  )
}
