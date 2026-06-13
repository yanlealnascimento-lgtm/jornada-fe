# JourneyFaith 🛡️📖

JourneyFaith é um app churchtech gamificado de aprendizado cristão, focado em proporcionar uma experiência leve, acolhedora e motivadora, similar ao Duolingo, mas com contexto bíblico.

## 🚀 Estrutura do Monorepo

- `/app`: Aplicativo Mobile (Flutter)
- `/api`: Backend (Node.js + Express + TypeScript)
- `/admin`: Painel Administrativo de Conteúdo (React.js)
- `/company`: Painel B2B para Instituições (React.js)
- `/shared` (futuro): Tipos e recursos globais compartilhados

## ⚙️ Tecnologias Principais

- **Mobile:** Flutter (Riverpod, GoRouter, Isar, Lottie)
- **Backend:** Node.js, Express, TypeScript, Mongoose, Zod
- **Banco de Dados:** MongoDB
- **Cache & Leaderboards:** Redis (Sorted Sets)
- **Painéis:** React.js, Vite, TypeScript, Zustand, TailwindCSS

## 🛠️ Como Rodar Localmente

### 1. Pré-Requisitos
- Docker e Docker Compose (Para MongoDB e Redis locais)
- Node.js versão 20.x
- Flutter SDK 3.x

### 2. Subir Bancos de Dados Localmente
Inicie o MongoDB e o Redis usando o Docker Compose na raiz do projeto:
```bash
docker-compose up -d
```
Verifique se os containers `jf_mongodb` e `jf_redis` estão em execução.

### 3. Executando a API (Backend)
Vá para a pasta `/api`, crie seu arquivo `.env` e rode a API:
```bash
cd api
cp .env.example .env
npm install
npm run dev
```
A API iniciará na porta `4000`.

### 4. Executando os Painéis Web (Admin e Company)
A partir da raiz, vá em cada pasta e inicie:
```bash
# Para o painel Admin:
cd admin
npm install
npm run dev
# Rodará no http://localhost:3000
```
```bash
# Para o painel Company:
cd company
npm install
npm run dev
# Rodará no http://localhost:5173
```

### 5. Executando o App Flutter
Na pasta `/app`:
```bash
cd app
flutter pub get
flutter run
```

## 🧪 Plano de Testes (QA)

A suíte de automação será desenvolvida conforme os componentes sejam consolidados.
- Backend: Utilizaremos Jest para validação de endpoints e lógicas de gamificação.
- Frontend/Admin/Company: Playwright com POM (Page Object Model) para testes E2E.

---
**Nota:** Projeto MVP em desenvolvimento focado em gamificação de aprendizado cristão, seguindo melhores práticas de Clean Code.
