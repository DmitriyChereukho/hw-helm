ДЗ Prometheus — мониторинг muffin-wallet
1. Описание

В рамках задания было развернуто приложение muffin-wallet в кластере Kubernetes (minikube) и настроен мониторинг производительности с использованием Prometheus.
Обеспечен сбор метрик приложения и инфраструктуры, а также подготовлены PromQL-запросы для анализа работы сервиса.

2. Архитектура решения

Используемые компоненты:

Kubernetes (minikube)

Helm / Helmfile

Spring Boot + Actuator + Micrometer

Prometheus Operator (kube-prometheus-stack)

Istio (Ingress Gateway, mTLS — опционально)

Схема:

Browser
  ↓
Istio Ingress Gateway
  ↓
muffin-wallet (Spring Boot)
  ↓
PostgreSQL

Prometheus
  └─ ServiceMonitor → /actuator/prometheus

3. Запуск кластера и приложения
3.1 Запуск minikube
minikube start

3.2 Установка Helm
helm version

3.3 Развёртывание приложения

Приложение разворачивается с помощью Helm / Helmfile:

helmfile sync


После этого в namespace muffin должны появиться pod’ы:

kubectl get pods -n muffin

4. Настройка метрик приложения
4.1 Включение Prometheus-endpoint

В приложении используется Spring Boot Actuator.
Метрики доступны по адресу:

/actuator/prometheus

4.2 Включение HTTP-histogram (обязательно для 99p)

В application.yaml включено:

management:
  metrics:
    distribution:
      percentiles-histogram:
        http.server.requests: true


Это позволяет Prometheus рассчитывать перцентили времени ответа через histogram.

5. Настройка Prometheus
5.1 Установка Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace

5.2 ServiceMonitor для muffin-wallet
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: muffin-wallet
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: muffin-wallet
  namespaceSelector:
    matchNames:
      - muffin
  endpoints:
    - port: http
      path: /actuator/prometheus
      interval: 15s


Service muffin-wallet имеет:

label app: muffin-wallet

именованный порт http

6. Проверка работоспособности
6.1 Проверка targets Prometheus

В UI Prometheus:

Status → Targets


Target muffin-wallet должен быть в состоянии UP.

6.2 Генерация нагрузки
kubectl run load -n muffin --rm -it --image=curlimages/curl -- sh

while true; do
  curl http://wallet.example.com/swagger-ui/index.html
done

7. PromQL-запросы (по заданию)
7.1 Количество запросов в секунду (RPS) по методам REST API
sum by (method, uri) (
  rate(http_server_requests_seconds_count[1m])
)

7.2 Количество ошибок в логах приложения
increase(logback_events_total{level="error"}[5m])

7.3 99-й персентиль времени ответа HTTP

Используется histogram:

histogram_quantile(
  0.99,
  sum by (le) (
    rate(http_server_requests_seconds_bucket[5m])
  )
)

7.4 Количество соединений к PostgreSQL

HikariCP метрики:

hikaricp_connections


Пиковое количество активных соединений:

max_over_time(hikaricp_connections_active[5m])


Метрика hikaricp_connections_active имеет моментальный характер и может быть равна 0 при быстром выполнении SQL-запросов. Для анализа используется агрегирование по времени.

8. Особенности и пояснения

Метрики HTTP-latency считаются через histogram, а не через quantile напрямую.

Prometheus скрейпит сервисы напрямую внутри кластера, а не через ingress.

При включённом mTLS для метрик используется режим PERMISSIVE, так как Prometheus не поддерживает mTLS.

Полученные метрики соответствуют реальному production-поведению приложений.
