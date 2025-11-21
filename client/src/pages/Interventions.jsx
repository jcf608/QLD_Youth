import { useEffect, useState } from 'react'
import { Target, Search, Filter, User, Briefcase, Calendar, TrendingUp } from 'lucide-react'
import { api } from '../api/client'

const Interventions = () => {
  const [interventions, setInterventions] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')

  useEffect(() => {
    fetchInterventions()
  }, [])

  const fetchInterventions = async () => {
    try {
      const response = await api.getInterventions()
      setInterventions(response.data)
    } catch (error) {
      console.error('Error fetching interventions:', error)
    } finally {
      setLoading(false)
    }
  }

  const getStatusBadge = (status) => {
    const badges = {
      planned: 'badge-warning',
      in_progress: 'badge-success',
      completed: 'badge-info',
      cancelled: 'badge-danger'
    }
    return `badge ${badges[status] || 'badge-info'}`
  }

  const filteredInterventions = interventions.filter(intervention => {
    const matchesSearch = 
      intervention.youth?.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      intervention.intervention_type?.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === 'all' || intervention.status === statusFilter
    const matchesType = typeFilter === 'all' || intervention.intervention_type === typeFilter
    return matchesSearch && matchesStatus && matchesType
  })

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-2xl font-bold text-gray-900">Interventions</h1>
          <button className="btn btn-primary">
            <Target size={18} className="inline mr-2" />
            New Intervention
          </button>
        </div>

        {/* Filters */}
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
            <input
              type="text"
              placeholder="Search interventions..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input pl-10"
            />
          </div>
          <div className="flex items-center gap-2">
            <Filter size={20} className="text-gray-400" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input"
            >
              <option value="all">All Status</option>
              <option value="planned">Planned</option>
              <option value="in_progress">In Progress</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="input"
          >
            <option value="all">All Types</option>
            <option value="counseling">Counseling</option>
            <option value="education_support">Education Support</option>
            <option value="employment_training">Employment Training</option>
            <option value="family_support">Family Support</option>
            <option value="substance_abuse">Substance Abuse</option>
            <option value="mental_health">Mental Health</option>
            <option value="community_service">Community Service</option>
          </select>
        </div>
      </div>

      {/* Interventions List */}
      <div className="space-y-4">
        {filteredInterventions.map((intervention) => (
          <div key={intervention.id} className="card hover:shadow-lg transition-shadow">
            <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
              <div className="flex-1">
                <div className="flex items-start gap-3 mb-3">
                  <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Target className="text-primary-600" size={20} />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900 text-lg capitalize mb-1">
                      {intervention.intervention_type?.replace(/_/g, ' ')}
                    </h3>
                    <span className={getStatusBadge(intervention.status)}>
                      {intervention.status?.replace(/_/g, ' ')}
                    </span>
                  </div>
                </div>

                {intervention.description && (
                  <p className="text-sm text-gray-600 mb-3">{intervention.description}</p>
                )}

                <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                  {intervention.youth && (
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <User size={16} className="text-gray-400" />
                      <span>{intervention.youth.full_name}</span>
                    </div>
                  )}
                  {intervention.youth_case && (
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Briefcase size={16} className="text-gray-400" />
                      <span>Case #{intervention.youth_case.case_number}</span>
                    </div>
                  )}
                  {intervention.start_date && (
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Calendar size={16} className="text-gray-400" />
                      <span>Started: {intervention.start_date}</span>
                    </div>
                  )}
                </div>
              </div>

              {intervention.attendance_rate !== null && intervention.attendance_rate !== undefined && (
                <div className="flex flex-col items-center justify-center bg-gray-50 rounded-lg p-4 min-w-[120px]">
                  <TrendingUp className={`mb-2 ${
                    intervention.attendance_rate >= 80 ? 'text-green-500' :
                    intervention.attendance_rate >= 60 ? 'text-yellow-500' :
                    'text-red-500'
                  }`} size={24} />
                  <p className="text-2xl font-bold text-gray-900">{intervention.attendance_rate}%</p>
                  <p className="text-xs text-gray-600">Attendance</p>
                </div>
              )}
            </div>

            {intervention.outcomes && (
              <div className="mt-4 pt-4 border-t border-gray-200">
                <p className="text-sm font-medium text-gray-700 mb-1">Outcomes:</p>
                <p className="text-sm text-gray-600">{intervention.outcomes}</p>
              </div>
            )}
          </div>
        ))}
      </div>

      {filteredInterventions.length === 0 && (
        <div className="card text-center py-12">
          <Target size={48} className="mx-auto text-gray-300 mb-4" />
          <p className="text-gray-500">No interventions found</p>
        </div>
      )}
    </div>
  )
}

export default Interventions

