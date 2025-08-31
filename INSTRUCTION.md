# Инструкции по валидации развертывания ToDo App с Kubernetes Volumes

## Предварительные требования

- Kubernetes кластер (можно использовать Kind, Minikube, или любой другой)
- kubectl настроен для работы с кластером
- Права на создание ресурсов в кластере

## Развертывание

1. **Клонируйте репозиторий** и перейдите в директорию проекта:

   ```bash
   git clone <repository-url>
   cd devops_todolist_kubernetes_task_8_volumes
   ```

2. **Запустите скрипт развертывания**:
   ```bash
   chmod +x bootstrap.sh
   ./bootstrap.sh
   ```

## Валидация развертывания

### 1. Проверка работоспособности приложения

#### Проверить статус подов:

```bash
kubectl get pods -n todoapp
```

**Ожидаемый результат**: Pod в статусе `Running`

#### Проверить логи приложения:

```bash
kubectl logs -n todoapp deployment/todoapp
```

**Ожидаемый результат**: Отсутствие критических ошибок в логах

#### Проверить доступность приложения:

```bash
# Получить NodePort
kubectl get service -n todoapp

# Проверить доступность через NodePort (замените <node-ip> и <port>)
curl http://<node-ip>:<nodeport>/api/health
```

**Ожидаемый результат**: HTTP 200 ответ

### 2. Валидация ConfigMap данных как файлов

#### Подключиться к поду и проверить монтирование ConfigMap:

```bash
# Получить имя пода
POD_NAME=$(kubectl get pods -n todoapp -l app=todoapp -o jsonpath='{.items[0].metadata.name}')

# Подключиться к поду
kubectl exec -n todoapp -it $POD_NAME -- /bin/bash

# Внутри пода проверить директорию /app/configs
ls -la /app/configs/

# Проверить содержимое конфигурационных файлов (в порядке)
cat /app/configs/01-python-config
cat /app/configs/02-django-settings
cat /app/configs/03-app-config
```

**Ожидаемые результаты**:

- Директория `/app/configs/` существует
- Файлы присутствуют в правильном порядке: `01-python-config`, `02-django-settings`, `03-app-config`
- Проверить порядок файлов: `ls -1 /app/configs/` должен показать файлы в числовом порядке
- Файлы доступны только для чтения

#### Альтернативный способ проверки через kubectl:

```bash
kubectl exec -n todoapp $POD_NAME -- ls -la /app/configs/
kubectl exec -n todoapp $POD_NAME -- ls -1 /app/configs/
kubectl exec -n todoapp $POD_NAME -- cat /app/configs/01-python-config
kubectl exec -n todoapp $POD_NAME -- cat /app/configs/02-django-settings
kubectl exec -n todoapp $POD_NAME -- cat /app/configs/03-app-config
```

### 3. Валидация Secret данных как файлов

#### Проверить монтирование Secret:

```bash
# В том же поде проверить директорию /app/secrets
kubectl exec -n todoapp -it $POD_NAME -- ls -la /app/secrets/

# Проверить содержимое файла SECRET_KEY
kubectl exec -n todoapp $POD_NAME -- cat /app/secrets/SECRET_KEY
```

**Ожидаемые результаты**:

- Директория `/app/secrets/` существует
- Файл `SECRET_KEY` содержит декодированное значение секрета
- Файлы доступны только для чтения
- Права доступа: `400` или `600`

### 4. Валидация PersistentVolume и PersistentVolumeClaim

#### Проверить статус PV и PVC:

```bash
# Проверить PersistentVolume
kubectl get pv

# Проверить PersistentVolumeClaim
kubectl get pvc -n todoapp

# Подробная информация о PVC
kubectl describe pvc todoapp-pvc -n todoapp
```

**Ожидаемые результаты**:

- PV в статусе `Bound`
- PVC в статусе `Bound`
- PV и PVC связаны друг с другом

#### Проверить монтирование PVC в поде:

```bash
# Проверить директорию /app/data
kubectl exec -n todoapp $POD_NAME -- ls -la /app/data/

# Создать тестовый файл для проверки записи
kubectl exec -n todoapp $POD_NAME -- touch /app/data/test-file.txt

# Записать данные в файл
kubectl exec -n todoapp $POD_NAME -- echo "Test data from pod" > /app/data/test-file.txt

# Проверить содержимое
kubectl exec -n todoapp $POD_NAME -- cat /app/data/test-file.txt
```

**Ожидаемые результаты**:

- Директория `/app/data/` существует и доступна для записи
- Можно создавать и изменять файлы
- Данные сохраняются между перезапусками подов

### 5. Проверка персистентности данных

#### Тест персистентности:

```bash
# Удалить под для проверки персистентности
kubectl delete pod -n todoapp $POD_NAME

# Дождаться создания нового пода
kubectl wait --for=condition=Ready pod -l app=todoapp -n todoapp --timeout=300s

# Получить имя нового пода
NEW_POD_NAME=$(kubectl get pods -n todoapp -l app=todoapp -o jsonpath='{.items[0].metadata.name}')

# Проверить, что файл все еще существует
kubectl exec -n todoapp $NEW_POD_NAME -- cat /app/data/test-file.txt
```

**Ожидаемый результат**: Файл и его содержимое сохранились после перезапуска пода

## Дополнительные проверки

### Проверка конфигурации volumes в Deployment:

```bash
kubectl get deployment todoapp -n todoapp -o yaml | grep -A 20 volumes:
```

### Проверка событий в namespace:

```bash
kubectl get events -n todoapp --sort-by='.lastTimestamp'
```

### Проверка ресурсов кластера:

```bash
kubectl get all -n todoapp
```

## Ожидаемая структура файлов в поде

После успешного развертывания в поде должна быть следующая структура:

```
/app/
├── configs/           # ConfigMap files (read-only, ordered)
│   ├── 01-python-config
│   ├── 02-django-settings
│   └── 03-app-config
├── data/             # PersistentVolume mount (read-write)
│   └── [user files]
└── secrets/          # Secret files (read-only)
    └── SECRET_KEY
```

### Проверка порядка файлов ConfigMap

Для валидации того, что файлы ConfigMap монтируются в правильном порядке:

```bash
# Проверить порядок файлов (должен быть числовой)
kubectl exec -n todoapp $POD_NAME -- ls -1 /app/configs/

# Ожидаемый вывод:
# 01-python-config
# 02-django-settings
# 03-app-config

# Проверить содержимое каждого файла
kubectl exec -n todoapp $POD_NAME -- cat /app/configs/01-python-config  # PYTHONUNBUFFERED=1
kubectl exec -n todoapp $POD_NAME -- cat /app/configs/02-django-settings # DEBUG=0
kubectl exec -n todoapp $POD_NAME -- cat /app/configs/03-app-config      # MAX_CONNECTIONS=100
```

## Устранение неполадок

### Если под не запускается:

```bash
kubectl describe pod -n todoapp $POD_NAME
kubectl logs -n todoapp $POD_NAME
```

### Если PVC не связывается с PV:

```bash
kubectl describe pvc todoapp-pvc -n todoapp
kubectl get events -n todoapp
```

### Если volumes не монтируются:

```bash
kubectl describe pod -n todoapp $POD_NAME
# Проверить секцию Mounts и Volumes
```

## Очистка ресурсов

Для удаления всех созданных ресурсов:

```bash
kubectl delete namespace todoapp
kubectl delete pv todoapp-pv
```
