import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/auth.store';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { ShieldCheck, Loader2, Eye, EyeOff, Lock } from 'lucide-react';
import { toast } from 'sonner';
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api/v1';

export function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isSeeding, setIsSeeding] = useState(false);
  
  const { login, isLoading } = useAuthStore();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await login(email, password);
      toast.success('Acesso Master autorizado!');
      navigate('/dashboard');
    } catch (err: any) {
      toast.error(err.message || 'Credenciais inválidas.');
    }
  };

  const seedMaster = async () => {
    setIsSeeding(true);
    try {
      const masterUser = {
        name: 'Isaias Silva (QA Master)',
        email: 'qa.eng.isaiasilva@gmail.com',
        username: 'isaias_master',
        password: 'Is@i@s1989',
        role: 'admin'
      };

      // Usando X-User-Id bypass temporário via auth.middleware fix que eu fiz
      await axios.post(`${API_URL}/seed-all`, {
        endpoint: '/users',
        data: [masterUser]
      }, {
        headers: { 'X-User-Id': 'dev-admin-001' }
      });

      toast.success('Mestre QA criado no sistema!');
      setEmail(masterUser.email);
      setPassword(masterUser.password);
    } catch (err) {
      toast.error('Erro ao realizar o seed do Master.');
    } finally {
      setIsSeeding(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 p-6 font-mono overflow-hidden relative">
      <div className="absolute top-0 right-0 p-80 bg-blue-600/10 rounded-full blur-[120px] -mr-40 -mt-40 shadow-inner" />
      <div className="absolute bottom-0 left-0 p-80 bg-indigo-600/10 rounded-full blur-[120px] -ml-40 -mb-40 shadow-inner" />

      <Card className="w-full max-w-[420px] border-slate-800 bg-slate-900/50 backdrop-blur-xl shadow-2xl relative border-2 rounded-3xl overflow-hidden animate-in fade-in zoom-in duration-500">
        <div className="h-2 bg-gradient-to-r from-blue-600 to-indigo-600" />
        <CardHeader className="text-center space-y-2 pb-8 pt-10">
          <div className="mx-auto w-16 h-16 bg-blue-600/20 rounded-2xl flex items-center justify-center mb-4 border border-blue-500/30">
            <ShieldCheck className="w-8 h-8 text-blue-500" />
          </div>
          <CardTitle className="text-3xl font-black text-white italic tracking-tighter">MASTER ACCESS</CardTitle>
          <CardDescription className="text-slate-400 font-medium">Painel Administrativo JourneyFaith</CardDescription>
        </CardHeader>
        <CardContent className="px-10 pb-10">
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <Label className="text-[10px] font-black uppercase tracking-widest text-slate-500">Credenciais</Label>
              <Input
                type="email"
                placeholder="email@master.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="bg-slate-950/50 border-slate-800 text-slate-100 h-12 rounded-2xl focus:ring-blue-500"
                required
              />
            </div>
            <div className="space-y-2 relative">
              <Input
                type={showPassword ? "text" : "password"}
                placeholder="********"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="bg-slate-950/50 border-slate-800 text-slate-100 h-12 rounded-2xl focus:ring-blue-500 pr-10"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-[10px] text-slate-500 hover:text-blue-500"
              >
                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
            
            <Button className="w-full h-12 rounded-2xl bg-blue-600 hover:bg-blue-500 text-white font-black italic text-lg shadow-xl shadow-blue-900/20" disabled={isLoading}>
              {isLoading ? <Loader2 className="animate-spin" /> : "AUTHENTICATE"}
            </Button>
          </form>

          <div className="mt-10 pt-8 border-t border-slate-800 text-center">
             <p className="text-[10px] text-slate-600 uppercase font-black tracking-[0.2em] mb-4">First time access?</p>
             <Button 
                variant="ghost" 
                onClick={seedMaster} 
                disabled={isSeeding}
                className="text-blue-500 hover:text-blue-400 hover:bg-blue-500/10 text-xs font-bold gap-2 rounded-xl"
             >
                {isSeeding ? <Loader2 className="w-4 h-4 animate-spin" /> : <Lock className="w-4 h-4" />}
                INITIALIZE MASTER USER
             </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
