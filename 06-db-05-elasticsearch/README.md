# Домашнее задание к занятию "6.5. Elasticsearch"

## Задача 1

В этом задании вы потренируетесь в:
- установке elasticsearch
- первоначальном конфигурировании elastcisearch
- запуске elasticsearch в docker

Используя докер образ [centos:7](https://hub.docker.com/_/centos) как базовый и 
[документацию по установке и запуску Elastcisearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html):

- составьте Dockerfile-манифест для elasticsearch
- соберите docker-образ и сделайте `push` в ваш docker.io репозиторий
- запустите контейнер из получившегося образа и выполните запрос пути `/` c хост-машины

Требования к `elasticsearch.yml`:
- данные `path` должны сохраняться в `/var/lib`
- имя ноды должно быть `netology_test`

В ответе приведите:
- текст Dockerfile манифеста
- ссылку на образ в репозитории dockerhub
- ответ `elasticsearch` на запрос пути `/` в json виде

Подсказки:
- возможно вам понадобится установка пакета perl-Digest-SHA для корректной работы пакета shasum
- при сетевых проблемах внимательно изучите кластерные и сетевые настройки в elasticsearch.yml
- при некоторых проблемах вам поможет docker директива ulimit
- elasticsearch в логах обычно описывает проблему и пути ее решения

Далее мы будем работать с данным экземпляром elasticsearch.

**Ответ**

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.15.2-linux-x86_64.tar.gz
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ docker build -t elasicsearch:v0.1 .
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ docker run -it -e ES_JAVA_OPTS="-Xms1g -Xmx1g" -d -p 9200:9200 --name elasticsearch elasicsearch:v0.2
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X GET "localhost:9200/_cluster/health/?pretty"
{
  "cluster_name" : "elasticsearch",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 0,
  "active_shards" : 0,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 39,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 2809,
  "active_shards_percent_as_number" : 100.0
}
```

dockerfile

```dockerfile
FROM centos:7

label version="0.1"

RUN groupadd elastic_group \
    && useradd -g elastic_group elastic_user

add elasticsearch-7.15.2-linux-x86_64.tar.gz /

copy elasticsearch.yml /elasticsearch-7.15.2/config/

RUN mkdir /var/log/logs \
    && chown elastic_user:elastic_group /var/log/logs \
    && mkdir /var/lib/data \
    && chown elastic_user:elastic_group  /var/lib/data \
    && chown -R elastic_user:elastic_group  /elasticsearch-7.15.2/
RUN mkdir /elasticsearch-7.15.2/snapshots &&\
    chown elastic_user:elastic_group  /elasticsearch-7.15.2/snapshots
    
EXPOSE 9200/tcp

USER elastic_user

CMD ["/usr/sbin/init"]
CMD ["/elasticsearch-7.15.2/bin/elasticsearch"]
```

elasticsearch.yml

```yaml
node.name: netology_test
path.data: /var/lib/data
path.logs: /var/log/logs
path.repo: /elasticsearch-7.15.2/snapshots
ngest.geoip.downloader.enabled: false
bootstrap.memory_lock: true
network.host: 127.0.0.1
http.host: 0.0.0.0 
http.port: 9200
```

Docker hub - https://hub.docker.com/r/rkhozyainov/elasicsearch

## Задача 2

В этом задании вы научитесь:
- создавать и удалять индексы
- изучать состояние кластера
- обосновывать причину деградации доступности данных

Ознакомтесь с [документацией](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html) 
и добавьте в `elasticsearch` 3 индекса, в соответствии со таблицей:

| Имя | Количество реплик | Количество шард |
|-----|-------------------|-----------------|
| ind-1| 0 | 1 |
| ind-2 | 1 | 2 |
| ind-3 | 2 | 4 |

Получите список индексов и их статусов, используя API и **приведите в ответе** на задание.

Получите состояние кластера `elasticsearch`, используя API.

Как вы думаете, почему часть индексов и кластер находится в состоянии yellow?

Удалите все индексы.

**Важно**

При проектировании кластера elasticsearch нужно корректно рассчитывать количество реплик и шард,
иначе возможна потеря данных индексов, вплоть до полной, при деградации системы.

**Ответ**

Создание индексов

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X PUT localhost:9200/ind-1 -H 'Content-Type: application/json' -d'{ "settings": { "number_of_shards": 1,  "number_of_replicas": 0 }}'
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X PUT localhost:9200/ind-2 -H 'Content-Type: application/json' -d'{ "settings": { "number_of_shards": 2,  "number_of_replicas": 1 }}'
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X PUT localhost:9200/ind-3 -H 'Content-Type: application/json' -d'{ "settings": { "number_of_shards": 4,  "number_of_replicas": 2 }}'
```

Список индексов и их статусов

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X GET 'http://localhost:9200/_cat/indices?v' 
health status index uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   ind-1 AEFmhNZjRdOXGFag65xguQ   1   0          0            0       208b           208b
yellow open   ind-3 99PiCSkZSM2Un71QUzKyzA   4   2          0            0       832b           832b
yellow open   ind-2 EFjjnZVfTYi27sSNwcpuDQ   2   1          0            0       416b           416b

rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X GET 'http://localhost:9200/_cluster/health/ind-1?pretty'
{
  "cluster_name" : "elasticsearch",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 1,
  "active_shards" : 1,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X GET 'http://localhost:9200/_cluster/health/ind-2?pretty'
{
  "cluster_name" : "elasticsearch",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 2,
  "active_shards" : 2,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 2,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 41.17647058823529
}
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X GET 'http://localhost:9200/_cluster/health/ind-3?pretty'
{
  "cluster_name" : "elasticsearch",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 4,
  "active_shards" : 4,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 8,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 41.17647058823529
}

```

Статус кластера

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X GET "localhost:9200/_cluster/health/?pretty"
{
  "cluster_name" : "elasticsearch",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 7,
  "active_shards" : 7,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 10,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 41.17647058823529
}

```

Удаление индексов

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X DELETE 'http://localhost:9200/ind-1'
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X DELETE 'http://localhost:9200/ind-1'
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X DELETE 'http://localhost:9200/ind-1'
```

Статус кластера желтный так как укзано количесвто реплик, а сервер всего один. 

## Задача 3

В данном задании вы научитесь:
- создавать бэкапы данных
- восстанавливать индексы из бэкапов

Создайте директорию `{путь до корневой директории с elasticsearch в образе}/snapshots`.

Используя API [зарегистрируйте](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-register-repository.html#snapshots-register-repository) 
данную директорию как `snapshot repository` c именем `netology_backup`.

**Приведите в ответе** запрос API и результат вызова API для создания репозитория.

Создайте индекс `test` с 0 реплик и 1 шардом и **приведите в ответе** список индексов.

[Создайте `snapshot`](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-take-snapshot.html) 
состояния кластера `elasticsearch`.

**Приведите в ответе** список файлов в директории со `snapshot`ами.

Удалите индекс `test` и создайте индекс `test-2`. **Приведите в ответе** список индексов.

[Восстановите](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-restore-snapshot.html) состояние
кластера `elasticsearch` из `snapshot`, созданного ранее. 

**Приведите в ответе** запрос к API восстановления и итоговый список индексов.

Подсказки:
- возможно вам понадобится доработать `elasticsearch.yml` в части директивы `path.repo` и перезапустить `elasticsearch`

**Ответ**

Создание репозитория 

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X PUT "localhost:9200/_snapshot/netology_backup?pretty" -H 'Content-Type: application/json' -d' { "type": "fs", "settings": { "location": "/elasticsearch-7.15.2/snapshots" } }'
{
  "acknowledged" : true
}
```

Создание индекса и вывод списка индексов 

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X PUT localhost:9200/test -H 'Content-Type: application/json' -d'{ "settings": { "number_of_shards": 1,  "number_of_replicas": 0 }}'

rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X GET 'http://localhost:9200/_cat/indices?v'
health status index uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   test  yrDLi9LdSaygDFVm2nRa7w   1   0          0            0       208b           208b
```

Создание бэкапа

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X PUT "localhost:9200/_snapshot/netology_backup/elasicsearch?wait_for_completion=true&pretty"
{
  "snapshot" : {
    "snapshot" : "elasicsearch",
    "uuid" : "PGqjA4QRQK2FkRENKmr9yw",
    "repository" : "netology_backup",
    "version_id" : 7150299,
    "version" : "7.15.2",
    "indices" : [
      "test"
    ],
    "data_streams" : [ ],
    "include_global_state" : true,
    "state" : "SUCCESS",
    "start_time" : "2021-12-06T23:11:11.815Z",
    "start_time_in_millis" : 1638832271815,
    "end_time" : "2021-12-06T23:11:12.016Z",
    "end_time_in_millis" : 1638832272016,
    "duration_in_millis" : 201,
    "failures" : [ ],
    "shards" : {
      "total" : 1,
      "failed" : 0,
      "successful" : 1
    },
    "feature_states" : [ ]
  }
}
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ 
```

Вывод списка файлов бэкапа

```bash
[elastic_user@838a1df156e2 /]$ ls -l /elasticsearch-7.15.2/snapshots/
total 44
-rw-r--r-- 1 elastic_user elastic_group   573 Dec  6 23:11 index-0
-rw-r--r-- 1 elastic_user elastic_group     8 Dec  6 23:11 index.latest
drwxr-xr-x 3 elastic_user elastic_group  4096 Dec  6 23:11 indices
-rw-r--r-- 1 elastic_user elastic_group 27202 Dec  6 23:11 meta-PGqjA4QRQK2FkRENKmr9yw.dat
-rw-r--r-- 1 elastic_user elastic_group   352 Dec  6 23:11 snap-PGqjA4QRQK2FkRENKmr9yw.dat
```

Удаление индекса, создание нового индекса, вывод списка индексов

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X DELETE 'http://localhost:9200/test'
{"acknowledged":true}
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X PUT localhost:9200/test-2 -H 'Content-Type: application/json' -d'{ "settings": { "number_of_shards": 1,  "number_of_replicas": 0 }}'

rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X GET 'http://localhost:9200/_cat/indices?v' 
health status index  uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   test-2 IEWGIDOsQae6bFtVtC2fnA   1   0          0            0       208b           208b
```

Восстановление из бэкапа и вывод списка индексов

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X POST "localhost:9200/_snapshot/netology_backup/elasicsearch/_restore?pretty"
{
  "accepted" : true
}
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-05-elasticsearch$ curl -X GET 'http://localhost:9200/_cat/indices?v' 
health status index  uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   test-2 IEWGIDOsQae6bFtVtC2fnA   1   0          0            0       208b           208b
green  open   test   4DdrArYmQMuR72HBhYz20A   1   0          0            0       208b           208b

```

---

### Как cдавать задание

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

---
