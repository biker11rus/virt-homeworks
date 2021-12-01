# Домашнее задание к занятию "6.3. MySQL"
## Задача 1

Используя docker поднимите инстанс MySQL (версию 8). Данные БД сохраните в volume.

Изучите [бэкап БД](https://github.com/netology-code/virt-homeworks/tree/master/06-db-03-mysql/test_data) и 
восстановитесь из него.

Перейдите в управляющую консоль `mysql` внутри контейнера.

Используя команду `\h` получите список управляющих команд.

Найдите команду для выдачи статуса БД и **приведите в ответе** из ее вывода версию сервера БД.

Подключитесь к восстановленной БД и получите список таблиц из этой БД.

**Приведите в ответе** количество записей с `price` > 300.

В следующих заданиях мы будем продолжать работу с данным контейнером.

**Ответ**

docker-compose
```yaml
version: "3"
volumes:
    data:
services:
  db:
    image: mysql:8
    #command: mysqld --default-authentication-plugin=mysql_native_password
    container_name: mysql_db
    volumes:
      - data:/var/lib/mysql
      - ./test_data:/backup
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      #MYSQL_DATABASE: ${MYSQL_DATABASE}
      #MYSQL_USER: ${MYSQL_USER}
      #MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "3306:3306"
    restart: always
```
Создание и подключение к контейнеру MySQL

```bash
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-03-mysql$ docker-compose up -d
[+] Running 3/3
 ⠿ Network 06-db-03-mysql_default  Created                                                                                                                         0.1s
 ⠿ Volume "06-db-03-mysql_data"    Created                                                                                                                         0.0s
 ⠿ Container mysql_db              Started                                                                                                                         1.1s
rkhozyainov@rkh:~/devops/virt-homeworks/06-db-03-mysql$ docker-compose exec db bash
root@2d6ecfddd94c:/# mysql -u root -p
```

Создание пуcтой базы для восстановления и вывод статуса сервера

```sql
mysql> create database test_db;
Query OK, 1 row affected (0.05 sec)
mysql> \s
--------------
mysql  Ver 8.0.27 for Linux on x86_64 (MySQL Community Server - GPL)
```

Восстановление базы

```bash
root@2d6ecfddd94c:/# mysql -u root -p test_db < /backup/test_dump.sql 
```
Просмотр баз, подключение к базе, просмотр таблиц, запрос к базе 

```sql
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| test_db            |
+--------------------+
5 rows in set (0.02 sec)

mysql> use test_db
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+-------------------+
| Tables_in_test_db |
+-------------------+
| orders            |
+-------------------+
1 row in set (0.01 sec)

mysql> select count(8) from orders where price > 300;
+----------+
| count(8) |
+----------+
|        1 |
+----------+
1 row in set (0.01 sec)
```
## Задача 2

Создайте пользователя test в БД c паролем test-pass, используя:
- плагин авторизации mysql_native_password
- срок истечения пароля - 180 дней 
- количество попыток авторизации - 3 
- максимальное количество запросов в час - 100
- аттрибуты пользователя:
    - Фамилия "Pretty"
    - Имя "James"

Предоставьте привелегии пользователю `test` на операции SELECT базы `test_db`.
    
Используя таблицу INFORMATION_SCHEMA.USER_ATTRIBUTES получите данные по пользователю `test` и 
**приведите в ответе к задаче**.

**Ответ**
```sql
mysql> create user 'test'@'localhost'
    -> identified with mysql_native_password by 'test-pass'
    -> with max_queries_per_hour 100
    -> password expire interval 180 day
    -> failed_login_attempts 3
    -> attribute '{"fname":"James", "lname":"Pretty"}';
Query OK, 0 rows affected (0.05 sec)

mysql> grant select on test_db.* to 'test'@'localhost';
Query OK, 0 rows affected, 1 warning (0.02 sec)

mysql> SELECT * FROM INFORMATION_SCHEMA.USER_ATTRIBUTES WHERE user='test';
+------+-----------+---------------------------------------+
| USER | HOST      | ATTRIBUTE                             |
+------+-----------+---------------------------------------+
| test | localhost | {"fname": "James", "lname": "Pretty"} |
+------+-----------+---------------------------------------+
1 row in set (0.01 sec)
```


## Задача 3

Установите профилирование `SET profiling = 1`.
Изучите вывод профилирования команд `SHOW PROFILES;`.

Исследуйте, какой `engine` используется в таблице БД `test_db` и **приведите в ответе**.

Измените `engine` и **приведите время выполнения и запрос на изменения из профайлера в ответе**:
- на `MyISAM`
- на `InnoDB`

**Ответ**

Установка SET profiling = 1, запрос, просмотр PROFILES

```sql
mysql> SET profiling = 1;
Query OK, 0 rows affected, 1 warning (0.04 sec)

mysql> select count(*) from test_db.orders;
+----------+
| count(*) |
+----------+
|        5 |
+----------+
1 row in set (0.03 sec)

mysql> SHOW PROFILES;
+----------+------------+-------------------------------------+
| Query_ID | Duration   | Query                               |
+----------+------------+-------------------------------------+
|        1 | 0.03156725 | select count(*) from test_db.orders |
+----------+------------+-------------------------------------+
1 row in set, 1 warning (0.00 sec)

mysql> SHOW PROFILE;
+--------------------------------+----------+
| Status                         | Duration |
+--------------------------------+----------+
| starting                       | 0.005962 |
| Executing hook on transaction  | 0.000560 |
| starting                       | 0.000038 |
| checking permissions           | 0.000023 |
| Opening tables                 | 0.016205 |
| init                           | 0.000138 |
| System lock                    | 0.000151 |
| optimizing                     | 0.000085 |
| statistics                     | 0.000391 |
| preparing                      | 0.000696 |
| executing                      | 0.006668 |
| end                            | 0.000049 |
| query end                      | 0.000007 |
| waiting for handler commit     | 0.000492 |
| closing tables                 | 0.000049 |
| freeing items                  | 0.000027 |
| cleaning up                    | 0.000028 |
+--------------------------------+----------+
17 rows in set, 1 warning (0.01 sec)
```

Просмотр движка таблицы 

```sql
mysql> show table status from test_db;
+--------+--------+---------+------------+------+----------------+-------------+-----------------+--------------+-----------+----------------+---------------------+---------------------+------------+--------------------+----------+----------------+---------+
| Name   | Engine | Version | Row_format | Rows | Avg_row_length | Data_length | Max_data_length | Index_length | Data_free | Auto_increment | Create_time         | Update_time         | Check_time | Collation          | Checksum | Create_options | Comment |
+--------+--------+---------+------------+------+----------------+-------------+-----------------+--------------+-----------+----------------+---------------------+---------------------+------------+--------------------+----------+----------------+---------+
| orders | InnoDB |      10 | Dynamic    |    5 |           3276 |       16384 |               0 |            0 |         0 |              6 | 2021-11-30 20:56:29 | 2021-11-30 20:56:29 | NULL       | utf8mb4_0900_ai_ci |     NULL |                |         |
+--------+--------+---------+------------+------+----------------+-------------+-----------------+--------------+-----------+----------------+---------------------+---------------------+------------+--------------------+----------+----------------+---------+
1 row in set (0.01 sec)

mysql> select table_name, engine from information_schema.tables where table_schema = "test_db";
+------------+--------+
| TABLE_NAME | ENGINE |
+------------+--------+
| orders     | InnoDB |
+------------+--------+
1 row in set (0.00 sec)


```

Смена движка таблицы orders

```sql
mysql> alter table orders engine = MyISAM;
Query OK, 5 rows affected (0.52 sec)
Records: 5  Duplicates: 0  Warnings: 0

mysql> SHOW PROFILE;
+--------------------------------+----------+
| Status                         | Duration |
+--------------------------------+----------+
| starting                       | 0.000159 |
| Executing hook on transaction  | 0.000018 |
| starting                       | 0.002816 |
| checking permissions           | 0.000017 |
| checking permissions           | 0.000518 |
| init                           | 0.000377 |
| Opening tables                 | 0.002213 |
| setup                          | 0.002414 |
| creating table                 | 0.008755 |
| waiting for handler commit     | 0.000024 |
| waiting for handler commit     | 0.027828 |
| After create                   | 0.004111 |
| System lock                    | 0.000032 |
| copy to tmp table              | 0.001509 |
| waiting for handler commit     | 0.000033 |
| waiting for handler commit     | 0.000028 |
| waiting for handler commit     | 0.000074 |
| rename result table            | 0.000164 |
| waiting for handler commit     | 0.080522 |
| waiting for handler commit     | 0.000017 |
| waiting for handler commit     | 0.149790 |
| waiting for handler commit     | 0.000048 |
| waiting for handler commit     | 0.147621 |
| waiting for handler commit     | 0.000020 |
| waiting for handler commit     | 0.010817 |
| end                            | 0.071452 |
| query end                      | 0.010582 |
| closing tables                 | 0.000048 |
| waiting for handler commit     | 0.000049 |
| freeing items                  | 0.000046 |
| cleaning up                    | 0.000038 |
+--------------------------------+----------+
31 rows in set, 1 warning (0.00 sec)

mysql> alter table orders engine = InnoDB;
Query OK, 5 rows affected (0.56 sec)
Records: 5  Duplicates: 0  Warnings: 0

mysql> SHOW PROFILE;
+--------------------------------+----------+
| Status                         | Duration |
+--------------------------------+----------+
| starting                       | 0.000201 |
| Executing hook on transaction  | 0.000019 |
| starting                       | 0.000061 |
| checking permissions           | 0.000024 |
| checking permissions           | 0.000018 |
| init                           | 0.000044 |
| Opening tables                 | 0.000703 |
| setup                          | 0.002965 |
| creating table                 | 0.000391 |
| After create                   | 0.123980 |
| System lock                    | 0.000054 |
| copy to tmp table              | 0.000633 |
| rename result table            | 0.002966 |
| waiting for handler commit     | 0.000029 |
| waiting for handler commit     | 0.018983 |
| waiting for handler commit     | 0.000015 |
| waiting for handler commit     | 0.231820 |
| waiting for handler commit     | 0.000029 |
| waiting for handler commit     | 0.122130 |
| waiting for handler commit     | 0.000017 |
| waiting for handler commit     | 0.025265 |
| end                            | 0.000976 |
| query end                      | 0.028685 |
| closing tables                 | 0.000025 |
| waiting for handler commit     | 0.000061 |
| freeing items                  | 0.000074 |
| cleaning up                    | 0.000060 |
+--------------------------------+----------+
27 rows in set, 1 warning (0.00 sec)
```

## Задача 4 

Изучите файл `my.cnf` в директории /etc/mysql.

Измените его согласно ТЗ (движок InnoDB):
- Скорость IO важнее сохранности данных
  
innodb_ﬂush_log_at_trx_commit = 2

- Нужна компрессия таблиц для экономии места на диске
  
innodb_file_per_table = 1

- Размер буффера с незакомиченными транзакциями 1 Мб
  
innodb_log_buffer_size = 1M

- Буффер кеширования 30% от ОЗУ
  
```bash
    root@2d6ecfddd94c:/# cat /proc/meminfo | grep MemTotal
    MemTotal:        3636580 kB
```

innodb_buffer_pool_size = 1212M

- Размер файла логов операций 100 Мб
  
innodb_log_ﬁle_size = 100M

---
