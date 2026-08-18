import api from './api'

export const submissionService = {
  async list(params = {}) {
    const { data } = await api.get('/submissions', { params })
    return data
  },

  async get(id) {
    const { data } = await api.get(`/submissions/${id}`)
    return data.submission
  },

  async updateStatus(id, status) {
    const { data } = await api.patch(`/submissions/${id}/status`, { status })
    return data.submission
  },

  async delete(id) {
    const { data } = await api.delete(`/submissions/${id}`)
    return data
  },

  async assign(submissionId, assignedTo, notes = '') {
    const { data } = await api.post('/submissions/assign', {
      submission_id: submissionId,
      assigned_to: assignedTo,
      notes,
    })
    return data
  },

  async getAssignments() {
    const { data } = await api.get('/submissions/assignments')
    return data.assignments
  },

  async addResponse(submissionId, message) {
    const { data } = await api.post('/responses', {
      submission_id: submissionId,
      message,
    })
    return data.response
  },

  async getResponses(submissionId) {
    const { data } = await api.get(`/responses/${submissionId}`)
    return data.responses
  },

  async getStats() {
    const { data } = await api.get('/monitoring/stats')
    return data
  },

  async getAuditLogs(params = {}) {
    const { data } = await api.get('/monitoring/audit-logs', { params })
    return data
  },

  async getUsers(params = {}) {
    const { data } = await api.get('/users', { params })
    return data.users
  },

  async getSecretaries() {
    const { data } = await api.get('/users/secretaries')
    return data.secretaries
  },

  async updateUserRole(userId, role) {
    const { data } = await api.patch(`/users/${userId}/role`, { role })
    return data.user
  },

  async toggleUserActive(userId) {
    const { data } = await api.patch(`/users/${userId}/toggle-active`)
    return data.user
  },

  async getNotifications() {
    const { data } = await api.get('/monitoring/notifications')
    return data
  },

  async markNotificationRead(id) {
    return api.patch(`/monitoring/notifications/${id}/read`)
  },

  async markAllNotificationsRead() {
    return api.patch('/monitoring/notifications/read-all')
  },
}
