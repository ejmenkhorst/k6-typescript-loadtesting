import http from "k6/http";
import { check } from "k6";
import encoding from "k6/encoding"; // Import the K6 encoding module

// Fetch document revision helper function
export function fetchDocumentRevision(url: string): string | null {
  const response = http.get(url);
  check(response, {
    "status is 200": (r) => r.status === 200,
    "response body is not empty": (r) =>
      typeof r.body === "string" && r.body.length > 0,
    "response body contains _rev": (r) =>
      typeof r.body === "string" && r.body.includes("_rev"),
  });

  if (response.status === 200) {
    try {
      const responseBody =
        typeof response.body === "string" ? JSON.parse(response.body) : null;
      return responseBody._rev || null;
    } catch (error) {
      console.error("Failed to parse response body as JSON:", error);
      return null;
    }
  }

  return null;
}

// Update document helper function
export function updateDocument(
  url: string,
  id: string,
  revision: string,
  latitude: number,
  carName: string
): boolean {
  // Construct the payload as a JSON object
  const payload = JSON.stringify({
    _id: id,
    _rev: revision,
    latitude: latitude.toString(), // Convert numbers to strings for JSON compatibility
    car_name: carName,
  });

  // Read authentication credentials from environment variables
  const dbUser = __ENV.DB_USER;
  const dbPassword = __ENV.DB_PASSWORD;

  // Encode credentials in Base64 using K6's encoding module
  const encodedCredentials = encoding.b64encode(`${dbUser}:${dbPassword}`);

  // Include Basic Authentication header and set Content-Type to application/json
  const headers = {
    "Content-Type": "application/json",
    Authorization: `Basic ${encodedCredentials}`,
  };

  // Send the PUT request with JSON payload
  const response = http.put(url, payload, { headers });

  check(response, {
    "status is 201 or 200": (r) => r.status === 201 || r.status === 200,
  });

  if (response.status === 201 || response.status === 200) {
    console.log("Document updated successfully.");
    return true;
  } else {
    console.error(`Failed to update document. Status: ${response.status}`);
    return false;
  }
}

// Generate random latitude within a range
export function generateRandomLatitude(
  min: number = -90,
  max: number = 90
): number {
  return Math.random() * (max - min) + min;
}
