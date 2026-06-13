import { BibleStudyModel } from './bible-study.model';

const CACHE_TTL_DAYS = 30;

export class StudyAIService {
  async getExplanation(
    studyId: string,
    lessonIndex: number,
    verseRef: string,
    verseText: string,
    characterName: string,
    difficulty: string,
  ): Promise<string> {
    const study = await BibleStudyModel.findById(studyId);
    if (!study) throw new Error('STUDY_NOT_FOUND');

    const lesson = study.lessons[lessonIndex];
    if (!lesson) throw new Error('LESSON_NOT_FOUND');

    // Cache valido -> retornar imediatamente
    if (lesson.ai_explanation_cache && lesson.ai_cached_at) {
      const ageInDays = (Date.now() - lesson.ai_cached_at.getTime()) / (1000 * 60 * 60 * 24);
      if (ageInDays < CACHE_TTL_DAYS) return lesson.ai_explanation_cache;
    }

    // Gerar nova explicacao
    const explanation = await this._generate(verseRef, verseText, characterName, difficulty);

    // Persistir no MongoDB
    await BibleStudyModel.updateOne(
      { _id: studyId },
      {
        $set: {
          [`lessons.${lessonIndex}.ai_explanation_cache`]: explanation,
          [`lessons.${lessonIndex}.ai_cached_at`]: new Date(),
        },
      },
    );

    return explanation;
  }

  private async _generate(
    verseRef: string,
    verseText: string,
    characterName: string,
    difficulty: string,
  ): Promise<string> {
    const levelGuide: Record<string, string> = {
      beginner: 'linguagem simples, sem termos teológicos complexos',
      intermediate: 'pode usar termos bíblicos com breve explicação',
      advanced: 'pode aprofundar em hermenêutica e contexto cultural hebraico/grego',
    };

    // Try Anthropic API if key available
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (apiKey) {
      try {
        // Dynamic import — only loaded if ANTHROPIC_API_KEY is set
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const Anthropic = require('@anthropic-ai/sdk').default || require('@anthropic-ai/sdk');
        const anthropic = new Anthropic({ apiKey });

        const msg = await anthropic.messages.create({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 150,
          messages: [{
            role: 'user',
            content: `Você é professor bíblico no app JourneyFaith, parceiro do personagem ${characterName}.
Explique o versículo "${verseRef}: ${verseText}" teologicamente.
Nível: ${levelGuide[difficulty] || levelGuide.beginner}.
Formato: exatamente 2 frases curtas e diretas (máx 60 palavras total).
Tom: motivacional, acolhedor, prático.
IMPORTANTE: NÃO comece com "Este versículo", "Jesus diz" ou qualquer introdução. Vá direto ao conteúdo.`,
          }],
        });

        return (msg.content[0] as { type: string; text: string }).text;
      } catch (err) {
        console.error('[StudyAI] Anthropic API error:', (err as Error).message);
      }
    }

    // Fallback: generate a contextual explanation without API
    return this._fallbackExplanation(verseRef, verseText);
  }

  private _fallbackExplanation(verseRef: string, verseText: string): string {
    const firstWords = verseText.split(' ').slice(0, 6).join(' ');
    return `${firstWords}... — esta passagem de ${verseRef} nos convida a uma reflexão profunda sobre a fé e a ação de Deus em nossas vidas. Cada palavra carrega um significado transformador para o nosso dia a dia.`;
  }

  async warmUpCache(studyId: string): Promise<{ warmed: number; skipped: number; errors: string[] }> {
    const study = await BibleStudyModel.findById(studyId).populate('character_id', 'name');
    if (!study) throw new Error('STUDY_NOT_FOUND');

    const characterName = (study.character_id as any)?.name || 'Dove';
    let warmed = 0, skipped = 0;
    const errors: string[] = [];

    for (let i = 0; i < study.lessons.length; i++) {
      const lesson = study.lessons[i];
      if (lesson.ai_explanation_cache && lesson.ai_cached_at) {
        const age = (Date.now() - lesson.ai_cached_at.getTime()) / (1000 * 60 * 60 * 24);
        if (age < CACHE_TTL_DAYS) { skipped++; continue; }
      }
      if (i > 0) await new Promise(r => setTimeout(r, 600));
      try {
        await this.getExplanation(
          study._id.toString(), i,
          lesson.verse_ref, lesson.verse_text,
          characterName, study.difficulty,
        );
        warmed++;
      } catch (e) {
        errors.push(`Lição ${i}: ${(e as Error).message}`);
      }
    }
    return { warmed, skipped, errors };
  }
}

export const studyAIService = new StudyAIService();
