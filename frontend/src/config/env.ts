function requerida(nombre: string, valor: string | undefined): string {
  const limpio = valor?.trim()

  if (!limpio) {
    throw new Error(
      `Falta ${nombre} en frontend/.env.local. Copia .env.example y completa las variables.`,
    )
  }

  return limpio
}

export const env = {
  supabaseUrl: requerida('VITE_SUPABASE_URL', import.meta.env.VITE_SUPABASE_URL),
  supabasePublishableKey: requerida(
    'VITE_SUPABASE_PUBLISHABLE_KEY',
    import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
  ),
  apiUrl: import.meta.env.VITE_API_URL?.trim() || '/api/v1',
} as const
