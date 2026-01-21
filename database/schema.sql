-- =====================================================
-- SkinTone Matcher - Schema do Banco de Dados (MVP)
-- Execute este script no SQL Editor do Supabase
-- =====================================================

-- Tabela de Produtos (bases/corretivos)
CREATE TABLE IF NOT EXISTS produtos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    marca TEXT NOT NULL,
    linha TEXT,
    cor_nome TEXT NOT NULL,
    hex_code TEXT NOT NULL,
    lab_l DECIMAL(10,4),
    lab_a DECIMAL(10,4),
    lab_b DECIMAL(10,4),
    acabamento TEXT CHECK (acabamento IN ('matte', 'glow', 'natural', 'acetinado')),
    tipo TEXT DEFAULT 'base' CHECK (tipo IN ('base', 'corretivo', 'bb_cream', 'cc_cream')),
    preco DECIMAL(10,2),
    url_compra TEXT,
    imagem_url TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de Análises de Pele
CREATE TABLE IF NOT EXISTS analises (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id TEXT,
    imagem_url TEXT,
    hex_pele TEXT,
    lab_l DECIMAL(10,4),
    lab_a DECIMAL(10,4),
    lab_b DECIMAL(10,4),
    subtom TEXT CHECK (subtom IN ('quente', 'frio', 'neutro')),
    monk_scale INTEGER CHECK (monk_scale >= 1 AND monk_scale <= 10),
    roi_mandibula_hex TEXT,
    roi_bochecha_hex TEXT,
    roi_pescoco_hex TEXT,
    metodo_calibracao TEXT CHECK (metodo_calibracao IN ('cartao_branco', 'esclera', 'auto', 'nenhum')),
    qualidade_imagem DECIMAL(5,2),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de Recomendações
CREATE TABLE IF NOT EXISTS recomendacoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    analise_id UUID REFERENCES analises(id) ON DELETE CASCADE,
    produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
    delta_e DECIMAL(10,4),
    ranking INTEGER,
    motivo TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de Marcas (opcional, para organização)
CREATE TABLE IF NOT EXISTS marcas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nome TEXT UNIQUE NOT NULL,
    pais_origem TEXT,
    logo_url TEXT,
    site_oficial TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_produtos_hex ON produtos(hex_code);
CREATE INDEX IF NOT EXISTS idx_produtos_marca ON produtos(marca);
CREATE INDEX IF NOT EXISTS idx_produtos_ativo ON produtos(ativo);
CREATE INDEX IF NOT EXISTS idx_analises_session ON analises(session_id);
CREATE INDEX IF NOT EXISTS idx_analises_subtom ON analises(subtom);
CREATE INDEX IF NOT EXISTS idx_recomendacoes_analise ON recomendacoes(analise_id);
CREATE INDEX IF NOT EXISTS idx_recomendacoes_delta ON recomendacoes(delta_e);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para produtos
DROP TRIGGER IF EXISTS trigger_produtos_updated_at ON produtos;
CREATE TRIGGER trigger_produtos_updated_at
    BEFORE UPDATE ON produtos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- RLS (Row Level Security) - Políticas Permissivas MVP
-- =====================================================

-- Habilitar RLS
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE analises ENABLE ROW LEVEL SECURITY;
ALTER TABLE recomendacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE marcas ENABLE ROW LEVEL SECURITY;

-- Políticas permissivas para MVP (acesso público total)
-- PRODUTOS: Leitura pública, escrita autenticada
CREATE POLICY "produtos_select_public" ON produtos FOR SELECT USING (true);
CREATE POLICY "produtos_insert_public" ON produtos FOR INSERT WITH CHECK (true);
CREATE POLICY "produtos_update_public" ON produtos FOR UPDATE USING (true);
CREATE POLICY "produtos_delete_public" ON produtos FOR DELETE USING (true);

-- ANALISES: Acesso público total (MVP sem autenticação)
CREATE POLICY "analises_select_public" ON analises FOR SELECT USING (true);
CREATE POLICY "analises_insert_public" ON analises FOR INSERT WITH CHECK (true);
CREATE POLICY "analises_update_public" ON analises FOR UPDATE USING (true);
CREATE POLICY "analises_delete_public" ON analises FOR DELETE USING (true);

-- RECOMENDACOES: Acesso público total
CREATE POLICY "recomendacoes_select_public" ON recomendacoes FOR SELECT USING (true);
CREATE POLICY "recomendacoes_insert_public" ON recomendacoes FOR INSERT WITH CHECK (true);
CREATE POLICY "recomendacoes_update_public" ON recomendacoes FOR UPDATE USING (true);
CREATE POLICY "recomendacoes_delete_public" ON recomendacoes FOR DELETE USING (true);

-- MARCAS: Acesso público total
CREATE POLICY "marcas_select_public" ON marcas FOR SELECT USING (true);
CREATE POLICY "marcas_insert_public" ON marcas FOR INSERT WITH CHECK (true);
CREATE POLICY "marcas_update_public" ON marcas FOR UPDATE USING (true);
CREATE POLICY "marcas_delete_public" ON marcas FOR DELETE USING (true);

-- =====================================================
-- Dados de Exemplo (Seed)
-- =====================================================

-- Inserir algumas marcas brasileiras populares
INSERT INTO marcas (nome, pais_origem, site_oficial) VALUES
    ('Bruna Tavares', 'Brasil', 'https://www.brunatavares.com.br'),
    ('Boca Rosa Beauty', 'Brasil', 'https://www.bocarosabeauty.com.br'),
    ('MAC', 'EUA', 'https://www.maccosmetics.com.br'),
    ('Vult', 'Brasil', 'https://www.vult.com.br'),
    ('Ruby Rose', 'Brasil', 'https://www.rubyrose.com.br'),
    ('Maybelline', 'EUA', 'https://www.maybelline.com.br'),
    ('Dailus', 'Brasil', 'https://www.dailus.com.br'),
    ('Fenty Beauty', 'EUA', 'https://www.fentybeauty.com')
ON CONFLICT (nome) DO NOTHING;

-- Inserir alguns produtos de exemplo (valores hex estimados para MVP)
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo) VALUES
    ('MAC', 'Studio Fix Fluid', 'NC15', '#F5D5B8', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NC20', '#E8C8A8', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NC25', '#DDB896', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NC30', '#D4A87A', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NC35', '#C99A6B', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NC40', '#BD8A5C', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NC42', '#B07D4F', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NC45', '#9E6D42', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NW15', '#F2D4BC', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NW20', '#E4C4AC', 'matte', 'base'),
    ('MAC', 'Studio Fix Fluid', 'NW25', '#D6B49C', 'matte', 'base'),
    ('Bruna Tavares', 'BT Skin', 'L10', '#F7E0C8', 'natural', 'base'),
    ('Bruna Tavares', 'BT Skin', 'L20', '#EDCFB0', 'natural', 'base'),
    ('Bruna Tavares', 'BT Skin', 'L30', '#DFC09E', 'natural', 'base'),
    ('Bruna Tavares', 'BT Skin', 'M40', '#CCA882', 'natural', 'base'),
    ('Bruna Tavares', 'BT Skin', 'M50', '#BA9468', 'natural', 'base'),
    ('Bruna Tavares', 'BT Skin', 'M60', '#A88052', 'natural', 'base'),
    ('Boca Rosa Beauty', 'Base Mate', '1 Maria', '#F5DCC5', 'matte', 'base'),
    ('Boca Rosa Beauty', 'Base Mate', '2 Ana', '#E8CDAE', 'matte', 'base'),
    ('Boca Rosa Beauty', 'Base Mate', '3 Francisca', '#DCBD98', 'matte', 'base'),
    ('Boca Rosa Beauty', 'Base Mate', '4 Antonia', '#CFAB82', 'matte', 'base'),
    ('Boca Rosa Beauty', 'Base Mate', '5 Adriana', '#C29A6E', 'matte', 'base'),
    ('Boca Rosa Beauty', 'Base Mate', '6 Juliana', '#B4885C', 'matte', 'base'),
    ('Boca Rosa Beauty', 'Base Mate', '7 Marcia', '#A6774C', 'matte', 'base'),
    ('Boca Rosa Beauty', 'Base Mate', '8 Fernanda', '#96653E', 'matte', 'base'),
    ('Fenty Beauty', 'Pro Filtr', '100', '#F7E4D0', 'matte', 'base'),
    ('Fenty Beauty', 'Pro Filtr', '130', '#EED2B4', 'matte', 'base'),
    ('Fenty Beauty', 'Pro Filtr', '185', '#E0BC96', 'matte', 'base'),
    ('Fenty Beauty', 'Pro Filtr', '240', '#D2A478', 'matte', 'base'),
    ('Fenty Beauty', 'Pro Filtr', '330', '#B8865A', 'matte', 'base'),
    ('Fenty Beauty', 'Pro Filtr', '385', '#9C6A42', 'matte', 'base'),
    ('Fenty Beauty', 'Pro Filtr', '420', '#7C5034', 'matte', 'base'),
    ('Fenty Beauty', 'Pro Filtr', '450', '#5C3A28', 'matte', 'base'),
    ('Maybelline', 'Fit Me', '110', '#F5DEC5', 'natural', 'base'),
    ('Maybelline', 'Fit Me', '120', '#EDD0B2', 'natural', 'base'),
    ('Maybelline', 'Fit Me', '130', '#E4C2A0', 'natural', 'base'),
    ('Maybelline', 'Fit Me', '220', '#D8B08A', 'natural', 'base'),
    ('Maybelline', 'Fit Me', '230', '#CCA076', 'natural', 'base'),
    ('Maybelline', 'Fit Me', '310', '#BA8C60', 'natural', 'base'),
    ('Maybelline', 'Fit Me', '330', '#A87A4E', 'natural', 'base');
