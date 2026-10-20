"""Genera el documento «BPMN de los procesos del sistema» v2.0 a partir de procesos.py.

Salidas (en <carpeta_salida>):
  bpmn-procesos-del-sistema.md     documento para el repositorio (figuras SVG completas)
  partes/P-xx-k.png                cortes de cada figura para impresión horizontal
  doc-impresion.md                 variante del Markdown con los cortes (entrada de pandoc)

Uso: python generar_documento.py <carpeta_figuras_png> <carpeta_salida>
"""
import math
import sys
from collections import OrderedDict
from pathlib import Path

from PIL import Image

from generar_bpmn import CAB_CARRIL, CAB_POOL, COL_W, MARGEN, POOL_X
from procesos import POOL, PROCESOS

FIG = Path(sys.argv[1])
OUT = Path(sys.argv[2])
(OUT / 'partes').mkdir(parents=True, exist_ok=True)

ESCALA = 2                 # las PNG se renderizaron con deviceScaleFactor 2
MAX_COLUMNAS = 9           # columnas por corte para que el texto siga legible en carta horizontal

FECHA = '19 de octubre de 2026'

SIMBOLOS = [
    ('Evento de inicio (círculo delgado)', 'Inicia el proceso. Con sobre: inicia al recibir un mensaje de otro proceso.'),
    ('Evento de fin (círculo grueso)', 'Termina el camino; su nombre indica el resultado.'),
    ('Tarea de usuario (icono de persona)', 'La realiza el tipo de usuario del carril, en la interfaz del sistema.'),
    ('Tarea de servicio (icono de engranes)', 'La ejecuta el sistema sin intervención de un usuario.'),
    ('Compuerta exclusiva (rombo vacío)', 'Toma un solo camino según la pregunta; cada salida va rotulada. Sin nombre, une caminos.'),
    ('Compuerta basada en eventos (rombo con pentágono)', 'Espera el primer evento que ocurra entre los que le siguen.'),
    ('Evento intermedio de mensaje (sobre)', 'Espera un aviso de otro proceso o de un usuario.'),
    ('Evento intermedio de temporizador (reloj)', 'Espera una fecha u hora.'),
    ('Evento de borde de temporizador', 'Interrumpe la tarea a la que está pegado cuando vence un plazo configurable.'),
    ('Carril', 'Tipo de usuario responsable (ERS §2.3) o el propio sistema.'),
]

CAMBIOS = [
    ('Procesos', 'P-01 a P-09.', 'P-01 a P-13: se agregan préstamo y oferta de cancha (P-10), cobros (P-11), venta de equipo (P-12) y control dual de permisos (P-13).'),
    ('Participantes', '«Administración», «Autoridad», «usuario autorizado», «por definir».', 'Los 12 tipos de usuario del ERS Rev. 0.4 (§2.3) como carriles, más el carril Sistema.'),
    ('P-03', 'Generación automática de la programación con restricciones duras y blandas.', 'Programación manual con validación de conflictos y aprobación del Presidente; la programación automática queda fuera del alcance (DEC-06, ERS §2.6).'),
    ('P-04', 'Estados SUSPENDIDO, CANCELADO, NO PROGRAMADO y RESUELTO ADMINISTRATIVAMENTE.', 'Seis estados: Programado, En curso, Finalizado, Suspendido, Reprogramado y Cancelado (ERS §4.3.1).'),
    ('P-05 y P-06', 'Resultado capturado y validado por un usuario autorizado; la cédula iniciaba el expediente.', 'Cédula capturada por el Capturista y aprobada por el árbitro; al vencer el plazo [DEMO] la aprueba la Comisión de Arbitraje. Al aprobarse, el resultado es oficial, se publica y las incidencias abren expedientes.'),
    ('Notación', 'Diagramas de imagen.', 'Archivos BPMN 2.0 (XML con diagrama) que se abren y editan en cualquier modelador compatible, más SVG y PNG.'),
]


def carriles_de(p):
    return [n for _, n in p['carriles']]


def cortes(p):
    """Divide la PNG del proceso en partes de hasta MAX_COLUMNAS columnas, repitiendo los nombres de carril."""
    img = Image.open(FIG / f"{p['archivo']}.png").convert('RGB')
    ancho, alto = img.size
    base = POOL_X + CAB_POOL + CAB_CARRIL + MARGEN          # x (SVG) donde empieza la columna 0
    ncol = round((ancho / ESCALA - CAB_POOL - CAB_CARRIL - 2 * MARGEN) / COL_W)
    partes = max(1, math.ceil(ncol / MAX_COLUMNAS))
    if partes == 1:
        destino = OUT / 'partes' / f"{p['archivo']}-1.png"
        img.save(destino)
        return [destino]
    por_parte = math.ceil(ncol / partes)
    cab = img.crop((0, 0, (CAB_POOL + CAB_CARRIL) * ESCALA, alto))
    rutas = []
    for k in range(partes):
        c0, c1 = k * por_parte, min(ncol, (k + 1) * por_parte)
        x0 = POOL_X + CAB_POOL + CAB_CARRIL if k == 0 else base + c0 * COL_W - 20
        x1 = POOL_X + ancho / ESCALA if c1 == ncol else base + c1 * COL_W - 20
        trozo = img.crop((int((x0 - POOL_X) * ESCALA), 0, int((x1 - POOL_X) * ESCALA), alto))
        hoja = Image.new('RGB', (cab.width + trozo.width, alto), 'white')
        hoja.paste(cab, (0, 0))
        hoja.paste(trozo, (cab.width, 0))
        destino = OUT / 'partes' / f"{p['archivo']}-{k + 1}.png"
        hoja.save(destino)
        rutas.append(destino)
    return rutas


def documento(impresion):
    L = []
    w = L.append
    if not impresion:
        w('# BPMN de los procesos del sistema')
        w('')
        w('**SIGLIM · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia**  ')
        w(f'Versión 2.0 · {FECHA} · Alineado con el [ERS Rev. 0.4](../ERS.md)')
        w('')
        w('> [!NOTE]')
        w('> Este documento reemplaza la versión 1.0 (6 de octubre de 2026), que se conserva en')
        w('> [`historico/`](historico/). Los diagramas son archivos BPMN 2.0 editables en')
        w('> [`procesos/`](procesos/); las figuras se generan a partir de ellos.')
        w('')
    w('## Control del documento')
    w('')
    w('| Versión | Fecha | Cambios |')
    w('| --- | --- | --- |')
    w('| 1.0 | 6 de octubre de 2026 | Procesos P-01 a P-09 del levantamiento inicial. |')
    w(f'| 2.0 | {FECHA} | Procesos P-01 a P-13 alineados con el ERS Rev. 0.4 y el registro de decisiones DEC-01 a DEC-44; archivos BPMN 2.0 editables. |')
    w('')
    w('## 1. Propósito y alcance')
    w('')
    w('Este documento modela en BPMN 2.0 los trece procesos de negocio que el ERS Rev. 0.4 resume en su')
    w('sección 4.2. Su objetivo es que el equipo, el profesor y la Liga revisen **quién hace cada paso,')
    w('en qué orden y qué decide el sistema** antes de diseñar la arquitectura, la base de datos y el')
    w('backlog. Los estados del partido, de la cédula, del registro y del expediente se detallan en las')
    w('máquinas de estado del ERS (§4.3); aquí aparecen solo los cambios de estado que mueven el flujo.')
    w('')
    w('Si un diagrama y el ERS no coinciden, **prevalece el ERS** y el diagrama se corrige.')
    w('')
    w('## 2. Referencias')
    w('')
    w('| ID | Documento |')
    w('| --- | --- |')
    w('| R1 | Especificación de requisitos de software SIGLIM, Rev. 0.4 (`docs/requisitos/ERS.md`). |')
    w('| R2 | Registro de decisiones DEC-01 a DEC-44 (`docs/requisitos/decisiones/registro-de-decisiones.md`). |')
    w('| R3 | OMG, *Business Process Model and Notation (BPMN)*, versión 2.0.2 (ISO/IEC 19510:2013). |')
    w('')
    w('## 3. Convenciones de modelado')
    w('')
    w(f'- Cada proceso es un **pool** («{POOL}») con un **carril** por tipo de usuario que participa y un')
    w('  carril **Sistema** para lo que SIGLIM ejecuta solo.')
    w('- Las tareas se nombran con verbo en infinitivo y objeto («Revisar cédula»). Toda compuerta')
    w('  exclusiva lleva una pregunta y cada salida su respuesta.')
    w('- Los plazos y valores marcados **[DEMO]** en el ERS (por ejemplo, las 48 horas para aprobar la')
    w('  cédula) son configuración de la temporada, no constantes del sistema.')
    w('- Los procesos se conectan por eventos de mensaje (por ejemplo, P-05 abre expedientes que inician')
    w('  P-06). La referencia «(P-xx)» en un nombre indica el proceso que produce o recibe el evento.')
    w('- No se modelan funciones fuera del alcance (ERS §2.6): programación automática, pasarela de pago')
    w('  real, avisos por WhatsApp o SMS, entre otras.')
    w('')
    w('### 3.1 Simbología')
    w('')
    w('| Símbolo | Significado |')
    w('| --- | --- |')
    for s, d in SIMBOLOS:
        w(f'| {s} | {d} |')
    w('')
    w('## 4. Catálogo de procesos')
    w('')
    w('| ID | Proceso | Disparador | Resultado |')
    w('| --- | --- | --- | --- |')
    for p in PROCESOS:
        w(f"| {p['id']} | {p['nombre']} | {p['disparador']} | {p['salida']} |")
    w('')
    w('### 4.1 Participación por carril')
    w('')
    part = OrderedDict()
    for p in PROCESOS:
        for n in carriles_de(p):
            part.setdefault(n, []).append(p['id'])
    w('| Carril | Procesos |')
    w('| --- | --- |')
    for n, v in part.items():
        w(f"| {n} | {', '.join(v)} |")
    w('')
    w('Los tipos de usuario Jugador (o su tutor) y Usuario público no tienen carril: consultan la')
    w('información que estos procesos producen (perfil propio y portal) y no deciden ningún paso.')
    w('')
    w('## 5. Procesos')
    for k, p in enumerate(PROCESOS, 1):
        w('')
        w(f"### 5.{k} {p['id']} {p['nombre']}")
        w('')
        if impresion:
            partes = cortes(p)
            for j, ruta in enumerate(partes, 1):
                w(f'![]({ruta})')
                w('')
                sufijo = f' (parte {j} de {len(partes)})' if len(partes) > 1 else ''
                w(f"Figura {k}{sufijo}. {p['id']} {p['nombre']}.")
                w('')
        else:
            w(f"![{p['id']} {p['nombre']}](figuras/{p['archivo']}.svg)")
            w('')
            w(f"*Figura {k}. {p['id']} {p['nombre']}.*")
            w('')
        w('| Elemento | Contenido |')
        w('| --- | --- |')
        w(f"| Objetivo | {p['objetivo']} |")
        w(f"| Disparador | {p['disparador']} |")
        w(f"| Resultado | {p['salida']} |")
        w(f"| Carriles | {', '.join(carriles_de(p))} |")
        w(f"| Requisitos | {p['requisitos']} |")
        if not impresion:
            w(f"| Archivo | [`procesos/{p['archivo']}.bpmn`](procesos/{p['archivo']}.bpmn) |")
        w('')
        w('**Notas de modelado**')
        w('')
        for n in p['notas']:
            w(f'- {n}')
    w('')
    w('## 6. Cambios respecto a la versión 1.0')
    w('')
    w('| Aspecto | Versión 1.0 | Versión 2.0 |')
    w('| --- | --- | --- |')
    for a, b, c in CAMBIOS:
        w(f'| {a} | {b} | {c} |')
    w('')
    w('## 7. Archivos y regeneración')
    w('')
    w('| Carpeta | Contenido |')
    w('| --- | --- |')
    w('| `procesos/` | Un archivo `.bpmn` (BPMN 2.0 con diagrama) por proceso; se abre en bpmn.io, Camunda Modeler u otro modelador. |')
    w('| `figuras/` | SVG y PNG de cada proceso, renderizados con bpmn-js. |')
    w('| `fuente/` | `procesos.py` (definición de los procesos), `generar_bpmn.py` (XML y distribución), `render.mjs` (validación y figuras) y `generar_documento.py` (este documento). |')
    w('')
    w('Para modificar un proceso se edita `fuente/procesos.py` y se regeneran los archivos (ver')
    w('`fuente/README.md`). Editar un `.bpmn` a mano en un modelador también es válido, pero entonces')
    w('`procesos.py` deja de ser la fuente y debe actualizarse para no perder el cambio.')
    w('')
    return '\n'.join(L)


(OUT / 'bpmn-procesos-del-sistema.md').write_text(documento(False), encoding='utf-8')
(OUT / 'doc-impresion.md').write_text(documento(True), encoding='utf-8')
print('ok')
