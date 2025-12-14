Я внимательно изучил примеры `README_FOR_REVIEWER.md` из прикрепленных файлов и создам свою версию. Вот подробный файл README в формате Markdown:

**`README_FOR_REVIEWER.md`**:

```markdown
# Task 7 - Аудит и обеспечение соответствия политике безопасности контейнеров

## Описание задания

Задача: настроить аудит и политики безопасности для предотвращения развёртывания небезопасных подов в кластере Kubernetes.

## Что было сделано

### 1. Создан Namespace с политикой безопасности

Namespace `audit-zone` создан с уровнем Pod Security Admission `restricted`, что обеспечивает базовую защиту на уровне admission controller.

### 2. Созданы небезопасные манифесты (для демонстрации нарушений)

Три манифеста в директории `insecure-manifests/`:

1. **01-privileged-pod.yaml** - Pod с `privileged: true`
2. **02-hostpath-pod.yaml** - Pod с монтированием `hostPath`
3. **03-root-user-pod.yaml** - Pod, запускаемый от root (UID 0)

### 3. Созданы безопасные исправленные манифесты

Три исправленных манифеста в директории `secure-manifests/`:

1. **01-secure.yaml** - Безопасная версия privileged-pod
2. **02-secure.yaml** - Безопасная версия hostpath-pod  
3. **03-secure.yaml** - Безопасная версия root-user-pod

### 4. Настроен OPA Gatekeeper

Созданы Constraint Templates и Constraints для следующих правил:

#### Constraint Templates:
1. **privileged.yaml** - Запрещает использование `privileged: true`
2. **hostpath.yaml** - Запрещает использование `hostPath` volumes
3. **runasnonroot.yaml** - Требует `runAsNonRoot: true` и `readOnlyRootFilesystem: true`

#### Constraints (применение правил к namespace):
- Все правила применяются только к namespace `audit-zone`

### 5. Созданы скрипты проверки

1. **validate-security.sh** - Статическая проверка манифестов на соответствие политикам безопасности
2. **verify-admission.sh** - Динамическая проверка работы admission controllers

### 6. Настроена политика аудита

Файл `audit-policy.yaml` настроен для отслеживания событий в namespace `audit-zone`.

## Инструкция по развертыванию и проверке

### Шаг 1: Подготовка кластера

```bash
# Установка Gatekeeper (если не установлен)
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

# Ожидание готовности Gatekeeper
kubectl -n gatekeeper-system wait --for=condition=ready pod --all --timeout=300s
```

### Шаг 2: Создание namespace

```bash
kubectl apply -f 01-create-namespace.yaml
```

### Шаг 3: Установка политик Gatekeeper

```bash
# Установка Constraint Templates
kubectl apply -f gatekeeper/constraint-templates/

# Проверка установки Constraint Templates
kubectl get constrainttemplates

# Установка Constraints
kubectl apply -f gatekeeper/constraints/

# Проверка установки Constraints
kubectl get constraints
```

### Шаг 4: Проверка работы

```bash
# Даем права на выполнение скриптов
chmod +x verify/*.sh

# Проверка статической безопасности манифестов
./verify/validate-security.sh

# Проверка работы admission controllers
./verify/verify-admission.sh
```

### Шаг 5: Проверка небезопасных манифестов (должны быть отклонены)

```bash
# Попытка создания небезопасных подов
kubectl apply -f insecure-manifests/01-privileged-pod.yaml
# Ожидаемый результат: Forbidden/Denied

kubectl apply -f insecure-manifests/02-hostpath-pod.yaml
# Ожидаемый результат: Forbidden/Denied

kubectl apply -f insecure-manifests/03-root-user-pod.yaml
# Ожидаемый результат: Forbidden/Denied
```

### Шаг 6: Проверка безопасных манифестов (должны быть созданы)

```bash
# Создание безопасных подов
kubectl apply -f secure-manifests/01-secure.yaml
kubectl apply -f secure-manifests/02-secure.yaml
kubectl apply -f secure-manifests/03-secure.yaml

# Проверка состояния подов
kubectl get pods -n audit-zone
```

### Шаг 7: Проверка аудита (если включен audit logging)

```bash
# Просмотр событий в namespace
kubectl get events -n audit-zone --sort-by='.lastTimestamp'

# Проверка violation от Gatekeeper
kubectl get k8sprivilegedcontainers.constraints.gatekeeper.sh -o yaml
kubectl get k8shostpathvolumes.constraints.gatekeeper.sh -o yaml
kubectl get k8srunasnonroot.constraints.gatekeeper.sh -o yaml
```

## Ожидаемые результаты проверки

### 1. Pod Security Admission
- Namespace `audit-zone` должен иметь label `pod-security.kubernetes.io/enforce: restricted`
- Небезопасные пода должны быть отклонены admission controller

### 2. OPA Gatekeeper
- Constraint Templates должны быть установлены
- Constraints должны быть активны
- Gatekeeper должен отклонять манифесты с нарушениями

### 3. Небезопасные манифесты должны быть отклонены:
- **01-privileged-pod.yaml**: отклонен из-за `privileged: true`
- **02-hostpath-pod.yaml**: отклонен из-за использования `hostPath`
- **03-root-user-pod.yaml**: отклонен из-за `runAsUser: 0`

### 4. Безопасные манифесты должны быть созданы:
- Все три пода из `secure-manifests/` успешно создаются и работают

### 5. Проверка скриптами:
- `validate-security.sh` должен показывать нарушения в insecure-манифестах
- `verify-admission.sh` должен демонстрировать работу admission controllers