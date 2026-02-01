import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

import { AppShell } from '@/components/layout'
import { LoginPage } from '@/pages/auth/login-page'
import { DashboardPage } from '@/pages/dashboard/dashboard-page'
import { StudentsListPage } from '@/pages/students/students-list-page'
import { StudentProfilePage } from '@/pages/students/student-profile-page'
import { ProgramsListPage } from '@/pages/programs/programs-list-page'
import { ProgramCreatePage } from '@/pages/programs/program-create-page'
import { ProgramDetailPage } from '@/pages/programs/program-detail-page'
import { NutritionListPage } from '@/pages/nutrition/nutrition-list-page'
import { NutritionCreatePage } from '@/pages/nutrition/nutrition-create-page'
import { NutritionDetailPage } from '@/pages/nutrition/nutrition-detail-page'
import { CalendarPage } from '@/pages/calendar/calendar-page'
import { MessagesPage } from '@/pages/messages/messages-page'
import { SettingsPage } from '@/pages/settings/settings-page'

const queryClient = new QueryClient()

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          {/* Auth */}
          <Route path="/login" element={<LoginPage />} />

          {/* Protected routes */}
          <Route element={<AppShell />}>
            <Route path="/" element={<DashboardPage />} />

            {/* Students */}
            <Route path="/students" element={<StudentsListPage />} />
            <Route path="/students/:id" element={<StudentProfilePage />} />

            {/* Programs */}
            <Route path="/programs" element={<ProgramsListPage />} />
            <Route path="/programs/create" element={<ProgramCreatePage />} />
            <Route path="/programs/:id" element={<ProgramDetailPage />} />

            {/* Nutrition */}
            <Route path="/nutrition" element={<NutritionListPage />} />
            <Route path="/nutrition/create" element={<NutritionCreatePage />} />
            <Route path="/nutrition/:id" element={<NutritionDetailPage />} />

            {/* Calendar */}
            <Route path="/calendar" element={<CalendarPage />} />

            {/* Messages */}
            <Route path="/messages" element={<MessagesPage />} />

            {/* Settings */}
            <Route path="/settings" element={<SettingsPage />} />
          </Route>

          {/* Fallback */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}

export default App
