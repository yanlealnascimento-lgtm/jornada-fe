import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { leaguesService, LeagueStats } from '../services/leagues.service';
import { RefreshCw, Zap, Trophy, Users, Loader2 } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { toast } from 'sonner';

// ─── Tier Config ─────────────────────────────────────────────────────────────

const TIERS = [
  { key: 'ruben',    label: 'Rúben',    emoji: '🟤', color: '#CD7F32', bg: 'bg-orange-50',  border: 'border-orange-200' },
  { key: 'simeao',   label: 'Simeão',   emoji: '⚪', color: '#A8A9AD', bg: 'bg-gray-50',    border: 'border-gray-200' },
  { key: 'levi',     label: 'Levi',     emoji: '🟡', color: '#BF953F', bg: 'bg-yellow-50',  border: 'border-yellow-200' },
  { key: 'juda',     label: 'Judá',     emoji: '🦁', color: '#F5A623', bg: 'bg-amber-50',   border: 'border-amber-200' },
  { key: 'da',       label: 'Dã',       emoji: '🌊', color: '#4ECDC4', bg: 'bg-teal-50',    border: 'border-teal-200' },
  { key: 'naftali',  label: 'Naftali',  emoji: '🦌', color: '#45B7D1', bg: 'bg-sky-50',     border: 'border-sky-200' },
  { key: 'gad',      label: 'Gad',      emoji: '⚔️', color: '#96E6A1', bg: 'bg-green-50',   border: 'border-green-200' },
  { key: 'aser',     label: 'Aser',     emoji: '✨', color: '#DDA0DD', bg: 'bg-purple-50',  border: 'border-purple-200' },
  { key: 'issacar',  label: 'Issacar',  emoji: '📖', color: '#7986CB', bg: 'bg-indigo-50',  border: 'border-indigo-200' },
  { key: 'zebulom',  label: 'Zebulom',  emoji: '🌟', color: '#4DB6AC', bg: 'bg-emerald-50', border: 'border-emerald-200' },
  { key: 'efraim',   label: 'Efraim',   emoji: '💎', color: '#E57373', bg: 'bg-red-50',     border: 'border-red-200' },
  { key: 'manasses', label: 'Manassés', emoji: '👑', color: '#FFD700', bg: 'bg-yellow-50',  border: 'border-yellow-200' },
];

// ─── Main Component ──────────────────────────────────────────────────────────

export function LeaguesList() {
  const queryClient = useQueryClient();
  const [processDialogOpen, setProcessDialogOpen] = useState(false);
  const [confirmText, setConfirmText] = useState('');

  // ─── Queries ─────────────────────────────────────────────────────────────
  const { data: statsResult, isLoading } = useQuery({
    queryKey: ['league-stats'],
    queryFn: () => leaguesService.stats().then((res: any) => res.data || res),
  });

  const stats: LeagueStats = statsResult ?? {
    active_leagues: 0,
    total_members: 0,
    by_tier: {},
    current_week: '-',
  };

  // ─── Mutations ───────────────────────────────────────────────────────────
  const seedMutation = useMutation({
    mutationFn: () => leaguesService.seed(),
    onSuccess: (res: any) => {
      const d = res.data || res;
      toast.success(`Seed concluído: ${d.created ?? d.leagues_created ?? 0} ligas criadas`);
      queryClient.invalidateQueries({ queryKey: ['league-stats'] });
    },
    onError: (e: any) => toast.error(`Erro no seed: ${e.message}`),
  });

  const processMutation = useMutation({
    mutationFn: () => leaguesService.processWeekly(),
    onSuccess: (res: any) => {
      const d = res.data || res;
      queryClient.invalidateQueries({ queryKey: ['league-stats'] });
      setProcessDialogOpen(false);
      setConfirmText('');
      toast.success(`Processamento concluído: ${d.promoted ?? 0} promovidos, ${d.demoted ?? 0} rebaixados`);
    },
    onError: (e: any) => {
      setProcessDialogOpen(false);
      setConfirmText('');
      toast.error(`Erro: ${e.message}`);
    },
  });

  // ─── Render ──────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-800">Ligas — 12 Tribos de Israel</h1>
          <p className="text-sm text-slate-500 mt-1">Sistema competitivo semanal com promoção e rebaixamento</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending}>
            <RefreshCw size={16} className={`mr-2 ${seedMutation.isPending ? 'animate-spin' : ''}`} />
            Criar ligas da semana atual
          </Button>
          <Button variant="destructive" onClick={() => setProcessDialogOpen(true)}>
            <Zap size={16} className="mr-2" />
            Processar Promoção Semanal
          </Button>
        </div>
      </div>

      {/* Stats Overview */}
      {isLoading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-slate-400" />
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-white rounded-xl border border-slate-200 p-5 relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-1 bg-indigo-500" />
              <div className="flex items-center gap-4">
                <div className="p-3 bg-indigo-100 text-indigo-600 rounded-full">
                  <Trophy className="w-6 h-6" />
                </div>
                <div>
                  <p className="text-sm font-medium text-slate-500">Semana Atual</p>
                  <h3 className="text-xl font-black text-slate-800">{stats.current_week || '-'}</h3>
                </div>
              </div>
            </div>
            <div className="bg-white rounded-xl border border-slate-200 p-5 relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-1 bg-green-500" />
              <div className="flex items-center gap-4">
                <div className="p-3 bg-green-100 text-green-600 rounded-full">
                  <Zap className="w-6 h-6" />
                </div>
                <div>
                  <p className="text-sm font-medium text-slate-500">Ligas Ativas</p>
                  <h3 className="text-xl font-black text-slate-800">{stats.active_leagues}</h3>
                </div>
              </div>
            </div>
            <div className="bg-white rounded-xl border border-slate-200 p-5 relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-1 bg-blue-500" />
              <div className="flex items-center gap-4">
                <div className="p-3 bg-blue-100 text-blue-600 rounded-full">
                  <Users className="w-6 h-6" />
                </div>
                <div>
                  <p className="text-sm font-medium text-slate-500">Total de Membros</p>
                  <h3 className="text-xl font-black text-slate-800">{stats.total_members}</h3>
                </div>
              </div>
            </div>
          </div>

          {/* Tier Cards */}
          <div>
            <h2 className="text-lg font-bold text-slate-700 mb-3">As 12 Tribos</h2>
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
              {TIERS.map(tier => {
                const tierData = stats.by_tier?.[tier.key];
                const members = tierData?.members ?? 0;
                const leagues = tierData?.leagues ?? 0;
                return (
                  <div
                    key={tier.key}
                    className={`rounded-xl border p-4 relative overflow-hidden ${tier.bg} ${tier.border}`}
                  >
                    <div className="absolute top-0 left-0 right-0 h-1" style={{ backgroundColor: tier.color }} />
                    <div className="text-3xl mb-2">{tier.emoji}</div>
                    <div className="text-sm font-black text-slate-800">{tier.label}</div>
                    <div className="mt-2 space-y-1">
                      <div className="flex justify-between text-xs">
                        <span className="text-slate-500">Membros</span>
                        <span className="font-bold text-slate-700">{members}</span>
                      </div>
                      <div className="flex justify-between text-xs">
                        <span className="text-slate-500">Grupos</span>
                        <span className="font-bold text-slate-700">{leagues}</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </>
      )}

      {/* Process Weekly Confirmation - Destructive with typed confirmation */}
      <ConfirmDialog
        isOpen={processDialogOpen}
        onOpenChange={(v) => {
          if (!v) {
            setProcessDialogOpen(false);
            setConfirmText('');
          }
        }}
        title="Processar Promoção Semanal"
        description={
          <div className="space-y-3">
            <p className="text-red-600 font-bold">Esta é uma ação irreversível e destrutiva.</p>
            <p className="text-sm text-slate-600">
              O sistema irá processar todas as ligas da semana atual imediatamente, promovendo e rebaixando
              todos os usuários, independentemente do dia da semana. A semana seguinte será criada automaticamente.
            </p>
            <div className="space-y-2 pt-2">
              <label className="text-sm font-medium text-slate-700">
                Digite <span className="font-mono font-bold text-red-600">CONFIRMAR</span> para prosseguir:
              </label>
              <Input
                value={confirmText}
                onChange={e => setConfirmText(e.target.value)}
                placeholder="CONFIRMAR"
                className="max-w-xs"
              />
            </div>
          </div>
        }
        confirmText="Processar Agora"
        onConfirm={() => {
          if (confirmText === 'CONFIRMAR') {
            processMutation.mutate();
          } else {
            toast.error('Digite "CONFIRMAR" para prosseguir');
          }
        }}
        isLoading={processMutation.isPending}
        variant="destructive"
      />
    </div>
  );
}
