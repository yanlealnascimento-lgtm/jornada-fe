import { useState } from 'react';
import { Button } from './ui/button';
import { Database, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { useQueryClient, useMutation } from '@tanstack/react-query';
import api from '../services/api';

interface SeedDataButtonProps {
  data: any[];
  endpoint: string;
  queryKey: string[];
}

export function SeedDataButton({ data, endpoint, queryKey }: SeedDataButtonProps) {
  const queryClient = useQueryClient();
  const [isLoading, setIsLoading] = useState(false);

  const mutation = useMutation({
    mutationFn: async () => {
      setIsLoading(true);
      try {
        console.log(`[SEED] Iniciando seed em lote para ${endpoint}...`);
        const response: any = await api.post('/seed-all', { data, endpoint });
        
        const successCount = response.data?.success || 0;
        const errorCount = response.data?.error || 0;
        const conflictCount = response.data?.conflict || 0;
        
        if (successCount > 0) {
          toast.success(`${successCount} registros criados em ${endpoint}!`);
          queryClient.invalidateQueries({ queryKey });
        }
        
        if (conflictCount > 0) {
          toast.info(`${conflictCount} registros já existiam.`);
        }

        if (errorCount > 0) {
          toast.error(`${errorCount} erros durante o seed.`);
        }
        
        return response.data;
      } catch (error: any) {
        console.error('[SEED] Erro fatal:', error);
        toast.error(`Falha ao processar sementes: ${error.message}`);
        throw error;
      } finally {
        setIsLoading(false);
      }
    }
  });

  return (
    <Button 
      variant="outline" 
      size="sm" 
      onClick={() => mutation.mutate()} 
      disabled={isLoading}
      className="flex items-center gap-2"
    >
      {isLoading ? (
        <Loader2 className="w-4 h-4 animate-spin" />
      ) : (
        <Database className="w-4 h-4 text-blue-500" />
      )}
      Carregar Dados de Exemplo
    </Button>
  );
}
