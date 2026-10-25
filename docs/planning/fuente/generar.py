"""Genera docs/planning/backlog-siglim.csv y docs/planning/sprint-plan.md desde datos.py y valida
la consistencia de ambos.

Uso (desde la raíz del repositorio):  python3 docs/planning/fuente/generar.py
"""
import csv
import io
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from datos import (BACKLOG_B, EPICAS, EXCLUIDOS, HORAS_B, HORAS_POR_SP, ITEMS, REPLAN, REPLAN_FECHA,  # noqa: E402
                   RESPONSABLE_S2, SPRINTS)

RAIZ = Path(__file__).resolve().parents[3]
CSV_SALIDA = RAIZ / 'docs/planning/backlog-siglim.csv'
MD_SALIDA = RAIZ / 'docs/planning/sprint-plan.md'
ERS = RAIZ / 'docs/requisitos/ERS.md'
PANTALLAS = RAIZ / 'docs/diseno-ui/pantallas'

TIPO_JIRA = {'Épica': 'Epic', 'Historia': 'Story', 'Tarea': 'Task', 'Subtarea': 'Subtask'}
MODULO = {e[0]: e[1] for e in EPICAS}
NOMBRE_EPICA = {e[0]: e[2] for e in EPICAS}


def etiqueta_modulo(epica):
    return MODULO[epica].lower().replace('-', '')


def etiqueta_sprint(s):
    return f'sprint-{s}' if s else 'backlog'


# ---------------------------------------------------------------------------
# 1. Construcción de filas con identificadores internos consecutivos
# ---------------------------------------------------------------------------
filas = []          # dicts con todos los datos
id_de = {}          # clave lógica -> Issue ID


def agregar(**f):
    f['id'] = len(filas) + 1
    filas.append(f)
    return f['id']


for cod, mod, nombre, desc, refs in EPICAS:
    id_de[cod] = agregar(clave=cod, tipo='Épica', titulo=f'[{cod}] {mod} {nombre}', padre=None,
                         prio=None, sp=None, horas=None, sprint=None,
                         labels=['siglim-v4', etiqueta_modulo(cod)],
                         desc=f'{desc}\n\nh3. Trazabilidad\n{refs}\n\nLas épicas no se planifican en un sprint: '
                              f'se planifican sus historias y tareas.', fuente=None)


def descripcion_item(it):
    p = []
    if it['tipo'] == 'Historia':
        p.append(f"*Como* {it['como']}, *quiero* {it['quiero']}, *para* {it['para']}.")
        p.append('')
    p.append(it['desc'])
    if it.get('ca'):
        p += ['', 'h3. Criterios de aceptación'] + [f'# {c}' for c in it['ca']]
    if it.get('resultado'):
        p += ['', 'h3. Resultado esperado', it['resultado']]
    p += ['', 'h3. Trazabilidad', 'Requisitos: ' + ', '.join(it['rf'])]
    if it['ui']:
        p.append('Pantallas aprobadas: ' + ', '.join(it['ui']) + ' (docs/diseno-ui/pantallas)')
    if it['api']:
        p.append('API: ' + '; '.join(it['api']) + ' (docs/arquitectura/convenciones-api.md)')
    p += ['', 'h3. Dependencias', ', '.join(it['dep']) if it['dep'] else 'Ninguna']
    p += ['', 'h3. Planificación',
          f"Sprint: {it['sprint'] or 'sin asignar (núcleo no comprometido)'} · MoSCoW: {it['moscow']} · "
          f"Prioridad: {it['prio']} · {it['sp']} SP"]
    p += ['', 'h3. Terminado', 'Cumple los criterios y la Definición de Terminado de CONTRIBUTING.md §4: compila, '
          'pruebas de la regla y de su error (incluidas 401/403/404), auditoría de operaciones críticas, '
          'documentación actualizada y PR aprobado.']
    return '\n'.join(p)


for it in ITEMS:
    id_de[it['k']] = agregar(clave=it['k'], tipo=it['tipo'], titulo=f"[{it['k']}] {it['titulo']}",
                             padre=it['epica'], prio=it['prio'], sp=it['sp'], horas=None, sprint=it['sprint'],
                             labels=['siglim-v4', etiqueta_sprint(it['sprint']),
                                     f"moscow-{it['moscow'].lower()}", etiqueta_modulo(it['epica'])],
                             desc=descripcion_item(it), fuente=it)

for k, ep, titulo, rf, ui, sp, nota in BACKLOG_B:
    d = [f'Historia de entrega B (backlog priorizado, ERS). Se desglosa en subtareas y criterios de '
         f'aceptación detallados cuando entre a un sprint (AGENTS.md §3.1).',
         '', 'h3. Trazabilidad', 'Requisitos: ' + ', '.join(rf)]
    if ui:
        d.append('Pantallas aprobadas: ' + ', '.join(ui))
    if nota:
        d += ['', 'h3. Nota', nota]
    d += ['', 'h3. Planificación', f'Sin sprint · MoSCoW: Could · Prioridad: Low · {sp} SP (estimación gruesa)']
    id_de[k] = agregar(clave=k, tipo='Historia', titulo=f'[{k}] {titulo}', padre=ep, prio='Low', sp=sp,
                       horas=None, sprint=None,
                       labels=['siglim-v4', 'backlog', 'entrega-b', etiqueta_modulo(ep)],
                       desc='\n'.join(d), fuente=dict(k=k, rf=rf, ui=ui, sp=sp, moscow='Could', epica=ep,
                                                       tipo='Historia', titulo=titulo, sprint=None, dep=[]))

for it in ITEMS:
    for n, s in enumerate(it['sub'], 1):
        clave = f"{it['k']}.{n}"
        id_de[clave] = agregar(clave=clave, tipo='Subtarea', titulo=f"[{clave}] {s['titulo']}", padre=it['k'],
                               prio=None, sp=None, horas=s['horas'], sprint=it['sprint'],
                               labels=['siglim-v4', etiqueta_sprint(it['sprint']), s['capa']],
                               desc=f"Parte de {it['k']}: {it['titulo']}.\n\nh3. Terminado cuando\n{s['hecho']}\n\n"
                                    f"h3. Estimación\n{s['horas']:g} h · capa: {s['capa']}",
                               fuente=s)

# ---------------------------------------------------------------------------
# 2. Validaciones
# ---------------------------------------------------------------------------
errores = []
ids = [f['id'] for f in filas]
if ids != list(range(1, len(filas) + 1)):
    errores.append('Los identificadores no son consecutivos desde 1.')
claves = Counter(f['clave'] for f in filas)
errores += [f'Clave duplicada {c}' for c, n in claves.items() if n > 1]
por_id = {f['id']: f for f in filas}
NIVEL = {'Épica': 1, 'Historia': 0, 'Tarea': 0, 'Subtarea': -1}
for f in filas:
    if f['tipo'] == 'Épica':
        if f['padre']:
            errores.append(f"{f['clave']}: una épica no tiene padre")
        continue
    if f['padre'] not in id_de:
        errores.append(f"{f['clave']}: padre inexistente {f['padre']}")
        continue
    p = por_id[id_de[f['padre']]]
    if NIVEL[p['tipo']] != NIVEL[f['tipo']] + 1:
        errores.append(f"{f['clave']}: jerarquía inválida {p['tipo']} → {f['tipo']}")
    if p['id'] >= f['id']:
        errores.append(f"{f['clave']}: el padre debe ir antes en el archivo")
    if f['tipo'] == 'Subtarea' and p['sprint'] != f['sprint']:
        errores.append(f"{f['clave']}: sprint distinto al de su padre")
    if len(f['desc']) < 60:
        errores.append(f"{f['clave']}: descripción insuficiente")
for it in ITEMS:
    if not it['sub']:
        errores.append(f"{it['k']}: sin subtareas")
    h = sum(s['horas'] for s in it['sub'])
    if abs(h - it['sp'] * HORAS_POR_SP) > 1.5:
        errores.append(f"{it['k']}: {h} h no corresponde a {it['sp']} SP")
    for d in it['dep']:
        if d not in id_de:
            errores.append(f"{it['k']}: dependencia inexistente {d}")
        else:
            dep = por_id[id_de[d]]['fuente']
            if it['sprint'] and (dep.get('sprint') is None or dep['sprint'] > it['sprint']):
                errores.append(f"{it['k']}: depende de {d}, planificada después o sin sprint")
    if it['tipo'] == 'Historia' and len(it.get('ca', [])) < 2:
        errores.append(f"{it['k']}: criterios de aceptación insuficientes")
    if it['moscow'] == 'Must' and not it['sprint']:
        errores.append(f"{it['k']}: Must sin sprint")
    for u in it['ui']:
        if u != 'F-36' and not any(PANTALLAS.glob(f'{u}-*')):
            errores.append(f"{it['k']}: pantalla {u} no existe")
for k, ep, titulo, rf, ui, sp, nota in BACKLOG_B:
    for u in ui:
        if not any(PANTALLAS.glob(f'{u}-*')):
            errores.append(f'{k}: pantalla {u} no existe')

# Replanificación (DEC-50): cada Should y cada B, exactamente una vez; dependencias en el mismo sprint o antes.
por_k = {it['k']: it for it in ITEMS}
sprint_replan = {}
for s_, claves_ in REPLAN.items():
    if s_ not in SPRINTS:
        errores.append(f'Replanificación: sprint {s_} inexistente')
    for c in claves_:
        if c in sprint_replan:
            errores.append(f'Replanificación: {c} aparece dos veces')
        sprint_replan[c] = s_
_sin_sprint = {it['k'] for it in ITEMS if not it['sprint']} | {b[0] for b in BACKLOG_B}
for c in sorted(_sin_sprint - set(sprint_replan)):
    errores.append(f'Replanificación: {c} no tiene sprint')
for c in sorted(set(sprint_replan) - _sin_sprint):
    errores.append(f'Replanificación: {c} no es Should ni B')
for c in HORAS_B:
    if sprint_replan.get(c) != 2:
        errores.append(f'Replanificación: horas de {c} sin estar en el Sprint 2')
for c in RESPONSABLE_S2:
    if c not in _sin_sprint and (por_k.get(c) or {}).get('sprint') != 2:
        errores.append(f'Replanificación: responsable de {c} sin estar en el Sprint 2')


def sprint_vigente(clave):
    it = por_k.get(clave)
    return (it['sprint'] if it and it['sprint'] else None) or sprint_replan.get(clave)


for it in ITEMS:
    for d in it['dep']:
        if d in por_k and sprint_vigente(d) and sprint_vigente(it['k']) and \
                sprint_vigente(d) > sprint_vigente(it['k']):
            errores.append(f"Replanificación: {it['k']} (S{sprint_vigente(it['k'])}) depende de {d} "
                           f"(S{sprint_vigente(d)})")

# Capacidad por sprint
sp_sprint = defaultdict(float)
h_sprint = defaultdict(float)
for it in ITEMS:
    if it['sprint']:
        sp_sprint[it['sprint']] += it['sp']
        h_sprint[it['sprint']] += sum(s['horas'] for s in it['sub'])
for s, cfg in SPRINTS.items():
    if sp_sprint[s] > cfg['capacidad_sp']:
        errores.append(f'Sprint {s}: {sp_sprint[s]} SP supera la capacidad {cfg["capacidad_sp"]}')
    if h_sprint[s] > cfg['capacidad_h']:
        errores.append(f'Sprint {s}: {h_sprint[s]} h supera la capacidad {cfg["capacidad_h"]} h')

# Cobertura de requisitos funcionales del ERS
ers = ERS.read_text(encoding='utf-8')
seccion = ers[ers.index('### 3.2 Requisitos funcionales'):ers.index('#### 3.2.15')]
entrega_rf = {}
for linea in seccion.split('\n'):
    m = re.match(r'\| (RF-\d{3}) \|', linea)
    if m:
        entrega_rf[m.group(1)] = linea.rstrip(' |').split('|')[-1].strip()
cubiertos = defaultdict(list)
for it in ITEMS:
    for r in it['rf']:
        cubiertos[r].append(it['k'])
for k, ep, titulo, rf, ui, sp, nota in BACKLOG_B:
    for r in rf:
        cubiertos[r].append(k)
faltan_n = sorted(r for r, e in entrega_rf.items() if e == 'N' and r not in cubiertos)
faltan_b = sorted(r for r, e in entrega_rf.items() if e == 'B' and r not in cubiertos)
if faltan_n:
    errores.append('RF N sin cubrir: ' + ', '.join(faltan_n))
if faltan_b:
    errores.append('RF B sin cubrir: ' + ', '.join(faltan_b))
f_en_backlog = sorted(r for r in cubiertos if entrega_rf.get(r) == 'F')
if f_en_backlog:
    errores.append('RF F incluidos: ' + ', '.join(f_en_backlog))
desconocidos = sorted(r for r in cubiertos if r.startswith('RF-') and r not in entrega_rf)
if desconocidos:
    errores.append('RF inexistentes en el ERS: ' + ', '.join(desconocidos))

# ---------------------------------------------------------------------------
# 3. CSV para el importador de Jira (UTF-8, coma, comillas dobles)
# ---------------------------------------------------------------------------
MAX_LABELS = max(len(f['labels']) for f in filas)
cabecera = (['Issue ID', 'Parent', 'Issue Type', 'Summary', 'Description', 'Priority', 'Status',
             'Story point estimate', 'Original Estimate'] + ['Labels'] * MAX_LABELS)
buf = io.StringIO()
w = csv.writer(buf, quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
w.writerow(cabecera)
for f in filas:
    w.writerow([f['id'], id_de[f['padre']] if f['padre'] else '', TIPO_JIRA[f['tipo']], f['titulo'], f['desc'],
                f['prio'] or '', 'Por hacer', f['sp'] if f['sp'] is not None else '',
                int(f['horas'] * 3600) if f['horas'] else ''] +
               f['labels'] + [''] * (MAX_LABELS - len(f['labels'])))
CSV_SALIDA.write_text(buf.getvalue(), encoding='utf-8')

# Relectura del CSV para comprobar que el formato se conserva
leidas = list(csv.reader(io.StringIO(CSV_SALIDA.read_text(encoding='utf-8'))))
if len(leidas) - 1 != len(filas) or any(len(r) != len(cabecera) for r in leidas):
    errores.append('El CSV releído no coincide en filas o columnas.')
for r in leidas[1:]:
    if r[1] and int(r[1]) >= int(r[0]):
        errores.append(f'CSV: el padre de {r[0]} no aparece antes')

# ---------------------------------------------------------------------------
# 4. Plan de sprints en Markdown
# ---------------------------------------------------------------------------
cuenta = Counter(f['tipo'] for f in filas)
n_b = len(BACKLOG_B)
items_sprint = {s: [it for it in ITEMS if it['sprint'] == s] for s in SPRINTS}
should = [it for it in ITEMS if not it['sprint']]
sp_should = sum(it['sp'] for it in should)
sp_b = sum(b[5] for b in BACKLOG_B)
sp_must = sum(sp_sprint.values())


def lista_subtareas(it):
    out = []
    for n, s in enumerate(it['sub'], 1):
        out.append(f"    - **{it['k']}.{n}** {s['titulo']} — {s['horas']:g} h · `{s['capa']}`  \n"
                   f"      Terminado cuando: {s['hecho']}")
    return out


def bloque_item(it):
    o = [f"- **{it['k']} · {it['tipo']}** — {it['titulo']} · **{it['sp']} SP** · {it['prio']} · "
         f"épica {it['epica']}"]
    if it['tipo'] == 'Historia':
        o.append(f"  - *Como* {it['como']}, *quiero* {it['quiero']}, *para* {it['para']}.")
    o.append(f"  - Requisitos: {', '.join(it['rf'])}")
    if it['ui']:
        o.append(f"  - Pantallas: {', '.join(it['ui'])}")
    o.append(f"  - Depende de: {', '.join(it['dep']) if it['dep'] else '—'}")
    if it.get('ca'):
        o.append('  - Criterios de aceptación:')
        o += [f'    {i}. {c}' for i, c in enumerate(it['ca'], 1)]
    if it.get('resultado'):
        o.append(f"  - Resultado esperado: {it['resultado']}")
    o.append(f"  - Subtareas ({sum(s['horas'] for s in it['sub']):g} h):")
    o += lista_subtareas(it)
    return o


md = []
A = md.append
A('# Plan de sprints — SIGLIM (backlog v4)')
A('')
A('**SIGLIM · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia**  ')
A(f'Versión 4.1 · {REPLAN_FECHA} (replanificación DEC-50; línea base 4.0 del 20 de octubre) · Alineado con el [ERS Rev. 0.4.1](../requisitos/ERS.md), la '
  '[arquitectura v2.1](../arquitectura/arquitectura-y-diseno-jerarquico.md), las '
  '[convenciones de API v2.0](../arquitectura/convenciones-api.md) y las '
  '[pantallas aprobadas](../diseno-ui/pantallas/README.md)')
A('')
A('> [!NOTE]')
A('> Este archivo y [`backlog-siglim.csv`](backlog-siglim.csv) se generan juntos con '
  '[`fuente/generar.py`](fuente/generar.py) a partir de [`fuente/datos.py`](fuente/datos.py). Para cambiar el '
  'backlog, edita `datos.py` y vuelve a generar: así el plan y el CSV no se desalinean. Reemplaza al backlog v3 '
  'y a los 81 issues anteriores de Jira (DEC-44, DEC-47).')
A('')
# --- Replanificación vigente (DEC-50) ---
b_por_k = {b[0]: b for b in BACKLOG_B}


def datos_replan(c):
    """(tipo, título, SP, horas) de un elemento Should o B."""
    if c in por_k:
        it = por_k[c]
        return it['tipo'], it['titulo'], it['sp'], sum(x['horas'] for x in it['sub'])
    b = b_por_k[c]
    return 'Historia B', b[2], b[5], HORAS_B.get(c, b[5] * HORAS_POR_SP)


A('## Replanificación vigente (DEC-50)')
A('')
A('> [!IMPORTANT]')
A(f'> El {REPLAN_FECHA} el equipo asignó a los Sprints 2 a 4 todo el núcleo Should y todo lo B '
  '([DEC-50](../requisitos/decisiones/registro-de-decisiones.md)), adelantando la mayor parte al Sprint 2. '
  'Las secciones 1 a 9 conservan la **línea base** que generó el CSV importado; esta sección manda sobre ellas. '
  'Las fechas, los responsables y el estado de cada subtarea viven en Jira (etiqueta `sprint-N`).')
A('')
A('| Sprint | Línea base (Must) | Should agregado | B agregado | Total | Capacidad calculada |')
A('| --- | --- | --- | --- | --- | --- |')
for s_, c_ in SPRINTS.items():
    sh = [datos_replan(c) for c in REPLAN.get(s_, []) if c in por_k]
    bb = [datos_replan(c) for c in REPLAN.get(s_, []) if c in b_por_k]
    tot_sp = sp_sprint[s_] + sum(x[2] for x in sh) + sum(x[2] for x in bb)
    tot_h = h_sprint[s_] + sum(x[3] for x in sh) + sum(x[3] for x in bb)
    A(f"| {s_} | {sp_sprint[s_]:g} SP · {h_sprint[s_]:g} h | {sum(x[2] for x in sh)} SP · {sum(x[3] for x in sh):g} h "
      f"| {sum(x[2] for x in bb)} SP · {sum(x[3] for x in bb):g} h | **{tot_sp:g} SP · {tot_h:g} h** "
      f"| {c_['capacidad_sp']} SP · {c_['capacidad_h']} h |")
A('')
A('Las horas de lo B en los Sprints 3 y 4 son estimación gruesa (SP × 3): sus subtareas se crean al refinarlas.')
A('')
A('### Sprint 2 replanificado')
A('')
A('| Clave | Tipo | Elemento | SP | Horas | Responsable |')
A('| --- | --- | --- | --- | --- | --- |')
for it in items_sprint[2]:
    A(f"| {it['k']} | {it['tipo']} (Must) | {it['titulo']} | {it['sp']} | "
      f"{sum(x['horas'] for x in it['sub']):g} | {RESPONSABLE_S2.get(it['k'], '—')} |")
for c in REPLAN[2]:
    t, ti, sp_, h_ = datos_replan(c)
    A(f"| {c} | {t if c in b_por_k else t + ' (Should)'} | {ti} | {sp_} | {h_:g} | {RESPONSABLE_S2.get(c, '—')} |")
A('')
A('**Reglas de trabajo del Sprint 2**')
A('')
A('1. **Orden:** Must → Should → B. Si en la revisión de mitad de sprint (1 de noviembre) los Must van atrasados, '
  'se retiran primero las B y después las Should, y regresan al backlog con su etiqueta.')
A('2. **Ruta crítica:** H-02 (autorización y auditoría, 26–29 oct) → H-04.1 (temporadas, 30–31 oct) → H-05.1 '
  '(categorías, 1–2 nov) → H-06.1 (clubes y equipos, 3 nov). Todo lo que usa clubes (H-22, H-29, B-04, B-05, '
  'B-13) empieza después de H-06.1; lo que extiende una pantalla (B-02 en F-10, B-04 y H-22 en F-15, B-11 y '
  'B-12 en F-21, H-31 y B-31 en F-33) empieza después de que esa pantalla existe.')
A('3. **Pruebas cruzadas:** cada prueba de aceptación la hace un integrante distinto de quien implementó.')
A('4. **Capacidad:** la carga supera la capacidad calculada con la velocidad del Sprint 1 (9 SP); es una '
  'decisión consciente del equipo (DEC-50) que se revisa en la retrospectiva con la velocidad real.')
A('')
for s_ in (3, 4):
    A(f'### Agregado al Sprint {s_}')
    A('')
    A('| Clave | Elemento | SP |')
    A('| --- | --- | --- |')
    for c in REPLAN[s_]:
        t, ti, sp_, h_ = datos_replan(c)
        A(f"| {c} | {ti}{' (Should)' if c in por_k else ''} | {sp_} |")
    A('')
A('## 1. Resumen y supuestos')
A('')
A('| Concepto | Valor |')
A('| --- | --- |')
A(f"| Elementos | {cuenta['Épica']} épicas · {cuenta['Historia']} historias ({cuenta['Historia'] - n_b} del núcleo y "
  f"{n_b} de entrega B) · {cuenta['Tarea']} tareas · {cuenta['Subtarea']} subtareas · **{len(filas)} filas** |")
A(f'| Comprometido en sprints (Must) | {sp_must:g} SP · {sum(h_sprint.values()):g} h |')
A(f'| Núcleo no comprometido (Should, sin sprint en la línea base) | {len(should)} historias · {sp_should} SP · asignadas por DEC-50 |')
A(f'| Backlog B (Could, sin sprint en la línea base) | {n_b} historias · {sp_b} SP · asignadas por DEC-50 |')
A('| Equipo | 3 integrantes; 10 h por persona por semana (supuesto aprobado el 20 oct 2026) |')
A(f'| Equivalencia | 1 SP ≈ {HORAS_POR_SP} h del equipo; solo para comprobar capacidad. Se recalibra con la '
  'velocidad real del Sprint 2. |')
A('| Jerarquía en Jira | Épica → Historia → Subtarea; y Épica → Tarea → Subtarea para trabajo técnico sin usuario '
  'final. Jira *team-managed* no permite una Tarea hija de una Historia (DEC-47). |')
A('')
A('Supuestos y reglas:')
A('')
A('- **Prioridad MoSCoW dentro del núcleo (DEC-47).** El ERS llama «núcleo comprometido» a 83 RF y 28 '
  'pantallas, que no caben en unas 6.5 semanas con 3 personas. Se compromete el **flujo central de punta a '
  'punta** (Must); el resto del núcleo (Should) queda listo para entrar en cuanto haya capacidad, y lo B queda '
  'como backlog.')
A('- **Nada pendiente se implementa como aprobado.** Las historias usan valores configurables, [DEMO] o '
  '[PROPUESTA] donde el ERS lo indica y no implementan las diferencias D-01 a D-12 de las pantallas.')
A('- **No entra trabajo ya hecho**: ERS, BPMN, arquitectura, BD, API y diseño. Sí entra lo que falta fuera del '
  'repositorio: aplicar la migración en Supabase (T-01) y crear la cuenta y el bucket de AWS (T-04).')
A('- **La demostración es local** con el proyecto Supabase de desarrollo mientras PEN-036 y PEN-037 sigan '
  'abiertos.')
A('')
A('Excluido de la planificación:')
A('')
A('| Elemento | Referencia | Motivo |')
A('| --- | --- | --- |')
for e in EXCLUIDOS:
    A(f'| {e[0]} | {e[1]} | {e[2]} |')
A('')
A('## 2. Sprints: duración, objetivo y capacidad')
A('')
A('| Sprint | Fechas | Objetivo | Capacidad | Comprometido |')
A('| --- | --- | --- | --- | --- |')
for s, c in SPRINTS.items():
    A(f"| {s} | {c['inicio']} → {c['fin']} ({c['semanas']} semanas) | {c['objetivo']} | {c['capacidad_h']} h · "
      f"{c['capacidad_sp']} SP | {sp_sprint[s]:g} SP · {h_sprint[s]:g} h |")
A('')
A('**Por qué sprints de dos semanas.** El Sprint 1 ya está fijado en dos semanas y DEC-08 fija 8 semanas en '
  '4 sprints. Mantener 2 semanas en los Sprints 2 a 4 conserva una velocidad comparable para recalibrar. Con 1 '
  'semana, historias verticales como H-12 o H-16 (5 SP, backend + pantalla + pruebas) no cerrarían dentro del '
  'sprint. Con 3 semanas solo quedarían dos revisiones y el riesgo del flujo de cédula se descubriría tarde. Los '
  'días feriados (2 y 16 de noviembre) se descuentan de la capacidad, no de la duración.')
A('')
for s, c in SPRINTS.items():
    A(f'- **Sprint {s}:** {c["nota"]}')
A('')
A('## 3. Épicas')
A('')
A('| Épica | Módulo | Nombre | SP en sprints | SP sin sprint (Should + B) |')
A('| --- | --- | --- | --- | --- |')
for cod, mod, nombre, desc, refs in EPICAS:
    a = sum(it['sp'] for it in ITEMS if it['epica'] == cod and it['sprint'])
    b = sum(it['sp'] for it in ITEMS if it['epica'] == cod and not it['sprint']) + \
        sum(x[5] for x in BACKLOG_B if x[1] == cod)
    A(f'| {cod} | {mod} | {nombre} | {a:g} | {b:g} |')
A('')
A('## 4. Contenido de cada sprint')
A('')
A('Cada elemento lista sus requisitos, pantallas, dependencias, criterios de aceptación y subtareas con su '
  'condición de terminado. Las claves (H-01, T-01, H-01.1…) aparecen al inicio del resumen en Jira.')
A('')
for s, c in SPRINTS.items():
    A(f'### Sprint {s} · {c["inicio"]} → {c["fin"]}')
    A('')
    A(f'**Objetivo.** {c["objetivo"]}')
    A('')
    A(f'**Carga.** {sp_sprint[s]:g} SP · {h_sprint[s]:g} h de {c["capacidad_h"]} h disponibles.')
    A('')
    for ep in dict.fromkeys(it['epica'] for it in items_sprint[s]):
        A(f'#### {ep} · {NOMBRE_EPICA[ep]}')
        A('')
        for it in items_sprint[s]:
            if it['epica'] == ep:
                md.extend(bloque_item(it))
        A('')
    A('**Entregable demostrable.**')
    A('')
    demo = {
        1: 'Iniciar sesión como Administrador general y como un segundo rol de prueba; cada uno ve en el panel '
           'solo sus módulos. `./mvnw verify` y la verificación del frontend en verde; la migración aplicada en '
           'Supabase.',
        2: 'Con cuentas de distintos roles: crear y activar una temporada con categorías, grupos y parámetros; '
           'registrar clubes, equipos y canchas con un bloqueo; mostrar un 403 sin permiso, un 404 fuera de '
           'ámbito y el registro de auditoría de cada operación.',
        3: 'Una Directiva afilia su club, registra a un menor con tutor y consentimiento, carga documentos que el '
           'Secretario valida; el Programador arma una jornada, ve rechazados un choque de cancha y uno de '
           'equipo con su explicación, la envía y el Presidente la publica.',
        4: 'Recorrido completo: designar árbitros, iniciar el partido, capturar la cédula (incluida una '
           'alineación rechazada por elegibilidad), validarla como árbitro, ver la tabla recalculada y el '
           'resultado en el portal público desde un teléfono.',
    }[s]
    A(demo)
    A('')
    A('**Incremento terminado cuando:** todas las historias del sprint cumplen sus criterios y la Definición de '
      'Terminado, el recorrido demostrable funciona en `main` con la migración vigente y no quedan defectos '
      'críticos abiertos.')
    A('')
A('## 5. Núcleo no comprometido (Should)')
A('')
A(f'{len(should)} historias, {sp_should} SP, con subtareas listas. Entran al sprint en que haya capacidad, en este '
  'orden sugerido: disciplina (H-26, H-27, H-28), tesorería (H-29, H-30, H-31), avisos (H-25) y el resto.')
A('')
A('El sprint vigente de cada historia es el de la replanificación (DEC-50), indicado en su primera línea.')
A('')
for it in should:
    b_ = bloque_item(it)
    b_[0] += f" · **Sprint {sprint_replan[it['k']]} (DEC-50)**"
    md.extend(b_)
A('')
A('## 6. Backlog B')
A('')
A('| Clave | Épica | Historia | Requisitos | SP | Sprint (DEC-50) | Nota |')
A('| --- | --- | --- | --- | --- | --- | --- |')
for k, ep, titulo, rf, ui, sp, nota in BACKLOG_B:
    A(f"| {k} | {ep} | {titulo} | {', '.join(rf)} | {sp} | {sprint_replan[k]} | {nota or '—'} |")
A('')
A('## 7. Dependencias críticas')
A('')
A('```mermaid')
A('flowchart LR')
for it in ITEMS:
    if it['sprint']:
        A(f"    {it['k'].replace('-', '')}[\"{it['k']} S{it['sprint']}\"]")
for it in ITEMS:
    if it['sprint']:
        for d in it['dep']:
            A(f"    {d.replace('-', '')} --> {it['k'].replace('-', '')}")
A('```')
A('')
A('La ruta crítica es T-01 → T-02 → H-01 → H-02 → H-05 → H-06 → H-08 → H-09 → H-10 → H-16 → H-17 → H-18 → H-19 → T-05. Un retraso en '
  'H-12 o H-16 (5 SP cada una) recorre el resto del plan: si al cierre de un sprint no están terminadas, se '
  'pasan al siguiente antes que cualquier otra historia y se mueve fuera la última Must de menor valor.')
A('')
A('## 8. Criterios de aceptación y Definición de Terminado')
A('')
A('- Cada historia trae sus criterios de aceptación verificables en la descripción del issue (Dado / cuando / '
  'entonces).')
A('- Cada subtarea dice cuándo está terminada.')
A('- **Definición de Terminado** (CONTRIBUTING.md §4): cumple los criterios y el ERS §3.4.3; compila '
  '(`./mvnw verify`, `npm run lint && npm test && npm run build`); pruebas de la regla y de su error, incluidas '
  '401, 403 y 404 por endpoint (RNF-003); respeta las convenciones de API y `DESIGN.md`; audita las operaciones '
  'críticas; documentación actualizada; PR revisado y fusionado con *squash*.')
A('')
A('## 9. Importación a Jira y paso a los sprints')
A('')
A('**Antes de importar**')
A('')
A('1. Eliminar los 81 issues actuales (SCRUM-78 a SCRUM-159), como decidió el equipo. Es irreversible: búsqueda '
  '`project = SCRUM` → Herramientas → Cambio masivo → Eliminar. El Sprint 1 y el tablero no se borran.')
A('2. Habilitar las horas en las subtareas: Configuración del proyecto → Tipos de trabajo → Subtask → agregar el '
  'campo **Time tracking** (Seguimiento del tiempo).')
A('3. En Configuración de Jira → Sistema → Seguimiento del tiempo, fijar la **unidad predeterminada en horas** '
  'durante la importación: hay un defecto conocido que interpreta mal los segundos cuando la unidad es minutos '
  '(JRACLOUD-65361).')
A('')
A('**Importar**')
A('')
A('1. Configuración de Jira → Sistema → Importación de sistemas externos → **CSV**. Archivo '
  '`backlog-siglim.csv`, codificación UTF-8, separador coma.')
A('2. Proyecto destino: **SIGLIM (SCRUM)**.')
A('3. Mapear columnas: `Issue ID` → Issue Id · `Parent` → Parent · `Issue Type` → Issue Type · `Summary` → '
  'Summary · `Description` → Description · `Priority` → Priority · `Status` → Status · `Story point estimate` → '
  'Story point estimate · `Original Estimate` → Original Estimate (en segundos) · `Labels` → Labels.')
A('4. Mapear valores: `Status` «Por hacer» → **Por hacer**. Los tipos ya vienen con los nombres de Jira (Epic, '
  'Story, Task, Subtask).')
A('5. Importar. Las filas ya vienen en orden: épicas, después historias y tareas, y al final las subtareas, '
  'para que cada padre exista antes que sus hijos.')
A('')
A('Las claves visibles las asigna Jira y continuarán después de SCRUM-159; el `Issue ID` del CSV (1 a '
  f'{len(filas)}) solo sirve para las relaciones durante la importación. Las épicas y las subtareas no llevan '
  'prioridad porque ese campo no existe en sus tipos (Epic, Subtask) en este proyecto.')
A('')
A('**Pasar los elementos a los sprints**')
A('')
A('1. En el Backlog del tablero, filtrar por la etiqueta `sprint-1` y arrastrar las historias y tareas (las '
  'subtareas viajan con su padre) al **Sprint 1** activo.')
A('2. Crear los Sprints 2, 3 y 4 con las fechas de la sección 2 y repetir con `sprint-2`, `sprint-3` y '
  '`sprint-4`. No iniciar un sprint hasta cerrar el anterior.')
A(f'3. En la importación, lo etiquetado `backlog` ({len(should)} historias Should y {n_b} historias B) se quedó en el '
  'Backlog. Desde la replanificación (DEC-50) esas historias llevan la etiqueta `sprint-N` de su sprint.')
A('4. Las épicas no se asignan a ningún sprint.')
A('')
A('## 10. Verificación después de importar')
A('')
A('| # | Verificación | JQL o acción | Esperado |')
A('| --- | --- | --- | --- |')
A(f'| 1 | Total importado | `project = SCRUM AND labels = siglim-v4` | {len(filas)} |')
A(f"| 2 | Por tipo | `… AND issuetype = Epic / Story / Task / Subtask` | {cuenta['Épica']} / {cuenta['Historia']} / "
  f"{cuenta['Tarea']} / {cuenta['Subtarea']} |")
A(f'| 3 | Todo en Por hacer | `… AND status != "Por hacer"` | 0 |')
A('| 4 | Sin huérfanos | `… AND issuetype in (Story, Task) AND parent is EMPTY` | 0 |')
A('| 5 | Subtareas con padre | `… AND issuetype = Subtask AND parent is EMPTY` | 0 |')
A(f"| 6 | Story Points | Suma de `Story point estimate` en Story y Task | {sp_must + sp_should + sp_b:g} |")
A(f"| 7 | Horas | Suma de la estimación original de las subtareas | {sum(s['horas'] for it in ITEMS for s in it['sub']):g} h |")
A('| 8 | Sprints | Filtro por etiqueta `sprint-N` contra el contenido del sprint N | Coinciden |')
A('| 9 | Épicas fuera de sprints | `… AND issuetype = Epic AND sprint is not EMPTY` | 0 |')
A('')
A('Claude puede ejecutar estas consultas con el conector de Jira y reportar el resultado real cuando el equipo '
  'termine la importación.')
A('')
A('## 11. Validaciones del generador')
A('')
A('`generar.py` se detiene si alguna falla:')
A('')
A('- Identificadores consecutivos desde 1, claves únicas, cada padre existe, va antes que su hijo y respeta la '
  'jerarquía de Jira (Épica → Historia/Tarea → Subtarea).')
A('- Cada historia del núcleo tiene criterios de aceptación y cada historia o tarea del núcleo tiene subtareas.')
A('- Horas de subtareas ≈ SP × 3 (±1.5 h); SP y horas de cada sprint dentro de su capacidad.')
A('- Dependencias existentes y planificadas en el mismo sprint o antes.')
A('- **Cobertura del ERS:** todo RF de entrega N y B aparece en algún elemento; ningún RF de entrega F se '
  'incluye; no hay RF inexistentes.')
A('- Las pantallas citadas existen en `docs/diseno-ui/pantallas/`.')
A('- El CSV releído tiene el mismo número de filas y columnas.')
A('')

MD_SALIDA.write_text('\n'.join(md) + '\n', encoding='utf-8')

# ---------------------------------------------------------------------------
print(f"Filas: {len(filas)} · {dict(cuenta)}")
print('SP por sprint:', dict(sp_sprint), '· horas:', dict(h_sprint))
print(f'Should: {sp_should} SP · B: {sp_b} SP')
if errores:
    print('ERRORES:')
    for e in errores:
        print(' -', e)
    sys.exit(1)
print('Validación correcta.')
