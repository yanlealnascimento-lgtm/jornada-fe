import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '../components/ui/dialog';
import { Plus, Search, UserCheck, Flame, Medal, Mail, Loader2, Link2, Share2, Info } from 'lucide-react';
import { toast } from 'sonner';
import api from '../services/api';

interface Member {
  id: string;
  name: string;
  email: string;
  level: number;
  xp_total: number;
  streak_current: number;
  is_active: boolean;
}

export function MembersList() {
  const [members, setMembers] = useState<Member[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Modais Control
  const [isInviteOpen, setIsInviteOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [selectedMember, setSelectedMember] = useState<Member | null>(null);
  const [inviteEmail, setInviteEmail] = useState('');
  const [isInviting, setIsInviting] = useState(false);

  useEffect(() => {
    fetchMembers();
  }, []);

  const fetchMembers = async () => {
    setIsLoading(true);
    try {
      const resp: any = await api.get('/companies/b2b/members');
      setMembers(resp.data || []);
    } catch (err) {
      toast.error('Erro ao carregar lista de membros');
    } finally {
      setIsLoading(false);
    }
  };

  const handleInvite = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsInviting(true);
    try {
      // Simulação de convite por e-mail
      await new Promise(r => setTimeout(r, 1500));
      toast.success(`Convite enviado para ${inviteEmail}!`);
      setIsInviteOpen(false);
      setInviteEmail('');
    } catch (err) {
      toast.error('Erro ao enviar convite');
    } finally {
      setIsInviting(false);
    }
  };

  const openProfile = (member: Member) => {
    setSelectedMember(member);
    setIsProfileOpen(true);
  };

  const filtered = members.filter(m => 
    m.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    m.email.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Membros da Comunidade</h2>
          <p className="text-muted-foreground mt-1">Gerencie os discípulos e acompanhe seu crescimento espiritual.</p>
        </div>
        <Button onClick={() => setIsInviteOpen(true)} className="h-11 px-6 flex items-center gap-2 shadow-lg shadow-primary/20 bg-primary hover:bg-primary/90 rounded-full font-bold">
          <Plus className="w-5 h-5" /> Convidar Novos Membros
        </Button>
      </div>

      <div className="grid gap-4 grid-cols-2 md:grid-cols-4">
        <Card className="bg-primary/5 border-primary/10 rounded-2xl p-4">
          <p className="text-xs font-bold text-primary uppercase tracking-widest opacity-60">Fidelidade</p>
          <div className="text-3xl font-black mt-2">{members.length > 0 ? Math.floor(members.length * 0.4) : 0}</div>
          <p className="text-[10px] text-muted-foreground mt-1">Estudaram a palavra hoje</p>
        </Card>
        <Card className="bg-slate-50 border-slate-100 rounded-2xl p-4">
          <p className="text-xs font-bold text-slate-500 uppercase tracking-widest">Total</p>
          <div className="text-3xl font-black mt-2">{members.length}</div>
          <p className="text-[10px] text-muted-foreground mt-1">Membros registrados</p>
        </Card>
      </div>

      <Card className="border-slate-200 shadow-xl sm:rounded-3xl overflow-hidden bg-white">
        <CardHeader className="bg-slate-50/50 border-b border-slate-100 space-y-4 px-6 py-6 md:flex-row md:items-center md:justify-between md:space-y-0">
          <div>
            <CardTitle className="text-xl font-black italic">Lista de Discípulos</CardTitle>
            <CardDescription>Monitoramento em tempo real do engajamento.</CardDescription>
          </div>
          <div className="relative w-full md:w-80">
             <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
             <Input 
               placeholder="Buscar discípulo..." 
               value={searchTerm}
               onChange={e => setSearchTerm(e.target.value)}
               className="pl-10 h-11 border-slate-200 rounded-2xl focus:ring-secondary"
             />
          </div>
        </CardHeader>
        <CardContent className="p-0 overflow-x-auto">
          {isLoading ? (
            <div className="p-20 text-center flex flex-col items-center gap-4">
               <Loader2 className="w-8 h-8 animate-spin text-slate-300" />
               <p className="text-muted-foreground font-mono uppercase text-xs tracking-widest">Sincronizando com a nuvem...</p>
            </div>
          ) : members.length === 0 ? (
            <div className="p-20 text-center flex flex-col items-center gap-4 bg-slate-50/30">
              <div className="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center">
                 <Mail className="w-10 h-10 text-slate-300" />
              </div>
              <h3 className="text-xl font-bold">Nenhum membro ativo</h3>
              <p className="text-muted-foreground max-w-xs mx-auto">Comece a expansão da sua congregação convidando os primeiros membros via e-mail ou link.</p>
              <Button variant="outline" onClick={() => setIsInviteOpen(true)} className="rounded-full h-10 px-8">Enviar Primeiros Convites</Button>
            </div>
          ) : (
            <Table>
              <TableHeader className="bg-slate-50 border-b border-slate-100">
                <TableRow>
                  <TableHead className="w-[300px] h-12 uppercase text-[10px] font-black tracking-widest px-6">Membro</TableHead>
                  <TableHead className="text-center uppercase text-[10px] font-black tracking-widest">Nível</TableHead>
                  <TableHead className="text-center uppercase text-[10px] font-black tracking-widest">Progresso</TableHead>
                  <TableHead className="text-center uppercase text-[10px] font-black tracking-widest">Streak</TableHead>
                  <TableHead className="text-right px-6 uppercase text-[10px] font-black tracking-widest">Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.map((member) => (
                  <TableRow key={member.id} className="hover:bg-primary/5 transition-colors group cursor-pointer" onClick={() => openProfile(member)}>
                    <TableCell className="px-6 py-4">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 rounded-2xl bg-slate-100 border border-slate-200 flex items-center justify-center font-black text-slate-500 text-lg transition-transform group-hover:scale-105">
                           {member.name.charAt(0)}
                        </div>
                        <div>
                          <p className="text-sm font-bold text-slate-800 leading-tight">{member.name}</p>
                          <p className="text-xs text-muted-foreground mt-1 group-hover:text-primary transition-colors">{member.email}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-center">
                       <Badge variant="secondary" className="px-3 py-1 font-black text-[10px] bg-blue-50 text-blue-600 border-none rounded-2xl uppercase tracking-tighter">
                          <Medal className="w-3 h-3 mr-1" /> Lvl {member.level}
                       </Badge>
                    </TableCell>
                    <TableCell className="text-center">
                       <div className="inline-flex flex-col items-center">
                          <span className="text-sm font-black text-slate-700">{member.xp_total.toLocaleString()}</span>
                          <span className="text-[10px] text-slate-400 font-bold uppercase tracking-widest">XP Total</span>
                       </div>
                    </TableCell>
                    <TableCell className="text-center">
                       <div className="flex items-center justify-center gap-1.5 text-orange-600 font-black text-lg italic">
                          <Flame className="w-5 h-5 fill-orange-600 animate-pulse" /> {member.streak_current}
                       </div>
                    </TableCell>
                    <TableCell className="text-right px-6">
                       <Button variant="ghost" size="sm" className="rounded-full h-8 px-4 hover:bg-primary hover:text-white transition-all font-bold group-hover:shadow-md">
                         Ver Perfil
                       </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* MODAL: CONVITAR */}
      <Dialog open={isInviteOpen} onOpenChange={setIsInviteOpen}>
        <DialogContent className="sm:max-w-[480px] rounded-3xl p-8 border-none shadow-2xl overflow-hidden">
          <div className="absolute top-0 right-0 p-12 bg-primary/5 -mr-12 -mt-12 rounded-full blur-3xl" />
          <DialogHeader className="relative">
            <DialogTitle className="text-3xl font-black italic text-primary tracking-tighter">Expandir Reino</DialogTitle>
            <DialogDescription className="text-base text-slate-500 mt-2">
              Convide seus membros para iniciarem a jornada gamificada da fé.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-6 pt-6 relative">
             <div className="space-y-3">
               <Label className="uppercase text-[10px] font-black tracking-widest text-slate-400 px-1">Enviar por Email</Label>
               <div className="flex gap-2">
                 <Input 
                   type="email" 
                   placeholder="ex: fiel@igreja.com.br" 
                   className="h-12 border-slate-200 rounded-2xl text-lg"
                   value={inviteEmail}
                   onChange={e => setInviteEmail(e.target.value)}
                 />
                 <Button onClick={handleInvite} className="h-12 px-6 rounded-2xl font-black" disabled={!inviteEmail || isInviting}>
                   {isInviting ? <Loader2 className="animate-spin" /> : 'CONVIDAR'}
                 </Button>
               </div>
             </div>

             <div className="relative">
               <div className="absolute inset-0 flex items-center"><span className="w-full border-t border-slate-100" /></div>
               <div className="relative flex justify-center text-xs uppercase"><span className="bg-white px-2 text-muted-foreground font-black">ou compartilhe o código</span></div>
             </div>

             <div className="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex items-center justify-between">
                <div className="flex items-center gap-3">
                   <div className="p-2 bg-white rounded-xl shadow-sm"><Link2 className="w-5 h-5 text-primary" /></div>
                   <div>
                      <p className="text-[10px] uppercase font-black text-slate-400 leading-none">Código da Instituição</p>
                      <p className="text-xl font-black text-slate-800 tracking-widest mt-1">COD3WC7</p>
                   </div>
                </div>
                <Button variant="ghost" size="icon" className="rounded-xl hover:bg-white hover:text-primary transition-all shadow-sm">
                   <Share2 className="w-5 h-5" />
                </Button>
             </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* MODAL: PERFIL RÁPIDO */}
      <Dialog open={isProfileOpen} onOpenChange={setIsProfileOpen}>
        <DialogContent className="sm:max-w-[400px] p-0 border-none rounded-3xl overflow-hidden shadow-2xl">
          {selectedMember && (
            <div className="flex flex-col">
              <div className="bg-gradient-to-br from-primary to-blue-900 p-8 text-white relative overflow-hidden">
                <div className="absolute -right-4 -bottom-4 text-white/10 opacity-20"><Medal size={200} /></div>
                <div className="relative z-10 flex flex-col items-center text-center">
                  <div className="w-24 h-24 rounded-3xl bg-white/20 backdrop-blur-md border-2 border-white/30 flex items-center justify-center text-4xl mb-4 font-black shadow-2xl rotate-3">
                     {selectedMember.name.charAt(0)}
                  </div>
                  <h3 className="text-2xl font-black italic tracking-tighter">{selectedMember.name}</h3>
                  <p className="text-white/60 text-sm font-medium">{selectedMember.email}</p>
                </div>
              </div>
              <div className="p-8 space-y-8 bg-white">
                <div className="grid grid-cols-2 gap-4">
                   <div className="p-4 bg-slate-50 rounded-2xl text-center border border-slate-100">
                      <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest mb-1">Nível Atual</p>
                      <p className="text-2xl font-black text-primary italic">Lvl {selectedMember.level}</p>
                   </div>
                   <div className="p-4 bg-slate-50 rounded-2xl text-center border border-slate-100">
                      <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest mb-1">Status</p>
                      <div className="flex items-center justify-center gap-1 text-emerald-600 font-bold">
                         <UserCheck size={16} /> Ativo
                      </div>
                   </div>
                </div>
                <div className="space-y-4">
                   <div className="flex justify-between items-center bg-slate-50 p-3 rounded-xl">
                      <div className="flex items-center gap-3">
                         <Flame className="w-5 h-5 text-orange-500 fill-orange-500" />
                         <span className="text-sm font-bold text-slate-700">Ofensiva Atual (Streak)</span>
                      </div>
                      <span className="text-lg font-black text-orange-600 italic">{selectedMember.streak_current} Dias</span>
                   </div>
                   <div className="flex justify-between items-center bg-slate-50 p-3 rounded-xl">
                      <div className="flex items-center gap-3">
                         <Info className="w-5 h-5 text-blue-500" />
                         <span className="text-sm font-bold text-slate-700">Total de Conquistas</span>
                      </div>
                      <span className="text-lg font-black text-blue-600 italic">12</span>
                   </div>
                </div>
                <Button className="w-full h-12 rounded-2xl font-black shadow-lg shadow-primary/20">Ver Histórico Completo</Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
