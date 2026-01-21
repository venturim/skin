'use client';

import { useState, useRef, useCallback, useEffect } from 'react';

// Tipos
interface RGB {
  r: number;
  g: number;
  b: number;
}

interface MonkTone {
  tom: number;
  codigo: string;
  nome: string;
  hex_referencia: string;
  fitzpatrick: string;
  descricao: string;
  undertones_comuns: string[];
  dicas: string[];
  confianca: number;
}

interface Undertone {
  tipo: string;
  tipo_en: string;
  descricao: string;
  cores_ideais: string[];
}

interface AnaliseDetalhada {
  luminosidade: number;
  saturacao: number;
  matiz: number;
  profundidade: string;
  saturacao_descricao: string;
}

interface Produto {
  id?: string;
  marca: string;
  linha: string;
  cor_nome: string;
  hex: string;
  acabamento?: string;
  cobertura?: string;
  subtom?: string;
  preco?: number;
  onde_comprar?: string;
  match_score: number;
}

interface Recomendacoes {
  bases: Produto[];
  corretivos: Produto[];
  pos: Produto[];
  contornos: Produto[];
  iluminadores: Produto[];
}

interface AnalysisResult {
  tom_detectado: {
    hex: string;
    rgb: RGB;
  };
  monk_tone: MonkTone;
  undertone: Undertone;
  analise_detalhada: AnaliseDetalhada;
  recomendacoes: Recomendacoes;
  dicas_profissionais: string[];
  prompt_ia: string;
  imagem_maquiagem?: string;
}

// Regioes do rosto para selecao
type FaceRegion = 'pele' | 'olhos' | 'sobrancelhas' | 'blush' | 'contorno' | 'iluminador' | 'labios';

interface RegionConfig {
  id: FaceRegion;
  nome: string;
  icone: string;
  descricao: string;
  gradientFrom: string;
  gradientTo: string;
  produtos: 'bases' | 'corretivos' | 'pos' | 'contornos' | 'iluminadores';
}

const FACE_REGIONS: RegionConfig[] = [
  { id: 'pele', nome: 'Pele / Base', icone: '🎨', descricao: 'Base e corretivo para pele uniforme', gradientFrom: 'from-amber-400', gradientTo: 'to-orange-500', produtos: 'bases' },
  { id: 'olhos', nome: 'Olhos', icone: '👁️', descricao: 'Sombras, delineado e mascara', gradientFrom: 'from-purple-400', gradientTo: 'to-pink-500', produtos: 'pos' },
  { id: 'sobrancelhas', nome: 'Sobrancelhas', icone: '✨', descricao: 'Definicao e preenchimento', gradientFrom: 'from-stone-400', gradientTo: 'to-stone-600', produtos: 'pos' },
  { id: 'blush', nome: 'Blush', icone: '🌸', descricao: 'Cor e vida nas bochechas', gradientFrom: 'from-rose-400', gradientTo: 'to-pink-500', produtos: 'pos' },
  { id: 'contorno', nome: 'Contorno', icone: '💫', descricao: 'Definicao e escultura facial', gradientFrom: 'from-amber-600', gradientTo: 'to-amber-800', produtos: 'contornos' },
  { id: 'iluminador', nome: 'Iluminador', icone: '✨', descricao: 'Brilho e pontos de luz', gradientFrom: 'from-yellow-300', gradientTo: 'to-amber-400', produtos: 'iluminadores' },
  { id: 'labios', nome: 'Labios', icone: '💋', descricao: 'Batom, gloss e cor', gradientFrom: 'from-red-400', gradientTo: 'to-rose-600', produtos: 'pos' },
];

// Cores extras para labios e olhos
const EXTRA_COLORS = {
  labios: [
    { nome: 'Vermelho Classico', hex: '#C41E3A', acabamento: 'Matte' },
    { nome: 'Rosa Nude', hex: '#D4A5A5', acabamento: 'Cremoso' },
    { nome: 'Vinho', hex: '#722F37', acabamento: 'Matte' },
    { nome: 'Coral', hex: '#FF7F50', acabamento: 'Gloss' },
    { nome: 'Nude Rosado', hex: '#E8B4B8', acabamento: 'Cetim' },
    { nome: 'Rosa Pink', hex: '#FF69B4', acabamento: 'Matte' },
    { nome: 'Terracota', hex: '#C2452D', acabamento: 'Cremoso' },
    { nome: 'Marrom Nude', hex: '#A67B5B', acabamento: 'Cetim' },
  ],
  olhos: [
    { nome: 'Marrom Neutro', hex: '#8B4513', acabamento: 'Matte' },
    { nome: 'Dourado', hex: '#FFD700', acabamento: 'Shimmer' },
    { nome: 'Bronze', hex: '#CD7F32', acabamento: 'Metalico' },
    { nome: 'Preto Esfumado', hex: '#2C2C2C', acabamento: 'Matte' },
    { nome: 'Rose Gold', hex: '#B76E79', acabamento: 'Shimmer' },
    { nome: 'Champagne', hex: '#F7E7CE', acabamento: 'Shimmer' },
    { nome: 'Burgundy', hex: '#800020', acabamento: 'Matte' },
    { nome: 'Cobre', hex: '#B87333', acabamento: 'Metalico' },
  ],
  blush: [
    { nome: 'Pessego', hex: '#FFCBA4', acabamento: 'Matte' },
    { nome: 'Rosa Suave', hex: '#FFB6C1', acabamento: 'Acetinado' },
    { nome: 'Coral Vibrante', hex: '#FF6F61', acabamento: 'Matte' },
    { nome: 'Malva', hex: '#E0B0FF', acabamento: 'Shimmer' },
    { nome: 'Terracota', hex: '#CC5500', acabamento: 'Matte' },
    { nome: 'Berry', hex: '#8E4585', acabamento: 'Cremoso' },
  ],
};

// Escala Monk para visualizacao
const MONK_SCALE = [
  { tom: 1, hex: '#f6ede4', nome: 'Muito Claro' },
  { tom: 2, hex: '#f3e7db', nome: 'Claro' },
  { tom: 3, hex: '#f7ead0', nome: 'Claro Medio' },
  { tom: 4, hex: '#eadaba', nome: 'Medio Claro' },
  { tom: 5, hex: '#d7bd96', nome: 'Medio' },
  { tom: 6, hex: '#a07e56', nome: 'Medio Escuro' },
  { tom: 7, hex: '#825c43', nome: 'Escuro Claro' },
  { tom: 8, hex: '#604134', nome: 'Escuro' },
  { tom: 9, hex: '#3a312a', nome: 'Muito Escuro' },
  { tom: 10, hex: '#2d2926', nome: 'Escuro Profundo' },
];

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function Home() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [result, setResult] = useState<AnalysisResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [cameraReady, setCameraReady] = useState(false);
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [capturedImageBlob, setCapturedImageBlob] = useState<Blob | null>(null);

  // Estado para selecao de maquiagem
  const [showMakeupSelector, setShowMakeupSelector] = useState(false);
  const [selectedRegions, setSelectedRegions] = useState<Set<FaceRegion>>(new Set());
  const [selectedProducts, setSelectedProducts] = useState<Record<FaceRegion, Produto | null>>({
    pele: null,
    olhos: null,
    sobrancelhas: null,
    blush: null,
    contorno: null,
    iluminador: null,
    labios: null,
  });
  const [activeRegion, setActiveRegion] = useState<FaceRegion | null>(null);
  const [generatingImage, setGeneratingImage] = useState(false);
  const [generatedImage, setGeneratedImage] = useState<string | null>(null);

  // Iniciar camera
  const startCamera = useCallback(async () => {
    try {
      setError(null);
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'user', width: { ideal: 1280 }, height: { ideal: 720 } },
        audio: false
      });
      setStream(mediaStream);
    } catch (err) {
      setError('Nao foi possivel acessar a camera: ' + (err instanceof Error ? err.message : 'Erro desconhecido'));
    }
  }, []);

  // Conectar stream ao video
  useEffect(() => {
    if (stream && videoRef.current) {
      videoRef.current.srcObject = stream;
      videoRef.current.onloadedmetadata = () => {
        videoRef.current?.play().then(() => setCameraReady(true)).catch(err => {
          setError('Erro ao iniciar video: ' + err.message);
        });
      };
    }
  }, [stream]);

  // Parar camera
  const stopCamera = useCallback(() => {
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      setStream(null);
      setCameraReady(false);
    }
  }, [stream]);

  // Capturar e analisar
  const captureAndAnalyze = useCallback(async () => {
    if (!videoRef.current || !cameraReady) return;

    setLoading(true);
    setError(null);

    try {
      const canvas = document.createElement('canvas');
      canvas.width = videoRef.current.videoWidth;
      canvas.height = videoRef.current.videoHeight;

      const ctx = canvas.getContext('2d');
      if (!ctx) throw new Error('Nao foi possivel criar contexto do canvas');

      ctx.drawImage(videoRef.current, 0, 0);

      // Salvar imagem capturada para exibir no resultado
      setCapturedImage(canvas.toDataURL('image/jpeg', 0.9));

      const blob = await new Promise<Blob | null>((resolve) => {
        canvas.toBlob(resolve, 'image/jpeg', 0.9);
      });

      if (!blob) throw new Error('Erro ao criar imagem');

      setCapturedImageBlob(blob);

      const formData = new FormData();
      formData.append('image', blob, 'capture.jpg');

      const response = await fetch(`${API_URL}/analyze-complete`, {
        method: 'POST',
        body: formData
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.detail || 'Erro ao analisar imagem');
      }

      setResult(data);
      stopCamera();

    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro desconhecido');
    } finally {
      setLoading(false);
    }
  }, [cameraReady, stopCamera]);

  // Reset
  const reset = useCallback(() => {
    setResult(null);
    setError(null);
    setCapturedImage(null);
    setCapturedImageBlob(null);
    setShowMakeupSelector(false);
    setSelectedRegions(new Set());
    setSelectedProducts({
      pele: null,
      olhos: null,
      sobrancelhas: null,
      blush: null,
      contorno: null,
      iluminador: null,
      labios: null,
    });
    setActiveRegion(null);
    setGeneratedImage(null);
    startCamera();
  }, [startCamera]);

  // Toggle regiao selecionada
  const toggleRegion = useCallback((region: FaceRegion) => {
    setSelectedRegions(prev => {
      const newSet = new Set(prev);
      if (newSet.has(region)) {
        newSet.delete(region);
        setSelectedProducts(p => ({ ...p, [region]: null }));
      } else {
        newSet.add(region);
        setActiveRegion(region);
      }
      return newSet;
    });
  }, []);

  // Selecionar produto para uma regiao
  const selectProduct = useCallback((region: FaceRegion, produto: Produto) => {
    setSelectedProducts(prev => ({ ...prev, [region]: produto }));
  }, []);

  // Obter produtos para uma regiao
  const getProductsForRegion = useCallback((region: FaceRegion): Produto[] => {
    if (!result) return [];

    switch (region) {
      case 'pele':
        return result.recomendacoes.bases;
      case 'contorno':
        return result.recomendacoes.contornos;
      case 'iluminador':
        return result.recomendacoes.iluminadores;
      case 'olhos':
        return EXTRA_COLORS.olhos.map((c, i) => ({
          id: `olhos-${i}`,
          marca: 'Paleta',
          linha: 'Sombras',
          cor_nome: c.nome,
          hex: c.hex,
          acabamento: c.acabamento,
          match_score: 90 - i * 5,
        }));
      case 'labios':
        return EXTRA_COLORS.labios.map((c, i) => ({
          id: `labios-${i}`,
          marca: 'Batom',
          linha: 'Labios',
          cor_nome: c.nome,
          hex: c.hex,
          acabamento: c.acabamento,
          match_score: 90 - i * 5,
        }));
      case 'blush':
        return EXTRA_COLORS.blush.map((c, i) => ({
          id: `blush-${i}`,
          marca: 'Blush',
          linha: 'Bochechas',
          cor_nome: c.nome,
          hex: c.hex,
          acabamento: c.acabamento,
          match_score: 90 - i * 5,
        }));
      case 'sobrancelhas':
        return [
          { id: 'sob-1', marca: 'Lapis', linha: 'Sobrancelhas', cor_nome: 'Castanho Claro', hex: '#8B7355', acabamento: 'Natural', match_score: 95 },
          { id: 'sob-2', marca: 'Lapis', linha: 'Sobrancelhas', cor_nome: 'Castanho Medio', hex: '#6B4423', acabamento: 'Natural', match_score: 90 },
          { id: 'sob-3', marca: 'Lapis', linha: 'Sobrancelhas', cor_nome: 'Castanho Escuro', hex: '#4A3728', acabamento: 'Natural', match_score: 85 },
          { id: 'sob-4', marca: 'Lapis', linha: 'Sobrancelhas', cor_nome: 'Preto Suave', hex: '#2C2C2C', acabamento: 'Natural', match_score: 80 },
        ];
      default:
        return [];
    }
  }, [result]);

  // Gerar prompt personalizado baseado nas selecoes
  const generateCustomPrompt = useCallback(() => {
    if (!result) return '';

    const selectedList = Array.from(selectedRegions);
    if (selectedList.length === 0) return '';

    let prompt = `INSTRUCOES PARA MAQUIAGEM PROFISSIONAL:

Mantenha EXATAMENTE o rosto, expressao, formato dos olhos, nariz, boca e todas as caracteristicas faciais da pessoa na foto original. NAO altere nenhum traco facial.

APLIQUE SOMENTE os seguintes produtos de maquiagem de forma realista e profissional:

`;

    // Adicionar cada regiao selecionada
    selectedList.forEach(region => {
      const produto = selectedProducts[region];
      if (!produto) return;

      const regionConfig = FACE_REGIONS.find(r => r.id === region);
      if (!regionConfig) return;

      switch (region) {
        case 'pele':
          prompt += `PELE/BASE:
- Aplicar base cor ${produto.cor_nome} (${produto.hex}) de forma uniforme em todo o rosto
- Cobertura ${produto.cobertura || 'media'}, acabamento ${produto.acabamento || 'natural'}
- Blend perfeito nas bordas do rosto e pescoco

`;
          break;

        case 'olhos':
          prompt += `OLHOS:
- Aplicar sombra ${produto.cor_nome} (${produto.hex}) nas palpebras
- Acabamento ${produto.acabamento || 'natural'}
- Esfumar suavemente para transicao perfeita
- Delineado discreto na linha dos cilios superiores
- Mascara de cilios para volume natural

`;
          break;

        case 'sobrancelhas':
          prompt += `SOBRANCELHAS:
- Preencher com tom ${produto.cor_nome} (${produto.hex})
- Manter formato natural das sobrancelhas
- Definir e pentear para acabamento limpo

`;
          break;

        case 'blush':
          prompt += `BLUSH:
- Aplicar blush ${produto.cor_nome} (${produto.hex}) nas macas do rosto
- Acabamento ${produto.acabamento || 'natural'}
- Esfumar em direcao as temporas para efeito lifting

`;
          break;

        case 'contorno':
          prompt += `CONTORNO:
- Aplicar contorno ${produto.cor_nome} (${produto.hex}) nas laterais do nariz
- Definir temporas e linha do maxilar
- Blend suave para efeito natural de sombra

`;
          break;

        case 'iluminador':
          prompt += `ILUMINADOR:
- Aplicar iluminador ${produto.cor_nome} (${produto.hex}) nos pontos altos do rosto
- Osso da bochecha, ponta do nariz, arco do cupido
- Brilho sutil e elegante

`;
          break;

        case 'labios':
          prompt += `LABIOS:
- Aplicar batom ${produto.cor_nome} (${produto.hex})
- Acabamento ${produto.acabamento || 'cremoso'}
- Contorno dos labios definido
- Aplicacao uniforme e precisa

`;
          break;
      }
    });

    prompt += `
ESTILO FINAL: Maquiagem brasileira profissional, acabamento impecavel.

IMPORTANTE:
- NAO modificar estrutura facial, apenas adicionar os produtos listados
- Manter naturalidade e realismo
- A foto deve parecer que a pessoa realmente esta usando estes produtos
- Iluminacao e qualidade da foto devem permanecer iguais`;

    return prompt;
  }, [result, selectedRegions, selectedProducts]);

  // Gerar imagem com maquiagem via Gemini
  const generateMakeupImage = useCallback(async () => {
    if (!capturedImageBlob || selectedRegions.size === 0) return;

    setGeneratingImage(true);
    setError(null);

    try {
      const prompt = generateCustomPrompt();

      const formData = new FormData();
      formData.append('image', capturedImageBlob, 'capture.jpg');
      formData.append('prompt', prompt);

      const response = await fetch(`${API_URL}/generate-makeup`, {
        method: 'POST',
        body: formData
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.detail || 'Erro ao gerar imagem');
      }

      if (data.imagem_gerada) {
        setGeneratedImage(`data:image/jpeg;base64,${data.imagem_gerada}`);
      } else {
        throw new Error('Imagem nao foi gerada');
      }

    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao gerar imagem com IA');
    } finally {
      setGeneratingImage(false);
    }
  }, [capturedImageBlob, selectedRegions, generateCustomPrompt]);

  // Helpers
  const translateUndertone = (undertone: string) => {
    const translations: Record<string, string> = {
      'quente': 'Quente',
      'frio': 'Frio',
      'neutro': 'Neutro',
      'oliva': 'Oliva'
    };
    return translations[undertone] || undertone;
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-rose-50 via-amber-50 to-orange-50">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-sm shadow-sm sticky top-0 z-40">
        <div className="max-w-lg mx-auto px-4 py-3">
          <h1 className="text-xl font-bold text-center bg-gradient-to-r from-amber-700 to-rose-600 bg-clip-text text-transparent">
            SkinTone Matcher
          </h1>
          <p className="text-center text-gray-500 text-xs">
            Analise profissional de tom de pele
          </p>
        </div>
      </header>

      <div className="max-w-lg mx-auto px-4 py-4">
        {/* Erro */}
        {error && (
          <div className="mb-4 p-3 bg-red-100 border border-red-200 rounded-xl text-red-700 text-sm">
            {error}
          </div>
        )}

        {/* Estado inicial */}
        {!stream && !result && (
          <div className="text-center py-8">
            <div className="w-28 h-28 mx-auto mb-5 rounded-full bg-gradient-to-br from-amber-200 to-rose-200 flex items-center justify-center shadow-lg">
              <svg className="w-14 h-14 text-amber-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <h2 className="text-lg font-semibold text-gray-800 mb-2">Descubra seu tom de pele</h2>
            <p className="text-gray-500 text-sm mb-6 px-4">
              Tire uma foto do seu rosto para receber uma analise completa e visualizar maquiagens personalizadas
            </p>
            <button
              onClick={startCamera}
              className="w-full max-w-xs py-3.5 bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 text-white rounded-xl font-semibold shadow-lg shadow-amber-200 transition-all"
            >
              Iniciar Camera
            </button>

            {/* Info sobre Monk Scale */}
            <div className="mt-8 p-4 bg-white/70 rounded-2xl">
              <p className="text-xs text-gray-500 mb-3">Baseado na escala Monk Skin Tone (Google)</p>
              <div className="flex justify-center gap-1">
                {MONK_SCALE.map((tone) => (
                  <div
                    key={tone.tom}
                    className="w-6 h-6 rounded-full shadow-sm border border-white"
                    style={{ backgroundColor: tone.hex }}
                    title={`Tom ${tone.tom}: ${tone.nome}`}
                  />
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Camera ativa */}
        {stream && !result && (
          <div className="space-y-4">
            <div className="relative rounded-2xl overflow-hidden shadow-xl bg-black">
              <video
                ref={videoRef}
                autoPlay
                playsInline
                muted
                className="w-full aspect-[3/4] object-cover"
              />
              <div className="absolute inset-0 pointer-events-none">
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-44 h-56 border-2 border-white/40 rounded-full" />
                </div>
                <div className="absolute bottom-3 left-0 right-0 text-center text-white text-sm bg-black/40 py-2 backdrop-blur-sm">
                  {cameraReady ? 'Posicione seu rosto no oval' : 'Carregando camera...'}
                </div>
              </div>
            </div>

            <button
              onClick={captureAndAnalyze}
              disabled={loading || !cameraReady}
              className="w-full py-3.5 bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 disabled:from-gray-400 disabled:to-gray-500 text-white rounded-xl font-semibold shadow-lg transition-all flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  Analisando...
                </>
              ) : (
                'Capturar e Analisar'
              )}
            </button>

            <button
              onClick={stopCamera}
              className="w-full py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl font-medium transition-colors"
            >
              Cancelar
            </button>
          </div>
        )}

        {/* Resultado da Analise */}
        {result && !showMakeupSelector && (
          <div className="space-y-4 pb-6">
            {/* Card principal - Tom detectado */}
            <div className="bg-white rounded-2xl shadow-lg overflow-hidden">
              <div className="bg-gradient-to-r from-amber-500 to-rose-500 p-4">
                <h2 className="text-white font-semibold text-center">Seu Tom de Pele</h2>
              </div>
              <div className="p-4">
                <div className="flex items-start gap-4">
                  {/* Foto + cor detectada */}
                  <div className="flex flex-col items-center gap-2">
                    {capturedImage && (
                      <img
                        src={capturedImage}
                        alt="Sua foto"
                        className="w-16 h-16 rounded-full object-cover border-2 border-white shadow-md"
                      />
                    )}
                    <div
                      className="w-14 h-14 rounded-full shadow-lg border-4 border-white"
                      style={{ backgroundColor: result.tom_detectado.hex }}
                    />
                  </div>

                  {/* Info */}
                  <div className="flex-1">
                    <p className="font-mono text-xl font-bold text-gray-800">
                      {result.tom_detectado.hex.toUpperCase()}
                    </p>
                    <p className="text-sm text-gray-500 mt-1">
                      Tom Monk: <span className="font-semibold text-amber-700">{result.monk_tone.tom}</span> - {result.monk_tone.nome.replace(`Tom ${result.monk_tone.tom} - `, '')}
                    </p>
                    <p className="text-sm text-gray-500">
                      Fitzpatrick: <span className="font-medium">{result.monk_tone.fitzpatrick}</span>
                    </p>
                    <div className="mt-2 flex items-center gap-2">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                        result.undertone.tipo === 'quente' ? 'bg-orange-100 text-orange-700' :
                        result.undertone.tipo === 'frio' ? 'bg-blue-100 text-blue-700' :
                        result.undertone.tipo === 'oliva' ? 'bg-green-100 text-green-700' :
                        'bg-gray-100 text-gray-700'
                      }`}>
                        Subtom {translateUndertone(result.undertone.tipo)}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Escala Monk visual */}
                <div className="mt-4 pt-4 border-t border-gray-100">
                  <p className="text-xs text-gray-400 mb-2 text-center">Escala Monk Skin Tone</p>
                  <div className="flex gap-1 justify-center">
                    {MONK_SCALE.map((tone) => (
                      <div
                        key={tone.tom}
                        className={`w-7 h-7 rounded-full transition-all ${
                          tone.tom === result.monk_tone.tom
                            ? 'ring-2 ring-amber-500 ring-offset-2 scale-110'
                            : ''
                        }`}
                        style={{ backgroundColor: tone.hex }}
                      />
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Analise Detalhada */}
            <div className="bg-white rounded-2xl shadow-lg p-4">
              <h3 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
                <span className="text-lg">📊</span> Analise Detalhada
              </h3>

              <div className="space-y-3">
                <div>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-gray-600">Luminosidade</span>
                    <span className="font-medium">{result.analise_detalhada.luminosidade}%</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-gray-800 to-amber-400 rounded-full transition-all"
                      style={{ width: `${result.analise_detalhada.luminosidade}%` }}
                    />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-gray-600">Saturacao</span>
                    <span className="font-medium">{result.analise_detalhada.saturacao}%</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-gray-400 to-rose-500 rounded-full transition-all"
                      style={{ width: `${result.analise_detalhada.saturacao}%` }}
                    />
                  </div>
                </div>

                <div className="flex gap-4 pt-2">
                  <div className="flex-1 text-center p-2 bg-gray-50 rounded-lg">
                    <p className="text-xs text-gray-500">Profundidade</p>
                    <p className="text-sm font-medium text-gray-800 capitalize">{result.analise_detalhada.profundidade}</p>
                  </div>
                  <div className="flex-1 text-center p-2 bg-gray-50 rounded-lg">
                    <p className="text-xs text-gray-500">Temperatura</p>
                    <p className="text-sm font-medium text-gray-800 capitalize">{result.undertone.tipo}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Dicas Profissionais */}
            <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-2xl shadow-lg p-4 border border-amber-100">
              <h3 className="font-semibold text-amber-800 mb-3 flex items-center gap-2">
                <span className="text-lg">💡</span> Dicas da Maquiadora
              </h3>
              <ul className="space-y-2">
                {result.dicas_profissionais.slice(0, 3).map((dica, index) => (
                  <li key={index} className="flex gap-2 text-sm text-gray-700">
                    <span className="text-amber-500">•</span>
                    {dica}
                  </li>
                ))}
              </ul>
            </div>

            {/* CTA Criar Maquiagem */}
            <div className="bg-gradient-to-r from-purple-500 via-pink-500 to-rose-500 rounded-2xl shadow-xl p-5 text-white">
              <div className="text-center">
                <h3 className="font-bold text-xl mb-2 flex items-center justify-center gap-2">
                  <span>✨</span> Crie sua Maquiagem
                </h3>
                <p className="text-white/90 text-sm mb-4">
                  Selecione produtos para cada regiao do rosto e visualize como ficaria em voce usando IA
                </p>
                <button
                  onClick={() => setShowMakeupSelector(true)}
                  className="w-full py-3.5 bg-white text-purple-600 rounded-xl font-bold text-lg shadow-lg hover:bg-purple-50 transition-all transform hover:scale-[1.02]"
                >
                  Personalizar Maquiagem
                </button>
              </div>
            </div>

            {/* Botoes de acao */}
            <button
              onClick={reset}
              className="w-full py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl font-medium transition-colors"
            >
              Nova Analise
            </button>
          </div>
        )}

        {/* Seletor de Maquiagem por Regiao */}
        {result && showMakeupSelector && !generatedImage && (
          <div className="space-y-4 pb-6">
            {/* Header com foto */}
            <div className="bg-white rounded-2xl shadow-lg p-4">
              <div className="flex items-center gap-4">
                {capturedImage && (
                  <img
                    src={capturedImage}
                    alt="Sua foto"
                    className="w-20 h-20 rounded-2xl object-cover shadow-md"
                  />
                )}
                <div className="flex-1">
                  <h2 className="font-bold text-gray-800 text-lg">Monte sua Maquiagem</h2>
                  <p className="text-gray-500 text-sm">Selecione as regioes e escolha os produtos</p>
                  <div className="mt-2 flex items-center gap-2">
                    <div
                      className="w-5 h-5 rounded-full border-2 border-white shadow"
                      style={{ backgroundColor: result.tom_detectado.hex }}
                    />
                    <span className="text-xs text-gray-500">Tom {result.monk_tone.tom} - {result.undertone.tipo}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Grid de Regioes do Rosto */}
            <div className="bg-white rounded-2xl shadow-lg p-4">
              <h3 className="font-semibold text-gray-800 mb-3">Selecione as Regioes</h3>
              <div className="grid grid-cols-2 gap-3">
                {FACE_REGIONS.map((region) => {
                  const isSelected = selectedRegions.has(region.id);
                  const hasProduct = selectedProducts[region.id] !== null;

                  return (
                    <button
                      key={region.id}
                      onClick={() => toggleRegion(region.id)}
                      className={`relative p-4 rounded-xl text-left transition-all transform ${
                        isSelected
                          ? `bg-gradient-to-br ${region.gradientFrom} ${region.gradientTo} text-white shadow-lg scale-[1.02]`
                          : 'bg-gray-50 hover:bg-gray-100 text-gray-700'
                      }`}
                    >
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-xl">{region.icone}</span>
                        <span className="font-semibold text-sm">{region.nome}</span>
                      </div>
                      <p className={`text-xs ${isSelected ? 'text-white/80' : 'text-gray-500'}`}>
                        {region.descricao}
                      </p>

                      {/* Indicador de produto selecionado */}
                      {hasProduct && (
                        <div className="absolute top-2 right-2">
                          <div
                            className="w-6 h-6 rounded-full border-2 border-white shadow-md"
                            style={{ backgroundColor: selectedProducts[region.id]?.hex }}
                          />
                        </div>
                      )}

                      {/* Checkmark */}
                      {isSelected && (
                        <div className="absolute bottom-2 right-2">
                          <svg className="w-5 h-5 text-white/80" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                          </svg>
                        </div>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Seletor de Produtos por Regiao */}
            {selectedRegions.size > 0 && (
              <div className="bg-white rounded-2xl shadow-lg overflow-hidden">
                <div className="p-4 border-b border-gray-100 bg-gradient-to-r from-gray-50 to-white">
                  <h3 className="font-semibold text-gray-800">Escolha os Produtos</h3>
                  <p className="text-xs text-gray-500">Toque em uma regiao para ver as opcoes</p>
                </div>

                {/* Tabs das regioes selecionadas */}
                <div className="flex overflow-x-auto border-b border-gray-100">
                  {Array.from(selectedRegions).map((regionId) => {
                    const region = FACE_REGIONS.find(r => r.id === regionId);
                    if (!region) return null;

                    const hasProduct = selectedProducts[regionId] !== null;

                    return (
                      <button
                        key={regionId}
                        onClick={() => setActiveRegion(regionId)}
                        className={`flex-shrink-0 px-4 py-3 text-sm font-medium transition-colors flex items-center gap-2 ${
                          activeRegion === regionId
                            ? 'text-purple-700 border-b-2 border-purple-500 bg-purple-50'
                            : 'text-gray-500 hover:text-gray-700'
                        }`}
                      >
                        <span>{region.icone}</span>
                        <span>{region.nome}</span>
                        {hasProduct && (
                          <div
                            className="w-4 h-4 rounded-full border border-white shadow"
                            style={{ backgroundColor: selectedProducts[regionId]?.hex }}
                          />
                        )}
                      </button>
                    );
                  })}
                </div>

                {/* Lista de produtos para a regiao ativa */}
                {activeRegion && (
                  <div className="p-3 max-h-64 overflow-y-auto">
                    <div className="grid grid-cols-2 gap-2">
                      {getProductsForRegion(activeRegion).map((produto, index) => {
                        const isProductSelected = selectedProducts[activeRegion]?.id === produto.id ||
                          (selectedProducts[activeRegion]?.cor_nome === produto.cor_nome &&
                           selectedProducts[activeRegion]?.hex === produto.hex);

                        return (
                          <button
                            key={produto.id || index}
                            onClick={() => selectProduct(activeRegion, produto)}
                            className={`p-3 rounded-xl text-left transition-all ${
                              isProductSelected
                                ? 'bg-purple-100 border-2 border-purple-400 shadow-md'
                                : 'bg-gray-50 hover:bg-gray-100 border-2 border-transparent'
                            }`}
                          >
                            <div className="flex items-center gap-2 mb-1">
                              <div
                                className="w-8 h-8 rounded-full shadow border-2 border-white flex-shrink-0"
                                style={{ backgroundColor: produto.hex }}
                              />
                              <div className="min-w-0 flex-1">
                                <p className="font-medium text-sm text-gray-800 truncate">
                                  {produto.cor_nome}
                                </p>
                                <p className="text-[10px] text-gray-500 truncate">
                                  {produto.acabamento || produto.marca}
                                </p>
                              </div>
                            </div>
                            {isProductSelected && (
                              <div className="flex justify-end">
                                <svg className="w-4 h-4 text-purple-600" fill="currentColor" viewBox="0 0 20 20">
                                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                </svg>
                              </div>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Resumo das selecoes */}
            {selectedRegions.size > 0 && (
              <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-2xl shadow-lg p-4 border border-purple-100">
                <h3 className="font-semibold text-purple-800 mb-3 flex items-center gap-2">
                  <span>🎨</span> Sua Selecao
                </h3>
                <div className="space-y-2">
                  {Array.from(selectedRegions).map((regionId) => {
                    const region = FACE_REGIONS.find(r => r.id === regionId);
                    const produto = selectedProducts[regionId];

                    return (
                      <div key={regionId} className="flex items-center justify-between py-2 border-b border-purple-100 last:border-0">
                        <div className="flex items-center gap-2">
                          <span>{region?.icone}</span>
                          <span className="text-sm font-medium text-gray-700">{region?.nome}</span>
                        </div>
                        {produto ? (
                          <div className="flex items-center gap-2">
                            <span className="text-xs text-gray-600">{produto.cor_nome}</span>
                            <div
                              className="w-5 h-5 rounded-full border-2 border-white shadow"
                              style={{ backgroundColor: produto.hex }}
                            />
                          </div>
                        ) : (
                          <span className="text-xs text-gray-400">Selecione...</span>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Botao Gerar Imagem */}
            <div className="space-y-3">
              <button
                onClick={generateMakeupImage}
                disabled={generatingImage || selectedRegions.size === 0 || Array.from(selectedRegions).some(r => !selectedProducts[r])}
                className={`w-full py-4 rounded-xl font-bold text-lg shadow-lg transition-all transform ${
                  generatingImage || selectedRegions.size === 0 || Array.from(selectedRegions).some(r => !selectedProducts[r])
                    ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                    : 'bg-gradient-to-r from-purple-500 via-pink-500 to-rose-500 text-white hover:scale-[1.02]'
                }`}
              >
                {generatingImage ? (
                  <span className="flex items-center justify-center gap-2">
                    <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                    </svg>
                    Gerando com IA...
                  </span>
                ) : (
                  <span className="flex items-center justify-center gap-2">
                    <span>✨</span>
                    Gerar Visualizacao
                  </span>
                )}
              </button>

              <button
                onClick={() => setShowMakeupSelector(false)}
                className="w-full py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl font-medium transition-colors"
              >
                Voltar
              </button>
            </div>
          </div>
        )}

        {/* Resultado da Imagem Gerada */}
        {generatedImage && (
          <div className="space-y-4 pb-6">
            <div className="bg-white rounded-2xl shadow-lg overflow-hidden">
              <div className="bg-gradient-to-r from-purple-500 via-pink-500 to-rose-500 p-4">
                <h2 className="text-white font-bold text-center text-lg flex items-center justify-center gap-2">
                  <span>✨</span> Sua Maquiagem
                </h2>
              </div>

              {/* Comparacao lado a lado */}
              <div className="p-4">
                <div className="grid grid-cols-2 gap-3">
                  <div className="text-center">
                    <p className="text-xs text-gray-500 mb-2">Antes</p>
                    <img
                      src={capturedImage || ''}
                      alt="Antes"
                      className="w-full rounded-xl shadow-md"
                    />
                  </div>
                  <div className="text-center">
                    <p className="text-xs text-gray-500 mb-2">Depois</p>
                    <img
                      src={generatedImage}
                      alt="Com maquiagem"
                      className="w-full rounded-xl shadow-md"
                    />
                  </div>
                </div>

                {/* Imagem grande */}
                <div className="mt-4">
                  <img
                    src={generatedImage}
                    alt="Resultado final"
                    className="w-full rounded-2xl shadow-lg"
                  />
                </div>
              </div>
            </div>

            {/* Produtos utilizados */}
            <div className="bg-white rounded-2xl shadow-lg p-4">
              <h3 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
                <span>💄</span> Produtos Aplicados
              </h3>
              <div className="space-y-2">
                {Array.from(selectedRegions).map((regionId) => {
                  const region = FACE_REGIONS.find(r => r.id === regionId);
                  const produto = selectedProducts[regionId];
                  if (!produto) return null;

                  return (
                    <div key={regionId} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                      <div
                        className="w-10 h-10 rounded-full shadow border-2 border-white flex-shrink-0"
                        style={{ backgroundColor: produto.hex }}
                      />
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-gray-800 text-sm">{region?.nome}</p>
                        <p className="text-xs text-gray-500">{produto.cor_nome} - {produto.acabamento || produto.marca}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Botoes de acao */}
            <div className="space-y-3">
              <button
                onClick={() => {
                  setGeneratedImage(null);
                  setShowMakeupSelector(true);
                }}
                className="w-full py-3.5 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-xl font-semibold shadow-lg transition-all"
              >
                Tentar Outros Produtos
              </button>

              <button
                onClick={reset}
                className="w-full py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl font-medium transition-colors"
              >
                Nova Analise
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Footer */}
      <footer className="text-center text-gray-400 text-xs py-4 border-t border-gray-100 bg-white/50">
        <p>SkinTone Matcher</p>
        <p className="text-[10px] mt-1">Baseado na Monk Skin Tone Scale (Google)</p>
      </footer>
    </main>
  );
}
