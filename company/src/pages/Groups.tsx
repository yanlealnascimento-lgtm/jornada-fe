import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Badge } from '../components/ui/badge';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '../components/ui/dialog';
import { Users, Plus, Target, Calendar, MessageSquare, Flame, Trash2, Edit3, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import api from '../services/api';

interface StudyGroup {
  id: string;
  name: string;
  description: string;
  category: string;
  icon_emoji: string;
  member_count?: number;
}

export function GroupsList() {
  const [groups, setGroups] = useState<StudyGroup[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  
  // Form State
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: 'general',
    icon_emoji: '👥'
  });

  useEffect(() => {
    fetchGroups();
  }, []);

  const fetchGroups = async () => {
    setIsLoading(true);
    try {
      const resp: any = await api.get('/companies/b2b/groups');
      setGroups(resp.data || []);
    } catch (err) {
      toast.error('Erro ao carregar grupos');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateOrUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    try {
      if (editingId) {
        await api.put(`/companies/b2b/groups/${editingId}`, formData);
        toast.success('Grupo atualizado!');
      } else {
        await api.post('/companies/b2b/groups', formData);
        toast.success('Grupo criado com sucesso!');
      }
      setIsDialogOpen(false);
      fetchGroups();
    } catch (err: any) {
      toast.error('Erro ao salvar grupo: ' + err.message);
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Tem certeza que deseja excluir este grupo?')) return;
    try {
      await api.delete(`/companies/b2b/groups/${id}`);
      toast.success('Grupo removido');
      fetchGroups();
    } catch (err: any) {
      toast.error('Erro ao remover: ' + err.message);
    }
  };

  const openCreate = () => {
    setEditingId(null);
    setFormData({ name: '', description: '', category: 'general', icon_emoji: '👥' });
    setIsDialogOpen(true);
  };

  const openEdit = (group: StudyGroup) => {
    setEditingId(group.id);
    setFormData({ 
      name: group.name, 
      description: group.description, 
      category: group.category, 
      icon_emoji: group.icon_emoji 
    });
    setIsDialogOpen(true);
  };

  const categories = [
    { value: 'youth', label: 'Jovens', color: 'bg-purple-100 text-purple-700' },
    { value: 'kids', label: 'Crianças', color: 'bg-pink-100 text-pink-700' },
    { value: 'couples', label: 'Casais', color: 'bg-red-100 text-red-700' },
    { value: 'adults', label: 'Adultos', color: 'bg-emerald-100 text-emerald-700' },
    { value: 'general', label: 'Geral', color: 'bg-slate-100 text-slate-700' },
  ];

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Grupos de Estudo</h2>
          <p className="text-muted-foreground mt-1">Organize sua congregação em células e departamentos.</p>
        </div>
        <Button onClick={openCreate} className="h-10 px-4 flex items-center gap-2">
          <Plus className="w-4 h-4" /> Novo Grupo
        </Button>
      </div>

      {isLoading ? (
        <div className="p-12 text-center text-muted-foreground">Carregando grupos...</div>
      ) : groups.length === 0 ? (
        <Card className="p-12 text-center border-dashed border-2 flex flex-col items-center gap-4 bg-slate-50/50">
          <div className="text-4xl">👥</div>
          <h3 className="text-xl font-bold">Inicie o Discipulado</h3>
          <p className="text-muted-foreground max-w-sm">Grupos ajudam na organização e permitem criar competições saudáveis e metas corporativas.</p>
          <Button onClick={openCreate}>Criar Primeiro Grupo</Button>
        </Card>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {groups.map((group) => (
            <Card key={group.id} className="hover:shadow-lg transition-shadow border-slate-200 flex flex-col overflow-hidden">
              <CardHeader className="bg-slate-50 border-b border-slate-100 space-y-4">
                <div className="flex justify-between items-start">
                   <div className="w-12 h-12 rounded-2xl bg-white shadow-sm flex items-center justify-center text-2xl border border-slate-100">
                      {group.icon_emoji}
                   </div>
                   <Badge className={categories.find(c => c.value === group.category)?.color}>
                      {categories.find(c => c.value === group.category)?.label}
                   </Badge>
                </div>
                <div>
                   <CardTitle className="text-lg font-bold">{group.name}</CardTitle>
                   <CardDescription className="line-clamp-2 mt-1">{group.description}</CardDescription>
                </div>
              </CardHeader>
              <CardContent className="pt-6 flex-1">
                 <div className="grid grid-cols-2 gap-4">
                    <div className="flex items-center gap-2 text-sm text-slate-600">
                       <Users className="w-4 h-4 text-slate-400" />
                       <span className="font-semibold">{group.member_count || 10}</span> Membros
                    </div>
                    <div className="flex items-center gap-2 text-sm text-slate-600">
                       <Flame className="w-4 h-4 text-orange-500 fill-orange-500" />
                       <span className="font-semibold text-orange-600">Alta</span> Atividade
                    </div>
                 </div>
              </CardContent>
              <CardFooter className="bg-slate-50 border-t border-slate-100 p-2 flex gap-1">
                 <Button variant="ghost" className="flex-1 text-xs gap-1 h-8" onClick={() => openEdit(group)}>
                   <Edit3 className="w-3 h-3" /> Editar
                 </Button>
                 <Button variant="ghost" className="flex-1 text-xs gap-1 h-8 text-destructive hover:text-destructive" onClick={() => handleDelete(group.id)}>
                   <Trash2 className="w-3 h-3" /> Excluir
                 </Button>
              </CardFooter>
            </Card>
          ))}
        </div>
      )}

      {/* Modal de Criação/Edição */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>{editingId ? 'Editar Grupo' : 'Novo Grupo de Estudo'}</DialogTitle>
            <DialogDescription>
              Crie grupos para organizar o aprendizado na sua instituição.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreateOrUpdate} className="space-y-4 pt-4">
            <div className="space-y-2">
              <Label htmlFor="name">Nome do Grupo</Label>
              <Input 
                id="name" 
                placeholder="Ex: Ministério Jovem" 
                value={formData.name} 
                onChange={e => setFormData({...formData, name: e.target.value})}
                required 
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="desc">Descrição</Label>
              <Input 
                id="desc" 
                placeholder="Do que se trata este grupo?" 
                value={formData.description} 
                onChange={e => setFormData({...formData, description: e.target.value})}
                required 
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Categoria</Label>
                <select 
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                  value={formData.category}
                  onChange={e => setFormData({...formData, category: e.target.value})}
                >
                  {categories.map(c => <option key={c.value} value={c.value}>{c.label}</option>)}
                </select>
              </div>
              <div className="space-y-2">
                <Label>Emoji Sugerido</Label>
                <Input 
                   value={formData.icon_emoji} 
                   onChange={e => setFormData({...formData, icon_emoji: e.target.value})}
                   placeholder="🔥"
                />
              </div>
            </div>
            <DialogFooter className="pt-4">
              <Button type="submit" disabled={isSaving} className="w-full">
                {isSaving && <Loader2 className="w-4 h-4 animate-spin mr-2" />}
                {editingId ? 'Salvar Alterações' : 'Criar Grupo'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
