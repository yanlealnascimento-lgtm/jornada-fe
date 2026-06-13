import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Badge } from '../components/ui/badge';
import { Search, UserCog, Loader2, ShieldAlert, User, Landmark } from 'lucide-react';
import { toast } from 'sonner';
import api from '../services/api';

interface SystemUser {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'company_admin' | 'user';
  company_name: string;
  is_active: boolean;
}

export function UsersList() {
  const [users, setUsers] = useState<SystemUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const resp: any = await api.get('/users');
      setUsers(resp.data || []);
    } catch (err) {
      toast.error('Erro ao listar usuários do sistema.');
    } finally {
      setLoading(false);
    }
  };

  const filtered = users.filter(u => 
    u.name.toLowerCase().includes(search.toLowerCase()) || 
    u.email.toLowerCase().includes(search.toLowerCase())
  );

  const getRoleBadge = (role: string) => {
    switch (role) {
      case 'admin': return <Badge className="bg-blue-600 font-black italic rounded-lg tracking-tighter"><ShieldAlert size={12} className="mr-1" /> MASTER</Badge>;
      case 'company_admin': return <Badge className="bg-indigo-600 font-black italic rounded-lg tracking-tighter"><Landmark size={12} className="mr-1" /> LÍDER</Badge>;
      default: return <Badge variant="secondary" className="font-bold opacity-60 rounded-lg tracking-tighter"><User size={12} className="mr-1" /> ALUNO</Badge>;
    }
  };

  return (
    <div className="p-8 space-y-8 animate-in fade-in duration-700 bg-white min-h-full">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-4xl font-black italic tracking-tighter text-slate-800 uppercase">Gestão de Identidade</h2>
          <p className="text-slate-500 font-medium">Controle de acesso global e auditoria de privilégios.</p>
        </div>
        <div className="flex gap-4">
           <div className="relative w-72">
             <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
             <Input 
               placeholder="Buscar usuários..." 
               value={search}
               onChange={e => setSearch(e.target.value)}
               className="pl-10 h-12 border-slate-200 rounded-2xl shadow-sm focus:ring-blue-600"
             />
           </div>
        </div>
      </div>

      <Card className="rounded-3xl shadow-2xl border-slate-100 overflow-hidden bg-white">
        <CardHeader className="bg-slate-50 border-b border-slate-100 p-8">
           <CardTitle className="text-xl font-black italic text-slate-700">Audit Registry</CardTitle>
           <CardDescription>Visualização em tempo real de permissões e estados de contas.</CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
             <div className="p-32 flex flex-col items-center gap-4">
                <Loader2 className="w-10 h-10 animate-spin text-blue-600 opacity-20" />
                <p className="text-xs font-black uppercase tracking-[0.3em] text-slate-400">Loading Access Control List...</p>
             </div>
          ) : (
            <Table>
              <TableHeader className="bg-slate-50/50">
                <TableRow className="border-b border-slate-100 h-14">
                  <TableHead className="px-8 uppercase text-[10px] font-black tracking-widest text-slate-400">Identidade</TableHead>
                  <TableHead className="uppercase text-[10px] font-black tracking-widest text-slate-400">Privilégio</TableHead>
                  <TableHead className="uppercase text-[10px] font-black tracking-widest text-slate-400">Instituição / Grupo</TableHead>
                  <TableHead className="text-right px-8 uppercase text-[10px] font-black tracking-widest text-slate-400">Gerenciar</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.map(user => (
                  <TableRow key={user.id} className="group hover:bg-slate-50/50 transition-all border-b border-slate-50 h-20">
                    <TableCell className="px-8">
                       <div className="flex items-center gap-4">
                          <div className="w-10 h-10 rounded-2xl bg-slate-100 border border-slate-200 flex items-center justify-center font-black text-slate-400 group-hover:bg-blue-600 group-hover:text-white group-hover:border-blue-500 transition-all">
                             {user.name.charAt(0)}
                          </div>
                          <div>
                             <p className="text-sm font-black text-slate-800 tracking-tight leading-none mb-1">{user.name}</p>
                             <p className="text-[11px] font-medium text-slate-400 lowercase">{user.email}</p>
                          </div>
                       </div>
                    </TableCell>
                    <TableCell>
                       {getRoleBadge(user.role)}
                    </TableCell>
                    <TableCell>
                       <div className="flex items-center gap-2">
                          <Landmark size={14} className="text-slate-300" />
                          <span className="text-xs font-bold text-slate-600 italic underline underline-offset-4 decoration-slate-200">{user.company_name}</span>
                       </div>
                    </TableCell>
                    <TableCell className="text-right px-8">
                       <Button variant="ghost" size="icon" className="group-hover:bg-white shadow-sm rounded-xl">
                          <UserCog size={18} className="text-slate-400 group-hover:text-blue-600 transition-colors" />
                       </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
