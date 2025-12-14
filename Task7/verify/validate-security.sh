#!/bin/bash

echo "=== Проверка безопасности пода ==="
echo

# Функция для проверки пода
check_pod_security() {
    local pod_file=$1
    echo "Проверка: $(basename $pod_file)"

    # Проверяем privileged
    if grep -q "privileged: true" "$pod_file"; then
        echo "  ✗ Нарушение: privileged: true"
        return 1
    fi

    # Проверяем hostPath
    if grep -q "hostPath:" "$pod_file"; then
        echo "  ✗ Нарушение: hostPath volume"
        return 1
    fi

    # Проверяем runAsUser: 0
    if grep -q "runAsUser: 0" "$pod_file"; then
        echo "  ✗ Нарушение: runAsUser: 0 (root)"
        return 1
    fi

    # Проверяем отсутствие runAsNonRoot: true
    if ! grep -q "runAsNonRoot: true" "$pod_file"; then
        echo "  ✗ Нарушение: отсутствует runAsNonRoot: true"
        return 1
    fi

    # Проверяем readOnlyRootFilesystem
    if ! grep -q "readOnlyRootFilesystem: true" "$pod_file"; then
        echo "  ⚠ Предупреждение: рекомендуется readOnlyRootFilesystem: true"
    fi

    echo "  ✓ Безопасен"
    return 0
}

echo "Проверка небезопасных манифестов:"
for file in insecure-manifests/*.yaml; do
    check_pod_security "$file"
done

echo
echo "Проверка безопасных манифестов:"
for file in secure-manifests/*.yaml; do
    check_pod_security "$file"
done

echo
echo "=== Проверка Gatekeeper ==="
echo "1. ConstraintTemplates:"
kubectl get constrainttemplates -o name | grep -E "privileged|hostpath|runasnonroot"
echo
echo "2. Constraints:"
kubectl get constraints -o name | grep -E "privileged|hostpath|runasnonroot"
echo
echo "3. Проверяем работу Gatekeeper:"
echo "   (запустите verify-admission.sh для полной проверки)"