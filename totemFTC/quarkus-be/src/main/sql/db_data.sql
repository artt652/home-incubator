ALTER SEQUENCE IF EXISTS user_info_user_id_seq
    RESTART 10000;

INSERT INTO user_type_description(user_type, name) VALUES
                                            ('guest',   'Гость'),
                                            ('user',    'Посетитель'),  -- Allow payments through app
                                            ('trainer', 'Тренер'),
                                            ('admin',   'Администратор');

INSERT INTO training_type (training_type, name) VALUES
                                                    ('func',    'Кросcфит'),
                                                    ('stretch', 'Растяжка'),
                                                    ('yoga',    'Йога'),
                                                    ('massage', 'Массаж');

INSERT INTO user_info (user_id, first_name, last_name, nick_name, user_type, training_types) VALUES
                                                                                 (1000, 'Ринат', 'Фаттяхудинов', 'Ринат', 'admin', ['func']),
                                                                                 (1001, 'Нина', 'Елизова', 'Нина', 'trainer', ['func', 'stretch']),
                                                                                 (1002, 'Ильза', 'Зырянова', 'Ильза', 'trainer', ['func', 'stretch', 'yoga']);
INSERT INTO user_email (email, user_id, confirmed) VALUES
    ('rinchik_g@mail.ru', 1000, true);

