*** Variables ***
# Base URLs — override at CLI: --variable BASE_URL:https://staging.shopdemo.com
${BASE_URL}             http://localhost:5173
${API_BASE_URL}         http://localhost:3000

# Browser
${BROWSER}              chromium
${HEADLESS}             ${TRUE}
${DEFAULT_TIMEOUT}      10s

# Test credentials
${VALID_EMAIL}          yorgo@hotmail.com
${VALID_PASSWORD}       Test123!
${INVALID_EMAIL}        wrong@shopdemo.com
${INVALID_PASSWORD}     wrongpassword

# API defaults
&{API_HEADERS}          Content-Type=application/json    Accept=application/json
${API_TIMEOUT}          10
