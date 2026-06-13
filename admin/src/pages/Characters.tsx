import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { charactersService, Character, CharacterStats } from '../services/characters.service';
import { Plus, Pencil, Trash2, RefreshCw, ShieldAlert } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../components/ui/dialog';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { RarityBadge, RarityType } from '../components/RarityBadge';
import { EmptyState } from '../components/EmptyState';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { toast } from 'sonner';

// ─── Schema ──────────────────────────────────────────────────────────────────

const characterSchema = z.object({
  name: z.string().min(2, 'Obrigatório'),
  title: z.string().min(2, 'Obrigatório'),
  biblical_reference: z.string().min(2, 'Obrigatório'),
  biblical_story: z.string().min(10, 'Mínimo 10 caracteres').max(1000),
  sprite_url: z.string().url('URL inválida'),
  lottie_idle_url: z.string().url().optional().or(z.literal('')),
  lottie_happy_url: z.string().url().optional().or(z.literal('')),
  lottie_sad_url: z.string().url().optional().or(z.literal('')),
  color_hex: z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'Formato #RRGGBB'),
  rarity: z.enum(['common', 'uncommon', 'rare', 'epic', 'special']),
  trail_id: z.string().optional(),
  unlock_condition: z.object({
    type: z.enum(['default', 'trail_complete', 'level', 'streak', 'achievement']),
    value: z.union([z.string(), z.number()]).optional(),
  }),
  dialogues: z.array(z.object({
    type: z.enum(['greeting', 'lesson_start', 'correct', 'wrong', 'lesson_complete', 'streak_warning', 'streak_broken', 'level_up']),
    text: z.string().min(1, 'Não pode ser vazio').max(300),
  })).min(1, 'Ao menos um diálogo'),
  is_sacred: z.boolean().default(false),
  is_active: z.boolean().default(true),
  sort_order: z.preprocess((v) => Number(v), z.number().min(0)),
});
type CharacterFormValues = z.infer<typeof characterSchema>;

const STAT_CARDS: { key: keyof CharacterStats; label: string; icon: string; color: string }[] = [
  { key: 'total',    label: 'Total',    icon: '👤', color: '#4A90E2' },
  { key: 'active',   label: 'Ativos',   icon: '✅', color: '#27AE60' },
  { key: 'common',   label: 'Comuns',   icon: '⚪', color: '#6B7280' },
  { key: 'uncommon', label: 'Incomuns', icon: '🟢', color: '#10B981' },
  { key: 'rare',     label: 'Raros',    icon: '🔵', color: '#3B82F6' },
  { key: 'epic',     label: 'Épicos',   icon: '🟣', color: '#8B5CF6' },
  { key: 'special',  label: 'Especiais',icon: '⭐', color: '#F59E0B' },
  { key: 'sacred',   label: 'Sagrados', icon: '🙏', color: '#EF4444' },
];

function formatUnlockCondition(uc: { type: string; value?: string | number }) {
  switch (uc.type) {
    case 'default': return 'Desbloqueado por padrão';
    case 'trail_complete': return `Trilha: ${uc.value}`;
    case 'level': return `Nível ${uc.value}`;
    case 'streak': return `${uc.value} dias de streak`;
    case 'achievement': return `Conquista: ${uc.value}`;
    default: return uc.type;
  }
}

// ─── Main Component ──────────────────────────────────────────────────────────

export function CharactersList() {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterRarity, setFilterRarity] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingChar, setEditingChar] = useState<Character | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<{ id: string; name: string } | null>(null);
  const [toggleId, setToggleId] = useState<string | null>(null);

  // ─── Queries ─────────────────────────────────────────────────────────────
  const { data: listResult, isLoading } = useQuery({
    queryKey: ['characters'],
    queryFn: () => charactersService.list().then((res: any) => {
      const d = res.data || res;
      return d.characters ? d : { characters: Array.isArray(d) ? d : [], total: 0 };
    }),
  });

  const { data: statsResult } = useQuery({
    queryKey: ['character-stats'],
    queryFn: () => charactersService.stats().then((res: any) => res.data || res),
  });

  const stats: CharacterStats = statsResult ?? { total: 0, active: 0, inactive: 0, common: 0, uncommon: 0, rare: 0, epic: 0, special: 0, sacred: 0 };
  const characters: Character[] = listResult?.characters || [];

  const filtered = characters.filter(c => {
    const matchSearch = c.name.toLowerCase().includes(searchTerm.toLowerCase()) || c.title.toLowerCase().includes(searchTerm.toLowerCase());
    const matchRarity = filterRarity === 'all' || c.rarity === filterRarity;
    const matchStatus = filterStatus === 'all' || (filterStatus === 'true' && c.is_active) || (filterStatus === 'false' && !c.is_active);
    return matchSearch && matchRarity && matchStatus;
  });

  // ─── Mutations ───────────────────────────────────────────────────────────
  const invalidateAll = () => {
    queryClient.invalidateQueries({ queryKey: ['characters'] });
    queryClient.invalidateQueries({ queryKey: ['character-stats'] });
  };

  const createMutation = useMutation({
    mutationFn: (data: CharacterFormValues) => charactersService.create(data as any),
    onSuccess: () => { invalidateAll(); setIsFormOpen(false); toast.success('Personagem criado com sucesso'); },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: CharacterFormValues }) => charactersService.update(id, data as any),
    onSuccess: () => { invalidateAll(); setIsFormOpen(false); toast.success('Personagem atualizado com sucesso'); },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => charactersService.delete(id),
    onSuccess: () => { invalidateAll(); setDeleteTarget(null); toast.success('Personagem removido'); },
    onError: (e: any) => { toast.error(`Erro: ${e.message}`); setDeleteTarget(null); },
  });

  const toggleMutation = useMutation({
    mutationFn: (id: string) => charactersService.toggleActive(id),
    onSuccess: () => { invalidateAll(); setToggleId(null); toast.success('Status atualizado'); },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const seedMutation = useMutation({
    mutationFn: () => charactersService.seed(),
    onSuccess: (res: any) => {
      const d = res.data || res;
      toast.success(`Seed: ${d.created ?? 0} criados, ${d.updated ?? 0} atualizados`);
      invalidateAll();
    },
    onError: (e: any) => toast.error(`Erro no seed: ${e.message}`),
  });

  // ─── Form ────────────────────────────────────────────────────────────────
  const form = useForm<CharacterFormValues>({
    resolver: zodResolver(characterSchema),
    defaultValues: {
      is_active: true, is_sacred: false, rarity: 'common', sort_order: 0,
      color_hex: '#4A90E2', unlock_condition: { type: 'default', value: '' },
      dialogues: [{ type: 'greeting', text: '' }],
    },
  });

  const { fields, append, remove } = useFieldArray({ control: form.control, name: 'dialogues' });

  const openNew = () => {
    setEditingChar(null);
    form.reset({
      name: '', title: '', biblical_reference: '', biblical_story: '', sprite_url: '',
      lottie_idle_url: '', lottie_happy_url: '', lottie_sad_url: '',
      color_hex: '#4A90E2', rarity: 'common', trail_id: '',
      unlock_condition: { type: 'default', value: '' },
      dialogues: [{ type: 'greeting', text: '' }],
      is_sacred: false, is_active: true, sort_order: characters.length + 1,
    });
    setIsFormOpen(true);
  };

  const openEdit = (char: Character) => {
    setEditingChar(char);
    form.reset({
      name: char.name,
      title: char.title,
      biblical_reference: char.biblical_reference,
      biblical_story: char.biblical_story,
      sprite_url: char.sprite_url,
      lottie_idle_url: char.lottie_idle_url || '',
      lottie_happy_url: char.lottie_happy_url || '',
      lottie_sad_url: char.lottie_sad_url || '',
      color_hex: char.color_hex,
      rarity: char.rarity as any,
      trail_id: typeof char.trail_id === 'object' && char.trail_id ? char.trail_id._id : (char.trail_id as string) || '',
      unlock_condition: { type: (char.unlock_condition?.type || 'default') as any, value: char.unlock_condition?.value ?? '' },
      dialogues: (char.dialogues || []).map(d => ({ type: d.type as any, text: d.text })),
      is_sacred: char.is_sacred,
      is_active: char.is_active,
      sort_order: char.sort_order,
    });
    setIsFormOpen(true);
  };

  const onSubmit = (data: CharacterFormValues) => {
    if (editingChar) updateMutation.mutate({ id: editingChar.id || editingChar._id, data });
    else createMutation.mutate(data);
  };

  const storyLen = form.watch('biblical_story')?.length || 0;

  // ─── Render ──────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-800">Personagens</h1>
          <p className="text-sm text-slate-500 mt-1">Companheiros de jornada, avatares e guias bíblicos</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending}>
            <RefreshCw size={16} className={`mr-2 ${seedMutation.isPending ? 'animate-spin' : ''}`} />
            Seed Dados
          </Button>
          <Button onClick={openNew}><Plus size={16} className="mr-2" /> Novo Personagem</Button>
        </div>
      </div>

      {/* Stats Dashboard */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-3">
        {STAT_CARDS.map((card) => (
          <div key={card.key} className="bg-white rounded-xl border border-slate-200 p-3 relative overflow-hidden">
            <div className="absolute top-0 left-0 right-0 h-1" style={{ backgroundColor: card.color }} />
            <div className="text-xl mb-0.5">{card.icon}</div>
            <div className="text-lg font-black text-slate-800">{(stats as any)[card.key] ?? 0}</div>
            <div className="text-[10px] font-semibold text-slate-500">{card.label}</div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        <Input placeholder="Buscar por nome..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} className="max-w-xs" />
        <select className="border rounded-md px-3 py-2 text-sm bg-white" value={filterRarity} onChange={e => setFilterRarity(e.target.value)}>
          <option value="all">Raridade: Todas</option>
          <option value="common">Comum</option>
          <option value="uncommon">Incomum</option>
          <option value="rare">Raro</option>
          <option value="epic">Épico</option>
          <option value="special">Especial</option>
        </select>
        <select className="border rounded-md px-3 py-2 text-sm bg-white" value={filterStatus} onChange={e => setFilterStatus(e.target.value)}>
          <option value="all">Status: Todos</option>
          <option value="true">Ativos</option>
          <option value="false">Inativos</option>
        </select>
        <span className="text-sm text-slate-400 ml-auto">{filtered.length} personagem(ns)</span>
      </div>

      {/* Grid */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {[1, 2, 3].map(i => <div key={i} className="h-56 bg-muted animate-pulse rounded-2xl" />)}
        </div>
      ) : characters.length === 0 ? (
        <EmptyState
          icon={ShieldAlert}
          title="Nenhum personagem cadastrado"
          description='Crie personagens bíblicos ou clique em "Seed Dados" para carregar 9 de exemplo.'
          actionText="Novo Personagem"
          onAction={openNew}
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {filtered.map(char => (
            <div key={char.id || char._id} className="relative rounded-2xl border-2 overflow-hidden bg-white" style={{ borderColor: char.color_hex + '44' }}>
              <div style={{ height: 6, background: char.color_hex }} />
              <div className="p-4">
                {/* Avatar + Info */}
                <div className="flex items-start gap-3 mb-3">
                  <div className="w-16 h-20 rounded-xl overflow-hidden flex-shrink-0 flex items-center justify-center" style={{ background: char.color_hex + '22' }}>
                    {char.sprite_url ? (
                      <img src={char.sprite_url} alt={char.name} className="w-full h-full object-cover" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; (e.target as HTMLImageElement).parentElement!.innerHTML = `<span class="text-2xl font-bold" style="color:${char.color_hex}">${char.name.charAt(0)}</span>`; }} />
                    ) : (
                      <span className="text-2xl font-bold" style={{ color: char.color_hex }}>{char.name.charAt(0)}</span>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-base text-slate-800">{char.name}</h3>
                    <p className="text-sm text-slate-500 italic">{char.title}</p>
                    <p className="text-xs text-slate-400 mt-1">{char.biblical_reference}</p>
                    <div className="flex gap-1.5 mt-2 flex-wrap">
                      <RarityBadge rarity={char.rarity as RarityType} />
                      {char.is_sacred && <span className="text-xs px-2 py-0.5 rounded-full bg-yellow-100 text-yellow-800 border border-yellow-300">🙏 Sagrado</span>}
                      {!char.is_active && <span className="text-xs px-2 py-0.5 rounded-full bg-gray-100 text-gray-600">Inativo</span>}
                    </div>
                  </div>
                </div>

                <div className="text-xs text-slate-400 mb-1">💬 {char.dialogues?.length || 0} diálogo(s)</div>
                <div className="text-xs text-slate-400 mb-3">🔓 {formatUnlockCondition(char.unlock_condition || { type: 'default' })}</div>

                {/* Actions */}
                <div className="flex items-center gap-2 pt-3 border-t">
                  <label className="relative inline-flex items-center cursor-pointer" title={char.is_active ? 'Ativo' : 'Inativo'}>
                    <input type="checkbox" checked={char.is_active} onChange={() => setToggleId(char.id || char._id)} disabled={char.is_sacred} className="sr-only peer" />
                    <div className="w-9 h-5 bg-gray-200 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-green-500" />
                  </label>
                  <span className="text-xs text-slate-400 flex-1">{char.is_active ? 'Ativo' : 'Inativo'}</span>
                  <Button variant="ghost" size="icon" onClick={() => openEdit(char)} title="Editar"><Pencil className="h-4 w-4" /></Button>
                  <Button variant="ghost" size="icon" onClick={() => setDeleteTarget({ id: char.id || char._id, name: char.name })} disabled={char.is_sacred} title={char.is_sacred ? 'Sagrados não podem ser excluídos' : 'Excluir'}>
                    <Trash2 className="h-4 w-4 text-destructive" />
                  </Button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Form Dialog */}
      <Dialog open={isFormOpen} onOpenChange={setIsFormOpen}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingChar ? 'Editar Personagem' : 'Novo Personagem'}</DialogTitle>
          </DialogHeader>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 pt-4">
            {/* Seção 1: Identidade */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Nome *</label>
                <Input {...form.register('name')} />
                {form.formState.errors.name && <span className="text-xs text-red-500">{form.formState.errors.name.message}</span>}
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Título *</label>
                <Input {...form.register('title')} placeholder="ex: O Corajoso" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Referência Bíblica *</label>
                <Input {...form.register('biblical_reference')} placeholder="ex: Números 13-14" />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Cor Destaque *</label>
                <div className="flex gap-2">
                  <input type="color" {...form.register('color_hex')} className="h-10 w-10 p-1 border rounded" />
                  <Input {...form.register('color_hex')} className="flex-1" />
                </div>
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">História * <span className="text-slate-400 font-normal">({storyLen}/1000)</span></label>
              <textarea {...form.register('biblical_story')} maxLength={1000} className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2" />
              {form.formState.errors.biblical_story && <span className="text-xs text-red-500">{form.formState.errors.biblical_story.message}</span>}
            </div>

            {/* Seção 2: Visual */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Sprite URL *</label>
                <Input {...form.register('sprite_url')} />
                {form.watch('sprite_url') && <img src={form.watch('sprite_url')} alt="Preview" className="w-16 h-20 object-cover rounded border mt-1" onError={e => (e.currentTarget.style.display = 'none')} />}
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Lottie Idle URL</label>
                <Input {...form.register('lottie_idle_url')} />
                <label className="text-sm font-medium mt-2 block">Lottie Happy URL</label>
                <Input {...form.register('lottie_happy_url')} />
                <label className="text-sm font-medium mt-2 block">Lottie Sad URL</label>
                <Input {...form.register('lottie_sad_url')} />
              </div>
            </div>

            {/* Seção 3: Configuração de Jogo */}
            <div className="grid grid-cols-2 gap-4 p-4 border rounded-md bg-slate-50/50">
              <div className="space-y-3">
                <div className="space-y-1">
                  <label className="text-sm font-medium">Raridade</label>
                  <select {...form.register('rarity')} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                    <option value="common">⚪ Comum</option>
                    <option value="uncommon">🟢 Incomum</option>
                    <option value="rare">🔵 Raro</option>
                    <option value="epic">🟣 Épico</option>
                    <option value="special">⭐ Especial</option>
                  </select>
                </div>
                <div className="space-y-1">
                  <label className="text-sm font-medium">Ordem</label>
                  <Input type="number" min={0} {...form.register('sort_order')} />
                </div>
              </div>
              <div className="space-y-3">
                <div className="space-y-1">
                  <label className="text-sm font-medium">Condição de Desbloqueio</label>
                  <select {...form.register('unlock_condition.type')} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                    <option value="default">Padrão (liberado)</option>
                    <option value="level">Por Nível</option>
                    <option value="trail_complete">Após Trilha</option>
                    <option value="streak">Streak de Dias</option>
                    <option value="achievement">Conquista</option>
                  </select>
                </div>
                {form.watch('unlock_condition.type') !== 'default' && (
                  <div className="space-y-1">
                    <label className="text-xs text-slate-500">Valor</label>
                    <Input {...form.register('unlock_condition.value')} placeholder="ID da trilha, dias, etc." />
                  </div>
                )}
              </div>
            </div>

            {/* Flags */}
            <div className="flex gap-6">
              <label className="flex items-center gap-2">
                <input type="checkbox" {...form.register('is_active')} className="rounded" />
                <span className="text-sm font-medium">Ativo (visível no app)</span>
              </label>
              <label className="flex items-center gap-2 border p-2 bg-amber-50 rounded">
                <input type="checkbox" {...form.register('is_sacred')} className="rounded" />
                <span className="text-sm font-medium text-amber-700">🙏 Sagrado (não pode ser excluído)</span>
              </label>
            </div>

            {/* Seção 4: Diálogos */}
            <div className="border p-4 rounded-md space-y-3">
              <div className="flex justify-between items-center">
                <h4 className="text-sm font-bold">Diálogos</h4>
                <Button type="button" variant="outline" size="sm" onClick={() => append({ type: 'greeting', text: '' })}>+ Adicionar</Button>
              </div>
              {fields.map((field, index) => (
                <div key={field.id} className="flex gap-2 items-start">
                  <select {...form.register(`dialogues.${index}.type`)} className="w-40 rounded-md border text-xs px-2 py-2">
                    <option value="greeting">Saudação</option>
                    <option value="lesson_start">Início Lição</option>
                    <option value="correct">Acerto</option>
                    <option value="wrong">Erro</option>
                    <option value="lesson_complete">Fim Lição</option>
                    <option value="streak_warning">Aviso Streak</option>
                    <option value="streak_broken">Streak Perdida</option>
                    <option value="level_up">Level Up</option>
                  </select>
                  <Input {...form.register(`dialogues.${index}.text`)} className="flex-1" placeholder="Texto da fala" maxLength={300} />
                  <Button type="button" variant="ghost" size="sm" onClick={() => remove(index)} className="text-red-400">X</Button>
                </div>
              ))}
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
        isOpen={!!deleteTarget}
        onOpenChange={(v) => !v && setDeleteTarget(null)}
        title={`Excluir "${deleteTarget?.name}"?`}
        description="Esta ação não pode ser desfeita. O personagem será removido permanentemente."
        confirmText="Sim, excluir"
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
        isLoading={deleteMutation.isPending}
      />

      {/* Toggle Confirmation */}
      <ConfirmDialog
        isOpen={!!toggleId}
        onOpenChange={(v) => !v && setToggleId(null)}
        title="Alternar status do personagem"
        description="Se desativar, usuários não poderão usá-lo em lições. Confirmar?"
        confirmText="Confirmar"
        variant="default"
        onConfirm={() => toggleId && toggleMutation.mutate(toggleId)}
        isLoading={toggleMutation.isPending}
      />
    </div>
  );
}
