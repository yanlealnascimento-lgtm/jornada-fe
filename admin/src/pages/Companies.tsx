import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../services/api';
import { Plus, Edit2, RotateCcw, Link as LinkIcon, Lock, Unlock, Building2 } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../components/ui/dialog';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { StatusBadge } from '../components/StatusBadge';
import { EmptyState } from '../components/EmptyState';
import { SeedDataButton } from '../components/SeedDataButton';
import { SEED_COMPANIES } from '../data/seed-data';
import { toast } from 'sonner';
import { ConfirmDialog } from '../components/ConfirmDialog';

// ======== SCHEMA ======== //
const companySchema = z.object({
  name: z.string().min(3, "Nome da instituição obrigatório"),
  type: z.enum(['church','school','ngo','business']),
  cnpj: z.string().optional(),
  address: z.object({
    city: z.string().min(2, "Cidade obrigatória"),
    state: z.string().min(2, "UF obrigatória"),
    country: z.string().default("BR")
  }),
  responsible: z.object({
    name: z.string().min(3, "Nome do responsável"),
    email: z.string().email("E-mail inválido"),
    role: z.string().min(2, "Cargo do responsável")
  }),
  plan: z.enum(['free','basic','professional','enterprise']),
  members_limit: z.preprocess((val) => Number(val), z.number().min(5)),
  primary_color: z.string().regex(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, "Hex inválido"),
  allow_public_join: z.boolean().default(false),
  invite_code: z.string().min(5, "Ao menos 5 caracteres"),
  is_active: z.boolean().default(true)
});

type CompanyFormValues = z.infer<typeof companySchema>;
type Company = CompanyFormValues & { 
  id: string; 
  _count?: { users: number }; 
};

export function CompaniesList() {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [filterPlan, setFilterPlan] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingCompany, setEditingCompany] = useState<Company | null>(null);
  const [toggleWarningId, setToggleWarningId] = useState<string | null>(null);

  const { data: fetchResult, isLoading } = useQuery({
    queryKey: ['companies'],
    queryFn: () => api.get('/companies').then(r => typeof r.data === 'object' ? (r.data.data ? r.data : {data: r.data}) : {data: r}).catch(() => ({ data: [] }))
  });
  
  const companies: Company[] = fetchResult?.data || [];

  const filtered = companies.filter(c => {
    const matchesSearch = c.name.toLowerCase().includes(searchTerm.toLowerCase()) || c.cnpj?.includes(searchTerm);
    const matchesType = filterType === 'all' || c.type === filterType;
    const matchesPlan = filterPlan === 'all' || c.plan === filterPlan;
    const matchesStatus = filterStatus === 'all' || (filterStatus === 'active' && c.is_active) || (filterStatus === 'inactive' && !c.is_active);
    return matchesSearch && matchesType && matchesPlan && matchesStatus;
  });

  const generateInviteCode = () => {
    const el = document.querySelector('input[name="address.city"]') as HTMLInputElement;
    const prefix = el?.value?.substring(0, 3).toUpperCase() || "COD";
    const rnd = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `${prefix}${rnd}`;
  };

  const createMutation = useMutation({
    mutationFn: (data: CompanyFormValues) => api.post('/companies', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      setIsFormOpen(false);
      toast.success("✅ Instituição criada com sucesso!");
    },
    onError: (e: any) => toast.error(`Erro: ${e.response?.data?.message || e.message}`)
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string, data: CompanyFormValues }) => api.put(`/companies/${id}`, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      setIsFormOpen(false);
      
      const currentMembers = editingCompany?._count?.users || 0;
      if (variables.data.members_limit < currentMembers) {
        toast.warning(
          `Limites reduzidos! O plano foi alterado, mas existem ${currentMembers} usuários. Novos cadastros serão bloqueados na API.`,
          { duration: 8000 }
        );
      } else {
        toast.success("✅ Alterações salvas");
      }
    },
    onError: (e: any) => toast.error(`Erro: ${e.response?.data?.message || e.message}`)
  });

  const toggleStatusMutation = useMutation({
    mutationFn: (id: string) => {
      const c = companies.find(x => x.id === id);
      return api.patch(`/companies/${id}`, { is_active: !c?.is_active });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      setToggleWarningId(null);
      toast.success("Status atualizado");
    }
  });

  const form = useForm<CompanyFormValues>({
    resolver: zodResolver(companySchema),
    defaultValues: { 
      type: 'church', plan: 'basic', members_limit: 100, is_active: true, allow_public_join: false, 
      primary_color: '#3498DB', address: { country: 'BR', city: '', state: '' },
      invite_code: generateInviteCode()
    }
  });

  const openNew = () => {
    setEditingCompany(null);
    form.reset({
      type: 'church', plan: 'basic', members_limit: 100, is_active: true, allow_public_join: false,
      primary_color: '#3498DB', address: { country: 'BR', city: '', state: '' },
      invite_code: generateInviteCode(),
      name: '', responsible: { name: '', role: '', email: '' }
    });
    setIsFormOpen(true);
  };

  const openEdit = (comp: Company) => {
    setEditingCompany(comp);
    form.reset(comp);
    setIsFormOpen(true);
  };

  const onSubmit = (data: CompanyFormValues) => {
    if (editingCompany) updateMutation.mutate({ id: editingCompany.id, data });
    else createMutation.mutate(data);
  };

  const handleCopyLink = (code: string) => {
    const url = `${window.location.origin}/join/${code}`;
    navigator.clipboard.writeText(url);
    toast.success("Link de convite copiado!");
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Instituições (B2B)</h2>
          <p className="text-muted-foreground">Gerencie igrejas, ONGs e escolas usando o app corporativo.</p>
        </div>
        <div className="flex gap-2">
          {companies.length === 0 && !isLoading && (
            <SeedDataButton data={SEED_COMPANIES} endpoint="/companies" queryKey={['companies']} />
          )}
          <Button onClick={openNew}><Plus className="w-4 h-4 mr-2" /> Nova Instituição</Button>
        </div>
      </div>

      <div className="flex gap-4 items-center flex-wrap">
        <Input placeholder="Buscar por nome ou CNPJ..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} className="w-64" />
        <select className="border rounded-md px-3 py-2 text-sm max-w-xs" value={filterType} onChange={e => setFilterType(e.target.value)}>
          <option value="all">Tipo: Todos</option>
          <option value="church">Igreja</option>
          <option value="school">Escola</option>
          <option value="ngo">ONG / Missão</option>
          <option value="business">Empresa</option>
        </select>
        <select className="border rounded-md px-3 py-2 text-sm max-w-xs" value={filterPlan} onChange={e => setFilterPlan(e.target.value)}>
          <option value="all">Plano: Todos</option>
          <option value="free">Free</option>
          <option value="basic">Basics</option>
          <option value="professional">Professional</option>
          <option value="enterprise">Enterprise</option>
        </select>
        <select className="border rounded-md px-3 py-2 text-sm max-w-xs" value={filterStatus} onChange={e => setFilterStatus(e.target.value)}>
          <option value="all">Status: Todos</option>
          <option value="active">Apenas Ativas</option>
          <option value="inactive">Apenas Inativas/Bloqueadas</option>
        </select>
      </div>

      {isLoading ? (
        <div>Carregando...</div>
      ) : companies.length === 0 ? (
        <EmptyState icon={Building2} title="Nenhuma instituição cadastrada" description="Traga igrejas e comunidades para o aplicativo." actionText="Nova Instituição" onAction={openNew} />
      ) : (
        <div className="border rounded-md overflow-x-auto">
          <Table className="min-w-[1000px]">
            <TableHeader>
              <TableRow>
                <TableHead className="w-12">Cor</TableHead>
                <TableHead>Nome e CNPJ</TableHead>
                <TableHead>Tipo</TableHead>
                <TableHead>Plano</TableHead>
                <TableHead>Membros</TableHead>
                <TableHead>Responsável</TableHead>
                <TableHead>Local</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Ações</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map(comp => (
                <TableRow key={comp.id}>
                  <TableCell>
                    <div className="w-6 h-6 rounded-md shadow-sm" style={{ backgroundColor: comp.primary_color }}></div>
                  </TableCell>
                  <TableCell>
                    <div className="font-bold">{comp.name}</div>
                    {comp.cnpj && <div className="text-xs text-muted-foreground font-mono">{comp.cnpj}</div>}
                  </TableCell>
                  <TableCell className="capitalize">{comp.type}</TableCell>
                  <TableCell>
                    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium uppercase border bg-gray-100 text-gray-800">
                      {comp.plan}
                    </span>
                  </TableCell>
                  <TableCell>
                    <span className="font-semibold">{comp._count?.users || 0}</span> / {comp.members_limit === 999999 ? '∞' : comp.members_limit}
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">{comp.responsible?.name}</div>
                    <div className="text-xs text-muted-foreground">{comp.responsible?.role}</div>
                  </TableCell>
                  <TableCell className="text-sm">{comp.address?.city} - {comp.address?.state}</TableCell>
                  <TableCell>
                    <StatusBadge status={comp.is_active ? "active" : "inactive"} />
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-1">
                      <Button variant="ghost" size="icon" title="Copiar Link de Convite" onClick={() => handleCopyLink(comp.invite_code)}>
                        <LinkIcon className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" title="Editar" onClick={() => openEdit(comp)}>
                        <Edit2 className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" title={comp.is_active ? "Bloquear Acesso" : "Desbloquear Acesso"}
                        className={comp.is_active ? "text-destructive" : "text-green-600"}
                        onClick={() => setToggleWarningId(comp.id)}>
                        {comp.is_active ? <Lock className="h-4 w-4" /> : <Unlock className="h-4 w-4" />}
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      {/* FORM */}
      <Dialog open={isFormOpen} onOpenChange={setIsFormOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingCompany ? 'Editar Instituição (B2B)' : 'Nova Instituição (B2B)'}</DialogTitle>
          </DialogHeader>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6 pt-4">
            <div className="grid grid-cols-2 gap-6">
              <div className="space-y-4">
                <h4 className="font-semibold border-b pb-2 text-sm text-muted-foreground uppercase">Dados da Instituição</h4>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Nome Completo *</label>
                  <Input {...form.register("name")} />
                  {form.formState.errors.name && <span className="text-xs text-red-500">{form.formState.errors.name.message}</span>}
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium">CNPJ</label>
                    <Input {...form.register("cnpj")} placeholder="Apenas números" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Tipo *</label>
                    <select {...form.register("type")} className="flex h-10 w-full rounded-md border text-sm px-2">
                      <option value="church">Igreja</option>
                      <option value="school">Escola</option>
                      <option value="ngo">ONG</option>
                      <option value="business">Empresa</option>
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-2">
                  <div className="space-y-2 col-span-2">
                    <label className="text-sm font-medium">Cidade *</label>
                    <Input {...form.register("address.city")} />
                  </div>
                  <div className="space-y-2 col-span-1">
                    <label className="text-sm font-medium">UF *</label>
                    <Input {...form.register("address.state")} maxLength={2} className="uppercase" />
                  </div>
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium">Cor da Marca (Customização Frontend) *</label>
                  <div className="flex gap-2">
                    <input type="color" {...form.register("primary_color")} className="h-10 w-10 p-1 border rounded" />
                    <Input {...form.register("primary_color")} className="uppercase" />
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <h4 className="font-semibold border-b pb-2 text-sm text-muted-foreground uppercase">Contato & Gerenciamento</h4>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Responsável Legal *</label>
                  <Input {...form.register("responsible.name")} placeholder="Nome" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Cargo/Função *</label>
                    <Input {...form.register("responsible.role")} placeholder="Pastor, Diretor, etc" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium">E-mail *</label>
                    <Input type="email" {...form.register("responsible.email")} />
                  </div>
                </div>

                <div className="mt-6 border-t pt-4">
                  <h4 className="font-semibold text-sm text-indigo-600 dark:text-indigo-400 uppercase mb-4">Plano Admin Override</h4>
                  <div className="grid grid-cols-2 gap-4 bg-muted/30 p-4 rounded-md border">
                    <div className="space-y-2">
                      <label className="text-sm font-medium">Atribuir Plano *</label>
                      <select {...form.register("plan")} className="flex h-10 w-full rounded-md border text-sm px-2 bg-background font-mono">
                        <option value="free">Free</option>
                        <option value="basic">Basic</option>
                        <option value="professional">Professional</option>
                        <option value="enterprise">Enterprise</option>
                      </select>
                    </div>
                    <div className="space-y-2">
                      <label className="text-sm font-medium text-amber-600">Max. Membros *</label>
                      <Input type="number" {...form.register("members_limit")} className="font-mono bg-background" />
                    </div>
                  </div>
                </div>

                <div className="mt-4 border p-4 rounded-md space-y-4">
                  <div className="flex items-center gap-2 mb-2">
                    <label className="text-sm font-medium flex-1">Código de Convite (Envie aos Alunos/Membros)</label>
                  </div>
                  <div className="flex gap-2 items-center">
                    <Input {...form.register("invite_code")} className="font-mono font-bold text-center uppercase tracking-widest text-lg" readOnly />
                    <Button type="button" variant="outline" size="icon" onClick={() => form.setValue("invite_code", generateInviteCode())}>
                      <RotateCcw className="w-4 h-4" />
                    </Button>
                  </div>
                  <label className="flex items-center gap-2 bg-amber-50 p-2 rounded text-amber-900 border border-amber-200">
                    <input type="checkbox" {...form.register("allow_public_join")} />
                    <span className="text-sm font-medium">Permitir entrada pública com este código aberto</span>
                  </label>
                </div>
              </div>
            </div>

            <div className="flex justify-between pt-4 border-t items-center mt-6">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...form.register("is_active")} />
                <span className="text-lg font-bold text-green-600">Instituição Ativa</span>
                <span className="text-sm text-muted-foreground ml-2">(Pode logar no admin)</span>
              </label>
              
              <div className="flex justify-end pt-4">
                <Button type="button" variant="outline" className="mr-2" onClick={() => setIsFormOpen(false)}>Cancelar</Button>
                <Button type="submit" disabled={createMutation.isPending || updateMutation.isPending}>
                  {createMutation.isPending || updateMutation.isPending ? "Salvando..." : "Salvar Configuração"}
                </Button>
              </div>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      <ConfirmDialog 
        isOpen={!!toggleWarningId} 
        onOpenChange={(v) => !v && setToggleWarningId(null)} 
        title="Alterar Acesso da Instituição" 
        description="Bloquear o acesso impedirá que o líder administrativo, bem como membros entrem no namespace desta instituição. Confirma a ação?"
        variant="destructive"
        onConfirm={() => toggleWarningId && toggleStatusMutation.mutate(toggleWarningId)} 
        isLoading={toggleStatusMutation.isPending}
      />
    </div>
  );
}
