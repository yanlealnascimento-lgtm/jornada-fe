import { create } from 'zustand';
import api from '../services/api';

interface CompanyAdminUser {
  id: string;
  email: string;
  name: string;
  company_id: string;
  company_name?: string;
  role: 'company_admin';
}

interface AuthState {
  user: CompanyAdminUser | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  updateUser: (data: Partial<CompanyAdminUser>) => void;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: JSON.parse(localStorage.getItem('company_user') || 'null'),
  token: localStorage.getItem('company_token'),
  
  login: async (email, password) => {
    try {
      const resp: any = await api.post('/auth/login', { email, password });
      const { token, user } = resp.data;
      
      // Buscar nome da empresa
      const setResp: any = await api.get('/companies/b2b/settings', {
        headers: { Authorization: `Bearer ${token}` }
      });
      user.company_name = setResp.data.name;

      localStorage.setItem('company_token', token);
      localStorage.setItem('company_user', JSON.stringify(user));
      
      set({ token, user });
    } catch (error) {
      throw error;
    }
  },

  updateUser: (data) => {
    const current = get().user;
    if (current) {
      const updated = { ...current, ...data };
      localStorage.setItem('company_user', JSON.stringify(updated));
      set({ user: updated });
    }
  },

  logout: () => {
    localStorage.removeItem('company_token');
    localStorage.removeItem('company_user');
    set({ user: null, token: null });
    window.location.href = '/login';
  }
}));
