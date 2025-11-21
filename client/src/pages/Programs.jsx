import { useEffect, useState } from 'react'
import { Folder, MapPin, Users, Clock, Search, Filter } from 'lucide-react'
import { api } from '../api/client'

const Programs = () => {
  const [programs, setPrograms] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [typeFilter, setTypeFilter] = useState('all')

  useEffect(() => {
    fetchPrograms()
  }, [])

  const fetchPrograms = async () => {
    try {
      const response = await api.getPrograms()
      setPrograms(response.data)
    } catch (error) {
      console.error('Error fetching programs:', error)
    } finally {
      setLoading(false)
    }
  }

  const getProgramTypeColor = (type) => {
    const colors = {
      education: 'bg-blue-100 text-blue-800',
      employment: 'bg-green-100 text-green-800',
      counseling: 'bg-purple-100 text-purple-800',
      rehabilitation: 'bg-orange-100 text-orange-800',
      community_based: 'bg-teal-100 text-teal-800',
      residential: 'bg-red-100 text-red-800'
    }
    return colors[type] || 'bg-gray-100 text-gray-800'
  }

  const filteredPrograms = programs.filter(program => {
    const matchesSearch = program.name?.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesType = typeFilter === 'all' || program.program_type === typeFilter
    return matchesSearch && matchesType
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
          <h1 className="text-2xl font-bold text-gray-900">Programs</h1>
          <button className="btn btn-primary">
            <Folder size={18} className="inline mr-2" />
            Create Program
          </button>
        </div>

        {/* Filters */}
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
            <input
              type="text"
              placeholder="Search programs..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="input pl-10"
            />
          </div>
          <div className="flex items-center gap-2">
            <Filter size={20} className="text-gray-400" />
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="input"
            >
              <option value="all">All Types</option>
              <option value="education">Education</option>
              <option value="employment">Employment</option>
              <option value="counseling">Counseling</option>
              <option value="rehabilitation">Rehabilitation</option>
              <option value="community_based">Community Based</option>
              <option value="residential">Residential</option>
            </select>
          </div>
        </div>
      </div>

      {/* Programs Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {filteredPrograms.map((program) => (
          <div key={program.id} className="card hover:shadow-lg transition-shadow">
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-start gap-3">
                <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Folder className="text-primary-600" size={24} />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 text-lg mb-1">{program.name}</h3>
                  <span className={`badge ${getProgramTypeColor(program.program_type)}`}>
                    {program.program_type?.replace(/_/g, ' ')}
                  </span>
                </div>
              </div>
              <span className={`badge ${
                program.status === 'active' ? 'badge-success' : 'badge-info'
              }`}>
                {program.status}
              </span>
            </div>

            {program.description && (
              <p className="text-sm text-gray-600 mb-4 line-clamp-2">{program.description}</p>
            )}

            <div className="grid grid-cols-2 gap-4 mb-4">
              {program.duration_weeks && (
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Clock size={16} className="text-gray-400" />
                  <span>{program.duration_weeks} weeks</span>
                </div>
              )}
              {program.capacity && (
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Users size={16} className="text-gray-400" />
                  <span>Capacity: {program.capacity}</span>
                </div>
              )}
            </div>

            {program.location && (
              <div className="flex items-center gap-2 text-sm text-gray-600 mb-4">
                <MapPin size={16} className="text-gray-400" />
                <span>{program.location}</span>
              </div>
            )}

            <div className="pt-4 border-t border-gray-200">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">
                  {program.interventions?.length || 0} active interventions
                </span>
                <button className="text-primary-600 hover:text-primary-800 text-sm font-medium">
                  View Details
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filteredPrograms.length === 0 && (
        <div className="card text-center py-12">
          <Folder size={48} className="mx-auto text-gray-300 mb-4" />
          <p className="text-gray-500">No programs found</p>
        </div>
      )}
    </div>
  )
}

export default Programs

