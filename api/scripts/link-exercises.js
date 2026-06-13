const mongoose = require('mongoose');
require('dotenv').config();

const MAPPING = [
  { q: 'No princípio criou Deus', lesson: 'A Criacao' },
  { q: 'primeiro homem criado por Deus', lesson: 'Adao e Eva' },
  { q: 'jardim onde Adão e Eva', lesson: 'O Jardim do Eden' },
  { q: 'Quantos discípulos Jesus escolheu', lesson: 'Os Primeiros Discipulos' },
  { q: 'construiu a Arca', lesson: 'Noe o Justo' },
  { q: 'Em qual cidade Jesus nasceu', lesson: 'Nascido em Belem' },
  { q: 'batizou Jesus no Rio Jordão', lesson: 'O Batismo de Jesus' },
  { q: 'três dias dentro de um grande peixe', lesson: 'A Profecia Cumprida' },
  { q: 'negou Jesus três vezes', lesson: 'O Jardim do Getsemani' },
  { q: 'Quantos dias Jesus ficou no deserto', lesson: 'O Batismo de Jesus' },
  { q: 'rei de Israel pediu sabedoria', lesson: 'Sabedoria vs Loucura' },
  { q: 'primeiro milagre de Jesus', lesson: 'Milagres e Parabolas' },
  { q: 'pai da fé', lesson: 'A Chamada' },
  { q: 'Onde Jesus foi crucificado', lesson: 'A Crucificacao' },
  { q: 'livro do NT tem mais capítulos', lesson: 'As Cartas de Paulo' },
  { q: 'Sermão da Montanha está registrado', lesson: 'O Sermao da Montanha' },
  { q: 'Moisés recebeu os Dez Mandamentos', lesson: 'A Profecia Cumprida' },
  { q: 'Davi era filho de Jessé', lesson: 'A Profecia Cumprida' },
  { q: 'Paulo escreveu o Evangelho de João', lesson: 'A Conversao de Paulo' },
  { q: 'Salomão foi o rei mais sábio', lesson: 'O Temor do Senhor' },
  { q: 'Torre de Babel', lesson: 'A Queda' },
  { q: 'Paulo nunca conheceu Jesus pessoalmente', lesson: 'A Conversao de Paulo' },
  { q: 'Bíblia tem 66 livros', lesson: 'A Profecia Cumprida' },
  { q: 'Jesus ressuscitou no terceiro dia', lesson: 'A Ressurreicao' },
  { q: 'livro de Rute tem 20 capítulos', lesson: 'A Profecia Cumprida' },
  { q: 'Deus amou o mundo', lesson: 'Amar a Deus' },
  { q: 'Senhor é o meu', lesson: 'Salmo 23 - O Bom Pastor' },
  { q: 'caminho, a', lesson: 'O Batismo de Jesus' },
  { q: 'No princípio era o', lesson: 'A Criacao' },
  { q: 'Tudo posso naquele', lesson: 'As Cartas de Paulo' },
  { q_index: 30, lesson: 'Os Pastores e a Estrela' },
  { q_index: 31, lesson: 'A Arca' },
  { q_index: 32, lesson: 'O Diluvio' },
  { q_index: 33, lesson: 'A Chamada' },
  { q_index: 34, lesson: 'O Semeador' },
  { q_index: 35, lesson: 'O Filho Prodigo' },
  { q_index: 36, lesson: 'Salmo 91 - Abrigo do Altissimo' },
  { q_index: 37, lesson: 'Salmo 100 - Alegria no Senhor' },
  { q_index: 38, lesson: 'Salmo 150 - Louvor Final' },
  { q: 'pragas foram enviadas ao Egito', lesson: 'A Profecia Cumprida' },
];

async function run() {
  await mongoose.connect(process.env.MONGODB_URI || '');
  const db = mongoose.connection.db;

  const exercises = await db.collection('exercises').find({}).sort({ _id: 1 }).toArray();
  const lessons = await db.collection('lessons').find({}).toArray();
  const lessonMap = new Map(lessons.map(l => [l.title, l._id]));

  let linked = 0, notFound = 0;

  for (let i = 0; i < exercises.length; i++) {
    const ex = exercises[i];
    let mapping = MAPPING.find(m => m.q && ex.question.includes(m.q));
    if (!mapping) mapping = MAPPING.find(m => m.q_index === i);

    if (!mapping) {
      console.log('SKIP:', ex.question.substring(0, 60));
      continue;
    }

    const lessonId = lessonMap.get(mapping.lesson);
    if (!lessonId) {
      console.log('LESSON NOT FOUND:', mapping.lesson);
      notFound++;
      continue;
    }

    await db.collection('exercises').updateOne({ _id: ex._id }, { $set: { lesson_id: lessonId } });
    linked++;
  }

  // Update total_exercises for all affected lessons
  const affectedLessonIds = [...new Set(
    MAPPING.map(m => lessonMap.get(m.lesson)).filter(Boolean)
  )];
  for (const lid of affectedLessonIds) {
    const count = await db.collection('exercises').countDocuments({ lesson_id: lid, is_active: true });
    await db.collection('lessons').updateOne({ _id: lid }, { $set: { total_exercises: count } });
  }

  console.log('\nLinked:', linked, '| Not found:', notFound);
  process.exit(0);
}
run().catch(e => { console.error(e); process.exit(1); });
