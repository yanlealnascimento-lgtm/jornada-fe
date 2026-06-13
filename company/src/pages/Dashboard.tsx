import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Users, Flame, BookOpen, UserMinus, Trophy, ArrowUpRight, Plus } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useNavigate } from 'react-router-dom';

const dataActivity = [
  { day: 'Seg', ativos: 120, licoes: 450 },
  { day: 'Ter', ativos: 135, licoes: 512 },
  { day: 'Qua', ativos: 142, licoes: 600 },
  { day: 'Qui', ativos: 130, licoes: 480 },
  { day: 'Sex', ativos: 110, licoes: 390 },
  { day: 'Sáb', ativos: 155, licoes: 800 },
  { day: 'Dom', ativos: 168, licoes: 920 },
];

export const CompanyDashboard: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-16">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
         <div>
           <h2 className="text-3xl font-black italic tracking-tighter text-slate-900 dark:text-slate-100 uppercase">Dashboard</h2>
           <p className="text-muted-foreground mt-1 font-medium">Bem-vindo(a) ao centro de comando da sua comunidade.</p>
         </div>
         <Button onClick={() => navigate('/members')} className="h-11 px-6 flex items-center gap-2 shadow-xl shadow-primary/20 bg-primary hover:bg-primary/90 font-bold rounded-full w-full sm:w-auto">
            <Plus className="w-5 h-5" /> Convidar Membros
         </Button>
      </div>
      
      <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { label: 'Membros Totais', value: '150', sub: '+5 este mês', icon: <Users className="h-5 w-5" />, color: 'blue' },
          { label: 'Ativos Hoje', value: '23', sub: '15% engajados', icon: <Flame className="h-5 w-5" />, color: 'emerald' },
          { label: 'Streak Médio', value: '12.3', sub: 'Recorde: 45 dias', icon: <Flame className="h-5 w-5 fill-amber-500" />, color: 'amber' },
          { label: 'Lições na Semana', value: '892', sub: '6 por membro ativo', icon: <BookOpen className="h-5 w-5" />, color: 'indigo' },
        ].map((stat, i) => (
          <Card key={i} className={`border-l-4 border-l-${stat.color}-500 shadow-xl rounded-2xl overflow-hidden transition-transform hover:scale-[1.02]`}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-xs font-black uppercase tracking-widest text-slate-400">{stat.label}</CardTitle>
              <div className={`p-2 bg-${stat.color}-50 text-${stat.color}-500 rounded-xl`}>{stat.icon}</div>
            </CardHeader>
            <CardContent>
              <div className="text-4xl font-black italic text-slate-800 tracking-tighter">{stat.value}</div>
              <p className="text-[10px] text-muted-foreground font-bold mt-1 uppercase tracking-tighter opacity-60">{stat.sub}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-8 lg:grid-cols-7">
        <Card className="lg:col-span-4 shadow-2xl border-slate-100 rounded-3xl overflow-hidden bg-white">
          <CardHeader className="bg-slate-50/50 border-b border-slate-100 py-6">
            <div className="flex justify-between items-center">
              <div>
                <CardTitle className="text-xl font-black italic">Engajamento Semanal</CardTitle>
                <p className="text-xs text-muted-foreground font-medium mt-1">Volume de lições concluídas por dia.</p>
              </div>
              <Button variant="ghost" size="sm" className="text-primary font-bold">Ver Tudo <ArrowUpRight className="w-3 h-3 ml-1" /></Button>
            </div>
          </CardHeader>
          <CardContent className="pt-10 pl-2">
             <div className="h-[320px] w-full px-4">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={dataActivity}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                    <XAxis dataKey="day" axisLine={false} tickLine={false} className="text-xs font-bold text-slate-400" />
                    <YAxis axisLine={false} tickLine={false} className="text-xs font-bold text-slate-400" />
                    <Tooltip cursor={{fill: '#f8fafc'}} contentStyle={{ borderRadius: '16px', border: 'none', boxShadow: '0 20px 25px -5px rgb(0 0 0 / 0.1)' }} />
                    <Bar dataKey="licoes" fill="#4B90E2" radius={[6, 6, 0, 0]} barSize={32} />
                  </BarChart>
                </ResponsiveContainer>
             </div>
          </CardContent>
        </Card>
        
        <Card className="lg:col-span-3 shadow-2xl border-slate-100 rounded-3xl overflow-hidden bg-white">
          <CardHeader className="pb-4 border-b border-slate-100 bg-slate-50/50 py-6">
            <CardTitle className="flex items-center gap-2 text-xl font-black italic text-secondary">
               <Trophy className="w-6 h-6" /> Top Discípulos
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-slate-100">
              {[
                { name: 'Maria Oliveira', xp: 450, lvl: 18, c: 'bg-yellow-400' },
                { name: 'João Silva', xp: 420, lvl: 16, c: 'bg-slate-300' },
                { name: 'Pastor Renato', xp: 390, lvl: 15, c: 'bg-amber-600' },
                { name: 'Ana Beatriz', xp: 360, lvl: 14, c: 'bg-primary' },
                { name: 'Lucas Santos', xp: 330, lvl: 12, c: 'bg-primary/80' }
              ].map((m, i) => (
                <div key={i} className="flex items-center p-5 hover:bg-slate-50 transition-colors cursor-pointer group">
                  <div className={`w-10 h-10 rounded-2xl flex items-center justify-center font-black text-white mr-5 shadow-sm transform group-hover:scale-110 transition-transform ${m.c}`}>
                     {i+1}
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-black text-slate-800 uppercase tracking-tight">{m.name}</p>
                    <p className="text-[10px] text-muted-foreground font-black uppercase tracking-widest mt-0.5">Nível {m.lvl}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-black text-lg text-secondary tracking-tighter italic">{m.xp} XP</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="lg:col-span-7 border-destructive/20 shadow-xl bg-red-50/20 rounded-3xl p-2 border-dashed">
           <CardHeader className="pb-2">
              <CardTitle className="flex items-center gap-3 text-destructive text-lg font-black italic">
                 <div className="p-2 bg-red-100 rounded-xl"><UserMinus className="w-5 h-5" /></div> 
                 Membros em Alerta (Período de Inatividade)
              </CardTitle>
           </CardHeader>
           <CardContent>
              <p className="text-sm text-slate-600 mb-6 font-medium">Estes membros possuem histórico recorrente, mas não registram atividade hoje. Uma mensagem de encorajamento pode ajudar.</p>
              <div className="flex flex-wrap gap-3">
                 {['Matheus L.', 'Sara V.', 'Eunice C.', 'Lucas T.'].map((n, idx) => (
                    <div key={idx} className="bg-white border-2 border-slate-100 shadow-md px-5 py-2.5 rounded-full text-xs font-black flex items-center gap-3 transform hover:-translate-y-1 transition-transform cursor-pointer">
                       <div className="w-5 h-5 bg-slate-100 rounded-full flex items-center justify-center text-[10px]">{n[0]}</div>
                       {n} <span className="text-orange-500 flex items-center bg-orange-50 px-2 py-0.5 rounded-lg"><Flame className="w-3.5 h-3.5 mr-1 fill-orange-500" /> 14</span>
                    </div>
                 ))}
              </div>
           </CardContent>
        </Card>
      </div>
    </div>
  );
};
