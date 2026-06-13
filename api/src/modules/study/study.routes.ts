import { Router, Request, Response, NextFunction } from 'express';
import { BibleStudyModel } from './bible-study.model';
import { UserStudyProgressModel } from './user-study-progress.model';
import { studyAIService } from './study-ai.service';
import { studyAccessService } from './study-access.service';
import { sendSuccess, sendError } from '../../shared/utils/response.util';
import { SEED_BIBLE_STUDIES } from './bible-study.seed';
import { LeagueService } from '../leagues/league.service';
import { UserModel } from '../users/user.model';
import { getWeekKey } from '../../shared/utils/date.util';

// ═══════════════════════════════════════════════
// PUBLIC ROUTES (App Flutter)
// ═══════════════════════════════════════════════

const publicRouter = Router();

// GET /api/v1/studies — Listar estudos publicados
publicRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { category, difficulty, search, featured } = req.query;
    const filter: Record<string, any> = { is_published: true };
    if (category) filter.category = category;
    if (difficulty) filter.difficulty = difficulty;
    if (featured === 'true') filter.is_featured = true;
    if (search) filter.title = { $regex: search, $options: 'i' };

    const studies = await BibleStudyModel.find(filter)
      .select('-lessons.ai_explanation_cache -lessons.ai_cached_at -lessons.quiz_mc -lessons.quiz_fill -lessons.quiz_order')
      .populate('character_id', 'name title avatar_url')
      .sort({ order: 1 })
      .lean();

    return sendSuccess(res, studies);
  } catch (error) { next(error); }
});

// GET /api/v1/studies/:slug — Detalhe do estudo (sem cache IA, com quizzes)
publicRouter.get('/:slug', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const study = await BibleStudyModel.findOne({ slug: req.params.slug, is_published: true })
      .select('-lessons.ai_explanation_cache -lessons.ai_cached_at')
      .populate('character_id', 'name title avatar_url personality')
      .lean();
    if (!study) return sendError(res, 'Estudo não encontrado', 'NOT_FOUND', 404);
    return sendSuccess(res, study);
  } catch (error) { next(error); }
});

// POST /api/v1/studies/:slug/start — Verificar acesso + criar progress
publicRouter.post('/:slug/start', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { user_id, user_is_premium } = req.body;
    if (!user_id) return sendError(res, 'user_id obrigatório', 'VALIDATION_ERROR', 400);

    const study = await BibleStudyModel.findOne({ slug: req.params.slug, is_published: true });
    if (!study) return sendError(res, 'Estudo não encontrado', 'NOT_FOUND', 404);

    const access = await studyAccessService.canAccess(user_id, study.is_premium, user_is_premium === true);
    if (!access.allowed) return sendSuccess(res, { access }, 'Acesso negado');

    // Create or get progress
    let progress = await UserStudyProgressModel.findOne({ user_id, study_id: study._id });
    if (!progress) {
      progress = await UserStudyProgressModel.create({
        user_id,
        study_id: study._id,
        study_slug: study.slug,
        status: 'in_progress',
        started_at: new Date(),
        last_activity: new Date(),
      });
    }

    return sendSuccess(res, { access, progress });
  } catch (error) { next(error); }
});

// GET /api/v1/studies/:slug/lessons/:index/ai — Buscar explicação IA
publicRouter.get('/:slug/lessons/:index/ai', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const study = await BibleStudyModel.findOne({ slug: req.params.slug })
      .populate('character_id', 'name');
    if (!study) return sendError(res, 'Estudo não encontrado', 'NOT_FOUND', 404);

    const lessonIndex = parseInt(req.params.index, 10);
    const lesson = study.lessons[lessonIndex];
    if (!lesson) return sendError(res, 'Lição não encontrada', 'NOT_FOUND', 404);

    const characterName = (study.character_id as any)?.name || 'Dove';
    const explanation = await studyAIService.getExplanation(
      study._id.toString(), lessonIndex,
      lesson.verse_ref, lesson.verse_text,
      characterName, study.difficulty,
    );

    return sendSuccess(res, { explanation });
  } catch (error) { next(error); }
});

// POST /api/v1/studies/:slug/lessons/:index/complete — Completar lição
publicRouter.post('/:slug/lessons/:index/complete', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { user_id, pf_earned } = req.body;
    if (!user_id) return sendError(res, 'user_id obrigatório', 'VALIDATION_ERROR', 400);

    const study = await BibleStudyModel.findOne({ slug: req.params.slug });
    if (!study) return sendError(res, 'Estudo não encontrado', 'NOT_FOUND', 404);

    const lessonIndex = parseInt(req.params.index, 10);
    const lesson = study.lessons[lessonIndex];
    if (!lesson) return sendError(res, 'Lição não encontrada', 'NOT_FOUND', 404);

    const progress = await UserStudyProgressModel.findOne({ user_id, study_id: study._id });
    if (!progress) return sendError(res, 'Progresso não encontrado. Inicie o estudo primeiro.', 'NOT_FOUND', 404);

    // Mark lesson completed
    if (!progress.lessons_completed.includes(lessonIndex)) {
      progress.lessons_completed.push(lessonIndex);
    }
    progress.pf_earned += (pf_earned || lesson.pf_reward);
    progress.mana_earned += lesson.mana_reward;
    progress.current_lesson = Math.max(progress.current_lesson, lessonIndex + 1);
    progress.last_activity = new Date();

    if (progress.lessons_completed.length >= study.total_lessons) {
      progress.status = 'completed';
      progress.completed_at = new Date();
      // Increment total completions
      await BibleStudyModel.updateOne({ _id: study._id }, { $inc: { total_completions: 1 } });
    }
    await progress.save();

    // Persist PF to user document
    const totalPF = pf_earned || lesson.pf_reward;
    if (totalPF > 0) {
      try {
        await UserModel.findByIdAndUpdate(user_id, {
          $inc: { pf_total: Number(totalPF), pf_weekly: Number(totalPF) },
        });
      } catch (_) {}
    }

    // Add PF to user's league (fire-and-forget)
    if (totalPF > 0) {
      try {
        const leagueService = new LeagueService();
        const user = await UserModel.findById(user_id).select('league_tier').lean();
        const tier = (user as any)?.league_tier || 'ruben';
        const weekKey = getWeekKey();
        await leagueService.addPFToLeague(user_id, tier, weekKey, totalPF);
      } catch (_) { /* silent — league PF is best-effort */ }
    }

    return sendSuccess(res, progress, 'Lição concluída');
  } catch (error) { next(error); }
});

// GET /api/v1/studies/:slug/progress — Progresso do usuário
publicRouter.get('/:slug/progress', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { user_id } = req.query;
    if (!user_id) return sendError(res, 'user_id obrigatório', 'VALIDATION_ERROR', 400);

    const study = await BibleStudyModel.findOne({ slug: req.params.slug }).select('_id');
    if (!study) return sendError(res, 'Estudo não encontrado', 'NOT_FOUND', 404);

    const progress = await UserStudyProgressModel.findOne({ user_id, study_id: study._id });
    return sendSuccess(res, progress || { status: 'not_started', lessons_completed: [], current_lesson: 0 });
  } catch (error) { next(error); }
});

// ═══════════════════════════════════════════════
// ADMIN ROUTES
// ═══════════════════════════════════════════════

const adminRouter = Router();

// GET /api/v1/admin/studies — Listar com stats
adminRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const studies = await BibleStudyModel.find()
      .populate('character_id', 'name avatar_url')
      .sort({ order: 1 })
      .lean();

    // Add cache stats per study
    const result = studies.map(s => {
      const totalLessons = s.lessons.length;
      const cachedLessons = s.lessons.filter(l => l.ai_explanation_cache && l.ai_cached_at).length;
      return {
        ...s,
        id: s._id,
        cache_status: totalLessons === 0 ? 'empty' : cachedLessons === totalLessons ? 'warm' : cachedLessons > 0 ? 'partial' : 'cold',
        cache_count: cachedLessons,
        cache_total: totalLessons,
      };
    });

    return sendSuccess(res, result);
  } catch (error) { next(error); }
});

// GET /api/v1/admin/studies/stats
adminRouter.get('/stats', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const all = await BibleStudyModel.find().lean();
    const totalLessons = all.reduce((s, st) => s + st.lessons.length, 0);
    const cachedLessons = all.reduce((s, st) => s + st.lessons.filter(l => l.ai_explanation_cache).length, 0);

    return sendSuccess(res, {
      total: all.length,
      published: all.filter(s => s.is_published).length,
      draft: all.filter(s => !s.is_published).length,
      premium: all.filter(s => s.is_premium).length,
      free: all.filter(s => !s.is_premium).length,
      featured: all.filter(s => s.is_featured).length,
      total_lessons: totalLessons,
      cached_lessons: cachedLessons,
    });
  } catch (error) { next(error); }
});

// POST /api/v1/admin/studies — Criar
adminRouter.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const study = await BibleStudyModel.create(req.body);
    return sendSuccess(res, { ...study.toObject(), id: study._id }, 'Estudo criado', 201);
  } catch (error) { next(error); }
});

// GET /api/v1/admin/studies/:id
adminRouter.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const study = await BibleStudyModel.findById(req.params.id).populate('character_id', 'name avatar_url').lean();
    if (!study) return sendError(res, 'Estudo não encontrado', 'NOT_FOUND', 404);
    return sendSuccess(res, { ...study, id: study._id });
  } catch (error) { next(error); }
});

// PUT /api/v1/admin/studies/:id
adminRouter.put('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    // If lessons changed, recalculate total
    if (req.body.lessons) req.body.total_lessons = req.body.lessons.length;

    const study = await BibleStudyModel.findByIdAndUpdate(req.params.id, { $set: req.body }, { new: true });
    if (!study) return sendError(res, 'Estudo não encontrado', 'NOT_FOUND', 404);
    return sendSuccess(res, { ...study.toObject(), id: study._id }, 'Estudo atualizado');
  } catch (error) { next(error); }
});

// DELETE /api/v1/admin/studies/:id
adminRouter.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const study = await BibleStudyModel.findByIdAndDelete(req.params.id);
    if (!study) return sendError(res, 'Estudo não encontrado', 'NOT_FOUND', 404);
    await UserStudyProgressModel.deleteMany({ study_id: study._id });
    return sendSuccess(res, null, 'Estudo removido');
  } catch (error) { next(error); }
});

// POST /api/v1/admin/studies/:id/warm-cache
adminRouter.post('/:id/warm-cache', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await studyAIService.warmUpCache(req.params.id);
    return sendSuccess(res, result, 'Cache aquecido');
  } catch (error) { next(error); }
});

// POST /api/v1/admin/studies/seed
adminRouter.post('/seed', async (req: Request, res: Response, next: NextFunction) => {
  try {
    let created = 0, updated = 0;
    for (const data of SEED_BIBLE_STUDIES) {
      const existing = await BibleStudyModel.findOne({ slug: data.slug });
      if (existing) {
        updated++;
      } else {
        await BibleStudyModel.create({ ...data, total_lessons: data.lessons.length });
        created++;
      }
    }
    return sendSuccess(res, { created, updated }, 'Seed concluído');
  } catch (error) { next(error); }
});

export const studyPublicRoutes = publicRouter;
export const studyAdminRoutes = adminRouter;
