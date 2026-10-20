"""Genera el documento BPMN v2.0 en Word (carta horizontal) a partir de doc-impresion.md.

Pasos: 1) sustituye cada bloque Mermaid por su imagen PNG (renderizada con mermaid-cli);
2) convierte con pandoc; 3) da formato institucional con python-docx (portada, márgenes,
encabezado, pie con número de página, tablas con bordes y encabezado sombreado).
"""
import re
import subprocess
import tempfile
import sys
from pathlib import Path

from docx import Document
from docx.enum.section import WD_ORIENT
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

SRC = Path(sys.argv[1])          # doc-impresion.md
LOGO = Path(sys.argv[2])         # logotipo de la plantilla
OUT = Path(sys.argv[3])          # .docx de salida
WORK = Path(tempfile.mkdtemp())   # intermedios fuera del repositorio

VERDE = RGBColor(0x00, 0x68, 0x37)
FUENTE = 'Arial'

# ---------- 1. Markdown para pandoc ----------
md = SRC.read_text(encoding='utf-8')
(WORK / 'BPMN-pandoc.md').write_text(md, encoding='utf-8')
subprocess.run(['pandoc', str(WORK / 'BPMN-pandoc.md'), '-f', 'gfm', '-t', 'docx',
                '--toc', '--toc-depth=2', '--shift-heading-level-by=-1', '-M', 'toc-title=Contenido',
                '-o', str(WORK / 'raw.docx')], check=True)

# ---------- 2. Formato ----------
doc = Document(WORK / 'raw.docx')

for s in doc.sections:
    s.orientation = WD_ORIENT.LANDSCAPE
    s.page_width, s.page_height = Cm(27.94), Cm(21.59)    # carta horizontal
    s.left_margin = s.right_margin = Cm(2.0)
    s.top_margin = s.bottom_margin = Cm(1.8)
ANCHO = Cm(27.94 - 4.0)

estilos = doc.styles


def estilo(nombre):
    for s in estilos:
        if s.name and s.name.lower() == nombre.lower():
            return s
    return None


for nombre in ['Normal', 'Body Text', 'First Paragraph', 'Compact', 'Table', 'Image Caption']:
    st = estilo(nombre)
    if st is not None:
        st.font.name = FUENTE
        st.font.size = Pt(10.5 if nombre != 'Compact' else 9)
        st.element.get_or_add_rPr().get_or_add_rFonts().set(qn('w:eastAsia'), FUENTE)
for nivel, tam in [(1, 16), (2, 13), (3, 11.5), (4, 11)]:
    st = estilo(f'Heading {nivel}')
    st.font.name = FUENTE
    st.font.size = Pt(tam)
    st.font.bold = True
    st.font.color.rgb = VERDE
    st.element.get_or_add_rPr().get_or_add_rFonts().set(qn('w:eastAsia'), FUENTE)
    st.paragraph_format.space_before = Pt(14 if nivel == 1 else 10)
    st.paragraph_format.space_after = Pt(6)
    st.paragraph_format.keep_with_next = True
estilo('Heading 1').paragraph_format.page_break_before = True


def borde(celda, color='808080'):
    tcPr = celda._tc.get_or_add_tcPr()
    bordes = OxmlElement('w:tcBorders')
    for lado in ('top', 'left', 'bottom', 'right'):
        e = OxmlElement(f'w:{lado}')
        e.set(qn('w:val'), 'single')
        e.set(qn('w:sz'), '4')
        e.set(qn('w:color'), color)
        bordes.append(e)
    tcPr.append(bordes)


def sombrear(celda, color='DCEFE3'):
    tcPr = celda._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), color)
    tcPr.append(shd)


for tabla in doc.tables:
    tabla.alignment = WD_TABLE_ALIGNMENT.CENTER
    tblPr = tabla._tbl.tblPr
    ancho = OxmlElement('w:tblW')
    ancho.set(qn('w:w'), '5000')
    ancho.set(qn('w:type'), 'pct')
    for e in tblPr.findall(qn('w:tblW')):
        tblPr.remove(e)
    tblPr.append(ancho)
    for i, fila in enumerate(tabla.rows):
        if i == 0:   # repetir encabezado en cada página
            trPr = fila._tr.get_or_add_trPr()
            h = OxmlElement('w:tblHeader')
            trPr.append(h)
        for celda in fila.cells:
            borde(celda)
            if i == 0:
                sombrear(celda)
            for p in celda.paragraphs:
                p.paragraph_format.space_after = Pt(1)
                p.paragraph_format.space_before = Pt(1)
                for r in p.runs:
                    r.font.size = Pt(8.5)
                    r.font.name = FUENTE
                    if i == 0:
                        r.font.bold = True

# Anchos de columna proporcionales al contenido
import math
for tabla in doc.tables:
    ncol = len(tabla.columns)
    if ncol < 2:
        continue
    minimos, pesos = [], []
    for j in range(ncol):
        textos = [fila.cells[j].text for fila in list(tabla.rows)[1:] if j < len(fila.cells)] or ['']
        titulo = tabla.rows[0].cells[j].text if j < len(tabla.rows[0].cells) else ''
        largo = sum(len(x) for x in textos) / max(1, len(textos))
        palabra = max((len(w) for x in textos for w in x.split()), default=4)
        p_tit = max((len(w) for w in titulo.split()), default=2)
        minimos.append(Cm(max(min(palabra, 22) * 0.17, p_tit * 0.16) + 0.4))
        pesos.append(max(largo, 1) ** 0.9)
    resto = max(ANCHO - sum(minimos), 0)
    total = sum(pesos)
    anchos = [int(m + resto * w / total) for m, w in zip(minimos, pesos)]
    if sum(anchos) > ANCHO:
        anchos = [int(a * ANCHO / sum(anchos)) for a in anchos]
    tblPr = tabla._tbl.tblPr
    lay = OxmlElement('w:tblLayout'); lay.set(qn('w:type'), 'fixed'); tblPr.append(lay)
    for e in tblPr.findall(qn('w:tblW')):
        e.set(qn('w:w'), str(int(ANCHO.twips if hasattr(ANCHO, 'twips') else ANCHO / 635)))
        e.set(qn('w:type'), 'dxa')
    grid = tabla._tbl.tblGrid
    for j, gc in enumerate(grid.findall(qn('w:gridCol'))):
        if j < ncol:
            gc.set(qn('w:w'), str(int(anchos[j] / 635)))
    for fila in tabla.rows:
        for j, celda in enumerate(fila.cells):
            if j < ncol:
                celda.width = anchos[j]

# Imágenes: ajustar al ancho y a una altura máxima
ALTO_MAX = Cm(14.2)
for forma in doc.inline_shapes:
    w, h = forma.width, forma.height
    escala = min(ANCHO / w, ALTO_MAX / h)
    forma.width, forma.height = int(w * escala), int(h * escala)
import re as _re
anterior = None
for p in doc.paragraphs:
    if p.style.name.lower().startswith('heading 2') and _re.match(r'5\.\d+ P-', p.text):
        p.paragraph_format.page_break_before = True      # cada proceso inicia en página nueva
    if p._p.findall('.//' + qn('w:drawing')):
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        es_titulo = anterior is not None and anterior.style.name.lower().startswith('heading')
        p.paragraph_format.page_break_before = not es_titulo
        p.paragraph_format.keep_with_next = True
    anterior = p
    if p.text.startswith('Figura '):
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for r in p.runs:
            r.font.size = Pt(9)


# ---------- 3. Portada ----------
cuerpo = doc.element.body
primero = cuerpo[0]


def parrafo_antes(texto='', tam=11, negrita=False, centrado=True, color=None, espacio=6):
    p = doc.add_paragraph()
    cuerpo.remove(p._p)
    primero.addprevious(p._p)
    if centrado:
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(espacio)
    if texto:
        r = p.add_run(texto)
        r.font.size = Pt(tam)
        r.font.bold = negrita
        r.font.name = FUENTE
        if color:
            r.font.color.rgb = color
    return p


logo = parrafo_antes(espacio=12)
logo.add_run().add_picture(str(LOGO), width=Cm(3.2))
parrafo_antes('Tecnológico Nacional de México', 12, True, espacio=2)
parrafo_antes('Instituto Tecnológico de Morelia', 12, True, espacio=24)
parrafo_antes('BPMN de los procesos del sistema', 22, True, color=VERDE)
parrafo_antes('SIGLIM · Sistema de Gestión de la Liga Municipal de Futbol Amateur Morelia', 13, espacio=12)
parrafo_antes('Versión 2.0 · BPMN 2.0 (ISO/IEC 19510) · Alineado con el ERS Rev. 0.4', 11, espacio=24)
parrafo_antes('Ingeniería en Sistemas Computacionales · Fundamentos de Ingeniería de Software', 11, espacio=12)
parrafo_antes('Presentan: López Meza Leonardo · Olvera Bucio Jose Israel · Olvera Lobato David Geovani', 11, espacio=4)
parrafo_antes('Profesor: Claudio Ernesto Florian Arenas', 11, espacio=24)
parrafo_antes('Morelia, Michoacán · Octubre de 2026', 11)
fin = parrafo_antes('Borrador para seguimiento académico; pendiente de validación por la Liga.', 9)
fin.add_run().add_break(WD_BREAK.PAGE)

# ---------- 4. Encabezado y pie ----------


def campo(parrafo, instr):
    r = parrafo.add_run()
    a = OxmlElement('w:fldChar'); a.set(qn('w:fldCharType'), 'begin'); r._r.append(a)
    t = OxmlElement('w:instrText'); t.set(qn('xml:space'), 'preserve'); t.text = instr; r._r.append(t)
    b = OxmlElement('w:fldChar'); b.set(qn('w:fldCharType'), 'end'); r._r.append(b)
    return r


s = doc.sections[0]
s.different_first_page_header_footer = True
enc = s.header.paragraphs[0]
enc.text = 'BPMN de los procesos del sistema · SIGLIM · Versión 2.0'
enc.alignment = WD_ALIGN_PARAGRAPH.RIGHT
for r in enc.runs:
    r.font.size = Pt(8)
    r.font.color.rgb = RGBColor(0x55, 0x55, 0x55)
pie = s.footer.paragraphs[0]
pie.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = pie.add_run('Borrador para seguimiento · Octubre de 2026 · Pág. ')
r.font.size = Pt(8)
campo(pie, 'PAGE').font.size = Pt(8)

# Actualizar campos (índice) al abrir
settings = doc.settings.element
upd = OxmlElement('w:updateFields'); upd.set(qn('w:val'), 'true')
settings.append(upd)

core = doc.core_properties
core.title = 'BPMN de los procesos del sistema — SIGLIM · v2.0'
core.author = 'López Meza Leonardo; Olvera Bucio Jose Israel; Olvera Lobato David Geovani'
core.subject = 'Modelo de procesos de negocio (BPMN 2.0)'
core.language = 'es-MX'

doc.save(OUT)
print('ok', OUT)
