import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Briefcase,
  Users,
  Target,
  TrendingUp,
  AlertCircle,
  CheckCircle,
  Clock
} from 'lucide-react'
import { api } from '../api/client'

const Dashboard = () => {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchStats()
  }, [])

  const fetchStats = async () => {
    try {
      const response = await api.getDashboardStats()
      setStats(response.data)
    } catch (error) {
      console.error('Error fetching dashboard stats:', error)
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

  const statCards = [
    {
      title: 'Total Cases',
      value: stats?.total_cases || 0,
      icon: Briefcase,
      color: 'bg-blue-500',
      link: '/cases'
    },
    {
      title: 'Active Cases',
      value: stats?.active_cases || 0,
      icon: AlertCircle,
      color: 'bg-green-500',
      link: '/cases'
    },
    {
      title: 'Total Youth',
      value: stats?.total_youth || 0,
      icon: Users,
      color: 'bg-purple-500',
      link: '/youth'
    },
    {
      title: 'Active Interventions',
      value: stats?.active_interventions || 0,
      icon: Target,
      color: 'bg-orange-500',
      link: '/interventions'
    }
  ]

  return (
    <div className="space-y-6">
      {/* Welcome Section */}
      <div className="card">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          Welcome to QLD Youth Justice System
        </h1>
        <p className="text-gray-600">
          Manage cases, track interventions, and support youth rehabilitation programs.
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statCards.map((stat, index) => {
          const Icon = stat.icon
          return (
            <Link
              key={index}
              to={stat.link}
              className="card hover:shadow-lg transition-shadow duration-200 cursor-pointer"
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600 mb-1">
                    {stat.title}
                  </p>
                  <p className="text-3xl font-bold text-gray-900">{stat.value}</p>
                </div>
                <div className={`${stat.color} p-4 rounded-lg`}>
                  <Icon className="text-white" size={24} />
                </div>
              </div>
            </Link>
          )
        })}
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Cases by Status */}
        <div className="card">
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp className="text-primary-600" size={20} />
            <h3 className="text-lg font-semibold text-gray-900">Cases by Status</h3>
          </div>
          <div className="space-y-3">
            {stats?.cases_by_status &&
              Object.entries(stats.cases_by_status).map(([status, count]) => (
                <div key={status} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    {status === 'active' && <CheckCircle size={16} className="text-green-500" />}
                    {status === 'pending' && <Clock size={16} className="text-yellow-500" />}
                    {status === 'closed' && <CheckCircle size={16} className="text-gray-500" />}
                    <span className="text-sm font-medium text-gray-700 capitalize">
                      {status.replace('_', ' ')}
                    </span>
                  </div>
                  <span className="text-sm font-bold text-gray-900">{count}</span>
                </div>
              ))}
          </div>
        </div>

        {/* Interventions by Type */}
        <div className="card">
          <div className="flex items-center gap-2 mb-4">
            <Target className="text-primary-600" size={20} />
            <h3 className="text-lg font-semibold text-gray-900">
              Interventions by Type
            </h3>
          </div>
          <div className="space-y-3">
            {stats?.interventions_by_type &&
              Object.entries(stats.interventions_by_type).map(([type, count]) => (
                <div key={type} className="flex items-center justify-between">
                  <span className="text-sm font-medium text-gray-700 capitalize">
                    {type.replace(/_/g, ' ')}
                  </span>
                  <span className="text-sm font-bold text-gray-900">{count}</span>
                </div>
              ))}
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Link
            to="/cases"
            className="btn btn-primary flex items-center justify-center gap-2"
          >
            <Briefcase size={18} />
            View All Cases
          </Link>
          <Link
            to="/youth"
            className="btn btn-secondary flex items-center justify-center gap-2"
          >
            <Users size={18} />
            Manage Youth
          </Link>
          <Link
            to="/interventions"
            className="btn btn-secondary flex items-center justify-center gap-2"
          >
            <Target size={18} />
            Track Interventions
          </Link>
        </div>
      </div>
    </div>
  )
}

export default Dashboard

