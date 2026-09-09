# Artesãs de Heliópolis

Plataforma digital de exportação de artesanato, desenvolvida como Projeto Integrador Interdisciplinar (PII) do IMT em parceria com Heliópolis.

## Estrutura

```
.
├── frontend/   # App Flutter (Dart) - interface do usuário, multiplataforma
└── backend/    # API Node.js + TypeScript + Express + MongoDB (Mongoose)
```

## Frontend (Flutter)

```
cd frontend
flutter pub get
flutter run
```

## Backend (Node.js + TypeScript + MongoDB)

```
cd backend
npm install
cp .env.example .env   # ajuste PORT e MONGODB_URI se necessário
npm run dev
```

Endpoint de verificação: `GET /health`

Rotas da API (em construção):
- `/api/produtos`
- `/api/artesas`
- `/api/exportacao`
- `/api/mensagens`
- `/api/cadastro`
