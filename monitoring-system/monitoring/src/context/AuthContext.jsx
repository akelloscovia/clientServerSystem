import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { authService } from '../services/auth'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const stored = authService.getStoredUser()
    if (stored && authService.isAuthenticated()) {
      setUser(stored)
    }
    setLoading(false)
  }, [])

  const login = useCallback(async (email, password) => {
    const u = await authService.login(email, password)
    // Only allow admin and secretary to access the dashboard
    if (u.role === 'user') {
      authService.logout()
      throw new Error('Access denied. This portal is for administrators and secretaries only.')
    }
    setUser(u)
    return u
  }, [])

  const logout = useCallback(() => {
    authService.logout()
    setUser(null)
  }, [])

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
