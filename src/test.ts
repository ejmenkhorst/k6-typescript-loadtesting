import http from "k6/http";
import { check, sleep } from "k6";
import {
  fetchDocumentRevision,
  updateDocument,
  generateRandomLatitude,
  logError,
  logInfo,
} from "./helpers.js";

// Dynamically import the options file based on the environment variable
const optionsFile = __ENV.OPTIONS_FILE || "optionsLoadTest"; // Default to optionsLoadTest
const { options } = require(`./options/${optionsFile}.js`); // Dynamically load the options file

const CAR_DB_URL = __ENV.DB_HOST;
const DATABASE_NAME = __ENV.NEW_DB_NAME;
const DOCUMENT_ID_CAR = __ENV.DOC_ID_CAR;

export { options }; // Export the dynamically loaded options

export default function () {
  const url = `http://${CAR_DB_URL}/${DATABASE_NAME}/${DOCUMENT_ID_CAR}`;
  const revision = fetchDocumentRevision(url);

  if (!revision) {
    logError("Failed to fetch document revision.");
    return;
  }

  logInfo(`Document revision: ${revision}`);

  const documentId = DOCUMENT_ID_CAR;
  const randomLatitude = generateRandomLatitude();
  const currentTime = new Date().toISOString();

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

  sleep(5);
}
