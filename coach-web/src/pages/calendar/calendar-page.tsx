import { useState } from 'react'
import {
  ChevronLeft,
  ChevronRight,
  Plus,
  Dumbbell,
  Apple,
  MessageSquare,
  Calendar,
  Clock,
  Users,
  Check,
  Trash2,
} from 'lucide-react'
import {
  format,
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  addDays,
  addMonths,
  subMonths,
  isSameMonth,
  isSameDay,
  isToday,
} from 'date-fns'
import { fr } from 'date-fns/locale'
import { Header } from '@/components/layout'
import { CreateEventModal } from '@/components/modals/create-event-modal'
import { EditEventModal } from '@/components/modals/edit-event-modal'
import { useEventsStore } from '@/store/events-store'
import { useStudentsStore } from '@/store/students-store'
import { cn } from '@/lib/utils'
import type { CalendarEvent } from '@/types'

const eventTypeConfig = {
  workout: { label: 'Entraînement', icon: Dumbbell, color: 'accent' },
  nutrition: { label: 'Nutrition', icon: Apple, color: 'success' },
  'check-in': { label: 'Check-in', icon: MessageSquare, color: 'info' },
  other: { label: 'Autre', icon: Calendar, color: 'warning' },
}

export function CalendarPage() {
  const [currentMonth, setCurrentMonth] = useState(new Date())
  const [selectedDate, setSelectedDate] = useState(new Date())
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(null)
  const [selectedStudentIds, setSelectedStudentIds] = useState<string[]>([])
  const { events, toggleComplete, deleteEvent } = useEventsStore()
  const { students } = useStudentsStore()

  const toggleStudentFilter = (studentId: string) => {
    setSelectedStudentIds(prev =>
      prev.includes(studentId)
        ? prev.filter(id => id !== studentId)
        : [...prev, studentId]
    )
  }

  const clearStudentFilter = () => setSelectedStudentIds([])

  const handleEditEvent = (event: CalendarEvent) => {
    setSelectedEvent(event)
    setIsEditModalOpen(true)
  }

  const monthStart = startOfMonth(currentMonth)
  const monthEnd = endOfMonth(monthStart)
  const startDate = startOfWeek(monthStart, { weekStartsOn: 1 })
  const endDate = endOfWeek(monthEnd, { weekStartsOn: 1 })

  const prevMonth = () => setCurrentMonth(subMonths(currentMonth, 1))
  const nextMonth = () => setCurrentMonth(addMonths(currentMonth, 1))

  const getEventsForDate = (date: Date) => {
    return events.filter((e) => {
      const matchesDate = e.date === format(date, 'yyyy-MM-dd')
      const matchesStudent = selectedStudentIds.length === 0 || selectedStudentIds.includes(e.studentId)
      return matchesDate && matchesStudent
    })
  }

  // Filtered events for stats
  const filteredEvents = selectedStudentIds.length === 0
    ? events
    : events.filter(e => selectedStudentIds.includes(e.studentId))

  const selectedDateEvents = getEventsForDate(selectedDate)

  // Generate calendar days
  const days: Date[] = []
  let day = startDate
  while (day <= endDate) {
    days.push(day)
    day = addDays(day, 1)
  }

  // Stats (use filtered events)
  const todayEvents = getEventsForDate(new Date())
  const weekEvents = filteredEvents.filter(e => {
    const eventDate = new Date(e.date)
    const now = new Date()
    const weekFromNow = addDays(now, 7)
    return eventDate >= now && eventDate <= weekFromNow
  })

  return (
    <div className="min-h-screen">
      <Header
        title="Calendrier"
        subtitle="Gérez vos rendez-vous et événements"
        showSearch={false}
        action={
          <button
            onClick={() => setIsCreateModalOpen(true)}
            className={cn(
              'flex items-center gap-2 h-11 px-5 rounded-xl font-semibold text-white',
              'bg-gradient-to-r from-accent to-[#ff8f5c]',
              'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
              'transition-all duration-300'
            )}
          >
            <Plus className="w-5 h-5" />
            Nouvel événement
          </button>
        }
      />

      <div className="p-8 space-y-6">
        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-4">
          {[
            { label: 'Aujourd\'hui', value: todayEvents.length, icon: Calendar, color: 'accent' },
            { label: 'Cette semaine', value: weekEvents.length, icon: Clock, color: 'info' },
            { label: 'Élèves actifs', value: students.length, icon: Users, color: 'success' },
          ].map((stat, index) => (
            <div
              key={stat.label}
              className={cn(
                'flex items-center gap-4 p-4 rounded-xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out_forwards] opacity-0'
              )}
              style={{ animationDelay: `${index * 50}ms` }}
            >
              <div className={cn(
                'w-12 h-12 rounded-xl flex items-center justify-center',
                stat.color === 'accent' ? 'bg-accent/10' :
                stat.color === 'info' ? 'bg-info/10' : 'bg-success/10'
              )}>
                <stat.icon className={cn(
                  'w-6 h-6',
                  stat.color === 'accent' ? 'text-accent' :
                  stat.color === 'info' ? 'text-info' : 'text-success'
                )} />
              </div>
              <div>
                <p className="text-2xl font-bold text-text-primary">{stat.value}</p>
                <p className="text-sm text-text-muted">{stat.label}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Student Filter */}
        <div className="flex items-center gap-3 p-4 rounded-xl bg-surface border border-border">
          <span className="text-sm font-medium text-text-secondary">Filtrer par élève :</span>
          <div className="flex items-center gap-2 flex-wrap">
            {students.map((student) => {
              const isSelected = selectedStudentIds.includes(student.id)
              return (
                <button
                  key={student.id}
                  onClick={() => toggleStudentFilter(student.id)}
                  className={cn(
                    'flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm font-medium transition-all duration-200',
                    isSelected
                      ? 'bg-accent text-white'
                      : 'bg-surface-elevated text-text-secondary hover:text-text-primary hover:bg-surface-elevated/80'
                  )}
                >
                  <div className={cn(
                    'w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold text-white',
                    isSelected ? 'bg-white/20' : 'bg-accent'
                  )}>
                    {student.name.split(' ').map(n => n[0]).join('')}
                  </div>
                  {student.name}
                </button>
              )
            })}
            {selectedStudentIds.length > 0 && (
              <button
                onClick={clearStudentFilter}
                className="px-3 py-1.5 rounded-lg text-sm font-medium text-text-muted hover:text-text-primary transition-colors"
              >
                Effacer
              </button>
            )}
          </div>
        </div>

        <div className="grid grid-cols-4 gap-6">
          {/* Calendar */}
          <div className={cn(
            'col-span-3 p-6 rounded-2xl',
            'bg-surface border border-border',
            'animate-[fadeIn_0.4s_ease-out]'
          )}>
            {/* Month navigation */}
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-semibold text-text-primary capitalize">
                {format(currentMonth, 'MMMM yyyy', { locale: fr })}
              </h2>
              <div className="flex items-center gap-2">
                <button
                  onClick={prevMonth}
                  className={cn(
                    'p-2 rounded-lg transition-all duration-200',
                    'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
                  )}
                >
                  <ChevronLeft className="w-5 h-5" />
                </button>
                <button
                  onClick={() => {
                    setCurrentMonth(new Date())
                    setSelectedDate(new Date())
                  }}
                  className={cn(
                    'px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200',
                    'text-accent hover:bg-accent/10'
                  )}
                >
                  Aujourd'hui
                </button>
                <button
                  onClick={nextMonth}
                  className={cn(
                    'p-2 rounded-lg transition-all duration-200',
                    'text-text-muted hover:text-text-primary hover:bg-surface-elevated'
                  )}
                >
                  <ChevronRight className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Weekday headers */}
            <div className="grid grid-cols-7 mb-2">
              {['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((d) => (
                <div
                  key={d}
                  className="text-center text-sm font-medium text-text-muted py-3"
                >
                  {d}
                </div>
              ))}
            </div>

            {/* Calendar grid */}
            <div className="grid grid-cols-7 gap-1">
              {days.map((date, i) => {
                const dayEvents = getEventsForDate(date)
                const isSelected = isSameDay(date, selectedDate)
                const isCurrentMonth = isSameMonth(date, currentMonth)
                const isTodayDate = isToday(date)

                return (
                  <button
                    key={i}
                    onClick={() => setSelectedDate(date)}
                    className={cn(
                      'relative aspect-square p-2 rounded-xl text-left transition-all duration-200',
                      isSelected
                        ? 'bg-accent/10 border-2 border-accent shadow-[0_0_20px_rgba(255,107,53,0.1)]'
                        : 'border border-transparent hover:bg-surface-elevated hover:border-border',
                      !isCurrentMonth && 'opacity-30'
                    )}
                  >
                    <span
                      className={cn(
                        'text-sm font-medium inline-flex items-center justify-center',
                        isTodayDate && 'w-7 h-7 rounded-full bg-gradient-to-br from-accent to-[#ff8f5c] text-white shadow-md shadow-accent/30',
                        isSelected && !isTodayDate && 'text-accent',
                        !isSelected && !isTodayDate && 'text-text-primary'
                      )}
                    >
                      {format(date, 'd')}
                    </span>
                    {dayEvents.length > 0 && (
                      <div className="absolute bottom-2 left-2 right-2 space-y-0.5">
                        {dayEvents.slice(0, 2).map((event) => {
                          const config = eventTypeConfig[event.type] || eventTypeConfig.other
                          return (
                            <div
                              key={event.id}
                              className={cn(
                                'text-[10px] px-1.5 py-0.5 rounded truncate font-medium',
                                config.color === 'accent' && 'bg-accent/20 text-accent',
                                config.color === 'success' && 'bg-success/20 text-success',
                                config.color === 'info' && 'bg-info/20 text-info',
                                config.color === 'warning' && 'bg-warning/20 text-warning'
                              )}
                            >
                              {event.title.split(' - ')[0]}
                            </div>
                          )
                        })}
                        {dayEvents.length > 2 && (
                          <div className="text-[10px] text-text-muted text-center">
                            +{dayEvents.length - 2} autres
                          </div>
                        )}
                      </div>
                    )}
                  </button>
                )
              })}
            </div>
          </div>

          {/* Selected day events */}
          <div className={cn(
            'p-6 rounded-2xl',
            'bg-surface border border-border',
            'animate-[fadeIn_0.4s_ease-out]'
          )}>
            {/* Header */}
            <div className="flex items-center gap-3 mb-6">
              <div className={cn(
                'w-12 h-12 rounded-xl flex items-center justify-center',
                'bg-gradient-to-br from-accent/20 to-accent/5'
              )}>
                <Calendar className="w-6 h-6 text-accent" />
              </div>
              <div>
                <h3 className="font-semibold text-text-primary capitalize">
                  {format(selectedDate, 'EEEE', { locale: fr })}
                </h3>
                <p className="text-sm text-text-muted">
                  {format(selectedDate, 'd MMMM yyyy', { locale: fr })}
                </p>
              </div>
            </div>

            {/* Event type legend */}
            <div className="flex flex-wrap gap-2 mb-6">
              {Object.entries(eventTypeConfig).filter(([key]) => key !== 'other').map(([type, config]) => (
                <div
                  key={type}
                  className={cn(
                    'flex items-center gap-1.5 px-2 py-1 rounded-lg text-xs font-medium',
                    config.color === 'accent' && 'bg-accent/10 text-accent',
                    config.color === 'success' && 'bg-success/10 text-success',
                    config.color === 'info' && 'bg-info/10 text-info'
                  )}
                >
                  <config.icon className="w-3 h-3" />
                  {config.label}
                </div>
              ))}
            </div>

            {selectedDateEvents.length > 0 ? (
              <div className="space-y-3">
                {selectedDateEvents.map((event, index) => {
                  const config = eventTypeConfig[event.type] || eventTypeConfig.other
                  const student = students.find((s) => s.id === event.studentId)

                  return (
                    <div
                      key={event.id}
                      onClick={() => handleEditEvent(event)}
                      className={cn(
                        'group p-4 rounded-xl transition-all duration-200 cursor-pointer',
                        'bg-surface-elevated border border-border',
                        'hover:border-accent/30 hover:shadow-md',
                        'animate-[fadeIn_0.3s_ease-out]',
                        event.completed && 'opacity-60'
                      )}
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <div className="flex items-start gap-3">
                        <div
                          className={cn(
                            'w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0',
                            config.color === 'accent' && 'bg-accent/20',
                            config.color === 'success' && 'bg-success/20',
                            config.color === 'info' && 'bg-info/20',
                            config.color === 'warning' && 'bg-warning/20'
                          )}
                        >
                          <config.icon className={cn(
                            'w-4 h-4',
                            config.color === 'accent' && 'text-accent',
                            config.color === 'success' && 'text-success',
                            config.color === 'info' && 'text-info',
                            config.color === 'warning' && 'text-warning'
                          )} />
                        </div>
                        <div className="flex-1 min-w-0 overflow-hidden">
                          <p className={cn(
                            'font-semibold text-text-primary text-sm truncate',
                            event.completed && 'line-through'
                          )}>
                            {event.title}
                          </p>
                          <div className="flex items-center gap-2 mt-1">
                            <span className="flex items-center gap-1 text-xs text-text-muted flex-shrink-0">
                              <Clock className="w-3 h-3" />
                              {event.time}
                            </span>
                            {student && (
                              <span className="text-[10px] text-text-muted truncate">
                                {student.name}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>

                      {/* Actions */}
                      <div className="flex items-center justify-between mt-3 pt-3 border-t border-border/50">
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            toggleComplete(event.id)
                          }}
                          className={cn(
                            'flex items-center gap-1 px-2 py-1 rounded-md text-[11px] font-medium transition-colors',
                            event.completed
                              ? 'bg-success/10 text-success'
                              : 'bg-surface text-text-muted hover:text-success hover:bg-success/10'
                          )}
                        >
                          <Check className="w-3 h-3" />
                          {event.completed ? 'Terminé' : 'Terminer'}
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            deleteEvent(event.id)
                          }}
                          className="p-1 rounded-md text-text-muted hover:text-error hover:bg-error/10 transition-colors"
                        >
                          <Trash2 className="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                  )
                })}
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center py-12">
                <div className="w-16 h-16 rounded-2xl bg-surface-elevated flex items-center justify-center mb-4">
                  <Calendar className="w-8 h-8 text-text-muted" />
                </div>
                <p className="text-text-secondary font-medium mb-1">
                  Aucun événement
                </p>
                <p className="text-sm text-text-muted text-center">
                  Pas d'événement prévu ce jour
                </p>
              </div>
            )}

            {/* Add button */}
            <button
              onClick={() => setIsCreateModalOpen(true)}
              className={cn(
                'w-full flex items-center justify-center gap-2 h-11 mt-6 rounded-xl',
                'font-medium transition-all duration-200',
                'border-2 border-dashed border-border',
                'text-text-muted hover:text-accent hover:border-accent/30 hover:bg-accent/5'
              )}
            >
              <Plus className="w-4 h-4" />
              Ajouter un événement
            </button>
          </div>
        </div>
      </div>

      {/* Create Event Modal */}
      <CreateEventModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        selectedDate={selectedDate}
      />

      {/* Edit Event Modal */}
      <EditEventModal
        isOpen={isEditModalOpen}
        onClose={() => {
          setIsEditModalOpen(false)
          setSelectedEvent(null)
        }}
        event={selectedEvent}
      />
    </div>
  )
}
