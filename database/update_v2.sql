-- =====================================================
-- SkinTone Matcher - Atualização V2
-- Escala Monk Skin Tone + Produtos Brasileiros Expandidos
-- Execute este script no SQL Editor do Supabase
-- =====================================================

-- =====================================================
-- 1. TABELA: Escala Monk Skin Tone (Referência Google)
-- =====================================================
CREATE TABLE IF NOT EXISTS monk_skin_tones (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) UNIQUE NOT NULL,
    tom_numero INTEGER NOT NULL CHECK (tom_numero >= 1 AND tom_numero <= 10),
    nome VARCHAR(100) NOT NULL,
    nome_en VARCHAR(100),
    hex_code VARCHAR(7) NOT NULL,
    rgb_r INTEGER NOT NULL,
    rgb_g INTEGER NOT NULL,
    rgb_b INTEGER NOT NULL,
    fitzpatrick VARCHAR(10),
    descricao TEXT,
    undertones_comuns TEXT[],
    dicas_maquiagem TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir os 10 tons da escala Monk
INSERT INTO monk_skin_tones (codigo, tom_numero, nome, nome_en, hex_code, rgb_r, rgb_g, rgb_b, fitzpatrick, descricao, undertones_comuns, dicas_maquiagem) VALUES
    ('MST01', 1, 'Tom 1 - Muito Claro', 'Very Light', '#f6ede4', 246, 237, 228, 'I',
     'Pele muito clara, geralmente de origem europeia ou asiática do leste. Queima facilmente ao sol.',
     ARRAY['frio', 'neutro'],
     ARRAY['Use bases com subtom rosado ou neutro', 'Protetor solar é essencial', 'Blush em tons rosados ou pêssego suave']),

    ('MST02', 2, 'Tom 2 - Claro', 'Light', '#f3e7db', 243, 231, 219, 'I-II',
     'Pele clara com leve tonalidade. Pode ter sardas. Queima com facilidade.',
     ARRAY['frio', 'neutro', 'quente'],
     ARRAY['Bases com subtom amarelo suave ou rosado', 'Iluminadores champagne funcionam bem', 'Bronzer leve para dar vida']),

    ('MST03', 3, 'Tom 3 - Claro Médio', 'Light Medium', '#f7ead0', 247, 234, 208, 'II',
     'Pele clara com fundo dourado. Bronzeia levemente após queimar.',
     ARRAY['quente', 'neutro'],
     ARRAY['Bases com subtom dourado ou pêssego', 'Contorno em tons de caramelo', 'Blush coral ou pêssego']),

    ('MST04', 4, 'Tom 4 - Médio Claro', 'Medium Light', '#eadaba', 234, 218, 186, 'II-III',
     'Pele média clara, comum em pessoas latinas e mediterrâneas. Bronzeia gradualmente.',
     ARRAY['quente', 'neutro', 'oliva'],
     ARRAY['Bases com subtom amarelo ou oliva', 'Evite bases muito rosadas', 'Iluminadores dourados']),

    ('MST05', 5, 'Tom 5 - Médio', 'Medium', '#d7bd96', 215, 189, 150, 'III',
     'Pele média, muito comum em brasileiros. Bronzeia bem, raramente queima.',
     ARRAY['quente', 'neutro', 'oliva'],
     ARRAY['Ampla gama de subtons funciona', 'Contorno em tons de chocolate ao leite', 'Blush em tons terrosos ou coral']),

    ('MST06', 6, 'Tom 6 - Médio Escuro', 'Medium Tan', '#a07e56', 160, 126, 86, 'III-IV',
     'Pele média escura com fundo dourado. Bronzeia facilmente, não queima.',
     ARRAY['quente', 'neutro'],
     ARRAY['Bases com subtom dourado ou caramelo', 'Iluminadores bronze ou cobre', 'Blush em tons de ameixa ou terracota']),

    ('MST07', 7, 'Tom 7 - Escuro Claro', 'Tan', '#825c43', 130, 92, 67, 'IV-V',
     'Pele escura clara, comum em pessoas afrodescendentes e indianas.',
     ARRAY['quente', 'neutro', 'vermelho'],
     ARRAY['Bases com subtom vermelho ou dourado', 'Evite bases acinzentadas', 'Iluminadores dourados ou bronze']),

    ('MST08', 8, 'Tom 8 - Escuro', 'Dark', '#604134', 96, 65, 52, 'V',
     'Pele escura com tons ricos. Nunca queima ao sol.',
     ARRAY['quente', 'vermelho', 'neutro'],
     ARRAY['Bases com subtom vermelho ou mogno', 'Contorno em tons de chocolate amargo', 'Iluminadores dourados intensos ou cobre']),

    ('MST09', 9, 'Tom 9 - Muito Escuro', 'Deep', '#3a312a', 58, 49, 42, 'V-VI',
     'Pele muito escura com reflexos azulados ou avermelhados.',
     ARRAY['vermelho', 'neutro', 'azul'],
     ARRAY['Bases com subtom vermelho ou neutro', 'Evite bases com fundo cinza', 'Iluminadores dourados ou rosé gold']),

    ('MST10', 10, 'Tom 10 - Escuro Profundo', 'Deep Dark', '#2d2926', 45, 41, 38, 'VI',
     'Pele escura profunda, a mais rica em melanina.',
     ARRAY['vermelho', 'neutro'],
     ARRAY['Bases com bastante pigmento vermelho', 'Iluminadores cobre ou bronze', 'Blush em tons de vinho ou berry'])
ON CONFLICT (codigo) DO UPDATE SET
    nome = EXCLUDED.nome,
    hex_code = EXCLUDED.hex_code,
    descricao = EXCLUDED.descricao,
    dicas_maquiagem = EXCLUDED.dicas_maquiagem;

-- Índice para busca por tom
CREATE INDEX IF NOT EXISTS idx_monk_tom ON monk_skin_tones(tom_numero);

-- =====================================================
-- 2. ATUALIZAR TABELA PRODUTOS - Novos campos
-- =====================================================
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS monk_tone_min INTEGER CHECK (monk_tone_min >= 1 AND monk_tone_min <= 10);
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS monk_tone_max INTEGER CHECK (monk_tone_max >= 1 AND monk_tone_max <= 10);
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS cobertura VARCHAR(20) CHECK (cobertura IN ('leve', 'media', 'alta', 'total'));
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS subtom VARCHAR(20) CHECK (subtom IN ('quente', 'frio', 'neutro', 'oliva'));
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS onde_comprar TEXT;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS categoria VARCHAR(50) DEFAULT 'base';

-- Atualizar categoria para incluir mais tipos
ALTER TABLE produtos DROP CONSTRAINT IF EXISTS produtos_tipo_check;
ALTER TABLE produtos ADD CONSTRAINT produtos_tipo_check CHECK (tipo IN ('base', 'corretivo', 'bb_cream', 'cc_cream', 'po_compacto', 'po_solto', 'contorno', 'iluminador', 'blush', 'primer'));

-- =====================================================
-- 3. EXPANDIR BASE DE PRODUTOS BRASILEIROS
-- =====================================================

-- Limpar produtos existentes para reinserir com dados completos
DELETE FROM produtos;

-- NATURA UNA
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Natura', 'Una', '01N', '#F5E1CC', 'natural', 'base', 'media', 'neutro', 1, 2, 89.90, 'natura.com.br'),
    ('Natura', 'Una', '02C', '#EED4B8', 'natural', 'base', 'media', 'quente', 2, 3, 89.90, 'natura.com.br'),
    ('Natura', 'Una', '03N', '#E5C5A0', 'natural', 'base', 'media', 'neutro', 3, 4, 89.90, 'natura.com.br'),
    ('Natura', 'Una', '04C', '#D9B58C', 'natural', 'base', 'media', 'quente', 4, 5, 89.90, 'natura.com.br'),
    ('Natura', 'Una', '05N', '#CCA478', 'natural', 'base', 'media', 'neutro', 5, 6, 89.90, 'natura.com.br'),
    ('Natura', 'Una', '06C', '#BD9264', 'natural', 'base', 'media', 'quente', 5, 6, 89.90, 'natura.com.br'),
    ('Natura', 'Una', '07N', '#A87D50', 'natural', 'base', 'media', 'neutro', 6, 7, 89.90, 'natura.com.br'),
    ('Natura', 'Una', '08C', '#8F6840', 'natural', 'base', 'media', 'quente', 7, 8, 89.90, 'natura.com.br'),
    ('Natura', 'Una', '09N', '#765434', 'natural', 'base', 'media', 'neutro', 8, 9, 89.90, 'natura.com.br'),
    ('Natura', 'Una', '10C', '#5D4228', 'natural', 'base', 'media', 'quente', 9, 10, 89.90, 'natura.com.br');

-- O BOTICÁRIO MAKE B.
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('O Boticário', 'Make B.', '01 Clara', '#F4DFC8', 'matte', 'base', 'alta', 'neutro', 1, 2, 79.90, 'boticario.com.br'),
    ('O Boticário', 'Make B.', '02 Clara', '#EBCFB0', 'matte', 'base', 'alta', 'quente', 2, 3, 79.90, 'boticario.com.br'),
    ('O Boticário', 'Make B.', '03 Média Clara', '#DFC09C', 'matte', 'base', 'alta', 'neutro', 3, 4, 79.90, 'boticario.com.br'),
    ('O Boticário', 'Make B.', '04 Média', '#D0AD84', 'matte', 'base', 'alta', 'quente', 4, 5, 79.90, 'boticario.com.br'),
    ('O Boticário', 'Make B.', '05 Média', '#C09A6C', 'matte', 'base', 'alta', 'neutro', 5, 6, 79.90, 'boticario.com.br'),
    ('O Boticário', 'Make B.', '06 Média Escura', '#A88458', 'matte', 'base', 'alta', 'quente', 6, 7, 79.90, 'boticario.com.br'),
    ('O Boticário', 'Make B.', '07 Escura', '#906C44', 'matte', 'base', 'alta', 'neutro', 7, 8, 79.90, 'boticario.com.br'),
    ('O Boticário', 'Make B.', '08 Escura', '#785638', 'matte', 'base', 'alta', 'quente', 8, 9, 79.90, 'boticario.com.br');

-- QUEM DISSE BERENICE
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Quem Disse Berenice', 'Base Aveludada', '01-N', '#F6E2CB', 'matte', 'base', 'media', 'neutro', 1, 2, 69.90, 'quemdisseberenice.com.br'),
    ('Quem Disse Berenice', 'Base Aveludada', '02-Q', '#EDD2B5', 'matte', 'base', 'media', 'quente', 2, 3, 69.90, 'quemdisseberenice.com.br'),
    ('Quem Disse Berenice', 'Base Aveludada', '03-N', '#E0C19E', 'matte', 'base', 'media', 'neutro', 3, 4, 69.90, 'quemdisseberenice.com.br'),
    ('Quem Disse Berenice', 'Base Aveludada', '04-Q', '#D2AE86', 'matte', 'base', 'media', 'quente', 4, 5, 69.90, 'quemdisseberenice.com.br'),
    ('Quem Disse Berenice', 'Base Aveludada', '05-N', '#C49C70', 'matte', 'base', 'media', 'neutro', 5, 6, 69.90, 'quemdisseberenice.com.br'),
    ('Quem Disse Berenice', 'Base Aveludada', '06-Q', '#B08858', 'matte', 'base', 'media', 'quente', 6, 7, 69.90, 'quemdisseberenice.com.br'),
    ('Quem Disse Berenice', 'Base Aveludada', '07-N', '#987046', 'matte', 'base', 'media', 'neutro', 7, 8, 69.90, 'quemdisseberenice.com.br'),
    ('Quem Disse Berenice', 'Base Aveludada', '08-Q', '#805A36', 'matte', 'base', 'media', 'quente', 8, 9, 69.90, 'quemdisseberenice.com.br');

-- BRUNA TAVARES BT SKIN (atualizado)
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Bruna Tavares', 'BT Skin', 'L10', '#F7E0C8', 'natural', 'base', 'media', 'neutro', 1, 2, 89.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Skin', 'L20', '#EDCFB0', 'natural', 'base', 'media', 'quente', 2, 3, 89.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Skin', 'L30', '#DFC09E', 'natural', 'base', 'media', 'neutro', 3, 4, 89.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Skin', 'M40', '#CCA882', 'natural', 'base', 'media', 'quente', 4, 5, 89.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Skin', 'M50', '#BA9468', 'natural', 'base', 'media', 'neutro', 5, 6, 89.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Skin', 'M60', '#A88052', 'natural', 'base', 'media', 'quente', 6, 7, 89.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Skin', 'D70', '#8E6840', 'natural', 'base', 'media', 'neutro', 7, 8, 89.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Skin', 'D80', '#745432', 'natural', 'base', 'media', 'quente', 8, 9, 89.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Skin', 'D90', '#5C4226', 'natural', 'base', 'media', 'neutro', 9, 10, 89.00, 'belezanaweb.com.br');

-- BOCA ROSA BEAUTY (atualizado)
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Boca Rosa Beauty', 'Base Mate HD', '1 Maria', '#F5DCC5', 'matte', 'base', 'alta', 'neutro', 1, 2, 59.90, 'bocarosabeauty.com.br'),
    ('Boca Rosa Beauty', 'Base Mate HD', '2 Ana', '#E8CDAE', 'matte', 'base', 'alta', 'quente', 2, 3, 59.90, 'bocarosabeauty.com.br'),
    ('Boca Rosa Beauty', 'Base Mate HD', '3 Francisca', '#DCBD98', 'matte', 'base', 'alta', 'neutro', 3, 4, 59.90, 'bocarosabeauty.com.br'),
    ('Boca Rosa Beauty', 'Base Mate HD', '4 Antonia', '#CFAB82', 'matte', 'base', 'alta', 'quente', 4, 5, 59.90, 'bocarosabeauty.com.br'),
    ('Boca Rosa Beauty', 'Base Mate HD', '5 Adriana', '#C29A6E', 'matte', 'base', 'alta', 'neutro', 5, 6, 59.90, 'bocarosabeauty.com.br'),
    ('Boca Rosa Beauty', 'Base Mate HD', '6 Juliana', '#B4885C', 'matte', 'base', 'alta', 'quente', 6, 7, 59.90, 'bocarosabeauty.com.br'),
    ('Boca Rosa Beauty', 'Base Mate HD', '7 Marcia', '#A6774C', 'matte', 'base', 'alta', 'neutro', 7, 8, 59.90, 'bocarosabeauty.com.br'),
    ('Boca Rosa Beauty', 'Base Mate HD', '8 Fernanda', '#96653E', 'matte', 'base', 'alta', 'quente', 8, 9, 59.90, 'bocarosabeauty.com.br'),
    ('Boca Rosa Beauty', 'Base Mate HD', '9 Aline', '#825534', 'matte', 'base', 'alta', 'neutro', 9, 10, 59.90, 'bocarosabeauty.com.br');

-- VULT
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Vult', 'Base HD', '01', '#F4DEC6', 'natural', 'base', 'media', 'neutro', 1, 2, 39.90, 'vult.com.br'),
    ('Vult', 'Base HD', '02', '#EBCDB0', 'natural', 'base', 'media', 'quente', 2, 3, 39.90, 'vult.com.br'),
    ('Vult', 'Base HD', '03', '#DDBC98', 'natural', 'base', 'media', 'neutro', 3, 4, 39.90, 'vult.com.br'),
    ('Vult', 'Base HD', '04', '#CEA880', 'natural', 'base', 'media', 'quente', 4, 5, 39.90, 'vult.com.br'),
    ('Vult', 'Base HD', '05', '#BE9468', 'natural', 'base', 'media', 'neutro', 5, 6, 39.90, 'vult.com.br'),
    ('Vult', 'Base HD', '06', '#A88054', 'natural', 'base', 'media', 'quente', 6, 7, 39.90, 'vult.com.br'),
    ('Vult', 'Base HD', '07', '#906A42', 'natural', 'base', 'media', 'neutro', 7, 8, 39.90, 'vult.com.br'),
    ('Vult', 'Base HD', '08', '#785634', 'natural', 'base', 'media', 'quente', 8, 9, 39.90, 'vult.com.br');

-- TRACTA
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Tracta', 'Base Matte', '01C', '#F3DDC4', 'matte', 'base', 'alta', 'quente', 1, 2, 45.90, 'tracta.com.br'),
    ('Tracta', 'Base Matte', '02N', '#E8CCB0', 'matte', 'base', 'alta', 'neutro', 2, 3, 45.90, 'tracta.com.br'),
    ('Tracta', 'Base Matte', '03C', '#DABA98', 'matte', 'base', 'alta', 'quente', 3, 4, 45.90, 'tracta.com.br'),
    ('Tracta', 'Base Matte', '04N', '#CCA680', 'matte', 'base', 'alta', 'neutro', 4, 5, 45.90, 'tracta.com.br'),
    ('Tracta', 'Base Matte', '05C', '#BA9268', 'matte', 'base', 'alta', 'quente', 5, 6, 45.90, 'tracta.com.br'),
    ('Tracta', 'Base Matte', '06N', '#A47E52', 'matte', 'base', 'alta', 'neutro', 6, 7, 45.90, 'tracta.com.br'),
    ('Tracta', 'Base Matte', '07C', '#8C6840', 'matte', 'base', 'alta', 'quente', 7, 8, 45.90, 'tracta.com.br'),
    ('Tracta', 'Base Matte', '08N', '#745432', 'matte', 'base', 'alta', 'neutro', 8, 9, 45.90, 'tracta.com.br');

-- RUBY ROSE
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Ruby Rose', 'Base Matte', 'L1', '#F5DFC8', 'matte', 'base', 'media', 'neutro', 1, 2, 29.90, 'rubyrose.com.br'),
    ('Ruby Rose', 'Base Matte', 'L2', '#ECCFB2', 'matte', 'base', 'media', 'quente', 2, 3, 29.90, 'rubyrose.com.br'),
    ('Ruby Rose', 'Base Matte', 'L3', '#DEBF9C', 'matte', 'base', 'media', 'neutro', 3, 4, 29.90, 'rubyrose.com.br'),
    ('Ruby Rose', 'Base Matte', 'L4', '#D0AC84', 'matte', 'base', 'media', 'quente', 4, 5, 29.90, 'rubyrose.com.br'),
    ('Ruby Rose', 'Base Matte', 'L5', '#C0986C', 'matte', 'base', 'media', 'neutro', 5, 6, 29.90, 'rubyrose.com.br'),
    ('Ruby Rose', 'Base Matte', 'L6', '#A88456', 'matte', 'base', 'media', 'quente', 6, 7, 29.90, 'rubyrose.com.br'),
    ('Ruby Rose', 'Base Matte', 'L7', '#906E44', 'matte', 'base', 'media', 'neutro', 7, 8, 29.90, 'rubyrose.com.br'),
    ('Ruby Rose', 'Base Matte', 'L8', '#785836', 'matte', 'base', 'media', 'quente', 8, 9, 29.90, 'rubyrose.com.br');

-- MAC (atualizado com monk tones)
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('MAC', 'Studio Fix Fluid', 'NC15', '#F5D5B8', 'matte', 'base', 'alta', 'quente', 1, 2, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NC20', '#E8C8A8', 'matte', 'base', 'alta', 'quente', 2, 3, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NC25', '#DDB896', 'matte', 'base', 'alta', 'quente', 3, 4, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NC30', '#D4A87A', 'matte', 'base', 'alta', 'quente', 4, 5, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NC35', '#C99A6B', 'matte', 'base', 'alta', 'quente', 5, 6, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NC40', '#BD8A5C', 'matte', 'base', 'alta', 'quente', 5, 6, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NC42', '#B07D4F', 'matte', 'base', 'alta', 'quente', 6, 7, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NC45', '#9E6D42', 'matte', 'base', 'alta', 'quente', 7, 8, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NC50', '#8A5C36', 'matte', 'base', 'alta', 'quente', 8, 9, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NW15', '#F2D4BC', 'matte', 'base', 'alta', 'frio', 1, 2, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NW20', '#E4C4AC', 'matte', 'base', 'alta', 'frio', 2, 3, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NW25', '#D6B49C', 'matte', 'base', 'alta', 'frio', 3, 4, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NW30', '#C8A48C', 'matte', 'base', 'alta', 'frio', 4, 5, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NW35', '#BA947C', 'matte', 'base', 'alta', 'frio', 5, 6, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NW40', '#A8826A', 'matte', 'base', 'alta', 'frio', 6, 7, 249.00, 'maccosmetics.com.br'),
    ('MAC', 'Studio Fix Fluid', 'NW45', '#96705A', 'matte', 'base', 'alta', 'frio', 7, 8, 249.00, 'maccosmetics.com.br');

-- FENTY BEAUTY (atualizado)
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Fenty Beauty', 'Pro Filtr', '100', '#F7E4D0', 'matte', 'base', 'alta', 'neutro', 1, 2, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '130', '#EED2B4', 'matte', 'base', 'alta', 'quente', 2, 3, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '150', '#E6C6A4', 'matte', 'base', 'alta', 'neutro', 2, 3, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '185', '#E0BC96', 'matte', 'base', 'alta', 'quente', 3, 4, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '220', '#D4AA80', 'matte', 'base', 'alta', 'neutro', 4, 5, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '240', '#D2A478', 'matte', 'base', 'alta', 'quente', 4, 5, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '290', '#C69468', 'matte', 'base', 'alta', 'neutro', 5, 6, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '330', '#B8865A', 'matte', 'base', 'alta', 'quente', 5, 6, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '350', '#AA784C', 'matte', 'base', 'alta', 'neutro', 6, 7, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '385', '#9C6A42', 'matte', 'base', 'alta', 'quente', 6, 7, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '400', '#8E5E38', 'matte', 'base', 'alta', 'neutro', 7, 8, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '420', '#7C5034', 'matte', 'base', 'alta', 'quente', 7, 8, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '445', '#6A4430', 'matte', 'base', 'alta', 'neutro', 8, 9, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '450', '#5C3A28', 'matte', 'base', 'alta', 'quente', 8, 9, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '480', '#4A3024', 'matte', 'base', 'alta', 'neutro', 9, 10, 249.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Pro Filtr', '498', '#3C2620', 'matte', 'base', 'alta', 'quente', 9, 10, 249.00, 'sephora.com.br');

-- MAYBELLINE FIT ME (atualizado)
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Maybelline', 'Fit Me', '110', '#F5DEC5', 'natural', 'base', 'leve', 'neutro', 1, 2, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '120', '#EDD0B2', 'natural', 'base', 'leve', 'quente', 2, 3, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '130', '#E4C2A0', 'natural', 'base', 'leve', 'neutro', 2, 3, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '140', '#DCB490', 'natural', 'base', 'leve', 'quente', 3, 4, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '220', '#D8B08A', 'natural', 'base', 'leve', 'neutro', 4, 5, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '230', '#CCA076', 'natural', 'base', 'leve', 'quente', 4, 5, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '310', '#BA8C60', 'natural', 'base', 'leve', 'neutro', 5, 6, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '320', '#AA7C52', 'natural', 'base', 'leve', 'quente', 6, 7, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '330', '#9A6C46', 'natural', 'base', 'leve', 'neutro', 7, 8, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '340', '#8A5C3A', 'natural', 'base', 'leve', 'quente', 8, 9, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '355', '#7A4C30', 'natural', 'base', 'leve', 'neutro', 8, 9, 59.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Fit Me', '360', '#6A3E28', 'natural', 'base', 'leve', 'quente', 9, 10, 59.90, 'belezanaweb.com.br');

-- L'ORÉAL INFALLIBLE
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('L''Oréal', 'Infallible', '100', '#F6E0CA', 'matte', 'base', 'alta', 'neutro', 1, 2, 89.90, 'belezanaweb.com.br'),
    ('L''Oréal', 'Infallible', '110', '#EDD0B4', 'matte', 'base', 'alta', 'quente', 2, 3, 89.90, 'belezanaweb.com.br'),
    ('L''Oréal', 'Infallible', '120', '#E2C0A0', 'matte', 'base', 'alta', 'neutro', 3, 4, 89.90, 'belezanaweb.com.br'),
    ('L''Oréal', 'Infallible', '130', '#D6AE8A', 'matte', 'base', 'alta', 'quente', 4, 5, 89.90, 'belezanaweb.com.br'),
    ('L''Oréal', 'Infallible', '140', '#C89C74', 'matte', 'base', 'alta', 'neutro', 5, 6, 89.90, 'belezanaweb.com.br'),
    ('L''Oréal', 'Infallible', '150', '#B88A60', 'matte', 'base', 'alta', 'quente', 5, 6, 89.90, 'belezanaweb.com.br'),
    ('L''Oréal', 'Infallible', '160', '#A6784E', 'matte', 'base', 'alta', 'neutro', 6, 7, 89.90, 'belezanaweb.com.br'),
    ('L''Oréal', 'Infallible', '170', '#94663E', 'matte', 'base', 'alta', 'quente', 7, 8, 89.90, 'belezanaweb.com.br'),
    ('L''Oréal', 'Infallible', '180', '#825432', 'matte', 'base', 'alta', 'neutro', 8, 9, 89.90, 'belezanaweb.com.br'),
    ('L''Oréal', 'Infallible', '190', '#704428', 'matte', 'base', 'alta', 'quente', 9, 10, 89.90, 'belezanaweb.com.br');

-- =====================================================
-- 4. CORRETIVOS
-- =====================================================
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Bruna Tavares', 'BT Concealer', 'L1', '#F8E6D2', 'natural', 'corretivo', 'alta', 'neutro', 1, 2, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Concealer', 'L2', '#F0D8C0', 'natural', 'corretivo', 'alta', 'quente', 2, 3, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Concealer', 'M3', '#E4C8A8', 'natural', 'corretivo', 'alta', 'neutro', 3, 4, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Concealer', 'M4', '#D8B890', 'natural', 'corretivo', 'alta', 'quente', 4, 5, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Concealer', 'M5', '#C8A478', 'natural', 'corretivo', 'alta', 'neutro', 5, 6, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Concealer', 'D6', '#B89060', 'natural', 'corretivo', 'alta', 'quente', 6, 7, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Concealer', 'D7', '#A07C4C', 'natural', 'corretivo', 'alta', 'neutro', 7, 8, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Concealer', 'D8', '#88683C', 'natural', 'corretivo', 'alta', 'quente', 8, 9, 59.00, 'belezanaweb.com.br'),
    ('Maybelline', 'Instant Age', '100', '#F7E8D4', 'natural', 'corretivo', 'media', 'neutro', 1, 2, 69.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Instant Age', '120', '#EED8C0', 'natural', 'corretivo', 'media', 'quente', 2, 3, 69.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Instant Age', '140', '#E2C8AC', 'natural', 'corretivo', 'media', 'neutro', 3, 4, 69.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Instant Age', '142', '#D8B898', 'natural', 'corretivo', 'media', 'quente', 4, 5, 69.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Instant Age', '145', '#C8A480', 'natural', 'corretivo', 'media', 'neutro', 5, 6, 69.90, 'belezanaweb.com.br'),
    ('Maybelline', 'Instant Age', '148', '#B89068', 'natural', 'corretivo', 'media', 'quente', 6, 7, 69.90, 'belezanaweb.com.br');

-- =====================================================
-- 5. PÓS COMPACTOS E SOLTOS
-- =====================================================
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Bruna Tavares', 'BT Powder', 'Translúcido', '#F8F4EC', 'matte', 'po_solto', 'leve', 'neutro', 1, 5, 69.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Powder', 'Banana', '#F5E8C8', 'matte', 'po_solto', 'leve', 'quente', 3, 7, 69.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Powder', 'Caramelo', '#D4B088', 'matte', 'po_solto', 'leve', 'quente', 5, 8, 69.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Powder', 'Cacau', '#8C6844', 'matte', 'po_solto', 'leve', 'neutro', 7, 10, 69.00, 'belezanaweb.com.br'),
    ('Vult', 'Pó Compacto', '01', '#F4E0CA', 'matte', 'po_compacto', 'leve', 'neutro', 1, 3, 29.90, 'vult.com.br'),
    ('Vult', 'Pó Compacto', '03', '#E4C8A8', 'matte', 'po_compacto', 'leve', 'quente', 3, 5, 29.90, 'vult.com.br'),
    ('Vult', 'Pó Compacto', '05', '#C8A878', 'matte', 'po_compacto', 'leve', 'neutro', 5, 7, 29.90, 'vult.com.br'),
    ('Vult', 'Pó Compacto', '07', '#A88050', 'matte', 'po_compacto', 'leve', 'quente', 7, 9, 29.90, 'vult.com.br');

-- =====================================================
-- 6. CONTORNOS E ILUMINADORES
-- =====================================================
INSERT INTO produtos (marca, linha, cor_nome, hex_code, acabamento, tipo, cobertura, subtom, monk_tone_min, monk_tone_max, preco, onde_comprar) VALUES
    ('Bruna Tavares', 'BT Contour', 'Light', '#C4A080', 'matte', 'contorno', 'media', 'neutro', 1, 4, 49.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Contour', 'Medium', '#9C7850', 'matte', 'contorno', 'media', 'neutro', 4, 7, 49.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Contour', 'Dark', '#6C5038', 'matte', 'contorno', 'media', 'neutro', 7, 10, 49.00, 'belezanaweb.com.br'),
    ('Fenty Beauty', 'Match Stix', 'Amber', '#B08050', 'matte', 'contorno', 'alta', 'quente', 3, 6, 159.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Match Stix', 'Mocha', '#7C5840', 'matte', 'contorno', 'alta', 'neutro', 5, 8, 159.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Match Stix', 'Espresso', '#4C3428', 'matte', 'contorno', 'alta', 'quente', 8, 10, 159.00, 'sephora.com.br'),
    ('Bruna Tavares', 'BT Glow', 'Champagne', '#F0DCC0', 'glow', 'iluminador', 'leve', 'neutro', 1, 5, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Glow', 'Gold', '#E8C890', 'glow', 'iluminador', 'leve', 'quente', 3, 7, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Glow', 'Bronze', '#C8A060', 'glow', 'iluminador', 'leve', 'quente', 5, 9, 59.00, 'belezanaweb.com.br'),
    ('Bruna Tavares', 'BT Glow', 'Copper', '#B88850', 'glow', 'iluminador', 'leve', 'quente', 7, 10, 59.00, 'belezanaweb.com.br'),
    ('Fenty Beauty', 'Killawatt', 'Hu$tla Baby', '#F8E0C8', 'glow', 'iluminador', 'media', 'neutro', 1, 4, 189.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Killawatt', 'Mean Money', '#E8C898', 'glow', 'iluminador', 'media', 'quente', 3, 6, 189.00, 'sephora.com.br'),
    ('Fenty Beauty', 'Killawatt', 'Trophy Wife', '#D4A860', 'glow', 'iluminador', 'media', 'quente', 5, 10, 189.00, 'sephora.com.br');

-- =====================================================
-- 7. ATUALIZAR MARCAS
-- =====================================================
INSERT INTO marcas (nome, pais_origem, site_oficial) VALUES
    ('Natura', 'Brasil', 'https://www.natura.com.br'),
    ('O Boticário', 'Brasil', 'https://www.boticario.com.br'),
    ('Quem Disse Berenice', 'Brasil', 'https://www.quemdisseberenice.com.br'),
    ('Tracta', 'Brasil', 'https://www.tracta.com.br'),
    ('L''Oréal', 'França', 'https://www.loreal-paris.com.br')
ON CONFLICT (nome) DO NOTHING;

-- Verificar total de produtos
-- SELECT tipo, COUNT(*) FROM produtos GROUP BY tipo ORDER BY tipo;
