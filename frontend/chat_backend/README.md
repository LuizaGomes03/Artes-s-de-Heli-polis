# Chatbot — Artesãs de Heliópolis

Este backend mantém a chave da API fora do Flutter e faz a ponte:

Flutter → API local → OpenAI Responses API → Flutter

## 1. Instalar

Abra o PowerShell nesta pasta e execute:

```powershell
npm install
```

## 2. Configurar a chave

Copie `.env.example` para `.env`:

```powershell
Copy-Item .env.example .env
```

Depois abra `.env` e coloque sua chave em `OPENAI_API_KEY`.

**Nunca coloque a chave no código Flutter e não envie o `.env` para o GitHub.**

## 3. Rodar

```powershell
npm start
```

A API ficará em:

`http://127.0.0.1:3000`

Teste no navegador:

`http://127.0.0.1:3000/api/health`

## 4. Rodar o Flutter

No projeto Flutter:

```powershell
flutter pub get
flutter run -d windows
```

O botão verde de chat abre o assistente.

## 5. Se o Flutter estiver em outro computador/dispositivo

Passe o endereço do computador que está rodando o backend:

```powershell
flutter run -d chrome --dart-define=CHAT_API_URL=http://IP_DO_SERVIDOR:3000/api
```

Para celular físico, o computador e o celular precisam estar na mesma rede e o firewall precisa permitir a porta 3000.
