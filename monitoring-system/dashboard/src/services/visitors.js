import api from './api'

export const visitorService = {
  async create(payload) {
    const { data } = await api.post('/visitors', payload)
    return data
  },

  async list(params = {}) {
    const { data } = await api.get('/visitors', { params })
    return data
  },

  async get(id) {
    const { data } = await api.get(`/visitors/${id}`)
    return data.visitor
  },

  async updateStatus(id, status) {
    const { data } = await api.patch(`/visitors/${id}/status`, { status })
    return data.visitor
  },

  async assign(id, assignedTo) {
    const { data } = await api.post(`/visitors/${id}/assign`, { assigned_to: assignedTo })
    return data
  },

  async reply(id, message) {
    const { data } = await api.post(`/visitors/${id}/replies`, { message })
    return data.reply
  },

  async remove(id) {
    const { data } = await api.delete(`/visitors/${id}`)
    return data
  },
}
