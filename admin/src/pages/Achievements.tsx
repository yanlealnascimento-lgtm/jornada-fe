import { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { achievementsService, Achievement, AchievementStats } from '../services/achievements.service';
import { Plus, Trash2, RefreshCw, Pencil, Trophy, Download } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../components/ui/dialog';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { StatusBadge } from '../components/StatusBadge';
import { RarityBadge, RarityType } from '../components/RarityBadge';
import { EmptyState } from '../components/EmptyState';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { toast } from 'sonner';

// ─── Types & Schema ──────────────────────────────────────────────────────────

const achievementSchema = z.object({
  key: z.string().min(2, 'Obrigatório').regex(/^[a-z0-9_]+$/, 'Apenas minúsculas e underline'),
  name: z.string().min(2, 'Obrigatório'),
  description: z.string().min(5, 'Obrigatório'),
  verse_reference: z.string().optional(),
  verse_text: z.string().optional(),
  icon_url: z.string().url('URL inválida').optional().or(z.literal('')),
  icon_emoji: z.string().optional(),
  trigger: z.object({
    type: z.enum(['lesson_count', 'streak_days', 'trail_complete', 'league_rank', 'invite_count', 'pf_total', 'level', 'perfect_lesson', 'pf_earn', 'trail_progress', 'study_complete', 'league_xp', 'review_lesson', 'streak_maintain']),
    value: z.preprocess((val) => Number(val), z.number().min(1)),
  }),
  rarity: z.enum(['common', 'rare', 'epic']),
  cycle: z.enum(['one_time', 'daily', 'weekly']).default('one_time'),
  difficulty: z.enum(['easy', 'medium', 'hard']).optional(),
  is_premium: z.boolean().default(false),
  pf_reward: z.preprocess((val) => Number(val), z.number().min(0)),
  mana_reward: z.preprocess((val) => Number(val), z.number().min(0)),
  is_active: z.boolean().default(true),
  sort_order: z.preprocess((val) => Number(val), z.number().min(0)),
});
type AchievementFormValues = z.infer<typeof achievementSchema>;

const STAT_CARDS: { key: keyof AchievementStats; label: string; icon: string; color: string }[] = [
  { key: 'total',    label: 'Total',    icon: '🏆', color: '#4A90E2' },
  { key: 'active',   label: 'Ativas',   icon: '✅', color: '#27AE60' },
  { key: 'common',   label: 'Comuns',   icon: '⚪', color: '#95A5A6' },
  { key: 'rare',     label: 'Raras',    icon: '🔵', color: '#3B82F6' },
  { key: 'epic',     label: 'Épicas',   icon: '🟣', color: '#8B5CF6' },
  { key: 'inactive', label: 'Inativas', icon: '🚫', color: '#EF4444' },
];

const TRIGGER_LABELS: Record<string, string> = {
  lesson_count: 'Total de Lições',
  streak_days: 'Dias Seguidos',
  trail_complete: 'Trilhas Completadas',
  league_rank: 'Posição na Liga',
  invite_count: 'Convites de Amigos',
  pf_total: 'Total PF Alcançado',
  level: 'Nível Alcançado',
  perfect_lesson: 'Lições 100% Acerto',
  pf_earn: 'PF Ganho',
  trail_progress: 'Progresso Trilha',
  study_complete: 'Estudos Concluídos',
  league_xp: 'PF na Liga',
  review_lesson: 'Lições Revisadas',
  streak_maintain: 'Streak Mantido',
};

const CYCLE_LABELS: Record<string, string> = {
  one_time: 'Única',
  daily: 'Diária',
  weekly: 'Semanal',
};

const DIFFICULTY_LABELS: Record<string, string> = {
  easy: 'Fácil',
  medium: 'Médio',
  hard: 'Difícil',
};

const DIFFICULTY_COLORS: Record<string, string> = {
  easy: 'bg-green-100 text-green-700',
  medium: 'bg-yellow-100 text-yellow-700',
  hard: 'bg-red-100 text-red-700',
};

// ─── Main Component ──────────────────────────────────────────────────────────

export function AchievementsList() {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterRarity, setFilterRarity] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterCycle, setFilterCycle] = useState('all');
  const [filterDifficulty, setFilterDifficulty] = useState('all');
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<Achievement | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  // ─── Queries ─────────────────────────────────────────────────────────────
  const { data: listResult, isLoading } = useQuery({
    queryKey: ['achievements'],
    queryFn: () => achievementsService.list().then((res: any) => {
      const d = res.data || res;
      return d.achievements ? d : { achievements: Array.isArray(d) ? d : [], total: 0 };
    }),
  });

  const { data: statsResult } = useQuery({
    queryKey: ['achievement-stats'],
    queryFn: () => achievementsService.stats().then((res: any) => res.data || res),
  });

  const stats: AchievementStats = statsResult ?? { total: 0, active: 0, inactive: 0, common: 0, rare: 0, epic: 0 };
  const achievements: Achievement[] = useMemo(() => listResult?.achievements || [], [listResult]);

  const filtered = useMemo(() => achievements.filter((a: any) => {
    const matchSearch = a.name.toLowerCase().includes(searchTerm.toLowerCase()) || a.key.includes(searchTerm.toLowerCase());
    const matchRarity = filterRarity === 'all' || a.rarity === filterRarity;
    const matchStatus = filterStatus === 'all' || (filterStatus === 'active' && a.is_active) || (filterStatus === 'inactive' && !a.is_active);
    const matchCycle = filterCycle === 'all' || (a.cycle || 'one_time') === filterCycle;
    const matchDifficulty = filterDifficulty === 'all' || a.difficulty === filterDifficulty;
    return matchSearch && matchRarity && matchStatus && matchCycle && matchDifficulty;
  }), [achievements, searchTerm, filterRarity, filterStatus, filterCycle, filterDifficulty]);

  // ─── Mutations ───────────────────────────────────────────────────────────
  const invalidateAll = () => {
    queryClient.invalidateQueries({ queryKey: ['achievements'] });
    queryClient.invalidateQueries({ queryKey: ['achievement-stats'] });
  };

  const createMutation = useMutation({
    mutationFn: (data: AchievementFormValues) => achievementsService.create(data as any),
    onSuccess: () => {
      invalidateAll();
      setIsFormOpen(false);
      toast.success('Conquista criada com sucesso');
    },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: AchievementFormValues }) => achievementsService.update(id, data as any),
    onSuccess: () => {
      invalidateAll();
      setIsFormOpen(false);
      toast.success('Conquista atualizada com sucesso');
    },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => achievementsService.delete(id),
    onSuccess: () => {
      invalidateAll();
      setDeleteId(null);
      toast.success('Conquista removida');
    },
    onError: (e: any) => {
      toast.error(`Falha ao remover: ${e.message}`);
      setDeleteId(null);
    },
  });

  const toggleActiveMutation = useMutation({
    mutationFn: ({ id, is_active }: { id: string; is_active: boolean }) =>
      achievementsService.update(id, { is_active } as any),
    onSuccess: () => invalidateAll(),
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const seedMutation = useMutation({
    mutationFn: () => achievementsService.seed(),
    onSuccess: (res: any) => {
      const d = res.data || res;
      toast.success(`Seed concluído: ${d.created ?? 0} criadas, ${d.updated ?? 0} atualizadas`);
      invalidateAll();
    },
    onError: (e: any) => toast.error(`Erro no seed: ${e.message}`),
  });

  // ─── Handlers ────────────────────────────────────────────────────────────
  const form = useForm<AchievementFormValues>({
    resolver: zodResolver(achievementSchema),
    defaultValues: {
      is_active: true, rarity: 'common', sort_order: 0,
      trigger: { type: 'lesson_count', value: 1 },
      pf_reward: 10, mana_reward: 5,
    },
  });

  const openNew = () => {
    setEditingItem(null);
    form.reset({
      is_active: true, rarity: 'common', sort_order: achievements.length + 1,
      trigger: { type: 'lesson_count', value: 1 },
      pf_reward: 10, mana_reward: 5,
      cycle: 'one_time', difficulty: undefined, is_premium: false,
      key: '', name: '', description: '', icon_emoji: '', icon_url: '',
      verse_reference: '', verse_text: '',
    });
    setIsFormOpen(true);
  };

  const openEdit = (item: Achievement) => {
    setEditingItem(item);
    form.reset({
      key: item.key,
      name: item.name,
      description: item.description,
      icon_emoji: item.icon_emoji || '🏆',
      icon_url: item.icon_url || '',
      verse_reference: item.verse_reference || '',
      verse_text: item.verse_text || '',
      trigger: { type: item.trigger.type as any, value: item.trigger.value },
      rarity: item.rarity as any,
      cycle: (item as any).cycle || 'one_time',
      difficulty: (item as any).difficulty || undefined,
      is_premium: (item as any).is_premium || false,
      pf_reward: item.pf_reward,
      mana_reward: item.mana_reward,
      is_active: item.is_active,
      sort_order: item.sort_order,
    });
    setIsFormOpen(true);
  };

  const onSubmit = (data: AchievementFormValues) => {
    if (editingItem) updateMutation.mutate({ id: editingItem.id || editingItem._id, data });
    else createMutation.mutate(data);
  };

  // ─── Render ──────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-800">Conquistas</h1>
          <p className="text-sm text-slate-500 mt-1">Sistema de troféus e badges para engajar usuários</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending}>
            <RefreshCw size={16} className={`mr-2 ${seedMutation.isPending ? 'animate-spin' : ''}`} />
            Seed Dados
          </Button>
          <Button onClick={openNew}><Plus size={16} className="mr-2" /> Nova Conquista</Button>
        </div>
      </div>

      {/* Stats Dashboard */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {STAT_CARDS.map((card) => (
          <div key={card.key} className="bg-white rounded-xl border border-slate-200 p-4 relative overflow-hidden">
            <div className="absolute top-0 left-0 right-0 h-1" style={{ backgroundColor: card.color }} />
            <div className="text-2xl mb-1">{card.icon}</div>
            <div className="text-xl font-black text-slate-800">
              {(stats as any)[card.key] ?? 0}
            </div>
            <div className="text-xs font-semibold text-slate-500 leading-tight">{card.label}</div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        <Input
          placeholder="Buscar por nome ou chave..."
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
          className="max-w-xs"
        />
        <select
          className="flex h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
          value={filterRarity}
          onChange={e => setFilterRarity(e.target.value)}
        >
          <option value="all">Raridade: Todas</option>
          <option value="common">Comum</option>
          <option value="rare">Raro</option>
          <option value="epic">Épico</option>
        </select>
        <select
          className="flex h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
          value={filterCycle}
          onChange={e => setFilterCycle(e.target.value)}
        >
          <option value="all">Ciclo: Todos</option>
          <option value="one_time">Única</option>
          <option value="daily">Diária</option>
          <option value="weekly">Semanal</option>
        </select>
        <select
          className="flex h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
          value={filterDifficulty}
          onChange={e => setFilterDifficulty(e.target.value)}
        >
          <option value="all">Dificuldade: Todas</option>
          <option value="easy">Fácil</option>
          <option value="medium">Médio</option>
          <option value="hard">Difícil</option>
        </select>
        <select
          className="flex h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
          value={filterStatus}
          onChange={e => setFilterStatus(e.target.value)}
        >
          <option value="all">Status: Todos</option>
          <option value="active">Ativas</option>
          <option value="inactive">Inativas</option>
        </select>
        <span className="text-sm text-slate-400 ml-auto">{filtered.length} conquista(s)</span>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {isLoading ? (
          <div className="text-center py-12 text-slate-400">Carregando...</div>
        ) : achievements.length === 0 ? (
          <EmptyState
            icon={Download}
            title="Nenhuma conquista cadastrada"
            description='Crie sua primeira conquista ou clique em "Seed Dados" para carregar exemplos.'
            actionText="Nova Conquista"
            onAction={openNew}
          />
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="bg-slate-50">
                  <TableHead className="w-16 text-center">Emoji</TableHead>
                  <TableHead>Nome</TableHead>
                  <TableHead>Chave</TableHead>
                  <TableHead>Gatilho</TableHead>
                  <TableHead className="text-center">Valor</TableHead>
                  <TableHead>Raridade</TableHead>
                  <TableHead className="text-center">PF</TableHead>
                  <TableHead className="text-center">Manás</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.map(ach => (
                  <TableRow key={ach.id || ach._id}>
                    <TableCell className="text-center text-2xl">
                      {ach.icon_emoji || (ach.icon_url ? <img src={ach.icon_url} alt="" className="w-8 h-8 mx-auto" /> : '🏆')}
                    </TableCell>
                    <TableCell>
                      <div className="font-medium text-slate-800 max-w-xs truncate" title={ach.name}>{ach.name}</div>
                      <div className="text-xs text-slate-400 truncate max-w-xs" title={ach.description}>{ach.description}</div>
                    </TableCell>
                    <TableCell>
                      <span className="text-xs font-mono text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded">{ach.key}</span>
                    </TableCell>
                    <TableCell className="text-sm text-slate-600">
                      {TRIGGER_LABELS[ach.trigger.type] || ach.trigger.type}
                    </TableCell>
                    <TableCell className="text-center font-bold">{ach.trigger.value}</TableCell>
                    <TableCell><RarityBadge rarity={ach.rarity as RarityType} /></TableCell>
                    <TableCell className="text-center">
                      <span className="text-green-600 font-bold">{ach.pf_reward}</span>
                    </TableCell>
                    <TableCell className="text-center">
                      <span className="text-blue-500 font-bold">{ach.mana_reward}</span>
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={ach.is_active ? 'active' : 'inactive'} />
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <label className="relative inline-flex items-center cursor-pointer" title={ach.is_active ? 'Ativa' : 'Inativa'}>
                          <input
                            type="checkbox"
                            checked={ach.is_active}
                            onChange={() => toggleActiveMutation.mutate({ id: ach.id || ach._id, is_active: !ach.is_active })}
                            className="sr-only peer"
                          />
                          <div className="w-9 h-5 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-green-500" />
                        </label>
                        <Button variant="ghost" size="icon" onClick={() => openEdit(ach)}>
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="text-destructive hover:text-destructive hover:bg-destructive/10"
                          onClick={() => setDeleteId(ach.id || ach._id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
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
            <DialogTitle>{editingItem ? 'Editar Conquista' : 'Nova Conquista'}</DialogTitle>
          </DialogHeader>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 pt-4">
            {/* Informações Básicas */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Chave (snake_case) *</label>
                <Input {...form.register('key')} placeholder="ex: ten_lessons" disabled={!!editingItem} />
                {form.formState.errors.key && <span className="text-xs text-red-500">{form.formState.errors.key.message}</span>}
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Nome *</label>
                <Input {...form.register('name')} placeholder="ex: Dez Palavras" />
                {form.formState.errors.name && <span className="text-xs text-red-500">{form.formState.errors.name.message}</span>}
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Descrição *</label>
              <textarea
                {...form.register('description')}
                placeholder="Complete 10 lições"
                className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
              />
              {form.formState.errors.description && <span className="text-xs text-red-500">{form.formState.errors.description.message}</span>}
            </div>

            <div className="grid grid-cols-4 gap-4">
              <div className="col-span-1 space-y-2">
                <label className="text-sm font-medium">Emoji</label>
                <Input {...form.register('icon_emoji')} placeholder="ex: 📖" />
              </div>
              <div className="col-span-3 space-y-2">
                <label className="text-sm font-medium">URL Ícone (opcional)</label>
                <Input {...form.register('icon_url')} placeholder="https://..." />
              </div>
            </div>

            {/* Versículo */}
            <div className="grid grid-cols-3 gap-4">
              <div className="col-span-1 space-y-2">
                <label className="text-sm font-medium">Referência (Versículo)</label>
                <Input {...form.register('verse_reference')} placeholder="ex: Êxodo 20" />
              </div>
              <div className="col-span-2 space-y-2">
                <label className="text-sm font-medium">Texto do Versículo</label>
                <Input {...form.register('verse_text')} placeholder="Então Deus pronunciou..." />
              </div>
            </div>

            {/* Trigger */}
            <div className="border p-4 rounded-md space-y-4 bg-slate-50/50">
              <h4 className="text-sm font-bold">Gatilho / Condição</h4>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Tipo</label>
                  <select {...form.register('trigger.type')} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                    {Object.entries(TRIGGER_LABELS).map(([k, v]) => (
                      <option key={k} value={k}>{v}</option>
                    ))}
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Valor (meta numérica)</label>
                  <Input type="number" {...form.register('trigger.value')} min={1} />
                  {form.formState.errors.trigger?.value && <span className="text-xs text-red-500">{form.formState.errors.trigger.value.message}</span>}
                </div>
              </div>
            </div>

            {/* Raridade */}
            <div className="space-y-2">
              <label className="text-sm font-medium">Raridade</label>
              <div className="flex gap-4">
                {(['common', 'rare', 'epic'] as const).map(r => (
                  <label key={r} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      value={r}
                      {...form.register('rarity')}
                      className="accent-primary"
                    />
                    <span className="text-sm font-medium capitalize">
                      {r === 'common' ? 'Comum' : r === 'rare' ? 'Raro' : 'Épico'}
                    </span>
                  </label>
                ))}
              </div>
            </div>

            {/* Ciclo & Dificuldade (merged from Missions) */}
            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Ciclo</label>
                <select {...form.register('cycle')} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                  <option value="one_time">Única (permanente)</option>
                  <option value="daily">Diária</option>
                  <option value="weekly">Semanal</option>
                </select>
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Dificuldade</label>
                <select {...form.register('difficulty')} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                  <option value="">Nenhuma</option>
                  <option value="easy">Fácil</option>
                  <option value="medium">Médio</option>
                  <option value="hard">Difícil</option>
                </select>
              </div>
              <div className="space-y-2 flex items-end">
                <label className="flex items-center gap-2">
                  <input type="checkbox" {...form.register('is_premium')} className="rounded" />
                  <span className="text-sm font-medium">Premium (JF+)</span>
                </label>
              </div>
            </div>

            {/* Recompensas */}
            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium text-green-600">Recompensa: PF</label>
                <Input type="number" {...form.register('pf_reward')} min={0} />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-blue-500">Recompensa: Maná</label>
                <Input type="number" {...form.register('mana_reward')} min={0} />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Ordem de Listagem</label>
                <Input type="number" {...form.register('sort_order')} min={0} />
              </div>
            </div>

            {/* Ativo */}
            <div className="flex gap-6">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...form.register('is_active')} className="rounded" />
                <span className="text-sm font-medium">Ativa (visível e validada pelas triggers)</span>
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
        title="Remover Conquista?"
        description="Se usuários já destravaram esta conquista, ela sumirá de seus murais. Essa ação não pode ser desfeita."
        confirmText="Sim, excluir"
        onConfirm={() => deleteId && deleteMutation.mutate(deleteId)}
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
}
