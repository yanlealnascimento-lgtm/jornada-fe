import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { Download, Calendar, TrendingUp, Users, BookOpen, Flame } from 'lucide-react';

const dataGrowth = [
  { month: 'Jan', membros: 45 },
  { month: 'Fev', membros: 52 },
  { month: 'Mar', membros: 68 },
  { month: 'Abr', membros: 85 },
  { month: 'Mai', membros: 110 },
  { month: 'Jun', membros: 150 },
];

const dataEngagement = [
  { day: 'Seg', aulas: 45 },
  { day: 'Ter', aulas: 58 },
  { day: 'Qua', aulas: 62 },
  { day: 'Qui', aulas: 54 },
  { day: 'Sex', aulas: 48 },
  { day: 'Sáb', aulas: 85 },
  { day: 'Dom', aulas: 95 },
];

export function Reports() {
  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-16">
      <div className="flex items-center justify-between">
         <div>
           <h2 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100 font-mono italic">Relatórios</h2>
           <p className="text-muted-foreground mt-1">Análise profunda de crescimento e engajamento da palavra.</p>
         </div>
         <div className="flex gap-3">
            <Button variant="outline" className="h-10 px-4 flex items-center gap-2 border-slate-200">
               <Calendar className="w-4 h-4 text-slate-400" /> Últimos 30 dias
            </Button>
            <Button className="h-10 px-4 flex items-center gap-2 shadow-lg shadow-primary/20">
               <Download className="w-4 h-4" /> Exportar Dados (PDF/XL)
            </Button>
         </div>
      </div>

      <div className="grid gap-6 md:grid-cols-4">
         {[
           { label: 'Retenção Mental', value: '78%', icon: <TrendingUp className="text-emerald-500" /> },
           { label: 'Média de Lições', value: '4.2', icon: <BookOpen className="text-blue-500" /> },
           { label: 'Conversão de Convites', value: '12%', icon: <Users className="text-indigo-500" /> },
           { label: 'Consistência (Streak)', value: '14d', icon: <Flame className="text-orange-500" /> },
         ].map((stat, i) => (
            <Card key={i} className="border-slate-100 shadow-sm border-2">
               <CardContent className="pt-6">
                  <div className="flex justify-between items-start">
                     <div className="p-2 bg-slate-50 rounded-xl">{stat.icon}</div>
                     <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest leading-none">Status</span>
                  </div>
                  <div className="mt-4">
                     <p className="text-3xl font-black tracking-tighter text-slate-900">{stat.value}</p>
                     <p className="text-xs text-muted-foreground font-medium mt-1 uppercase">{stat.label}</p>
                  </div>
               </CardContent>
            </Card>
         ))}
      </div>

      <div className="grid gap-8 md:grid-cols-2">
         <Card className="shadow-lg border-2 border-slate-100 overflow-hidden">
            <CardHeader className="bg-slate-50/50 border-b border-slate-50">
               <CardTitle className="text-xl">Crescimento da Congregação</CardTitle>
               <CardDescription>Fluxo de novos membros no aplicativo institucional.</CardDescription>
            </CardHeader>
            <CardContent className="pt-8">
               <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={dataGrowth}>
                      <defs>
                        <linearGradient id="colorMembros" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#4A90E2" stopOpacity={0.8}/>
                          <stop offset="95%" stopColor="#4A90E2" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                      <XAxis dataKey="month" axisLine={false} tickLine={false} />
                      <YAxis axisLine={false} tickLine={false} />
                      <Tooltip />
                      <Area type="monotone" dataKey="membros" stroke="#4A90E2" fillOpacity={1} fill="url(#colorMembros)" />
                    </AreaChart>
                  </ResponsiveContainer>
               </div>
            </CardContent>
         </Card>

         <Card className="shadow-lg border-2 border-slate-100 overflow-hidden">
            <CardHeader className="bg-slate-50/50 border-b border-slate-50">
               <CardTitle className="text-xl">Aulas Concluídas</CardTitle>
               <CardDescription>Frequência diária de estudo bíblico dos discípulos.</CardDescription>
            </CardHeader>
            <CardContent className="pt-8">
               <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={dataEngagement}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                      <XAxis dataKey="day" axisLine={false} tickLine={false} />
                      <YAxis axisLine={false} tickLine={false} />
                      <Tooltip />
                      <Bar dataKey="aulas" fill="#1C64F2" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
               </div>
            </CardContent>
         </Card>
      </div>

      <Card className="border-primary/20 bg-primary/5 p-6 border-dashed">
         <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="space-y-2 text-center md:text-left">
               <h3 className="text-xl font-bold text-primary italic underline underline-offset-4">Insight da Semana</h3>
               <p className="text-slate-700 max-w-lg leading-relaxed">
                  Observamos que o grupo **Base Kids** teve um aumento de 35% no engajamento matinal. Sugerimos parabenizar este grupo no painel de líderes para manter a constância.
               </p>
            </div>
            <Button className="h-12 px-8 shadow-xl shadow-primary/30">Enviar Mensagem ao Líder</Button>
         </div>
      </Card>
    </div>
  );
}
