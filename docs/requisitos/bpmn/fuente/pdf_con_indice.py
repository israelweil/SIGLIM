"""Exporta un .docx a PDF con LibreOffice actualizando antes el índice (campo TOC)."""
import subprocess, sys, time
from pathlib import Path
import uno
from com.sun.star.beans import PropertyValue

src, dst = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
proc = subprocess.Popen(['soffice', '--headless', '--invisible', '--norestore',
                         '--accept=socket,host=127.0.0.1,port=2002;urp;'])
ctx = None
res = uno.getComponentContext().ServiceManager.createInstanceWithContext('com.sun.star.bridge.UnoUrlResolver', uno.getComponentContext())
for _ in range(60):
    try:
        ctx = res.resolve('uno:socket,host=127.0.0.1,port=2002;urp;StarOffice.ComponentContext'); break
    except Exception:
        time.sleep(0.5)
desk = ctx.ServiceManager.createInstanceWithContext('com.sun.star.frame.Desktop', ctx)
def pv(n, v):
    p = PropertyValue(); p.Name, p.Value = n, v; return p
doc = desk.loadComponentFromURL(src.as_uri(), '_blank', 0, (pv('Hidden', True),))
idx = doc.getDocumentIndexes()
n_indices = idx.getCount()
for i in range(n_indices):
    idx.getByIndex(i).update()
doc.refresh()
doc.storeToURL(dst.as_uri(), (pv('FilterName', 'writer_pdf_Export'),))
doc.close(True)
try:
    desk.terminate()
except Exception:
    pass
proc.wait(timeout=30)
print('ok', dst, 'índices:', n_indices)
