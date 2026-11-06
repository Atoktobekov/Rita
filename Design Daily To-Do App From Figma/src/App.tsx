import { useMemo, useState } from 'react'

type Task = { id: number; text: string; done: boolean }
type Day = { date: string; label: string; tasks: Task[] }
type Tab = 'today' | 'history' | 'stats' | 'awards'

const I = ({ d, className = 'w-6 h-6', fill = 'none', sw = 1.8 }: { d: string; className?: string; fill?: string; sw?: number }) => (
  <svg viewBox="0 0 24 24" className={className} fill={fill} stroke="currentColor" strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"><path d={d} /></svg>
)
const P = {
  check: 'M5 12.5l4.5 4.5L19 7.5',
  plus: 'M12 5v14M5 12h14',
  sun: 'M12 4V2m0 20v-2m8-8h2M2 12h2m13.7-5.7l1.4-1.4M4.9 19.1l1.4-1.4m0-11.4L4.9 4.9m14.2 14.2l-1.4-1.4M12 8a4 4 0 100 8 4 4 0 000-8z',
  archive: 'M4 7h16v3H4zM5 10v9h14v-9M10 14h4',
  chart: 'M5 20V10m7 10V4m7 16v-7',
  trophy: 'M8 4h8v6a4 4 0 01-8 0V4zM8 6H4v1a4 4 0 004 4m8-5h4v1a4 4 0 01-4 4M12 14v4m-3 2h6',
  bell: 'M6 16V11a6 6 0 1112 0v5l2 2H4l2-2zm4 4a2 2 0 004 0',
  moon: 'M20 14.5A8 8 0 019.5 4a8 8 0 1010.5 10.5z',
  trash: 'M5 7h14M10 7V4h4v3m-7 0l1 13h8l1-13',
  flame: 'M12 3c1 4 5 5.5 5 10a5 5 0 01-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-6 1-9z',
  chev: 'M9 6l6 6-6 6',
}

const mk = (t: [string, boolean][]) => t.map(([text, done], i) => ({ id: i + 1, text, done }))
const HISTORY: Day[] = [
  { date: '2025-01-14', label: 'Вчера', tasks: mk([['Зарядка 15 минут', true], ['Прочитать 20 страниц', true], ['Выучить урок по Dart', true], ['Позвонить родителям', false]]) },
  { date: '2025-01-13', label: '13 января', tasks: mk([['Пробежка', true], ['Разобрать почту', true], ['Закончить экран профиля', true]]) },
  { date: '2025-01-12', label: '12 января', tasks: mk([['Медитация', true], ['Приготовить ужин', false], ['Виджет списка задач', true], ['Растяжка', false], ['Выпить 2 л воды', true]]) },
  { date: '2025-01-11', label: '11 января', tasks: mk([['Прогулка', false], ['Тема про состояние во Flutter', true]]) },
  { date: '2025-01-10', label: '10 января', tasks: mk([['Hive: хранение данных', true], ['Зарядка', true], ['Чтение', true], ['Уборка', true]]) },
]

const pct = (t: Task[]) => (t.length ? Math.round((t.filter((x) => x.done).length / t.length) * 100) : 0)

function Ring({ value, size = 120, stroke = 12, children }: { value: number; size?: number; stroke?: number; children?: React.ReactNode }) {
  const r = (size - stroke) / 2, c = 2 * Math.PI * r
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(43,33,22,.12)" strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#2b2116" strokeWidth={stroke} strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={c * (1 - value / 100)} style={{ transition: 'stroke-dashoffset .6s ease' }} />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">{children}</div>
    </div>
  )
}

function Check({ done, onClick }: { done: boolean; onClick: () => void }) {
  return (
    <button onClick={onClick} aria-label="Выполнено"
      className={`w-7 h-7 rounded-full border-2 grid place-items-center shrink-0 transition-colors ${done ? 'bg-moss border-moss text-ink' : 'border-ink/25 text-transparent'}`}>
      {done && <span className="pop"><I d={P.check} className="w-4 h-4" sw={3} /></span>}
    </button>
  )
}

export default function App() {
  const [tab, setTab] = useState<Tab>('today')
  const [tasks, setTasks] = useState<Task[]>(mk([['Зарядка 15 минут', true], ['Сделать экран статистики', false], ['Прочитать 20 страниц', false], ['Выпить 2 л воды', true]]))
  const [draft, setDraft] = useState('')
  const [remind, setRemind] = useState(true)
  const [time, setTime] = useState('21:30')
  const [open, setOpen] = useState<string | null>(null)

  const add = () => {
    if (!draft.trim()) return
    setTasks((t) => [...t, { id: Date.now(), text: draft.trim(), done: false }])
    setDraft('')
  }
  const toggle = (id: number) => setTasks((t) => t.map((x) => (x.id === id ? { ...x, done: !x.done } : x)))

  const all = useMemo(() => [{ date: 'today', label: 'Сегодня', tasks }, ...HISTORY], [tasks])
  const total = all.reduce((s, d) => s + d.tasks.length, 0)
  const doneN = all.reduce((s, d) => s + d.tasks.filter((x) => x.done).length, 0)
  const rate = total ? Math.round((doneN / total) * 100) : 0
  const todayP = pct(tasks)
  const streak = HISTORY.filter((d) => pct(d.tasks) >= 50).length + (todayP >= 50 ? 1 : 0)

  const awards = [
    { t: 'Первый шаг', d: 'Выполни первую задачу', ok: doneN >= 1, g: '1' },
    { t: 'Десятка', d: '10 выполненных задач', ok: doneN >= 10, g: '10' },
    { t: 'Идеальный день', d: '100% за один день', ok: all.some((d) => d.tasks.length > 0 && pct(d.tasks) === 100), g: '100' },
    { t: 'Серия 3 дня', d: 'Три дня подряд от 50%', ok: streak >= 3, g: '3д' },
    { t: 'Неделя силы', d: 'Серия 7 дней', ok: streak >= 7, g: '7д' },
    { t: 'Полсотни', d: '50 выполненных задач', ok: doneN >= 50, g: '50' },
  ]
  const got = awards.filter((a) => a.ok).length

  const tabs: { id: Tab; l: string; d: string }[] = [
    { id: 'today', l: 'Сегодня', d: P.sun },
    { id: 'history', l: 'Архив', d: P.archive },
    { id: 'stats', l: 'Статистика', d: P.chart },
    { id: 'awards', l: 'Ачивки', d: P.trophy },
  ]

  return (
    <div className="min-h-screen grid place-items-center sm:p-6">
      <div className="relative w-full sm:w-[390px] h-screen sm:h-[800px] sm:rounded-[44px] sm:border-[10px] border-ink bg-paper overflow-hidden flex flex-col shadow-2xl">
        <div className="flex justify-between items-center px-7 pt-3 text-xs font-semibold text-ink/70 shrink-0">
          <span>9:41</span><span className="hidden sm:block w-24 h-6 rounded-full bg-ink absolute left-1/2 -translate-x-1/2 top-2" /><span>100%</span>
        </div>

        <main key={tab} className="flex-1 overflow-y-auto px-5 pt-5 pb-28 rise [scrollbar-width:none]">
          {tab === 'today' && (
            <>
              <p className="text-sm text-ink/55 font-medium">Среда, 15 января</p>
              <h1 className="font-serif text-[34px] leading-tight mt-1">Твой день</h1>

              <section className="mt-5 rounded-[28px] bg-moss text-ink p-5 flex items-center gap-5 relative overflow-hidden">
                <div className="absolute -right-10 -top-10 w-40 h-40 rounded-full bg-white/30" />
                <Ring value={todayP} size={104} stroke={11}>
                  <span className="font-serif text-2xl">{todayP}%</span>
                </Ring>
                <div className="relative">
                  <p className="text-ink/65 text-sm">Выполнено</p>
                  <p className="font-serif text-3xl">{tasks.filter((t) => t.done).length} из {tasks.length}</p>
                  <p className="text-sm mt-2 flex items-center gap-1 text-ink"><I d={P.flame} className="w-4 h-4" fill="currentColor" sw={1} /> Серия: {streak} дн.</p>
                </div>
              </section>

              <div className="mt-4 rounded-2xl bg-sand/70 px-4 py-3 flex items-center gap-3">
                <span className="w-9 h-9 rounded-full bg-card grid place-items-center text-ink"><I d={P.bell} className="w-5 h-5" /></span>
                <div className="flex-1 leading-tight">
                  <p className="text-sm font-semibold">Вечернее напоминание</p>
                  <p className="text-xs text-ink/55">{remind ? 'Заполнить план на завтра' : 'Выключено'}</p>
                </div>
                {remind && (
                  <select value={time} onChange={(e) => setTime(e.target.value)} className="text-sm font-bold bg-card border border-ink/5 rounded-lg px-2 py-1 outline-none">
                    {['21:00', '21:30', '22:00'].map((t) => <option key={t}>{t}</option>)}
                  </select>
                )}
                <button onClick={() => setRemind(!remind)} role="switch" aria-checked={remind} className={`w-11 h-6 rounded-full p-0.5 transition-colors ${remind ? 'bg-moss' : 'bg-ink/20'}`}>
                  <span className={`block w-5 h-5 rounded-full bg-white shadow transition-transform ${remind ? 'translate-x-5' : ''}`} />
                </button>
              </div>

              <h2 className="mt-7 mb-3 text-xs font-bold tracking-widest text-ink/45 uppercase">Задачи</h2>
              <ul className="space-y-2.5">
                {tasks.map((t) => (
                  <li key={t.id} className="group flex items-center gap-3 bg-card border border-ink/5 rounded-2xl px-4 py-3.5 shadow-[0_1px_0_rgba(0,0,0,.04)]">
                    <Check done={t.done} onClick={() => toggle(t.id)} />
                    <span className={`flex-1 text-[15px] font-medium transition-all ${t.done ? 'line-through text-ink/35' : ''}`}>{t.text}</span>
                    <button onClick={() => setTasks((x) => x.filter((y) => y.id !== t.id))} aria-label="Удалить" className="text-ink/25 hover:text-ink"><I d={P.trash} className="w-4.5 h-4.5" /></button>
                  </li>
                ))}
                {!tasks.length && <li className="text-center text-ink/45 py-8 text-sm">Пока пусто. Запланируй свой день.</li>}
              </ul>

              <form onSubmit={(e) => { e.preventDefault(); add() }} className="mt-3 flex items-center gap-2 border-2 border-dashed border-ink/20 rounded-2xl pl-4 pr-1.5 py-1.5 focus-within:border-moss">
                <input value={draft} onChange={(e) => setDraft(e.target.value)} placeholder="Новая задача…" className="flex-1 bg-transparent outline-none text-[15px] py-2" />
                <button type="submit" aria-label="Добавить" className="w-10 h-10 rounded-xl bg-clay text-ink grid place-items-center"><I d={P.plus} /></button>
              </form>

              <p className="mt-6 flex items-center justify-center gap-2 text-xs text-ink/45"><I d={P.moon} className="w-4 h-4" /> После полуночи карточка уйдёт в архив</p>
            </>
          )}

          {tab === 'history' && (
            <>
              <h1 className="font-serif text-[34px] leading-tight">Архив</h1>
              <p className="text-sm text-ink/55 mt-1">Прошедшие дни можно редактировать</p>
              <div className="mt-5 space-y-3">
                {HISTORY.map((d) => {
                  const p = pct(d.tasks), isOpen = open === d.date
                  return (
                    <div key={d.date} className="bg-card border border-ink/5 rounded-3xl overflow-hidden">
                      <button onClick={() => setOpen(isOpen ? null : d.date)} className="w-full flex items-center gap-4 p-4 text-left">
                        <div className="w-14 h-14 rounded-2xl grid place-items-center font-serif text-lg shrink-0" style={{ background: `color-mix(in srgb, var(--color-moss) ${Math.max(p, 12)}%, var(--color-sage))`, color: 'var(--color-ink)' }}>{p}%</div>
                        <div className="flex-1">
                          <p className="font-semibold">{d.label}</p>
                          <p className="text-xs text-ink/50">{d.tasks.filter((t) => t.done).length} из {d.tasks.length} задач</p>
                        </div>
                        <span className={`text-ink/30 transition-transform ${isOpen ? 'rotate-90' : ''}`}><I d={P.chev} className="w-5 h-5" /></span>
                      </button>
                      {isOpen && (
                        <ul className="px-4 pb-4 space-y-2 rise">
                          {d.tasks.map((t) => (
                            <li key={t.id} className="flex items-center gap-3 text-sm">
                              <span className={`w-5 h-5 rounded-full grid place-items-center ${t.done ? 'bg-moss text-ink' : 'border-2 border-ink/20'}`}>{t.done && <I d={P.check} className="w-3 h-3" sw={3.5} />}</span>
                              <span className={t.done ? 'text-ink/50 line-through' : ''}>{t.text}</span>
                            </li>
                          ))}
                        </ul>
                      )}
                    </div>
                  )
                })}
              </div>
            </>
          )}

          {tab === 'stats' && (
            <>
              <h1 className="font-serif text-[34px] leading-tight">Статистика</h1>
              <section className="mt-5 rounded-[28px] bg-moss text-ink p-6 flex items-center gap-6">
                <Ring value={rate} size={116} stroke={12}><span className="font-serif text-3xl">{rate}%</span></Ring>
                <div><p className="text-ink/65 text-sm">Процент выполнения</p><p className="font-serif text-xl leading-snug mt-1">{rate >= 70 ? 'Отличный темп!' : 'Есть куда расти'}</p></div>
              </section>
              <div className="grid grid-cols-2 gap-3 mt-3">
                <div className="bg-card border border-ink/5 rounded-3xl p-5"><p className="text-xs text-ink/50 font-semibold">Всего задач</p><p className="font-serif text-4xl mt-2">{total}</p></div>
                <div className="bg-card border border-ink/5 rounded-3xl p-5"><p className="text-xs text-ink/50 font-semibold">Выполнено</p><p className="font-serif text-4xl mt-2 text-ink">{doneN}</p></div>
              </div>
              <section className="bg-card border border-ink/5 rounded-3xl p-5 mt-3">
                <p className="text-sm font-bold mb-4">Последние 6 дней</p>
                <div className="flex items-end justify-between h-36 gap-2">
                  {[...all].slice(0, 6).reverse().map((d) => {
                    const p = pct(d.tasks)
                    return (
                      <div key={d.date} className="flex-1 flex flex-col items-center gap-2 h-full justify-end">
                        <span className="text-[10px] font-bold text-ink/50">{p}</span>
                        <div className={`w-full rounded-t-xl ${d.date === 'today' ? 'bg-clay' : 'bg-moss'}`} style={{ height: `${Math.max(p, 4)}%`, transition: 'height .5s' }} />
                        <span className="text-[10px] text-ink/45">{d.date === 'today' ? 'Сег' : d.date.slice(8)}</span>
                      </div>
                    )
                  })}
                </div>
              </section>
            </>
          )}

          {tab === 'awards' && (
            <>
              <h1 className="font-serif text-[34px] leading-tight">Ачивки</h1>
              <p className="text-sm text-ink/55 mt-1">Открыто {got} из {awards.length}</p>
              <div className="h-2 bg-sand rounded-full mt-3 overflow-hidden"><div className="h-full bg-clay rounded-full transition-all" style={{ width: `${(got / awards.length) * 100}%` }} /></div>
              <div className="grid grid-cols-2 gap-3 mt-5">
                {awards.map((a) => (
                  <div key={a.t} className={`rounded-3xl p-4 ${a.ok ? 'bg-card' : 'bg-sand/60'}`}>
                    <div className={`w-14 h-14 rounded-full grid place-items-center font-serif text-lg ${a.ok ? 'bg-clay text-ink shadow-[0_6px_14px_-4px_rgba(255,170,70,.8)]' : 'bg-ink/10 text-ink/30'}`}>{a.g}</div>
                    <p className={`font-bold mt-3 text-[15px] ${a.ok ? '' : 'text-ink/45'}`}>{a.t}</p>
                    <p className="text-xs text-ink/50 mt-0.5 leading-snug">{a.d}</p>
                  </div>
                ))}
              </div>
            </>
          )}
        </main>

        <nav className="absolute bottom-0 inset-x-0 bg-card/95 backdrop-blur border-t border-ink/5 px-3 pt-2 pb-5 flex justify-around">
          {tabs.map((t) => (
            <button key={t.id} onClick={() => setTab(t.id)} className={`flex flex-col items-center gap-1 px-3 py-1.5 rounded-2xl text-[11px] font-semibold transition-colors ${tab === t.id ? 'text-ink bg-sage' : 'text-ink/40'}`}>
              <I d={t.d} className="w-5.5 h-5.5" />{t.l}
            </button>
          ))}
        </nav>
      </div>
    </div>
  )
}
