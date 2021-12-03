# Домашнее задание к занятию "6.4. PostgreSQL"

## Задача 1

Используя docker поднимите инстанс PostgreSQL (версию 13). Данные БД сохраните в volume.

Подключитесь к БД PostgreSQL используя `psql`.

Воспользуйтесь командой `\?` для вывода подсказки по имеющимся в `psql` управляющим командам.

**Найдите и приведите** управляющие команды для:
- вывода списка БД
- подключения к БД
- вывода списка таблиц
- вывода описания содержимого таблиц
- выхода из psql

**Ответ**

```yaml
version: "3"
volumes:
    data:
services:
  db:
    image: postgres:13
    container_name: db
    volumes:
      - data:/var/lib/postgresql/data
      - ./test_data:/var/lib/backup_postgresql
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATA: "/var/lib/postgresql/data/pgdata"
    ports:
      - "5432:5432"
    restart: unless-stopped

```
```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-04-postgresql$ docker-compose up -d
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-04-postgresql$ psql -h localhost -U postgres -W
```
Вывод списка БД

```sql
postgres-# \l
```

Подключения к БД

```sql
postgres-# \c db_name
```

Вывод списка таблиц

```sql
postgres-# \d
```

Вывод описания содержимого таблиц

```sql
postgres-# \d name_table
```

Выход из psql

```sql
postgres-# \q
```


## Задача 2

Используя `psql` создайте БД `test_database`.

Изучите [бэкап БД](https://github.com/netology-code/virt-homeworks/tree/master/06-db-04-postgresql/test_data).

Восстановите бэкап БД в `test_database`.

Перейдите в управляющую консоль `psql` внутри контейнера.

Подключитесь к восстановленной БД и проведите операцию ANALYZE для сбора статистики по таблице.

Используя таблицу [pg_stats](https://postgrespro.ru/docs/postgresql/12/view-pg-stats), найдите столбец таблицы `orders` 
с наибольшим средним значением размера элементов в байтах.

**Приведите в ответе** команду, которую вы использовали для вычисления и полученный результат.

**Ответ**

Создание пустой базы, восстановление из бекапа и подключение psql

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-04-postgresql$ createdb -h localhost -U postgres -W -e test_database
Password: 
SELECT pg_catalog.set_config('search_path', '', false);
CREATE DATABASE test_database;
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-04-postgresql$ psql -h localhost -U postgres -W test_database < ./test_data/test_dump.sql 
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-04-postgresql$ psql -h localhost -U postgres -W test_database
```

Выполнение ANALYZE и поиск столбца

```sql
test_database=# analyze;
ANALYZE
test_database=# SELECT avg_width FROM pg_stats WHERE tablename = 'orders' ORDER BY avg_width DESC limit 1;
 avg_width 
-----------
        16
(1 row)

```
## Задача 3

Архитектор и администратор БД выяснили, что ваша таблица orders разрослась до невиданных размеров и
поиск по ней занимает долгое время. Вам, как успешному выпускнику курсов DevOps в нетологии предложили
провести разбиение таблицы на 2 (шардировать на orders_1 - price>499 и orders_2 - price<=499).

Предложите SQL-транзакцию для проведения данной операции.

Можно ли было изначально исключить "ручное" разбиение при проектировании таблицы orders?

**Ответ**

Секционирование с использованием наследования

```sql
CREATE table orders_range_inh (like orders);
CREATE TABLE orders_1_inh (check (price > 500 )) inherits (orders_range_inh);
CREATE TABLE orders_2_inh (check (price <= 500 )) inherits (orders_range_inh);
create rule orders1_insert as on insert to orders_range_inh where (price > 500 ) do instead insert into orders_1_inh values (NEW.*);
create rule orders2_insert as on insert to orders_range_inh where (price <= 499 ) do instead insert into orders_2_inh values (NEW.*);
insert into orders_range_inh select * from orders;
```

Декларативное секционирование

```sql
CREATE TABLE orders_range_part (id INT, title varchar (80), price INT ) PARTITION BY RANGE(price);
create table orders_1_part partition of orders_range_part for values from (499) to (999999999);
create table orders_2_part partition of orders_range_part for values from (0) to (499);
insert into orders_range_part (id, title, price) select * from orders;
```

Можно было избежать изначально используя секционирование


## Задача 4

Используя утилиту `pg_dump` создайте бекап БД `test_database`.


Как бы вы доработали бэкап-файл, чтобы добавить уникальность значения столбца `title` для таблиц `test_database`?


**Ответ**

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-04-postgresql$ docker-compose exec db pg_dump -U postgres test_database > test-backup.sql
```

Добработка бэкапа

1. Добавить в запрос на создание таблицы test_database к  столбцу title параметр UNIQUE в ручную или через sed
2. Проверить что вставляемые данные явяются уникальными в данной таблицы можно сделать в ручную, если данных много то что бы избежать ошибок при восстановление, можно добавить ON CONFLICT DO NOTHING, но тогда не уникальные данные не будут добавлены.

---


​					  