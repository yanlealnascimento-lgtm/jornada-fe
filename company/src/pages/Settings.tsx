import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Badge } from '../components/ui/badge';
import { Church, ShieldCheck, Mail, Palette, Save, Loader2, Link2 } from 'lucide-react';
import { toast } from 'sonner';
import { useAuthStore } from '../store/auth.store';
import api from '../services/api';

export function Settings() {
  const [settings, setSettings] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const updateUser = useAuthStore(s => s.updateUser);

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    try {
      const resp: any = await api.get('/companies/b2b/settings');
      setSettings(resp.data);
    } catch (err) {
      toast.error('Erro ao carregar configurações');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    try {
      // Simular save ou implementar no backend se necessário
      // await api.put('/companies/b2b/settings', settings);
      toast.success('Configurações salvas!');
      updateUser({ company_name: settings.name });
    } catch (err) {
      toast.error('Erro ao salvar');
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) return <div className="p-12 text-center text-muted-foreground italic">Carregando perfil institucional...</div>;

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div className="flex items-center justify-between">
         <div>
           <h2 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100 italic">Configurações</h2>
           <p className="text-muted-foreground mt-1 text-base">Gerencie a identidade e o plano da sua instituição.</p>
         </div>
      </div>

      <div className="grid gap-8 md:grid-cols-3">
         <div className="col-span-2 space-y-6">
            <Card className="border-slate-200 shadow-sm sm:rounded-2xl overflow-hidden">
               <CardHeader className="bg-slate-50/50 border-b border-slate-100 flex-row items-center gap-4 py-8">
                  <div className="w-20 h-20 rounded-3xl bg-white border shadow-md flex items-center justify-center text-4xl overflow-hidden">
                     {settings.logo_url ? <img src={settings.logo_url} alt="Logo" className="w-full h-full object-cover" /> : <Church className="w-10 h-10 text-primary" />}
                  </div>
                  <div className="space-y-1">
                     <CardTitle className="text-2xl font-bold">{settings.name}</CardTitle>
                     <CardDescription className="flex items-center gap-2">
                        <Badge variant="outline" className="text-xs uppercase font-bold tracking-widest">{settings.type}</Badge>
                        <span className="text-xs text-muted-foreground font-mono">{settings.cnpj || 'Sem CNPJ informado'}</span>
                     </CardDescription>
                  </div>
               </CardHeader>
               <CardContent className="pt-8 p-8">
                  <form onSubmit={handleSave} className="space-y-8">
                     <div className="grid gap-6 md:grid-cols-2">
                        <div className="space-y-2">
                           <Label htmlFor="inst-name">Nome de Exibição</Label>
                           <Input 
                              id="inst-name" 
                              value={settings.name} 
                              onChange={e => setSettings({...settings, name: e.target.value})}
                              className="h-11 px-4 border-slate-200" 
                           />
                        </div>
                        <div className="space-y-2">
                           <Label htmlFor="brand-color">Cor da Marca (Principal)</Label>
                           <div className="flex gap-2">
                              <Input 
                                 id="brand-color" 
                                 type="color" 
                                 value={settings.primary_color || '#4A90E2'}
                                 onChange={e => setSettings({...settings, primary_color: e.target.value})}
                                 className="w-12 h-11 p-1 rounded-lg border-slate-200"
                              />
                              <Input 
                                 value={settings.primary_color || '#4A90E2'} 
                                 className="h-11 flex-1 font-mono uppercase border-slate-200"
                                 onChange={e => setSettings({...settings, primary_color: e.target.value})}
                              />
                           </div>
                        </div>
                     </div>

                     <div className="space-y-2">
                        <Label>Endereço da Sede</Label>
                        <Input 
                           value={`${settings.address?.street || ''}, ${settings.address?.number || ''} - ${settings.address?.city} / ${settings.address?.state}`}
                           disabled
                           className="bg-slate-50 h-11 border-dashed cursor-not-allowed"
                        />
                        <p className="text-[10px] text-muted-foreground italic">*Alterações de endereço devem ser solicitadas ao suporte JourneyFaith.</p>
                     </div>

                     <div className="pt-4 border-t border-slate-100 flex justify-end">
                        <Button type="submit" className="h-11 px-8 gap-2 shadow-lg hover:shadow-primary/20 transition-all font-bold" disabled={isSaving}>
                           {isSaving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                           Salvar Alterações
                        </Button>
                     </div>
                  </form>
               </CardContent>
            </Card>

            <Card className="border-slate-200 shadow-sm opacity-60 grayscale bg-slate-50">
               <CardHeader>
                  <CardTitle className="text-lg flex items-center gap-2">
                     <Link2 className="w-5 h-5 text-slate-400" /> Domínio Customizado
                  </CardTitle>
                  <CardDescription>Acesse seu painel através de um subdomínio próprio (ex: paz.journeyfaith.com.br).</CardDescription>
               </CardHeader>
               <CardContent>
                  <Button variant="outline" size="sm" disabled>Indisponível no plano {settings.plan}</Button>
               </CardContent>
            </Card>
         </div>

         <div className="space-y-6">
            <Card className="border-primary/20 bg-primary/5 shadow-none border-dashed p-2">
               <CardHeader className="pb-2">
                  <div className="flex items-center justify-between mb-2">
                     <Badge variant="secondary" className="bg-primary/20 text-primary border-none text-[10px] font-bold tracking-widest uppercase py-0.5">Assinatura</Badge>
                     <ShieldCheck className="w-5 h-5 text-primary" />
                  </div>
                  <CardTitle className="text-2xl font-black capitalize tracking-tight text-primary">{settings.plan}</CardTitle>
               </CardHeader>
               <CardContent className="space-y-4">
                  <div className="space-y-2">
                     <div className="flex justify-between text-sm">
                        <span className="text-slate-600 font-medium">Uso de Membros</span>
                        <span className="font-bold text-primary">0 / {settings.members_limit}</span>
                     </div>
                     <div className="h-2 bg-slate-200 rounded-full overflow-hidden">
                        <div className="h-full bg-primary w-[2%]" />
                     </div>
                  </div>
                  <p className="text-xs text-slate-500 leading-relaxed italic">Seu plano permite gerenciar até 400 discípulos. Para upgrades, acesse o painel financeiro.</p>
               </CardContent>
               <CardFooter>
                  <Button variant="link" className="text-primary p-0 h-auto font-bold underline underline-offset-4">Gerenciar Minha Assinatura</Button>
               </CardFooter>
            </Card>

            <Card className="shadow-sm border-slate-200">
               <CardHeader className="pb-3 border-b border-slate-100 bg-slate-50/50">
                  <CardTitle className="text-base">Contato de Suporte</CardTitle>
               </CardHeader>
               <CardContent className="pt-6 space-y-4">
                  <div className="flex items-center gap-3">
                     <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500">
                        <Mail className="w-4 h-4" />
                     </div>
                     <div className="text-sm">
                        <p className="text-slate-400 font-medium text-[10px] uppercase">E-mail</p>
                        <p className="font-medium text-slate-700">{settings.responsible?.email}</p>
                     </div>
                  </div>
                  <div className="flex items-center gap-3">
                     <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500">
                        <Palette className="w-4 h-4" />
                     </div>
                     <div className="text-sm">
                        <p className="text-slate-400 font-medium text-[10px] uppercase">Responsável</p>
                        <p className="font-medium text-slate-700">{settings.responsible?.name}</p>
                     </div>
                  </div>
               </CardContent>
            </Card>
         </div>
      </div>
    </div>
  );
}
