import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';
import { Button } from '../components/ui/button';
import { ExerciseEditor } from '../components/ExerciseEditor/ExerciseEditor';

export const LessonEditorPage: React.FC = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  return (
    <div className="animate-in fade-in slide-in-from-bottom-2 duration-500">
      <div className="mb-6">
         <Button variant="ghost" className="text-muted-foreground -ml-4" onClick={() => navigate(-1)}>
            <ArrowLeft className="w-4 h-4 mr-2" /> Voltar para a Unidade
         </Button>
      </div>
      
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Edição de Lição {id ? `#${id}` : ''}</h1>
        <p className="text-muted-foreground">Preencha o conteúdo teórico e logo em seguida mapeie os exercícios gamificados.</p>
      </div>

      <ExerciseEditor />
    </div>
  );
};
