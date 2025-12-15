#!/bin/bash

echo "=== Проверка Pod Security Admission ==="
echo

# Проверяем namespace
echo "1. Проверяем namespace audit-zone:"
kubectl get namespace audit-zone -o jsonpath='{.metadata.labels}' | jq .
echo

# Пробуем создать небезопасные пода
echo "2. Пробуем создать небезопасные пода:"
echo "   а) Privileged pod:"
kubectl apply -f insecure-manifests/01-privileged-pod.yaml 2>&1 | grep -E "denied|error|Forbidden" || echo "   Успешно создан (не должно быть!)"
echo

echo "   б) HostPath pod:"
kubectl apply -f insecure-manifests/02-hostpath-pod.yaml 2>&1 | grep -E "denied|error|Forbidden" || echo "   Успешно создан (не должно быть!)"
echo

echo "   в) Root user pod:"
kubectl apply -f insecure-manifests/03-root-user-pod.yaml 2>&1 | grep -E "denied|error|Forbidden" || echo "   Успешно создан (не должно быть!)"
echo

# Пробуем создать безопасные пода
echo "3. Пробуем создать безопасные пода:"
echo "   а) Secure pod 1:"
kubectl apply -f secure-manifests/01-secure.yaml 2>&1 | grep -E "created|configured" && echo "   ✓ Успешно создан"
echo

echo "   б) Secure pod 2:"
kubectl apply -f secure-manifests/02-secure.yaml 2>&1 | grep -E "created|configured" && echo "   ✓ Успешно создан"
echo

echo "   в) Secure pod 3:"
kubectl apply -f secure-manifests/03-secure.yaml 2>&1 | grep -E "created|configured" && echo "   ✓ Успешно создан"
echo

# Очистка
echo "4. Очистка:"
kubectl delete -f secure-manifests/ --ignore-not-found=true
echo "   ✓ Очищено"