import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import {
  ArrowLeft,
  User,
  Calendar,
  Phone,
  MapPin,
  AlertCircle,
  Briefcase,
  Target
} from 'lucide-react'
import { api } from '../api/client'

const YouthDetail = () => {
  const { id } = useParams()
  const [youth, setYouth] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchYouthDetail()
  }, [id])

  const fetchYouthDetail = async () => {
    try {
      const response = await api.getYouthById(id)
      setYouth(response.data)
    } catch (error) {
      console.error('Error fetching youth detail:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  if (!youth) {
    return (
      <div className="text-center py-12">
        <AlertCircle size={48} className="mx-auto text-red-500 mb-4" />
        <p className="text-gray-500">Youth not found</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="card">
        <Link to="/youth" className="inline-flex items-center gap-2 text-primary-600 hover:text-primary-800 mb-4">
          <ArrowLeft size={20} />
          Back to Youth List
        </Link>
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center">
              <User className="text-primary-600" size={32} />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">{youth.full_name}</h1>
              <p className="text-lg text-gray-600">{youth.age} years old • {youth.gender}</p>
            </div>
          </div>
          <button className="btn btn-primary">Edit Profile</button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Personal Information */}
          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Personal Information</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium text-gray-600">First Name</label>
                <p className="text-base text-gray-900">{youth.first_name}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-600">Last Name</label>
                <p className="text-base text-gray-900">{youth.last_name}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-600">Date of Birth</label>
                <div className="flex items-center gap-2 text-base text-gray-900">
                  <Calendar size={16} className="text-gray-400" />
                  {youth.date_of_birth}
                </div>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-600">Age</label>
                <p className="text-base text-gray-900">{youth.age} years</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-600">Gender</label>
                <p className="text-base text-gray-900">{youth.gender}</p>
              </div>
            </div>
          </div>

          {/* Contact Information */}
          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Contact Information</h2>
            <div className="space-y-4">
              {youth.phone && (
                <div>
                  <label className="text-sm font-medium text-gray-600">Phone</label>
                  <div className="flex items-center gap-2 text-base text-gray-900">
                    <Phone size={16} className="text-gray-400" />
                    {youth.phone}
                  </div>
                </div>
              )}
              {youth.address && (
                <div>
                  <label className="text-sm font-medium text-gray-600">Address</label>
                  <div className="flex items-center gap-2 text-base text-gray-900">
                    <MapPin size={16} className="text-gray-400" />
                    {youth.address}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Emergency Contact */}
          {(youth.emergency_contact || youth.emergency_phone) && (
            <div className="card">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Emergency Contact</h2>
              <div className="space-y-3">
                {youth.emergency_contact && (
                  <div>
                    <label className="text-sm font-medium text-gray-600">Contact Name</label>
                    <p className="text-base text-gray-900">{youth.emergency_contact}</p>
                  </div>
                )}
                {youth.emergency_phone && (
                  <div>
                    <label className="text-sm font-medium text-gray-600">Phone</label>
                    <div className="flex items-center gap-2 text-base text-gray-900">
                      <Phone size={16} className="text-gray-400" />
                      {youth.emergency_phone}
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Cases */}
          {youth.cases && youth.cases.length > 0 && (
            <div className="card">
              <div className="flex items-center gap-2 mb-4">
                <Briefcase className="text-primary-600" size={20} />
                <h2 className="text-xl font-semibold text-gray-900">Cases</h2>
              </div>
              <div className="space-y-3">
                {youth.cases.map((caseItem) => (
                  <Link
                    key={caseItem.id}
                    to={`/cases/${caseItem.id}`}
                    className="block border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-gray-900">{caseItem.case_number}</p>
                        <p className="text-sm text-gray-600 capitalize">
                          {caseItem.case_type?.replace(/_/g, ' ')}
                        </p>
                      </div>
                      <span className={`badge ${
                        caseItem.status === 'active' ? 'badge-success' :
                        caseItem.status === 'closed' ? 'badge-info' :
                        'badge-warning'
                      }`}>
                        {caseItem.status}
                      </span>
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Quick Stats */}
          <div className="card">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Stats</h2>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Active Cases</span>
                <span className="text-lg font-bold text-gray-900">
                  {youth.cases?.filter(c => c.status === 'active').length || 0}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Total Cases</span>
                <span className="text-lg font-bold text-gray-900">
                  {youth.cases?.length || 0}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Interventions</span>
                <span className="text-lg font-bold text-gray-900">
                  {youth.interventions?.length || 0}
                </span>
              </div>
            </div>
          </div>

          {/* Recent Interventions */}
          {youth.interventions && youth.interventions.length > 0 && (
            <div className="card">
              <div className="flex items-center gap-2 mb-4">
                <Target className="text-primary-600" size={20} />
                <h2 className="text-lg font-semibold text-gray-900">Recent Interventions</h2>
              </div>
              <div className="space-y-3">
                {youth.interventions.slice(0, 3).map((intervention) => (
                  <div key={intervention.id} className="border-l-4 border-primary-500 pl-3 py-2">
                    <p className="text-sm font-medium text-gray-900 capitalize">
                      {intervention.intervention_type?.replace(/_/g, ' ')}
                    </p>
                    <span className={`badge mt-1 ${
                      intervention.status === 'in_progress' ? 'badge-success' :
                      intervention.status === 'completed' ? 'badge-info' :
                      'badge-warning'
                    }`}>
                      {intervention.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default YouthDetail

