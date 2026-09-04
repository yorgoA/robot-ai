*** Variables ***
# Base URLs — override at CLI: --variable BASE_URL:https://staging.shopdemo.com
${BASE_URL}             http://localhost:5173
${API_BASE_URL}         http://localhost:3000

# Browser
${BROWSER}              chromium
${HEADLESS}             ${TRUE}
${DEFAULT_TIMEOUT}      10s

# Test credentials — a shared account the suite creates for itself via
# "Ensure The Test Account Exists" (see resources/keywords/given.resource),
# so no manually pre-registered user is required. Override at the CLI or via
# env vars for a different environment: --variable VALID_EMAIL:qa@example.com
${VALID_EMAIL}          %{SHOPDEMO_TEST_EMAIL=qa.robot@example.com}
${VALID_PASSWORD}       %{SHOPDEMO_TEST_PASSWORD=Test123!}
${INVALID_EMAIL}        wrong@shopdemo.com
${INVALID_PASSWORD}     wrongpassword

# API defaults
&{API_HEADERS}          Content-Type=application/json    Accept=application/json
${API_TIMEOUT}          10
