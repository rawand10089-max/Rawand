import React, { useState, useEffect } from 'react';
import { Navbar } from './components/Navbar';
import { DailyBriefingBanner } from './components/DailyBriefingBanner';
import { TaskList } from './components/Tasks/TaskList';
import { StudyScheduler } from './components/Schedule/StudyScheduler';
import { PomodoroRoom } from './components/Focus/PomodoroRoom';
import { AiAssistantView } from './components/Assistant/AiAssistantView';
import { ProgressStats } from './components/Analytics/ProgressStats';
import { 
  Task, 
  StudySessionBlock, 
  SubjectItem, 
  PomodoroSettings, 
  StudyStats,
  StudyLogEntry,
  StudyGoal
} from './types';
import { 
  INITIAL_TASKS, 
  INITIAL_SCHEDULE, 
  INITIAL_SUBJECTS, 
  DEFAULT_POMODORO_SETTINGS, 
  INITIAL_STATS,
  INITIAL_STUDY_LOGS,
  INITIAL_GOALS
} from './utils/initialData';

export default function App() {
  const [isDarkMode, setIsDarkMode] = useState<boolean>(() => {
    const saved = localStorage.getItem('monjez_dark_mode');
    return saved !== null ? saved === 'true' : window.matchMedia('(prefers-color-scheme: dark)').matches;
  });

  useEffect(() => {
    if (isDarkMode) document.documentElement.classList.add('dark');
    else document.documentElement.classList.remove('dark');
    localStorage.setItem('monjez_dark_mode', String(isDarkMode));
  }, [isDarkMode]);

  const [activeTab, setActiveTab] = useState<'tasks' | 'schedule' | 'focus' | 'assistant' | 'analytics'>('tasks');
  const [isWizardOpen, setIsWizardOpen] = useState(false);

  const [tasks, setTasks] = useState<Task[]>(() => {
    const s = localStorage.getItem('monjez_tasks');
    return s ? JSON.parse(s) : INITIAL_TASKS;
  });

  const [schedule, setSchedule] = useState<StudySessionBlock[]>(() => {
    const s = localStorage.getItem('monjez_schedule');
    return s ? JSON.parse(s) : INITIAL_SCHEDULE;
  });

  const [subjects, setSubjects] = useState<SubjectItem[]>(() => {
    const s = localStorage.getItem('monjez_subjects');
    return s ? JSON.parse(s) : INITIAL_SUBJECTS;
  });

  const [studyLogs, setStudyLogs] = useState<StudyLogEntry[]>(() => {
    const s = localStorage.getItem('monjez_study_logs');
    return s ? JSON.parse(s) : INITIAL_STUDY_LOGS;
  });

  const [goals, setGoals] = useState<StudyGoal[]>(() => {
    const s = localStorage.getItem('monjez_goals');
    return s ? JSON.parse(s) : INITIAL_GOALS;
  });

  const [pomodoroSettings, setPomodoroSettings] = useState<PomodoroSettings>(() => {
    const s = localStorage.getItem('monjez_pomodoro_settings');
    return s ? JSON.parse(s) : DEFAULT_POMODORO_SETTINGS;
  });

  const [stats, setStats] = useState<StudyStats>(() => {
    const s = localStorage.getItem('monjez_stats');
    return s ? JSON.parse(s) : INITIAL_STATS;
  });

  const [activeFocusItem, setActiveFocusItem] = useState<{
    type: 'task' | 'session' | 'free';
    item?: Task | StudySessionBlock;
  }>({ type: 'free' });

  useEffect(() => localStorage.setItem('monjez_tasks', JSON.stringify(tasks)), [tasks]);
  useEffect(() => localStorage.setItem('monjez_schedule', JSON.stringify(schedule)), [schedule]);
  useEffect(() => localStorage.setItem('monjez_subjects', JSON.stringify(subjects)), [subjects]);
  useEffect(() => localStorage.setItem('monjez_study_logs', JSON.stringify(studyLogs)), [studyLogs]);
  useEffect(() => localStorage.setItem('monjez_goals', JSON.stringify(goals)), [goals]);
  useEffect(() => localStorage.setItem('monjez_pomodoro_settings', JSON.stringify(pomodoroSettings)), [pomodoroSettings]);
  useEffect(() => localStorage.setItem('monjez_stats', JSON.stringify(stats)), [stats]);

  const todayStr = new Date().toISOString().split('T')[0];

  const handleToggleTask = (id: string) => {
    setTasks(prev => prev.map(t => {
      if (t.id === id) {
        const nextCompleted = !t.completed;
        if (nextCompleted) {
          setStats(s => ({ ...s, completedTasksCount: s.completedTasksCount + 1 }));
        }
        return { ...t, completed: nextCompleted, completedAt: nextCompleted ? new Date().toISOString() : undefined };
      }
      return t;
    }));
  };

  const handleToggleSubtask = (taskId: string, subtaskId: string) => {
    setTasks(prev => prev.map(t => {
      if (t.id === taskId) {
        const subtasks = t.subtasks.map(st => st.id === subtaskId ? { ...st, completed: !st.completed } : st);
        return { ...t, subtasks, completed: subtasks.length > 0 && subtasks.every(s => s.completed) };
      }
      return t;
    }));
  };

  const handleAddStudyLog = (logData: Omit<StudyLogEntry, 'id' | 'createdAt'>) => {
    const newEntry: StudyLogEntry = { ...logData, id: `log-${Date.now()}`, createdAt: new Date().toISOString() };
    setStudyLogs(prev => [newEntry, ...prev]);
    setStats(prev => {
      let nextStreak = prev.streakDays;
      if (prev.lastActiveDate !== todayStr && newEntry.date === todayStr) nextStreak += 1;
      return {
        ...prev,
        totalMinutesStudied: prev.totalMinutesStudied + newEntry.minutes,
        streakDays: nextStreak,
        lastActiveDate: todayStr,
      };
    });
  };

  const handleStartFocus = (item: Task | StudySessionBlock) => {
    setActiveFocusItem({ type: 'category' in item ? 'task' : 'session', item });
    setActiveTab('focus');
  };

  const handleLogCompletedSession = (minutes: number, subject?: string, topic?: string) => {
    handleAddStudyLog({
      subject: subject || (subjects[0]?.name || 'المذاكرة العامة'),
      minutes,
      date: todayStr,
      startTime: new Date().toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' }),
      topic: topic || 'جلسة تركيز بومودورو',
      focusRating: 5,
      source: 'pomodoro',
    });
  };

  const todayMinutes = stats.history[todayStr]?.minutesStudied || 0;
  const pendingTasksCount = tasks.filter(t => !t.completed).length;

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 flex flex-col font-sans transition-colors duration-200">
      <Navbar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        streakDays={stats.streakDays}
        todayMinutes={todayMinutes}
        pendingTasksCount={pendingTasksCount}
        isDarkMode={isDarkMode}
        toggleDarkMode={() => setIsDarkMode(!isDarkMode)}
        onOpenScheduleWizard={() => setIsWizardOpen(true)}
      />

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-6">
        <DailyBriefingBanner
          tasks={tasks}
          scheduleSlots={schedule.filter(s => s.date === todayStr)}
          streakDays={stats.streakDays}
          todayMinutes={todayMinutes}
        />

        {activeTab === 'tasks' && (
          <TaskList
            tasks={tasks}
            subjects={subjects}
            onToggleTask={handleToggleTask}
            onToggleSubtask={handleToggleSubtask}
            onAddTask={(d) => setTasks([{ ...d, id: `task-${Date.now()}`, completed: false, subtasks: d.subtasks || [], createdAt: new Date().toISOString() }, ...tasks])}
            onUpdateTask={(t) => setTasks(tasks.map(i => i.id === t.id ? t : i))}
            onDeleteTask={(id) => setTasks(tasks.filter(t => t.id !== id))}
            onStartFocus={handleStartFocus}
          />
        )}

        {activeTab === 'schedule' && (
          <StudyScheduler
            schedule={schedule}
            subjects={subjects}
            onAddSession={(s) => setSchedule([...schedule, s])}
            onUpdateSession={(s) => setSchedule(schedule.map(i => i.id === s.id ? s : i))}
            onDeleteSession={(id) => setSchedule(schedule.filter(s => s.id !== id))}
            onToggleSessionComplete={(id) => setSchedule(schedule.map(s => s.id === id ? { ...s, status: s.status === 'completed' ? 'scheduled' : 'completed' } : s))}
            onStartFocus={handleStartFocus}
            isWizardOpen={isWizardOpen}
            setIsWizardOpen={setIsWizardOpen}
          />
        )}

        {activeTab === 'focus' && (
          <PomodoroRoom
            settings={pomodoroSettings}
            onUpdateSettings={setPomodoroSettings}
            activeFocusItem={activeFocusItem}
            onClearActiveItem={() => setActiveFocusItem({ type: 'free' })}
            onLogCompletedSession={handleLogCompletedSession}
            onMarkTaskCompleted={handleToggleTask}
            onMarkSessionCompleted={(id) => setSchedule(schedule.map(s => s.id === id ? { ...s, status: 'completed' } : s))}
          />
        )}

        {activeTab === 'assistant' && (
          <AiAssistantView
            tasks={tasks}
            schedule={schedule}
            streakDays={stats.streakDays}
            todayMinutes={todayMinutes}
            onOpenScheduleWizard={() => setIsWizardOpen(true)}
          />
        )}

        {activeTab === 'analytics' && (
          <ProgressStats
            stats={stats}
            subjects={subjects}
            tasks={tasks}
            schedule={schedule}
            studyLogs={studyLogs}
            goals={goals}
            onAddStudyLog={handleAddStudyLog}
            onDeleteStudyLog={(id) => setStudyLogs(studyLogs.filter(l => l.id !== id))}
            onAddGoal={(g) => setGoals([...goals, { ...g, id: `goal-${Date.now()}`, createdAt: new Date().toISOString() }])}
            onDeleteGoal={(id) => setGoals(goals.filter(g => g.id !== id))}
            onUpdateGoalTarget={(id, target) => setGoals(goals.map(g => g.id === id ? { ...g, targetValue: target } : g))}
          />
        )}
      </main>

      <footer className="border-t border-slate-200 dark:border-slate-800/80 py-6 text-center text-xs text-slate-500">
        مُنجِز (Monjez) • المساعد الشخصي لتنظيم المهام وجدولة وقت المذاكرة
      </footer>
    </div>
  );
}