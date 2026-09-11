import api from './api'

export const advertisementService = {
  async list(all = false) {
    const { data } = await api.get('/advertisements', { params: all ? { all: 1 } : {} })
    return data.advertisements
  },
  async create(payload) {
    const { data } = await api.post('/advertisements', payload)
    return data.advertisement
  },
  async update(id, payload) {
    const { data } = await api.put(`/advertisements/${id}`, payload)
    return data.advertisement
  },
  async remove(id) {
    return api.delete(`/advertisements/${id}`)
  },
}
