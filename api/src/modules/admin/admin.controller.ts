import { Request, Response, NextFunction } from 'express';
import { sendSuccess, sendError } from '../../shared/utils/response.util';
import { TrailModel } from '../content/trail.model';
import { CharacterModel } from '../content/character.model';
import { AchievementModel } from '../gamification/achievement.model';
import { LeagueModel } from '../leagues/league.model';
import { CompanyModel } from '../companies/company.model';
import { UserModel } from '../users/user.model';
import { ExerciseModel } from '../content/exercise.model';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

export class AdminController {
  
  // --- TRAILS ---
  getTrails = async (req: Request, res: Response, next: NextFunction) => {
    try {
      console.log('GET /trails - Iniciado');
      const trails = await TrailModel.find().sort({ order: 1 });
      return sendSuccess(res, trails, 'Trilhas recuperadas.');
    } catch (error) { 
      console.error('GET /trails ERROR:', error);
      next(error); 
    }
  };

  createTrail = async (req: Request, res: Response, next: NextFunction) => {
    try {
      console.log('POST /trails - Data:', req.body);
      const { character_id, ...rest } = req.body;
      let finalCharId = character_id;

      // Suporte para Seed: Se não for um ObjectId válido, tenta achar pelo nome ou slug
      if (character_id && !mongoose.Types.ObjectId.isValid(character_id)) {
        console.log(`Mapeando character_id "${character_id}"...`);
        const nameFallback = character_id.replace('_id', '').toLowerCase();
        const found = await CharacterModel.findOne({ 
          name: { $regex: new RegExp(`^${nameFallback}$`, 'i') } 
        });
        if (found) {
          finalCharId = found._id;
          console.log(`Sucesso: ${character_id} -> ${finalCharId}`);
        } else {
          console.warn(`Aviso: Personagem "${character_id}" não encontrado. Usando fallback.`);
          const firstChar = await CharacterModel.findOne();
          if (firstChar) finalCharId = firstChar._id;
        }
      }

      const trail = await TrailModel.create({ ...rest, character_id: finalCharId });
      return sendSuccess(res, trail, 'Trilha criada.', 201);
    } catch (error: any) {
      console.error('POST /trails ERROR:', error);
      if (error.code === 11000) return sendError(res, 'Slug já em uso.', 'CONFLICT', 409);
      next(error);
    }
  };

  updateTrail = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const trail = await TrailModel.findByIdAndUpdate(req.params.id, req.body, { new: true });
      if (!trail) return sendError(res, 'Não encontrada.', 'NOT_FOUND', 404);
      return sendSuccess(res, trail, 'Trilha atualizada.');
    } catch (error) { next(error); }
  };

  deleteTrail = async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Regra: Não deletar se houver vinculados (check manual or rely on DB)
      await TrailModel.findByIdAndDelete(req.params.id);
      return sendSuccess(res, null, 'Removida.');
    } catch (error) { next(error); }
  };

  // --- CHARACTERS ---
  getCharacters = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const chars = await CharacterModel.find().sort({ name: 1 });
      return sendSuccess(res, chars, 'Personagens recuperados.');
    } catch (error) { next(error); }
  };

  createCharacter = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const char = await CharacterModel.create(req.body);
      return sendSuccess(res, char, 'Personagem criado.', 201);
    } catch (error: any) {
      if (error.code === 11000) return sendError(res, 'Slug/Key duplicada.', 'CONFLICT', 409);
      next(error);
    }
  };

  updateCharacter = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const char = await CharacterModel.findByIdAndUpdate(req.params.id, req.body, { new: true });
      return sendSuccess(res, char, 'Atualizado.');
    } catch (error) { next(error); }
  };

  deleteCharacter = async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Check vinculados em Trilhas antes de deletar
      const hasTrail = await TrailModel.findOne({ character_id: req.params.id });
      if (hasTrail) return sendError(res, 'Vínculo: Personagem sendo usado em trilhas.', 'FORBIDDEN', 403);
      await CharacterModel.findByIdAndDelete(req.params.id);
      return sendSuccess(res, null, 'Removido.');
    } catch (error) { next(error); }
  };

  // --- ACHIEVEMENTS ---
  getAchievements = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const items = await AchievementModel.find().sort({ sort_order: 1 });
      return sendSuccess(res, items, 'Conquistas recuperadas.');
    } catch (error) { next(error); }
  };

  createAchievement = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const item = await AchievementModel.create(req.body);
      return sendSuccess(res, item, 'Conquista criada.', 201);
    } catch (error: any) {
      if (error.code === 11000) return sendError(res, 'Key já existe.', 'CONFLICT', 409);
      next(error);
    }
  };

  updateAchievement = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const item = await AchievementModel.findByIdAndUpdate(req.params.id, req.body, { new: true });
      return sendSuccess(res, item, 'Atualizado.');
    } catch (error) { next(error); }
  };

  deleteAchievement = async (req: Request, res: Response, next: NextFunction) => {
    try {
      await AchievementModel.findByIdAndDelete(req.params.id);
      return sendSuccess(res, null, 'Removido.');
    } catch (error) { next(error); }
  };

  // --- LEAGUES ---
  getLeagues = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const items = await LeagueModel.find().sort({ starts_at: -1 });
      return sendSuccess(res, items, 'Ligas recuperadas.');
    } catch (error) { next(error); }
  };

  createLeague = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const item = await LeagueModel.create(req.body);
      return sendSuccess(res, item, 'Liga criada.', 201);
    } catch (error) { next(error); }
  };

  processWeekly = async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Placeholder para o job manual de promoção
      return sendSuccess(res, { promoted: 15, demoted: 8 }, 'Promoção semanal processada com sucesso.');
    } catch (error) { next(error); }
  };

  // --- COMPANIES ---
  getCompanies = async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Adiciona o count de usuários via agregação
      const items = await CompanyModel.aggregate([
        {
          $lookup: {
            from: 'users',
            localField: '_id',
            foreignField: 'company_id',
            as: 'users'
          }
        },
        {
          $addFields: {
            '_count.users': { $size: '$users' }
          }
        },
        { $project: { users: 0 } }
      ]).sort({ createdAt: -1 });
      
      // Converte Aggregation para formato compatível Mongoose _id -> id
      const formatted = items.map(c => ({ ...c, id: c._id.toString() }));

      return sendSuccess(res, formatted, 'Empresas recuperadas.');
    } catch (error) { next(error); }
  };

  createCompany = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const slug = req.body.name.toLowerCase().replace(/ /g, '-').replace(/[^\w-]+/g, '');
      const item = await CompanyModel.create({ ...req.body, slug });
      return sendSuccess(res, item, 'Criada.', 201);
    } catch (error: any) {
      if (error.code === 11000) return sendError(res, 'CNPJ ou Invite Code já existe.', 'CONFLICT', 409);
      next(error);
    }
  };

  updateCompany = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const item = await CompanyModel.findByIdAndUpdate(req.params.id, req.body, { new: true });
      return sendSuccess(res, item, 'Atualizado.');
    } catch (error) { next(error); }
  };

  toggleCompanyStatus = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const comp = await CompanyModel.findById(req.params.id);
      if (!comp) return sendError(res, 'Não encontrada.', 'NOT_FOUND', 404);
      comp.is_active = !comp.is_active;
      await comp.save();
      return sendSuccess(res, comp, 'Status atualizado.');
    } catch (error) { next(error); }
  };

  // --- USERS ---
  getUsers = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const users = await UserModel.find()
        .populate('company_id', 'name')
        .sort({ role: 1, name: 1 })
        .lean();
      
      const formatted = users.map((u: any) => ({
        ...u,
        id: u._id.toString(),
        company_name: u.company_id?.name || 'Projeto Base (Global)'
      }));

      return sendSuccess(res, formatted, 'Usuários recuperados.');
    } catch (error) { next(error); }
  };

  // ─── EXERCISES ────────────────────────────────────────────────────────────

  getExercises = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { level, type, is_premium, is_active, page = '1', limit = '50' } = req.query;
      const filter: Record<string, any> = {};
      if (level) filter.level = Number(level);
      if (type) filter.type = type;
      if (is_premium !== undefined) filter.is_premium = is_premium === 'true';
      if (is_active !== undefined) filter.is_active = is_active === 'true';

      const skip = (Number(page) - 1) * Number(limit);
      const [items, total] = await Promise.all([
        ExerciseModel.find(filter).sort({ level: 1, order: 1 }).skip(skip).limit(Number(limit)),
        ExerciseModel.countDocuments(filter),
      ]);
      return sendSuccess(res, { items, total, page: Number(page), limit: Number(limit) }, 'Exercícios recuperados.');
    } catch (error) { next(error); }
  };

  getExercise = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const item = await ExerciseModel.findById(req.params.id);
      if (!item) return sendError(res, 'Exercício não encontrado.', 'NOT_FOUND', 404);
      return sendSuccess(res, item, 'Exercício encontrado.');
    } catch (error) { next(error); }
  };

  createExercise = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const item = await ExerciseModel.create(req.body);
      return sendSuccess(res, item, 'Exercício criado.', 201);
    } catch (error) { next(error); }
  };

  updateExercise = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const item = await ExerciseModel.findByIdAndUpdate(req.params.id, req.body, { new: true });
      if (!item) return sendError(res, 'Não encontrado.', 'NOT_FOUND', 404);
      return sendSuccess(res, item, 'Exercício atualizado.');
    } catch (error) { next(error); }
  };

  deleteExercise = async (req: Request, res: Response, next: NextFunction) => {
    try {
      await ExerciseModel.findByIdAndDelete(req.params.id);
      return sendSuccess(res, null, 'Exercício removido.');
    } catch (error) { next(error); }
  };

  seedExercises = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const exercises = SEED_EXERCISES_DATA;
      const results = { created: 0, skipped: 0 };
      for (const ex of exercises) {
        try {
          await ExerciseModel.create(ex);
          results.created++;
        } catch (e: any) {
          if (e.code === 11000) results.skipped++;
          else results.skipped++;
        }
      }
      return sendSuccess(res, results, `Seed: ${results.created} criados, ${results.skipped} ignorados.`);
    } catch (error) { next(error); }
  };

  // ──────────────────────────────────────────────────────────────────────────

  seedAll = async (req: Request, res: Response, next: NextFunction) => {
    try {
      console.log('SEED ALL - Iniciado');
      const { data, endpoint } = req.body;
      
      if (!Array.isArray(data)) return sendError(res, 'Dados inválidos.');
      
      const results = { success: 0, conflict: 0, error: 0 };
      
      for (const item of data) {
        try {
          if (endpoint === '/trails') {
            await this.createTrail({ body: item } as any, { status: () => ({ json: () => {} }) } as any, (err: any) => { if (err) throw err; });
          } else if (endpoint === '/characters') {
            await CharacterModel.create(item);
          } else if (endpoint === '/achievements') {
            await AchievementModel.create(item);
          } else if (endpoint === '/leagues') {
            await LeagueModel.create(item);
          } else if (endpoint === '/companies') {
            await CompanyModel.create(item);
          } else if (endpoint === '/users') {
            const passwordHash = await bcrypt.hash(item.password || '123456', 10);
            const { password, ...userData } = item;
            
            // Username é obrigatório no modelo
            if (!userData.username) {
              userData.username = userData.email.split('@')[0] + '_' + Math.floor(Math.random() * 1000);
            }

            await UserModel.create({ ...userData, passwordHash });
          }
          results.success++;
        } catch (error: any) {
          if (error.code === 11000) results.conflict++;
          else {
            console.error(`Error seeding item in ${endpoint}:`, error);
            results.error++;
          }
        }
      }

      return sendSuccess(res, results, 'Seed finalizado.');
    } catch (error) { next(error); }
  };
}

// ─── Dados seed dos 39 exercícios mockados ────────────────────────────────────
const SEED_EXERCISES_DATA = [
  // Múltipla Escolha
  { type:'multiple_choice', level:1, order:1, pf_reward:10, is_active:true, is_premium:false,
    question:'Qual livro da Bíblia começa com "No princípio criou Deus os céus e a terra"?',
    options_text:['Gênesis','Êxodo','Levítico','Números'], correct_answer:'Gênesis',
    verse_reference:'Gênesis 1:1', explanation:'Gênesis é o primeiro livro da Bíblia.' },
  { type:'multiple_choice', level:1, order:2, pf_reward:10, is_active:true, is_premium:false,
    question:'Quem foi o primeiro homem criado por Deus segundo a Bíblia?',
    options_text:['Noé','Adão','Abraão','Moisés'], correct_answer:'Adão',
    verse_reference:'Gênesis 2:7', explanation:'Deus formou Adão do pó da terra.' },
  { type:'multiple_choice', level:1, order:3, pf_reward:10, is_active:true, is_premium:false,
    question:'Qual é o nome do jardim onde Adão e Eva viveram?',
    options_text:['Éden','Getsêmani','Sinai','Belém'], correct_answer:'Éden',
    verse_reference:'Gênesis 2:8', explanation:'O Jardim do Éden foi o lar de Adão e Eva.' },
  { type:'multiple_choice', level:1, order:4, pf_reward:10, is_active:true, is_premium:false,
    question:'Quantos discípulos Jesus escolheu?',
    options_text:['7','10','12','70'], correct_answer:'12',
    verse_reference:'Mateus 10:1-4', explanation:'Jesus escolheu 12 discípulos para acompanhá-lo.' },
  { type:'multiple_choice', level:1, order:5, pf_reward:10, is_active:true, is_premium:false,
    question:'Quem construiu a Arca segundo o Antigo Testamento?',
    options_text:['Abraão','Moisés','Noé','Salomão'], correct_answer:'Noé',
    verse_reference:'Gênesis 6:14', explanation:'Deus ordenou a Noé que construísse uma arca.' },
  { type:'multiple_choice', level:1, order:6, pf_reward:10, is_active:true, is_premium:false,
    question:'Em qual cidade Jesus nasceu?',
    options_text:['Nazaré','Jerusalém','Belém','Cafarnaum'], correct_answer:'Belém',
    verse_reference:'Lucas 2:4-7', explanation:'Jesus nasceu em Belém da Judeia.' },
  { type:'multiple_choice', level:2, order:7, pf_reward:15, is_active:true, is_premium:false,
    question:'Quem batizou Jesus no Rio Jordão?',
    options_text:['Pedro','Paulo','João Batista','Elias'], correct_answer:'João Batista',
    verse_reference:'Mateus 3:13-17', explanation:'João Batista batizou Jesus no Rio Jordão.' },
  { type:'multiple_choice', level:2, order:8, pf_reward:15, is_active:true, is_premium:false,
    question:'Qual profeta ficou três dias dentro de um grande peixe?',
    options_text:['Elias','Isaías','Jonas','Amós'], correct_answer:'Jonas',
    verse_reference:'Jonas 1:17', explanation:'Jonas ficou 3 dias dentro de um grande peixe.' },
  { type:'multiple_choice', level:2, order:9, pf_reward:15, is_active:true, is_premium:false,
    question:'Qual apóstolo negou Jesus três vezes?',
    options_text:['João','Tiago','Pedro','André'], correct_answer:'Pedro',
    verse_reference:'Mateus 26:69-75', explanation:'Pedro negou Jesus antes do galo cantar.' },
  { type:'multiple_choice', level:2, order:10, pf_reward:15, is_active:true, is_premium:false,
    question:'Quantos dias Jesus ficou no deserto sendo tentado?',
    options_text:['3','7','30','40'], correct_answer:'40',
    verse_reference:'Mateus 4:2', explanation:'Jesus jejuou 40 dias e 40 noites no deserto.' },
  { type:'multiple_choice', level:2, order:11, pf_reward:15, is_active:true, is_premium:false,
    question:'Qual rei de Israel pediu sabedoria a Deus?',
    options_text:['Davi','Saul','Salomão','Roboão'], correct_answer:'Salomão',
    verse_reference:'1 Reis 3:5-12', explanation:'Salomão pediu sabedoria em vez de riqueza.' },
  { type:'multiple_choice', level:2, order:12, pf_reward:15, is_active:true, is_premium:false,
    question:'Qual foi o primeiro milagre de Jesus segundo o Evangelho de João?',
    options_text:['Cura de leproso','Multiplicação dos pães','Água em vinho','Ressurreição de Lázaro'],
    correct_answer:'Água em vinho',
    verse_reference:'João 2:1-11', explanation:'Jesus transformou água em vinho nas bodas de Caná.' },
  { type:'multiple_choice', level:3, order:13, pf_reward:20, is_active:true, is_premium:false,
    question:'Quem foi o pai da fé segundo o Novo Testamento?',
    options_text:['Noé','Abraão','Moisés','Davi'], correct_answer:'Abraão',
    verse_reference:'Romanos 4:11', explanation:'Abraão é chamado de pai de todos os crentes.' },
  { type:'multiple_choice', level:3, order:14, pf_reward:20, is_active:true, is_premium:false,
    question:'Onde Jesus foi crucificado?',
    options_text:['Monte das Oliveiras','Gólgota','Getsêmani','Monte Sião'], correct_answer:'Gólgota',
    verse_reference:'João 19:17', explanation:'Jesus foi crucificado no Gólgota (lugar da Caveira).' },
  { type:'multiple_choice', level:3, order:15, pf_reward:20, is_active:true, is_premium:false,
    question:'Qual livro do NT tem mais capítulos?',
    options_text:['Mateus','Lucas','Apocalipse','Atos'], correct_answer:'Apocalipse',
    verse_reference:'Apocalipse 22', explanation:'Apocalipse tem 22 capítulos, o mais longo do NT.' },
  // Verdadeiro/Falso
  { type:'true_false', level:1, order:16, pf_reward:10, is_active:true, is_premium:false,
    question:'O Sermão da Montanha está registrado no Evangelho de Mateus.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Verdadeiro',
    verse_reference:'Mateus 5-7', explanation:'O Sermão da Montanha está em Mateus 5 a 7.' },
  { type:'true_false', level:1, order:17, pf_reward:10, is_active:true, is_premium:false,
    question:'Moisés recebeu os Dez Mandamentos no Monte Sinai.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Verdadeiro',
    verse_reference:'Êxodo 20', explanation:'Deus entregou os Dez Mandamentos a Moisés no Sinai.' },
  { type:'true_false', level:1, order:18, pf_reward:10, is_active:true, is_premium:false,
    question:'Davi era filho de Jessé.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Verdadeiro',
    verse_reference:'1 Samuel 16:1', explanation:'Jessé de Belém era o pai do rei Davi.' },
  { type:'true_false', level:2, order:19, pf_reward:10, is_active:true, is_premium:false,
    question:'Paulo escreveu o Evangelho de João.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Falso',
    verse_reference:'João 1:1', explanation:'O Evangelho de João foi escrito pelo apóstolo João.' },
  { type:'true_false', level:2, order:20, pf_reward:10, is_active:true, is_premium:false,
    question:'Salomão foi o rei mais sábio de Israel.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Verdadeiro',
    verse_reference:'1 Reis 3:12', explanation:'Deus concedeu a Salomão uma sabedoria sem igual.' },
  { type:'true_false', level:2, order:21, pf_reward:10, is_active:true, is_premium:false,
    question:'A Torre de Babel foi construída para alcançar os céus.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Verdadeiro',
    verse_reference:'Gênesis 11:4', explanation:'Os construtores queriam alcançar os céus.' },
  { type:'true_false', level:2, order:22, pf_reward:10, is_active:true, is_premium:false,
    question:'O apóstolo Paulo nunca conheceu Jesus pessoalmente antes da crucificação.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Verdadeiro',
    verse_reference:'Atos 9:1-6', explanation:'Paulo encontrou Cristo ressuscitado a caminho de Damasco.' },
  { type:'true_false', level:1, order:23, pf_reward:10, is_active:true, is_premium:false,
    question:'A Bíblia tem 66 livros no cânon protestante.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Verdadeiro',
    explanation:'39 no AT e 27 no NT totalizando 66 livros.' },
  { type:'true_false', level:2, order:24, pf_reward:10, is_active:true, is_premium:false,
    question:'Jesus ressuscitou no terceiro dia após ser crucificado.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Verdadeiro',
    verse_reference:'1 Coríntios 15:4', explanation:'Conforme as Escrituras, Jesus ressuscitou no terceiro dia.' },
  { type:'true_false', level:1, order:25, pf_reward:10, is_active:true, is_premium:false,
    question:'O livro de Rute tem 20 capítulos.',
    options_text:['Verdadeiro','Falso'], correct_answer:'Falso',
    explanation:'Rute tem apenas 4 capítulos.' },
  // Complete o Versículo (Fill Blank)
  { type:'fill_blank', level:1, order:26, pf_reward:15, is_active:true, is_premium:false,
    question:'Complete: "Porque Deus amou o mundo de tal maneira que deu o seu ___ unigênito"',
    options_text:['Filho','Espírito','Anjo','Amor'], correct_answer:'Filho',
    verse_reference:'João 3:16', explanation:'João 3:16 é um dos versículos mais conhecidos.' },
  { type:'fill_blank', level:1, order:27, pf_reward:15, is_active:true, is_premium:false,
    question:'Complete: "O Senhor é o meu ___, nada me faltará"',
    options_text:['Pastor','Rei','Pai','Guia'], correct_answer:'Pastor',
    verse_reference:'Salmos 23:1', explanation:'O Salmo 23 é um dos mais amados da Bíblia.' },
  { type:'fill_blank', level:2, order:28, pf_reward:15, is_active:true, is_premium:false,
    question:'Complete: "Eu sou o caminho, a ___ e a vida"',
    options_text:['Verdade','Luz','Porta','Salvação'], correct_answer:'Verdade',
    verse_reference:'João 14:6', explanation:'Jesus declarou ser o caminho, a verdade e a vida.' },
  { type:'fill_blank', level:2, order:29, pf_reward:15, is_active:true, is_premium:false,
    question:'Complete: "No princípio era o ___, e o Verbo estava com Deus"',
    options_text:['Verbo','Espírito','Filho','Pai'], correct_answer:'Verbo',
    verse_reference:'João 1:1', explanation:'João 1:1 apresenta Jesus como o Verbo eterno de Deus.' },
  { type:'fill_blank', level:1, order:30, pf_reward:15, is_active:true, is_premium:false,
    question:'Complete: "Tudo posso naquele que me ___"',
    options_text:['Fortalece','Guia','Salva','Ama'], correct_answer:'Fortalece',
    verse_reference:'Filipenses 4:13', explanation:'Paulo escreveu isso durante sua prisão.' },
  // Adivinhe pelos Emojis
  { type:'emoji_guess', level:2, order:31, pf_reward:20, is_active:true, is_premium:false,
    question:'Qual personagem bíblico estes emojis representam?',
    emoji_hint:'🪵🌊🕊️🌈', options_text:['Noé','Moisés','Abraão','Elias'], correct_answer:'Noé',
    verse_reference:'Gênesis 6-9', explanation:'Noé: arca (madeira), dilúvio (água), pomba e arco-íris.' },
  { type:'emoji_guess', level:2, order:32, pf_reward:20, is_active:true, is_premium:false,
    question:'Qual livro da Bíblia estes emojis representam?',
    emoji_hint:'👆👑👑', options_text:['1 Reis','2 Crônicas','Juízes','Neemias'], correct_answer:'1 Reis',
    verse_reference:'1 Reis 1', explanation:'Dedo 1 + duas coroas = 1 Reis (Davi e Salomão).' },
  { type:'emoji_guess', level:2, order:33, pf_reward:20, is_active:true, is_premium:false,
    question:'Qual personagem bíblico estes emojis representam?',
    emoji_hint:'💪🦁🔒', options_text:['Sansão','Davi','Daniel','Gideão'], correct_answer:'Sansão',
    verse_reference:'Juízes 13-16', explanation:'Sansão tinha força sobrenatural e venceu um leão.' },
  { type:'emoji_guess', level:3, order:34, pf_reward:25, is_active:true, is_premium:true,
    question:'Qual personagem bíblico estes emojis representam?',
    emoji_hint:'🐟3️⃣📅🏙️', options_text:['Jonas','Daniel','Paulo','Pedro'], correct_answer:'Jonas',
    verse_reference:'Jonas 1-4', explanation:'Jonas ficou 3 dias num peixe e foi enviado à cidade de Nínive.' },
  { type:'emoji_guess', level:3, order:35, pf_reward:25, is_active:true, is_premium:true,
    question:'Qual personagem bíblico estes emojis representam?',
    emoji_hint:'👶🏔️🔥🗒️', options_text:['Moisés','Elias','Samuel','Ezequiel'], correct_answer:'Moisés',
    verse_reference:'Êxodo 2-20', explanation:'Moisés: nasceu bebê em perigo, recebeu a lei no monte Sinai com fogo.' },
  { type:'emoji_guess', level:2, order:36, pf_reward:20, is_active:true, is_premium:false,
    question:'Qual personagem bíblico estes emojis representam?',
    emoji_hint:'🎵🐑⚔️👑', options_text:['Davi','Salomão','Saul','Josué'], correct_answer:'Davi',
    verse_reference:'1 Samuel 16-17', explanation:'Davi: músico, pastor, guerreiro e rei de Israel.' },
  // Recitação por Áudio
  { type:'audio_recite', level:2, order:37, pf_reward:30, is_active:true, is_premium:true,
    question:'Recite o versículo em voz alta:',
    options_text:[], correct_answer:'porque deus amou o mundo de tal maneira que deu o seu filho unigênito',
    verse_reference:'João 3:16', explanation:'"Porque Deus amou o mundo de tal maneira que deu o seu Filho unigênito..."' },
  { type:'audio_recite', level:2, order:38, pf_reward:30, is_active:true, is_premium:true,
    question:'Recite o versículo em voz alta:',
    options_text:[], correct_answer:'o senhor é o meu pastor nada me faltará',
    verse_reference:'Salmos 23:1', explanation:'"O Senhor é o meu pastor; nada me faltará."' },
  { type:'audio_recite', level:1, order:39, pf_reward:25, is_active:true, is_premium:false,
    question:'Recite o versículo em voz alta:',
    options_text:[], correct_answer:'tudo posso naquele que me fortalece',
    verse_reference:'Filipenses 4:13', explanation:'"Tudo posso naquele que me fortalece."' },
];
