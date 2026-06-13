import { IExercise } from './exercise.model';

export class AnswerCheckerService {
  
  public checkAnswer(exercise: IExercise, answer: any): boolean {
    switch (exercise.type) {
      case 'multiple_choice':
        return this.checkMultipleChoice(exercise, answer);
      case 'fill_blank':
        return this.checkFillBlank(exercise, answer);
      case 'sort_words':
        return this.checkSortWords(exercise, answer);
      case 'pair_match':
        return this.checkPairMatch(exercise, answer);
      case 'true_false':
        return this.checkTrueFalse(exercise, answer);
      default:
        return false;
    }
  }

  private checkMultipleChoice(exercise: IExercise, answer: string): boolean {
    if (!exercise.options) return false;
    const selectedOption = exercise.options.find(opt => opt.id === answer);
    return selectedOption?.is_correct || false;
  }

  private checkFillBlank(exercise: IExercise, answer: string): boolean {
    if (!exercise.correct_answer || !answer) return false;
    
    const normalize = (str: string) => 
      str.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
      
    return normalize(exercise.correct_answer) === normalize(answer);
  }

  private checkSortWords(exercise: IExercise, answer: string[]): boolean {
    if (!exercise.correct_order || !answer || !Array.isArray(answer)) return false;
    
    if (exercise.correct_order.length !== answer.length) return false;
    
    for (let i = 0; i < exercise.correct_order.length; i++) {
        if (exercise.correct_order[i] !== answer[i]) return false;
    }
    
    return true;
  }

  private checkPairMatch(exercise: IExercise, answer: {left: string, right: string}[]): boolean {
    if (!exercise.pairs || !answer || !Array.isArray(answer)) return false;
    
    // Todos os pares corretos devem existir na resposta (considerando esquerda e direita)
    for (const correctPair of exercise.pairs) {
        const matchingAnswer = answer.find(a => a.left === correctPair.left && a.right === correctPair.right);
        if (!matchingAnswer) return false;
    }
    
    return true;
  }

  private checkTrueFalse(exercise: IExercise, answer: boolean): boolean {
    if (!exercise.options || exercise.options.length === 0) return false;
    // Opcionalmente, pode-se tratar true/false como options ou um field isolado. 
    // Assumindo true_false usando checkMultipleChoice logic via is_correct
    const correctOptionId = exercise.options.find(o => o.is_correct)?.id;
    return answer.toString() === correctOptionId;
  }
}
