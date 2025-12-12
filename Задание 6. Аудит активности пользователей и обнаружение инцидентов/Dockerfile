FROM alpine:latest

RUN apk add --no-cache jq grep

WORKDIR /app
COPY audit.log ./

# 1. Исправленный фильтр для secrets - ищем не только get, но и watch/list
RUN echo "=== Тестирование фильтров ===" > /app/filter-test.txt && \
    echo "1. Поиск secrets (get или watch):" >> /app/filter-test.txt && \
    jq 'select(.objectRef.resource=="secrets" and (.verb=="get" or .verb=="watch" or .verb=="list"))' audit.log | head -3 >> /app/filter-test.txt 2>&1 && \
    echo "" >> /app/filter-test.txt && \
    echo "2. Поиск exec (любой verb с subresource exec):" >> /app/filter-test.txt && \
    jq 'select(.objectRef.subresource=="exec")' audit.log | head -3 >> /app/filter-test.txt 2>&1 && \
    echo "" >> /app/filter-test.txt && \
    echo "3. Поиск privileged containers:" >> /app/filter-test.txt && \
    jq 'select(.objectRef.resource=="pods" and .requestObject.spec.containers[].securityContext.privileged==true)' audit.log | head -3 >> /app/filter-test.txt 2>&1

# Создаем итоговый файл с исправленными фильтрами
RUN echo "[" > audit-extract.json && \
    # 1. Secrets: get, watch или list
    jq -c 'select(.objectRef.resource=="secrets" and (.verb=="get" or .verb=="watch" or .verb=="list"))' audit.log 2>/dev/null | sed '$!s/$/,/' >> audit-extract.json && \
    # 2. Exec: любая операция с subresource exec
    jq -c 'select(.objectRef.subresource=="exec")' audit.log 2>/dev/null | sed '$!s/$/,/' >> audit-extract.json && \
    # 3. Privileged containers (если есть requestObject)
    jq -c 'select(.objectRef.resource=="pods" and .requestObject.spec.containers[].securityContext.privileged==true)' audit.log 2>/dev/null | sed '$!s/$/,/' >> audit-extract.json && \
    echo "]" >> audit-extract.json

# Исправляем JSON (убираем лишние запятые)
RUN sed -i '${/^,$/d}' audit-extract.json 2>/dev/null && \
    sed -i 's/,]/]/' audit-extract.json 2>/dev/null || true && \
    # Если файл пустой или невалидный
    jq . audit-extract.json > /dev/null 2>&1 || echo '[]' > audit-extract.json

VOLUME /export

CMD ["sh", "-c", "echo '=== Результаты анализа ===' && \
      echo 'Найдено записей: $(jq length /app/audit-extract.json 2>/dev/null || echo 0)' && \
      echo '' && \
      echo '=== Примеры найденных записей ===' && \
      jq '.[0:2]' /app/audit-extract.json 2>/dev/null || echo 'Нет записей' && \
      echo '' && \
      echo '=== Фильтры тест ===' && \
      cat /app/filter-test.txt && \
      echo '' && \
      cp /app/audit-extract.json /export/"]