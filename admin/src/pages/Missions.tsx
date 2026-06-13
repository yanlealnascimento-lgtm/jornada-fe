import { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { missionsService, MissionTemplate, MissionStats } from '../services/missions.service';
import { Plus, Trash2, RefreshCw, Pencil, Download } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../components/ui/dialog';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { StatusBadge } from '../components/StatusBadge';
import { EmptyState } from '../components/EmptyState';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { toast } from 'sonner';

// ─── Types & Schema ──────────────────────────────────────────────────────────

const missionSchema = z.object({
  title: z.string().min(2, 'Obrigatório'),
  description: z.string().min(5, 'Obrigatório'),
  icon_emoji: z.string().min(1, 'Obrigatório'),
  cycle: z.enum(['daily', 'weekly']),
  trigger: z.enum([
    'lesson_count', 'perfect_lesson', 'streak_maintain', 'pf_earn',
    'trail_progress', 'study_complete', 'league_xp', 'invite_friend', 'review_lesson',
  ]),
  target: z.preprocess((v) => Number(v), z.number().min(1)),
  difficulty: z.enum(['easy', 'medium', 'hard']),
  pf_reward: z.preprocess((v) => Number(v), z.number().min(0)),
  mana_reward: z.preprocess((v) => Number(v), z.number().min(0)),
  verse_reference: z.string().optional(),
  verse_text: z.string().optional(),
  is_active: z.boolean().default(true),
  is_premium: z.boolean().default(false),
  weight: z.preprocess((v) => Number(v), z.number().min(1).max(10)),
  sort_order: z.preprocess((v) => Number(v), z.number().min(0)),
});
type MissionFormValues = z.infer<typeof missionSchema>;

const STAT_CARDS: { key: keyof MissionStats; label: string; icon: string; color: string }[] = [
  { key: 'total',   label: 'Total',    icon: '🎯', color: '#4A90E2' },
  { key: 'active',  label: 'Ativas',   icon: '✅', color: '#27AE60' },
  { key: 'daily',   label: 'Diárias',  icon: '📅', color: '#F59E0B' },
  { key: 'weekly',  label: 'Semanais', icon: '📆', color: '#8B5CF6' },
  { key: 'easy',    label: 'Fáceis',   icon: '🟢', color: '#22C55E' },
  { key: 'hard',    label: 'Difíceis', icon: '🔴', color: '#EF4444' },
];

const TRIGGER_LABELS: Record<string, string> = {
  lesson_count:    'Lições Completadas',
  perfect_lesson:  'Lições Perfeitas',
  streak_maintain: 'Streak Mantido',
  pf_earn:         'PF Ganho',
  trail_progress:  'Progresso Trilha',
  study_complete:  'Estudo Concluído',
  league_xp:       'PF na Liga',
  invite_friend:   'Convites',
  review_lesson:   'Revisão',
};

const DIFFICULTY_LABELS: Record<string, { label: string; color: string }> = {
  easy:   { label: 'Fácil',   color: '#22C55E' },
  medium: { label: 'Médio',   color: '#F59E0B' },
  hard:   { label: 'Difícil', color: '#EF4444' },
};

const EMOJI_SUGGESTIONS = ['📖', '🔥', '⭐', '💯', '🎯', '🏆', '⚡', '💎', '📅', '📯', '🌟', '👑', '🛤️', '🕯️', '🥊', '🔍', '🏅', '📚'];

// ─── Main Component ──────────────────────────────────────────────────────────

export function MissionsList() {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCycle, setFilterCycle] = useState('all');
  const [filterDifficulty, setFilterDifficulty] = useState('all');
  const [filterTrigger, setFilterTrigger] = useState('all');
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<MissionTemplate | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  // ─── Queries ─────────────────────────────────────────────────────────────
  const { data: listResult, isLoading } = useQuery({
    queryKey: ['missions'],
    queryFn: () => missionsService.list().then((res: any) => {
      const d = res.data || res;
      return d.templates ? d : { templates: Array.isArray(d) ? d : [], total: 0 };
    }),
  });

  const { data: statsResult } = useQuery({
    queryKey: ['mission-stats'],
    queryFn: () => missionsService.stats().then((res: any) => res.data || res),
  });

  const stats: MissionStats = statsResult ?? { total: 0, active: 0, daily: 0, weekly: 0, premium: 0, easy: 0, medium: 0, hard: 0 };
  const templates: MissionTemplate[] = useMemo(() => listResult?.templates || [], [listResult]);

  const filtered = useMemo(() => templates.filter(t => {
    const matchSearch = t.title.toLowerCase().includes(searchTerm.toLowerCase()) || t.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchCycle = filterCycle === 'all' || t.cycle === filterCycle;
    const matchDifficulty = filterDifficulty === 'all' || t.difficulty === filterDifficulty;
    const matchTrigger = filterTrigger === 'all' || t.trigger === filterTrigger;
    return matchSearch && matchCycle && matchDifficulty && matchTrigger;
  }), [templates, searchTerm, filterCycle, filterDifficulty, filterTrigger]);

  // ─── Mutations ───────────────────────────────────────────────────────────
  const invalidateAll = () => {
    queryClient.invalidateQueries({ queryKey: ['missions'] });
    queryClient.invalidateQueries({ queryKey: ['mission-stats'] });
  };

  const createMutation = useMutation({
    mutationFn: (data: MissionFormValues) => missionsService.create(data as any),
    onSuccess: () => { invalidateAll(); setIsFormOpen(false); toast.success('Missão criada com sucesso'); },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: MissionFormValues }) => missionsService.update(id, data as any),
    onSuccess: () => { invalidateAll(); setIsFormOpen(false); toast.success('Missão atualizada com sucesso'); },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => missionsService.delete(id),
    onSuccess: () => { invalidateAll(); setDeleteId(null); toast.success('Missão removida'); },
    onError: (e: any) => { toast.error(`Falha: ${e.message}`); setDeleteId(null); },
  });

  const toggleActiveMutation = useMutation({
    mutationFn: ({ id, is_active }: { id: string; is_active: boolean }) => missionsService.update(id, { is_active } as any),
    onSuccess: () => invalidateAll(),
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const seedMutation = useMutation({
    mutationFn: () => missionsService.seed(),
    onSuccess: (res: any) => {
      const d = res.data || res;
      toast.success(`Seed concluído: ${d.created ?? 0} criadas, ${d.updated ?? 0} atualizadas`);
      invalidateAll();
    },
    onError: (e: any) => toast.error(`Erro no seed: ${e.message}`),
  });

  // ─── Handlers ────────────────────────────────────────────────────────────
  const form = useForm<MissionFormValues>({
    resolver: zodResolver(missionSchema),
    defaultValues: {
      is_active: true, is_premium: false, cycle: 'daily', difficulty: 'easy',
      trigger: 'lesson_count', target: 1, pf_reward: 10, mana_reward: 5,
      weight: 5, sort_order: 0, icon_emoji: '🎯',
    },
  });

  const openNew = () => {
    setEditingItem(null);
    form.reset({
      is_active: true, is_premium: false, cycle: 'daily', difficulty: 'easy',
      trigger: 'lesson_count', target: 1, pf_reward: 10, mana_reward: 5,
      weight: 5, sort_order: templates.length + 1, icon_emoji: '🎯',
      title: '', description: '', verse_reference: '', verse_text: '',
    });
    setIsFormOpen(true);
  };

  const openEdit = (item: MissionTemplate) => {
    setEditingItem(item);
    form.reset({
      title: item.title, description: item.description, icon_emoji: item.icon_emoji || '🎯',
      cycle: item.cycle, trigger: item.trigger as any, target: item.target,
      difficulty: item.difficulty, pf_reward: item.pf_reward, mana_reward: item.mana_reward,
      verse_reference: item.verse_reference || '', verse_text: item.verse_text || '',
      is_active: item.is_active, is_premium: item.is_premium,
      weight: item.weight, sort_order: item.sort_order,
    });
    setIsFormOpen(true);
  };

  const onSubmit = (data: MissionFormValues) => {
    if (editingItem) updateMutation.mutate({ id: editingItem.id || editingItem._id, data });
    else createMutation.mutate(data);
  };

  const watchTitle = form.watch('title');
  const watchTarget = form.watch('target');
  const titlePreview = (watchTitle || '').replace('{target}', String(watchTarget || '?'));

  // ─── Render ──────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-800">Missões</h1>
          <p className="text-sm text-slate-500 mt-1">Templates de missões diárias e semanais para engajamento</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending}>
            <RefreshCw size={16} className={`mr-2 ${seedMutation.isPending ? 'animate-spin' : ''}`} />
            Seed Dados
          </Button>
          <Button onClick={openNew}><Plus size={16} className="mr-2" /> Nova Missão</Button>
        </div>
      </div>

      {/* Stats Dashboard */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {STAT_CARDS.map((card) => (
          <div key={card.key} className="bg-white rounded-xl border border-slate-200 p-4 relative overflow-hidden">
            <div className="absolute top-0 left-0 right-0 h-1" style={{ backgroundColor: card.color }} />
            <div className="text-2xl mb-1">{card.icon}</div>
            <div className="text-xl font-black text-slate-800">{(stats as any)[card.key] ?? 0}</div>
            <div className="text-xs font-semibold text-slate-500 leading-tight">{card.label}</div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        <Input placeholder="Buscar por título..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} className="max-w-xs" />
        <select className="flex h-10 rounded-md border border-input bg-background px-3 py-2 text-sm" value={filterCycle} onChange={e => setFilterCycle(e.target.value)}>
          <option value="all">Ciclo: Todos</option>
          <option value="daily">Diária</option>
          <option value="weekly">Semanal</option>
        </select>
        <select className="flex h-10 rounded-md border border-input bg-background px-3 py-2 text-sm" value={filterDifficulty} onChange={e => setFilterDifficulty(e.target.value)}>
          <option value="all">Dificuldade: Todas</option>
          <option value="easy">Fácil</option>
          <option value="medium">Médio</option>
          <option value="hard">Difícil</option>
        </select>
        <select className="flex h-10 rounded-md border border-input bg-background px-3 py-2 text-sm" value={filterTrigger} onChange={e => setFilterTrigger(e.target.value)}>
          <option value="all">Gatilho: Todos</option>
          {Object.entries(TRIGGER_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
        </select>
        <span className="text-sm text-slate-400 ml-auto">{filtered.length} missão(ões)</span>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {isLoading ? (
          <div className="text-center py-12 text-slate-400">Carregando...</div>
        ) : templates.length === 0 ? (
          <EmptyState icon={Download} title="Nenhuma missão cadastrada" description='Crie sua primeira missão ou clique em "Seed Dados" para carregar 20 exemplos.' actionText="Nova Missão" onAction={openNew} />
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="bg-slate-50">
                  <TableHead className="w-12 text-center">Emoji</TableHead>
                  <TableHead>Título</TableHead>
                  <TableHead>Ciclo</TableHead>
                  <TableHead>Gatilho</TableHead>
                  <TableHead className="text-center">Alvo</TableHead>
                  <TableHead>Dificuldade</TableHead>
                  <TableHead className="text-center">PF</TableHead>
                  <TableHead className="text-center">Manás</TableHead>
                  <TableHead>Premium</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.map(t => (
                  <TableRow key={t.id || t._id}>
                    <TableCell className="text-center text-2xl">{t.icon_emoji || '🎯'}</TableCell>
                    <TableCell>
                      <div className="font-medium text-slate-800 max-w-xs truncate" title={t.title}>{t.title.replace('{target}', String(t.target))}</div>
                      <div className="text-xs text-slate-400 truncate max-w-xs" title={t.description}>{t.description}</div>
                    </TableCell>
                    <TableCell>
                      <span className={`text-xs font-bold px-2 py-0.5 rounded ${t.cycle === 'daily' ? 'bg-amber-100 text-amber-700' : 'bg-violet-100 text-violet-700'}`}>
                        {t.cycle === 'daily' ? 'Diária' : 'Semanal'}
                      </span>
                    </TableCell>
                    <TableCell className="text-sm text-slate-600">{TRIGGER_LABELS[t.trigger] || t.trigger}</TableCell>
                    <TableCell className="text-center font-bold">{t.target}</TableCell>
                    <TableCell>
                      <span className="text-xs font-bold px-2 py-0.5 rounded" style={{ backgroundColor: DIFFICULTY_LABELS[t.difficulty]?.color + '20', color: DIFFICULTY_LABELS[t.difficulty]?.color }}>
                        {DIFFICULTY_LABELS[t.difficulty]?.label || t.difficulty}
                      </span>
                    </TableCell>
                    <TableCell className="text-center"><span className="text-green-600 font-bold">{t.pf_reward}</span></TableCell>
                    <TableCell className="text-center"><span className="text-blue-500 font-bold">{t.mana_reward}</span></TableCell>
                    <TableCell>{t.is_premium ? <span className="text-xs font-bold text-amber-600 bg-amber-50 px-2 py-0.5 rounded">JF+</span> : <span className="text-xs text-slate-400">Free</span>}</TableCell>
                    <TableCell><StatusBadge status={t.is_active ? 'active' : 'inactive'} /></TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <label className="relative inline-flex items-center cursor-pointer" title={t.is_active ? 'Ativa' : 'Inativa'}>
                          <input type="checkbox" checked={t.is_active} onChange={() => toggleActiveMutation.mutate({ id: t.id || t._id, is_active: !t.is_active })} className="sr-only peer" />
                          <div className="w-9 h-5 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-green-500" />
                        </label>
                        <Button variant="ghost" size="icon" onClick={() => openEdit(t)}><Pencil className="h-4 w-4" /></Button>
                        <Button variant="ghost" size="icon" className="text-destructive hover:text-destructive hover:bg-destructive/10" onClick={() => setDeleteId(t.id || t._id)}><Trash2 className="h-4 w-4" /></Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {/* Form Dialog */}
      <Dialog open={isFormOpen} onOpenChange={setIsFormOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingItem ? 'Editar Missão' : 'Nova Missão'}</DialogTitle>
          </DialogHeader>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 pt-4">

            {/* Emoji + Title */}
            <div className="grid grid-cols-6 gap-4">
              <div className="col-span-1 space-y-2">
                <label className="text-sm font-medium">Emoji</label>
                <Input {...form.register('icon_emoji')} placeholder="🎯" className="text-center text-xl" />
                <div className="flex flex-wrap gap-1 mt-1">
                  {EMOJI_SUGGESTIONS.slice(0, 6).map(e => (
                    <button key={e} type="button" className="text-lg hover:scale-125 transition-transform" onClick={() => form.setValue('icon_emoji', e)}>{e}</button>
                  ))}
                </div>
              </div>
              <div className="col-span-5 space-y-2">
                <label className="text-sm font-medium">Título * <span className="text-xs text-slate-400">(use {'{target}'} para substituição)</span></label>
                <Input {...form.register('title')} placeholder='ex: Complete {target} lições hoje' />
                {titlePreview && <div className="text-xs text-blue-600 bg-blue-50 px-2 py-1 rounded">Preview: {titlePreview}</div>}
                {form.formState.errors.title && <span className="text-xs text-red-500">{form.formState.errors.title.message}</span>}
              </div>
            </div>

            {/* Description */}
            <div className="space-y-2">
              <label className="text-sm font-medium">Descrição * <span className="text-xs text-slate-400">(dica: inclua versículo)</span></label>
              <textarea {...form.register('description')} placeholder="Motivação para a missão..." className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2" />
              {form.formState.errors.description && <span className="text-xs text-red-500">{form.formState.errors.description.message}</span>}
            </div>

            {/* Cycle + Trigger + Target */}
            <div className="border p-4 rounded-md space-y-4 bg-slate-50/50">
              <h4 className="text-sm font-bold">Configuração</h4>
              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Ciclo</label>
                  <select {...form.register('cycle')} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                    <option value="daily">📅 Diária</option>
                    <option value="weekly">📆 Semanal</option>
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Gatilho</label>
                  <select {...form.register('trigger')} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                    {Object.entries(TRIGGER_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Meta (alvo)</label>
                  <Input type="number" {...form.register('target')} min={1} max={50} />
                  {form.formState.errors.target && <span className="text-xs text-red-500">{form.formState.errors.target.message}</span>}
                </div>
              </div>
            </div>

            {/* Difficulty */}
            <div className="space-y-2">
              <label className="text-sm font-medium">Dificuldade</label>
              <div className="flex gap-4">
                {(['easy', 'medium', 'hard'] as const).map(d => (
                  <label key={d} className="flex items-center gap-2 cursor-pointer">
                    <input type="radio" value={d} {...form.register('difficulty')} className="accent-primary" />
                    <span className="text-sm font-medium" style={{ color: DIFFICULTY_LABELS[d].color }}>
                      {d === 'easy' ? '🟢 Fácil' : d === 'medium' ? '🟡 Médio' : '🔴 Difícil'}
                    </span>
                  </label>
                ))}
              </div>
            </div>

            {/* Rewards + Weight */}
            <div className="grid grid-cols-4 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium text-green-600">PF Recompensa</label>
                <Input type="number" {...form.register('pf_reward')} min={0} max={200} />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-blue-500">Manás Recompensa</label>
                <Input type="number" {...form.register('mana_reward')} min={0} max={60} />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Peso (1-10)</label>
                <Input type="number" {...form.register('weight')} min={1} max={10} />
                <p className="text-[10px] text-slate-400">Maior = aparece mais</p>
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Ordem</label>
                <Input type="number" {...form.register('sort_order')} min={0} />
              </div>
            </div>

            {/* Verse */}
            <div className="grid grid-cols-3 gap-4">
              <div className="col-span-1 space-y-2">
                <label className="text-sm font-medium">Versículo (ref)</label>
                <Input {...form.register('verse_reference')} placeholder="ex: Rm 12:12" />
              </div>
              <div className="col-span-2 space-y-2">
                <label className="text-sm font-medium">Texto do Versículo</label>
                <Input {...form.register('verse_text')} placeholder="Seja constante na oração..." />
              </div>
            </div>

            {/* Switches */}
            <div className="flex gap-6">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...form.register('is_active')} className="rounded" />
                <span className="text-sm font-medium">Ativa</span>
              </label>
              <label className="flex items-center gap-2">
                <input type="checkbox" {...form.register('is_premium')} className="rounded" />
                <span className="text-sm font-medium text-amber-600">Exclusivo JF Plus</span>
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
        title="Remover Missão?"
        description="Missões ativas de usuários baseadas neste template não serão afetadas. Essa ação não pode ser desfeita."
        confirmText="Sim, excluir"
        onConfirm={() => deleteId && deleteMutation.mutate(deleteId)}
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
}
