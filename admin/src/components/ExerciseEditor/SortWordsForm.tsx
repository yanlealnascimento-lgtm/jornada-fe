import React, { useState } from 'react';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Shuffle } from 'lucide-react';

export const SortWordsForm: React.FC = () => {
  const [verse, setVerse] = useState('');

  // A simple deterministic shuffle just to show a visual preview to the admin
  const shuffledWords = verse.split(' ').filter(w => w.trim().length > 0).sort(() => 0.5 - Math.random());

  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <Label>Versículo Correto</Label>
        <p className="text-xs text-muted-foreground mb-2">Digite o versículo na ordem exata. O aplicativo se encarregará de fatiar cada palavra e embaralhá-las para o jogador.</p>
        <Textarea 
          placeholder="Ex: No princípio, criou Deus os céus e a terra." 
          className="resize-none h-24" 
          value={verse}
          onChange={(e) => setVerse(e.target.value)}
        />
      </div>

      {/* Preview do Embaralhamento */}
      <div className="p-4 bg-slate-50 dark:bg-zinc-900 border rounded-lg space-y-3">
         <Label className="text-xs text-muted-foreground uppercase tracking-wider block flex items-center gap-1">
            <Shuffle className="w-3 h-3" /> Exemplo de Embaralhamento (App)
         </Label>
         <div className="flex flex-wrap gap-2">
            {shuffledWords.length === 0 && <span className="text-sm italic text-muted-foreground">Aguardando texto...</span>}
            {shuffledWords.map((word, i) => (
                <div key={i} className="px-3 py-1.5 bg-white dark:bg-zinc-800 border shadow-sm rounded-md font-medium text-sm">
                    {word}
                </div>
            ))}
         </div>
      </div>

      <div className="space-y-2">
        <Label>Explicação</Label>
        <Textarea placeholder="Ex: Gênesis 1:1 é o início de toda a bíblia..." className="resize-none h-20" />
      </div>
    </div>
  );
};
