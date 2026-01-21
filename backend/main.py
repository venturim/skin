from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional
import cv2
import numpy as np
import httpx
import os
import io
import base64
import colorsys
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="SkinTone Matcher API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Config
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

def get_supabase_headers():
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json"
    }

# =====================================================
# ESCALA MONK SKIN TONE (Google)
# =====================================================
MONK_SKIN_TONES = [
    {"codigo": "MST01", "tom": 1, "nome": "Tom 1 - Muito Claro", "hex": "#f6ede4", "rgb": (246, 237, 228), "fitzpatrick": "I",
     "descricao": "Pele muito clara. Queima facilmente ao sol.", "undertones": ["frio", "neutro"],
     "dicas": ["Use bases com subtom rosado ou neutro", "Protetor solar e essencial", "Blush em tons rosados ou pessego suave"]},
    {"codigo": "MST02", "tom": 2, "nome": "Tom 2 - Claro", "hex": "#f3e7db", "rgb": (243, 231, 219), "fitzpatrick": "I-II",
     "descricao": "Pele clara com leve tonalidade. Queima com facilidade.", "undertones": ["frio", "neutro", "quente"],
     "dicas": ["Bases com subtom amarelo suave ou rosado", "Iluminadores champagne funcionam bem", "Bronzer leve para dar vida"]},
    {"codigo": "MST03", "tom": 3, "nome": "Tom 3 - Claro Medio", "hex": "#f7ead0", "rgb": (247, 234, 208), "fitzpatrick": "II",
     "descricao": "Pele clara com fundo dourado. Bronzeia levemente.", "undertones": ["quente", "neutro"],
     "dicas": ["Bases com subtom dourado ou pessego", "Contorno em tons de caramelo", "Blush coral ou pessego"]},
    {"codigo": "MST04", "tom": 4, "nome": "Tom 4 - Medio Claro", "hex": "#eadaba", "rgb": (234, 218, 186), "fitzpatrick": "II-III",
     "descricao": "Pele media clara, comum em latinas. Bronzeia gradualmente.", "undertones": ["quente", "neutro", "oliva"],
     "dicas": ["Bases com subtom amarelo ou oliva", "Evite bases muito rosadas", "Iluminadores dourados"]},
    {"codigo": "MST05", "tom": 5, "nome": "Tom 5 - Medio", "hex": "#d7bd96", "rgb": (215, 189, 150), "fitzpatrick": "III",
     "descricao": "Pele media, muito comum em brasileiros.", "undertones": ["quente", "neutro", "oliva"],
     "dicas": ["Ampla gama de subtons funciona", "Contorno em tons de chocolate ao leite", "Blush em tons terrosos ou coral"]},
    {"codigo": "MST06", "tom": 6, "nome": "Tom 6 - Medio Escuro", "hex": "#a07e56", "rgb": (160, 126, 86), "fitzpatrick": "III-IV",
     "descricao": "Pele media escura com fundo dourado.", "undertones": ["quente", "neutro"],
     "dicas": ["Bases com subtom dourado ou caramelo", "Iluminadores bronze ou cobre", "Blush em tons de ameixa ou terracota"]},
    {"codigo": "MST07", "tom": 7, "nome": "Tom 7 - Escuro Claro", "hex": "#825c43", "rgb": (130, 92, 67), "fitzpatrick": "IV-V",
     "descricao": "Pele escura clara.", "undertones": ["quente", "neutro", "vermelho"],
     "dicas": ["Bases com subtom vermelho ou dourado", "Evite bases acinzentadas", "Iluminadores dourados ou bronze"]},
    {"codigo": "MST08", "tom": 8, "nome": "Tom 8 - Escuro", "hex": "#604134", "rgb": (96, 65, 52), "fitzpatrick": "V",
     "descricao": "Pele escura com tons ricos.", "undertones": ["quente", "vermelho", "neutro"],
     "dicas": ["Bases com subtom vermelho ou mogno", "Contorno em tons de chocolate amargo", "Iluminadores dourados intensos"]},
    {"codigo": "MST09", "tom": 9, "nome": "Tom 9 - Muito Escuro", "hex": "#3a312a", "rgb": (58, 49, 42), "fitzpatrick": "V-VI",
     "descricao": "Pele muito escura com reflexos.", "undertones": ["vermelho", "neutro", "azul"],
     "dicas": ["Bases com subtom vermelho ou neutro", "Evite bases com fundo cinza", "Iluminadores dourados ou rose gold"]},
    {"codigo": "MST10", "tom": 10, "nome": "Tom 10 - Escuro Profundo", "hex": "#2d2926", "rgb": (45, 41, 38), "fitzpatrick": "VI",
     "descricao": "Pele escura profunda, rica em melanina.", "undertones": ["vermelho", "neutro"],
     "dicas": ["Bases com bastante pigmento vermelho", "Iluminadores cobre ou bronze", "Blush em tons de vinho ou berry"]}
]

# =====================================================
# FUNCOES AUXILIARES
# =====================================================
face_cascade = None

def get_face_cascade():
    global face_cascade
    if face_cascade is None:
        cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        face_cascade = cv2.CascadeClassifier(cascade_path)
    return face_cascade

def extract_skin_color_opencv(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    cascade = get_face_cascade()
    faces = cascade.detectMultiScale(gray, scaleFactor=1.05, minNeighbors=3, minSize=(50, 50), flags=cv2.CASCADE_SCALE_IMAGE)
    if len(faces) == 0:
        faces = cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=2, minSize=(30, 30))
    if len(faces) == 0:
        return None, "Nenhum rosto detectado na imagem"
    x, y, w, h = max(faces, key=lambda f: f[2] * f[3])
    cheek_region = img[y + int(h * 0.35):y + int(h * 0.65), x + int(w * 0.15):x + int(w * 0.85)]
    if cheek_region.size == 0:
        return None, "Nao foi possivel extrair a regiao da pele"
    hsv = cv2.cvtColor(cheek_region, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(hsv, np.array([0, 20, 70], dtype=np.uint8), np.array([50, 255, 255], dtype=np.uint8))
    skin_pixels = cheek_region[mask > 0]
    if len(skin_pixels) < 100:
        skin_pixels = cheek_region.reshape(-1, 3)
    avg_color = np.mean(skin_pixels, axis=0).astype(int)
    return (int(avg_color[2]), int(avg_color[1]), int(avg_color[0])), None

def hex_to_rgb(hex_color: str) -> tuple:
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(r: int, g: int, b: int) -> str:
    return "#{:02x}{:02x}{:02x}".format(r, g, b)

def rgb_to_hsl(r: int, g: int, b: int) -> tuple:
    r_norm, g_norm, b_norm = r / 255.0, g / 255.0, b / 255.0
    h, l, s = colorsys.rgb_to_hls(r_norm, g_norm, b_norm)
    return (int(h * 360), int(s * 100), int(l * 100))

def calculate_color_distance(rgb1: tuple, rgb2: tuple) -> float:
    return np.sqrt(sum((a - b) ** 2 for a, b in zip(rgb1, rgb2)))

def classify_monk_tone(r: int, g: int, b: int) -> dict:
    min_distance = float('inf')
    closest_tone = MONK_SKIN_TONES[4]
    for tone in MONK_SKIN_TONES:
        distance = calculate_color_distance((r, g, b), tone["rgb"])
        if distance < min_distance:
            min_distance = distance
            closest_tone = tone
    confidence = max(0, 100 - (min_distance / 441.67 * 100))
    return {
        "tom": closest_tone["tom"], "codigo": closest_tone["codigo"], "nome": closest_tone["nome"],
        "hex_referencia": closest_tone["hex"], "fitzpatrick": closest_tone["fitzpatrick"],
        "descricao": closest_tone["descricao"], "undertones_comuns": closest_tone["undertones"],
        "dicas": closest_tone["dicas"], "confianca": round(confidence, 1)
    }

def determine_undertone(r: int, g: int, b: int) -> dict:
    h, s, l = rgb_to_hsl(r, g, b)
    if r > b and (r - b) > 15:
        undertone, undertone_en = "quente", "warm"
        descricao = "Tons dourados, amarelados ou pessego. Veias esverdeadas no pulso."
        cores_ideais = ["dourado", "caramelo", "pessego", "coral", "bronze"]
    elif b > r and (b - r) > 15:
        undertone, undertone_en = "frio", "cool"
        descricao = "Tons rosados ou azulados. Veias azuladas ou roxas no pulso."
        cores_ideais = ["rosa", "vinho", "ameixa", "prata", "berry"]
    else:
        undertone, undertone_en = "neutro", "neutral"
        descricao = "Equilibrio entre tons quentes e frios."
        cores_ideais = ["nude", "rose", "terracota suave", "champagne"]
    if g > (r + b) / 2 * 0.9 and g < (r + b) / 2 * 1.1 and s < 50:
        if undertone in ["quente", "neutro"]:
            undertone, undertone_en = "oliva", "olive"
            descricao = "Tom esverdeado sob a pele. Comum em brasileiros."
            cores_ideais = ["terracota", "mostarda", "verde oliva", "bronze", "cobre"]
    return {"tipo": undertone, "tipo_en": undertone_en, "descricao": descricao, "cores_ideais": cores_ideais}

def analyze_skin_detailed(r: int, g: int, b: int) -> dict:
    h, s, l = rgb_to_hsl(r, g, b)
    if l >= 80: profundidade = "muito clara"
    elif l >= 65: profundidade = "clara"
    elif l >= 50: profundidade = "media"
    elif l >= 35: profundidade = "media escura"
    elif l >= 20: profundidade = "escura"
    else: profundidade = "muito escura"
    saturacao_desc = "alta" if s >= 60 else "media" if s >= 35 else "baixa"
    return {"luminosidade": l, "saturacao": s, "matiz": h, "profundidade": profundidade, "saturacao_descricao": saturacao_desc}

def generate_makeup_prompt_for_gemini(monk_tone: dict, undertone: dict, base: dict) -> str:
    tom_num = monk_tone.get("tom", 5)
    if tom_num <= 3:
        blush = "rosa pessego suave"
        sombra = "neutros claros (bege, champagne)"
        batom = "nude rosado ou coral claro"
    elif tom_num <= 6:
        blush = "coral ou terracota"
        sombra = "bronze, cobre, marrom"
        batom = "nude caramelo ou coral"
    else:
        blush = "ameixa ou berry"
        sombra = "bronze, cobre, dourado intenso"
        batom = "vinho ou nude escuro"

    prompt = f"""Aplique maquiagem profissional nesta foto mantendo EXATAMENTE o rosto, expressao e todas as caracteristicas faciais originais da pessoa. NAO altere o formato do rosto, olhos, nariz, boca ou qualquer outra caracteristica.

MAQUIAGEM A APLICAR:

PELE:
- Base uniforme tom {base.get('hex', monk_tone.get('hex_referencia', '#d7bd96'))}, cobertura media, acabamento natural
- Corretivo nas olheiras (1-2 tons mais claro)
- Po translucido na zona T

CONTORNO E ILUMINACAO:
- Contorno suave nas temporas, laterais do nariz e maxilar
- Blush {blush} nas macas do rosto
- Iluminador no osso da bochecha, ponta do nariz e arco do cupido

OLHOS:
- Sombras em tons {sombra}
- Delineado fino e elegante
- Mascara de cilios com volume natural

SOBRANCELHAS:
- Preenchidas naturalmente, penteadas

LABIOS:
- Batom {batom}, acabamento cremoso

ESTILO: Maquiagem profissional brasileira, pele luminosa e saudavel, acabamento glow natural. A maquiagem deve parecer feita por uma maquiadora profissional.

CRITICO: Mantenha 100% da identidade facial da pessoa - apenas adicione a maquiagem de forma hiper-realista."""

    return prompt

async def generate_makeup_image_gemini(image_bytes: bytes, prompt: str) -> Optional[str]:
    """Gera imagem com maquiagem usando Google Gemini API."""
    if not GOOGLE_API_KEY:
        return None

    try:
        # Converter imagem para base64
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')

        # Preparar request para Gemini
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent?key={GOOGLE_API_KEY}"

        payload = {
            "contents": [
                {
                    "parts": [
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": image_base64
                            }
                        },
                        {
                            "text": prompt
                        }
                    ]
                }
            ],
            "generationConfig": {
                "responseModalities": ["image", "text"],
                "responseMimeType": "image/jpeg"
            }
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(url, json=payload)

            if response.status_code != 200:
                print(f"Gemini API error: {response.status_code} - {response.text}")
                return None

            data = response.json()

            # Extrair imagem da resposta
            if "candidates" in data and len(data["candidates"]) > 0:
                candidate = data["candidates"][0]
                if "content" in candidate and "parts" in candidate["content"]:
                    for part in candidate["content"]["parts"]:
                        if "inlineData" in part:
                            return part["inlineData"]["data"]

            return None

    except Exception as e:
        print(f"Erro ao gerar imagem com Gemini: {e}")
        return None

# =====================================================
# ENDPOINTS
# =====================================================

@app.get("/")
async def root():
    return {"message": "SkinTone Matcher API", "version": "2.1", "status": "running", "gemini_enabled": bool(GOOGLE_API_KEY)}

@app.get("/health")
async def health():
    supabase_ok = False
    if SUPABASE_URL and SUPABASE_KEY:
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(f"{SUPABASE_URL}/rest/v1/", headers=get_supabase_headers())
                supabase_ok = resp.status_code == 200
        except:
            pass
    return {"status": "healthy", "supabase_connected": supabase_ok, "gemini_enabled": bool(GOOGLE_API_KEY)}

@app.get("/monk-scale")
async def get_monk_scale():
    return {"escala": "Monk Skin Tone Scale", "fonte": "Google / Dr. Ellis Monk", "tons": MONK_SKIN_TONES}

@app.post("/analyze")
async def analyze_skin(image: UploadFile = File(...)):
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Arquivo deve ser uma imagem")
    contents = await image.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise HTTPException(status_code=400, detail="Nao foi possivel processar a imagem")
    rgb_color, error = extract_skin_color_opencv(img)
    if error:
        raise HTTPException(status_code=400, detail=error)
    r, g, b = rgb_color
    hex_color = rgb_to_hex(r, g, b)
    undertone_data = determine_undertone(r, g, b)
    monk_data = classify_monk_tone(r, g, b)
    recommendations = []
    if SUPABASE_URL and SUPABASE_KEY:
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(f"{SUPABASE_URL}/rest/v1/produtos?select=*&ativo=eq.true&tipo=eq.base", headers=get_supabase_headers())
                products = resp.json()
            for p in products:
                if not p.get("hex_code"): continue
                product_rgb = hex_to_rgb(p["hex_code"])
                diff = calculate_color_distance((r, g, b), product_rgb)
                score = max(0, 100 - (diff / 4.41))
                recommendations.append({
                    "id": p.get("id"), "marca": p.get("marca"), "linha": p.get("linha"),
                    "cor_nome": p.get("cor_nome"), "hex": p.get("hex_code"),
                    "acabamento": p.get("acabamento"), "match_score": round(score, 1)
                })
            recommendations.sort(key=lambda x: x["match_score"], reverse=True)
        except Exception as e:
            print(f"Erro ao buscar produtos: {e}")
    return {
        "skin_tone": {"hex": hex_color, "rgb": {"r": int(r), "g": int(g), "b": int(b)}, "undertone": undertone_data["tipo"]},
        "monk_tone": monk_data,
        "recommendations": recommendations[:5]
    }

@app.post("/analyze-complete")
async def analyze_skin_complete(image: UploadFile = File(...)):
    """Analise completa com geracao automatica de imagem com maquiagem."""
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Arquivo deve ser uma imagem")

    contents = await image.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        raise HTTPException(status_code=400, detail="Nao foi possivel processar a imagem")

    rgb_color, error = extract_skin_color_opencv(img)
    if error:
        raise HTTPException(status_code=400, detail=error)

    r, g, b = rgb_color
    hex_color = rgb_to_hex(r, g, b)
    undertone_data = determine_undertone(r, g, b)
    monk_data = classify_monk_tone(r, g, b)
    detailed_analysis = analyze_skin_detailed(r, g, b)

    # Buscar produtos
    recommendations = {"bases": [], "corretivos": [], "pos": [], "contornos": [], "iluminadores": []}

    if SUPABASE_URL and SUPABASE_KEY:
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(f"{SUPABASE_URL}/rest/v1/produtos?select=*&ativo=eq.true", headers=get_supabase_headers())
                products = resp.json()

            for p in products:
                if not p.get("hex_code"): continue
                product_rgb = hex_to_rgb(p["hex_code"])
                diff = calculate_color_distance((r, g, b), product_rgb)
                score = max(0, 100 - (diff / 4.41))
                product_data = {
                    "id": p.get("id"), "marca": p.get("marca"), "linha": p.get("linha"),
                    "cor_nome": p.get("cor_nome"), "hex": p.get("hex_code"),
                    "acabamento": p.get("acabamento"), "cobertura": p.get("cobertura"),
                    "subtom": p.get("subtom"), "preco": p.get("preco"),
                    "onde_comprar": p.get("onde_comprar"), "match_score": round(score, 1)
                }
                tipo = p.get("tipo", "base")
                if tipo == "base": recommendations["bases"].append(product_data)
                elif tipo == "corretivo": recommendations["corretivos"].append(product_data)
                elif tipo in ["po_compacto", "po_solto"]: recommendations["pos"].append(product_data)
                elif tipo == "contorno": recommendations["contornos"].append(product_data)
                elif tipo == "iluminador": recommendations["iluminadores"].append(product_data)

            for key in recommendations:
                recommendations[key].sort(key=lambda x: x["match_score"], reverse=True)
                recommendations[key] = recommendations[key][:5]
        except Exception as e:
            print(f"Erro ao buscar produtos: {e}")

    # Selecionar melhor base
    best_base = recommendations["bases"][0] if recommendations["bases"] else {}

    # Gerar prompt e imagem com Gemini
    gemini_prompt = generate_makeup_prompt_for_gemini(monk_data, undertone_data, best_base)
    makeup_image_base64 = await generate_makeup_image_gemini(contents, gemini_prompt)

    return {
        "tom_detectado": {"hex": hex_color, "rgb": {"r": int(r), "g": int(g), "b": int(b)}},
        "monk_tone": monk_data,
        "undertone": undertone_data,
        "analise_detalhada": detailed_analysis,
        "recomendacoes": recommendations,
        "dicas_profissionais": monk_data.get("dicas", []),
        "prompt_ia": gemini_prompt,
        "imagem_maquiagem": makeup_image_base64
    }

@app.post("/generate-makeup")
async def generate_makeup_custom(
    image: UploadFile = File(...),
    prompt: str = Form(...)
):
    """Gera imagem com maquiagem usando prompt personalizado do usuario."""
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Arquivo deve ser uma imagem")

    if not GOOGLE_API_KEY:
        raise HTTPException(status_code=503, detail="API do Gemini nao configurada")

    if not prompt or len(prompt) < 10:
        raise HTTPException(status_code=400, detail="Prompt muito curto ou vazio")

    contents = await image.read()

    # Gerar imagem com Gemini usando o prompt personalizado
    generated_image = await generate_makeup_image_gemini(contents, prompt)

    if not generated_image:
        raise HTTPException(status_code=500, detail="Falha ao gerar imagem com IA. Tente novamente.")

    return {
        "sucesso": True,
        "imagem_gerada": generated_image,
        "prompt_usado": prompt[:200] + "..." if len(prompt) > 200 else prompt
    }

@app.get("/products")
async def list_products(tipo: Optional[str] = None):
    if not SUPABASE_URL or not SUPABASE_KEY:
        return []
    try:
        url = f"{SUPABASE_URL}/rest/v1/produtos?select=*&ativo=eq.true"
        if tipo: url += f"&tipo=eq.{tipo}"
        async with httpx.AsyncClient() as client:
            resp = await client.get(url, headers=get_supabase_headers())
            return resp.json()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
