import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../ui/card';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Button } from '../ui/button';
import { Save, Plus } from 'lucide-react';

// Form Subcomponents
import { MultipleChoiceForm } from './MultipleChoiceForm';
import { FillBlankForm } from './FillBlankForm';
import { SortWordsForm } from './SortWordsForm';
import { PairMatchForm } from './PairMatchForm';
import { TrueFalseForm } from './TrueFalseForm';

type ExerciseType = 'multiple_choice' | 'fill_blank' | 'sort_words' | 'pair_match' | 'true_false';

export const ExerciseEditor: React.FC = () => {
  const [exerciseType, setExerciseType] = useState<ExerciseType>('multiple_choice');

  const renderFormByType = () => {
    switch(exerciseType) {
      case 'multiple_choice': return <MultipleChoiceForm />;
      case 'fill_blank': return <FillBlankForm />;
      case 'sort_words': return <SortWordsForm />;
      case 'pair_match': return <PairMatchForm />;
      case 'true_false': return <TrueFalseForm />;
      default: return null;
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
         <div>
           <h2 className="text-2xl font-bold tracking-tight">Novo Bloco de Exercício</h2>
           <p className="text-muted-foreground mt-1 text-sm">Monte o desafio do usuário e valide como as telas reagirão antes de salvar.</p>
         </div>
         <div className="flex gap-2">
            <Button variant="outline">Cancelar</Button>
            <Button className="bg-blue-600 hover:bg-blue-700">
              <Save className="w-4 h-4 mr-2"/> Salvar Bloco
            </Button>
         </div>
      </div>
      
      <div className="grid grid-cols-12 gap-6">
        {/* Lado Esquerdo: Formulário principal e seleção */}
        <Card className="col-span-12 xl:col-span-8">
          <CardHeader className="bg-slate-50 border-b pb-4 mb-4">
            <div className="flex items-center gap-4">
              <div className="w-1/3 space-y-2">
                <Label htmlFor="type-selector" className="text-xs uppercase tracking-wider text-muted-foreground">Tipo de Desafio</Label>
                <Select value={exerciseType} onValueChange={(v: ExerciseType) => setExerciseType(v)}>
                  <SelectTrigger id="type-selector" className="bg-white">
                    <SelectValue placeholder="Selecione o tipo..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="multiple_choice">Múltipla Escolha Clássica</SelectItem>
                    <SelectItem value="fill_blank">Complete a Lacuna</SelectItem>
                    <SelectItem value="sort_words">Ordenação de Versos</SelectItem>
                    <SelectItem value="pair_match">Ligar as Colunas Pela Metade</SelectItem>
                    <SelectItem value="true_false">Verdadeiro ou Falso</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="w-2/3 space-y-1 mt-7 text-xs text-muted-foreground">
                 {exerciseType === 'multiple_choice' && "O jogador escolhe 1 opção entre 4 baseada no texto/vídeo prévio."}
                 {exerciseType === 'fill_blank' && "A palavra fica vazia e barras de letras aparecem para o usuário reconstruí-la."}
                 {exerciseType === 'sort_words' && "As palavras ficam embaralhadas para serem empurradas na ordem da frase original."}
                 {exerciseType === 'pair_match' && "Lado Esquerdo Fixo, Lado Direito Embaralhado - ligue os blocos."}
                 {exerciseType === 'true_false' && "Julgue a afirmação como Verdadeira ou Falsa (Ideal para mitos)."}
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-2 pb-6">
            {renderFormByType()}
          </CardContent>
        </Card>

        {/* Lado Direito: Preview Sidebar/Stats (Mocked para demonstração de uso do espaço) */}
        <div className="col-span-12 xl:col-span-4 space-y-6">
           {/* PF e Gamificação Estimativa */}
           <Card className="bg-blue-50 border-blue-100">
             <CardHeader className="pb-3">
               <CardTitle className="text-sm text-blue-800">Carga de Gamificação</CardTitle>
               <CardDescription className="text-blue-600/80 text-xs">Avanço automático calculado pelo tipo de exercício.</CardDescription>
             </CardHeader>
             <CardContent className="space-y-4">
               <div className="flex justify-between items-center text-sm font-medium">
                  <span className="text-blue-900">PF Base de Acerto:</span>
                  <span className="px-2 py-0.5 rounded-full bg-blue-200 text-blue-800">+10 PF</span>
               </div>
               <div className="flex justify-between items-center text-sm font-medium">
                  <span className="text-blue-900">Perda por Erro:</span>
                  <span className="px-2 py-0.5 rounded-full bg-red-100 text-red-700">-1 Vida</span>
               </div>
             </CardContent>
           </Card>

           <Button variant="secondary" className="w-full border shadow-sm h-12">
              <Plus className="w-4 h-4 mr-2"/> Adicionar Bloco de Texto Teórico
           </Button>
        </div>
      </div>
    </div>
  );
}
