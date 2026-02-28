import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    admin_lists: {
      executor: "constant-vus",
      vus: 10,
      duration: "5m",
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<900"],
  },
};

const baseUrl = __ENV.BASE_URL || "http://localhost:8001";
const adminCookie = __ENV.ADMIN_COOKIE || "";

if (!adminCookie) {
  throw new Error("ADMIN_COOKIE env var is required for admin list load test.");
}

function request(path, tag) {
  return http.get(`${baseUrl}${path}`, {
    headers: {
      Cookie: adminCookie,
      Accept: "text/html,application/xhtml+xml",
    },
    tags: { endpoint: tag },
  });
}

export default function () {
  const policies = request("/admin/policies", "admin_policies_index");
  check(policies, {
    "policies list accessible": (r) => r.status === 200,
  });

  const tickets = request("/admin/support-tickets", "admin_support_tickets_index");
  check(tickets, {
    "support tickets list accessible": (r) => r.status === 200,
  });

  sleep(0.5);
}
