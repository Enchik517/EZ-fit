FROM denoland/deno:1.37.0

WORKDIR /app

# Копируем файлы
COPY . .

# Устанавливаем переменные окружения
ENV GEMINI_API_KEY=AIzaSyDC0n2jCKm5K2jL-9oeb_jYCcsINaGqjjY

# Запускаем приложение
CMD ["deno", "run", "--allow-net", "--allow-env", "index.ts"] 