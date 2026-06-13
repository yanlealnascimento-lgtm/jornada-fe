import React from 'react';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { RadioGroup, RadioGroupItem } from '../ui/radio-group';

export const TrueFalseForm: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <Label>Afirmação</Label>
        <Textarea placeholder="Ex: Jesus foi batizado por Pedro no Rio Jordão." className="resize-none h-24" />
      </div>

      <div className="space-y-3">
        <Label>Esta afirmação é:</Label>
        <RadioGroup defaultValue="false" className="flex gap-6">
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="true" id="true" />
            <Label htmlFor="true" className="font-bold text-emerald-600">Verdadeira</Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="false" id="false" />
            <Label htmlFor="false" className="font-bold text-destructive">Falsa</Label>
          </div>
        </RadioGroup>
      </div>

      <div className="space-y-2 mt-4">
        <Label>Explicação do Fato</Label>
        <Textarea placeholder="Ex: Falso. Jesus foi batizado por João Batista, não por Pedro." className="resize-none h-20" />
      </div>
    </div>
  );
};
