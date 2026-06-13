import React from 'react';
import { Label } from '../ui/label';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { RadioGroup, RadioGroupItem } from '../ui/radio-group';

export const MultipleChoiceForm: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <Label>Pergunta do Exercício</Label>
        <Textarea placeholder="Ex: Onde Jesus nasceu?" className="resize-none" />
      </div>

      <div className="space-y-4">
        <Label className="text-muted-foreground">Alternativas (Marque a correta na esquerda)</Label>
        <RadioGroup defaultValue="b" className="space-y-3">
          {['A', 'B', 'C', 'D'].map((opt) => (
            <div key={opt} className="flex items-center space-x-3">
              <RadioGroupItem value={opt.toLowerCase()} id={`opt-${opt}`} className="mt-1" />
              <div className="flex-1">
                <Input placeholder={`Opção ${opt}`} />
              </div>
            </div>
          ))}
        </RadioGroup>
      </div>

      <div className="space-y-2">
        <Label>Referência Bíblica (Opcional)</Label>
        <Input placeholder="Ex: Lucas 2:4-7" />
      </div>

      <div className="space-y-2">
        <Label>Explicação em Caso de Erro</Label>
        <Textarea placeholder="Ex: Jesus nasceu em Belém, a cidade de Davi, para cumprir as profecias." className="resize-none" />
      </div>
    </div>
  );
};
