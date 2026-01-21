# SkinTone Matcher - MVP

Aplicacao para detectar tom de pele atraves de foto e recomendar bases de maquiagem compativeis.

## Estrutura do Projeto

```
makeup/
├── backend/          # API FastAPI (Python)
│   ├── main.py       # Servidor principal
│   └── requirements.txt
├── frontend/         # App Next.js (React)
│   └── src/app/      # Paginas
└── database/         # Schema SQL
    └── schema.sql    # Tabela de produtos
```

## Requisitos

- Python 3.10+
- Node.js 18+
- Conta no Supabase (gratuito)

## Setup

### 1. Banco de Dados (Supabase)

1. Crie uma conta em [supabase.com](https://supabase.com)
2. Crie um novo projeto
3. Va em SQL Editor e execute o conteudo de `database/schema.sql`
4. Copie a URL e a anon key do projeto (Settings > API)

### 2. Backend

```bash
cd backend

# Criar ambiente virtual (opcional mas recomendado)
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou: venv\Scripts\activate  # Windows

# Instalar dependencias
pip install -r requirements.txt

# Configurar variaveis de ambiente
# Crie um arquivo .env com:
# SUPABASE_URL=sua-url
# SUPABASE_KEY=sua-key

# Rodar servidor
uvicorn main:app --reload --port 8000
```

### 3. Frontend

```bash
cd frontend

# Instalar dependencias
npm install

# Rodar servidor de desenvolvimento
npm run dev
```

Acesse: http://localhost:3000

## Uso

1. Abra o app no navegador (de preferencia no celular)
2. Clique em "Iniciar Camera"
3. Posicione seu rosto dentro do circulo guia
4. Clique em "Capturar e Analisar"
5. Veja seu tom de pele e as recomendacoes de produtos

## Testar no Celular

Para testar no celular na mesma rede WiFi:

1. Descubra o IP do seu computador
2. Acesse `http://SEU_IP:3000` no celular
3. A camera deve funcionar via HTTPS ou localhost

Ou use ngrok para criar um tunel HTTPS:
```bash
ngrok http 3000
```

## Tecnologias

- **Frontend**: Next.js 14, React, Tailwind CSS
- **Backend**: FastAPI, OpenCV, MediaPipe
- **Banco**: Supabase (PostgreSQL)

## API Endpoints

- `GET /` - Status da API
- `GET /health` - Health check
- `POST /analyze` - Analisa imagem e retorna tom de pele
- `GET /products` - Lista todos os produtos

## Proximos Passos

- [ ] Melhorar algoritmo de extracao (white balance)
- [ ] Usar Delta E (CIEDE2000) para matching mais preciso
- [ ] Adicionar mais produtos ao catalogo
- [ ] Deploy (Vercel + Railway)
