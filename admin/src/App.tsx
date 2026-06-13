import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AppLayout } from './components/AppLayout';
import { AdminDashboard as Dashboard } from './pages/Dashboard';
import { TrailsList } from './pages/Trails';
import { CharactersList } from './pages/Characters';
import { AchievementsList } from './pages/Achievements';
import { LeaguesList } from './pages/Leagues';
import { CompaniesList } from './pages/Companies';
import { UsersList } from './pages/Users';
// Missions removed — merged into Achievements
import { StudiesList } from './pages/Studies';
import { TrailDetail } from './pages/TrailDetail';
import { Login } from './pages/Login';
import { Toaster } from 'sonner';

const AuthGuard = ({ children }: { children: React.ReactNode }) => {
  const token = localStorage.getItem('__jf_admin_token');
  const userStr = localStorage.getItem('__jf_admin_user');
  
  if (!token || !userStr) {
    return <Navigate to="/login" replace />;
  }
  
  try {
    const user = JSON.parse(userStr);
    if (user.role !== 'admin') {
      localStorage.removeItem('__jf_admin_token');
      localStorage.removeItem('__jf_admin_user');
      return <Navigate to="/login" replace />;
    }
  } catch (e) {
    return <Navigate to="/login" replace />;
  }
  
  return <>{children}</>;
};

function App() {
  return (
    <BrowserRouter>
      <Toaster position="top-right" richColors closeButton />
      <Routes>
        <Route path="/login" element={<Login />} />
        
        <Route path="/" element={
          <AuthGuard>
            <AppLayout />
          </AuthGuard>
        }>
          <Route index element={<Dashboard />} />
          <Route path="trails" element={<TrailsList />} />
          <Route path="trails/:trailId" element={<TrailDetail />} />
          <Route path="characters" element={<CharactersList />} />
          <Route path="achievements" element={<AchievementsList />} />
          <Route path="leagues" element={<LeaguesList />} />
          <Route path="companies" element={<CompaniesList />} />
          <Route path="users" element={<UsersList />} />
          {/* Missions removed — merged into Achievements */}
          <Route path="studies" element={<StudiesList />} />
        </Route>

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
