import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import CasesList from './pages/CasesList'
import CaseDetail from './pages/CaseDetail'
import YouthList from './pages/YouthList'
import YouthDetail from './pages/YouthDetail'
import CaseManagers from './pages/CaseManagers'
import Programs from './pages/Programs'
import Interventions from './pages/Interventions'

function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<Dashboard />} />
        <Route path="cases" element={<CasesList />} />
        <Route path="cases/:id" element={<CaseDetail />} />
        <Route path="youth" element={<YouthList />} />
        <Route path="youth/:id" element={<YouthDetail />} />
        <Route path="case-managers" element={<CaseManagers />} />
        <Route path="programs" element={<Programs />} />
        <Route path="interventions" element={<Interventions />} />
      </Route>
    </Routes>
  )
}

export default App

