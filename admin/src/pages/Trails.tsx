import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { trailsService, Trail, TrailStats } from '../services/trails.service';
import { api } from '../services/api';
import { Plus, Trash2, GripVertical, RefreshCw, Download, Pencil, BookOpen, MoreVertical, Eye, EyeOff } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '../components/ui/dropdown-menu';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../components/ui/dialog';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { DndContext, closestCenter, DragEndEvent } from '@dnd-kit/core';
import { arrayMove, SortableContext, useSortable, verticalListSortingStrategy } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { StatusBadge } from '../components/StatusBadge';
import { EmptyState } from '../components/EmptyState';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { toast } from 'sonner';

// ─── Types & Schema ──────────────────────────────────────────────────────────

const trailSchema = z.object({
  title: z.string().min(3, 'Mínimo de 3 caracteres').max(100),
  slug: z.string().min(1, 'Slug obrigatório'),
  description: z.string().min(10, 'Mínimo de 10 caracteres').max(500),
  thumbnail_url: z.string().url('URL inválida').optional().or(z.literal('')),
  character_id: z.string().optional(),
  order: z.preprocess((val) => Number(val), z.number().min(0)),
  is_core: z.boolean().default(true),
  denomination: z.string().optional(),
  unlock_level: z.preprocess((val) => Number(val), z.number().min(1).max(100)),
  estimated_hours: z.preprocess((val) => Number(val), z.number().min(0.5)),
  is_premium: z.boolean().default(false),
  is_published: z.boolean().default(false),
});
type TrailFormValues = z.infer<typeof trailSchema>;

const STAT_CARDS: { key: keyof TrailStats | 'characters'; label: string; icon: string; color: string }[] = [
  { key: 'total',        label: 'Total de Trilhas', icon: '📚', color: '#4A90E2' },
  { key: 'published',    label: 'Publicadas',       icon: '✅', color: '#27AE60' },
  { key: 'draft',        label: 'Rascunhos',        icon: '📝', color: '#95A5A6' },
  { key: 'free',         label: 'Gratuitas',        icon: '🆓', color: '#16A34A' },
  { key: 'premium',      label: 'Premium',          icon: '⭐', color: '#D4A017' },
  { key: 'core',         label: 'Núcleo Comum',     icon: '✝️', color: '#6366F1' },
  { key: 'denomination', label: 'Denominacionais',  icon: '🏛️', color: '#EC4899' },
];

// ─── Sortable Row ────────────────────────────────────────────────────────────

function SortableRow({ trail, onEdit, onDelete, onTogglePublish, onManage }: {
  trail: Trail;
  onEdit: (t: Trail) => void;
  onDelete: (id: string) => void;
  onTogglePublish: (id: string, published: boolean) => void;
  onManage: (id: string) => void;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: trail.id || trail._id });
  const style = { transform: CSS.Transform.toString(transform), transition, zIndex: isDragging ? 100 : 1, opacity: isDragging ? 0.8 : 1 };

  return (
    <TableRow ref={setNodeRef} style={style} className={isDragging ? 'bg-secondary' : ''}>
      <TableCell className="w-12 text-center">
        <div {...attributes} {...listeners} className="cursor-grab p-1 inline-block">
          <GripVertical className="h-4 w-4 text-muted-foreground" />
        </div>
      </TableCell>
      <TableCell className="w-16">
        {trail.thumbnail_url ? (
          <img src={trail.thumbnail_url} alt={trail.title} className="w-10 h-10 rounded object-cover" />
        ) : (
          <div className="w-10 h-10 rounded bg-muted flex items-center justify-center text-xs">📚</div>
        )}
      </TableCell>
      <TableCell>
        <div className="font-medium text-slate-800 max-w-xs truncate" title={trail.title}>{trail.title}</div>
        <div className="text-xs text-slate-400 font-mono">{trail.slug}</div>
      </TableCell>
      <TableCell>
        {trail.is_core ? (
          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-indigo-100 text-indigo-800 border border-indigo-200">Núcleo</span>
        ) : (
          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-pink-100 text-pink-800 border border-pink-200">{trail.denomination || 'Denominação'}</span>
        )}
      </TableCell>
      <TableCell className="text-center">Nvl {trail.unlock_level}</TableCell>
      <TableCell className="text-center">{trail.estimated_hours}h</TableCell>
      <TableCell className="text-center">{trail.total_units || 0}</TableCell>
      <TableCell className="text-center">{trail.total_lessons || 0}</TableCell>
      <TableCell><StatusBadge status={trail.is_published ? 'published' : 'draft'} /></TableCell>
      <TableCell>{trail.is_premium ? '⭐ Premium' : '🆓 Free'}</TableCell>
      <TableCell>
        <Button variant="outline" size="sm" className="gap-1.5 text-blue-600 border-blue-200 hover:bg-blue-50 hover:border-blue-300" onClick={() => onManage(trail.id || trail._id)}>
          <BookOpen className="h-3.5 w-3.5" /> Gerenciar
        </Button>
      </TableCell>
      <TableCell>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="h-8 w-8"><MoreVertical className="h-4 w-4" /></Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => onEdit(trail)}>
              <Pencil className="h-4 w-4 mr-2" /> Editar
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => onTogglePublish(trail.id || trail._id, !trail.is_published)}>
              {trail.is_published ? <><EyeOff className="h-4 w-4 mr-2" /> Despublicar</> : <><Eye className="h-4 w-4 mr-2" /> Publicar</>}
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem className="text-destructive focus:text-destructive" onClick={() => onDelete(trail.id || trail._id)}>
              <Trash2 className="h-4 w-4 mr-2" /> Excluir
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </TableCell>
    </TableRow>
  );
}

// ─── Main Component ──────────────────────────────────────────────────────────

export function TrailsList() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingTrail, setEditingTrail] = useState<Trail | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  // ─── Queries ─────────────────────────────────────────────────────────────
  const { data: listResult, isLoading } = useQuery({
    queryKey: ['trails'],
    queryFn: () => trailsService.list().then((res: any) => {
      const d = res.data || res;
      return d.trails ? d : { trails: Array.isArray(d) ? d : [], total: 0 };
    }),
  });

  const { data: statsResult } = useQuery({
    queryKey: ['trail-stats'],
    queryFn: () => trailsService.stats().then((res: any) => res.data || res),
  });

  const { data: charsResult } = useQuery({
    queryKey: ['characters'],
    queryFn: () => api.get('/characters').then((res: any) => res.data || res),
  });

  const stats: TrailStats = statsResult ?? { total: 0, published: 0, draft: 0, free: 0, premium: 0, core: 0, denomination: 0, by_denomination: {} };
  const characters = Array.isArray(charsResult) ? charsResult : [];
  const trails: Trail[] = useMemo(() => listResult?.trails || [], [listResult]);

  // DND sort state
  const [sortTrails, setSortTrails] = useState<Trail[]>([]);
  useEffect(() => { if (trails.length > 0) setSortTrails(trails); }, [trails]);

  const filteredTrails = sortTrails.filter(t => {
    const matchSearch = t.title.toLowerCase().includes(searchTerm.toLowerCase()) || t.slug.includes(searchTerm.toLowerCase());
    const matchType = filterType === 'all' || (filterType === 'core' && t.is_core) || (filterType === 'denom' && !t.is_core);
    return matchSearch && matchType;
  });

  // ─── Mutations ───────────────────────────────────────────────────────────
  const createMutation = useMutation({
    mutationFn: (data: TrailFormValues) => trailsService.create(data as any),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trails'] });
      queryClient.invalidateQueries({ queryKey: ['trail-stats'] });
      setIsFormOpen(false);
      toast.success('Trilha criada com sucesso');
    },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: TrailFormValues }) => trailsService.update(id, data as any),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trails'] });
      queryClient.invalidateQueries({ queryKey: ['trail-stats'] });
      setIsFormOpen(false);
      toast.success('Trilha atualizada com sucesso');
    },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => trailsService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trails'] });
      queryClient.invalidateQueries({ queryKey: ['trail-stats'] });
      setDeleteId(null);
      toast.success('Trilha removida');
    },
    onError: () => {
      toast.error('Não foi possível remover: existem lições/unidades vinculadas.');
      setDeleteId(null);
    },
  });

  const togglePublishMutation = useMutation({
    mutationFn: ({ id, is_published }: { id: string; is_published: boolean }) =>
      trailsService.update(id, { is_published } as any),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trails'] });
      queryClient.invalidateQueries({ queryKey: ['trail-stats'] });
    },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const reorderMutation = useMutation({
    mutationFn: (items: { id: string; order: number }[]) => trailsService.reorder(items),
    onSuccess: () => toast.success('Ordenação salva'),
    onError: (e: any) => toast.error(`Falha ao reordenar: ${e.message}`),
  });

  const seedMutation = useMutation({
    mutationFn: () => trailsService.seed(),
    onSuccess: (res: any) => {
      const d = res.data || res;
      toast.success(`Seed concluído: ${d.created ?? 0} criadas, ${d.updated ?? 0} atualizadas`);
      queryClient.invalidateQueries({ queryKey: ['trails'] });
      queryClient.invalidateQueries({ queryKey: ['trail-stats'] });
    },
    onError: (e: any) => toast.error(`Erro no seed: ${e.message}`),
  });

  // ─── Handlers ────────────────────────────────────────────────────────────
  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    if (over && active.id !== over.id) {
      const oldIndex = sortTrails.findIndex(t => (t.id || t._id) === active.id);
      const newIndex = sortTrails.findIndex(t => (t.id || t._id) === over.id);
      const newArray = arrayMove(sortTrails, oldIndex, newIndex);
      setSortTrails(newArray);
      const items = newArray.map((t, i) => ({ id: t.id || t._id, order: i + 1 }));
      reorderMutation.mutate(items);
    }
  };

  const form = useForm<TrailFormValues>({
    resolver: zodResolver(trailSchema),
    defaultValues: { is_core: true, is_premium: false, is_published: false, order: 0, unlock_level: 1, estimated_hours: 1 },
  });

  const openNew = () => {
    setEditingTrail(null);
    form.reset({ is_core: true, is_premium: false, is_published: false, order: trails.length + 1, unlock_level: 1, estimated_hours: 1, title: '', slug: '', description: '', thumbnail_url: '', character_id: '', denomination: '' });
    setIsFormOpen(true);
  };

  const openEdit = (trail: Trail) => {
    setEditingTrail(trail);
    const charId = typeof trail.character_id === 'object' && trail.character_id
      ? trail.character_id._id
      : (trail.character_id as string) || '';
    form.reset({ ...trail, character_id: charId, thumbnail_url: trail.thumbnail_url || '', denomination: trail.denomination || '' });
    setIsFormOpen(true);
  };

  const onSubmit = (data: TrailFormValues) => {
    if (editingTrail) updateMutation.mutate({ id: editingTrail.id || editingTrail._id, data });
    else createMutation.mutate(data);
  };

  const descLength = form.watch('description')?.length || 0;

  // ─── Render ──────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-800">Trilhas</h1>
          <p className="text-sm text-slate-500 mt-1">Gerencie as jornadas de aprendizado bíblico</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending}>
            <RefreshCw size={16} className={`mr-2 ${seedMutation.isPending ? 'animate-spin' : ''}`} />
            Seed Dados
          </Button>
          <Button onClick={openNew}><Plus size={16} className="mr-2" /> Nova Trilha</Button>
        </div>
      </div>

      {/* Stats Dashboard */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
        {STAT_CARDS.map((card) => (
          <div key={card.key} className="bg-white rounded-xl border border-slate-200 p-4 relative overflow-hidden">
            <div className="absolute top-0 left-0 right-0 h-1" style={{ backgroundColor: card.color }} />
            <div className="text-2xl mb-1">{card.icon}</div>
            <div className="text-xl font-black text-slate-800">
              {card.key === 'characters' ? characters.length : ((stats as any)[card.key] ?? 0)}
            </div>
            <div className="text-xs font-semibold text-slate-500 leading-tight">{card.label}</div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        <Input placeholder="Buscar por título ou slug..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} className="max-w-xs" />
        <div className="flex gap-2">
          {([['all', 'Todos'], ['core', 'Núcleo'], ['denom', 'Denominação']] as const).map(([key, label]) => (
            <button
              key={key}
              onClick={() => setFilterType(key)}
              className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${filterType === key ? 'bg-slate-800 text-white border-slate-800' : 'bg-white text-slate-600 border-slate-200 hover:border-slate-400'}`}
            >
              {label}
            </button>
          ))}
        </div>
        <span className="text-sm text-slate-400 ml-auto">{filteredTrails.length} trilha(s)</span>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {isLoading ? (
          <div className="text-center py-12 text-slate-400">Carregando...</div>
        ) : trails.length === 0 ? (
          <EmptyState
            icon={Download}
            title="Nenhuma trilha cadastrada"
            description='Crie sua primeira trilha ou clique em "Seed Dados" para carregar 20 trilhas de exemplo.'
            actionText="Nova Trilha"
            onAction={openNew}
          />
        ) : (
          <div className="overflow-x-auto">
            <DndContext collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
              <Table>
                <TableHeader>
                  <TableRow className="bg-slate-50">
                    <TableHead className="w-12">#</TableHead>
                    <TableHead>Thumb</TableHead>
                    <TableHead>Título + Slug</TableHead>
                    <TableHead>Tipo</TableHead>
                    <TableHead className="text-center">Nível</TableHead>
                    <TableHead className="text-center">Horas</TableHead>
                    <TableHead className="text-center">Unid.</TableHead>
                    <TableHead className="text-center">Lições</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Acesso</TableHead>
                    <TableHead>Gerenciar</TableHead>
                    <TableHead className="w-12">Ações</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  <SortableContext items={filteredTrails.map(t => t.id || t._id)} strategy={verticalListSortingStrategy}>
                    {filteredTrails.map(trail => (
                      <SortableRow
                        key={trail.id || trail._id}
                        trail={trail}
                        onEdit={openEdit}
                        onDelete={setDeleteId}
                        onTogglePublish={(id, published) => togglePublishMutation.mutate({ id, is_published: published })}
                        onManage={(id) => navigate(`/trails/${id}`)}
                      />
                    ))}
                  </SortableContext>
                </TableBody>
              </Table>
            </DndContext>
          </div>
        )}
      </div>

      {/* Form Dialog */}
      <Dialog open={isFormOpen} onOpenChange={setIsFormOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingTrail ? 'Editar Trilha' : 'Nova Trilha'}</DialogTitle>
          </DialogHeader>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 pt-4">
            {/* Seção 1: Informações Básicas */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Título *</label>
                <Input {...form.register('title')} onChange={e => {
                  const val = e.target.value;
                  form.setValue('title', val);
                  if (!editingTrail) {
                    const slug = val.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
                    form.setValue('slug', slug);
                  }
                }} />
                {form.formState.errors.title && <span className="text-xs text-red-500">{form.formState.errors.title.message}</span>}
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Slug *</label>
                <Input {...form.register('slug')} />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Descrição * <span className="text-slate-400 font-normal">({descLength}/500)</span></label>
              <textarea {...form.register('description')} maxLength={500} className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2" />
              {form.formState.errors.description && <span className="text-xs text-red-500">{form.formState.errors.description.message}</span>}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Thumbnail URL</label>
                <Input {...form.register('thumbnail_url')} placeholder="https://..." />
                {form.watch('thumbnail_url') && (
                  <img src={form.watch('thumbnail_url')} alt="Preview" className="w-full h-20 object-cover rounded border mt-1" onError={e => (e.currentTarget.style.display = 'none')} />
                )}
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Personagem Guia</label>
                <select {...form.register('character_id')} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                  <option value="">Sem personagem</option>
                  {characters.map((c: any) => (
                    <option key={c.id || c._id} value={c.id || c._id}>{c.name} ({c.title})</option>
                  ))}
                </select>
              </div>
            </div>

            {/* Seção 2: Configuração */}
            <div className="grid grid-cols-2 gap-4 p-4 border rounded-md bg-slate-50/50">
              <div className="space-y-3">
                <label className="flex items-center gap-2">
                  <input type="checkbox" {...form.register('is_core')} className="rounded" />
                  <span className="text-sm font-medium">Núcleo Comum</span>
                </label>
                {!form.watch('is_core') && (
                  <div className="space-y-1">
                    <label className="text-xs font-medium text-slate-500">Denominação</label>
                    <select {...form.register('denomination')} className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm">
                      <option value="">Selecione...</option>
                      <option value="Evangélico">Evangélico</option>
                      <option value="Católico">Católico</option>
                      <option value="Espírita Cristão">Espírita Cristão</option>
                      <option value="Protestante">Protestante</option>
                      <option value="Carismático">Carismático</option>
                      <option value="Outro">Outro</option>
                    </select>
                  </div>
                )}
              </div>
              <div className="space-y-3">
                <div className="space-y-1">
                  <label className="text-sm font-medium">Nível Mínimo</label>
                  <Input type="number" min={1} max={100} {...form.register('unlock_level')} />
                </div>
                <div className="space-y-1">
                  <label className="text-sm font-medium">Horas Estimadas</label>
                  <Input type="number" step="0.5" min={0.5} {...form.register('estimated_hours')} />
                </div>
                <div className="space-y-1">
                  <label className="text-sm font-medium">Ordem</label>
                  <Input type="number" min={0} {...form.register('order')} />
                </div>
              </div>
            </div>

            {/* Seção 3: Publicação */}
            <div className="flex gap-6">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...form.register('is_published')} className="rounded" />
                <span className="text-sm font-medium">Visível no app</span>
              </label>
              <label className="flex items-center gap-2">
                <input type="checkbox" {...form.register('is_premium')} className="rounded" />
                <span className="text-sm font-medium">Exclusivo JF Plus</span>
              </label>
            </div>

            <div className="flex justify-end pt-4 border-t">
              <Button type="button" variant="outline" className="mr-2" onClick={() => setIsFormOpen(false)}>Cancelar</Button>
              <Button type="submit" disabled={createMutation.isPending || updateMutation.isPending}>
                {createMutation.isPending || updateMutation.isPending ? 'Salvando...' : 'Salvar'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!deleteId}
        onOpenChange={(v) => !v && setDeleteId(null)}
        title="Excluir trilha?"
        description="Esta ação não pode ser desfeita. A trilha será removida permanentemente. As unidades e lições vinculadas NÃO serão excluídas automaticamente."
        confirmText="Sim, excluir"
        onConfirm={() => deleteId && deleteMutation.mutate(deleteId)}
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
}
