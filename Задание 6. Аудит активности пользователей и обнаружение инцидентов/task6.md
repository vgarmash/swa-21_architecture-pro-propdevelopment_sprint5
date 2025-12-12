# Задание 6. Аудит активности пользователей и обнаружение инцидентов

Вам необходимо настроить аудит активности пользователей, чтобы своевременно обнаруживать аномалии, попытки несанкционированного доступа и другие угрозы.
Что нужно сделать

## Шаг 1. Настройте среду
Minikube с включённым audit-policy.yaml и экспортом лога (/var/log/audit.log).
```yaml 
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  verbs: \["create", "delete", "update", "patch", "get", "list"\]
  resources:
    - group: ""
      resources: \["pods", "secrets", "configmaps", "serviceaccounts", "roles", "rolebindings"\]
- level: Metadata
  resources:
    - group: "\*"
      resources: \["\*"\]
```    

## Шаг 2. Запустите скрипт симуляции действий

```
bash simulate-incident.sh
```

Скрипт выполняет следующие действия:
* Доступ к secrets от system:serviceaccount:monitoring.
* Создание привилегированного пода.
* Использование kubectl exec в чужом поде.
* Удаление audit-policy.
* Создание RoleBinding без согласования.


## Шаг 3. Проведите анализ audit.log
Найдите и распишите:
*   Кто инициировал каждое из действий.
*   Какие действия могли быть вредоносными.
*   Что можно считать компрометацией кластера.
*   Какие ошибки допускает политика RBAC.

Для анализа подготовьте скрипт.

На проверку вам нужно передать три артефакта:
1. analysis.md: краткий отчёт по выявленным событиям.

    Шаблон отчёта:
    
    ```markdown
    # Отчёт по результатам анализа Kubernetes Audit Log
    
    ## Подозрительные события
    
    1. Доступ к секретам:
       - Кто: ...
       - Где: ...
       - Почему подозрительно: ...
    
    2. Привилегированные поды:
       - Кто: ...
       - Комментарий: ...
    
    3. Использование kubectl exec в чужом поде:
       - Кто: ...
       - Что делал: ...
    
    4. Создание RoleBinding с правами cluster-admin:
       - Кто: ...
       - К чему привело: ...
    
    5. Удаление audit-policy.yaml:
       - Кто: ...
       - Возможные последствия: ...
    
    ## Вывод
    
    ...
    
    ```
1. audit-extract.json: выжимка из audit.log, содержащая подозрительные события.
1. Скрипт фильтрации audit.log, написанный на Bash или Python.

## Как проверить самостоятельно
1. Проверка на события доступа к secrets:
    ```
    jq 'select(.objectRef.resource=="secrets" and .verb=="get")' audit.log
    ```
1. Проверка на kubectl exec в чужие поды:
    ```
    jq 'select(.verb=="create" and .objectRef.subresource=="exec")' audit.log
    ```
1. Привилегированные поды:
    ```
    jq 'select(.objectRef.resource=="pods" and .requestObject.spec.containers[].securityContext.privileged==true)' audit.log
    ```
1. Удаление или изменение audit policy:
    ```
    grep -i 'audit-policy' audit.log
    ```
   
Когда вы выполните задание, у вас должно получиться три файла: analysis.md — краткий отчёт по выявленным событиям, audit-extract.json — выжимка из audit.log с подозрительными событиями и скрипт фильтрации audit.log на Bash или Python. Когда будете сдавать работу, загрузите файлы в директорию Task6 в рамках пул-реквеста.