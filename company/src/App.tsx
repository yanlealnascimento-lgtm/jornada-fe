import React from 'react';
import { AppLayout } from './components/AppLayout';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
// Removido store import

// Stubs
import { Login } from './pages/Login';
import { CompanyDashboard } from './pages/Dashboard';
import { MembersList } from './pages/Members';
import { GroupsList } from './pages/Groups';
import { Settings } from './pages/Settings';
import { Reports } from './pages/Reports';

const AuthGuard = ({ children }: { children: React.ReactNode }) => {
  const token = localStorage.getItem('company_token');
  if (!token) return <Navigate to="/login" replace />;
  return <>{children}</>; 
};

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        
        <Route path="/" element={<AuthGuard><AppLayout /></AuthGuard>}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<CompanyDashboard />} />
          <Route path="members" element={<MembersList />} />
          <Route path="groups" element={<GroupsList />} />
          <Route path="reports" element={<Reports />} />
          <Route path="settings" element={<Settings />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
