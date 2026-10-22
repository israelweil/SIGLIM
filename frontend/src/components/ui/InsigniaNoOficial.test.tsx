import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { InsigniaNoOficial } from '@/components/ui/InsigniaNoOficial'

describe('InsigniaNoOficial', () => {
  it('rotula los valores [DEMO] como «No oficial» en ámbar', () => {
    render(<InsigniaNoOficial />)

    expect(screen.getByText('No oficial')).toHaveClass('text-warning-strong')
  })
})
