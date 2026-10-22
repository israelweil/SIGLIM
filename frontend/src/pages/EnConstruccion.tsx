type Props = {
  titulo: string
  descripcion: string
}

/** Marcador provisional de las rutas; se sustituye en T-03.2 y las historias de cada módulo. */
export function EnConstruccion({ titulo, descripcion }: Props) {
  return (
    <main className="min-h-dvh bg-background px-4 py-8 sm:px-6 lg:px-8">
      <h1 className="text-display-lg-mobile text-text-main sm:text-display-lg">{titulo}</h1>
      <p className="mt-2 text-body-md text-text-muted">{descripcion}</p>
    </main>
  )
}
