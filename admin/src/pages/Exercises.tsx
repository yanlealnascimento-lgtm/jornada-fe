import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../services/api';
import { Plus, Edit2, Trash2, Puzzle, RefreshCw } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../components/ui/dialog';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { EmptyState } from '../components/EmptyState';
import { toast } from 'sonner';
import { useForm, Controller } from 'react-hook-form';

// ─── Types ────────────────────────────────────────────────────────────────────

type ExType = 'multiple_choice' | 'true_false' | 'fill_blank' | 'emoji_guess' | 'audio_recite';

interface Exercise {
  id: string;
  _id?: string;
  type: ExType;
  question: string;
  options_text: string[];
  correct_answer: string;
  explanation: string;
  verse_reference?: string;
  emoji_hint?: string;
  level: number;
  pf_reward: number;
  is_active: boolean;
  is_premium: boolean;
  order: number;
}

interface ExForm {
  type: ExType;
  question: string;
  options_text: string; // comma-separated
  correct_answer: string;
  explanation: string;
  verse_reference: string;
  emoji_hint: string;
  level: number;
  pf_reward: number;
  order: number;
  is_active: boolean;
  is_premium: boolean;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

const TYPE_LABELS: Record<ExType, string> = {
  multiple_choice: 'Múltipla Escolha',
  true_false: 'Verdadeiro/Falso',
  fill_blank: 'Complete o Versículo',
  emoji_guess: 'Adivinhe pelos Emojis',
  audio_recite: 'Recitação por Áudio',
};

const TYPE_COLORS: Record<ExType, string> = {
  multiple_choice: 'bg-blue-100 text-blue-800 border-blue-200',
  true_false: 'bg-green-100 text-green-800 border-green-200',
  fill_blank: 'bg-purple-100 text-purple-800 border-purple-200',
  emoji_guess: 'bg-yellow-100 text-yellow-800 border-yellow-200',
  audio_recite: 'bg-pink-100 text-pink-800 border-pink-200',
};

const TYPE_EMOJI: Record<ExType, string> = {
  multiple_choice: '🔵',
  true_false: '✅',
  fill_blank: '✏️',
  emoji_guess: '😀',
  audio_recite: '🎤',
};

// ─── Form Modal ───────────────────────────────────────────────────────────────

function ExerciseFormModal({
  isOpen,
  onClose,
  editingItem,
  onSubmit,
  isLoading,
}: {
  isOpen: boolean;
  onClose: () => void;
  editingItem: Exercise | null;
  onSubmit: (data: ExForm) => void;
  isLoading: boolean;
}) {
  const { register, handleSubmit, control, watch, reset, formState: { errors } } = useForm<ExForm>({
    defaultValues: editingItem
      ? {
          ...editingItem,
          options_text: editingItem.options_text?.join(', ') ?? '',
          verse_reference: editingItem.verse_reference ?? '',
          emoji_hint: editingItem.emoji_hint ?? '',
        }
      : {
          type: 'multiple_choice',
          question: '',
          options_text: '',
          correct_answer: '',
          explanation: '',
          verse_reference: '',
          emoji_hint: '',
          level: 1,
          pf_reward: 10,
          order: 1,
          is_active: true,
          is_premium: false,
        },
  });

  React.useEffect(() => {
    if (isOpen) {
      reset(editingItem
        ? { ...editingItem, options_text: editingItem.options_text?.join(', ') ?? '', verse_reference: editingItem.verse_reference ?? '', emoji_hint: editingItem.emoji_hint ?? '' }
        : { type: 'multiple_choice', question: '', options_text: '', correct_answer: '', explanation: '', verse_reference: '', emoji_hint: '', level: 1, pf_reward: 10, order: 1, is_active: true, is_premium: false }
      );
    }
  }, [isOpen, editingItem, reset]);

  const watchType = watch('type');

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{editingItem ? '✏️ Editar Exercício' : '➕ Novo Exercício'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 mt-2">
          {/* Tipo */}
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Tipo *</label>
            <Controller
              name="type"
              control={control}
              render={({ field }) => (
                <select {...field} className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm">
                  {(Object.entries(TYPE_LABELS) as [ExType, string][]).map(([k, v]) => (
                    <option key={k} value={k}>{TYPE_EMOJI[k]} {v}</option>
                  ))}
                </select>
              )}
            />
          </div>

          {/* Pergunta */}
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Pergunta *</label>
            <textarea
              {...register('question', { required: 'Obrigatório' })}
              className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm resize-none"
              rows={3}
              placeholder="Ex: Quem foi o primeiro homem criado por Deus?"
            />
            {errors.question && <p className="text-red-500 text-xs mt-1">{errors.question.message}</p>}
          </div>

          {/* Emoji Hint — apenas para emoji_guess */}
          {watchType === 'emoji_guess' && (
            <div>
              <label className="text-xs font-bold text-slate-600 mb-1 block">Emojis de dica *</label>
              <Input {...register('emoji_hint')} placeholder="🪵🌊🕊️🌈" />
            </div>
          )}

          {/* Opções */}
          {watchType !== 'audio_recite' && (
            <div>
              <label className="text-xs font-bold text-slate-600 mb-1 block">
                Opções (separadas por vírgula) *
              </label>
              <Input
                {...register('options_text', { required: watchType !== 'audio_recite' ? 'Obrigatório' : false })}
                placeholder="Gênesis, Êxodo, Levítico, Números"
              />
              {errors.options_text && <p className="text-red-500 text-xs mt-1">{errors.options_text.message}</p>}
            </div>
          )}

          {/* Resposta Correta */}
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Resposta Correta *</label>
            <Input
              {...register('correct_answer', { required: 'Obrigatório' })}
              placeholder="Ex: Gênesis"
            />
            {errors.correct_answer && <p className="text-red-500 text-xs mt-1">{errors.correct_answer.message}</p>}
          </div>

          {/* Explicação */}
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Explicação *</label>
            <Input
              {...register('explanation', { required: 'Obrigatório' })}
              placeholder="Breve explicação exibida após a resposta"
            />
            {errors.explanation && <p className="text-red-500 text-xs mt-1">{errors.explanation.message}</p>}
          </div>

          {/* Referência Bíblica */}
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Referência Bíblica</label>
            <Input {...register('verse_reference')} placeholder="Ex: Gênesis 1:1" />
          </div>

          {/* Nível / PF / Ordem */}
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="text-xs font-bold text-slate-600 mb-1 block">Nível</label>
              <Input type="number" {...register('level', { valueAsNumber: true, min: 1 })} min={1} />
            </div>
            <div>
              <label className="text-xs font-bold text-slate-600 mb-1 block">PF</label>
              <Input type="number" {...register('pf_reward', { valueAsNumber: true, min: 0 })} min={0} />
            </div>
            <div>
              <label className="text-xs font-bold text-slate-600 mb-1 block">Ordem</label>
              <Input type="number" {...register('order', { valueAsNumber: true, min: 1 })} min={1} />
            </div>
          </div>

          {/* Flags */}
          <div className="flex gap-6">
            <label className="flex items-center gap-2 text-sm cursor-pointer">
              <input type="checkbox" {...register('is_active')} className="rounded" />
              <span>Ativo</span>
            </label>
            <label className="flex items-center gap-2 text-sm cursor-pointer">
              <input type="checkbox" {...register('is_premium')} className="rounded" />
              <span>💎 Premium</span>
            </label>
          </div>

          {/* Actions */}
          <div className="flex justify-end gap-3 pt-2 border-t border-slate-100">
            <Button type="button" variant="outline" onClick={onClose}>Cancelar</Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading ? 'Salvando...' : editingItem ? 'Salvar Alterações' : 'Criar Exercício'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export function ExercisesBoard() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [filterType, setFilterType] = useState<ExType | 'all'>('all');
  const [filterPremium, setFilterPremium] = useState<'all' | 'free' | 'premium'>('all');
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<Exercise | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  // Fetch
  const { data: fetchResult, isLoading } = useQuery({
    queryKey: ['exercises'],
    queryFn: () => api.get('/exercises?limit=200').catch(() => ({ data: { items: [] } })),
  });
  const rawData = (fetchResult as any)?.data ?? {};
  const exercises: Exercise[] = (rawData.items ?? []).map((e: any) => ({ ...e, id: e._id ?? e.id }));

  // Filtered
  const filtered = exercises.filter((ex) => {
    const matchType = filterType === 'all' || ex.type === filterType;
    const matchPremium = filterPremium === 'all' || (filterPremium === 'premium' && ex.is_premium) || (filterPremium === 'free' && !ex.is_premium);
    const matchSearch = search === '' || ex.question.toLowerCase().includes(search.toLowerCase()) || (ex.verse_reference ?? '').toLowerCase().includes(search.toLowerCase());
    return matchType && matchPremium && matchSearch;
  });

  // Stats
  const stats = (Object.keys(TYPE_LABELS) as ExType[]).map((type) => ({
    type,
    total: exercises.filter((e) => e.type === type).length,
    premium: exercises.filter((e) => e.type === type && e.is_premium).length,
  }));

  // Mutations
  const createMutation = useMutation({
    mutationFn: (data: any) => api.post('/exercises', data),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['exercises'] }); setIsFormOpen(false); toast.success('✅ Exercício criado!'); },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => api.put(`/exercises/${id}`, data),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['exercises'] }); setIsFormOpen(false); toast.success('✅ Exercício atualizado!'); },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/exercises/${id}`),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['exercises'] }); toast.success('🗑 Exercício removido.'); },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const seedMutation = useMutation({
    mutationFn: () => api.post('/exercises/seed', {}),
    onSuccess: (r: any) => {
      queryClient.invalidateQueries({ queryKey: ['exercises'] });
      toast.success(`✅ Seed: ${r?.data?.created ?? '?'} criados, ${r?.data?.skipped ?? '?'} ignorados.`);
    },
    onError: (e: any) => toast.error(`Erro no seed: ${e.message}`),
  });

  function toPayload(form: ExForm) {
    return {
      ...form,
      options_text: form.options_text ? form.options_text.split(',').map((s) => s.trim()).filter(Boolean) : [],
      verse_reference: form.verse_reference || undefined,
      emoji_hint: form.emoji_hint || undefined,
    };
  }

  function handleSubmit(form: ExForm) {
    const payload = toPayload(form);
    if (editingItem) {
      updateMutation.mutate({ id: editingItem.id, data: payload });
    } else {
      createMutation.mutate(payload);
    }
  }

  function openEdit(item: Exercise) {
    setEditingItem(item);
    setIsFormOpen(true);
  }

  function openCreate() {
    setEditingItem(null);
    setIsFormOpen(true);
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-800">Exercícios</h1>
          <p className="text-sm text-slate-500 mt-1">{exercises.length} exercícios no banco de dados</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending}>
            <RefreshCw size={16} className={`mr-2 ${seedMutation.isPending ? 'animate-spin' : ''}`} />
            Seed Dados
          </Button>
          <Button onClick={openCreate}>
            <Plus size={16} className="mr-2" /> Novo Exercício
          </Button>
        </div>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        {stats.map((s) => (
          <div
            key={s.type}
            onClick={() => setFilterType(filterType === s.type ? 'all' : s.type)}
            className={`bg-white rounded-xl border-2 p-4 cursor-pointer transition-all hover:shadow-md ${filterType === s.type ? 'border-blue-500 shadow-md' : 'border-slate-100'}`}
          >
            <div className="text-2xl mb-1">{TYPE_EMOJI[s.type]}</div>
            <div className="text-xl font-black text-slate-800">{s.total}</div>
            <div className="text-xs font-semibold text-slate-600 leading-tight">{TYPE_LABELS[s.type]}</div>
            {s.premium > 0 && <div className="text-[10px] text-amber-600 font-bold mt-1">💎 {s.premium} premium</div>}
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        <Input placeholder="Buscar por pergunta ou versículo..." value={search} onChange={(e) => setSearch(e.target.value)} className="max-w-xs" />
        <div className="flex gap-2">
          {(['all', 'free', 'premium'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilterPremium(f)}
              className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${filterPremium === f ? 'bg-slate-800 text-white border-slate-800' : 'bg-white text-slate-600 border-slate-200 hover:border-slate-400'}`}
            >
              {f === 'all' ? 'Todos' : f === 'free' ? '🆓 Gratuito' : '💎 Premium'}
            </button>
          ))}
        </div>
        <span className="text-sm text-slate-400 ml-auto">{filtered.length} exercício(s)</span>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {isLoading ? (
          <div className="text-center py-12 text-slate-400">Carregando...</div>
        ) : filtered.length === 0 ? (
          <EmptyState
            icon={Puzzle}
            title="Nenhum exercício encontrado"
            description={exercises.length === 0 ? 'Clique em "Seed Dados" para importar os exercícios mockados ou crie um novo.' : 'Tente ajustar os filtros.'}
          />
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="bg-slate-50">
                  <TableHead className="w-12">#</TableHead>
                  <TableHead className="w-40">Tipo</TableHead>
                  <TableHead>Pergunta</TableHead>
                  <TableHead className="w-28">Versículo</TableHead>
                  <TableHead className="w-24">Nível / PF</TableHead>
                  <TableHead>Opções</TableHead>
                  <TableHead className="w-32">Resposta</TableHead>
                  <TableHead className="w-20 text-center">Acesso</TableHead>
                  <TableHead className="w-20 text-center">Status</TableHead>
                  <TableHead className="w-24 text-center">Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.map((ex) => (
                  <TableRow key={ex.id} className="hover:bg-slate-50">
                    <TableCell className="text-slate-400 font-mono text-xs">{ex.order}</TableCell>
                    <TableCell>
                      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-bold border ${TYPE_COLORS[ex.type]}`}>
                        {TYPE_EMOJI[ex.type]} {TYPE_LABELS[ex.type]}
                      </span>
                    </TableCell>
                    <TableCell>
                      <div className="font-medium text-slate-800 max-w-xs line-clamp-2 text-sm">{ex.question}</div>
                      {ex.emoji_hint && <div className="text-lg mt-1 tracking-widest">{ex.emoji_hint}</div>}
                    </TableCell>
                    <TableCell className="text-xs text-slate-500">{ex.verse_reference ?? '—'}</TableCell>
                    <TableCell>
                      <div className="text-xs">
                        <span className="font-bold text-slate-700">Nv. {ex.level}</span>
                        <span className="text-slate-400 ml-1">· {ex.pf_reward} PF</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-wrap gap-1 max-w-[180px]">
                        {(ex.options_text ?? []).map((opt) => (
                          <span
                            key={opt}
                            className={`px-1.5 py-0.5 rounded text-xs border ${opt === ex.correct_answer ? 'bg-green-50 text-green-700 border-green-300 font-bold' : 'bg-slate-50 text-slate-500 border-slate-200'}`}
                          >
                            {opt}
                          </span>
                        ))}
                        {ex.type === 'audio_recite' && <span className="text-slate-400 text-xs italic">livre</span>}
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="font-bold text-green-700 text-xs bg-green-50 border border-green-200 px-1.5 py-0.5 rounded">
                        ✓ {(ex.correct_answer ?? '').length > 30 ? ex.correct_answer.slice(0, 30) + '…' : ex.correct_answer}
                      </span>
                    </TableCell>
                    <TableCell className="text-center">
                      {ex.is_premium ? <span className="text-amber-600 font-bold text-xs">💎</span> : <span className="text-slate-400 text-xs">🆓</span>}
                    </TableCell>
                    <TableCell className="text-center">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${ex.is_active ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-400'}`}>
                        {ex.is_active ? 'Ativo' : 'Inativo'}
                      </span>
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1 justify-center">
                        <button onClick={() => openEdit(ex)} className="p-1.5 rounded hover:bg-slate-100 text-slate-500 hover:text-blue-600 transition-colors" title="Editar">
                          <Edit2 size={14} />
                        </button>
                        <button onClick={() => setDeleteId(ex.id)} className="p-1.5 rounded hover:bg-red-50 text-slate-500 hover:text-red-600 transition-colors" title="Excluir">
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {/* Form Modal */}
      <ExerciseFormModal
        isOpen={isFormOpen}
        onClose={() => setIsFormOpen(false)}
        editingItem={editingItem}
        onSubmit={handleSubmit}
        isLoading={createMutation.isPending || updateMutation.isPending}
      />

      {/* Confirm Delete */}
      <ConfirmDialog
        isOpen={!!deleteId}
        onOpenChange={(v) => !v && setDeleteId(null)}
        title="Excluir exercício?"
        description="Esta ação não pode ser desfeita."
        onConfirm={() => { if (deleteId) { deleteMutation.mutate(deleteId); setDeleteId(null); } }}
      />
    </div>
  );
}
