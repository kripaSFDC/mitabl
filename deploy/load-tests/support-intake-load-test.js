import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    support_intake: {
      executor: "ramping-vus",
      startVUs: 1,
      stages: [
        { duration: "1m", target: 20 },
        { duration: "3m", target: 20 },
        { duration: "1m", target: 0 },
      ],
      gracefulRampDown: "30s",
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.02"],
    http_req_duration: ["p(95)<750"],
  },
};

const baseUrl = __ENV.BASE_URL || "http://localhost:8000";
const captchaToken = __ENV.CAPTCHA_TOKEN || "";

export default function () {
  const correlation = `k6-${__VU}-${__ITER}-${Date.now()}`;
  const body = {
    requester_name: "Load Test",
    requester_email: `load+${correlation}@example.com`,
    requester_phone: "0400111222",
    subject: `Load ticket ${correlation}`,
    description: "Load test ticket payload for support intake endpoint.",
    category: "general",
    priority: "normal",
  };

  if (captchaToken) {
    body.captcha_token = captchaToken;
  }

  const payload = JSON.stringify(body);

  const response = http.post(`${baseUrl}/api/support/ticket`, payload, {
    headers: {
      "Content-Type": "application/json",
      "X-Request-Id": correlation,
    },
    tags: { endpoint: "support_ticket_store" },
  });

  check(response, {
    "support intake returns 200": (r) => r.status === 200,
    "support intake response marks success": (r) => {
      try {
        return r.json("isSuccess") === true;
      } catch (e) {
        return false;
      }
    },
  });

  sleep(0.25);
}
