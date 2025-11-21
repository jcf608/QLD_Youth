import { useEffect, useState } from 'react'
import { UserCheck, Mail, Phone, Briefcase, Search } from 'lucide-react'
import { api } from '../api/client'

const CaseManagers = () => {
  const [managers, setManagers] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    fetchManagers()
  }, [])

  const fetchManagers = async () => {
    try {
      const response = await api.getCaseManagers()
      setManagers(response.data)
    } catch (error) {
      console.error('Error fetching case managers:', error)
    } finally {
      setLoading(false)
    }
  }

  const filteredManagers = managers.filter(manager =>
    manager.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    manager.email?.toLowerCase().includes(searchTerm.toLowerCase())
  )

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
          <h1 className="text-2xl font-bold text-gray-900">Case Managers</h1>
          <button className="btn btn-primary">
            <UserCheck size={18} className="inline mr-2" />
            Add Case Manager
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Search by name or email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input pl-10"
          />
        </div>
      </div>

      {/* Managers Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredManagers.map((manager) => (
          <div key={manager.id} className="card hover:shadow-lg transition-shadow">
            <div className="flex items-start gap-4 mb-4">
              <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center flex-shrink-0">
                <UserCheck className="text-primary-600" size={28} />
              </div>
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold text-gray-900 text-lg">{manager.full_name}</h3>
                {manager.department && (
                  <p className="text-sm text-gray-500">{manager.department}</p>
                )}
              </div>
            </div>

            <div className="space-y-3 mb-4">
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Mail size={16} className="text-gray-400 flex-shrink-0" />
                <span className="truncate">{manager.email}</span>
              </div>
              {manager.phone && (
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Phone size={16} className="text-gray-400 flex-shrink-0" />
                  <span>{manager.phone}</span>
                </div>
              )}
              {manager.specializations && (
                <div className="text-sm text-gray-600">
                  <p className="font-medium text-gray-700 mb-1">Specializations:</p>
                  <p className="text-xs">{manager.specializations}</p>
                </div>
              )}
            </div>

            <div className="pt-4 border-t border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Briefcase size={16} className="text-gray-400" />
                  <span>{manager.cases?.length || 0} cases</span>
                </div>
                <button className="text-primary-600 hover:text-primary-800 text-sm font-medium">
                  View Details
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filteredManagers.length === 0 && (
        <div className="card text-center py-12">
          <UserCheck size={48} className="mx-auto text-gray-300 mb-4" />
          <p className="text-gray-500">No case managers found</p>
        </div>
      )}
    </div>
  )
}

export default CaseManagers

