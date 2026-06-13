import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Database, Loader2, Church, LogIn, Eye, EyeOff } from 'lucide-react';
import { toast } from 'sonner';
import { useAuthStore } from '../store/auth.store';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';

export function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isSeeding, setIsSeeding] = useState(false);
  
  const login = useAuthStore(s => s.login);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      await login(email, password);
      toast.success('Bem-vindo ao Painel B2B!');
      navigate('/dashboard');
    } catch (err: any) {
      toast.error(err.message || 'Falha no login');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSeedIBBI = async () => {
    setIsSeeding(true);
    try {
      // Usar slug curto para busca flexível via Regex no backend
      await api.post('/companies/b2b/seed', { slug: 'Israel' });
      toast.success('Semente plantada! Use o e-mail cadastrado no Admin.');
      setEmail('ibbisede@gmail.com');
      setPassword('123456');
    } catch (err: any) {
      toast.error('Erro no seed: ' + err.message);
    } finally {
      setIsSeeding(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 dark:bg-slate-950 p-6">
      <div className="w-full max-w-md space-y-8 animate-in fade-in zoom-in-95 duration-500">
        <div className="text-center space-y-2">
          <div className="inline-flex p-3 bg-primary/10 rounded-2xl mb-4">
            <Church className="w-10 h-10 text-primary" />
          </div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">JourneyFaith B2B</h1>
          <p className="text-muted-foreground">Gestão de Comunidades e Discipulado</p>
        </div>

        <Card className="border-slate-200 shadow-xl overflow-hidden">
          <CardHeader className="bg-slate-50/50 border-b border-slate-100">
            <CardTitle className="text-xl">Login Institucional</CardTitle>
            <CardDescription>Acesse o painel com as credenciais do responsável.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6">
            <form onSubmit={handleLogin} className="space-y-4 text-left">
              <div className="space-y-2">
                <Label htmlFor="email">E-mail do Responsável</Label>
                <Input 
                   id="email" 
                   type="email" 
                   placeholder="pastor@igreja.com" 
                   value={email} 
                   onChange={e => setEmail(e.target.value)} 
                   required 
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="password">Senha</Label>
                <div className="relative">
                  <Input 
                    id="password" 
                    type={showPassword ? "text" : "password"} 
                    value={password} 
                    onChange={e => setPassword(e.target.value)} 
                    required 
                    className="pr-10"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>
              <Button type="submit" className="w-full h-11" disabled={isLoading}>
                {isLoading ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <LogIn className="w-4 h-4 mr-2" />}
                Entrar no Painel
              </Button>
            </form>

            <div className="mt-8 pt-6 border-t border-slate-100">
              <div className="flex flex-col gap-3">
                 <p className="text-[10px] text-center font-bold text-slate-400 uppercase tracking-widest">Acesso de Desenvolvedor (Modo Teste)</p>
                 <Button 
                   variant="secondary" 
                   onClick={handleSeedIBBI} 
                   disabled={isSeeding}
                   className="w-full text-xs"
                 >
                   {isSeeding ? <Loader2 className="w-3 h-3 animate-spin mr-2" /> : <Database className="w-3 h-3 mr-2 text-primary" />}
                   Popular Dados da "Igreja Israel" (Seed B2B)
                 </Button>
                 <p className="text-[10px] text-center text-muted-foreground">Isso criará o Pastor Borges, membros e grupos de estudo para testes.</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
