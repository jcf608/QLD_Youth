import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { Search, Eye, User, Calendar, Phone } from 'lucide-react'
import { api } from '../api/client'

const YouthList = () => {
  const [youth, setYouth] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    fetchYouth()
  }, [])

  const fetchYouth = async () => {
    try {
      const response = await api.getYouth()
      setYouth(response.data)
    } catch (error) {
      console.error('Error fetching youth:', error)
    } finally {
      setLoading(false)
    }
  }

  const filteredYouth = youth.filter(person =>
    person.full_name?.toLowerCase().includes(searchTerm.toLowerCase())
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
          <h1 className="text-2xl font-bold text-gray-900">Youth Registry</h1>
          <button className="btn btn-primary">
            <User size={18} className="inline mr-2" />
            Add Youth
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Search by name..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input pl-10"
          />
        </div>
      </div>

      {/* Youth Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredYouth.map((person) => (
          <div key={person.id} className="card hover:shadow-lg transition-shadow">
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center">
                  <User className="text-primary-600" size={24} />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">{person.full_name}</h3>
                  <p className="text-sm text-gray-500">{person.age} years old</p>
                </div>
              </div>
            </div>

            <div className="space-y-2 mb-4">
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Calendar size={16} className="text-gray-400" />
                <span>DOB: {person.date_of_birth}</span>
              </div>
              {person.phone && (
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Phone size={16} className="text-gray-400" />
                  <span>{person.phone}</span>
                </div>
              )}
            </div>

            <Link
              to={`/youth/${person.id}`}
              className="btn btn-secondary w-full flex items-center justify-center gap-2"
            >
              <Eye size={16} />
              View Profile
            </Link>
          </div>
        ))}
      </div>

      {filteredYouth.length === 0 && (
        <div className="card text-center py-12">
          <User size={48} className="mx-auto text-gray-300 mb-4" />
          <p className="text-gray-500">No youth found</p>
        </div>
      )}
    </div>
  )
}

export default YouthList

