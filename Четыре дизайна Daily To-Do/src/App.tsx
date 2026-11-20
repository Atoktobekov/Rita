import { useEffect, useLayoutEffect, useRef, useState } from "react";
import type { CSSProperties, ReactNode } from "react";
import { copyUnfinished, parseTaskBackup, sortTasks } from "./tasks";
import type { Task } from "./tasks";

type IconName =
  | "sun"
  | "archive"
  | "chart"
  | "award"
  | "plus"
  | "arrow"
  | "chevron"
  | "calendar"
  | "check"
  | "copy"
  | "close"
  | "edit"
  | "trash"
  | "settings"
  | "moon"
  | "bell"
  | "download"
  | "upload"
  | "lock"
  | "flame"
  | "star"
  | "bolt"
  | "target"
  | "leaf"
  | "coffee"
  | "expand";
function Icon({
  name,
  size = 22,
  ...props
}: {
  name: IconName;
  size?: number;
  className?: string;
  style?: CSSProperties;
}) {
  const paths: Record<IconName, ReactNode> = {
    sun: (
      <>
        <circle cx="12" cy="12" r="4" />
        <path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5" />
      </>
    ),
    archive: (
      <>
        <rect x="4" y="7" width="16" height="14" rx="2" />
        <path d="M3 3h18v4H3zM9 12h6" />
      </>
    ),
    chart: (
      <>
        <path d="M4 3v18h17M9 16v-5m5 5V6m5 10V9" />
      </>
    ),
    award: (
      <>
        <circle cx="12" cy="9" r="6" />
        <path d="m8 14-2 8 6-3 6 3-2-8m-6-5 1.4 1.4L14 8" />
      </>
    ),
    plus: <path d="M12 5v14M5 12h14" />,
    arrow: <path d="M4 12h16m-6-6 6 6-6 6" />,
    chevron: <path d="m9 5 7 7-7 7" />,
    calendar: (
      <>
        <rect x="3" y="5" width="18" height="16" rx="3" />
        <path d="M7 2v6m10-6v6M3 11h18m-14 4h2m4 0h2" />
      </>
    ),
    check: <path d="m5 12 4 4L19 6" />,
    copy: (
      <>
        <rect x="8" y="8" width="12" height="13" rx="2" />
        <path d="M15 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h3" />
      </>
    ),
    close: <path d="m6 6 12 12M6 18 18 6" />,
    edit: (
      <>
        <path d="m15 4 5 5-11 11H4v-5L15 4Z" />
        <path d="m12 7 5 5" />
      </>
    ),
    trash: (
      <>
        <path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7m4-7v7" />
      </>
    ),
    settings: (
      <>
        <path d="M4 6h16M4 18h16M4 12h16" />
        <circle cx="9" cy="6" r="2" />
        <circle cx="15" cy="12" r="2" />
        <circle cx="9" cy="18" r="2" />
      </>
    ),
    moon: <path d="M20 15A9 9 0 0 1 9 4a9 9 0 1 0 11 11Z" />,
    bell: (
      <>
        <path d="M5 17h14l-2-4V9A5 5 0 0 0 7 9v4l-2 4Zm5 4h4" />
      </>
    ),
    download: <path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5" />,
    upload: <path d="M12 16V4m-5 5 5-5 5 5M4 16v5h16v-5" />,
    lock: (
      <>
        <rect x="5" y="10" width="14" height="11" rx="3" />
        <path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2" />
      </>
    ),
    flame: (
      <path d="M13 2c2 6-4 6-2 11 2-1 3-3 3-5 9 8 4 14-2 14S2 16 6 10c0 4 2 4 2 4C6 7 12 7 13 2Z" />
    ),
    star: <path d="m12 3 2.8 5.7 6.2.9-4.5 4.4 1 6.2-5.5-2.9-5.5 2.9 1-6.2L3 9.6l6.2-.9L12 3Z" />,
    bolt: <path d="m13 2-9 12h7l-1 8 10-13h-7l1-7Z" />,
    target: (
      <>
        <circle cx="12" cy="12" r="9" />
        <circle cx="12" cy="12" r="5" />
        <circle cx="12" cy="12" r="1" />
      </>
    ),
    leaf: (
      <>
        <path d="M20 3C5 1 1 10 6 16S22 17 20 3ZM4 21 16 8" />
      </>
    ),
    coffee: (
      <>
        <path d="M4 8h13v9a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V8Zm13 1h2a3 3 0 1 1 0 6h-2M7 2v2m5-2v2" />
      </>
    ),
    expand: <path d="M8 3H3v5m13-5h5v5M3 16v5h5m13-5v5h-5" />,
  };
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      {paths[name]}
    </svg>
  );
}

const directions = [
  {
    id: "warm",
    number: "01",
    title: "Тёплый минимализм",
    label: "Тепло в простом",
    desc: "Мягкие формы и персиковые акценты. Меньше давления — больше внимания к себе.",
    tags: ["Спокойный", "Тактильный"],
    color: "#FFCF94",
  },
  {
    id: "strict",
    number: "02",
    title: "Строгий современный",
    label: "Фокус на главном",
    desc: "Чёткая сетка, графит и яркий лайм. Ничего лишнего между вами и результатом.",
    tags: ["Собранный", "Контрастный"],
    color: "#D5EF78",
  },
  {
    id: "play",
    number: "03",
    title: "Мягкий игровой",
    label: "Маленькие победы",
    desc: "Дружелюбный ритм и немного азарта. Каждый выполненный пункт — уже повод.",
    tags: ["Живой", "Мотивирующий"],
    color: "#C5B5F4",
  },
  {
    id: "editorial",
    number: "04",
    title: "Тихая редакция",
    label: "День как история",
    desc: "Эстетика личного дневника: бумага, чернила и выразительная типографика.",
    tags: ["Авторский", "Вдумчивый"],
    color: "#AEC8D4",
  },
] as const;
type Direction = (typeof directions)[number]["id"];
type Screen = "today" | "archive" | "stats" | "achievements";
const TODAY = "2026-06-18";
const TOMORROW = "2026-06-19";
const initialTasks: Task[] = [
  { id: 1, title: "Прочитать 20 страниц", done: false, date: TODAY },
  { id: 2, title: "Сделать тренировку", done: false, date: TODAY },
  { id: 3, title: "Записаться к врачу", done: false, date: TODAY },
  { id: 4, title: "Закончить проект", done: true, date: TODAY },
  { id: 5, title: "Купить продукты", done: true, date: TODAY },
];
const tabs: { id: Screen; label: string; icon: IconName }[] = [
  { id: "today", label: "Сегодня", icon: "sun" },
  { id: "archive", label: "Архив", icon: "archive" },
  { id: "stats", label: "Статистика", icon: "chart" },
  { id: "achievements", label: "Ачивки", icon: "award" },
];
const history = [
  { date: "2026-06-17", label: "17 июня", day: "Среда", done: 4, total: 5 },
  { date: "2026-06-16", label: "16 июня", day: "Вторник", done: 5, total: 5 },
  { date: "2026-06-15", label: "15 июня", day: "Понедельник", done: 3, total: 4 },
  { date: "2026-06-14", label: "14 июня", day: "Воскресенье", done: 2, total: 4 },
  { date: "2026-06-13", label: "13 июня", day: "Суббота", done: 3, total: 5 },
  { date: "2026-06-12", label: "12 июня", day: "Пятница", done: 4, total: 4 },
];
const archivedTasks: Task[] = history.flatMap((day, d) =>
  initialTasks
    .slice(0, day.total)
    .map((task, i) => ({ ...task, id: 100 + d * 10 + i, date: day.date, done: i < day.done })),
);
type Sheet =
  | "menu"
  | "editor"
  | "calendar"
  | "future"
  | "settings"
  | "backup"
  | "day"
  | "achievement"
  | null;
type StatePreview = "dark" | "empty" | "menu" | "editor" | "day";

function TaskList({
  tasks,
  onToggle,
  onMenu,
}: {
  tasks: Task[];
  onToggle: (id: number) => void;
  onMenu: (task: Task) => void;
}) {
  const refs = useRef(new Map<number, HTMLButtonElement>());
  const positions = useRef(new Map<number, number>());
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const held = useRef(false);
  const sorted = sortTasks(tasks);
  useLayoutEffect(() => {
    refs.current.forEach((el, id) => {
      const y = el.offsetTop;
      const old = positions.current.get(id);
      if (old !== undefined && old !== y)
        el.animate([{ transform: `translateY(${old - y}px)` }, { transform: "translateY(0)" }], {
          duration: 380,
          easing: "cubic-bezier(.2,.75,.25,1)",
        });
      positions.current.set(id, y);
    });
  }, [tasks]);
  const clear = () => {
    if (timer.current) clearTimeout(timer.current);
  };
  return (
    <div className="task-list">
      {sorted.map((task) => (
        <button
          key={task.id}
          ref={(el) => {
            if (el) refs.current.set(task.id, el);
            else refs.current.delete(task.id);
          }}
          className={`task ${task.done ? "completed" : ""}`}
          onPointerDown={() => {
            held.current = false;
            timer.current = setTimeout(() => {
              held.current = true;
              onMenu(task);
            }, 500);
          }}
          onPointerUp={clear}
          onPointerLeave={clear}
          onPointerCancel={clear}
          onContextMenu={(e) => {
            e.preventDefault();
            held.current = true;
            onMenu(task);
          }}
          onClick={() => {
            if (!held.current) onToggle(task.id);
          }}
          aria-label={`${task.title}, ${task.done ? "выполнено" : "не выполнено"}. Удерживайте для редактирования`}
        >
          <span>{task.title}</span>
          <span className="task-check">{task.done && <Icon name="check" size={16} />}</span>
        </button>
      ))}
    </div>
  );
}

function Phone({
  direction,
  initialScreen = "today",
  preview,
  expanded = false,
}: {
  direction: Direction;
  initialScreen?: Screen;
  preview?: StatePreview;
  expanded?: boolean;
}) {
  const [screen, setScreen] = useState<Screen>(initialScreen);
  const [tasks, setTasks] = useState<Task[]>(() =>
    preview === "empty" ? [...archivedTasks] : [...initialTasks, ...archivedTasks],
  );
  const [date, setDate] = useState(TODAY);
  const [dark, setDark] = useState(preview === "dark");
  const [sheet, setSheet] = useState<Sheet>(
    preview === "menu"
      ? "menu"
      : preview === "editor"
        ? "editor"
        : preview === "day"
          ? "day"
          : null,
  );
  const [selected, setSelected] = useState<Task>(initialTasks[0]);
  const [title, setTitle] = useState(initialTasks[0].title);
  const [editDate, setEditDate] = useState(TODAY);
  const [quick, setQuick] = useState("");
  const [quickOpen, setQuickOpen] = useState(false);
  const [archiveOpen, setArchiveOpen] = useState<string | null>(null);
  const [chartMode, setChartMode] = useState("tasks");
  const [dayDate, setDayDate] = useState("2026-06-17");
  const [reminder, setReminder] = useState(true);
  const [reminderTime, setReminderTime] = useState("21:00");
  const [toast, setToast] = useState("");
  const [achievement, setAchievement] = useState(0);
  const [calendarDate, setCalendarDate] = useState(TODAY);
  const touchX = useRef<number | null>(null);
  const uploadRef = useRef<HTMLInputElement>(null);
  const isNew = useRef(false);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const notify = (text: string) => {
    setToast(text);
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(""), 3000);
  };
  const current = tasks.filter((t) => t.date === date);
  const completed = current.filter((t) => t.done).length;
  const percent = current.length ? Math.round((completed / current.length) * 100) : 0;
  const toggle = (id: number) =>
    setTasks((old) => old.map((t) => (t.id === id ? { ...t, done: !t.done } : t)));
  const menu = (task: Task) => {
    setSelected(task);
    setSheet("menu");
  };
  const openEditor = (task?: Task, targetDate = date) => {
    isNew.current = !task;
    setSelected(task || { id: Date.now(), title: "", date: targetDate, done: false });
    setTitle(task?.title || "");
    setEditDate(task?.date || targetDate);
    setSheet("editor");
  };
  const add = (targetDate: string) => {
    if (!quick.trim()) return;
    setTasks((old) => [
      ...old,
      { id: Date.now(), title: quick.trim(), done: false, date: targetDate },
    ]);
    setQuick("");
    setQuickOpen(false);
  };
  const quickAdd = (targetDate: string) =>
    quickOpen ? (
      <form
        className="quick-form"
        onSubmit={(e) => {
          e.preventDefault();
          add(targetDate);
        }}
      >
        <input
          autoFocus
          placeholder="Что нужно сделать?"
          value={quick}
          onChange={(e) => setQuick(e.target.value)}
          maxLength={160}
          aria-label="Название новой задачи"
        />
        <button aria-label="Добавить задачу" type="submit">
          <Icon name="arrow" />
        </button>
      </form>
    ) : (
      <button className="add-task" onClick={() => setQuickOpen(true)}>
        <Icon name="plus" size={21} />
        Добавить задачу
      </button>
    );
  const navIndex = tabs.findIndex((t) => t.id === screen);
  const totalDone = tasks.filter((t) => t.done).length;
  const totalPercent = tasks.length ? Math.round((totalDone / tasks.length) * 100) : 0;
  const streak = (() => {
    let n = 0;
    for (const d of history) {
      const list = tasks.filter((t) => t.date === d.date);
      if (list.length && list.filter((t) => t.done).length / list.length >= 0.5) n++;
      else break;
    }
    return n;
  })();
  const days = [...new Set(tasks.map((t) => t.date))].map((d) => {
    const list = tasks.filter((t) => t.date === d);
    return { date: d, percent: list.filter((t) => t.done).length / list.length };
  });
  const longestStreak = (threshold: number) => {
    let longest = 0,
      run = 0,
      previous = 0;
    for (const day of [...days].sort((a, b) => a.date.localeCompare(b.date))) {
      const time = Date.parse(day.date + "T12:00:00Z");
      run = day.percent >= threshold ? (time - previous === 86400000 ? run + 1 : 1) : 0;
      longest = Math.max(longest, run);
      previous = time;
    }
    return longest;
  };
  const achievements: { title: string; desc: string; icon: IconName; open: boolean }[] = [
    { title: "Первоход", desc: "Первая выполненная задача", icon: "leaf", open: totalDone >= 1 },
    { title: "Червонец", desc: "10 выполненных задач", icon: "bolt", open: totalDone >= 10 },
    {
      title: "Ты у меня третий",
      desc: "3 дня подряд от 50%",
      icon: "flame",
      open: longestStreak(0.5) >= 3,
    },
    {
      title: "Эйс",
      desc: "Первый день со 100%",
      icon: "target",
      open: days.some((d) => d.percent === 1),
    },
    {
      title: "Жигули",
      desc: "7 дней с выполнением от 50%",
      icon: "star",
      open: days.filter((d) => d.percent >= 0.5).length >= 7,
    },
    { title: "Трудоголик", desc: "100 выполненных задач", icon: "coffee", open: totalDone >= 100 },
    {
      title: "Тайная вечеря",
      desc: "13 дней подряд со 100%",
      icon: "award",
      open: longestStreak(1) >= 13,
    },
  ];
  const unlocked = achievements.filter((a) => a.open).length;
  const sheetTitle =
    sheet === "menu"
      ? "Задача"
      : sheet === "editor"
        ? isNew.current
          ? "Новая задача"
          : "Редактировать задачу"
        : sheet === "calendar"
          ? "Выберите день"
          : sheet === "future"
            ? "Будущие планы"
            : sheet === "settings"
              ? "Как вам удобно"
              : sheet === "backup"
                ? "Ваши задачи — с вами"
                : sheet === "achievement"
                  ? "Маленькая победа"
                  : `${Number(dayDate.slice(-2))} июня, ${history.find((d) => d.date === dayDate)?.day.toLowerCase() || "четверг"}`;

  return (
    <div className={`phone-frame ${expanded ? "is-expanded" : ""}`}>
      <div className={`phone-inner theme-${direction} ${dark ? "is-dark" : ""}`}>
        <div className="status-bar">
          <span>9:41</span>
          <div className="system-status">
            <svg width="17" height="14" viewBox="0 0 17 14" fill="currentColor">
              <rect x="0" y="9" width="3" height="5" rx=".8" />
              <rect x="5" y="6" width="3" height="8" rx=".8" />
              <rect x="10" y="2" width="3" height="12" rx=".8" />
            </svg>
            <svg
              width="17"
              height="14"
              viewBox="0 0 20 16"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.3"
            >
              <path d="M2 5a12 12 0 0 1 16 0M5 9a7 7 0 0 1 10 0m-7 4a3 3 0 0 1 4 0" />
            </svg>
            <span className="battery" />
          </div>
        </div>
        <div
          className="phone-scroll"
          onTouchStart={(e) => {
            touchX.current = e.touches[0].clientX;
          }}
          onTouchEnd={(e) => {
            if (touchX.current === null || sheet) return;
            const delta = touchX.current - e.changedTouches[0].clientX;
            if (Math.abs(delta) > 65)
              setScreen(tabs[Math.max(0, Math.min(3, navIndex + (delta > 0 ? 1 : -1)))].id);
            touchX.current = null;
          }}
        >
          <div className="app-top">
            <span className="app-wordmark">
              daily<span className="wordmark-dot">.</span>
            </span>
            <span className="app-top-note">
              {direction === "strict"
                ? "МЕНЬШЕ, НО ЛУЧШЕ"
                : direction === "play"
                  ? "Всё получится"
                  : direction === "editorial"
                    ? "Личный планировщик"
                    : "В своём ритме"}
              <span className="tiny-dot" />
            </span>
          </div>
          {screen === "today" && (
            <>
              <div className="date-selector">
                <button className={date === TODAY ? "selected" : ""} onClick={() => setDate(TODAY)}>
                  Сегодня
                </button>
                <button
                  className={date === TOMORROW ? "selected" : ""}
                  onClick={() => setDate(TOMORROW)}
                >
                  Завтра
                </button>
                <button
                  aria-label="Выбрать дату в календаре"
                  className={
                    date !== TODAY && date !== TOMORROW
                      ? "selected calendar-button"
                      : "calendar-button"
                  }
                  onClick={() => {
                    setCalendarDate(date);
                    setSheet("calendar");
                  }}
                >
                  <Icon name="calendar" size={21} />
                </button>
              </div>
              <div className="day-heading">
                <div className="eyebrow">
                  {date === TODAY
                    ? "ЧЕТВЕРГ, 18 ИЮНЯ"
                    : date === TOMORROW
                      ? "ПЯТНИЦА, 19 ИЮНЯ"
                      : new Date(date + "T12:00:00")
                          .toLocaleDateString("ru-RU", {
                            weekday: "long",
                            day: "numeric",
                            month: "long",
                          })
                          .toUpperCase()}
                </div>
                <h2>
                  {date === TODAY
                    ? direction === "play"
                      ? "Твой день."
                      : direction === "strict"
                        ? "План на день"
                        : "Хороший день"
                    : "Новый день"}
                  {direction === "warm" && (
                    <span className="heading-sun">
                      <Icon name="sun" size={29} />
                    </span>
                  )}
                </h2>
                <p>
                  {direction === "play"
                    ? "Не всё сразу. По одной победе."
                    : direction === "editorial"
                      ? "Оставьте место для важного."
                      : "Маленькие шаги к большому."}
                </p>
              </div>
              <div className="progress-panel">
                <div className="progress-copy">
                  <span>
                    Выполнено{" "}
                    <strong>
                      {completed} из {current.length}
                    </strong>
                  </span>
                  <strong>
                    {percent}
                    <small>%</small>
                  </strong>
                </div>
                <div className="progress-track">
                  <span style={{ width: `${percent}%` }} />
                </div>
                {direction === "play" && (
                  <span className="progress-caption">Хорошее начало. Продолжим?</span>
                )}
              </div>
              <div className="list-label">
                <span>{direction === "strict" ? "ЗАДАЧИ" : "Мои задачи"}</span>
                <span>{String(current.length).padStart(2, "0")}</span>
              </div>
              {current.length ? (
                <TaskList tasks={current} onToggle={toggle} onMenu={menu} />
              ) : (
                <div className="empty-state">
                  <div className="empty-art">
                    <Icon name="sun" size={56} />
                  </div>
                  <h3>День — чистый лист</h3>
                  <p>
                    Никакой спешки. Добавьте то,
                    <br />
                    что действительно важно.
                  </p>
                </div>
              )}
              {quickAdd(date)}
              <div className="today-secondary">
                <button
                  onClick={() => {
                    const undone = current.filter((t) => !t.done);
                    if (!undone.length) return notify("Нет незавершённых задач");
                    const copies = copyUnfinished(tasks, date);
                    setTasks((old) => [...old, ...copies]);
                    notify(
                      copies.length
                        ? `На завтра скопировано: ${copies.length}`
                        : "Эти задачи уже есть на завтра",
                    );
                  }}
                >
                  <Icon name="copy" size={17} />
                  <span>Скопировать незавершённые на завтра</span>
                </button>
                <button className="future-link" onClick={() => setSheet("future")}>
                  Будущие планы
                  <Icon name="arrow" size={18} />
                </button>
              </div>
            </>
          )}
          {screen === "archive" && (
            <>
              <div className="section-heading">
                <div className="eyebrow">ВСЁ ОСТАЁТСЯ С ВАМИ</div>
                <h2>
                  Архив<span className="heading-mark">↙</span>
                </h2>
                <p>Каждый день — часть пути.</p>
              </div>
              <div className="month-label">
                <span>Июнь 2026</span>
                <span>6 дней</span>
              </div>
              <div className="archive-list">
                {history.map((day) => {
                  const list = tasks.filter((t) => t.date === day.date);
                  const done = list.filter((t) => t.done).length;
                  const pct = list.length ? Math.round((done / list.length) * 100) : 0;
                  return (
                    <div
                      className={`archive-item ${archiveOpen === day.date ? "open" : ""}`}
                      key={day.date}
                    >
                      <button
                        className="archive-summary"
                        onClick={() => setArchiveOpen(archiveOpen === day.date ? null : day.date)}
                      >
                        <span className="archive-date">
                          <strong>{day.label}</strong>
                          <small>
                            {day.day} · {done} из {list.length} задач
                          </small>
                        </span>
                        <span className={`archive-percent ${pct === 100 ? "all-done" : ""}`}>
                          {pct}%
                        </span>
                        <Icon name="chevron" size={18} />
                      </button>
                      {archiveOpen === day.date && (
                        <div className="archive-expanded">
                          <TaskList tasks={list} onToggle={toggle} onMenu={menu} />
                          <button
                            className="add-task"
                            onClick={() => openEditor(undefined, day.date)}
                          >
                            <Icon name="plus" size={18} />
                            Добавить задачу
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
              <button className="backup-button" onClick={() => setSheet("backup")}>
                <span className="backup-icon">
                  <Icon name="archive" size={21} />
                </span>
                <span>
                  <strong>Сохранить важное</strong>
                  <small>Импорт и экспорт задач</small>
                </span>
                <Icon name="arrow" size={19} />
              </button>
            </>
          )}
          {screen === "stats" && (
            <>
              <div className="section-heading heading-with-action">
                <div>
                  <div className="eyebrow">МАЛЕНЬКИЕ ШАГИ СЧИТАЮТСЯ</div>
                  <h2>Статистика</h2>
                  <p>Вы делаете больше, чем кажется.</p>
                </div>
                <button
                  className="icon-button"
                  aria-label="Настройки"
                  onClick={() => setSheet("settings")}
                >
                  <Icon name="settings" />
                </button>
              </div>
              <div className="stat-hero">
                <div>
                  <span>Общий прогресс</span>
                  <strong>
                    {totalPercent}
                    <small>%</small>
                  </strong>
                  <p>Хороший ритм. Так держать.</p>
                </div>
                <div
                  className="stat-ring"
                  style={{ "--progress": `${totalPercent}%` } as CSSProperties}
                >
                  <Icon name={direction === "play" ? "star" : "arrow"} size={31} />
                </div>
              </div>
              <div className="stat-pair">
                <div>
                  <Icon name="check" size={19} />
                  <strong>{totalDone}</strong>
                  <span>задачи выполнены</span>
                </div>
                <div>
                  <Icon name="flame" size={19} />
                  <strong>
                    {streak}
                    <small> дней</small>
                  </strong>
                  <span>текущая серия</span>
                </div>
              </div>
              <div className="chart-card">
                <div className="chart-header">
                  <h3>Ваш ритм</h3>
                  <span>12–17 июня</span>
                </div>
                <div className="chart-toggle">
                  <button
                    className={chartMode === "tasks" ? "selected" : ""}
                    onClick={() => setChartMode("tasks")}
                  >
                    Задачи
                  </button>
                  <button
                    className={chartMode === "percent" ? "selected" : ""}
                    onClick={() => setChartMode("percent")}
                  >
                    Проценты
                  </button>
                </div>
                <div className="bar-chart">
                  {[...history].reverse().map((day, i) => {
                    const list = tasks.filter((t) => t.date === day.date),
                      n = list.filter((t) => t.done).length,
                      p = list.length ? Math.round((n / list.length) * 100) : 0;
                    return (
                      <button
                        key={day.date}
                        className={`bar-column ${i === 5 ? "last" : ""}`}
                        onClick={() => {
                          setDayDate(day.date);
                          setSheet("day");
                        }}
                        aria-label={`Открыть ${day.label}: ${n} выполненных задач`}
                      >
                        <div className="bar-space">
                          <span
                            className="bar-value"
                            style={{
                              bottom: `${(chartMode === "tasks" ? n / 5 : p / 100) * 100}%`,
                            }}
                          >
                            {chartMode === "tasks" ? n : `${p}%`}
                          </span>
                          <span
                            className="bar"
                            style={{
                              height: `${(chartMode === "tasks" ? n / 5 : p / 100) * 100}%`,
                            }}
                          />
                        </div>
                        <span className="bar-label">{12 + i}</span>
                      </button>
                    );
                  })}
                </div>
                <p className="chart-hint">Нажмите на столбик, чтобы открыть день</p>
              </div>
              <button className="settings-link" onClick={() => setSheet("settings")}>
                <Icon name="settings" size={19} />
                Тема и вечернее напоминание
                <Icon name="chevron" size={17} />
              </button>
            </>
          )}
          {screen === "achievements" && (
            <>
              <div className="section-heading">
                <div className="eyebrow">ЕСТЬ ЧЕМ ГОРДИТЬСЯ</div>
                <h2>
                  {direction === "editorial" ? "Мои открытия" : "Ачивки"}
                  <span className="heading-sun">
                    <Icon name="star" size={28} />
                  </span>
                </h2>
                <p>
                  {direction === "play"
                    ? "Обычные дела. Необычный ты."
                    : "Не гонка. Ваша личная коллекция."}
                </p>
              </div>
              <div className="achievement-progress">
                <span>
                  <strong>{unlocked}</strong> из 7 открыто
                </span>
                <div className="mini-progress">
                  <span style={{ width: `${(unlocked / achievements.length) * 100}%` }} />
                </div>
              </div>
              <div className="achievement-grid">
                {achievements.map((item, i) => (
                  <button
                    key={item.title}
                    className={`achievement ${item.open ? "unlocked" : "locked"}`}
                    onClick={() => {
                      setAchievement(i);
                      setSheet("achievement");
                    }}
                  >
                    <span className={`medal medal-${i}`}>
                      <Icon name={item.icon} size={33} />
                      {!item.open && (
                        <span className="lock-badge">
                          <Icon name="lock" size={11} />
                        </span>
                      )}
                    </span>
                    <strong>{item.title}</strong>
                    <span>{item.desc}</span>
                    {item.open && (
                      <small>
                        <Icon name="check" size={11} />
                        Открыто
                      </small>
                    )}
                  </button>
                ))}
              </div>
            </>
          )}
        </div>
        <nav className="bottom-nav" aria-label="Навигация приложения">
          <span className="nav-slider" style={{ transform: `translateX(${navIndex * 100}%)` }} />
          {tabs.map((tab) => (
            <button
              key={tab.id}
              className={screen === tab.id ? "active" : ""}
              onClick={() => setScreen(tab.id)}
              aria-current={screen === tab.id ? "page" : undefined}
            >
              <Icon name={tab.icon} size={23} />
              <span>{tab.label}</span>
            </button>
          ))}
        </nav>
        <div className="home-indicator">
          <span />
        </div>
        {toast && (
          <div className="toast" role="status">
            <Icon name="check" size={18} />
            {toast}
          </div>
        )}
        {sheet && (
          <div className="sheet-layer">
            <button
              className="sheet-backdrop"
              onClick={() => setSheet(null)}
              aria-label="Закрыть окно"
            />
            <section
              className={`bottom-sheet sheet-${sheet}`}
              role="dialog"
              aria-modal="true"
              aria-label={sheetTitle}
            >
              <span className="sheet-handle" />
              <div className="sheet-heading">
                <h3>{sheetTitle}</h3>
                <button className="icon-button" onClick={() => setSheet(null)} aria-label="Закрыть">
                  <Icon name="close" size={20} />
                </button>
              </div>
              {sheet === "menu" && (
                <>
                  <p className="selected-task-name">{selected.title}</p>
                  <button className="sheet-action" onClick={() => openEditor(selected)}>
                    <Icon name="edit" />
                    Редактировать
                    <Icon name="chevron" size={17} />
                  </button>
                  <button
                    className="sheet-action danger"
                    onClick={() => {
                      setTasks((old) => old.filter((t) => t.id !== selected.id));
                      setSheet(null);
                      notify("Задача удалена");
                    }}
                  >
                    <Icon name="trash" />
                    Удалить
                  </button>
                </>
              )}
              {sheet === "editor" && (
                <form
                  className="editor-form"
                  onSubmit={(e) => {
                    e.preventDefault();
                    if (!title.trim()) return;
                    setTasks((old) =>
                      isNew.current
                        ? [...old, { ...selected, title: title.trim(), date: editDate }]
                        : old.map((t) =>
                            t.id === selected.id
                              ? { ...t, title: title.trim(), date: editDate }
                              : t,
                          ),
                    );
                    setSheet(null);
                    notify("Задача сохранена");
                  }}
                >
                  <label>
                    Название задачи
                    <textarea
                      value={title}
                      onChange={(e) => setTitle(e.target.value)}
                      required
                      maxLength={160}
                      rows={3}
                    />
                  </label>
                  <label>
                    Дата
                    <input
                      type="date"
                      value={editDate}
                      onChange={(e) => setEditDate(e.target.value)}
                      required
                    />
                  </label>
                  <p className="form-note">Без спешки. План всегда можно изменить.</p>
                  <button type="submit" className="primary-button">
                    Сохранить изменения
                    <Icon name="check" size={19} />
                  </button>
                </form>
              )}
              {sheet === "calendar" && (
                <div className="calendar-sheet">
                  <p>Планы на любой день — в одном месте.</p>
                  <label>
                    Дата
                    <input
                      aria-label="Дата"
                      type="date"
                      value={calendarDate}
                      onChange={(e) => setCalendarDate(e.target.value)}
                    />
                  </label>
                  <button
                    className="primary-button"
                    onClick={() => {
                      setDate(calendarDate);
                      setSheet(null);
                    }}
                  >
                    Открыть день
                    <Icon name="arrow" size={19} />
                  </button>
                </div>
              )}
              {sheet === "future" && (
                <div className="future-sheet">
                  <p>Освободите голову — оставьте планы здесь.</p>
                  {[...new Set(tasks.filter((t) => t.date > TODAY).map((t) => t.date))]
                    .sort()
                    .map((d) => (
                      <button
                        className="sheet-action"
                        key={d}
                        onClick={() => {
                          setDate(d);
                          setScreen("today");
                          setSheet(null);
                        }}
                      >
                        <Icon name="calendar" />
                        <span>
                          {new Date(d + "T12:00:00").toLocaleDateString("ru-RU", {
                            day: "numeric",
                            month: "long",
                          })}
                        </span>
                        <span>{tasks.filter((t) => t.date === d).length} задач</span>
                        <Icon name="chevron" size={17} />
                      </button>
                    ))}
                  {!tasks.some((t) => t.date > TODAY) && (
                    <div className="future-empty">
                      <Icon name="calendar" size={36} />
                      <h4>Будущее ещё не расписано</h4>
                      <p>Выберите день и добавьте первый план.</p>
                    </div>
                  )}
                  <button
                    className="primary-button"
                    onClick={() => {
                      setCalendarDate(TOMORROW);
                      setSheet("calendar");
                    }}
                  >
                    Выбрать день
                    <Icon name="plus" size={19} />
                  </button>
                </div>
              )}
              {sheet === "settings" && (
                <div className="settings-sheet">
                  <div className="setting-row">
                    <Icon name="moon" />
                    <span>Тёмная тема</span>
                    <button
                      role="switch"
                      aria-checked={dark}
                      aria-label="Тёмная тема"
                      className={`switch ${dark ? "on" : ""}`}
                      onClick={() => setDark(!dark)}
                    >
                      <span />
                    </button>
                  </div>
                  <div className="setting-row">
                    <Icon name="bell" />
                    <span>Вечернее напоминание</span>
                    <button
                      role="switch"
                      aria-checked={reminder}
                      aria-label="Вечернее напоминание"
                      className={`switch ${reminder ? "on" : ""}`}
                      onClick={() => setReminder(!reminder)}
                    >
                      <span />
                    </button>
                  </div>
                  {reminder && (
                    <label className="time-setting">
                      Время
                      <input
                        type="time"
                        value={reminderTime}
                        onChange={(e) => setReminderTime(e.target.value)}
                      />
                    </label>
                  )}
                  <p className="form-note">
                    Демонстрация настройки. Системные уведомления в веб-прототипе не отправляются.
                  </p>
                </div>
              )}
              {sheet === "backup" && (
                <div className="backup-sheet">
                  <p>
                    Скачайте копию или восстановите задачи из JSON-файла. Импорт добавит задачи к
                    существующим.
                  </p>
                  <button
                    className="sheet-action"
                    onClick={() => {
                      const url = URL.createObjectURL(
                        new Blob([JSON.stringify(tasks, null, 2)], { type: "application/json" }),
                      );
                      const a = document.createElement("a");
                      a.href = url;
                      a.download = "daily-tasks.json";
                      a.click();
                      URL.revokeObjectURL(url);
                      notify("Копия задач скачана");
                    }}
                  >
                    <Icon name="download" />
                    Экспортировать JSON
                    <Icon name="arrow" size={18} />
                  </button>
                  <button className="sheet-action" onClick={() => uploadRef.current?.click()}>
                    <Icon name="upload" />
                    Импортировать JSON
                    <Icon name="arrow" size={18} />
                  </button>
                  <input
                    type="file"
                    accept=".json,application/json"
                    hidden
                    ref={uploadRef}
                    onChange={async (e) => {
                      const file = e.target.files?.[0];
                      if (!file) return;
                      try {
                        const data = parseTaskBackup(await file.text());
                        setTasks((old) => [...old, ...data]);
                        notify(`Импортировано задач: ${data.length}`);
                        setSheet(null);
                      } catch {
                        notify("Не удалось прочитать файл задач");
                      }
                      e.target.value = "";
                    }}
                  />
                </div>
              )}
              {sheet === "day" && (
                <div className="day-sheet">
                  <div className="day-sheet-meta">
                    <span>
                      Выполнено {tasks.filter((t) => t.date === dayDate && t.done).length} из{" "}
                      {tasks.filter((t) => t.date === dayDate).length}
                    </span>
                    <span>Ваш день в деталях</span>
                  </div>
                  <TaskList
                    tasks={tasks.filter((t) => t.date === dayDate)}
                    onToggle={toggle}
                    onMenu={menu}
                  />
                  <button className="add-task" onClick={() => openEditor(undefined, dayDate)}>
                    <Icon name="plus" size={20} />
                    Добавить задачу
                  </button>
                  <p className="form-note">Удерживайте задачу, чтобы изменить или удалить.</p>
                </div>
              )}
              {sheet === "achievement" && (
                <div className="achievement-detail">
                  <span className={`medal medal-${achievement}`}>
                    <Icon name={achievements[achievement].icon} size={48} />
                  </span>
                  <h2>{achievements[achievement].title}</h2>
                  <p>{achievements[achievement].desc}</p>
                  <span className="achievement-status">
                    {achievements[achievement].open
                      ? "Уже в вашей коллекции"
                      : "Всё впереди. В своём ритме."}
                  </span>
                </div>
              )}
            </section>
          </div>
        )}
      </div>
    </div>
  );
}

const statePreviews: { id: StatePreview; title: string; desc: string; screen?: Screen }[] = [
  { id: "dark", title: "Когда день стихает", desc: "Тёмная тема · мягкий контраст" },
  { id: "empty", title: "Всё начинается с малого", desc: "Пустой день · без давления" },
  { id: "menu", title: "Только нужные действия", desc: "Удержание карточки · 500 мс" },
  { id: "editor", title: "Планы могут меняться", desc: "Название и дата · один экран" },
  {
    id: "day",
    title: "За цифрами — ваши дни",
    desc: "Карточка дня из статистики",
    screen: "stats",
  },
];

export default function App() {
  const [activeSection, setActiveSection] = useState("today");
  const [focus, setFocus] = useState<Direction | null>(null);
  const [showInfo, setShowInfo] = useState(false);
  useEffect(() => {
    if (!focus) return;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") setFocus(null);
    };
    document.addEventListener("keydown", closeOnEscape);
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", closeOnEscape);
      document.body.style.overflow = previousOverflow;
    };
  }, [focus]);
  const openFocus = (direction: Direction, screen: Screen) => {
    setActiveSection(screen);
    setFocus(direction);
  };
  const navigate = (id: string) => {
    setActiveSection(id);
    document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
  };
  return (
    <div className="design-studio">
      <header className="studio-header">
        <a className="studio-brand" href="#">
          <span className="brand-symbol">
            <Icon name="check" size={20} />
          </span>
          daily<span className="brand-period">.</span>
          <span className="brand-divider" />
          <span className="brand-descriptor">Дизайн-исследование</span>
        </a>
        <div className="header-right">
          <span className="prototype-label">
            <span />
            Интерактивный прототип
          </span>
          <button className="about-button" onClick={() => setShowInfo(!showInfo)}>
            О проекте
            <Icon name="arrow" size={15} />
          </button>
        </div>
      </header>
      <main>
        <section className="hero">
          <div className="hero-copy">
            <div className="hero-eyebrow">
              <span />
              ОДИН ДЕНЬ. ЧЕТЫРЕ НАСТРОЕНИЯ.
            </div>
            <h1>
              Большие планы.
              <br />
              <span>В вашем ритме.</span>
            </h1>
            <p>
              Четыре взгляда на ежедневный планировщик.
              <br />
              Одинаковые возможности. Разное ощущение от каждого дня.
            </p>
          </div>
          <div className="hero-aside">
            <div className="concept-orbit">
              <span className="orbit-disc disc-one">
                <Icon name="sun" size={31} />
              </span>
              <span className="orbit-disc disc-two">
                <Icon name="check" size={31} />
              </span>
              <span className="orbit-disc disc-three">
                <Icon name="star" size={30} />
              </span>
              <span className="orbit-disc disc-four">
                <Icon name="leaf" size={29} />
              </span>
            </div>
            <div className="hero-facts">
              <span>
                <strong>04</strong>направления
              </span>
              <span>
                <strong>16</strong>экранов
              </span>
              <span>
                <strong>05</strong>состояний
              </span>
            </div>
            <div className="platform-label">
              iOS & Android
              <span />
              390 × 844
            </div>
          </div>
        </section>
        {showInfo && (
          <div className="project-info">
            <div>
              <h3>Личный планировщик. Ничего лишнего.</h3>
              <p>
                Без регистрации, команд и категорий. Сравните четыре направления на одинаковых
                данных. Нажимайте на задачи, удерживайте их для меню, переключайте вкладки и
                открывайте дни диаграммы.
              </p>
            </div>
            <p>
              Это веб-прототип: изменения живут до перезагрузки страницы. Компоненты и токены
              редактируются в коде; Figma Auto Layout и Smart Animate не создаются.
            </p>
            <button
              className="icon-button"
              aria-label="Закрыть описание"
              onClick={() => setShowInfo(false)}
            >
              <Icon name="close" />
            </button>
          </div>
        )}
        <div className="gallery-toolbar">
          <div className="screen-tabs">
            {tabs.map((tab, i) => (
              <button
                key={tab.id}
                className={activeSection === tab.id ? "active" : ""}
                onClick={() => navigate(tab.id)}
              >
                <span className="tab-number">0{i + 1}</span>
                {tab.label}
              </button>
            ))}
            <button
              className={activeSection === "states" ? "active" : ""}
              onClick={() => navigate("states")}
            >
              <span className="tab-number">05</span>Состояния
            </button>
          </div>
          <span className="toolbar-hint">
            <span className="live-dot" />
            Экраны можно потрогать
          </span>
        </div>
        <section id="today" className="comparison-section first-section">
          <div className="directions-grid">
            {directions.map((d) => (
              <article className={`direction-card direction-${d.id}`} key={d.id}>
                <div className="direction-topline">
                  <span className="direction-number">{d.number}</span>
                  <span className="direction-swatch" style={{ background: d.color }} />
                  <span className="direction-platform">
                    {d.id === "warm" ? "ВЫБОР РЕДАКЦИИ" : "DAILY TO-DO"}
                  </span>
                </div>
                <h2>{d.title}</h2>
                <p>{d.desc}</p>
                <div className="direction-tags">
                  {d.tags.map((tag) => (
                    <span key={tag}>{tag}</span>
                  ))}
                </div>
                <div className="artboard-caption">
                  <span>01 / Сегодня</span>
                  <button title="Открыть в полном размере" onClick={() => openFocus(d.id, "today")}>
                    <Icon name="expand" size={15} />
                  </button>
                </div>
                <Phone direction={d.id} />
                <div className="direction-footnote">
                  <span style={{ background: d.color }} />
                  <span>{d.label}</span>
                  <button
                    onClick={() => openFocus(d.id, "today")}
                    aria-label={`Открыть ${d.title}`}
                  >
                    <Icon name="arrow" size={17} />
                  </button>
                </div>
              </article>
            ))}
          </div>
        </section>
        <div className="interaction-note">
          <span className="note-icon">
            <Icon name="plus" size={18} />
          </span>
          <span>
            <strong>Не просто картинки.</strong> Выполняйте задачи, удерживайте для редактирования и
            переключайте вкладки — даже свайпом.
          </span>
          <span className="note-line" />
          <span className="note-key">Нажмите ↗ для масштаба 1:1</span>
        </div>
        {tabs.slice(1).map((tab, i) => (
          <section id={tab.id} className="comparison-section" key={tab.id}>
            <div className="section-title-row">
              <div>
                <div className="section-kicker">ЭКРАН 0{i + 2}</div>
                <h2>
                  {tab.label}
                  <span>
                    {tab.id === "archive"
                      ? "Прошлое под рукой"
                      : tab.id === "stats"
                        ? "Прогресс, который видно"
                        : "Каждая победа имеет значение"}
                  </span>
                </h2>
              </div>
              <Icon name={tab.icon} size={26} />
            </div>
            <div className="directions-grid">
              {directions.map((d) => (
                <div key={d.id}>
                  <div className="artboard-caption">
                    <span>
                      <i style={{ background: d.color }} />
                      {d.number} / {d.title}
                    </span>
                    <button
                      aria-label={`Открыть ${d.title}`}
                      onClick={() => openFocus(d.id, tab.id)}
                    >
                      <Icon name="expand" size={15} />
                    </button>
                  </div>
                  <Phone direction={d.id} initialScreen={tab.id} />
                </div>
              ))}
            </div>
          </section>
        ))}
        <section id="states" className="states-section">
          <div className="section-title-row">
            <div>
              <div className="section-kicker">БЛИЖЕ К НАСТОЯЩЕЙ ЖИЗНИ</div>
              <h2>
                Продумано до мелочей<span>01 / Тёплый минимализм</span>
              </h2>
            </div>
            <span className="selection-badge">
              <Icon name="star" size={14} />
              Выбор редакции
            </span>
          </div>
          <p className="states-intro">
            Самый спокойный вариант — в разных состояниях. Комфорт остаётся, даже когда планы
            меняются.
          </p>
          <div className="states-grid">
            {statePreviews.map((state, i) => (
              <article key={state.id}>
                <div className="state-label">
                  <span>0{i + 1}</span>
                  <h3>{state.title}</h3>
                  <p>{state.desc}</p>
                </div>
                <Phone direction="warm" preview={state.id} initialScreen={state.screen} />
              </article>
            ))}
          </div>
        </section>
        <section className="system-section">
          <div>
            <span className="section-kicker">ОБЩАЯ ОСНОВА</span>
            <h2>
              Четыре характера.
              <br />
              Одна забота о вас.
            </h2>
          </div>
          <div className="system-detail">
            <Icon name="target" />
            <h3>Удобно одной рукой</h3>
            <p>Зоны касания от 48 px, навигация внизу и безопасные отступы.</p>
          </div>
          <div className="system-detail">
            <Icon name="leaf" />
            <h3>Без лишнего шума</h3>
            <p>Читаемый текст, понятные состояния и только нужные действия.</p>
          </div>
          <div className="system-detail">
            <Icon name="settings" />
            <h3>Гибкая система</h3>
            <p>Общие React-компоненты, цветовые токены и адаптивная компоновка.</p>
          </div>
        </section>
      </main>
      <footer className="studio-footer">
        <span className="footer-logo">daily.</span>
        <span>Личное пространство для обычных, важных дней.</span>
        <button onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}>
          В начало
          <Icon name="arrow" size={16} />
        </button>
      </footer>
      {focus && (
        <div
          className="focus-overlay"
          role="dialog"
          aria-modal="true"
          aria-label="Интерактивный прототип"
        >
          <button
            className="focus-backdrop"
            onClick={() => setFocus(null)}
            aria-label="Закрыть прототип"
          />
          <div className="focus-content">
            <div className="focus-heading">
              <span>{directions.find((d) => d.id === focus)?.title}</span>
              <button onClick={() => setFocus(null)} aria-label="Закрыть">
                <Icon name="close" />
              </button>
            </div>
            <Phone
              direction={focus}
              initialScreen={
                tabs.some((t) => t.id === activeSection) ? (activeSection as Screen) : "today"
              }
              expanded
            />
            <p>Нажмите на задачу · удерживайте для меню</p>
          </div>
        </div>
      )}
    </div>
  );
}
