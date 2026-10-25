/*
Абрамкина Милана Игоревна
Вариант: 13
База данных музея

Домашнее задание к практическому занятию 1:
Заполнить таблицы, созданные в рамках домашнего задания к практическому занятию 1
(museum.sql), не менее, чем 5-ю осмысленными записями. Данные возьмите из
аналогичных систем в реальной жизни. Заполнение оформите в виде SQL-запросов.

Вариант 13
Выберите информацию о коллекциях (все поля таблицы), срок показа которых от начала
до конца не превышает 30 дней, отсортировав результат по этому сроку в прямом порядке.
Выберите информацию о коллекциях (все поля) и число экспонатов в них,
отсортировав по данному числу в порядке возрастания.

Задание: определить сущности, их атрибуты, типы данных и связи.
Составить SQL-скрипт создания таблиц с ограничениями целостности
и значениями по умолчанию.

Описание предметной области
Описание коллекций и экспонатов музея. Включает в себя: выставочные залы,
коллекции, экспонаты, стоимости билетов.

Выставочные залы описываются названием.

Коллекции состоят из: названия, краткого описания, списка выставочных залов,
в которых они размещены, периода показа, определяющегося датой начала и конца.

Экспонаты состоят из: названия, краткого описания, страховой стоимости,
века создания, указания коллекции, в которую экспонат входит, указания зала,
в котором он размещён, габаритных размеров, включающих высоту, ширину, длину,
и условий содержания, определяемых необходимостью контроля температуры,
необходимостью контроля влажности, защищённостью от людей.

Стоимости билетов состоят из: типа посетителя, набора коллекций,
к которым по данному билету возможен доступ, стоимости в рублях.

PostgreSQL. Запуск через psql:
psql -U postgres -d postgres -f museum.sql
База museum создаётся при запуске и не должна существовать заранее.
*/

\set ON_ERROR_STOP on

CREATE DATABASE museum WITH ENCODING = 'UTF8' TEMPLATE = template0;

\connect museum

BEGIN;

-- Выставочные залы
CREATE TABLE exhibition_halls (
    hall_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL CHECK (btrim(name) <> '')
);

-- Коллекции
CREATE TABLE collections (
    collection_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL CHECK (btrim(name) <> ''),
    description TEXT NOT NULL CHECK (btrim(description) <> ''),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CONSTRAINT valid_collection_period CHECK (end_date >= start_date)
);

-- В каких залах размещены коллекции
CREATE TABLE collection_halls (
    collection_id INTEGER NOT NULL REFERENCES collections (collection_id),
    hall_id INTEGER NOT NULL REFERENCES exhibition_halls (hall_id),
    PRIMARY KEY (collection_id, hall_id)
);

-- Экспонаты. Стоимость указана в рублях, размеры — в сантиметрах.
CREATE TABLE exhibits (
    exhibit_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL CHECK (btrim(name) <> ''),
    description TEXT NOT NULL CHECK (btrim(description) <> ''),
    insurance_value_rub NUMERIC(18, 2) NOT NULL CHECK (insurance_value_rub >= 0),

    -- Отрицательное число обозначает век до нашей эры, положительное — нашей эры.
    creation_century SMALLINT NOT NULL CHECK (creation_century <> 0),

    collection_id INTEGER NOT NULL,
    hall_id INTEGER NOT NULL,
    height_cm NUMERIC(10, 2) NOT NULL CHECK (height_cm > 0),
    width_cm NUMERIC(10, 2) NOT NULL CHECK (width_cm > 0),
    length_cm NUMERIC(10, 2) NOT NULL CHECK (length_cm > 0),

    -- TRUE — условие необходимо, FALSE — не требуется.
    requires_temperature_control BOOLEAN NOT NULL DEFAULT FALSE,
    requires_humidity_control BOOLEAN NOT NULL DEFAULT FALSE,
    requires_visitor_protection BOOLEAN NOT NULL DEFAULT FALSE,

    -- Зал экспоната должен входить в список залов его коллекции.
    CONSTRAINT exhibit_collection_hall_fk
        FOREIGN KEY (collection_id, hall_id)
        REFERENCES collection_halls (collection_id, hall_id)
);

-- Типы посетителей: взрослый, студент, ребёнок и т. д.
CREATE TABLE visitor_types (
    visitor_type_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE CHECK (btrim(name) <> '')
);

-- Стоимость билетов. Для бесплатного посещения указывается 0.
CREATE TABLE ticket_prices (
    ticket_price_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    visitor_type_id INTEGER NOT NULL REFERENCES visitor_types (visitor_type_id),
    price_rub NUMERIC(10, 2) NOT NULL CHECK (price_rub >= 0)
);

-- Коллекции, которые можно посетить по билету
CREATE TABLE ticket_collections (
    ticket_price_id INTEGER NOT NULL REFERENCES ticket_prices (ticket_price_id),
    collection_id INTEGER NOT NULL REFERENCES collections (collection_id),
    PRIMARY KEY (ticket_price_id, collection_id)
);

COMMIT;

/*
Примеры произведений, их дат создания и размеров взяты из каталога
«Моя Третьяковка». Примеры стоимости билетов основаны на тарифах галереи.
Даты показа, распределение произведений по залам, страховая стоимость,
толщина картин и условия хранения заданы как учебные примеры: такие данные
не указаны в открытых карточках произведений.

Источники:
https://my.tretyakov.ru/app/masterpiece/8392
https://my.tretyakov.ru/app/masterpiece/20796
https://my.tretyakov.ru/app/masterpiece/8394
https://my.tretyakov.ru/app/masterpiece/8390
https://my.tretyakov.ru/app/masterpiece/8399
https://my.tretyakov.ru/app/masterpiece/8403
https://www.tretyakovgallery.ru/for-visitors/museums/istoricheskoe-zdanie/
*/

BEGIN;

-- Выставочные залы
INSERT INTO exhibition_halls (name) VALUES
    ('Персональный зал В. М. Васнецова'),
    ('Зал русского портрета'),
    ('Зал русского пейзажа'),
    ('Зал искусства начала XX века'),
    ('Зал русского авангарда');

-- Коллекции. Периоды показа подобраны для проверки запросов из варианта 13.
INSERT INTO collections (name, description, start_date, end_date) VALUES
    ('Былинные герои',
     'Картины Виктора Васнецова на темы русских былин.',
     DATE '2026-01-01', DATE '2026-12-31'),
    ('Портреты XIX века',
     'Портретная живопись русских художников.',
     DATE '2026-10-01', DATE '2026-10-20'),
    ('Русский пейзаж',
     'Пейзажи русской природы.',
     DATE '2026-10-03', DATE '2026-10-25'),
    ('Живопись начала XX века',
     'Известные произведения русских художников начала XX века.',
     DATE '2026-10-10', DATE '2026-11-08'),
    ('Русский авангард',
     'Произведения художников русского авангарда.',
     DATE '2026-10-01', DATE '2026-10-31');

-- Залы, в которых размещены коллекции
INSERT INTO collection_halls (collection_id, hall_id)
SELECT c.collection_id, h.hall_id
FROM (VALUES
    ('Былинные герои', 'Персональный зал В. М. Васнецова'),
    ('Портреты XIX века', 'Зал русского портрета'),
    ('Русский пейзаж', 'Зал русского пейзажа'),
    ('Живопись начала XX века', 'Зал искусства начала XX века'),
    ('Русский авангард', 'Зал русского авангарда')
) AS placements(collection_name, hall_name)
JOIN collections AS c ON c.name = placements.collection_name
JOIN exhibition_halls AS h ON h.name = placements.hall_name;

-- Экспонаты. Страховые суммы и толщина указаны для учебного примера.
INSERT INTO exhibits (
    name, description, insurance_value_rub, creation_century,
    collection_id, hall_id, height_cm, width_cm, length_cm,
    requires_temperature_control, requires_humidity_control,
    requires_visitor_protection
) VALUES
    (
        'Богатыри',
        'Картина Виктора Васнецова на сюжет русских былин.',
        1500000000.00, 19,
        (SELECT collection_id FROM collections WHERE name = 'Былинные герои'),
        (SELECT hall_id FROM exhibition_halls WHERE name = 'Персональный зал В. М. Васнецова'),
        295.3, 446.0, 5.0, TRUE, TRUE, TRUE
    ),
    (
        'После побоища Игоря Святославича с половцами',
        'Картина Виктора Васнецова на исторический сюжет.',
        700000000.00, 19,
        (SELECT collection_id FROM collections WHERE name = 'Былинные герои'),
        (SELECT hall_id FROM exhibition_halls WHERE name = 'Персональный зал В. М. Васнецова'),
        205.0, 390.0, 5.0, TRUE, TRUE, TRUE
    ),
    (
        'Девочка с персиками',
        'Портрет Веры Мамонтовой работы Валентина Серова.',
        300000000.00, 19,
        (SELECT collection_id FROM collections WHERE name = 'Портреты XIX века'),
        (SELECT hall_id FROM exhibition_halls WHERE name = 'Зал русского портрета'),
        91.0, 85.0, 4.0, TRUE, TRUE, TRUE
    ),
    (
        'Утро в сосновом лесу',
        'Пейзаж Ивана Шишкина с изображением медведей в лесу.',
        1000000000.00, 19,
        (SELECT collection_id FROM collections WHERE name = 'Русский пейзаж'),
        (SELECT hall_id FROM exhibition_halls WHERE name = 'Зал русского пейзажа'),
        139.0, 213.0, 4.0, TRUE, TRUE, TRUE
    ),
    (
        'Купание красного коня',
        'Картина Кузьмы Петрова-Водкина, написанная в 1912 году.',
        1200000000.00, 20,
        (SELECT collection_id FROM collections WHERE name = 'Живопись начала XX века'),
        (SELECT hall_id FROM exhibition_halls WHERE name = 'Зал искусства начала XX века'),
        160.0, 186.0, 4.0, TRUE, TRUE, TRUE
    ),
    (
        'Черный супрематический квадрат',
        'Картина Казимира Малевича, созданная в 1915 году.',
        2000000000.00, 20,
        (SELECT collection_id FROM collections WHERE name = 'Русский авангард'),
        (SELECT hall_id FROM exhibition_halls WHERE name = 'Зал русского авангарда'),
        79.5, 79.5, 3.0, TRUE, TRUE, TRUE
    );

-- Типы посетителей
INSERT INTO visitor_types (name) VALUES
    ('Взрослый'),
    ('Студент'),
    ('Пенсионер'),
    ('Ребенок от 7 до 17 лет'),
    ('Ребенок до 6 лет');

-- Суммы взяты с сайта галереи; соответствие льготных цен категориям условное.
INSERT INTO ticket_prices (visitor_type_id, price_rub)
SELECT v.visitor_type_id, p.price_rub
FROM (VALUES
    ('Взрослый', 700.00),
    ('Студент', 350.00),
    ('Пенсионер', 400.00),
    ('Ребенок от 7 до 17 лет', 350.00),
    ('Ребенок до 6 лет', 0.00)
) AS p(visitor_name, price_rub)
JOIN visitor_types AS v ON v.name = p.visitor_name;

-- По каждому билету доступны все пять коллекций из примера.
INSERT INTO ticket_collections (ticket_price_id, collection_id)
SELECT t.ticket_price_id, c.collection_id
FROM ticket_prices AS t
CROSS JOIN collections AS c;

COMMIT;

-- Вариант 13, запрос 1: коллекции с периодом показа не более 30 дней.
SELECT c.*
FROM collections AS c
WHERE c.end_date - c.start_date <= 30
ORDER BY c.end_date - c.start_date ASC;

-- Вариант 13, запрос 2: число экспонатов в каждой коллекции.
SELECT c.*, COUNT(e.exhibit_id) AS exhibit_count
FROM collections AS c
LEFT JOIN exhibits AS e ON e.collection_id = c.collection_id
GROUP BY c.collection_id
ORDER BY exhibit_count ASC, c.collection_id ASC;
