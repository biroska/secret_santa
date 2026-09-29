const assert = require("node:assert/strict");
const test = require("node:test");

const {
  generateDraw,
  ImpossibleDrawError,
  validateDrawAssignments,
} = require("../lib/drawLogic");

test("rejects dependent with no allowed receiver", () => {
  const participants = [
    {
      participantId: "A",
      isDependent: false,
      canSortResponsible: false,
      responsibleIds: [],
    },
    {
      participantId: "L",
      isDependent: false,
      canSortResponsible: false,
      responsibleIds: [],
    },
    {
      participantId: "B",
      isDependent: true,
      canSortResponsible: false,
      responsibleIds: ["A", "L"],
    },
  ];

  assert.throws(
    () => generateDraw(participants, () => 0),
    (error) =>
      error instanceof ImpossibleDrawError &&
      error.message.includes('"B"') &&
      error.message.includes("ninguém")
  );
});

test("rejects when each giver has candidates but no complete matching exists", () => {
  const participants = [
    {
      participantId: "A",
      isDependent: true,
      canSortResponsible: false,
      responsibleIds: ["B"],
    },
    {
      participantId: "B",
      isDependent: true,
      canSortResponsible: false,
      responsibleIds: ["A"],
    },
    {
      participantId: "C",
      isDependent: false,
      canSortResponsible: false,
      responsibleIds: [],
    },
  ];

  assert.throws(
    () => generateDraw(participants, () => 0),
    (error) =>
      error instanceof ImpossibleDrawError &&
      error.message.includes("Não foi possível gerar um sorteio válido")
  );
});

test("rejects responsible IDs that do not belong to the event", () => {
  const participants = [
    {
      participantId: "D1",
      isDependent: true,
      canSortResponsible: false,
      responsibleIds: ["unknown"],
    },
    {
      participantId: "P1",
      isDependent: false,
      canSortResponsible: false,
      responsibleIds: [],
    },
  ];

  assert.throws(
    () => generateDraw(participants, () => 0),
    (error) =>
      error instanceof ImpossibleDrawError &&
      error.message.includes("não pertencem ao evento")
  );
});

test("generates a complete draw when constraints allow one", () => {
  const participants = [
    {
      participantId: "A",
      isDependent: false,
      canSortResponsible: false,
      responsibleIds: [],
    },
    {
      participantId: "L",
      isDependent: false,
      canSortResponsible: false,
      responsibleIds: [],
    },
    {
      participantId: "B",
      isDependent: true,
      canSortResponsible: false,
      responsibleIds: ["A"],
    },
  ];

  const pairs = generateDraw(participants, () => 0);

  assert.equal(pairs.length, participants.length);
  assert.equal(new Set(pairs.map((pair) => pair.giverId)).size, participants.length);
  assert.equal(new Set(pairs.map((pair) => pair.receiverId)).size, participants.length);
  assert.ok(
    pairs.every(
      (pair) =>
        pair.giverId !== pair.receiverId &&
        !(pair.giverId === "B" && pair.receiverId === "A")
    )
  );
});

test("validates unique givers and receivers, self-draws, and dependents", () => {
  const participants = [
    {
      participantId: "D1",
      isDependent: true,
      canSortResponsible: false,
      responsibleIds: ["P1"],
    },
    {
      participantId: "P1",
      isDependent: false,
      canSortResponsible: false,
      responsibleIds: [],
    },
    {
      participantId: "P2",
      isDependent: false,
      canSortResponsible: false,
      responsibleIds: [],
    },
  ];

  const issues = validateDrawAssignments(
    [
      { giverId: "D1", receiverId: "P1" },
      { giverId: "D1", receiverId: "P1" },
      { giverId: "P2", receiverId: "P2" },
    ],
    participants
  );

  assert.ok(issues.some((issue) => issue.includes('giverId "D1"')));
  assert.ok(issues.some((issue) => issue.includes('receiverId "P1"')));
  assert.ok(issues.some((issue) => issue.includes("para si mesmo")));
  assert.ok(issues.some((issue) => issue.includes("não pode presentear")));
});

test("rejects an empty stored draw", () => {
  const issues = validateDrawAssignments([], []);

  assert.ok(issues.some((issue) => issue.includes("Nenhum resultado")));
});

test("allows a dependent to draw a responsible when permitted", () => {
  const issues = validateDrawAssignments(
    [{ giverId: "D1", receiverId: "P1" }],
    [
      {
        participantId: "D1",
        isDependent: true,
        canSortResponsible: true,
        responsibleIds: ["P1"],
      },
      {
        participantId: "P1",
        isDependent: false,
        canSortResponsible: false,
        responsibleIds: [],
      },
    ]
  );

  assert.deepEqual(issues, []);
});
