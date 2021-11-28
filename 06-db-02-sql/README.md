# Домашнее задание к занятию "6.2. SQL"
## Задача 1

Используя docker поднимите инстанс PostgreSQL (версию 12) c 2 volume, 
в который будут складываться данные БД и бэкапы.

Приведите получившуюся команду или docker-compose манифест.

**Ответ**

docker-compose.yml
```yaml
version: "3"
networks:
  net:
    driver: bridge
volumes:
    bd:
    backup_bd:
    pgadmin_data:
services:
  bd:
    image: postgres:12
    container_name: bd
    volumes:
      - bd:/var/lib/postgresql/data
      - backup_bd:/var/lib/backup_postgresql
    environment:
      #POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATA: "/var/lib/postgresql/data/pgdata"
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - net
  pgadmin:
    container_name: pgadmin_cont
    image: dpage/pgadmin4:5.7
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD}
      PGADMIN_CONFIG_SERVER_MODE: "False"
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    ports:
      - "5050:80"
    restart: unless-stopped
    networks:
      - net
```


## Задача 2

В БД из задачи 1: 
- создайте пользователя test-admin-user и БД test_db
- в БД test_db создайте таблицу orders и clients (спeцификация таблиц ниже)
- предоставьте привилегии на все операции пользователю test-admin-user на таблицы БД test_db
- создайте пользователя test-simple-user  
- предоставьте пользователю test-simple-user права на SELECT/INSERT/UPDATE/DELETE данных таблиц БД test_db

Таблица orders:
- id (serial primary key)
- наименование (string)
- цена (integer)

Таблица clients:
- id (serial primary key)
- фамилия (string)
- страна проживания (string, index)
- заказ (foreign key orders)

Приведите:
- итоговый список БД после выполнения пунктов выше,
- описание таблиц (describe)
- SQL-запрос для выдачи списка пользователей с правами над таблицами test_db
- список пользователей с правами над таблицами test_db

**Ответ**

Подключение к postgres

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-02-sql$ pgcli -h localhost -p 5432 -U postgres
```

Создание базы и пользователей

```SQL
postgres@localhost:postgres> create database test_db                                                                                                                    
CREATE DATABASE
Time: 0.459s
postgres@localhost:postgres> create user "test-admin-user"                                                                                                              
CREATE ROLE
Time: 0.007s
postgres@localhost:postgres> create user "test-simple-user"                                                                                                             
CREATE ROLE
Time: 0.006s
```

Создание таблиц в PGadmin4

```SQL
CREATE TABLE orders
(
id integer PRIMARY KEy,
name text,
price integer
);

CREATE TABLE clients
(
id integer PRIMARY KEy,
lastname text,
country text,
booking integer,
FOREIGN KEY (booking) REFERENCES orders (id)
);
```

Выдача прав 

```sql

postgres@localhost:postgres> \c test_db                                                                                                                                 
You are now connected to database "test_db" as user "postgres"
Time: 0.010s
postgres@localhost:test_db> grant all on database test_db to "test-admin-user"                                                                                          
GRANT
Time: 0.010s
postgres@localhost:test_db> grant all on table orders, clients to "test-admin-user"                                                                                     
GRANT
Time: 0.012s
postgres@localhost:test_db> GRANT SELECT,INSERT, UPDATE, DELETE on TABle orders, clients to "test-simple-user"                                                          
GRANT
Time: 0.007s
```

Список баз

```sql
est_db=# \l
                                     List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |       Access privileges        
-----------+----------+----------+------------+------------+--------------------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres                   +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres                   +
           |          |          |            |            | postgres=CTc/postgres
 test_db   | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =Tc/postgres                  +
           |          |          |            |            | postgres=CTc/postgres         +
           |          |          |            |            | "test-admin-user"=CTc/postgres
(4 rows)

```

Список таблиц

```sql
test_db=# \dt
          List of relations
 Schema |  Name   | Type  |  Owner   
--------+---------+-------+----------
 public | clients | table | postgres
 public | orders  | table | postgres
(2 rows)

test_db=# \d orders
               Table "public.orders"
 Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
 id     | integer |           | not null | 
 name   | text    |           |          | 
 price  | integer |           |          | 
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
Referenced by:
    TABLE "clients" CONSTRAINT "clients_booking_fkey" FOREIGN KEY (booking) REFERENCES orders(id)

test_db=# \d clients
               Table "public.clients"
  Column  |  Type   | Collation | Nullable | Default 
----------+---------+-----------+----------+---------
 id       | integer |           | not null | 
 lastname | text    |           |          | 
 country  | text    |           |          | 
 booking  | integer |           |          | 
Indexes:
    "clients_pkey" PRIMARY KEY, btree (id)
Foreign-key constraints:
    "clients_booking_fkey" FOREIGN KEY (booking) REFERENCES orders(id)

```

SQL - запрос на права

```
ostgres@localhost:test_db> SELECT * from information_schema.table_privileges WHERE table_name in ('clients','orders');                                                 
+-----------+------------------+-----------------+----------------+--------------+------------------+----------------+------------------+
| grantor   | grantee          | table_catalog   | table_schema   | table_name   | privilege_type   | is_grantable   | with_hierarchy   |
|-----------+------------------+-----------------+----------------+--------------+------------------+----------------+------------------|
| postgres  | postgres         | test_db         | public         | orders       | INSERT           | YES            | NO               |
| postgres  | postgres         | test_db         | public         | orders       | SELECT           | YES            | YES              |
| postgres  | postgres         | test_db         | public         | orders       | UPDATE           | YES            | NO               |
| postgres  | postgres         | test_db         | public         | orders       | DELETE           | YES            | NO               |
| postgres  | postgres         | test_db         | public         | orders       | TRUNCATE         | YES            | NO               |
| postgres  | postgres         | test_db         | public         | orders       | REFERENCES       | YES            | NO               |
| postgres  | postgres         | test_db         | public         | orders       | TRIGGER          | YES            | NO               |
| postgres  | test-admin-user  | test_db         | public         | orders       | INSERT           | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | orders       | SELECT           | NO             | YES              |
| postgres  | test-admin-user  | test_db         | public         | orders       | UPDATE           | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | orders       | DELETE           | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | orders       | TRUNCATE         | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | orders       | REFERENCES       | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | orders       | TRIGGER          | NO             | NO               |
| postgres  | test-simple-user | test_db         | public         | orders       | INSERT           | NO             | NO               |
| postgres  | test-simple-user | test_db         | public         | orders       | SELECT           | NO             | YES              |
| postgres  | test-simple-user | test_db         | public         | orders       | UPDATE           | NO             | NO               |
| postgres  | test-simple-user | test_db         | public         | orders       | DELETE           | NO             | NO               |
| postgres  | postgres         | test_db         | public         | clients      | INSERT           | YES            | NO               |
| postgres  | postgres         | test_db         | public         | clients      | SELECT           | YES            | YES              |
| postgres  | postgres         | test_db         | public         | clients      | UPDATE           | YES            | NO               |
| postgres  | postgres         | test_db         | public         | clients      | DELETE           | YES            | NO               |
| postgres  | postgres         | test_db         | public         | clients      | TRUNCATE         | YES            | NO               |
| postgres  | postgres         | test_db         | public         | clients      | REFERENCES       | YES            | NO               |
| postgres  | postgres         | test_db         | public         | clients      | TRIGGER          | YES            | NO               |
| postgres  | test-admin-user  | test_db         | public         | clients      | INSERT           | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | clients      | SELECT           | NO             | YES              |
| postgres  | test-admin-user  | test_db         | public         | clients      | UPDATE           | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | clients      | DELETE           | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | clients      | TRUNCATE         | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | clients      | REFERENCES       | NO             | NO               |
| postgres  | test-admin-user  | test_db         | public         | clients      | TRIGGER          | NO             | NO               |
| postgres  | test-simple-user | test_db         | public         | clients      | INSERT           | NO             | NO               |
| postgres  | test-simple-user | test_db         | public         | clients      | SELECT           | NO             | YES              |
| postgres  | test-simple-user | test_db         | public         | clients      | UPDATE           | NO             | NO               |
| postgres  | test-simple-user | test_db         | public         | clients      | DELETE           | NO             | NO               |
+-----------+------------------+-----------------+----------------+--------------+------------------+----------------+------------------+
SELECT 36
Time: 0.040s
```
Список пользователей с правами
```sql
test_db=# \dp
                                      Access privileges
 Schema |  Name   | Type  |         Access privileges          | Column privileges | Policies 
--------+---------+-------+------------------------------------+-------------------+----------
 public | clients | table | postgres=arwdDxt/postgres         +|                   | 
        |         |       | "test-admin-user"=arwdDxt/postgres+|                   | 
        |         |       | "test-simple-user"=arwd/postgres   |                   | 
 public | orders  | table | postgres=arwdDxt/postgres         +|                   | 
        |         |       | "test-admin-user"=arwdDxt/postgres+|                   | 
        |         |       | "test-simple-user"=arwd/postgres   |                   | 
(2 rows)

```
## Задача 3

Используя SQL синтаксис - наполните таблицы следующими тестовыми данными:

Таблица orders

|Наименование|цена|
|------------|----|
|Шоколад| 10 |
|Принтер| 3000 |
|Книга| 500 |
|Монитор| 7000|
|Гитара| 4000|

Таблица clients

|ФИО|Страна проживания|
|------------|----|
|Иванов Иван Иванович| USA |
|Петров Петр Петрович| Canada |
|Иоганн Себастьян Бах| Japan |
|Ронни Джеймс Дио| Russia|
|Ritchie Blackmore| Russia|

Используя SQL синтаксис: 
- вычислите количество записей для каждой таблицы 
- приведите в ответе:
    - запросы 
    - результаты их выполнения.

**Ответ**

```sql
insert into orders VALUES (1, 'Шоколад', 10), (2, 'Принтер', 3000), (3, 'Книга', 500), (4, 'Монитор', 7000), (5, 'Гитара', 4000);

insert into clients VALUES (1, 'Иванов Иван Иванович', 'USA'), (2, 'Петров Петр Петрович', 'Canada'), (3, 'Иоганн Себастьян Бах', 'Japan'), (4, 'Ронни Джеймс Дио', 'Russia'), (5, 'Ritchie Blackmore', 'Russia');

postgres@localhost:test_db> select COUNT (*) from orders                                                                                                                
+---------+
| count   |
|---------|
| 5       |
+---------+
SELECT 1
Time: 0.015s
postgres@localhost:test_db> select COUNT (*) from clients                                                                                                               
+---------+
| count   |
|---------|
| 5       |
+---------+
SELECT 1
Time: 0.015s

```

## Задача 4

Часть пользователей из таблицы clients решили оформить заказы из таблицы orders.

Используя foreign keys свяжите записи из таблиц, согласно таблице:

|ФИО|Заказ|
|------------|----|
|Иванов Иван Иванович| Книга |
|Петров Петр Петрович| Монитор |
|Иоганн Себастьян Бах| Гитара |

Приведите SQL-запросы для выполнения данных операций.

Приведите SQL-запрос для выдачи всех пользователей, которые совершили заказ, а также вывод данного запроса.
 
Подсказк - используйте директиву `UPDATE`.

**Ответ**

Обновление данных

```
update  clients set booking = 3 where id = 1;
update  clients set booking = 4 where id = 2;
update  clients set booking = 5 where id = 3;
```

Запрос

```
spostgres@localhost:test_db> select * from clients as c where  exists (select id from orders as o where c.booking = o.id);                                               
+------+----------------------+-----------+-----------+
| id   | lastname             | country   | booking   |
|------+----------------------+-----------+-----------|
| 1    | Иванов Иван Иванович | USA       | 3         |
| 2    | Петров Петр Петрович | Canada    | 4         |
| 3    | Иоганн Себастьян Бах | Japan     | 5         |
+------+----------------------+-----------+-----------+
SELECT 3
Time: 0.016s

```
## Задача 5

Получите полную информацию по выполнению запроса выдачи всех пользователей из задачи 4 
(используя директиву EXPLAIN).

Приведите получившийся результат и объясните что значат полученные значения.

**Ответ**
```sql
postgres@localhost:test_db> explain select * from clients as c where  exists (select id from orders as o where c.booking = o.id);                                       
+------------------------------------------------------------------------+
| QUERY PLAN                                                             |
|------------------------------------------------------------------------|
| Hash Join  (cost=37.00..57.24 rows=810 width=72)                       |
|   Hash Cond: (c.booking = o.id)                                        |
|   ->  Seq Scan on clients c  (cost=0.00..18.10 rows=810 width=72)      |
|   ->  Hash  (cost=22.00..22.00 rows=1200 width=4)                      |
|         ->  Seq Scan on orders o  (cost=0.00..22.00 rows=1200 width=4) |
+------------------------------------------------------------------------+
EXPLAIN
Time: 0.027s
```
## Задача 6

Создайте бэкап БД test_db и поместите его в volume, предназначенный для бэкапов (см. Задачу 1).

Остановите контейнер с PostgreSQL (но не удаляйте volumes).

Поднимите новый пустой контейнер с PostgreSQL.

Восстановите БД test_db в новом контейнере.

Приведите список операций, который вы применяли для бэкапа данных и восстановления. 

**Ответ**

Бекап базы ролей схемы

```
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-02-sql$ docker-compose exec bd pg_dump -Fc-U postgres test_db -f /var/lib/backup_postgresql/test-backup.sql
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-02-sql$ docker-compose exec bd pg_dumpall -g -U postgres -f /var/lib/backup_postgresql/test-global-backup.dmp
```
Остановка контейнеров

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-02-sql$ docker-compose down
[+] Running 3/3
 ⠿ Container pgadmin_cont    Removed                                                                                                                              10.5s
 ⠿ Container bd              Removed                                                                                                                               0.5s
 ⠿ Network 06-db-02-sql_net  Removed 
```

backup_postgres.yaml

```yaml
version: "3"
networks:
  net:
    driver: bridge
volumes:
    backup_bd:
    #pgadmin_data:
services:
  bd_backup:
    image: postgres:12
    container_name: postgre_cont
    volumes:
      - backup_bd:/var/lib/backup_postgresql
    environment:
      #POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATA: "/var/lib/postgresql/data/pgdata"
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - net
  pgadmin:
    container_name: pgadmin_cont
    image: dpage/pgadmin4:5.7
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD}
      PGADMIN_CONFIG_SERVER_MODE: "False"
    #volumes:
    #  - pgadmin_data:/var/lib/pgadmin
    ports:
      - "5050:80"
    restart: unless-stopped
    networks:
      - net
```

Запуск новых контейнеров

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-02-sql$ docker-compose -f ./backup_postgres.yaml up -d
[+] Running 3/3
 ⠿ Network 06-db-02-sql_net  Created                                                                                                                               0.1s
 ⠿ Container postgre_cont    Started                                                                                                                               1.3s
 ⠿ Container pgadmin_cont    Started                                                                                                                               1.3s
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-02-sql$ 
```

Восстановление базы ролей схемы 
```
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-02-sql$ docker-compose -f ./backup_postgres.yaml exec bd_backup psql -U postgres -f /var/lib/backup_postgresql/test-global-backup.dmp
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-02-sql$ docker-compose -f ./backup_postgres.yaml exec bd_backup pg_restore -U postgres -C -d postgres /var/lib/backup_postgresql/test-backup.dmp
```

