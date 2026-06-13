import React, { useState } from 'react';
import { Label } from '../ui/label';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Button } from '../ui/button';
import { Plus, Trash2, ArrowRightLeft } from 'lucide-react';

export const PairMatchForm: React.FC = () => {
  const [pairs, setPairs] = useState([{ id: 1, left: '', right: '' }, { id: 2, left: '', right: '' }]);

  const addPair = () => {
    setPairs([...pairs, { id: Date.now(), left: '', right: '' }]);
  };

  const removePair = (id: number) => {
    setPairs(pairs.filter(p => p.id !== id));
  };

  return (
    <div className="space-y-6">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
           <Label>Pares de Correspondência</Label>
           <span className="text-xs text-muted-foreground">Mínimo sugerido: 4 pares</span>
        </div>
        
        <p className="text-xs text-muted-foreground mb-2">Digite as chaves da esquerda e seus correspondentes da direita. O app embaralhará a coluna da direita.</p>
        
        <div className="space-y-3">
          {pairs.map((pair) => (
            <div key={pair.id} className="flex gap-3 items-start">
              <div className="flex-1 space-y-1">
                <Input placeholder="Esquerda (Ex: Davi)" value={pair.left} />
              </div>
              <div className="pt-2.5 text-muted-foreground">
                 <ArrowRightLeft className="w-5 h-5" />
              </div>
              <div className="flex-1 space-y-1">
                <Input placeholder="Direita (Ex: Golias)" value={pair.right} />
              </div>
              <Button 
                variant="outline" 
                size="icon" 
                className="text-destructive hover:bg-destructive/10" 
                disabled={pairs.length <= 2}
                onClick={() => removePair(pair.id)}
              >
                <Trash2 className="w-4 h-4" />
              </Button>
            </div>
          ))}
        </div>

        <Button variant="outline" size="sm" onClick={addPair} className="w-full mt-2">
          <Plus className="w-4 h-4 mr-2" /> Adicionar Novo Par
        </Button>
      </div>

      <div className="space-y-2">
        <Label>Explicação Geral do Desafio</Label>
        <Textarea placeholder="Explicação pós desafio..." className="resize-none h-20" />
      </div>
    </div>
  );
};
