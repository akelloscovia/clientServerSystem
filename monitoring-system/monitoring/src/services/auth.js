import api from './api'

export const authService = {
  async login(email, password) {
    const { data } = await api.post('/auth/login', { email, password })
    localStorage.setItem('access_token', data.access_token)
    localStorage.setItem('refresh_token', data.refresh_token)
    localStorage.setItem('user', JSON.stringify(data.user))
    return data.user
  },

  async me() {
    const { data } = await api.get('/auth/me')
    return data.user
  },

  logout() {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('user')
  },

  getStoredUser() {
    try {
      return JSON.parse(localStorage.getItem('user'))
    } catch {
      return null
    }
  },

  isAuthenticated() {
    return !!localStorage.getItem('access_token')
  },
}
