# Что было сделано

Приложение muffin-wallet развернуто в Kubernetes (minikube) с помощью Helm / Helmfile.

В приложении включён Spring Boot Actuator и endpoint /actuator/prometheus для экспорта метрик.

Установлен Prometheus Operator (kube-prometheus-stack).

Создан ServiceMonitor, который находит сервис muffin-wallet и регулярно собирает метрики с /actuator/prometheus.

Настроен доступ к приложению через Istio Gateway по адресу http://prometheus.example.com/.
