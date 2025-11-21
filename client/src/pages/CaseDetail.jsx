import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import {
  ArrowLeft,
  User,
  Calendar,
  FileText,
  Target,
  MessageSquare,
  AlertCircle,
  CheckCircle,
  Clock
} from 'lucide-react'
import { api } from '../api/client'

const CaseDetail = () => {
  const { id } = useParams()
  const [caseData, setCaseData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchCaseDetail()
  }, [id])

  const fetchCaseDetail = async () => {
    try {
      const response = await api.getCase(id)
      setCaseData(response.data)
    } catch (error) {
      console.error('Error fetching case detail:', error)
    } finally {
      setLoading(false)
    }
  }

  const getStatusIcon = (status) => {
    const icons = {
      active: <CheckCircle className="text-green-500" size={20} />,
      pending: <Clock className="text-yellow-500" size={20} />,
      closed: <CheckCircle className="text-gray-500" size={20} />,
      review: <AlertCircle className="text-red-500" size={20} />
    }
    return icons[status] || <AlertCircle size={20} />
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  if (!caseData) {
    return (
      <div className="text-center py-12">
        <AlertCircle size={48} className="mx-auto text-red-500 mb-4" />
        <p className="text-gray-500">Case not found</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="card">
        <Link to="/cases" className="inline-flex items-center gap-2 text-primary-600 hover:text-primary-800 mb-4">
          <ArrowLeft size={20} />
          Back to Cases
        </Link>
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              Case {caseData.case_number}
            </h1>
            <div className="flex items-center gap-3">
              {getStatusIcon(caseData.status)}
              <span className="text-lg font-medium capitalize">{caseData.status}</span>
            </div>
          </div>
          <button className="btn btn-primary">Edit Case</button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Case Information */}
          <div className="card">
            <div className="flex items-center gap-2 mb-4">
              <FileText className="text-primary-600" size={20} />
              <h2 className="text-xl font-semibold text-gray-900">Case Information</h2>
            </div>
            <div className="space-y-3">
              <div>
                <label className="text-sm font-medium text-gray-600">Case Type</label>
                <p className="text-base text-gray-900 capitalize">
                  {caseData.case_type?.replace(/_/g, ' ')}
                </p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-600">Description</label>
                <p className="text-base text-gray-900">{caseData.description}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-600">Court Reference</label>
                <p className="text-base text-gray-900">{caseData.court_reference}</p>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-600">Conditions</label>
                <p className="text-base text-gray-900">{caseData.conditions}</p>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-600">Start Date</label>
                  <div className="flex items-center gap-2 text-base text-gray-900">
                    <Calendar size={16} className="text-gray-400" />
                    {caseData.start_date}
                  </div>
                </div>
                {caseData.end_date && (
                  <div>
                    <label className="text-sm font-medium text-gray-600">End Date</label>
                    <div className="flex items-center gap-2 text-base text-gray-900">
                      <Calendar size={16} className="text-gray-400" />
                      {caseData.end_date}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Interventions */}
          <div className="card">
            <div className="flex items-center gap-2 mb-4">
              <Target className="text-primary-600" size={20} />
              <h2 className="text-xl font-semibold text-gray-900">Interventions</h2>
            </div>
            {caseData.interventions && caseData.interventions.length > 0 ? (
              <div className="space-y-4">
                {caseData.interventions.map((intervention) => (
                  <div key={intervention.id} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex items-start justify-between mb-2">
                      <h3 className="font-medium text-gray-900 capitalize">
                        {intervention.intervention_type?.replace(/_/g, ' ')}
                      </h3>
                      <span className={`badge ${
                        intervention.status === 'in_progress' ? 'badge-success' :
                        intervention.status === 'completed' ? 'badge-info' :
                        'badge-warning'
                      }`}>
                        {intervention.status}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 mb-2">{intervention.description}</p>
                    {intervention.attendance_rate && (
                      <p className="text-sm text-gray-500">
                        Attendance: {intervention.attendance_rate}%
                      </p>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500">No interventions recorded</p>
            )}
          </div>

          {/* Case Notes */}
          <div className="card">
            <div className="flex items-center gap-2 mb-4">
              <MessageSquare className="text-primary-600" size={20} />
              <h2 className="text-xl font-semibold text-gray-900">Case Notes</h2>
            </div>
            {caseData.case_notes && caseData.case_notes.length > 0 ? (
              <div className="space-y-4">
                {caseData.case_notes.map((note) => (
                  <div key={note.id} className="border-l-4 border-primary-500 pl-4 py-2">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-xs font-medium text-gray-500 uppercase">
                        {note.note_type}
                      </span>
                      <span className="text-xs text-gray-400">•</span>
                      <span className="text-xs text-gray-500">
                        {note.created_at_formatted}
                      </span>
                    </div>
                    <p className="text-sm text-gray-700">{note.content}</p>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500">No case notes available</p>
            )}
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Youth Information */}
          <div className="card">
            <div className="flex items-center gap-2 mb-4">
              <User className="text-primary-600" size={20} />
              <h2 className="text-lg font-semibold text-gray-900">Youth Information</h2>
            </div>
            {caseData.youth && (
              <div className="space-y-3">
                <div>
                  <label className="text-sm font-medium text-gray-600">Name</label>
                  <p className="text-base text-gray-900">{caseData.youth.full_name}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-600">Age</label>
                  <p className="text-base text-gray-900">{caseData.youth.age} years</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-600">Gender</label>
                  <p className="text-base text-gray-900">{caseData.youth.gender}</p>
                </div>
                <Link
                  to={`/youth/${caseData.youth.id}`}
                  className="inline-flex items-center gap-1 text-primary-600 hover:text-primary-800 text-sm font-medium"
                >
                  View Full Profile
                </Link>
              </div>
            )}
          </div>

          {/* Case Manager */}
          <div className="card">
            <div className="flex items-center gap-2 mb-4">
              <User className="text-primary-600" size={20} />
              <h2 className="text-lg font-semibold text-gray-900">Case Manager</h2>
            </div>
            {caseData.case_manager && (
              <div className="space-y-3">
                <div>
                  <label className="text-sm font-medium text-gray-600">Name</label>
                  <p className="text-base text-gray-900">{caseData.case_manager.full_name}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-600">Email</label>
                  <p className="text-base text-gray-900">{caseData.case_manager.email}</p>
                </div>
                {caseData.case_manager.phone && (
                  <div>
                    <label className="text-sm font-medium text-gray-600">Phone</label>
                    <p className="text-base text-gray-900">{caseData.case_manager.phone}</p>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default CaseDetail

