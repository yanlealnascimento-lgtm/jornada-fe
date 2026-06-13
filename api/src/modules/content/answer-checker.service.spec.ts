import { AnswerCheckerService } from './answer-checker.service';
import { IExercise } from './exercise.model';

describe('🕹️ AnswerCheckerService Unit Tests', () => {
  let checker: AnswerCheckerService;

  beforeEach(() => {
    checker = new AnswerCheckerService();
  });

  describe('fill_blank', () => {
    it('Should validate correctly ignoring cases and accents', () => {
      const exercise = { 
        type: 'fill_blank', 
        correct_answer: 'Ressurreição' 
      } as IExercise;

      expect(checker.checkAnswer(exercise, 'ressurreicao')).toBe(true);
      expect(checker.checkAnswer(exercise, 'RESSURREIÇÃO')).toBe(true);
    });

    it('Should reject incorrect text', () => {
      const exercise = { 
        type: 'fill_blank', 
        correct_answer: 'Ressurreição' 
      } as IExercise;

      expect(checker.checkAnswer(exercise, 'Morte')).toBe(false);
    });
  });

  describe('sort_words', () => {
    it('Should validate exact correct order', () => {
      const exercise = { 
        type: 'sort_words', 
        correct_order: ['Pai', 'nosso', 'que', 'estás'] 
      } as IExercise;

      expect(checker.checkAnswer(exercise, ['Pai', 'nosso', 'que', 'estás'])).toBe(true);
    });

    it('Should reject partial or incorrect order', () => {
      const exercise = { 
        type: 'sort_words', 
        correct_order: ['Pai', 'nosso', 'que', 'estás'] 
      } as IExercise;

      expect(checker.checkAnswer(exercise, ['Pai', 'nosso', 'estás', 'que'])).toBe(false);
      expect(checker.checkAnswer(exercise, ['Pai', 'nosso'])).toBe(false);
    });
  });

  describe('multiple_choice', () => {
    it('Should correctly find the option by ID', () => {
      const exercise = { 
        type: 'multiple_choice',
        options: [
            { id: 'a', text: 'Nazaré', is_correct: false },
            { id: 'b', text: 'Belém', is_correct: true }
        ]
      } as IExercise;

      expect(checker.checkAnswer(exercise, 'b')).toBe(true);
      expect(checker.checkAnswer(exercise, 'a')).toBe(false);
    });
  });

  // ### 🧪 Plano de Testes
  // - [x] Testar case-insensitivity nas string types
  // - [x] Testar manipulação incorreta de arrays no Sort
});
