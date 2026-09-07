import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import QRCodeScanner from '../components/QRCodeScanner'
import QRCodeGenerator from '../components/QRCodeGenerator'
import api from '../services/api'
import './UserPortal.css'

export default function UserPortal() {
  const navigate = useNavigate()
  const [userEmail, setUserEmail] = useState('')
  const [userToken, setUserToken] = useState(localStorage.getItem('userToken') || '')
  const [mode, setMode] = useState('login') // login, scan, qr
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(false)
  const [qrData, setQrData] = useState('')

  useEffect(() => {
    if (userToken) {
      setMode('access')
    }
  }, [userToken])

  const handleQRScan = async (scannedData) => {
    try {
      // Extract token or ID from QR code
      setUserToken(scannedData)
      localStorage.setItem('userToken', scannedData)
      setMessage('✓ QR Code scanned successfully!')
      setMode('access')
    } catch (error) {
      setMessage('✗ Failed to scan QR code')
    }
  }

  const handleEmailAccess = async () => {
    if (!userEmail) {
      setMessage('Please enter your email')
      return
    }

    setLoading(true)
    try {
      const response = await api.post('/api/auth/user-portal', { email: userEmail })
      
      // Generate QR code for this email
      const qrContent = `${window.location.origin}/user-access?token=${response.data.token}`
      setQrData(qrContent)
      
      setUserToken(response.data.token)
      localStorage.setItem('userToken', response.data.token)
      setMessage('✓ Access granted! Use the QR code below to access from other devices.')
      setMode('qr')
    } catch (error) {
      setMessage('✗ Email not found or access denied')
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = () => {
    setUserToken('')
    setUserEmail('')
    localStorage.removeItem('userToken')
    setMode('login')
    setMessage('')
    setQrData('')
  }

  const navigateToSubmissions = () => {
    navigate('/user-submissions')
  }

  return (
    <div className="user-portal-container">
      <div className="portal-header">
        <h1>📱 User Portal</h1>
        <p>Access your submissions easily</p>
      </div>

      {message && (
        <div className={`message ${message.includes('✗') ? 'error' : 'success'}`}>
          {message}
        </div>
      )}

      {mode === 'login' && (
        <div className="portal-section">
          <h2>Choose Access Method</h2>
          
          <div className="access-methods">
            <div className="method-card">
              <h3>📧 Email Access</h3>
              <p>Enter your email to get started</p>
              <input
                type="email"
                placeholder="your@email.com"
                value={userEmail}
                onChange={(e) => setUserEmail(e.target.value)}
                disabled={loading}
              />
              <button 
                onClick={handleEmailAccess}
                disabled={loading}
                className="btn-primary"
              >
                {loading ? 'Processing...' : 'Get Access'}
              </button>
            </div>

            <div className="divider">OR</div>

            <div className="method-card">
              <h3>📸 Scan QR Code</h3>
              <p>Scan a QR code to access directly</p>
              <QRCodeScanner 
                onScan={handleQRScan}
                onError={(err) => console.log('Scan error:', err)}
              />
            </div>
          </div>
        </div>
      )}

      {mode === 'qr' && qrData && (
        <div className="portal-section">
          <h2>Your Access QR Code</h2>
          <p>Share this QR code or use it to access on other devices:</p>
          <QRCodeGenerator 
            data={qrData}
            label="Scan to access your submissions"
            downloadName="submission-access"
          />
          <button 
            onClick={navigateToSubmissions}
            className="btn-primary btn-large"
          >
            Continue to My Submissions
          </button>
        </div>
      )}

      {mode === 'access' && (
        <div className="portal-section">
          <h2>Welcome Back!</h2>
          <p>You have access to your submissions</p>
          <div className="access-buttons">
            <button 
              onClick={navigateToSubmissions}
              className="btn-primary btn-large"
            >
              View My Submissions
            </button>
            <button 
              onClick={handleLogout}
              className="btn-secondary"
            >
              Logout
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
