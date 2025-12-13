# Запуск minikube в Alt Linux с включенным аудитом
У нас вариация на тему [официальной инструкции](https://minikube.sigs.k8s.io/docs/tutorials/audit-policy/).
1. [Установить Docker](https://www.altlinux.org/Docker)
1. Установить minikube на хосте используя штатные средства.
    
    ```apt-get install -y minikube```

1. Установить Kubectl той же версии, что и версия кубера в Minikube. В моём случае это версия 1.28
   
   ```apt-get install -y kubernetes-1.28-client```

1. Запустить minikube первый раз, чтобы убедиться, что он запускается. Остановить его после этого.

    ```
   minikube start
   kubectl get po -A
   minikube stop
   ```
   
1. Создать папку для Audit Policy

    ```
   mkdir -p ~/.minikube/files/etc/ssl/certs
   ```
   
1. Скопировать в эту папку файл [audit-policy.yaml](audit-policy.yaml)

1. Снова запустить minikube с дополнительными параметрами

    ```
   minikube start --driver=docker \
   --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml \
   --extra-config=apiserver.audit-log-path=- \
   --extra-config=apiserver.audit-log-format=json
   ```
   
1. Проверяем minukube

    ```
   minikube status // все должны быть running
   ```
   
# Выполняем задание
1. Запускаем симуляцию активности и ждём, пока отработает

    ```
   bash ./simulate/simulate-incident.sh
   ```
   У меня вывод был такой: [simulate.log](simulate/simulate.log)
   
1. Достаем логи аудита
    * Вариант 1, но може вдруг сохранить не JSON строки 
       ```
      cd ./simulate
      kubectl logs kube-apiserver-minikube -n kube-system | grep audit.k8s.io/v1 > audit2.json
      ```
   * Вариант 2 с использованием jq для форматирования
     ```bash
     cd ./simulate
     kubectl logs kube-apiserver-minikube -n kube-system | grep -Eo '\{.*"kind":"Event".*"audit.k8s.io/v1".*\}' | jq --compact-output '.' > audit_clean.json
     ```
     
1. Сканируем логи на наличие подозрительных событий и получаем 

    ```
   bash scan-audit.sh audit2.json
   ```
   
1. Анализ полученного лога: [analysis.md](analysis.md)