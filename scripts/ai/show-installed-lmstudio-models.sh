#!/usr/bin/env bash

# Fetch models from LM Studio if running on port 1234
response=$(curl -s --connect-timeout 1 http://127.0.0.1:1234/v1/models 2>/dev/null)

if [ -z "$response" ]; then
    echo "[]"
    exit 0
fi

# Build JSON array of model IDs using jq or python
if command -v jq &>/dev/null; then
    echo "$response" | jq -c '[.data[].id | select(. != null)]'
else
    python3 -c "import sys, json; data = json.load(sys.stdin); print(json.dumps([m['id'] for m in data.get('data', [])]))" <<< "$response" 2>/dev/null || echo "[]"
fi
