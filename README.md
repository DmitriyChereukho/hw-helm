# Что было сделано

Приложение muffin-wallet развернуто в Kubernetes (minikube) с помощью Helm / Helmfile.

В приложении включён Spring Boot Actuator и endpoint /actuator/prometheus для экспорта метрик.

Установлен Prometheus Operator (kube-prometheus-stack).

Создан ServiceMonitor, который находит сервис muffin-wallet и регулярно собирает метрики с /actuator/prometheus.

Настроен доступ к приложению через Istio Gateway по адресу http://prometheus.example.com/.

# Запуск кластера и приложения

## Запуск minikube

minikube start

## Развёртывание приложения (должны быть установлены helm, helmfile, istio)

helmfile sync

## Получение доступа к кластеру

minikube tunnel

Хосты должны резолвиться, например через добавление в etc/hosts

# Проверка метрик

## Нагрузка

Нагрузку можно создать на http://wallet.example.com/

## Запросы в секунду (RPS):

sum by (method, uri) (
  rate(http_server_requests_seconds_count[1m])
)


## Количество ошибок:

increase(logback_events_total{level="error"}[5m])

## 99-й персентиль времени ответа:

histogram_quantile(
  0.99,
  sum by (le)(
    rate(http_server_requests_seconds_bucket[5m])
  )
)

## Количество соединений с БД:

hikaricp_connections_active

## Размер пула соединений с БД

hikaricp_connections_max
