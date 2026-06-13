import axios from 'axios';

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:4000/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('__jf_admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => {
    // Mapeamento automático de _id para id para compatibilidade com DND e Shadcn
    const mapId = (obj: any) => {
      if (obj && typeof obj === 'object') {
        if (obj._id && !obj.id) obj.id = obj._id;
      }
      return obj;
    };

    if (Array.isArray(response.data?.data)) {
      response.data.data = response.data.data.map(mapId);
    } else if (response.data?.data) {
      mapId(response.data.data);
    } else if (Array.isArray(response.data)) {
      response.data = response.data.map(mapId);
    }

    return response.data;
  },
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('__jf_admin_token');
      localStorage.removeItem('__jf_admin_user');
      window.location.href = '/login';
    }
    
    // Tratamento unificado de erro para componentes
    const backendError = error.response?.data;
    const message = backendError?.message || error.message || "Erro de conexão";
    
    return Promise.reject({
      message,
      status: error.response?.status,
      code: backendError?.code || error.code,
      data: backendError
    });
  }
);

export default api;
