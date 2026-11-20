export type Task = { id: number; title: string; done: boolean; date: string };

export function sortTasks(tasks: Task[]): Task[] {
  return [...tasks].sort((a, b) => Number(a.done) - Number(b.done));
}

export function copyUnfinished(tasks: Task[], date: string, idStart = Date.now()): Task[] {
  const tomorrow = new Date(`${date}T12:00:00Z`);
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  const targetDate = tomorrow.toISOString().slice(0, 10);
  return tasks
    .filter((task) => task.date === date && !task.done)
    .filter(
      (task) =>
        !tasks.some((existing) => existing.date === targetDate && existing.title === task.title),
    )
    .map((task, index) => ({ ...task, id: idStart + index, date: targetDate }));
}

export function parseTaskBackup(json: string, idStart = Date.now()): Task[] {
  const data: unknown = JSON.parse(json);
  if (!Array.isArray(data)) throw new Error("Ожидается список задач");
  return data.map((task, index) => {
    if (
      !task ||
      typeof task !== "object" ||
      typeof task.title !== "string" ||
      !task.title.trim() ||
      task.title.length > 160 ||
      typeof task.done !== "boolean" ||
      typeof task.date !== "string" ||
      !/^\d{4}-\d{2}-\d{2}$/.test(task.date) ||
      Number.isNaN(Date.parse(task.date)) ||
      new Date(task.date).toISOString().slice(0, 10) !== task.date
    )
      throw new Error("Некорректная задача");
    return { id: idStart + index, title: task.title.trim(), done: task.done, date: task.date };
  });
}
