# Fuente de los diagramas BPMN

Los trece procesos se definen en `procesos.py` y todo lo demás se genera a partir de ese archivo.
Así los diagramas, las figuras y el documento no se desalinean.

| Archivo | Qué hace |
| --- | --- |
| `procesos.py` | Define cada proceso: objetivo, disparador, resultado, requisitos, notas, carriles, nodos y flujos. |
| `generar_bpmn.py` | Escribe un `.bpmn` (BPMN 2.0: modelo y diagrama) por proceso; calcula la distribución y traza los flujos. |
| `render.mjs` | Valida cada `.bpmn` con bpmn-moddle y genera su SVG y PNG con bpmn-js en Chromium. Falla si hay advertencias. |
| `generar_documento.py` | Escribe `bpmn-procesos-del-sistema.md` y la variante para impresión (figuras cortadas en partes). |
| `build_docx_bpmn.py` | Convierte la variante para impresión a Word (carta horizontal, portada, índice, tablas). |
| `pdf_con_indice.py` | Exporta el Word a PDF con LibreOffice, actualizando antes el índice. |
| `logo.png` | Logotipo de la portada (plantilla del TecNM). |

## Requisitos

- Python 3.11 o superior con `pillow` y `python-docx`.
- Node.js 20 o superior (`npm install` en esta carpeta) y Chromium o Chrome. Si no está en
  `/opt/pw-browsers/chromium`, indica la ruta en la variable `CHROMIUM_PATH`.
- pandoc 3 y LibreOffice (solo para el Word y el PDF).

## Regenerar

Desde esta carpeta:

```bash
python3 generar_bpmn.py ../procesos              # 1. archivos .bpmn
npm install && npm run figuras                    # 2. validación y figuras SVG/PNG
python3 generar_documento.py ../figuras salida    # 3. Markdown (y variante para impresión)
cp salida/bpmn-procesos-del-sistema.md ..
python3 build_docx_bpmn.py salida/doc-impresion.md logo.png ../bpmn-procesos-del-sistema.docx
python3 pdf_con_indice.py ../bpmn-procesos-del-sistema.docx ../bpmn-procesos-del-sistema.pdf
rm -rf salida
```

Revisa las figuras después de cambiar un proceso: el trazado automático evita cruzar nodos, pero
en procesos con muchos retornos conviene confirmar que las etiquetas quedan legibles.
