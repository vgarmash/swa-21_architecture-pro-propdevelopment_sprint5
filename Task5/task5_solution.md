# Инструкция по настройке сетевых политик в Kubernetes

## Цель
Разграничить трафик между сервисами в кластере Kubernetes, разрешив связь только между определёнными парами подов.

---

## 1. Развертывание подов с метками

Выполните следующие команды для создания 4 подов на основе образа Nginx с соответствующими метками:

```bash
kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80
```

**Результат:**
- 4 пода с сервисами
- Каждому поду назначена метка `role` в соответствии с его функцией

---

## 2. Создание файла сетевой политики
[non-admin-api-allow.yaml](non-admin-api-allow.yaml)

**Описание политик:**
1. `non-admin-api-allow` — разрешает трафик от `front-end` к `back-end-api`
2. `admin-api-allow` — разрешает трафик от `admin-front-end` к `admin-back-end-api`

---

## 3. Применение сетевой политики

Выполните команду для применения политики:

```bash
kubectl apply -f non-admin-api-allow.yaml
```

**Ожидаемый вывод:**
```
networkpolicy.networking.k8s.io/non-admin-api-allow created
networkpolicy.networking.k8s.io/admin-api-allow created
```

---

## 4. Проверка связности

### Проверка разрешённых соединений

1. **front-end → back-end-api:**
```bash
kubectl run test-front --rm -i -t --image=alpine --labels role=front-end -- sh
/ # wget -qO- --timeout=2 http://back-end-api-app
```
**Ожидаемый результат:** Успешное подключение (возвращается HTML-код Nginx)

2. **admin-front-end → admin-back-end-api:**
```bash
kubectl run test-admin --rm -i -t --image=alpine --labels role=admin-front-end -- sh
/ # wget -qO- --timeout=2 http://admin-back-end-api-app
```
**Ожидаемый результат:** Успешное подключение

### Проверка запрещённых соединений

3. **front-end → admin-back-end-api:**
```bash
kubectl run test-front2 --rm -i -t --image=alpine --labels role=front-end -- sh
/ # wget -qO- --timeout=2 http://admin-back-end-api-app
```
**Ожидаемый результат:** Таймаут или ошибка соединения

4. **admin-front-end → back-end-api:**
```bash
kubectl run test-admin2 --rm -i -t --image=alpine --labels role=admin-front-end -- sh
/ # wget -qO- --timeout=2 http://back-end-api-app
```
**Ожидаемый результат:** Таймаут или ошибка соединения

---

## 5. Верификация конфигурации

Проверьте созданные сетевые политики:

```bash
kubectl get networkpolicies
```

Проверьте метки подов:

```bash
kubectl get pods --show-labels
```

---

## 6. Итоговый результат

После выполнения всех шагов вы получите:
- 4 работающих пода с Nginx
- 2 сетевые политики, изолирующие трафик
- Разрешённые соединения:
    - `front-end` ↔ `back-end-api`
    - `admin-front-end` ↔ `admin-back-end-api`
- Запрещённые все остальные межсервисные соединения

---

## Примечания

Все команды выполняются в namespace `default`. При необходимости укажите другой namespace через флаг `-n`