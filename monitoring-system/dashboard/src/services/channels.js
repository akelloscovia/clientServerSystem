import api from './api'

export const channelService = {
  async list(params = {}) {
    const { data } = await api.get('/channels', { params: { all: 1, ...params } })
    return data.channels
  },

  async create(payload) {
    const { data } = await api.post('/channels', payload)
    return data.channel
  },

  async update(id, payload) {
    const { data } = await api.put(`/channels/${id}`, payload)
    return data.channel
  },

  async remove(id) {
    const { data } = await api.delete(`/channels/${id}`)
    return data
  },
}
