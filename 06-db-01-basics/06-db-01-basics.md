# Домашнее задание к занятию "6.1. Типы и структура СУБД"
## Задача 1

Архитектор ПО решил проконсультироваться у вас, какой тип БД 
лучше выбрать для хранения определенных данных.

Он вам предоставил следующие типы сущностей, которые нужно будет хранить в БД:

- Электронные чеки в json виде **Ответ** Документо-ориентированная, потому что Json
- Склады и автомобильные дороги для логистической компании  **Ответ** Я бы применил колоночную базу 
- Генеалогические деревья **Ответ** Иерархическая либо графовая
- Кэш идентификаторов клиентов с ограниченным временем жизни для движка аутентификации  **Ответ** Для кеша подходящая база - Ключ-значение
- Отношения клиент-покупка для интернет-магазина **Ответ** Реляционная 

Выберите подходящие типы СУБД для каждой сущности и объясните свой выбор.

## Задача 2

Вы создали распределенное высоконагруженное приложение и хотите классифицировать его согласно 
CAP-теореме. Какой классификации по CAP-теореме соответствует ваша система, если 
(каждый пункт - это отдельная реализация вашей системы и для каждого пункта надо привести классификацию):

- Данные записываются на все узлы с задержкой до часа (асинхронная запись) **Ответ** CA, EL-PC
- При сетевых сбоях, система может разделиться на 2 раздельных кластера **Ответ** AP, PA-EL
- Система может не прислать корректный ответ или сбросить соединение **Ответ** CP, PA-EC

А согласно PACELC-теореме, как бы вы классифицировали данные реализации? 

## Задача 3

Могут ли в одной системе сочетаться принципы BASE и ACID? Почему? Не может. Это противоречащие друг другу принципы.

## Задача 4

Вам дали задачу написать системное решение, основой которого бы послужили:

- фиксация некоторых значений с временем жизни
- реакция на истечение таймаута

Вы слышали о key-value хранилище, которое имеет механизм [Pub/Sub](https://habr.com/ru/post/278237/). 
Что это за система? Какие минусы выбора данной системы?

**Ответ**

Механизм Pub/Sub шаблон, используемый для обмена сообщениями между различными компонентами системы. Издатели публикуют сообщения а подписки через очереди сообщений получают обновления, т.е. способ связи асинхронный. 

Под описание подходит база Redis. Минусы: Хранение базы в оперативной памяти. отсутствие синтаксиса SQL.
