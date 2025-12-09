# **Таблица ролей для PropDevelopment**

| Роль | Права роли | Группы пользователей | Namespace |
|------|------------|----------------------|-----------|
| **cluster-admin-propdev** | Полный доступ ко всем ресурсам кластера во всех namespace. Доступ ко всем API-группам, ресурсам и non-resource URLs. | DevOps-инженеры, Специалист по ИБ | Все namespace |
| **security-auditor** | Чтение всех ресурсов кластера во всех namespace (get, list, watch). Может просматривать, но не изменять. | Специалист по ИБ, Аудиторы безопасности | Все namespace |
| **namespace-viewer** | Просмотр основных ресурсов (pods, deployments, services, configmaps, jobs, cronjobs) во всех namespace. | Менеджеры, Бизнес-аналитики, Операционная команда | Все namespace |
| **developer-client** | Полный доступ (create, read, update, delete) к ресурсам в namespace client-services. Включает pods, deployments, services, configmaps, secrets, PVC, jobs, network policies. | Разработчики клиентских сервисов, Инженеры по эксплуатации (домен продаж) | client-services |
| **developer-tenant** | Полный доступ (create, read, update, delete) к ресурсам в namespace tenant-services. Включает pods, deployments, services, configmaps, secrets, PVC, jobs, network policies. | Разработчики сервисов ЖКУ, Инженеры по эксплуатации (домен ЖКУ) | tenant-services |
| **bi-analyst** | Чтение ресурсов (get, list, watch) и доступ к логам в namespace bi-services. Может просматривать pods, configmaps, PVC, deployments, statefulsets, читать логи. | Аналитики данных, Data Scientists, BI-специалисты | bi-services |
| **accounting-viewer** | Только чтение ресурсов (get, list, watch) в namespace accounting-services. Может просматривать pods, deployments, services, configmaps. | Бухгалтеры, Финансовый отдел, Аудиторы финансов | accounting-services |
| **pod-viewer** | Базовый просмотр pods (get, list, watch) в namespace default. Минимальные права для всех разработчиков. | Все разработчики, Тестировщики | default |

---

## **Ключевые принципы доступа:**

### **Принцип наименьших привилегий**
- Каждая роль имеет минимально необходимые права для выполнения задач
- Разделение прав между namespace предотвращает горизонтальную эскалацию

### **Разделение по доменам бизнеса**
1. **client-services** - Клиентские сервисы (продажи, CRM, онлайн-сделки)
2. **tenant-services** - Сервисы для собственников (ЖКУ, Умный дом)
3. **bi-services** - Обработка данных, аналитика, BI
4. **accounting-services** - Финансовые системы, бухгалтерия

### **Соответствие организационной структуре**
- DevOps/Security: полный доступ для поддержки инфраструктуры
- Разработчики: полный доступ в своём домене, только просмотр в других
- Бизнес-пользователи: только просмотр для мониторинга
- Специалисты данных: доступ к данным и логам для аналитики

### **Контроль безопасности**
- Аудиторы могут читать всё, но не могут изменять
- Чёткое разделение production namespace
- Логирование всех операций доступа через аудиторскую роль

# 1. Создать namespaces
kubectl apply -f ./kuber/namespace.yaml

# 2. Создать пользователей (ServiceAccounts)
kubectl apply -f ./kuber/users.yaml

# 3. Создать роли
kubectl apply -f ./kuber/role.yaml

# 4. Привязать роли к пользователям
kubectl apply -f ./kuber/role-binding.yaml

# 5. Проверить созданные ресурсы
kubectl get serviceaccounts -n default
kubectl get roles -A
kubectl get rolebindings -A
kubectl get clusterroles
kubectl get clusterrolebindings