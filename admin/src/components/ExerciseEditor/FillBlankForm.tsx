import React, { useState } from 'react';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Input } from '../ui/input';

export const FillBlankForm: React.FC = () => {
  const [verse, setVerse] = useState('');

  const renderPreview = () => {
    if (!verse) return <span className="text-muted-foreground italic">Comece a digitar o versículo acima usando cochetes para lacunas...</span>;
    
    // Substitui [palavra] por sublinhados no preview
    const parts = verse.split(/(\[[^[\]]*\])/g);
    return parts.map((part, i) => {
      if (part.startsWith('[') && part.endsWith(']')) {
        return <span key={i} className="inline-block border-b-2 border-primary text-primary font-bold px-2 mx-1 min-w-[60px] text-center bg-primary/10 rounded-sm pb-0.5">{part.slice(1, -1)}</span>;
      }
      return <span key={i}>{part}</span>;
    });
  };

  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <Label>Versículo com Lacunas</Label>
        <p className="text-xs text-muted-foreground mb-2">Cerque a palavra que deve ser preenchida com colchetes. Exemplo: "O Senhor é o meu [pastor], nada me faltará."</p>
        <Textarea 
          placeholder="Digite o versículo..." 
          className="resize-none h-24" 
          value={verse}
          onChange={(e) => setVerse(e.target.value)}
        />
      </div>

      {/* Preview Automático */}
      <div className="p-4 bg-slate-50 dark:bg-zinc-900 border rounded-lg">
         <Label className="text-xs text-muted-foreground uppercase tracking-wider mb-2 block">Pré-visualização (App)</Label>
         <div className="text-lg leading-relaxed font-serif">
            {renderPreview()}
         </div>
      </div>

      <div className="space-y-2">
        <Label>Banco de Palavras Extras (Distratores)</Label>
        <p className="text-xs text-muted-foreground">Separe por vírgulas. Essas palavras aparecerão junto com as corretas para confundir o jogador.</p>
        <Input placeholder="Ex: rei, mestre, amigo" />
      </div>

      <div className="space-y-2">
        <Label>Explicação</Label>
        <Textarea placeholder="Explicação pós desafio..." className="resize-none h-20" />
      </div>
    </div>
  );
};
