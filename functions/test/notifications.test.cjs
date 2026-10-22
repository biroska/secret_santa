const assert = require("node:assert/strict");
const test = require("node:test");

const { extractNotifiableUserIds } = require("../lib/notifications");

test("extractNotifiableUserIds filters dependents and synthetic ids", () => {
  const participants = [
    { userId: "uid-admin", isDependent: false },
    { userId: "uid-p2", isDependent: false },
    { userId: "dependent-D1", isDependent: true },
    { userId: "dependent-D2", isDependent: false },
    { userId: "", isDependent: false },
    { isDependent: false },
    null,
    { userId: "uid-admin", isDependent: false },
  ];

  assert.deepEqual(extractNotifiableUserIds(participants).sort(), [
    "uid-admin",
    "uid-p2",
  ]);
});

test("extractNotifiableUserIds returns an empty list for no participants", () => {
  assert.deepEqual(extractNotifiableUserIds([]), []);
});
