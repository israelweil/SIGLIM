"""Genera archivos BPMN 2.0 (semántica + diagrama) a partir de procesos.py.

Distribución: un pool horizontal con carriles; columnas por camino más largo desde el inicio
(ignorando los flujos de retorno); varios nodos en la misma columna y carril se apilan en el orden
de sus predecesores. Los flujos se trazan en ángulo recto eligiendo, entre varias rutas candidatas,
la primera que no atraviesa nodos ni se encima con otro flujo.
Uso: python generar_bpmn.py <carpeta_salida>
"""
import sys
from pathlib import Path
from xml.sax.saxutils import escape

from procesos import POOL, PROCESOS

TAM = {
    'inicio': (36, 36), 'inicio_tiempo': (36, 36), 'inicio_mensaje': (36, 36),
    'fin': (36, 36), 'fin_error': (36, 36), 'tiempo': (36, 36), 'mensaje': (36, 36),
    'borde_tiempo': (36, 36), 'xor': (50, 50), 'evento': (50, 50), 'and': (50, 50),
    'usuario': (120, 80), 'servicio': (120, 80), 'manual': (120, 80),
}
COL_W = 170
FILA_H = 125
POOL_X, POOL_Y = 20, 20
CAB_POOL = 30
CAB_CARRIL = 30
MARGEN = 40

ETIQUETA_INTERNA = {'usuario', 'servicio', 'manual'}


def capas(nodos, flujos):
    ids = [n[0] for n in nodos]
    tipo = {n[0]: n[1] for n in nodos}
    sal = {i: [] for i in ids}
    for o, d, _ in flujos:
        sal[o].append(d)
    # Detectar flujos de retorno con DFS desde los inicios (y desde eventos de borde)
    retorno = set()
    estado = {}

    def dfs(u):
        estado[u] = 1
        for v in sal[u]:
            if estado.get(v) == 1:
                retorno.add((u, v))
            elif v not in estado:
                dfs(v)
        estado[u] = 2

    for i in ids:
        if tipo[i].startswith('inicio'):
            dfs(i)
    for i in ids:
        if i not in estado:
            dfs(i)
    # Camino más largo sobre el DAG
    capa = {i: 0 for i in ids}
    host = {n[0]: n[4] for n in nodos if n[1] == 'borde_tiempo'}
    for _ in range(len(ids) + 2):
        cambio = False
        for b, h in host.items():
            if capa[b] != capa[h]:
                capa[b] = capa[h]; cambio = True
        for o, d, _ in flujos:
            if (o, d) in retorno:
                continue
            if capa[d] < capa[o] + 1:
                capa[d] = capa[o] + 1; cambio = True
        if not cambio:
            break
    return capa, retorno


def generar(p):
    nodos, flujos, carriles = p['nodos'], p['flujos'], p['carriles']
    capa, retorno = capas(nodos, flujos)
    tipo = {n[0]: n[1] for n in nodos}
    carril_de = {n[0]: n[3] for n in nodos}
    host = {n[0]: n[4] for n in nodos if n[1] == 'borde_tiempo'}

    # Sub-filas dentro de cada carril por columna
    # Orden dentro de cada (carril, columna) por baricentro de los predecesores, para evitar cruces.
    fila = {}
    ocup = {}
    idx_carril = {c: k for k, (c, _) in enumerate(carriles)}
    orden_original = {n[0]: k for k, n in enumerate(nodos)}
    pred = {}
    for o, d, _ in flujos:
        if (o, d) not in retorno:
            pred.setdefault(d, []).append(o)
    grupos = {}
    for n in nodos:
        if n[1] != 'borde_tiempo':
            grupos.setdefault((n[3], capa[n[0]]), []).append(n[0])
    for (c, col) in sorted(grupos, key=lambda g: g[1]):
        def clave(i):
            ps = [host.get(q, q) for q in pred.get(i, [])]
            ps = [q for q in ps if q in fila]
            if not ps:
                return (orden_original[i], orden_original[i])
            bc = sum(idx_carril[carril_de[q]] * 100 + fila[q] for q in ps) / len(ps)
            return (bc, orden_original[i])
        for k, i in enumerate(sorted(grupos[(c, col)], key=clave)):
            fila[i] = k
        ocup[(c, col)] = len(grupos[(c, col)])
    filas_carril = {c: max([v for (cc, _), v in ocup.items() if cc == c] or [1]) for c, _ in carriles}

    ncol = max(capa.values()) + 1
    ancho_pool = CAB_POOL + CAB_CARRIL + MARGEN * 2 + ncol * COL_W
    y = POOL_Y
    carril_y = {}
    for c, _ in carriles:
        h = filas_carril[c] * FILA_H + 20
        carril_y[c] = (y, h)
        y += h
    alto_pool = y - POOL_Y

    pos = {}
    for n in nodos:
        i, t = n[0], n[1]
        w, h = TAM[t]
        if t == 'borde_tiempo':
            continue
        cx = POOL_X + CAB_POOL + CAB_CARRIL + MARGEN + capa[i] * COL_W + COL_W / 2 - 25
        yc, _ = carril_y[n[3]]
        cy = yc + 10 + fila[i] * FILA_H + FILA_H / 2
        pos[i] = (cx - w / 2, cy - h / 2, w, h)
    for b, hst in host.items():
        x, yy, w, h = pos[hst]
        pos[b] = (x + w - 30, yy + h - 18, 36, 36)

    def centro(i):
        x, yy, w, h = pos[i]
        return x + w / 2, yy + h / 2

    # ---------- Ruteo ortogonal por candidatos ----------
    # Se generan rutas candidatas (de menos a más quiebres) y se elige la primera que no
    # atraviesa nodos ni se encima con otro flujo ya trazado.
    corredores = []
    for c, _ in carriles:
        yc, h = carril_y[c]
        for r in range(filas_carril[c] + 1):
            corredores.append(yc + 10 + r * FILA_H - (4 if r == filas_carril[c] else -4))
    corredores = sorted(set(corredores))
    trazados = []   # segmentos ya usados: (orientación, fijo, a, b)

    def segs(pts):
        return list(zip(pts, pts[1:]))

    def choca_nodo(pts, o, d):
        s = segs(pts)
        for k, ((ax, ay), (bx, by)) in enumerate(s):
            x0, x1_ = sorted((ax, bx)); y0, y1_ = sorted((ay, by))
            for n, (nx, ny, nw, nh) in pos.items():
                if n == o and k == 0 or n == d and k == len(s) - 1:
                    continue
                if n in host and (o == n or o == host.get(n)):
                    continue
                if o in host and n == host[o] and k == 0:
                    continue
                m = 6
                if x1_ > nx - m and x0 < nx + nw + m and y1_ > ny - m and y0 < ny + nh + m:
                    return True
        return False

    def encima(pts, o, d):
        for (ax, ay), (bx, by) in segs(pts):
            if abs(ax - bx) < 1:
                f, a, b, ori = ax, *sorted((ay, by)), 'v'
            else:
                f, a, b, ori = ay, *sorted((ax, bx)), 'h'
            for o2, f2, a2, b2, so, sd in trazados:
                if so == o or sd == d:
                    continue
                if o2 == ori and abs(f - f2) < 4 and min(b, b2) - max(a, a2) > 6:
                    return True
        return False

    def limpia(pts):
        r = [pts[0]]
        for p_ in pts[1:]:
            if abs(p_[0] - r[-1][0]) < 0.5 and abs(p_[1] - r[-1][1]) < 0.5:
                continue
            r.append(p_)
        # quitar puntos colineales
        k = 1
        while k < len(r) - 1:
            (a, b), (c_, d_), (e, f) = r[k - 1], r[k], r[k + 1]
            if (abs(a - c_) < 0.5 and abs(c_ - e) < 0.5) or (abs(b - d_) < 0.5 and abs(d_ - f) < 0.5):
                r.pop(k)
            else:
                k += 1
        return r

    def candidatos(o, d):
        x1, y1, w1, h1 = pos[o]
        x2, y2, w2, h2 = pos[d]
        cx1, cy1 = centro(o)
        cx2, cy2 = centro(d)
        gx = cx1 + COL_W / 2 - 12          # hueco a la derecha de la columna origen
        ex = cx2 - COL_W / 2 + 12          # hueco a la izquierda de la columna destino
        mx = x2 - 25
        compuerta = tipo[o] in ('xor', 'evento', 'and')
        R, B, T = (x1 + w1, cy1), (cx1, y1 + h1), (cx1, y1)
        L, Bd, Td = (x2, cy2), (cx2, y2 + h2), (cx2, y2)
        c = []
        if tipo[o] == 'borde_tiempo':
            c.append([B, (cx1, cy2), L] if x2 > cx1 else [B, (cx1, cy2), (x2 + w2, cy2)])
            c.append([B, (cx1, cy2 if cy2 > y1 + h1 else y1 + h1 + 20), (cx2, cy2 if cy2 > y1 + h1 else y1 + h1 + 20), Bd if cy2 < y1 else Td])
            for yy in corredores:
                c.append([B, (cx1, yy), (ex, yy), (ex, cy2), L])
            return c
        adelante = x2 > x1 + w1 + 5
        if adelante:
            if abs(cy1 - cy2) < 1:
                c.append([R, L])
            if compuerta and cy2 > cy1:
                c.append([B, (cx1, cy2), L])
            c.append([R, (mx, cy1), (mx, cy2), L])
            c.append([R, (gx, cy1), (gx, cy2), L])
            if not compuerta or cy2 > cy1:
                c.append([B if cy2 > cy1 else T, (cx1, cy2), L])
            c.append([R, (cx2, cy1), Td if cy2 > cy1 else Bd])
            orden = sorted(corredores, key=lambda yy: abs(yy - (cy1 + cy2) / 2))
            for yy in orden:
                for sal_ in ([R, (gx, cy1), (gx, yy)],
                             [B, (cx1, yy)] if yy > cy1 else ([T, (cx1, yy)] if not compuerta else None)):
                    if sal_ is None:
                        continue
                    c.append(sal_ + [(mx, yy), (mx, cy2), L])
                    c.append(sal_ + [(cx2, yy), Td if yy < cy2 else Bd])
        else:
            base = max(y1 + h1, y2 + h2)
            orden = sorted(corredores, key=lambda yy: (yy < base, abs(yy - base)))
            for yy in orden:
                for sal_ in ([R, (gx, cy1), (gx, yy)],
                             [B, (cx1, yy)] if yy > cy1 else ([T, (cx1, yy)] if not compuerta else None)):
                    if sal_ is None:
                        continue
                    c.append(sal_ + [(cx2, yy), Bd if yy > cy2 else Td])
                    c.append(sal_ + [(ex, yy), (ex, cy2), L])
        if compuerta:
            c.append([T, (cx1, cy2), L])
            for yy in corredores:
                c.append([T, (cx1, yy), (ex, yy), (ex, cy2), L])
        return c

    rutas = {}
    # primero los flujos hacia adelante, luego los de retorno
    orden_flujos = sorted(range(len(flujos)), key=lambda k: (flujos[k][:2] in retorno,
                          pos[flujos[k][1]][0] < pos[flujos[k][0]][0]))
    for k in orden_flujos:
        o, d, _ = flujos[k]
        cands = [limpia(c) for c in candidatos(o, d)]
        elegido = next((c for c in cands if not choca_nodo(c, o, d) and not encima(c, o, d)), None)
        if elegido is None:
            elegido = next((c for c in cands if not choca_nodo(c, o, d)), cands[0])
            print('  aviso: ruta encimada', p['id'], o, '->', d)
        for (ax, ay), (bx, by) in segs(elegido):
            if abs(ax - bx) < 1:
                trazados.append(('v', ax, *sorted((ay, by)), o, d))
            else:
                trazados.append(('h', ay, *sorted((ax, bx)), o, d))
        rutas[k] = elegido


    def sobre(px, py, pts):
        for (ax, ay), (bx, by) in segs(pts):
            if min(ax, bx) - 1 <= px <= max(ax, bx) + 1 and min(ay, by) - 1 <= py <= max(ay, by) + 1:
                return True
        return False

    def etiqueta_flujo(k):
        """Coloca la etiqueta donde el flujo se separa de los demás flujos que salen del mismo nodo."""
        o = flujos[k][0]
        hermanos = [rutas[j] for j in range(len(flujos)) if j != k and flujos[j][0] == o]
        pts = rutas[k]
        ss = segs(pts)

        def hermanos_cubren(ax, ay, px, py):
            # el tramo vertical inicial es compartido (tronco) hasta el punto de separación
            return abs(py - ay) > 3

        def sobre_horizontal(px, py, hacia_derecha, fin=None):
            if fin is not None and abs(fin - px) < 70:     # tramo corto: la etiqueta va antes del quiebre
                return px - 34, py - 18
            ly = py - 18
            if ly < POOL_Y + 2:
                ly = py + 4
            return (px + 12 if hacia_derecha else px - 40), ly

        for i, ((ax, ay), (bx, by)) in enumerate(ss):
            largo = abs(bx - ax) + abs(by - ay)
            paso = 0
            while paso <= largo:
                t = paso / largo if largo else 0
                px, py = ax + (bx - ax) * t, ay + (by - ay) * t
                if not any(sobre(px, py, h) for h in hermanos):
                    if abs(ax - bx) > 1:                       # tramo horizontal
                        return sobre_horizontal(px, py, bx > ax, bx)
                    if i + 1 < len(ss) and (i > 0 or hermanos_cubren(ax, ay, px, py)):             # se separa en un tramo vertical intermedio:
                        (cx_, cy_), (dx_, _) = ss[i + 1]       # se rotula el siguiente tramo horizontal
                        if abs(dx_ - cx_) >= 70:
                            return sobre_horizontal(cx_, cy_, dx_ > cx_)
                        return px - 26, (py + 22 if by > ay else py - 40)
                    return px + 6, (py + 4 if by > ay else py - 20)
                paso += 2
        (ax, ay), (bx, by) = pts[0], pts[1]
        return ax + 6, ay - 18

    # ---------- XML semántico ----------
    sal, ent = {}, {}
    for k, (o, d, _) in enumerate(flujos):
        fid = f'Flujo_{k + 1}'
        sal.setdefault(o, []).append(fid)
        ent.setdefault(d, []).append(fid)

    def nid(i):
        return f'{p["id"].replace("-", "")}_{i}'

    elem = []
    for n in nodos:
        i, t, nombre = n[0], n[1], n[2]
        io = ''.join(f'<bpmn:incoming>{f}</bpmn:incoming>' for f in ent.get(i, [])) + \
             ''.join(f'<bpmn:outgoing>{f}</bpmn:outgoing>' for f in sal.get(i, []))
        nm = escape(nombre, {'"': '&quot;'})
        if t == 'inicio':
            elem.append(f'<bpmn:startEvent id="{nid(i)}" name="{nm}">{io}</bpmn:startEvent>')
        elif t == 'inicio_tiempo':
            elem.append(f'<bpmn:startEvent id="{nid(i)}" name="{nm}">{io}<bpmn:timerEventDefinition/></bpmn:startEvent>')
        elif t == 'inicio_mensaje':
            elem.append(f'<bpmn:startEvent id="{nid(i)}" name="{nm}">{io}<bpmn:messageEventDefinition/></bpmn:startEvent>')
        elif t == 'fin':
            elem.append(f'<bpmn:endEvent id="{nid(i)}" name="{nm}">{io}</bpmn:endEvent>')
        elif t == 'fin_error':
            elem.append(f'<bpmn:endEvent id="{nid(i)}" name="{nm}">{io}<bpmn:errorEventDefinition/></bpmn:endEvent>')
        elif t == 'usuario':
            elem.append(f'<bpmn:userTask id="{nid(i)}" name="{nm}">{io}</bpmn:userTask>')
        elif t == 'servicio':
            elem.append(f'<bpmn:serviceTask id="{nid(i)}" name="{nm}">{io}</bpmn:serviceTask>')
        elif t == 'manual':
            elem.append(f'<bpmn:manualTask id="{nid(i)}" name="{nm}">{io}</bpmn:manualTask>')
        elif t == 'xor':
            elem.append(f'<bpmn:exclusiveGateway id="{nid(i)}" name="{nm}">{io}</bpmn:exclusiveGateway>')
        elif t == 'evento':
            elem.append(f'<bpmn:eventBasedGateway id="{nid(i)}" name="{nm}">{io}</bpmn:eventBasedGateway>')
        elif t == 'and':
            elem.append(f'<bpmn:parallelGateway id="{nid(i)}" name="{nm}">{io}</bpmn:parallelGateway>')
        elif t == 'tiempo':
            elem.append(f'<bpmn:intermediateCatchEvent id="{nid(i)}" name="{nm}">{io}<bpmn:timerEventDefinition/></bpmn:intermediateCatchEvent>')
        elif t == 'mensaje':
            elem.append(f'<bpmn:intermediateCatchEvent id="{nid(i)}" name="{nm}">{io}<bpmn:messageEventDefinition/></bpmn:intermediateCatchEvent>')
        elif t == 'borde_tiempo':
            elem.append(f'<bpmn:boundaryEvent id="{nid(i)}" name="{nm}" attachedToRef="{nid(n[4])}" cancelActivity="true">{io}<bpmn:timerEventDefinition/></bpmn:boundaryEvent>')
    for k, (o, d, et) in enumerate(flujos):
        nm = f' name="{escape(et)}"' if et else ''
        elem.append(f'<bpmn:sequenceFlow id="Flujo_{k + 1}"{nm} sourceRef="{nid(o)}" targetRef="{nid(d)}"/>')

    lanes = []
    for c, nombre in carriles:
        refs = ''.join(f'<bpmn:flowNodeRef>{nid(n[0])}</bpmn:flowNodeRef>' for n in nodos if n[3] == c)
        lanes.append(f'<bpmn:lane id="Carril_{c}" name="{escape(nombre)}">{refs}</bpmn:lane>')

    pid = p['id'].replace('-', '')
    # ---------- Diagrama ----------
    di = [f'<bpmndi:BPMNShape id="Pool_{pid}_di" bpmnElement="Pool_{pid}" isHorizontal="true">'
          f'<dc:Bounds x="{POOL_X}" y="{POOL_Y}" width="{ancho_pool}" height="{alto_pool}"/></bpmndi:BPMNShape>']
    for c, _ in carriles:
        yc, h = carril_y[c]
        di.append(f'<bpmndi:BPMNShape id="Carril_{c}_di" bpmnElement="Carril_{c}" isHorizontal="true">'
                  f'<dc:Bounds x="{POOL_X + CAB_POOL}" y="{yc}" width="{ancho_pool - CAB_POOL}" height="{h}"/></bpmndi:BPMNShape>')
    for n in nodos:
        i, t = n[0], n[1]
        x, yy, w, h = pos[i]
        etiqueta = ''
        if t not in ETIQUETA_INTERNA and n[2]:
            if t == 'borde_tiempo':
                etiqueta = f'<bpmndi:BPMNLabel><dc:Bounds x="{x + 40}" y="{yy + 10}" width="{w + 120}" height="14"/></bpmndi:BPMNLabel>'
            elif t in ('xor', 'evento', 'and'):
                etiqueta = f'<bpmndi:BPMNLabel><dc:Bounds x="{x - 40}" y="{yy - 34}" width="{w + 80}" height="28"/></bpmndi:BPMNLabel>'
            else:
                etiqueta = f'<bpmndi:BPMNLabel><dc:Bounds x="{x - 57}" y="{yy + h + 4}" width="{w + 114}" height="28"/></bpmndi:BPMNLabel>'
        di.append(f'<bpmndi:BPMNShape id="{nid(i)}_di" bpmnElement="{nid(i)}">'
                  f'<dc:Bounds x="{x:.0f}" y="{yy:.0f}" width="{w}" height="{h}"/>{etiqueta}</bpmndi:BPMNShape>')
    for k, (o, d, et) in enumerate(flujos):
        pts = rutas[k]
        wp = ''.join(f'<di:waypoint x="{a:.0f}" y="{b:.0f}"/>' for a, b in pts)
        lab = ''
        if et:
            lx, ly = etiqueta_flujo(k)
            ancho, alto = max(30, 7 * len(et)), 14
            if len(et) > 12:                       # etiquetas largas en dos renglones
                ancho, alto, ly = 80, 28, ly - 14
            lab = f'<bpmndi:BPMNLabel><dc:Bounds x="{lx:.0f}" y="{ly:.0f}" width="{ancho}" height="{alto}"/></bpmndi:BPMNLabel>'
        di.append(f'<bpmndi:BPMNEdge id="Flujo_{k + 1}_di" bpmnElement="Flujo_{k + 1}">{wp}{lab}</bpmndi:BPMNEdge>')

    doc = f'''<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
  id="Definiciones_{pid}" targetNamespace="https://github.com/israelweil/SIGLIM/bpmn"
  exporter="SIGLIM generar_bpmn.py" exporterVersion="2.0">
  <bpmn:collaboration id="Colaboracion_{pid}">
    <bpmn:documentation>{escape(p['id'] + ' ' + p['nombre'] + '. ' + p['objetivo'])}</bpmn:documentation>
    <bpmn:participant id="Pool_{pid}" name="{escape(POOL)}" processRef="Proceso_{pid}"/>
  </bpmn:collaboration>
  <bpmn:process id="Proceso_{pid}" name="{escape(p['id'] + ' ' + p['nombre'])}" isExecutable="false">
    <bpmn:laneSet id="Carriles_{pid}">{''.join(lanes)}</bpmn:laneSet>
    {chr(10).join('    ' + e for e in elem)}
  </bpmn:process>
  <bpmndi:BPMNDiagram id="Diagrama_{pid}">
    <bpmndi:BPMNPlane id="Plano_{pid}" bpmnElement="Colaboracion_{pid}">
{chr(10).join('      ' + d for d in di)}
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn:definitions>
'''
    return doc


if __name__ == '__main__':
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for p in PROCESOS:
        (out / f'{p["archivo"]}.bpmn').write_text(generar(p), encoding='utf-8')
        print(p['archivo'])
