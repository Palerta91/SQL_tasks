/*
Абрамкина Милана Игоревна
Вариант: 13
База данных музея

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
