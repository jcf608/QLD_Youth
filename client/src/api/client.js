import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:9292'

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// API methods
export const api = {
  // Dashboard
  getDashboardStats: () => apiClient.get('/api/dashboard/stats'),

  // Cases
  getCases: () => apiClient.get('/api/cases'),
  getCase: (id) => apiClient.get(`/api/cases/${id}`),
  createCase: (data) => apiClient.post('/api/cases', data),
  updateCase: (id, data) => apiClient.put(`/api/cases/${id}`, data),

  // Youth
  getYouth: () => apiClient.get('/api/youth'),
  getYouthById: (id) => apiClient.get(`/api/youth/${id}`),
  createYouth: (data) => apiClient.post('/api/youth', data),

  // Case Managers
  getCaseManagers: () => apiClient.get('/api/case-managers'),
  getCaseManager: (id) => apiClient.get(`/api/case-managers/${id}`),

  // Interventions
  getInterventions: () => apiClient.get('/api/interventions'),
  createIntervention: (data) => apiClient.post('/api/interventions', data),
  updateIntervention: (id, data) => apiClient.put(`/api/interventions/${id}`, data),

  // Programs
  getPrograms: () => apiClient.get('/api/programs'),
  getProgram: (id) => apiClient.get(`/api/programs/${id}`),
  createProgram: (data) => apiClient.post('/api/programs', data),

  // Case Notes
  createCaseNote: (data) => apiClient.post('/api/case-notes', data),
}

export default apiClient

