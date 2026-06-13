import { create } from 'zustand';
import axios from 'axios';

interface AdminUser {
  id: string;
  email: string;
  name: string;
  role: 'admin';
}

interface AuthState {
  admin: AdminUser | null;
  token: string | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  checkAuth: () => void;
}

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api/v1';

export const useAuthStore = create<AuthState>((set) => ({
  admin: JSON.parse(localStorage.getItem('__jf_admin_user') || 'null'),
  token: localStorage.getItem('__jf_admin_token'),
  isLoading: false,

  login: async (email, password) => {
    set({ isLoading: true });
    try {
      const resp = await axios.post(`${API_URL}/auth/login`, { email, password });
      const { token, user } = resp.data.data;

      if (user.role !== 'admin') {
        throw new Error('Acesso restrito a administradores.');
      }

      localStorage.setItem('__jf_admin_token', token);
      localStorage.setItem('__jf_admin_user', JSON.stringify(user));

      set({ token, admin: user });
    } catch (err: any) {
      throw new Error(err.response?.data?.message || err.message || 'Erro ao realizar login.');
    } finally {
      set({ isLoading: false });
    }
  },

  logout: () => {
    localStorage.removeItem('__jf_admin_token');
    localStorage.removeItem('__jf_admin_user');
    set({ admin: null, token: null });
    window.location.href = '/login';
  },

  checkAuth: () => {
    const token = localStorage.getItem('__jf_admin_token');
    const user = JSON.parse(localStorage.getItem('__jf_admin_user') || 'null');
    if (token && user) {
      set({ token, admin: user });
    }
  }
}));
