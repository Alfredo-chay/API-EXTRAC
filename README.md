# API-EXTRAC

Proyecto pequeño para extraer APIs y probar integraciones con OpenAI.

Contenido principal:

- `llm.py` — Lógica relacionada con el modelo.
- `main.py` — Punto de entrada.
- `models.py` — Definiciones de modelos/estructuras.
- `smoke_test.ps1` — Script de PowerShell para pruebas rápidas.

Configuración:

1. Crea un archivo `.env` con tu clave de OpenAI (no subirlo al repo):

```
OPENAI_API_KEY=tu_api_key_aqui
```

2. Ejecuta el script de pruebas en PowerShell:

```powershell
./smoke_test.ps1
```

Notas de seguridad:

- El archivo `.env` no está incluido en el repositorio remoto. No subas claves a Git.

Commit/push:

Este `README.md` se añadirá y empujará al remoto.
