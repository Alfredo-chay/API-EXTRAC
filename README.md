# API-EXTRAC: Microservicio de Extracción Estructurada con LLM

API en Python con FastAPI que recibe texto y devuelve una respuesta estructurada (JSON) validada, aplicando prompting avanzado, contrato de salida y validación con Pydantic.

## 📋 Requisitos

- Python 3.9+
- pip
- API key de OpenAI (o Google Gemini para fallback)

## 🚀 Instalación y Ejecución

### 1. Clonar y configurar el entorno

```bash
git clone https://github.com/Alfredo-chay/API-EXTRAC.git
cd API-EXTRAC
```

### 2. Crear archivo `.env` con tu API key

```bash
echo "OPENAI_API_KEY=tu_api_key_aqui" > .env
```

**⚠️ Nota de seguridad**: El archivo `.env` no debe subirse al repositorio.

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 4. Ejecutar la API

```bash
uvicorn main:app --host 127.0.0.1 --port 8000
```

La API estará disponible en: `http://127.0.0.1:8000`

Documentación interactiva (Swagger): `http://127.0.0.1:8000/docs`

---

## 📡 Endpoint: POST /extract

### Request Body

```json
{
  "text": "string (texto a analizar)",
  "domain": "string (contexto: universidad, soporte, ventas, etc.)"
}
```

### Response Body

```json
{
  "summary": "string (resumen máx 60 palabras)",
  "entities": [
    {
      "name": "string",
      "type": "PERSON | ORG | DATE | LOCATION | OTHER"
    }
  ],
  "actions": ["string (acciones sugeridas)"],
  "confidence": "number (0.0 - 1.0)",
  "needs_clarification": "boolean",
  "clarifying_questions": ["string (vacía si needs_clarification = false)"]
}
```

---

## 📝 Ejemplos de Uso

### Ejemplo A: Texto Claro (NO requiere aclaración)

#### Request (curl)

```bash
curl -X POST http://127.0.0.1:8000/extract \
  -H "Content-Type: application/json" \
  -d '{
    "text": "La Universidad organizará una reunión el 10 de abril de 2026 en el auditorio principal. María López coordinará el evento y se solicitará confirmar asistencia antes del 5 de abril.",
    "domain": "universidad"
  }'
```

#### Response

```json
{
  "summary": "Se programó una reunión universitaria para el 10 de abril de 2026 en el auditorio principal. María López coordina el evento y se debe confirmar asistencia antes del 5 de abril.",
  "entities": [
    { "name": "Universidad", "type": "ORG" },
    { "name": "10 de abril de 2026", "type": "DATE" },
    { "name": "auditorio principal", "type": "LOCATION" },
    { "name": "María López", "type": "PERSON" },
    { "name": "5 de abril", "type": "DATE" }
  ],
  "actions": [
    "Confirmar asistencia antes del 5 de abril",
    "Coordinar logística del evento con María López"
  ],
  "confidence": 0.86,
  "needs_clarification": false,
  "clarifying_questions": []
}
```

---

### Ejemplo B: Texto Ambiguo (SÍ requiere aclaración)

#### Request (curl)

```bash
curl -X POST http://127.0.0.1:8000/extract \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hay una reunión la próxima semana para revisar el proyecto. Necesitamos decidir el lugar y quién presentará.",
    "domain": "universidad"
  }'
```

#### Response

```json
{
  "summary": "Se menciona una reunión para revisar un proyecto la próxima semana, pero faltan detalles clave como fecha exacta, lugar y responsable de presentación.",
  "entities": [
    { "name": "la próxima semana", "type": "DATE" }
  ],
  "actions": [],
  "confidence": 0.42,
  "needs_clarification": true,
  "clarifying_questions": [
    "¿Cuál es la fecha y hora exacta de la reunión?",
    "¿Dónde será la reunión (lugar o enlace si es virtual)?",
    "¿Quién será la persona encargada de presentar?"
  ]
}
```

---

## 🧪 Tests Automáticos

Ejecutar el script de pruebas en PowerShell:

```powershell
.\smoke_test.ps1
```

El script:
- Inicia automáticamente la API en puerto 8010
- Ejecuta 2 casos de prueba (claro y ambiguo)
- Valida que `needs_clarification` sea correcto en cada caso
- Detiene el servidor al finalizar

---

## 🏗️ Arquitectura Técnica

### Componentes Principales

1. **`models.py`** - Definición de modelos Pydantic
   - `ExtractRequest`: Valida entrada (text, domain)
   - `Entity`: Estructura de entidades extraídas
   - `ExtractResponse`: Contrato de salida con validación completa

2. **`llm.py`** - Lógica de integración con LLM
   - Prompt estructurado con reglas explícitas (no inventar, necesidad de aclaración)
   - Soporta fallback heurístico si falla la API
   - Auto-detección de proveedor (OpenAI / Google Gemini)

3. **`main.py`** - Aplicación FastAPI
   - Endpoint POST /extract con `response_model` para validación
   - Manejo de errores robustos
   - Respuesta fallback en caso de excepción

### Validación de Respuesta

- **FastAPI `response_model`**: Valida automáticamente que la salida del LLM cumpla con `ExtractResponse`
- **Pydantic**: Valida tipos, rangos (confidence 0-1), campos requeridos
- **Filtrado de salida**: Si el LLM devuelve campos extra, se descartan

### Lógica de Aclaración

El sistema decide si necesita aclaración cuando:
- **Confianza baja** (< 0.5): Texto ambiguo o incompleto
- **Falta información contextual**: Nombres, fechas exactas, ubicaciones
- **Ambigüedad explícita**: "próxima semana", "algunos", "posiblemente"

Si `needs_clarification = true`:
- Se generan **mínimo 2 preguntas** clarificadoras
- Las preguntas son específicas al dominio y contexto

---

## 🔐 Variables de Entorno

```env
OPENAI_API_KEY=tu_api_key                    # OpenAI (requerida si se usa OpenAI)
GOOGLE_API_KEY=tu_api_key                    # Google Gemini (alternativa)
GEMINI_API_KEY=tu_api_key                    # Alias para GOOGLE_API_KEY
LLM_PROVIDER=openai                          # "openai", "google", o "auto" (por defecto)
LLM_MODEL=gpt-4o-mini                        # Modelo específico
```

---

## 📦 Dependencias

- `fastapi` - Framework web
- `uvicorn` - Servidor ASGI
- `pydantic` - Validación de datos
- `openai` - SDK de OpenAI (compatible con Gemini)
- `python-dotenv` - Manejo de variables de entorno

Ver `requirements.txt` para versiones exactas.

---

## 📄 Estructura del Proyecto

```
API-EXTRAC/
├── main.py                 # Aplicación FastAPI
├── models.py               # Modelos Pydantic
├── llm.py                  # Integración con LLM
├── smoke_test.ps1          # Tests automáticos (PowerShell)
├── requirements.txt        # Dependencias Python
├── .env.example            # Plantilla de configuración
├── .gitignore              # Exclusiones Git
└── README.md               # Este archivo
```

---

## 🐛 Solución de Problemas

### Error: "No se encontro ninguna API key valida"
- Verificar que `.env` existe y contiene `OPENAI_API_KEY`
- Ejecutar desde el directorio del proyecto

### El servidor no inicia
```bash
pip install -r requirements.txt --upgrade
```

### Tests no funcionan en Linux/Mac
- Los scripts PowerShell son específicos de Windows
- En Linux/Mac, usar `bash` o ejecutar manualmente:
```bash
uvicorn main:app --host 127.0.0.1 --port 8000 &
curl -X POST http://127.0.0.1:8000/extract ...
```

---

## 📝 Notas

- El sistema **nunca inventa información**: Si falta contexto, marca `needs_clarification = true`
- La **confianza** refleja qué tan seguros estamos de la extracción
- Las **preguntas clarificadoras** son concretas y actionables
- El **fallback heurístico** permite funcionar sin API si es necesario

---

**Autor**: Alfredo Chay  
**Última actualización**: Junio 2026
