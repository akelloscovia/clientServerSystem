import { useEffect, useState } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import QRCodeGenerator from '../components/QRCodeGenerator'
import { api } from '../services/api'
import '../pages/Submissions.css'

export default function UserSubmissions() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [submissions, setSubmissions] = useState([])
  const [loading, setLoading] = useState(true)
  const [token, setToken] = useState('')
  const [userInfo, setUserInfo] = useState(null)
  const [qrLink, setQrLink] = useState('')

  useEffect(() => {
    const paramToken = searchParams.get('token')
    const storedToken = paramToken || localStorage.getItem('userToken')

    if (storedToken) {
      setToken(storedToken)
      loadUserSubmissions(storedToken)
      generateQRLink(storedToken)
    } else {
      navigate('/user-portal')
    }
  }, [searchParams, navigate])

  const loadUserSubmissions = async (userToken) => {
    setLoading(true)
    try {
      const response = await api.get('/api/submissions/user', {
        headers: {
          'X-User-Token': userToken
        }
      })
      setSubmissions(response.data.submissions || [])
      setUserInfo(response.data.user)
    } catch (error) {
      console.error('Error loading submissions:', error)
      navigate('/user-portal')
    } finally {
      setLoading(false)
    }
  }

  const generateQRLink = (userToken) => {
    const accessUrl = `${window.location.origin}/user-submissions?token=${userToken}`
    setQrLink(accessUrl)
  }

  const handleLogout = () => {
    localStorage.removeItem('userToken')
    navigate('/user-portal')
  }

  if (loading) {
    return <div className="spinner-wrapper"><div className="spinner" /></div>
  }

  return (
    <div className="user-submissions-container">
      <div className="submissions-header">
        <div>
          <h1>📋 My Submissions</h1>
          {userInfo && <p>Welcome, {userInfo.email}</p>}
        </div>
        <button onClick={handleLogout} className="btn-logout">Logout</button>
      </div>

      {submissions.length === 0 ? (
        <div className="empty-state">
          <p>No submissions yet</p>
          <button onClick={() => navigate('/user-portal')} className="btn-primary">
            Back to Portal
          </button>
        </div>
      ) : (
        <>
          <div className="submissions-grid">
            {submissions.map((submission) => (
              <div key={submission.id} className="submission-card">
                <div className="card-header">
                  <h3>{submission.title || `Submission #${submission.id}`}</h3>
                  <span className={`status-badge status-${submission.status}`}>
                    {submission.status}
                  </span>
                </div>
                <div className="card-body">
                  <p><strong>Category:</strong> {submission.category}</p>
                  <p><strong>Date:</strong> {new Date(submission.created_at).toLocaleDateString()}</p>
                  {submission.description && (
                    <p><strong>Description:</strong> {submission.description.substring(0, 100)}...</p>
                  )}
                </div>
              </div>
            ))}
          </div>

          <div className="qr-section">
            <h3>Share Your Access</h3>
            <p>Share this QR code to allow others to view your submissions</p>
            <QRCodeGenerator 
              data={qrLink}
              label="Scan to access submissions"
              size={200}
              downloadName="my-submissions-access"
            />
          </div>
        </>
      )}
    </div>
  )
}
