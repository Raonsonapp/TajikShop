name: 🔄 Keep Server Alive (Render.com)

on:
  schedule:
    # Ҳар 14 дақиқа ping мекунад — сервер нахобад (15 дақиқа limit)
    - cron: '*/14 * * * *'
  workflow_dispatch:

jobs:
  ping:
    name: Ping tajikshop.onrender.com
    runs-on: ubuntu-latest
    steps:
      - name: 🏓 Ping server
        run: |
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time 60 \
            https://tajikshop.onrender.com/health || echo "000")
          echo "Server response: $STATUS"
          if [ "$STATUS" = "200" ] || [ "$STATUS" = "204" ]; then
            echo "✅ Сервер бедор аст!"
          else
            echo "⚠️  Сервер ҷавоб надод (status: $STATUS) — cold start шуда бошад."
          fi
