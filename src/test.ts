import http from "k6/http";
import { check, sleep } from "k6";
import {
  fetchDocumentRevision,
  updateDocument,
  generateRandomLatitude,
  logError,
  logInfo,
} from "./helpers.js";

const CAR_DB_URL = __ENV.DB_HOST;
const DATABASE_NAME = __ENV.NEW_DB_NAME;
const DOCUMENT_ID_CAR = __ENV.DOC_ID_CAR;

// Dynamically import the options file based on the environment variable
const optionsFile = __ENV.OPTIONS_FILE;

export const options = {
  vus: 1,
  duration: "2s",
};

export default function () {
  const url = `http://${CAR_DB_URL}/${DATABASE_NAME}/${DOCUMENT_ID_CAR}`;
  const revision = fetchDocumentRevision(url);

  if (!revision) {
    logError("Failed to fetch document revision.");
    return;
  }

  logInfo(`Document revision: ${revision}`);

  // Set document ID
  const documentId = DOCUMENT_ID_CAR;
  // Generate a random latitude
  const randomLatitude = generateRandomLatitude();

  // Use the current time of execution as the car_name
  const currentTime = new Date().toISOString();

  // Update the document
  const updated = updateDocument(
    url,
    documentId,
    revision,
    randomLatitude,
    currentTime
  );

  if (updated) {
    logInfo(
      `Document updated successfully with latitude: ${randomLatitude} and car_name: ${currentTime}`
    );
  } else {
    logError("Failed to update the document.");
  }

  sleep(1);
}
