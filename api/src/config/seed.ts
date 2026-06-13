import 'dotenv/config';
import { connectDB, mongoose } from './database';
import { UserModel } from '../modules/users/user.model';
import { TrailModel } from '../modules/content/trail.model';
import { UnitModel } from '../modules/content/unit.model';
import { LessonModel } from '../modules/content/lesson.model';
import { ExerciseModel } from '../modules/content/exercise.model';
import { CharacterModel } from '../modules/content/character.model';
import { AchievementModel } from '../modules/gamification/achievement.model';
import { LeagueModel } from '../modules/leagues/league.model';
import bcrypt from 'bcryptjs';
import { getWeekKey } from '../shared/utils/date.util';

const seedDatabase = async () => {
  try {
    console.log('🌱 Starting database seed...');
    await connectDB();

    // 1. Admin User
    const adminEmail = 'admin@journeyfaith.com';
    let admin = await UserModel.findOne({ email: adminEmail });
    if (!admin) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash('admin123', salt);
      admin = await UserModel.create({
        name: 'Admin Master',
        username: 'admin_master',
        email: adminEmail,
        passwordHash,
        role: 'admin',
        pf_total: 1000,
        level: 10
      });
      console.log('✅ Admin user created');
    }

    // 2. Personagem Caleb
    let caleb = await CharacterModel.findOne({ name: 'Caleb' });
    if (!caleb) {
      caleb = await CharacterModel.create({
        name: 'Caleb',
        title: 'O Corajoso',
        biblical_reference: 'Números 13-14',
        biblical_story: 'Foi um dos espias judeus enviados por Moisés para observar a Terra de Canaã. Ele e Josué foram os únicos que trouxeram um bom relatório e confiaram em Deus.',
        sprite_url: 'https://via.placeholder.com/150/09f/fff.png', // Placeholder
        color_hex: '#FFA500',
        rarity: 'common',
        is_sacred: false,
        is_active: true,
        dialogues: [
          { type: 'greeting', text: 'Shalom! Pronto para começar a jornada hoje?' },
          { type: 'correct', text: 'Isso aí! Muito bem.' },
          { type: 'wrong', text: 'Quase lá. Vamos tentar novamente.' }
        ]
      });
      console.log('✅ Character Caleb created');
    }

    // 3. Trilha e Unidades
    let trail = await TrailModel.findOne({ slug: 'fundamentos-vida-jesus' });
    if (!trail) {
      trail = await TrailModel.create({
        title: 'Fundamentos: A Vida de Jesus',
        slug: 'fundamentos-vida-jesus',
        description: 'Aprenda sobre o nascimento, ministério, ressurreição e ensinamentos de Jesus.',
        character_id: caleb._id,
        order: 1,
        is_core: true,
        is_published: true,
        total_units: 2,
        total_lessons: 5
      });
      console.log('✅ Trail "A Vida de Jesus" created');
    }

    const units = [];
    const unit1Data = { trail_id: trail._id, title: 'O Princípio', order: 1, icon_name: 'star', color_hex: '#FFD700', is_published: true };
    const unit2Data = { trail_id: trail._id, title: 'O Ministério', order: 2, icon_name: 'book', color_hex: '#1E90FF', is_published: true };

    let unit1 = await UnitModel.findOne({ trail_id: trail._id, order: 1 });
    if (!unit1) unit1 = await UnitModel.create(unit1Data);
    units.push(unit1);

    let unit2 = await UnitModel.findOne({ trail_id: trail._id, order: 2 });
    if (!unit2) unit2 = await UnitModel.create(unit2Data);
    units.push(unit2);

    console.log('✅ 2 Units created under trail');

    // 4. Lições (3 em Unit 1, 2 em Unit 2)
    const lessons = [];
    for (let i = 1; i <= 3; i++) {
        let l = await LessonModel.findOne({ unit_id: unit1._id, order: i });
        if (!l) {
            l = await LessonModel.create({
                unit_id: unit1._id,
                trail_id: trail._id,
                title: `Lição ${i} - ${unit1.title}`,
                order: i,
                is_published: true,
                total_exercises: 5
            });
        }
        lessons.push(l);
    }
    for (let i = 1; i <= 2; i++) {
        let l = await LessonModel.findOne({ unit_id: unit2._id, order: i });
        if (!l) {
            l = await LessonModel.create({
                unit_id: unit2._id,
                trail_id: trail._id,
                title: `Lição ${i} - ${unit2.title}`,
                order: i,
                is_published: true,
                total_exercises: 0
            });
        }
        lessons.push(l);
    }
    console.log('✅ 5 Lessons created (3 in unit 1, 2 in unit 2)');

    // 5. Exercícios na primeira lição (lessons[0])
    const countEx = await ExerciseModel.countDocuments({ lesson_id: lessons[0]._id });
    if (countEx === 0) {
      const exs = [
        {
          lesson_id: lessons[0]._id,
          order: 1,
          type: 'multiple_choice',
          question: 'Em qual cidade Jesus nasceu?',
          options_text: ['Jerusalém', 'Nazaré', 'Belém', 'Jericó'],
          correct_answer: 'Belém',
          options: [
            { id: 'a', text: 'Jerusalém', is_correct: false },
            { id: 'b', text: 'Nazaré', is_correct: false },
            { id: 'c', text: 'Belém', is_correct: true },
            { id: 'd', text: 'Jericó', is_correct: false },
          ],
          explanation: 'Jesus nasceu em Belém da Judeia.'
        },
        {
          lesson_id: lessons[0]._id,
          order: 2,
          type: 'fill_blank',
          question: 'Jesus transformou a água em _ em Caná.',
          options_text: ['vinho', 'pão', 'azeite', 'mel'],
          correct_answer: 'vinho',
          explanation: 'O primeiro milagre de Jesus foi transformar a água em vinho nas bodas de Caná.',
          word_bank: ['vinho', 'pão', 'azeite', 'mel']
        },
        {
          lesson_id: lessons[0]._id,
          order: 3,
          type: 'multiple_choice',
          question: 'Qual é a primeira frase da Oração do Pai Nosso?',
          options_text: [
            'Pai nosso que estás nos céus',
            'Deus nosso que estás no céu',
            'Senhor nosso que estás nos céus',
            'Pai nosso que estás na terra',
          ],
          correct_answer: 'Pai nosso que estás nos céus',
          explanation: 'Esta é a primeira frase da oração do Pai Nosso.'
        },
        {
          lesson_id: lessons[0]._id,
          order: 4,
          type: 'true_false',
          question: 'Jesus é conhecido como o "Cordeiro de Deus".',
          options_text: ['Verdadeiro', 'Falso'],
          correct_answer: 'Verdadeiro',
          options: [
            { id: 'true', text: 'Verdadeiro', is_correct: true },
            { id: 'false', text: 'Falso', is_correct: false }
          ],
          explanation: 'João Batista O chamou de "Cordeiro de Deus, que tira o pecado do mundo."'
        },
        {
          lesson_id: lessons[0]._id,
          order: 5,
          type: 'multiple_choice',
          question: 'Quem atravessou o Mar Vermelho com o povo de Israel?',
          options_text: ['Moisés', 'Davi', 'Noé', 'Abraão'],
          correct_answer: 'Moisés',
          explanation: 'Moisés liderou o povo de Israel na travessia do Mar Vermelho.'
        }
      ];
      await ExerciseModel.insertMany(exs);

      await LessonModel.findByIdAndUpdate(lessons[0]._id, { total_exercises: exs.length });
      console.log('✅ 5 Exercises created for the first lesson');
    }

    // 5b. Exercícios das demais lições (lessons[1..4])
    const otherLessonsExercises = [
      [ // Lição 2 - João Batista e o batismo de Jesus
        {
          order: 1, type: 'multiple_choice',
          question: 'Quem batizou Jesus no rio Jordão?',
          options_text: ['João Batista', 'Pedro', 'Moisés', 'Elias'],
          correct_answer: 'João Batista',
          explanation: 'João Batista batizou Jesus no rio Jordão.'
        },
        {
          order: 2, type: 'true_false',
          question: 'João Batista vivia no deserto e se alimentava de gafanhotos e mel selvagem.',
          options_text: ['Verdadeiro', 'Falso'],
          correct_answer: 'Verdadeiro',
          explanation: 'A Bíblia descreve o estilo de vida simples de João Batista no deserto.'
        },
        {
          order: 3, type: 'fill_blank',
          question: 'Jesus foi batizado no rio ___.',
          options_text: ['Jordão', 'Nilo', 'Eufrates', 'Tigre'],
          correct_answer: 'Jordão',
          explanation: 'O batismo de Jesus ocorreu no rio Jordão.'
        },
        {
          order: 4, type: 'multiple_choice',
          question: 'O que desceu sobre Jesus em forma de pomba durante o batismo?',
          options_text: ['Espírito Santo', 'Um anjo', 'Fogo', 'Uma estrela'],
          correct_answer: 'Espírito Santo',
          explanation: 'O Espírito Santo desceu sobre Jesus em forma de pomba.'
        },
        {
          order: 5, type: 'multiple_choice',
          question: 'Quantos dias Jesus jejuou no deserto antes de ser tentado?',
          options_text: ['40', '7', '12', '100'],
          correct_answer: '40',
          explanation: 'Jesus jejuou por 40 dias e 40 noites no deserto.'
        },
      ],
      [ // Lição 3 - A chamada dos discípulos
        {
          order: 1, type: 'multiple_choice',
          question: 'Qual era a profissão de Pedro e André antes de seguirem Jesus?',
          options_text: ['Pescadores', 'Carpinteiros', 'Cobradores de impostos', 'Pastores'],
          correct_answer: 'Pescadores',
          explanation: 'Pedro e André eram pescadores no Mar da Galileia.'
        },
        {
          order: 2, type: 'true_false',
          question: 'Jesus escolheu 12 discípulos.',
          options_text: ['Verdadeiro', 'Falso'],
          correct_answer: 'Verdadeiro',
          explanation: 'Jesus escolheu doze apóstolos para seguirem o Seu ministério.'
        },
        {
          order: 3, type: 'multiple_choice',
          question: 'Quem era o discípulo cobrador de impostos chamado por Jesus?',
          options_text: ['Mateus', 'Tiago', 'Tomé', 'Filipe'],
          correct_answer: 'Mateus',
          explanation: 'Mateus era cobrador de impostos antes de seguir Jesus.'
        },
        {
          order: 4, type: 'fill_blank',
          question: "Jesus disse: 'Sigam-me, e eu os farei pescadores de ___.'",
          options_text: ['homens', 'peixes', 'ovelhas', 'pão'],
          correct_answer: 'homens',
          explanation: 'Jesus chamou os pescadores para se tornarem "pescadores de homens".'
        },
        {
          order: 5, type: 'multiple_choice',
          question: 'Quem traiu Jesus por 30 moedas de prata?',
          options_text: ['Judas Iscariotes', 'Pedro', 'Tomé', 'João'],
          correct_answer: 'Judas Iscariotes',
          explanation: 'Judas Iscariotes traiu Jesus por trinta moedas de prata.'
        },
      ],
      [ // Lição 4 - Milagres de Jesus
        {
          order: 1, type: 'multiple_choice',
          question: 'Quantos pães e peixes Jesus usou para alimentar 5 mil pessoas?',
          options_text: ['5 pães e 2 peixes', '2 pães e 5 peixes', '7 pães e 3 peixes', '3 pães e 7 peixes'],
          correct_answer: '5 pães e 2 peixes',
          explanation: 'Jesus multiplicou 5 pães e 2 peixes para alimentar a multidão.'
        },
        {
          order: 2, type: 'true_false',
          question: 'Jesus andou sobre as águas do Mar da Galileia.',
          options_text: ['Verdadeiro', 'Falso'],
          correct_answer: 'Verdadeiro',
          explanation: 'Jesus caminhou sobre as águas, demonstrando seu poder sobre a natureza.'
        },
        {
          order: 3, type: 'multiple_choice',
          question: 'Qual amigo de Jesus foi ressuscitado após 4 dias morto?',
          options_text: ['Lázaro', 'Zaqueu', 'Bartimeu', 'Nicodemos'],
          correct_answer: 'Lázaro',
          explanation: 'Jesus ressuscitou Lázaro quatro dias após sua morte.'
        },
        {
          order: 4, type: 'fill_blank',
          question: 'Jesus transformou a água em vinho durante um ___.',
          options_text: ['casamento', 'funeral', 'jejum', 'julgamento'],
          correct_answer: 'casamento',
          explanation: 'O milagre da água em vinho aconteceu nas bodas (casamento) de Caná.'
        },
        {
          order: 5, type: 'multiple_choice',
          question: 'Em qual cidade ocorreu o casamento em que Jesus transformou água em vinho?',
          options_text: ['Caná', 'Belém', 'Jerusalém', 'Nazaré'],
          correct_answer: 'Caná',
          explanation: 'O milagre ocorreu nas bodas de Caná da Galileia.'
        },
      ],
      [ // Lição 5 - Paixão e ressurreição
        {
          order: 1, type: 'multiple_choice',
          question: 'Em qual cidade Jesus foi crucificado?',
          options_text: ['Jerusalém', 'Belém', 'Nazaré', 'Cafarnaum'],
          correct_answer: 'Jerusalém',
          explanation: 'Jesus foi crucificado em Jerusalém, no monte Calvário.'
        },
        {
          order: 2, type: 'true_false',
          question: 'Jesus ressuscitou no terceiro dia.',
          options_text: ['Verdadeiro', 'Falso'],
          correct_answer: 'Verdadeiro',
          explanation: 'Jesus ressuscitou no terceiro dia, conforme as Escrituras.'
        },
        {
          order: 3, type: 'multiple_choice',
          question: 'Qual refeição Jesus compartilhou com os discípulos antes de ser preso?',
          options_text: ['Última Ceia', 'Festa de Pentecostes', 'Casamento em Caná', 'Festa dos Tabernáculos'],
          correct_answer: 'Última Ceia',
          explanation: 'A Última Ceia foi a refeição final de Jesus com seus discípulos.'
        },
        {
          order: 4, type: 'fill_blank',
          question: 'Jesus foi crucificado no monte ___.',
          options_text: ['Calvário', 'Sinai', 'Sião', 'Carmelo'],
          correct_answer: 'Calvário',
          explanation: 'O Calvário (Gólgota) foi o local da crucificação de Jesus.'
        },
        {
          order: 5, type: 'multiple_choice',
          question: 'Quem encontrou o túmulo vazio primeiro?',
          options_text: ['Maria Madalena', 'Pedro', 'João', 'Tomé'],
          correct_answer: 'Maria Madalena',
          explanation: 'Maria Madalena foi a primeira a encontrar o túmulo vazio.'
        },
      ],
    ];

    for (let i = 0; i < otherLessonsExercises.length; i++) {
      const lesson = lessons[i + 1];
      const count = await ExerciseModel.countDocuments({ lesson_id: lesson._id });
      if (count === 0) {
        const exs = otherLessonsExercises[i].map((ex) => ({ ...ex, lesson_id: lesson._id }));
        await ExerciseModel.insertMany(exs);
        await LessonModel.findByIdAndUpdate(lesson._id, { total_exercises: exs.length });
        console.log(`✅ 5 Exercises created for lesson ${i + 2}`);
      }
    }

    // 6. Conquistas
    const countAch = await AchievementModel.countDocuments();
    if (countAch === 0) {
      await AchievementModel.insertMany([
        { key: 'first_lesson', name: 'Primeira Pedra', description: 'Complete sua primeira lição', trigger: { type: 'lesson_count', value: 1 }, pf_reward: 50, icon_url: 'placeholder_icon' },
        { key: 'streak_3_days', name: 'Começo Fiel', description: 'Mantenha 3 dias de devoção', trigger: { type: 'streak_days', value: 3 }, pf_reward: 100, icon_url: 'placeholder_icon' },
        { key: 'level_5', name: 'Discípulo', description: 'Atinja o nível 5', trigger: { type: 'level', value: 5 }, pf_reward: 200, icon_url: 'placeholder_icon' },
        { key: 'trail_jesus_complete', name: 'Caminho Completo', description: 'Conclua a trilha da vida de Jesus', trigger: { type: 'trail_complete', value: 1 }, pf_reward: 500, icon_url: 'placeholder_icon' },
        { key: 'first_league_promotion', name: 'Crescendo na Fé', description: 'Seja promovido em uma liga', trigger: { type: 'league_rank', value: 10 }, pf_reward: 100, icon_url: 'placeholder_icon' },
      ]);
      console.log('✅ 5 Achievements created');
    }

    // 7. Ligas Iniciais
    const weekKey = getWeekKey();
    let league = await LeagueModel.findOne({ tier: 'ruben', week_key: weekKey });
    if (!league) {
      const now = new Date();
      await LeagueModel.create({
        tier: 'ruben',
        week_key: weekKey,
        starts_at: new Date(now.setDate(now.getDate() - now.getDay())), // Domingo ou Segunda dependendo da lógica do getStartOfWeek
        ends_at: new Date(now.setDate(now.getDate() + 7)),
        is_active: true
      });
      console.log('✅ Base League (Ruben) created for this week');
    }

    console.log('🎉 Seed finalized successfully!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error executing seed:', error);
    process.exit(1);
  }
};

seedDatabase();
