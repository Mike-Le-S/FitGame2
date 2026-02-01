import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { cn, formatDate, formatTime, formatRelativeTime, generateId } from '@/lib/utils'

describe('cn (class name merging)', () => {
  it('merges multiple class names', () => {
    expect(cn('foo', 'bar')).toBe('foo bar')
  })

  it('handles undefined and null values', () => {
    expect(cn('foo', undefined, 'bar', null)).toBe('foo bar')
  })

  it('handles empty strings', () => {
    expect(cn('foo', '', 'bar')).toBe('foo bar')
  })

  it('handles conditional classes with objects', () => {
    expect(cn('base', { active: true, disabled: false })).toBe('base active')
  })

  it('handles arrays of class names', () => {
    expect(cn(['foo', 'bar'], 'baz')).toBe('foo bar baz')
  })

  it('merges Tailwind conflicting classes correctly', () => {
    // tailwind-merge should keep only the last conflicting class
    expect(cn('p-4', 'p-2')).toBe('p-2')
    expect(cn('text-red-500', 'text-blue-500')).toBe('text-blue-500')
    expect(cn('bg-white', 'bg-black')).toBe('bg-black')
  })

  it('keeps non-conflicting Tailwind classes', () => {
    expect(cn('p-4', 'm-2')).toBe('p-4 m-2')
    expect(cn('text-red-500', 'bg-blue-500')).toBe('text-red-500 bg-blue-500')
  })

  it('handles complex Tailwind class combinations', () => {
    expect(cn(
      'px-4 py-2 bg-blue-500 text-white rounded',
      'hover:bg-blue-600',
      { 'opacity-50': true, 'cursor-not-allowed': false }
    )).toBe('px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 opacity-50')
  })

  it('returns empty string when no valid classes', () => {
    expect(cn()).toBe('')
    expect(cn(undefined, null, '')).toBe('')
  })

  it('handles nested arrays', () => {
    expect(cn(['foo', ['bar', 'baz']])).toBe('foo bar baz')
  })
})

describe('formatDate', () => {
  it('formats a Date object to French locale', () => {
    const date = new Date('2024-06-15T10:30:00')
    const result = formatDate(date)
    // French format: "15 juin 2024"
    expect(result).toMatch(/15/)
    expect(result).toMatch(/juin/i)
    expect(result).toMatch(/2024/)
  })

  it('formats a date string to French locale', () => {
    const result = formatDate('2024-01-05')
    expect(result).toMatch(/5/)
    expect(result).toMatch(/janv/i)
    expect(result).toMatch(/2024/)
  })

  it('handles ISO date strings', () => {
    const result = formatDate('2024-12-25T00:00:00.000Z')
    expect(result).toMatch(/25/)
    expect(result).toMatch(/déc/i)
    expect(result).toMatch(/2024/)
  })

  it('formats different months correctly', () => {
    const months = [
      { date: '2024-03-10', expected: /mars/i },
      { date: '2024-07-22', expected: /juil/i },
      { date: '2024-11-30', expected: /nov/i },
    ]

    months.forEach(({ date, expected }) => {
      expect(formatDate(date)).toMatch(expected)
    })
  })

  it('handles leap year dates', () => {
    const result = formatDate('2024-02-29')
    expect(result).toMatch(/29/)
    expect(result).toMatch(/févr/i)
    expect(result).toMatch(/2024/)
  })

  it('handles year boundaries', () => {
    const newYearEve = formatDate('2023-12-31')
    expect(newYearEve).toMatch(/31/)
    expect(newYearEve).toMatch(/2023/)

    const newYearDay = formatDate('2024-01-01')
    expect(newYearDay).toMatch(/1/)
    expect(newYearDay).toMatch(/2024/)
  })
})

describe('formatTime', () => {
  it('formats time in 24-hour French format', () => {
    const date = new Date('2024-06-15T14:30:00')
    const result = formatTime(date)
    expect(result).toBe('14:30')
  })

  it('formats morning time correctly', () => {
    const date = new Date('2024-06-15T09:05:00')
    const result = formatTime(date)
    expect(result).toBe('09:05')
  })

  it('formats midnight correctly', () => {
    const date = new Date('2024-06-15T00:00:00')
    const result = formatTime(date)
    expect(result).toBe('00:00')
  })

  it('formats noon correctly', () => {
    const date = new Date('2024-06-15T12:00:00')
    const result = formatTime(date)
    expect(result).toBe('12:00')
  })

  it('handles string input', () => {
    const result = formatTime('2024-06-15T18:45:00')
    expect(result).toBe('18:45')
  })

  it('handles ISO strings with timezone', () => {
    // Note: this will be converted to local time
    const result = formatTime('2024-06-15T10:30:00.000Z')
    // Result depends on local timezone, but should be valid HH:MM format
    expect(result).toMatch(/^\d{2}:\d{2}$/)
  })

  it('pads single digit hours and minutes', () => {
    const earlyMorning = new Date('2024-06-15T01:05:00')
    expect(formatTime(earlyMorning)).toBe('01:05')
  })
})

describe('formatRelativeTime', () => {
  beforeEach(() => {
    // Mock Date.now to have consistent tests
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2024-06-15T12:00:00'))
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('returns "A l\'instant" for times less than 1 minute ago', () => {
    const now = new Date()
    expect(formatRelativeTime(now)).toBe("À l'instant")

    const thirtySecondsAgo = new Date(now.getTime() - 30000)
    expect(formatRelativeTime(thirtySecondsAgo)).toBe("À l'instant")
  })

  it('returns minutes for times between 1-59 minutes ago', () => {
    const now = new Date()

    const fiveMinutesAgo = new Date(now.getTime() - 5 * 60000)
    expect(formatRelativeTime(fiveMinutesAgo)).toBe('Il y a 5min')

    const thirtyMinutesAgo = new Date(now.getTime() - 30 * 60000)
    expect(formatRelativeTime(thirtyMinutesAgo)).toBe('Il y a 30min')

    const fiftyNineMinutesAgo = new Date(now.getTime() - 59 * 60000)
    expect(formatRelativeTime(fiftyNineMinutesAgo)).toBe('Il y a 59min')
  })

  it('returns hours for times between 1-23 hours ago', () => {
    const now = new Date()

    const oneHourAgo = new Date(now.getTime() - 60 * 60000)
    expect(formatRelativeTime(oneHourAgo)).toBe('Il y a 1h')

    const twoHoursAgo = new Date(now.getTime() - 2 * 3600000)
    expect(formatRelativeTime(twoHoursAgo)).toBe('Il y a 2h')

    const twentyThreeHoursAgo = new Date(now.getTime() - 23 * 3600000)
    expect(formatRelativeTime(twentyThreeHoursAgo)).toBe('Il y a 23h')
  })

  it('returns days for times between 1-6 days ago', () => {
    const now = new Date()

    const oneDayAgo = new Date(now.getTime() - 24 * 3600000)
    expect(formatRelativeTime(oneDayAgo)).toBe('Il y a 1j')

    const threeDaysAgo = new Date(now.getTime() - 3 * 86400000)
    expect(formatRelativeTime(threeDaysAgo)).toBe('Il y a 3j')

    const sixDaysAgo = new Date(now.getTime() - 6 * 86400000)
    expect(formatRelativeTime(sixDaysAgo)).toBe('Il y a 6j')
  })

  it('returns formatted date for times 7+ days ago', () => {
    const now = new Date()

    const sevenDaysAgo = new Date(now.getTime() - 7 * 86400000)
    const result = formatRelativeTime(sevenDaysAgo)
    // Should return formatDate result
    expect(result).toMatch(/\d/)
    expect(result).toMatch(/juin/i)

    const thirtyDaysAgo = new Date(now.getTime() - 30 * 86400000)
    const result2 = formatRelativeTime(thirtyDaysAgo)
    expect(result2).toMatch(/\d/)
    expect(result2).toMatch(/mai/i)
  })

  it('handles string input', () => {
    vi.setSystemTime(new Date('2024-06-15T12:00:00'))

    const result = formatRelativeTime('2024-06-15T11:30:00')
    expect(result).toBe('Il y a 30min')
  })

  it('handles edge cases at boundaries', () => {
    const now = new Date()

    // Exactly 60 minutes = 1 hour
    const sixtyMinutesAgo = new Date(now.getTime() - 60 * 60000)
    expect(formatRelativeTime(sixtyMinutesAgo)).toBe('Il y a 1h')

    // Exactly 24 hours = 1 day
    const twentyFourHoursAgo = new Date(now.getTime() - 24 * 3600000)
    expect(formatRelativeTime(twentyFourHoursAgo)).toBe('Il y a 1j')
  })
})

describe('generateId', () => {
  it('generates a string', () => {
    const id = generateId()
    expect(typeof id).toBe('string')
  })

  it('generates a 7-character string', () => {
    const id = generateId()
    expect(id.length).toBe(7)
  })

  it('generates alphanumeric characters only', () => {
    const id = generateId()
    expect(id).toMatch(/^[a-z0-9]+$/)
  })

  it('generates unique IDs', () => {
    const ids = new Set<string>()
    for (let i = 0; i < 100; i++) {
      ids.add(generateId())
    }
    // All 100 IDs should be unique
    expect(ids.size).toBe(100)
  })

  it('does not contain special characters', () => {
    for (let i = 0; i < 50; i++) {
      const id = generateId()
      expect(id).not.toMatch(/[^a-z0-9]/)
    }
  })

  it('generates IDs without leading zeros being stripped', () => {
    // Generate many IDs and verify length consistency
    for (let i = 0; i < 100; i++) {
      const id = generateId()
      expect(id.length).toBe(7)
    }
  })
})
