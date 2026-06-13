import React, { useState, useMemo } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { unitsService, lessonsService, Unit, Lesson } from '../services/units.service';
import { api } from '../services/api';
import {
  Plus, Trash2, Pencil, ArrowLeft, ChevronDown, ChevronRight,
  GraduationCap, Puzzle, Link2, Unlink, Search, Check, Layers,
} from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { toast } from 'sonner';

// ─── Schemas ──────────────────────────────────────────────────────────────────

const unitSchema = z.object({
  title: z.string().min(2, 'Obrigatório'),
  description: z.string().optional(),
  color_hex: z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'Cor inválida (#XXXXXX)'),
  icon_name: z.string().optional(),
  is_published: z.boolean().default(true),
});
type UnitForm = z.infer<typeof unitSchema>;

const lessonSchema = z.object({
  title: z.string().min(2, 'Obrigatório'),
  subtitle: z.string().optional(),
  lesson_type: z.enum(['standard', 'review', 'challenge', 'story']),
  pf_reward: z.preprocess(v => Number(v), z.number().min(0)),
  pf_perfect_bonus: z.preprocess(v => Number(v), z.number().min(0)),
  estimated_minutes: z.preprocess(v => Number(v), z.number().min(1)),
  is_published: z.boolean().default(true),
});
type LessonForm = z.infer<typeof lessonSchema>;

const COLORS = ['#4A90E2', '#58CC02', '#FF9600', '#8B5CF6', '#EC4899', '#EF4444', '#22C55E', '#0EA5E9', '#D4A017', '#6366F1'];
const LESSON_TYPES: Record<string, string> = { standard: 'Padrão', review: 'Revisão', challenge: 'Desafio', story: 'História' };

type ExType = 'multiple_choice' | 'true_false' | 'fill_blank' | 'emoji_guess' | 'audio_recite';
const TYPE_LABELS: Record<string, string> = { multiple_choice: 'Múltipla Escolha', fill_blank: 'Preencher Lacuna', sort_words: 'Ordenar Palavras', pair_match: 'Combinar Pares', true_false: 'V ou F', emoji_guess: 'Emoji', audio_recite: 'Áudio' };
const TYPE_EMOJI: Record<string, string> = { multiple_choice: '🔵', true_false: '✅', fill_blank: '✏️', emoji_guess: '😀', audio_recite: '🎤' };
const TYPE_COLORS: Record<string, string> = { multiple_choice: 'bg-blue-100 text-blue-800', true_false: 'bg-green-100 text-green-800', fill_blank: 'bg-purple-100 text-purple-800', emoji_guess: 'bg-yellow-100 text-yellow-800', audio_recite: 'bg-pink-100 text-pink-800' };

// ─── Exercise Form (reused from Exercises page) ─────────────────────────────

interface ExForm {
  type: ExType;
  question: string;
  options_text: string;
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

function ExerciseFormModal({ isOpen, onClose, editingItem, onSubmit, isLoading }: {
  isOpen: boolean; onClose: () => void; editingItem: any | null; onSubmit: (data: ExForm) => void; isLoading: boolean;
}) {
  const { register, handleSubmit, control, watch, reset, formState: { errors } } = useForm<ExForm>({
    defaultValues: { type: 'multiple_choice', question: '', options_text: '', correct_answer: '', explanation: '', verse_reference: '', emoji_hint: '', level: 1, pf_reward: 10, order: 1, is_active: true, is_premium: false },
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
          <DialogTitle>{editingItem ? 'Editar Exercício' : 'Novo Exercício'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 mt-2">
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Tipo *</label>
            <Controller name="type" control={control} render={({ field }) => (
              <select {...field} className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm">
                {Object.entries(TYPE_LABELS).filter(([k]) => ['multiple_choice','true_false','fill_blank','emoji_guess','audio_recite'].includes(k)).map(([k, v]) => (
                  <option key={k} value={k}>{TYPE_EMOJI[k] || ''} {v}</option>
                ))}
              </select>
            )} />
          </div>
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Pergunta *</label>
            <textarea {...register('question', { required: 'Obrigatório' })} className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm resize-none" rows={3} />
            {errors.question && <p className="text-red-500 text-xs mt-1">{errors.question.message}</p>}
          </div>
          {watchType === 'emoji_guess' && (
            <div>
              <label className="text-xs font-bold text-slate-600 mb-1 block">Emojis de dica *</label>
              <Input {...register('emoji_hint')} placeholder="🪵🌊🕊️🌈" />
            </div>
          )}
          {watchType !== 'audio_recite' && (
            <div>
              <label className="text-xs font-bold text-slate-600 mb-1 block">Opções (separadas por vírgula) *</label>
              <Input {...register('options_text', { required: watchType !== 'audio_recite' ? 'Obrigatório' : false })} placeholder="Gênesis, Êxodo, Levítico, Números" />
            </div>
          )}
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Resposta Correta *</label>
            <Input {...register('correct_answer', { required: 'Obrigatório' })} />
          </div>
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Explicação *</label>
            <Input {...register('explanation', { required: 'Obrigatório' })} />
          </div>
          <div>
            <label className="text-xs font-bold text-slate-600 mb-1 block">Referência Bíblica</label>
            <Input {...register('verse_reference')} placeholder="Ex: Gênesis 1:1" />
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div><label className="text-xs font-bold text-slate-600 mb-1 block">Nível</label><Input type="number" {...register('level', { valueAsNumber: true, min: 1 })} min={1} /></div>
            <div><label className="text-xs font-bold text-slate-600 mb-1 block">PF</label><Input type="number" {...register('pf_reward', { valueAsNumber: true, min: 0 })} min={0} /></div>
            <div><label className="text-xs font-bold text-slate-600 mb-1 block">Ordem</label><Input type="number" {...register('order', { valueAsNumber: true, min: 1 })} min={1} /></div>
          </div>
          <div className="flex gap-6">
            <label className="flex items-center gap-2 text-sm cursor-pointer"><input type="checkbox" {...register('is_active')} className="rounded" /> Ativo</label>
            <label className="flex items-center gap-2 text-sm cursor-pointer"><input type="checkbox" {...register('is_premium')} className="rounded" /> Premium</label>
          </div>
          <div className="flex justify-end gap-3 pt-2 border-t">
            <Button type="button" variant="outline" onClick={onClose}>Cancelar</Button>
            <Button type="submit" disabled={isLoading}>{isLoading ? 'Salvando...' : 'Salvar'}</Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

// ─── Stages Editor Component ─────────────────────────────────────────────────

function StagesEditor({ stagesCount, setStagesCount, stageAssignments, setStageAssignments, linkedExercises, onSave, isSaving }: {
  stagesCount: number;
  setStagesCount: (n: number) => void;
  stageAssignments: Record<number, string[]>;
  setStageAssignments: React.Dispatch<React.SetStateAction<Record<number, string[]>>>;
  linkedExercises: any[];
  onSave: () => void;
  isSaving: boolean;
}) {
  const allAssigned = Object.values(stageAssignments).flat();

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <span className="text-sm font-bold text-slate-600">Número de etapas:</span>
        <div className="flex gap-1">
          {[3, 4, 5].map(n => (
            <button key={n} onClick={() => setStagesCount(n)}
              className={`w-10 h-10 rounded-lg text-sm font-bold transition-all ${stagesCount === n ? 'bg-indigo-600 text-white shadow-md' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}
            >{n}</button>
          ))}
        </div>
        <div className="flex-1" />
        <Button size="sm" className="gap-1" onClick={onSave} disabled={isSaving}>
          {isSaving ? 'Salvando...' : 'Salvar Etapas'}
        </Button>
      </div>

      <p className="text-xs text-slate-400">Selecione exercícios para cada etapa. Exercícios sem etapa serão distribuídos automaticamente pelo app.</p>

      {Array.from({ length: stagesCount }, (_, stageIdx) => {
        const stageExIds = stageAssignments[stageIdx] || [];
        const stageExercises = linkedExercises.filter(ex => stageExIds.includes(ex.id || ex._id));
        const unassigned = linkedExercises.filter(ex => !allAssigned.includes(ex.id || ex._id));

        return (
          <div key={stageIdx} className="border border-slate-200 rounded-lg overflow-hidden">
            <div className="flex items-center gap-3 p-3 bg-slate-50">
              <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold bg-indigo-100 text-indigo-700">{stageIdx + 1}</div>
              <span className="text-sm font-bold text-slate-700">Etapa {stageIdx + 1}</span>
              <span className="text-xs text-slate-400">{stageExercises.length} exercício(s)</span>
            </div>
            <div className="p-3 space-y-1.5">
              {stageExercises.map((ex, ei) => (
                <div key={ex.id || ex._id} className="flex items-center gap-2 bg-white rounded border border-slate-100 px-3 py-2">
                  <span className="w-5 h-5 rounded text-[10px] font-bold flex items-center justify-center bg-indigo-100 text-indigo-700">{ei + 1}</span>
                  <div className="flex-1 min-w-0">
                    <div className="text-xs font-medium text-slate-700 truncate">{ex.question}</div>
                    <div className="text-[10px] text-slate-400">{TYPE_LABELS[ex.type] || ex.type}</div>
                  </div>
                  <Button variant="ghost" size="icon" className="h-6 w-6 text-red-400" title="Remover da etapa"
                    onClick={() => setStageAssignments(prev => ({ ...prev, [stageIdx]: (prev[stageIdx] || []).filter(id => id !== (ex.id || ex._id)) }))}
                  ><Trash2 className="h-3 w-3" /></Button>
                </div>
              ))}
              {unassigned.length > 0 && (
                <select className="w-full border border-dashed border-slate-300 rounded-lg px-3 py-2 text-xs text-slate-500 bg-transparent hover:border-indigo-300 cursor-pointer" value=""
                  onChange={e => { const id = e.target.value; if (id) setStageAssignments(prev => ({ ...prev, [stageIdx]: [...(prev[stageIdx] || []), id] })); }}
                >
                  <option value="">+ Adicionar exercício...</option>
                  {unassigned.map(ex => (
                    <option key={ex.id || ex._id} value={ex.id || ex._id}>{(TYPE_EMOJI[ex.type] || '')} {ex.question?.substring(0, 60)}</option>
                  ))}
                </select>
              )}
              {stageExercises.length === 0 && unassigned.length === 0 && (
                <p className="text-xs text-slate-300 text-center py-2">Vincule exercícios primeiro</p>
              )}
            </div>
          </div>
        );
      })}

      <div className="flex items-center gap-2 text-xs text-slate-500 bg-slate-50 rounded-lg p-3">
        <Layers size={14} />
        <span><strong>{allAssigned.length}</strong> de <strong>{linkedExercises.length}</strong> exercícios atribuídos
          {linkedExercises.length > allAssigned.length && (
            <span className="text-amber-500 ml-1">({linkedExercises.length - allAssigned.length} sem etapa)</span>
          )}
        </span>
      </div>
    </div>
  );
}

// ─── Main Component ──────────────────────────────────────────────────────────

export function TrailDetail() {
  const { trailId } = useParams<{ trailId: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [expandedUnit, setExpandedUnit] = useState<string | null>(null);
  const [unitFormOpen, setUnitFormOpen] = useState(false);
  const [editingUnit, setEditingUnit] = useState<Unit | null>(null);
  const [lessonFormOpen, setLessonFormOpen] = useState(false);
  const [editingLesson, setEditingLesson] = useState<Lesson | null>(null);
  const [activeUnitId, setActiveUnitId] = useState<string>('');
  const [deleteTarget, setDeleteTarget] = useState<{ type: 'unit' | 'lesson' | 'exercise'; id: string } | null>(null);

  // Exercise management dialog
  const [exerciseDialogOpen, setExerciseDialogOpen] = useState(false);
  const [exerciseDialogLessonId, setExerciseDialogLessonId] = useState('');
  const [exerciseDialogLessonTitle, setExerciseDialogLessonTitle] = useState('');
  const [exerciseSearch, setExerciseSearch] = useState('');
  const [exerciseTab, setExerciseTab] = useState<'linked' | 'all' | 'stages'>('linked');
  const [exerciseFormOpen, setExerciseFormOpen] = useState(false);
  const [editingExercise, setEditingExercise] = useState<any | null>(null);
  const [selectedForLink, setSelectedForLink] = useState<Set<string>>(new Set());
  const [stagesCount, setStagesCount] = useState(3);
  const [stageAssignments, setStageAssignments] = useState<Record<number, string[]>>({}); // stageIndex -> exercise_ids

  // ─── Queries ─────────────────────────────────────────────────────────────
  const { data: trailData } = useQuery({
    queryKey: ['trail', trailId],
    queryFn: () => api.get(`/admin/trails/${trailId}`).then((r: any) => r.data || r),
  });
  const { data: unitsData, isLoading: unitsLoading } = useQuery({
    queryKey: ['units', trailId],
    queryFn: () => unitsService.list(trailId!).then((r: any) => r.data || r),
    enabled: !!trailId,
  });
  const trail = trailData;
  const units: Unit[] = useMemo(() => (Array.isArray(unitsData) ? unitsData : []), [unitsData]);

  const { data: lessonsData } = useQuery({
    queryKey: ['lessons', expandedUnit],
    queryFn: () => lessonsService.list(expandedUnit!).then((r: any) => r.data || r),
    enabled: !!expandedUnit,
  });
  const lessons: Lesson[] = useMemo(() => (Array.isArray(lessonsData) ? lessonsData : []), [lessonsData]);

  // Exercises for the dialog
  const { data: linkedExData } = useQuery({
    queryKey: ['exercises-linked', exerciseDialogLessonId],
    queryFn: () => api.get('/admin/exercises', { params: { lesson_id: exerciseDialogLessonId } }).then((r: any) => r.data || r),
    enabled: exerciseDialogOpen && !!exerciseDialogLessonId,
  });
  const linkedExercises: any[] = useMemo(() => (Array.isArray(linkedExData) ? linkedExData : []), [linkedExData]);

  const { data: allExData } = useQuery({
    queryKey: ['exercises-all-global'],
    queryFn: () => api.get('/admin/exercises', { params: { limit: 500 } }).then((r: any) => r.data || r),
    enabled: exerciseDialogOpen && exerciseTab === 'all',
    staleTime: 30_000,
  });
  const allExercisesRaw: any[] = useMemo(() => (Array.isArray(allExData) ? allExData : []), [allExData]);
  // Filter out already-linked exercises and apply search
  const linkedIds = useMemo(() => new Set(linkedExercises.map((e: any) => e.id || e._id)), [linkedExercises]);
  const allExercises: any[] = useMemo(() => {
    const term = exerciseSearch.toLowerCase().trim();
    return allExercisesRaw.filter((ex: any) => {
      const exId = ex.id || ex._id;
      if (linkedIds.has(exId)) return false;
      if (!term) return true;
      return (ex.question || '').toLowerCase().includes(term)
        || (ex.correct_answer || '').toString().toLowerCase().includes(term)
        || (ex.type || '').toLowerCase().includes(term);
    });
  }, [allExercisesRaw, linkedIds, exerciseSearch]);

  // Lesson detail with stages (loaded when stages tab is opened)
  const { data: lessonDetailData } = useQuery({
    queryKey: ['lesson-detail', exerciseDialogLessonId],
    queryFn: () => api.get(`/admin/lessons/${exerciseDialogLessonId}`).then((r: any) => r.data || r),
    enabled: exerciseDialogOpen && !!exerciseDialogLessonId,
  });

  // Load stages from lesson detail when switching to stages tab
  const loadStagesFromLesson = (lessonData: any) => {
    if (!lessonData) return;
    const sc = lessonData.stages_count || lessonData.stages?.length || 3;
    setStagesCount(sc);
    const assignments: Record<number, string[]> = {};
    if (lessonData.stages && lessonData.stages.length > 0) {
      lessonData.stages.forEach((s: any) => {
        assignments[s.stage_index] = (s.exercise_ids || []).map((id: any) => id.toString ? id.toString() : id);
      });
    }
    setStageAssignments(assignments);
  };

  // Save stages mutation
  const saveStagesMutation = useMutation({
    mutationFn: async () => {
      const stages = Array.from({ length: stagesCount }, (_, i) => ({
        stage_index: i,
        exercise_ids: stageAssignments[i] || [],
        stage_type: 'mixed',
      }));
      return api.put(`/admin/lessons/${exerciseDialogLessonId}/stages`, { stages, stages_count: stagesCount });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lesson-detail', exerciseDialogLessonId] });
      invalidateExercises();
      toast.success('Etapas salvas com sucesso');
    },
    onError: (e: any) => toast.error(e.message),
  });

  // ─── Mutations ───────────────────────────────────────────────────────────
  const invalidateAll = () => {
    queryClient.invalidateQueries({ queryKey: ['units', trailId] });
    queryClient.invalidateQueries({ queryKey: ['lessons'] });
    queryClient.invalidateQueries({ queryKey: ['trail', trailId] });
  };
  const invalidateExercises = () => {
    queryClient.invalidateQueries({ queryKey: ['exercises-linked', exerciseDialogLessonId] });
    queryClient.invalidateQueries({ queryKey: ['exercises-all'] });
    queryClient.invalidateQueries({ queryKey: ['lessons', expandedUnit] });
  };

  const createUnitMutation = useMutation({ mutationFn: (data: UnitForm) => unitsService.create({ ...data, trail_id: trailId! } as any), onSuccess: () => { invalidateAll(); setUnitFormOpen(false); toast.success('Unidade criada'); }, onError: (e: any) => toast.error(e.message) });
  const updateUnitMutation = useMutation({ mutationFn: ({ id, data }: { id: string; data: UnitForm }) => unitsService.update(id, data as any), onSuccess: () => { invalidateAll(); setUnitFormOpen(false); toast.success('Unidade atualizada'); }, onError: (e: any) => toast.error(e.message) });
  const deleteUnitMutation = useMutation({ mutationFn: (id: string) => unitsService.delete(id), onSuccess: () => { invalidateAll(); setDeleteTarget(null); toast.success('Unidade removida'); }, onError: (e: any) => toast.error(e.message) });

  const createLessonMutation = useMutation({ mutationFn: (data: LessonForm & { unit_id: string; trail_id: string }) => lessonsService.create(data as any), onSuccess: () => { invalidateAll(); queryClient.invalidateQueries({ queryKey: ['lessons', expandedUnit] }); setLessonFormOpen(false); toast.success('Lição criada'); }, onError: (e: any) => toast.error(e.message) });
  const updateLessonMutation = useMutation({ mutationFn: ({ id, data }: { id: string; data: LessonForm }) => lessonsService.update(id, data as any), onSuccess: () => { invalidateAll(); queryClient.invalidateQueries({ queryKey: ['lessons', expandedUnit] }); setLessonFormOpen(false); toast.success('Lição atualizada'); }, onError: (e: any) => toast.error(e.message) });
  const deleteLessonMutation = useMutation({ mutationFn: (id: string) => lessonsService.delete(id), onSuccess: () => { invalidateAll(); queryClient.invalidateQueries({ queryKey: ['lessons', expandedUnit] }); setDeleteTarget(null); toast.success('Lição removida'); }, onError: (e: any) => toast.error(e.message) });

  const linkExerciseMutation = useMutation({
    mutationFn: ({ exercise_id, lesson_id }: { exercise_id: string; lesson_id: string }) => api.post('/admin/exercises/link', { exercise_id, lesson_id }),
    onSuccess: () => { invalidateExercises(); toast.success('Exercício vinculado'); },
    onError: (e: any) => toast.error(e.message),
  });
  const unlinkExerciseMutation = useMutation({
    mutationFn: (exercise_id: string) => api.post('/admin/exercises/unlink', { exercise_id }),
    onSuccess: () => { invalidateExercises(); toast.success('Exercício desvinculado'); },
    onError: (e: any) => toast.error(e.message),
  });
  const deleteExerciseMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/exercises/${id}`),
    onSuccess: () => { invalidateExercises(); setDeleteTarget(null); toast.success('Exercício removido'); },
    onError: (e: any) => toast.error(e.message),
  });
  const createExerciseMutation = useMutation({
    mutationFn: (data: any) => api.post('/admin/exercises', data),
    onSuccess: () => { invalidateExercises(); setExerciseFormOpen(false); toast.success('Exercício criado e vinculado'); },
    onError: (e: any) => toast.error(e.message),
  });
  const updateExerciseMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => api.put(`/admin/exercises/${id}`, data),
    onSuccess: () => { invalidateExercises(); setExerciseFormOpen(false); toast.success('Exercício atualizado'); },
    onError: (e: any) => toast.error(e.message),
  });

  // Link selected exercises in batch
  const linkSelected = async () => {
    for (const exId of selectedForLink) {
      await api.post('/admin/exercises/link', { exercise_id: exId, lesson_id: exerciseDialogLessonId });
    }
    setSelectedForLink(new Set());
    invalidateExercises();
    toast.success(`${selectedForLink.size} exercício(s) vinculado(s)`);
    setExerciseTab('linked');
  };

  // ─── Forms ───────────────────────────────────────────────────────────────
  const unitForm = useForm<UnitForm>({ resolver: zodResolver(unitSchema), defaultValues: { is_published: true, color_hex: '#4A90E2', icon_name: 'book' } });
  const lessonForm = useForm<LessonForm>({ resolver: zodResolver(lessonSchema), defaultValues: { is_published: true, lesson_type: 'standard', pf_reward: 10, pf_perfect_bonus: 5, estimated_minutes: 5 } });

  const openNewUnit = () => { setEditingUnit(null); unitForm.reset({ is_published: true, color_hex: '#4A90E2', icon_name: 'book', title: '', description: '' }); setUnitFormOpen(true); };
  const openEditUnit = (u: Unit) => { setEditingUnit(u); unitForm.reset({ title: u.title, description: u.description, color_hex: u.color_hex, icon_name: u.icon_name, is_published: u.is_published }); setUnitFormOpen(true); };
  const onSubmitUnit = (data: UnitForm) => { if (editingUnit) updateUnitMutation.mutate({ id: editingUnit.id || editingUnit._id, data }); else createUnitMutation.mutate(data); };

  const openNewLesson = (unitId: string) => { setEditingLesson(null); setActiveUnitId(unitId); lessonForm.reset({ is_published: true, lesson_type: 'standard', pf_reward: 10, pf_perfect_bonus: 5, estimated_minutes: 5, title: '', subtitle: '' }); setLessonFormOpen(true); };
  const openEditLesson = (l: Lesson) => { setEditingLesson(l); setActiveUnitId(l.unit_id); lessonForm.reset({ title: l.title, subtitle: l.subtitle, lesson_type: l.lesson_type as any, pf_reward: l.pf_reward, pf_perfect_bonus: l.pf_perfect_bonus, estimated_minutes: l.estimated_minutes, is_published: l.is_published }); setLessonFormOpen(true); };
  const onSubmitLesson = (data: LessonForm) => { if (editingLesson) updateLessonMutation.mutate({ id: editingLesson.id || editingLesson._id, data }); else createLessonMutation.mutate({ ...data, unit_id: activeUnitId, trail_id: trailId! }); };

  const openExerciseDialog = (lessonId: string, lessonTitle: string) => {
    setExerciseDialogLessonId(lessonId);
    setExerciseDialogLessonTitle(lessonTitle);
    setExerciseTab('linked');
    setExerciseSearch('');
    setSelectedForLink(new Set());
    setStageAssignments({});
    setStagesCount(3);
    setExerciseDialogOpen(true);
  };

  const handleExerciseFormSubmit = (form: ExForm) => {
    const payload = {
      ...form,
      options_text: form.options_text ? form.options_text.split(',').map(s => s.trim()).filter(Boolean) : [],
      verse_reference: form.verse_reference || undefined,
      emoji_hint: form.emoji_hint || undefined,
      lesson_id: exerciseDialogLessonId,
    };
    if (editingExercise) updateExerciseMutation.mutate({ id: editingExercise.id || editingExercise._id, data: payload });
    else createExerciseMutation.mutate(payload);
  };

  const toggleSelect = (id: string) => {
    setSelectedForLink(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  // ─── Render ──────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => navigate('/trails')}><ArrowLeft size={20} /></Button>
        <div className="flex-1">
          <h1 className="text-2xl font-black text-slate-800">{trail?.title || 'Trilha'}</h1>
          <p className="text-sm text-slate-500">{trail?.description || ''}</p>
        </div>
        <div className="flex gap-2 text-sm">
          <span className="bg-blue-50 text-blue-700 px-3 py-1 rounded-lg font-bold">{units.length} unidades</span>
          <span className="bg-green-50 text-green-700 px-3 py-1 rounded-lg font-bold">{units.reduce((s, u) => s + (u.lesson_count || 0), 0)} lições</span>
        </div>
      </div>

      <div className="flex justify-end">
        <Button onClick={openNewUnit}><Plus size={16} className="mr-2" /> Nova Unidade</Button>
      </div>

      {/* Units */}
      {unitsLoading ? (
        <div className="text-center py-12 text-slate-400">Carregando...</div>
      ) : units.length === 0 ? (
        <div className="bg-white border border-dashed border-slate-300 rounded-xl p-12 text-center">
          <GraduationCap size={48} className="mx-auto text-slate-300 mb-4" />
          <h3 className="text-lg font-bold text-slate-600">Nenhuma unidade</h3>
          <p className="text-sm text-slate-400 mt-1 mb-4">Crie unidades para organizar as lições desta trilha</p>
          <Button onClick={openNewUnit}><Plus size={16} className="mr-2" /> Criar Primeira Unidade</Button>
        </div>
      ) : (
        <div className="space-y-3">
          {units.map((unit, idx) => {
            const unitId = unit.id || unit._id;
            const isExpanded = expandedUnit === unitId;
            return (
              <div key={unitId} className="bg-white rounded-xl border border-slate-200 overflow-hidden">
                <div className="flex items-center gap-3 p-4 cursor-pointer hover:bg-slate-50 transition-colors" onClick={() => setExpandedUnit(isExpanded ? null : unitId)}>
                  <div className="w-10 h-10 rounded-lg flex items-center justify-center text-white font-black text-sm" style={{ backgroundColor: unit.color_hex || '#4A90E2' }}>{idx + 1}</div>
                  <div className="flex-1">
                    <div className="font-bold text-slate-800">{unit.title}</div>
                    <div className="text-xs text-slate-400">{unit.description} · {unit.lesson_count || 0} lições</div>
                  </div>
                  {!unit.is_published && <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded font-bold">Rascunho</span>}
                  <div className="flex items-center gap-1">
                    <Button variant="ghost" size="icon" onClick={e => { e.stopPropagation(); openEditUnit(unit); }}><Pencil className="h-4 w-4" /></Button>
                    <Button variant="ghost" size="icon" className="text-destructive" onClick={e => { e.stopPropagation(); setDeleteTarget({ type: 'unit', id: unitId }); }}><Trash2 className="h-4 w-4" /></Button>
                    {isExpanded ? <ChevronDown size={18} className="text-slate-400" /> : <ChevronRight size={18} className="text-slate-400" />}
                  </div>
                </div>

                {isExpanded && (
                  <div className="border-t border-slate-100 bg-slate-50/50 p-4 space-y-2">
                    {lessons.length === 0 ? (
                      <p className="text-sm text-slate-400 text-center py-4">Nenhuma lição nesta unidade</p>
                    ) : lessons.map((lesson, li) => {
                      const lessonId = lesson.id || lesson._id;
                      const hasExercises = (lesson.total_exercises || 0) > 0;
                      return (
                        <div key={lessonId} className="flex items-center gap-3 bg-white rounded-lg border border-slate-100 p-3">
                          <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold" style={{
                            backgroundColor: lesson.lesson_type === 'review' ? '#FEF3C7' : '#EFF6FF',
                            color: lesson.lesson_type === 'review' ? '#92400E' : '#1D4ED8',
                          }}>{li + 1}</div>
                          <div className="flex-1">
                            <div className="font-medium text-sm text-slate-800">{lesson.title}</div>
                            <div className="text-xs text-slate-400">
                              {LESSON_TYPES[lesson.lesson_type] || lesson.lesson_type} · {(lesson as any).exercises_pf_total || lesson.pf_reward} PF · {lesson.estimated_minutes}min
                              {hasExercises && <span className="text-indigo-600 font-bold ml-1">· {lesson.total_exercises} exercícios</span>}
                            </div>
                          </div>
                          {!lesson.is_published && <span className="text-[10px] bg-yellow-100 text-yellow-700 px-1.5 py-0.5 rounded font-bold">Rascunho</span>}
                          <Button
                            variant="ghost"
                            size="icon"
                            className={hasExercises ? 'text-indigo-500' : 'text-orange-400'}
                            title={hasExercises ? `${lesson.total_exercises} exercícios vinculados` : 'Vincular exercícios'}
                            onClick={() => openExerciseDialog(lessonId, lesson.title)}
                          >
                            <Puzzle className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="icon" onClick={() => openEditLesson(lesson)}><Pencil className="h-3.5 w-3.5" /></Button>
                          <Button variant="ghost" size="icon" className="text-destructive" onClick={() => setDeleteTarget({ type: 'lesson', id: lessonId })}><Trash2 className="h-3.5 w-3.5" /></Button>
                        </div>
                      );
                    })}
                    {lessons.length > 0 && (
                      <div className="flex justify-end px-3 py-2">
                        <span className="text-xs font-bold text-indigo-700">
                          Total da unidade: {lessons.reduce((sum, l) => sum + ((l as any).exercises_pf_total || l.pf_reward || 0), 0)} PF
                        </span>
                      </div>
                    )}
                    <Button variant="outline" size="sm" className="w-full mt-2" onClick={() => openNewLesson(unitId)}>
                      <Plus size={14} className="mr-1" /> Nova Lição
                    </Button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* ═══ Exercise Management Dialog ═══ */}
      <Dialog open={exerciseDialogOpen} onOpenChange={setExerciseDialogOpen}>
        <DialogContent className="max-w-4xl max-h-[85vh] flex flex-col p-0">
          <DialogHeader className="px-6 pt-5 pb-3 border-b border-slate-100">
            <DialogTitle className="flex items-center gap-2">
              <Puzzle size={18} className="text-indigo-500" />
              Exercícios — {exerciseDialogLessonTitle}
            </DialogTitle>
          </DialogHeader>

          {/* Tabs */}
          <div className="flex items-center gap-2 px-6 pt-3">
            <button
              onClick={() => setExerciseTab('linked')}
              className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all ${exerciseTab === 'linked' ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}
            >
              Vinculados ({linkedExercises.length})
            </button>
            <button
              onClick={() => setExerciseTab('all')}
              className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all ${exerciseTab === 'all' ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}
            >
              Disponíveis para vincular
            </button>
            <button
              onClick={() => { setExerciseTab('stages'); loadStagesFromLesson(lessonDetailData); }}
              className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all gap-1 flex items-center ${exerciseTab === 'stages' ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}
            >
              <Layers size={12} /> Etapas
            </button>
            <div className="flex-1" />
            <Button size="sm" className="gap-1" onClick={() => { setEditingExercise(null); setExerciseFormOpen(true); }}>
              <Plus size={14} /> Novo Exercício
            </Button>
          </div>

          {/* Content */}
          <div className="flex-1 overflow-auto px-6 py-3">
            {exerciseTab === 'stages' ? (
              /* ═══ Stages Tab ═══ */
              <StagesEditor
                stagesCount={stagesCount}
                setStagesCount={setStagesCount}
                stageAssignments={stageAssignments}
                setStageAssignments={setStageAssignments}
                linkedExercises={linkedExercises}
                onSave={() => saveStagesMutation.mutate()}
                isSaving={saveStagesMutation.isPending}
              />
            ) : exerciseTab === 'linked' ? (
              linkedExercises.length === 0 ? (
                <div className="text-center py-12">
                  <Puzzle size={40} className="mx-auto text-slate-200 mb-3" />
                  <p className="text-sm text-slate-400">Nenhum exercício vinculado a esta lição</p>
                  <p className="text-xs text-slate-300 mt-1">Use a aba "Disponíveis para vincular" ou crie um novo</p>
                </div>
              ) : (<>
                <Table>
                  <TableHeader>
                    <TableRow className="bg-slate-50">
                      <TableHead className="w-12">#</TableHead>
                      <TableHead className="w-32">Tipo</TableHead>
                      <TableHead>Pergunta</TableHead>
                      <TableHead className="w-20">PF</TableHead>
                      <TableHead className="w-24">Resposta</TableHead>
                      <TableHead className="w-28 text-center">Ações</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {linkedExercises.map((ex, i) => (
                      <TableRow key={ex.id || ex._id}>
                        <TableCell className="text-slate-400 text-xs">{i + 1}</TableCell>
                        <TableCell>
                          <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold ${TYPE_COLORS[ex.type] || 'bg-slate-100'}`}>
                            {TYPE_EMOJI[ex.type] || ''} {TYPE_LABELS[ex.type] || ex.type}
                          </span>
                        </TableCell>
                        <TableCell>
                          <div className="text-sm text-slate-700 line-clamp-2">{ex.question}</div>
                        </TableCell>
                        <TableCell className="text-xs font-bold text-green-600">{ex.pf_reward || 10} PF</TableCell>
                        <TableCell>
                          <span className="text-xs font-bold text-green-700 bg-green-50 border border-green-200 px-1.5 py-0.5 rounded truncate block max-w-[100px]">
                            {ex.correct_answer}
                          </span>
                        </TableCell>
                        <TableCell>
                          <div className="flex gap-1 justify-center">
                            <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => { setEditingExercise(ex); setExerciseFormOpen(true); }}><Pencil className="h-3.5 w-3.5" /></Button>
                            <Button variant="ghost" size="icon" className="h-7 w-7 text-orange-500" title="Desvincular" onClick={() => unlinkExerciseMutation.mutate(ex.id || ex._id)}><Unlink className="h-3.5 w-3.5" /></Button>
                            <Button variant="ghost" size="icon" className="h-7 w-7 text-destructive" title="Excluir" onClick={() => setDeleteTarget({ type: 'exercise', id: ex.id || ex._id })}><Trash2 className="h-3.5 w-3.5" /></Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
                <div className="flex justify-end px-4 py-3 border-t border-slate-100 bg-slate-50/50">
                  <span className="text-sm font-bold text-indigo-700">
                    Total: {linkedExercises.reduce((sum: number, ex: any) => sum + (ex.pf_reward || 10), 0)} PF
                  </span>
                </div>
              </>)
            ) : (
              <div className="space-y-3">
                {/* Combobox: search input + dropdown list */}
                <div className="relative">
                  <div className="relative">
                    <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 z-10" />
                    <Input
                      placeholder="Buscar exercício por pergunta, tipo ou resposta..."
                      value={exerciseSearch}
                      onChange={e => setExerciseSearch(e.target.value)}
                      className="pl-9 pr-4"
                    />
                  </div>

                  {/* Dropdown list (always visible, scrollable) */}
                  <div className="mt-2 border border-slate-200 rounded-lg bg-white max-h-[340px] overflow-y-auto shadow-sm">
                    {allExercises.length === 0 ? (
                      <p className="text-sm text-slate-400 text-center py-6">
                        {exerciseSearch ? 'Nenhum exercício encontrado para essa busca' : 'Nenhum exercício disponível'}
                      </p>
                    ) : (
                      <div className="divide-y divide-slate-100">
                        {allExercises.slice(0, 50).map(ex => {
                          const exId = ex.id || ex._id;
                          const isSelected = selectedForLink.has(exId);
                          return (
                            <div
                              key={exId}
                              className={`flex items-center gap-3 px-3 py-2.5 cursor-pointer transition-colors hover:bg-slate-50 ${isSelected ? 'bg-green-50 hover:bg-green-100' : ''}`}
                              onClick={() => toggleSelect(exId)}
                            >
                              <input type="checkbox" checked={isSelected} readOnly className="rounded shrink-0" />
                              <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold shrink-0 ${TYPE_COLORS[ex.type] || 'bg-slate-100'}`}>
                                {TYPE_EMOJI[ex.type] || ''} {TYPE_LABELS[ex.type] || ex.type}
                              </span>
                              <div className="flex-1 min-w-0">
                                <div className="text-sm text-slate-700 truncate">{ex.question}</div>
                              </div>
                              <span className="text-[10px] font-bold text-green-700 bg-green-50 border border-green-200 px-1.5 py-0.5 rounded shrink-0 max-w-[80px] truncate">
                                {ex.correct_answer}
                              </span>
                              <Button
                                size="sm"
                                variant="outline"
                                className="h-7 text-xs gap-1 border-green-200 text-green-700 hover:bg-green-50 shrink-0"
                                onClick={(e) => { e.stopPropagation(); linkExerciseMutation.mutate({ exercise_id: exId, lesson_id: exerciseDialogLessonId }); }}
                              >
                                <Link2 size={12} /> Vincular
                              </Button>
                            </div>
                          );
                        })}
                        {allExercises.length > 50 && (
                          <p className="text-xs text-slate-400 text-center py-2">
                            Mostrando 50 de {allExercises.length} — refine a busca para ver mais
                          </p>
                        )}
                      </div>
                    )}
                  </div>
                </div>

                {/* Batch link button */}
                {selectedForLink.size > 0 && (
                  <div className="flex justify-end pt-1">
                    <Button size="sm" className="gap-1 bg-green-600 hover:bg-green-700" onClick={linkSelected}>
                      <Check size={14} /> Vincular {selectedForLink.size} selecionado(s)
                    </Button>
                  </div>
                )}
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>

      {/* Exercise Form */}
      <ExerciseFormModal
        isOpen={exerciseFormOpen}
        onClose={() => setExerciseFormOpen(false)}
        editingItem={editingExercise}
        onSubmit={handleExerciseFormSubmit}
        isLoading={createExerciseMutation.isPending || updateExerciseMutation.isPending}
      />

      {/* Unit Form Dialog */}
      <Dialog open={unitFormOpen} onOpenChange={setUnitFormOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader><DialogTitle>{editingUnit ? 'Editar Unidade' : 'Nova Unidade'}</DialogTitle></DialogHeader>
          <form onSubmit={unitForm.handleSubmit(onSubmitUnit)} className="space-y-4 pt-4">
            <div className="space-y-2"><label className="text-sm font-medium">Título *</label><Input {...unitForm.register('title')} placeholder="ex: O Nascimento de Jesus" />{unitForm.formState.errors.title && <span className="text-xs text-red-500">{unitForm.formState.errors.title.message}</span>}</div>
            <div className="space-y-2"><label className="text-sm font-medium">Descrição</label><Input {...unitForm.register('description')} placeholder="Breve descrição da unidade" /></div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Cor</label>
              <div className="flex gap-2 flex-wrap">{COLORS.map(c => (<button key={c} type="button" className={`w-8 h-8 rounded-lg border-2 transition-all ${unitForm.watch('color_hex') === c ? 'border-slate-800 scale-110' : 'border-transparent'}`} style={{ backgroundColor: c }} onClick={() => unitForm.setValue('color_hex', c)} />))}</div>
              <Input {...unitForm.register('color_hex')} placeholder="#4A90E2" className="mt-2" />{unitForm.formState.errors.color_hex && <span className="text-xs text-red-500">{unitForm.formState.errors.color_hex.message}</span>}
            </div>
            <label className="flex items-center gap-2"><input type="checkbox" {...unitForm.register('is_published')} className="rounded" /><span className="text-sm font-medium">Publicada</span></label>
            <div className="flex justify-end pt-4 border-t"><Button type="button" variant="outline" className="mr-2" onClick={() => setUnitFormOpen(false)}>Cancelar</Button><Button type="submit" disabled={createUnitMutation.isPending || updateUnitMutation.isPending}>{(createUnitMutation.isPending || updateUnitMutation.isPending) ? 'Salvando...' : 'Salvar'}</Button></div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Lesson Form Dialog */}
      <Dialog open={lessonFormOpen} onOpenChange={setLessonFormOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader><DialogTitle>{editingLesson ? 'Editar Lição' : 'Nova Lição'}</DialogTitle></DialogHeader>
          <form onSubmit={lessonForm.handleSubmit(onSubmitLesson)} className="space-y-4 pt-4">
            <div className="space-y-2"><label className="text-sm font-medium">Título *</label><Input {...lessonForm.register('title')} />{lessonForm.formState.errors.title && <span className="text-xs text-red-500">{lessonForm.formState.errors.title.message}</span>}</div>
            <div className="space-y-2"><label className="text-sm font-medium">Subtítulo</label><Input {...lessonForm.register('subtitle')} placeholder="Opcional" /></div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2"><label className="text-sm font-medium">Tipo</label><select {...lessonForm.register('lesson_type')} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">{Object.entries(LESSON_TYPES).map(([k, v]) => <option key={k} value={k}>{v}</option>)}</select></div>
              <div className="space-y-2"><label className="text-sm font-medium">Tempo (min)</label><Input type="number" {...lessonForm.register('estimated_minutes')} min={1} /></div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2"><label className="text-sm font-medium text-green-600">PF Recompensa</label><Input type="number" {...lessonForm.register('pf_reward')} min={0} /></div>
              <div className="space-y-2"><label className="text-sm font-medium text-blue-500">Bônus Perfeito</label><Input type="number" {...lessonForm.register('pf_perfect_bonus')} min={0} /></div>
            </div>
            <label className="flex items-center gap-2"><input type="checkbox" {...lessonForm.register('is_published')} className="rounded" /><span className="text-sm font-medium">Publicada</span></label>
            <div className="flex justify-end pt-4 border-t"><Button type="button" variant="outline" className="mr-2" onClick={() => setLessonFormOpen(false)}>Cancelar</Button><Button type="submit" disabled={createLessonMutation.isPending || updateLessonMutation.isPending}>{(createLessonMutation.isPending || updateLessonMutation.isPending) ? 'Salvando...' : 'Salvar'}</Button></div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!deleteTarget}
        onOpenChange={v => !v && setDeleteTarget(null)}
        title={deleteTarget?.type === 'unit' ? 'Remover Unidade?' : deleteTarget?.type === 'lesson' ? 'Remover Lição?' : 'Remover Exercício?'}
        description={deleteTarget?.type === 'unit' ? 'Todas as lições desta unidade serão removidas.' : 'Essa ação não pode ser desfeita.'}
        confirmText="Sim, excluir"
        onConfirm={() => {
          if (!deleteTarget) return;
          if (deleteTarget.type === 'unit') deleteUnitMutation.mutate(deleteTarget.id);
          else if (deleteTarget.type === 'lesson') deleteLessonMutation.mutate(deleteTarget.id);
          else deleteExerciseMutation.mutate(deleteTarget.id);
        }}
        isLoading={deleteUnitMutation.isPending || deleteLessonMutation.isPending || deleteExerciseMutation.isPending}
      />
    </div>
  );
}
