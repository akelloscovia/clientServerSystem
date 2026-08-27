import api from './api'

export const programService = {
  async list(params = {}) {
    const { data } = await api.get('/programs', { params: { all: 1, ...params } })
    return data.programs
  },

  async create(payload) {
    const { data } = await api.post('/programs', payload)
    return data.program
  },

  async update(id, payload) {
    const { data } = await api.put(`/programs/${id}`, payload)
    return data.program
  },

  async remove(id) {
    const { data } = await api.delete(`/programs/${id}`)
    return data
  },
}
