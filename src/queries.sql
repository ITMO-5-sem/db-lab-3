-- Запрос 1
select оценк."ПРИМЕЧАНИЕ" as ОЦЕНКИ_ПРИМЕЧАНИЕ, вед."ИД" as ВЕДОМОСТи_ИД
from
    "Н_ВЕДОМОСТИ" as вед
    join
    "Н_ОЦЕНКИ" as оценк
    on вед."ОЦЕНКА" = оценк."КОД"
where
    оценк."ПРИМЕЧАНИЕ" = 'неудовлетворительно'
    and
    вед."ДАТА" > '2010-06-18'::timestamp
    and
    вед."ДАТА" < '1998-01-05'::timestamp;



-- Запрос 2
select *
from
     "Н_ЛЮДИ" as люд
     right join
     "Н_ОБУЧЕНИЯ" as обуч
     on люд."ИД" = обуч."ЧЛВК_ИД"
     right join
     "Н_УЧЕНИКИ" as учен
     on обуч."ЧЛВК_ИД" = учен."ЧЛВК_ИД"
where
    люд."ИМЯ" = 'Николай'
    and
    обуч."ЧЛВК_ИД" < 105590;



-- Запрос 3
with Уникальные_отчества as (
    select "ОТЧЕСТВО", count(*) as Количество_отчеств
    from "Н_ЛЮДИ"
    group by "ОТЧЕСТВО"
)
select count(*) from Уникальные_отчества;



-- Запрос 4
with группа_ученики as
(
    select группы_2011_КТиУ.номер, count(*) as количество_учеников
    from
    "Н_УЧЕНИКИ" as ученики
    join
    (
        select "ГРУППА" as номер
        from
        "Н_ГРУППЫ_ПЛАНОВ" as группы_планы
        join
        (
            select планы_2011_года."ИД"
            from "Н_ОТДЕЛЫ" as отделы
            join
            (
                select "ИД", "ОТД_ИД"
                from "Н_ПЛАНЫ"
                where "Н_ПЛАНЫ"."УЧЕБНЫЙ_ГОД" = '2011/2012'
            ) as планы_2011_года
            on планы_2011_года."ОТД_ИД" = отделы."ИД"
            where отделы."КОРОТКОЕ_ИМЯ" = 'КТиУ'
        ) as планы_2011_КТиУ
        on группы_планы."ПЛАН_ИД" = планы_2011_КТиУ."ИД"
    ) as группы_2011_КТиУ
    on ученики."ГРУППА" = группы_2011_КТиУ.номер
    group by группы_2011_КТиУ.номер
)
select count(*)
from группа_ученики
where группа_ученики.количество_учеников = 5;



-- Запрос 4 # 2
select *
from "Н_УЧЕНИКИ" as ученики -- [x rjhjxt
where ученики."НАЧАЛО" => '2011-11-21 00:00:00.000000'::timestamp;




-- Запрос 5

-- 1 вариант

create function get_students_and_avg_marks(group_number int)
returns table (ид int, фамилия varchar(25), имя varchar(15), отчество varchar(20), ср_оценка numeric)
language plpgsql as $$
    begin
        return query
            with человек_оценка as
            (
                select ученики."ИД", ученики."ФАМИЛИЯ", ученики."ИМЯ", ученики."ОТЧЕСТВО", ведомости."ОЦЕНКА"
                from
                "Н_ВЕДОМОСТИ" as ведомости
                join
                (
                    select "ИД", "ФАМИЛИЯ", "ИМЯ", "ОТЧЕСТВО"
                    from
                    "Н_ЛЮДИ" as люди
                    join
                    (
                        select ученики."ЧЛВК_ИД"
                        from "Н_УЧЕНИКИ" as ученики
                        where ученики."ГРУППА" = group_number
                    ) as ученики_4100_группы
                    on ученики_4100_группы."ЧЛВК_ИД" = люди."ИД"
                ) as ученики
                on ведомости."ЧЛВК_ИД" = ученики."ИД"
            )
            select "ИД", "ФАМИЛИЯ", "ИМЯ", "ОТЧЕСТВО", avg("ОЦЕНКА"::int)
            from человек_оценка
            where
                человек_оценка."ОЦЕНКА" ~ '^[0-9\.]+$'
            group by "ИД", "ФАМИЛИЯ", "ИМЯ", "ОТЧЕСТВО";
    end;
$$;


select * from get_students_and_avg_marks(4100);



-- 2 вариант

with человек_оценка as
(
    select ученики."ИД", ученики."ФАМИЛИЯ", ученики."ИМЯ", ученики."ОТЧЕСТВО", ведомости."ОЦЕНКА"
    from
    "Н_ВЕДОМОСТИ" as ведомости
    join
    (
        select "ИД", "ФАМИЛИЯ", "ИМЯ", "ОТЧЕСТВО"
        from
        "Н_ЛЮДИ" as люди
        join
        (
            select ученики."ЧЛВК_ИД"
            from "Н_УЧЕНИКИ" as ученики
            where ученики."ГРУППА" = '4100'
        ) as ученики_4100_группы
        on ученики_4100_группы."ЧЛВК_ИД" = люди."ИД"
    ) as ученики
    on ведомости."ЧЛВК_ИД" = ученики."ИД"
)
select "ИД", "ФАМИЛИЯ", "ИМЯ", "ОТЧЕСТВО", avg("ОЦЕНКА"::int)
from человек_оценка
where
    человек_оценка."ОЦЕНКА" ~ '^[0-9\.]+$'
    and человек_оценка."ОЦЕНКА"::numeric <=
        (
            with оценки as
            (
                select ведомости."ОЦЕНКА"
                from
                "Н_ВЕДОМОСТИ" as ведомости
                join
                (
                    select "ИД", "ФАМИЛИЯ", "ИМЯ", "ОТЧЕСТВО"
                    from
                    "Н_ЛЮДИ" as люди
                    join
                    (
                        select ученики."ЧЛВК_ИД"
                        from "Н_УЧЕНИКИ" as ученики
                        where ученики."ГРУППА" = '1100'
                    ) as ученики_4100_группы
                    on ученики_4100_группы."ЧЛВК_ИД" = люди."ИД"
                ) as ученики
                on ведомости."ЧЛВК_ИД" = ученики."ИД"
            )
            select avg("ОЦЕНКА"::int)
            from оценки
            where
                оценки."ОЦЕНКА" ~ '^[0-9\.]+$'
        )

group by "ИД", "ФАМИЛИЯ", "ИМЯ", "ОТЧЕСТВО";




-- 6 запрос
