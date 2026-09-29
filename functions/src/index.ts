import { initializeApp } from "firebase-admin/app";

initializeApp();

export { getMyDraw, performDraw, validateEventDraw } from "./draw";
