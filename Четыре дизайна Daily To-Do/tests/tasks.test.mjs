import assert from "node:assert/strict";
import test from "node:test";
import { sortTasks, copyUnfinished, parseTaskBackup } from "../src/tasks.ts";

const tasks = [
  { id: 1, title: "Прочитать 20 страниц", done: false, date: "2026-06-18" },
  { id: 2, title: "Закончить проект", done: true, date: "2026-06-18" },
  { id: 3, title: "Купить продукты", done: false, date: "2026-06-18" },
];

test("completed tasks move below unfinished tasks, without mutating the source", () => {
  assert.deepEqual(
    sortTasks(tasks).map((t) => t.id),
    [1, 3, 2],
  );
  assert.deepEqual(
    tasks.map((t) => t.id),
    [1, 2, 3],
  );
});
test("copy includes only unfinished tasks and preserves originals", () => {
  const copies = copyUnfinished(tasks, "2026-06-18", 10);
  assert.equal(copies.length, 2);
  assert.ok(copies.every((t) => t.date === "2026-06-19" && !t.done));
  assert.deepEqual(
    copies.map((t) => t.id),
    [10, 11],
  );
  assert.equal(tasks[0].date, "2026-06-18");
});
test("copying twice does not duplicate tomorrow’s tasks", () => {
  const copies = copyUnfinished(tasks, "2026-06-18", 10);
  assert.deepEqual(copyUnfinished([...tasks, ...copies], "2026-06-18", 20), []);
});
test("tomorrow is calculated correctly across year boundaries", () => {
  const copies = copyUnfinished([{ ...tasks[0], date: "2026-12-31" }], "2026-12-31", 10);
  assert.equal(copies[0].date, "2027-01-01");
});
test("empty days have nothing to copy", () => {
  assert.deepEqual(copyUnfinished(tasks, "2026-06-20"), []);
});
test("backup round-trip preserves task content and gives unique new IDs", () => {
  const imported = parseTaskBackup(JSON.stringify(tasks), 20);
  assert.deepEqual(
    imported.map(({ id, ...t }) => t),
    tasks.map(({ id, ...t }) => t),
  );
  assert.deepEqual(
    imported.map((t) => t.id),
    [20, 21, 22],
  );
});
test("invalid and impossible dates, missing fields and malformed JSON are rejected", () => {
  for (const data of [
    "{}",
    "null",
    "not json",
    JSON.stringify([{ ...tasks[0], date: "2026-02-30" }]),
    JSON.stringify([{ ...tasks[0], date: "not a date" }]),
    JSON.stringify([{ ...tasks[0], done: "true" }]),
    JSON.stringify([{ ...tasks[0], title: "   " }]),
    JSON.stringify([{ ...tasks[0], title: "я".repeat(161) }]),
  ])
    assert.throws(() => parseTaskBackup(data));
});
