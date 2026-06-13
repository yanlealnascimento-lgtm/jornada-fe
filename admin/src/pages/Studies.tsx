import { useState, useMemo, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../services/api';
import {
  Plus, Trash2, RefreshCw, Download, Pencil, MoreVertical, Eye, EyeOff,
  ChevronDown, ChevronRight, Flame, BookOpen, Sparkles,
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '../components/ui/dropdown-menu';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../components/ui/dialog';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { EmptyState } from '../components/EmptyState';
import { StatusBadge } from '../components/StatusBadge';
import { toast } from 'sonner';

// ─── Types ───────────────────────────────────────────────────────────────────

interface QuizMC {
  question: string;
  options: [string, string, string, string];
  correct_index: number;
}

interface QuizFill {
  verse_with_blank: string;
  answer: string;
  hint: string;
}

interface QuizOrder {
  words: string;
  correct: string;
}

interface Lesson {
  order: number;
  title: string;
  verse_ref: string;
  verse_text: string;
  verse_version: string;
  dialogue_intro: string;
  dialogue_character: string;
  dialogue_reaction: string;
  dialogue_application: string;
  dialogue_dove_close: string;
  quiz_mc: QuizMC;
  quiz_fill: QuizFill;
  quiz_order: QuizOrder;
  pf_reward: number;
  mana_reward: number;
}

interface Study {
  id: string;
  _id: string;
  title: string;
  slug: string;
  description: string;
  thumbnail_url: string;
  category: string;
  difficulty: string;
  character_id: string | { _id: string; name: string; title: string };
  tags: string[];
  is_premium: boolean;
  is_featured: boolean;
  is_published: boolean;
  lessons: Lesson[];
  cache_status: 'warm' | 'partial' | 'cold' | 'empty';
  cached_lessons: number;
  total_lessons: number;
}

interface StudyStats {
  total: number;
  published: number;
  premium: number;
  free: number;
  featured: number;
  cached: number;
  total_for_cache: number;
}

interface StudyFormData {
  title: string;
  slug: string;
  description: string;
  thumbnail_url: string;
  category: string;
  difficulty: string;
  character_id: string;
  tags: string;
  is_premium: boolean;
  is_featured: boolean;
  is_published: boolean;
  lessons: Lesson[];
}

// ─── Constants ───────────────────────────────────────────────────────────────

const CATEGORIES = [
  { value: 'personagens', label: 'Personagens' },
  { value: 'doutrinas', label: 'Doutrinas' },
  { value: 'vida-crista', label: 'Vida Cristã' },
  { value: 'profecias', label: 'Profecias' },
  { value: 'livros', label: 'Livros' },
  { value: 'devocionais', label: 'Devocionais' },
  { value: 'sazonais', label: 'Sazonais' },
];

const DIFFICULTIES = [
  { value: 'beginner', label: 'Iniciante' },
  { value: 'intermediate', label: 'Intermediário' },
  { value: 'advanced', label: 'Avançado' },
];

const CACHE_BADGE: Record<string, { label: string; className: string }> = {
  warm: { label: 'Warm', className: 'bg-green-100 text-green-800 border-green-200' },
  partial: { label: 'Partial', className: 'bg-yellow-100 text-yellow-800 border-yellow-200' },
  cold: { label: 'Cold', className: 'bg-red-100 text-red-800 border-red-200' },
  empty: { label: 'Empty', className: 'bg-gray-100 text-gray-500 border-gray-200' },
};

const STAT_CARDS: { key: string; label: string; icon: string; color: string }[] = [
  { key: 'total', label: 'Total', icon: '📚', color: '#4A90E2' },
  { key: 'published', label: 'Publicados', icon: '✅', color: '#27AE60' },
  { key: 'premium', label: 'Premium', icon: '⭐', color: '#D4A017' },
  { key: 'free', label: 'Gratuitos', icon: '🆓', color: '#16A34A' },
  { key: 'featured', label: 'Destaque', icon: '🔥', color: '#EF4444' },
  { key: 'cache', label: 'Cache IA', icon: '🤖', color: '#8B5CF6' },
];

const EMPTY_QUIZ_MC: QuizMC = { question: '', options: ['', '', '', ''], correct_index: 0 };
const EMPTY_QUIZ_FILL: QuizFill = { verse_with_blank: '', answer: '', hint: '' };
const EMPTY_QUIZ_ORDER: QuizOrder = { words: '', correct: '' };

function createEmptyLesson(order: number): Lesson {
  return {
    order,
    title: '',
    verse_ref: '',
    verse_text: '',
    verse_version: 'NVI',
    dialogue_intro: '',
    dialogue_character: '',
    dialogue_reaction: '',
    dialogue_application: '',
    dialogue_dove_close: '',
    quiz_mc: { ...EMPTY_QUIZ_MC, options: ['', '', '', ''] },
    quiz_fill: { ...EMPTY_QUIZ_FILL },
    quiz_order: { ...EMPTY_QUIZ_ORDER },
    pf_reward: 50,
    mana_reward: 10,
  };
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

// ─── Lesson Accordion Editor ─────────────────────────────────────────────────

function LessonEditor({
  lesson,
  index,
  onChange,
  onRemove,
  isExpanded,
  onToggle,
}: {
  lesson: Lesson;
  index: number;
  onChange: (index: number, lesson: Lesson) => void;
  onRemove: (index: number) => void;
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const update = (field: string, value: any) => {
    onChange(index, { ...lesson, [field]: value });
  };

  const updateQuizMC = (field: string, value: any) => {
    onChange(index, { ...lesson, quiz_mc: { ...lesson.quiz_mc, [field]: value } });
  };

  const updateQuizMCOption = (optIndex: number, value: string) => {
    const newOptions = [...lesson.quiz_mc.options] as [string, string, string, string];
    newOptions[optIndex] = value;
    onChange(index, { ...lesson, quiz_mc: { ...lesson.quiz_mc, options: newOptions } });
  };

  const updateQuizFill = (field: string, value: any) => {
    onChange(index, { ...lesson, quiz_fill: { ...lesson.quiz_fill, [field]: value } });
  };

  const updateQuizOrder = (field: string, value: string) => {
    onChange(index, { ...lesson, quiz_order: { ...lesson.quiz_order, [field]: value } });
  };

  return (
    <div className="border rounded-lg overflow-hidden">
      {/* Accordion Header */}
      <button
        type="button"
        onClick={onToggle}
        className="flex items-center justify-between w-full px-4 py-3 bg-slate-50 hover:bg-slate-100 transition-colors text-left"
      >
        <div className="flex items-center gap-3">
          {isExpanded ? <ChevronDown className="h-4 w-4 text-slate-500" /> : <ChevronRight className="h-4 w-4 text-slate-500" />}
          <span className="text-sm font-bold text-slate-700">
            Lição {lesson.order} {lesson.title ? `— ${lesson.title}` : ''}
          </span>
        </div>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          className="text-red-500 hover:text-red-700 hover:bg-red-50 h-7 px-2"
          onClick={(e) => {
            e.stopPropagation();
            onRemove(index);
          }}
        >
          <Trash2 className="h-3.5 w-3.5" />
        </Button>
      </button>

      {/* Accordion Content */}
      {isExpanded && (
        <div className="p-4 space-y-4 bg-white">
          {/* Basic Info */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-600">Ordem</label>
              <Input
                type="number"
                min={1}
                value={lesson.order}
                onChange={(e) => update('order', parseInt(e.target.value) || 1)}
              />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-600">Título *</label>
              <Input
                value={lesson.title}
                onChange={(e) => update('title', e.target.value)}
                placeholder="Ex: A Jornada de Abraão"
              />
            </div>
          </div>

          {/* Verse */}
          <div className="p-3 rounded-md border border-blue-100 bg-blue-50/30 space-y-3">
            <h4 className="text-xs font-bold text-blue-700 uppercase tracking-wide">Versículo</h4>
            <div className="grid grid-cols-3 gap-3">
              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-600">Referência</label>
                <Input
                  value={lesson.verse_ref}
                  onChange={(e) => update('verse_ref', e.target.value)}
                  placeholder="Gn 12:1-3"
                />
              </div>
              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-600">Versão</label>
                <select
                  value={lesson.verse_version}
                  onChange={(e) => update('verse_version', e.target.value)}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                >
                  <option value="NVI">NVI</option>
                  <option value="ARA">ARA</option>
                  <option value="ACF">ACF</option>
                  <option value="NAA">NAA</option>
                  <option value="NVT">NVT</option>
                  <option value="KJV">KJV</option>
                </select>
              </div>
              <div />
            </div>
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-600">Texto do Versículo</label>
              <textarea
                value={lesson.verse_text}
                onChange={(e) => update('verse_text', e.target.value)}
                className="flex min-h-[60px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                placeholder="Ora, o Senhor disse a Abrão..."
              />
            </div>
          </div>

          {/* Dialogues */}
          <div className="p-3 rounded-md border border-purple-100 bg-purple-50/30 space-y-3">
            <h4 className="text-xs font-bold text-purple-700 uppercase tracking-wide">Diálogos (5 falas)</h4>
            {[
              { field: 'dialogue_intro', label: 'Introdução (Narrador)', placeholder: 'Contexto inicial da lição...' },
              { field: 'dialogue_character', label: 'Fala do Personagem', placeholder: 'O que o personagem bíblico diz...' },
              { field: 'dialogue_reaction', label: 'Reação do Jogador', placeholder: 'Reflexão ou resposta do jogador...' },
              { field: 'dialogue_application', label: 'Aplicação Prática', placeholder: 'Como aplicar no dia a dia...' },
              { field: 'dialogue_dove_close', label: 'Encerramento (Pomba)', placeholder: 'Mensagem de encerramento da pomba...' },
            ].map(({ field, label, placeholder }) => (
              <div key={field} className="space-y-1">
                <label className="text-xs font-semibold text-slate-600">{label}</label>
                <textarea
                  value={(lesson as any)[field] || ''}
                  onChange={(e) => update(field, e.target.value)}
                  className="flex min-h-[50px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                  placeholder={placeholder}
                />
              </div>
            ))}
          </div>

          {/* Quiz MC */}
          <div className="p-3 rounded-md border border-green-100 bg-green-50/30 space-y-3">
            <h4 className="text-xs font-bold text-green-700 uppercase tracking-wide">Quiz - Múltipla Escolha</h4>
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-600">Pergunta</label>
              <Input
                value={lesson.quiz_mc.question}
                onChange={(e) => updateQuizMC('question', e.target.value)}
                placeholder="Qual foi a promessa de Deus a Abraão?"
              />
            </div>
            <div className="grid grid-cols-2 gap-2">
              {lesson.quiz_mc.options.map((opt, oi) => (
                <div key={oi} className="space-y-1">
                  <label className="text-xs font-semibold text-slate-600 flex items-center gap-1">
                    Opção {oi + 1}
                    {oi === lesson.quiz_mc.correct_index && (
                      <span className="text-green-600 text-[10px] font-bold">(CORRETA)</span>
                    )}
                  </label>
                  <Input
                    value={opt}
                    onChange={(e) => updateQuizMCOption(oi, e.target.value)}
                    className={oi === lesson.quiz_mc.correct_index ? 'border-green-300 bg-green-50' : ''}
                  />
                </div>
              ))}
            </div>
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-600">Índice da Resposta Correta</label>
              <select
                value={lesson.quiz_mc.correct_index}
                onChange={(e) => updateQuizMC('correct_index', parseInt(e.target.value))}
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              >
                <option value={0}>Opção 1</option>
                <option value={1}>Opção 2</option>
                <option value={2}>Opção 3</option>
                <option value={3}>Opção 4</option>
              </select>
            </div>
          </div>

          {/* Quiz Fill */}
          <div className="p-3 rounded-md border border-orange-100 bg-orange-50/30 space-y-3">
            <h4 className="text-xs font-bold text-orange-700 uppercase tracking-wide">Quiz - Preencher Lacuna</h4>
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-600">Versículo com Lacuna (use ___ para a lacuna)</label>
              <Input
                value={lesson.quiz_fill.verse_with_blank}
                onChange={(e) => updateQuizFill('verse_with_blank', e.target.value)}
                placeholder='Porque Deus amou o ___ de tal maneira...'
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-600">Resposta</label>
                <Input
                  value={lesson.quiz_fill.answer}
                  onChange={(e) => updateQuizFill('answer', e.target.value)}
                  placeholder="mundo"
                />
              </div>
              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-600">Dica</label>
                <Input
                  value={lesson.quiz_fill.hint}
                  onChange={(e) => updateQuizFill('hint', e.target.value)}
                  placeholder="Começa com M"
                />
              </div>
            </div>
          </div>

          {/* Quiz Order */}
          <div className="p-3 rounded-md border border-cyan-100 bg-cyan-50/30 space-y-3">
            <h4 className="text-xs font-bold text-cyan-700 uppercase tracking-wide">Quiz - Ordenar Palavras</h4>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-600">Palavras (separadas por vírgula)</label>
                <Input
                  value={lesson.quiz_order.words}
                  onChange={(e) => updateQuizOrder('words', e.target.value)}
                  placeholder="amou, Deus, mundo, o"
                />
              </div>
              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-600">Ordem Correta (separadas por vírgula)</label>
                <Input
                  value={lesson.quiz_order.correct}
                  onChange={(e) => updateQuizOrder('correct', e.target.value)}
                  placeholder="Deus, amou, o, mundo"
                />
              </div>
            </div>
          </div>

          {/* Rewards */}
          <div className="p-3 rounded-md border border-amber-100 bg-amber-50/30 space-y-3">
            <h4 className="text-xs font-bold text-amber-700 uppercase tracking-wide">Recompensas</h4>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-xs font-semibold text-slate-600">
                  PF Reward: <span className="text-amber-600 font-bold">{lesson.pf_reward}</span>
                </label>
                <input
                  type="range"
                  min={0}
                  max={200}
                  step={5}
                  value={lesson.pf_reward}
                  onChange={(e) => update('pf_reward', parseInt(e.target.value))}
                  className="w-full accent-amber-500"
                />
                <div className="flex justify-between text-[10px] text-slate-400">
                  <span>0</span>
                  <span>100</span>
                  <span>200</span>
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-xs font-semibold text-slate-600">
                  Mana Reward: <span className="text-blue-600 font-bold">{lesson.mana_reward}</span>
                </label>
                <input
                  type="range"
                  min={0}
                  max={50}
                  step={1}
                  value={lesson.mana_reward}
                  onChange={(e) => update('mana_reward', parseInt(e.target.value))}
                  className="w-full accent-blue-500"
                />
                <div className="flex justify-between text-[10px] text-slate-400">
                  <span>0</span>
                  <span>25</span>
                  <span>50</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Main Component ──────────────────────────────────────────────────────────

export function StudiesList() {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState('all');
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingStudy, setEditingStudy] = useState<Study | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [expandedLessons, setExpandedLessons] = useState<Set<number>>(new Set());

  // Form state
  const [formData, setFormData] = useState<StudyFormData>({
    title: '',
    slug: '',
    description: '',
    thumbnail_url: '',
    category: 'personagens',
    difficulty: 'beginner',
    character_id: '',
    tags: '',
    is_premium: true,
    is_featured: false,
    is_published: false,
    lessons: [],
  });

  // ─── Queries ──────────────────────────────────────────────────────────────

  const { data: listResult, isLoading } = useQuery({
    queryKey: ['studies'],
    queryFn: () =>
      api.get('/admin/studies').then((res: any) => {
        const d = res.data || res;
        return d.studies ? d : { studies: Array.isArray(d) ? d : [], total: 0 };
      }),
  });

  const { data: statsResult } = useQuery({
    queryKey: ['study-stats'],
    queryFn: () => api.get('/admin/studies/stats').then((res: any) => res.data || res),
  });

  const { data: charsResult } = useQuery({
    queryKey: ['characters'],
    queryFn: () => api.get('/characters').then((res: any) => res.data || res),
  });

  const stats: StudyStats = statsResult ?? {
    total: 0,
    published: 0,
    premium: 0,
    free: 0,
    featured: 0,
    cached: 0,
    total_for_cache: 0,
  };
  const characters = Array.isArray(charsResult) ? charsResult : [];
  const studies: Study[] = useMemo(() => listResult?.studies || [], [listResult]);

  const filteredStudies = useMemo(
    () =>
      studies.filter((s) => {
        const matchSearch =
          s.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
          s.slug.includes(searchTerm.toLowerCase());
        const matchCategory = filterCategory === 'all' || s.category === filterCategory;
        return matchSearch && matchCategory;
      }),
    [studies, searchTerm, filterCategory]
  );

  // ─── Mutations ────────────────────────────────────────────────────────────

  const invalidateAll = () => {
    queryClient.invalidateQueries({ queryKey: ['studies'] });
    queryClient.invalidateQueries({ queryKey: ['study-stats'] });
  };

  const createMutation = useMutation({
    mutationFn: (data: any) => api.post('/admin/studies', data),
    onSuccess: () => {
      invalidateAll();
      setIsFormOpen(false);
      toast.success('Estudo criado com sucesso');
    },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) => api.put(`/admin/studies/${id}`, data),
    onSuccess: () => {
      invalidateAll();
      setIsFormOpen(false);
      toast.success('Estudo atualizado com sucesso');
    },
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/admin/studies/${id}`),
    onSuccess: () => {
      invalidateAll();
      setDeleteId(null);
      toast.success('Estudo removido');
    },
    onError: (e: any) => {
      toast.error(`Erro ao remover: ${e.message}`);
      setDeleteId(null);
    },
  });

  const togglePublishMutation = useMutation({
    mutationFn: ({ id, is_published }: { id: string; is_published: boolean }) =>
      api.put(`/admin/studies/${id}`, { is_published }),
    onSuccess: () => invalidateAll(),
    onError: (e: any) => toast.error(`Erro: ${e.message}`),
  });

  const seedMutation = useMutation({
    mutationFn: () => api.post('/admin/studies/seed'),
    onSuccess: (res: any) => {
      const d = res.data || res;
      toast.success(`Seed concluído: ${d.created ?? 0} criados, ${d.updated ?? 0} atualizados`);
      invalidateAll();
    },
    onError: (e: any) => toast.error(`Erro no seed: ${e.message}`),
  });

  const warmCacheMutation = useMutation({
    mutationFn: (id: string) => api.post(`/admin/studies/${id}/warm-cache`),
    onSuccess: (res: any) => {
      const d = res.data || res;
      toast.success(`Cache aquecido: ${d.cached_lessons ?? 0} lições em cache`);
      invalidateAll();
    },
    onError: (e: any) => toast.error(`Erro ao aquecer cache: ${e.message}`),
  });

  // ─── Form Handlers ────────────────────────────────────────────────────────

  const updateFormField = useCallback((field: keyof StudyFormData, value: any) => {
    setFormData((prev) => {
      const next = { ...prev, [field]: value };
      if (field === 'title' && !editingStudy) {
        next.slug = slugify(value as string);
      }
      return next;
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editingStudy]);

  const updateLesson = useCallback((index: number, lesson: Lesson) => {
    setFormData((prev) => {
      const lessons = [...prev.lessons];
      lessons[index] = lesson;
      return { ...prev, lessons };
    });
  }, []);

  const addLesson = () => {
    setFormData((prev) => ({
      ...prev,
      lessons: [...prev.lessons, createEmptyLesson(prev.lessons.length + 1)],
    }));
    setExpandedLessons((prev) => new Set([...prev, formData.lessons.length]));
  };

  const removeLesson = (index: number) => {
    setFormData((prev) => {
      const lessons = prev.lessons.filter((_, i) => i !== index).map((l, i) => ({ ...l, order: i + 1 }));
      return { ...prev, lessons };
    });
    setExpandedLessons((prev) => {
      const next = new Set<number>();
      prev.forEach((v) => {
        if (v < index) next.add(v);
        else if (v > index) next.add(v - 1);
      });
      return next;
    });
  };

  const toggleLessonExpand = (index: number) => {
    setExpandedLessons((prev) => {
      const next = new Set(prev);
      if (next.has(index)) next.delete(index);
      else next.add(index);
      return next;
    });
  };

  const resetForm = (study?: Study | null) => {
    setExpandedLessons(new Set());
    if (study) {
      const charId =
        typeof study.character_id === 'object' && study.character_id
          ? study.character_id._id
          : (study.character_id as string) || '';
      setFormData({
        title: study.title,
        slug: study.slug,
        description: study.description || '',
        thumbnail_url: study.thumbnail_url || '',
        category: study.category || 'personagens',
        difficulty: study.difficulty || 'beginner',
        character_id: charId,
        tags: Array.isArray(study.tags) ? study.tags.join(', ') : '',
        is_premium: study.is_premium ?? true,
        is_featured: study.is_featured ?? false,
        is_published: study.is_published ?? false,
        lessons: (study.lessons || []).map((l, i) => ({
          ...createEmptyLesson(i + 1),
          ...l,
          order: l.order || i + 1,
          quiz_mc: l.quiz_mc ? { ...EMPTY_QUIZ_MC, ...l.quiz_mc, options: l.quiz_mc.options || ['', '', '', ''] } : { ...EMPTY_QUIZ_MC, options: ['', '', '', ''] },
          quiz_fill: l.quiz_fill ? { ...EMPTY_QUIZ_FILL, ...l.quiz_fill } : { ...EMPTY_QUIZ_FILL },
          quiz_order: l.quiz_order ? { ...EMPTY_QUIZ_ORDER, ...l.quiz_order } : { ...EMPTY_QUIZ_ORDER },
        })),
      });
    } else {
      setFormData({
        title: '',
        slug: '',
        description: '',
        thumbnail_url: '',
        category: 'personagens',
        difficulty: 'beginner',
        character_id: '',
        tags: '',
        is_premium: true,
        is_featured: false,
        is_published: false,
        lessons: [],
      });
    }
  };

  const openNew = () => {
    setEditingStudy(null);
    resetForm(null);
    setIsFormOpen(true);
  };

  const openEdit = (study: Study) => {
    setEditingStudy(study);
    resetForm(study);
    setIsFormOpen(true);
  };

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.title || formData.title.length < 3) {
      toast.error('Título deve ter pelo menos 3 caracteres');
      return;
    }
    if (!formData.slug) {
      toast.error('Slug é obrigatório');
      return;
    }
    if (!formData.description || formData.description.length < 10) {
      toast.error('Descrição deve ter pelo menos 10 caracteres');
      return;
    }

    const payload = {
      ...formData,
      tags: formData.tags
        .split(',')
        .map((t) => t.trim())
        .filter(Boolean),
    };

    if (editingStudy) {
      updateMutation.mutate({ id: editingStudy.id || editingStudy._id, data: payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const getCategoryLabel = (value: string) => CATEGORIES.find((c) => c.value === value)?.label || value;
  const getDifficultyLabel = (value: string) => DIFFICULTIES.find((d) => d.value === value)?.label || value;

  // ─── Render ───────────────────────────────────────────────────────────────

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-800">Estudos Bíblicos</h1>
          <p className="text-sm text-slate-500 mt-1">
            Gerencie estudos bíblicos com explicações geradas por IA
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={() => seedMutation.mutate()}
            disabled={seedMutation.isPending}
          >
            <RefreshCw
              size={16}
              className={`mr-2 ${seedMutation.isPending ? 'animate-spin' : ''}`}
            />
            Seed Dados
          </Button>
          <Button onClick={openNew}>
            <Plus size={16} className="mr-2" /> Novo Estudo
          </Button>
        </div>
      </div>

      {/* Stats Dashboard */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {STAT_CARDS.map((card) => (
          <div
            key={card.key}
            className="bg-white rounded-xl border border-slate-200 p-4 relative overflow-hidden"
          >
            <div
              className="absolute top-0 left-0 right-0 h-1"
              style={{ backgroundColor: card.color }}
            />
            <div className="text-2xl mb-1">{card.icon}</div>
            <div className="text-xl font-black text-slate-800">
              {card.key === 'cache'
                ? `${stats.cached ?? 0}/${stats.total_for_cache ?? 0}`
                : (stats as any)[card.key] ?? 0}
            </div>
            <div className="text-xs font-semibold text-slate-500 leading-tight">{card.label}</div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        <Input
          placeholder="Buscar por título ou slug..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="max-w-xs"
        />
        <div className="flex gap-2 flex-wrap">
          {[{ value: 'all', label: 'Todos' }, ...CATEGORIES].map(({ value, label }) => (
            <button
              key={value}
              onClick={() => setFilterCategory(value)}
              className={`px-3 py-1.5 rounded-full text-xs font-bold border transition-all ${
                filterCategory === value
                  ? 'bg-slate-800 text-white border-slate-800'
                  : 'bg-white text-slate-600 border-slate-200 hover:border-slate-400'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
        <span className="text-sm text-slate-400 ml-auto">{filteredStudies.length} estudo(s)</span>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {isLoading ? (
          <div className="text-center py-12 text-slate-400">Carregando...</div>
        ) : studies.length === 0 ? (
          <EmptyState
            icon={Download}
            title="Nenhum estudo cadastrado"
            description='Crie seu primeiro estudo bíblico ou clique em "Seed Dados" para carregar 10 estudos de exemplo.'
            actionText="Novo Estudo"
            onAction={openNew}
          />
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="bg-slate-50">
                  <TableHead>Thumb</TableHead>
                  <TableHead>Título + Slug</TableHead>
                  <TableHead>Categoria</TableHead>
                  <TableHead>Dificuldade</TableHead>
                  <TableHead className="text-center">Lições</TableHead>
                  <TableHead>Cache IA</TableHead>
                  <TableHead>Premium</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="w-12">Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredStudies.map((study) => {
                  const sid = study.id || study._id;
                  const cacheInfo = CACHE_BADGE[study.cache_status] || CACHE_BADGE.empty;
                  return (
                    <TableRow key={sid}>
                      <TableCell className="w-16">
                        {study.thumbnail_url ? (
                          <img
                            src={study.thumbnail_url}
                            alt={study.title}
                            className="w-10 h-10 rounded object-cover"
                          />
                        ) : (
                          <div className="w-10 h-10 rounded bg-muted flex items-center justify-center text-xs">
                            📖
                          </div>
                        )}
                      </TableCell>
                      <TableCell>
                        <div
                          className="font-medium text-slate-800 max-w-xs truncate"
                          title={study.title}
                        >
                          {study.title}
                        </div>
                        <div className="text-xs text-slate-400 font-mono">{study.slug}</div>
                      </TableCell>
                      <TableCell>
                        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-indigo-100 text-indigo-800 border border-indigo-200">
                          {getCategoryLabel(study.category)}
                        </span>
                      </TableCell>
                      <TableCell>
                        <span className="text-sm text-slate-600">
                          {getDifficultyLabel(study.difficulty)}
                        </span>
                      </TableCell>
                      <TableCell className="text-center">
                        {study.total_lessons || study.lessons?.length || 0}
                      </TableCell>
                      <TableCell>
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border ${cacheInfo.className}`}
                        >
                          {cacheInfo.label}
                          {(study.cache_status === 'partial' || study.cache_status === 'warm') && (
                            <span className="ml-1 text-[10px] opacity-75">
                              {study.cached_lessons}/{study.total_lessons || study.lessons?.length || 0}
                            </span>
                          )}
                        </span>
                      </TableCell>
                      <TableCell>
                        {study.is_premium ? (
                          <span className="text-amber-600 font-bold text-sm">Premium</span>
                        ) : (
                          <span className="text-green-600 font-bold text-sm">Free</span>
                        )}
                      </TableCell>
                      <TableCell>
                        <StatusBadge status={study.is_published ? 'published' : 'draft'} />
                      </TableCell>
                      <TableCell>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon" className="h-8 w-8">
                              <MoreVertical className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => openEdit(study)}>
                              <Pencil className="h-4 w-4 mr-2" /> Editar
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() =>
                                togglePublishMutation.mutate({
                                  id: sid,
                                  is_published: !study.is_published,
                                })
                              }
                            >
                              {study.is_published ? (
                                <>
                                  <EyeOff className="h-4 w-4 mr-2" /> Despublicar
                                </>
                              ) : (
                                <>
                                  <Eye className="h-4 w-4 mr-2" /> Publicar
                                </>
                              )}
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => warmCacheMutation.mutate(sid)}
                              disabled={warmCacheMutation.isPending}
                            >
                              <Flame className="h-4 w-4 mr-2" /> Warm Cache
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem
                              className="text-destructive focus:text-destructive"
                              onClick={() => setDeleteId(sid)}
                            >
                              <Trash2 className="h-4 w-4 mr-2" /> Excluir
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {/* Form Dialog */}
      <Dialog open={isFormOpen} onOpenChange={setIsFormOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <BookOpen className="h-5 w-5" />
              {editingStudy ? 'Editar Estudo Bíblico' : 'Novo Estudo Bíblico'}
            </DialogTitle>
          </DialogHeader>
          <form onSubmit={onSubmit} className="space-y-5 pt-4">
            {/* Section 1: Basic Info */}
            <div className="space-y-4">
              <h3 className="text-sm font-bold text-slate-700 uppercase tracking-wide border-b pb-2">
                Informações Básicas
              </h3>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Título *</label>
                  <Input
                    value={formData.title}
                    onChange={(e) => updateFormField('title', e.target.value)}
                    placeholder="Ex: A Jornada de Abraão"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Slug *</label>
                  <Input
                    value={formData.slug}
                    onChange={(e) => updateFormField('slug', e.target.value)}
                    placeholder="a-jornada-de-abraao"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">
                  Descrição *{' '}
                  <span className="text-slate-400 font-normal">
                    ({formData.description.length}/500)
                  </span>
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => updateFormField('description', e.target.value)}
                  maxLength={500}
                  className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                  placeholder="Descrição do estudo bíblico..."
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Thumbnail URL</label>
                  <Input
                    value={formData.thumbnail_url}
                    onChange={(e) => updateFormField('thumbnail_url', e.target.value)}
                    placeholder="https://..."
                  />
                  {formData.thumbnail_url && (
                    <img
                      src={formData.thumbnail_url}
                      alt="Preview"
                      className="w-full h-20 object-cover rounded border mt-1"
                      onError={(e) => ((e.currentTarget as HTMLImageElement).style.display = 'none')}
                    />
                  )}
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Personagem Guia</label>
                  <select
                    value={formData.character_id}
                    onChange={(e) => updateFormField('character_id', e.target.value)}
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  >
                    <option value="">Sem personagem</option>
                    {characters.map((c: any) => (
                      <option key={c.id || c._id} value={c.id || c._id}>
                        {c.name} ({c.title})
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Categoria *</label>
                  <select
                    value={formData.category}
                    onChange={(e) => updateFormField('category', e.target.value)}
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  >
                    {CATEGORIES.map((c) => (
                      <option key={c.value} value={c.value}>
                        {c.label}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Dificuldade *</label>
                  <select
                    value={formData.difficulty}
                    onChange={(e) => updateFormField('difficulty', e.target.value)}
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  >
                    {DIFFICULTIES.map((d) => (
                      <option key={d.value} value={d.value}>
                        {d.label}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Tags</label>
                  <Input
                    value={formData.tags}
                    onChange={(e) => updateFormField('tags', e.target.value)}
                    placeholder="abraão, fé, promessa"
                  />
                  <span className="text-[10px] text-slate-400">Separadas por vírgula</span>
                </div>
              </div>
            </div>

            {/* Section 2: Configuration */}
            <div className="space-y-3 p-4 border rounded-md bg-slate-50/50">
              <h3 className="text-sm font-bold text-slate-700 uppercase tracking-wide">
                Configurações
              </h3>
              <div className="flex gap-6 flex-wrap">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={formData.is_premium}
                    onChange={(e) => updateFormField('is_premium', e.target.checked)}
                    className="rounded"
                  />
                  <span className="text-sm font-medium">Premium (JF Plus)</span>
                </label>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={formData.is_featured}
                    onChange={(e) => updateFormField('is_featured', e.target.checked)}
                    className="rounded"
                  />
                  <span className="text-sm font-medium">Destaque</span>
                </label>
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={formData.is_published}
                    onChange={(e) => updateFormField('is_published', e.target.checked)}
                    className="rounded"
                  />
                  <span className="text-sm font-medium">Visível no app</span>
                </label>
              </div>
              {formData.is_premium && (
                <div className="flex items-start gap-2 p-3 rounded-md bg-amber-50 border border-amber-200">
                  <Sparkles className="h-4 w-4 text-amber-600 mt-0.5 flex-shrink-0" />
                  <p className="text-xs text-amber-700">
                    <strong>Atenção:</strong> Estudos premium utilizam a API de IA para gerar
                    explicações detalhadas em tempo real. Cada lição sem cache consome tokens da API.
                    Recomendamos aquecer o cache antes de publicar.
                  </p>
                </div>
              )}
            </div>

            {/* Section 3: Lessons */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-bold text-slate-700 uppercase tracking-wide border-b pb-2 flex-1">
                  Lições ({formData.lessons.length})
                </h3>
                <div className="flex gap-2 ml-4">
                  {formData.lessons.length > 0 && (
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        if (expandedLessons.size === formData.lessons.length) {
                          setExpandedLessons(new Set());
                        } else {
                          setExpandedLessons(new Set(formData.lessons.map((_, i) => i)));
                        }
                      }}
                    >
                      {expandedLessons.size === formData.lessons.length
                        ? 'Recolher Todas'
                        : 'Expandir Todas'}
                    </Button>
                  )}
                  <Button type="button" variant="outline" size="sm" onClick={addLesson}>
                    <Plus className="h-4 w-4 mr-1" /> Adicionar Lição
                  </Button>
                </div>
              </div>

              {formData.lessons.length === 0 ? (
                <div className="text-center py-8 text-slate-400 border border-dashed rounded-lg">
                  <BookOpen className="h-8 w-8 mx-auto mb-2 opacity-50" />
                  <p className="text-sm">Nenhuma lição adicionada ainda</p>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="mt-3"
                    onClick={addLesson}
                  >
                    <Plus className="h-4 w-4 mr-1" /> Adicionar Primeira Lição
                  </Button>
                </div>
              ) : (
                <div className="space-y-2">
                  {formData.lessons.map((lesson, index) => (
                    <LessonEditor
                      key={index}
                      lesson={lesson}
                      index={index}
                      onChange={updateLesson}
                      onRemove={removeLesson}
                      isExpanded={expandedLessons.has(index)}
                      onToggle={() => toggleLessonExpand(index)}
                    />
                  ))}
                </div>
              )}

              {formData.lessons.length > 0 && (
                <Button type="button" variant="outline" size="sm" onClick={addLesson} className="w-full border-dashed">
                  <Plus className="h-4 w-4 mr-1" /> Adicionar Outra Lição
                </Button>
              )}
            </div>

            {/* Submit */}
            <div className="flex justify-end pt-4 border-t">
              <Button
                type="button"
                variant="outline"
                className="mr-2"
                onClick={() => setIsFormOpen(false)}
              >
                Cancelar
              </Button>
              <Button
                type="submit"
                disabled={createMutation.isPending || updateMutation.isPending}
              >
                {createMutation.isPending || updateMutation.isPending
                  ? 'Salvando...'
                  : 'Salvar'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!deleteId}
        onOpenChange={(v) => !v && setDeleteId(null)}
        title="Excluir estudo?"
        description="Esta ação não pode ser desfeita. O estudo bíblico e todas as suas lições serão removidos permanentemente. O cache de IA associado também será limpo."
        confirmText="Sim, excluir"
        onConfirm={() => deleteId && deleteMutation.mutate(deleteId)}
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
}
