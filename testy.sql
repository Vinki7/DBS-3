-- 1st test case
-- Úspešné zoslanie kúziel a zabitie oponenta
-- Testuje plnú funkčnosť castu kúzla, zníženia HP a smrti oponenta.
-- Aktívny boj
-- Zoslanie ofenzívnych kúziel
-- Oponent má 0 HP a je mŕtvy - state = 'Died'

SELECT * FROM v_combat_state WHERE combat_id = 1; -- Získanie stavu boja
SELECT sp_cast_spell(1, 2, 1); -- Úspešné zoslanie kúzla
SELECT * FROM cv_combat_actions WHERE combat_id = 1; -- Získanie akcií boja
SELECT * FROM v_combat_state WHERE combat_id = 1; -- Získanie stavu boja
SELECT * FROM cv_character_profile; -- Oponent má 0 HP a je mŕtvy - state = 'Died'

-- 2nd test case
-- Úspešné zodvihnutie predmetu po smrti oponenta
-- Testuje možnosť zdvihnutia predmetu po smrti protivníka.
-- Oponent mŕtvy, predmet dostupný.
-- Pokus o zodvihnutie predmetu.
-- Predmet sa objaví v inventári postavy a je odstránený z bojiska.

SELECT * FROM cv_combat_actions WHERE combat_id = 1; -- Získanie akcií boja
SELECT * FROM cv_battleground_loot WHERE combat_id = 1; -- Získanie zoznamu loot predmetov
SELECT * FROM cv_character_profile WHERE character_id = 1; -- Oponent mŕtvy, predmet dostupný.
SELECT sp_loot_item(1, 1, 10); -- Pokus o pickup predmetu, neuspesný pokus, nedostatok miesta v inventári.
SELECT sp_loot_item(1, 1, 4); -- Pokus o pickup predmetu, úspešný pokus, predmet sa objaví v inventári postavy a je odstránený z bojiska.
SELECT * FROM cv_battleground_loot WHERE combat_id = 1; -- Získanie zoznamu loot predmetov - zmenený stav.
SELECT * FROM cv_character_profile WHERE character_id = 1; -- Predmet sa objaví v inventári postavy a je odstránený z bojiska.

-- 3rd test case
-- Zodvihnutie predmetu z iného bojiska
-- Testuje možnosť zodvihnutia predmetu z iného bojiska.
-- Existuje iný boj.
-- Pokus o zodvihnutie predmetu.
-- Proces končí s chybou, postava je mimo zamýšlaného bojiska.
SELECT * FROM cv_character_profile WHERE character_id = 1; -- Zobrazenie profilu postavy
SELECT * FROM cv_battleground_loot; -- Získanie stavu bojiska
SELECT sp_loot_item(2, 1, 4); -- Pokus o pickup predmetu, neuspesný pokus, predmet nie je dostupný.
SELECT * FROM cv_battleground_loot; -- Získanie stavu bojiska - predmet nie je dostupný.
SELECT * FROM cv_character_profile WHERE character_id = 1; -- Predmet sa objaví v inventári postavy a je odstránený z bojiska.

-- 4th test case
-- Zoslanie kúzla po smrti oponenta
-- Testuje možnosť zoslania kúzla po smrti protivníka.
-- Oponent mŕtvy, dostatok AP.
-- Pokus o zoslanie kúzla.
-- Proces končí s chybou, oponent je mŕtvy.
SELECT * FROM cv_character_profile WHERE character_id = 2; -- Zobrazenie profilu postavy
SELECT * FROM cv_combat_actions WHERE combat_id = 1; -- Získanie akcií boja
SELECT sp_cast_spell(1, 2, 1); -- Pokus o zoslanie kúzla, neuspesný pokus, oponent je mŕtvy.
SELECT * FROM cv_combat_actions WHERE combat_id = 1; -- Získanie akcií boja

-- 5th test case
-- Pokus o resetovanie kola pri nesúhlase účastníkov
-- Testuje možnosť resetovania kola pri nesúhlase účastníkov.
-- Aspoň jeden účastník nesúhlasí - pass_round = false.
-- Pokus o resetovanie kola.
-- Proces končí s chybou - Not all participants have passed the round for combat ID 1. 
SELECT * FROM v_combat_state WHERE combat_id = 1; -- Získanie stavu boja
SELECT sp_reset_round(1); -- Pokus o resetovanie kola, neuspesný pokus, aspoň jeden účastník nesúhlasí.
SELECT * FROM v_combat_state WHERE combat_id = 1; -- Získanie stavu boja

-- 6th test case
-- Úspešné resetovanie kola
-- Testuje možnosť resetovania kola.
-- Všetci účastníci súhlasia - pass_round = true.
-- Pokus o resetovanie kola.
-- Proces končí úspešne.
SELECT f_change_round_flag(1, TRUE);
SELECT f_change_round_flag(3, TRUE);
SELECT f_change_round_flag(5, TRUE);
SELECT f_change_round_flag(2, TRUE); -- Neprejde, pretože postava je mŕtva.
SELECT * FROM v_combat_state WHERE combat_id = 1; -- Získanie stavu boja
SELECT sp_reset_round(1); -- Pokus o resetovanie kola, úspešný pokus.
SELECT * FROM v_combat_state WHERE combat_id = 1; -- Získanie stavu boja
SELECT * FROM cv_combat_actions WHERE combat_id = 1; -- Získanie akcií boja

-- 7th test case
-- Uvedenie účastníka do oddychového stavu - neúspech
-- Testuje možnosť uvedenia účastníka do oddychového stavu.
-- Účastník je mŕtvy.
-- Pokus o uvedenie účastníka do oddychového stavu.
-- Proces končí s chybou - Character with ID 2 is dead and cannot rest.
SELECT * FROM cv_character_profile WHERE character_id = 2; -- Zobrazenie profilu postavy
SELECT sp_rest_character(2); -- Pokus o uvedenie účastníka do oddychového stavu, neuspesný pokus, účastník je mŕtvy.
SELECT * FROM cv_character_profile WHERE character_id = 2; -- Zobrazenie profilu postavy

-- 8th test case
-- Úspešné uvedenie účastníka do oddychového stavu
-- Testuje možnosť uvedenia účastníka do oddychového stavu.
-- Účastník je živý, jediný účastník v danom boji.
-- Pokus o uvedenie účastníka do oddychového stavu.
-- Proces končí úspešne.
SELECT sp_cast_spell(1, 4, 1); -- Zoslanie kúzla - účastník (ciel) je mimo daného boja., neuspesný pokus.
SELECT sp_cast_spell(1, 3, 1); -- Úspešné zoslanie kúzla - účastník (ciel) je v danom boji.
SELECT sp_cast_spell(1, 5, 1); -- Úspešné zoslanie kúzla - účastník (ciel) je v danom boji.
SELECT sp_cast_spell(1, 5, 1); -- Úspešné zoslanie kúzla - účastník (ciel) je v danom boji.
SELECT * FROM v_combat_state WHERE combat_id = 1; -- Získanie stavu boja
SELECT sp_rest_character(1); -- Pokus o uvedenie účastníka do oddychového stavu, úspešný pokus.
SELECT * FROM cv_character_profile WHERE character_id = 1; -- Zobrazenie profilu postavy
SELECT * FROM cv_combat_actions WHERE combat_id = 1; -- Získanie akcií boja

-- 9th test case
-- Neúspešné pridanie účastníka do boja
-- Testuje možnosť pridania účastníka do boja.
-- Účastník je v stave Resting, boj nie je aktívny.
-- Pokus o pridanie účastníka do boja.
-- Proces končí s chybou - Combat with ID 1 has already ended.
SELECT * FROM cv_character_profile WHERE character_id = 4; -- Zobrazenie profilu postavy
SELECT * FROM v_combat_state; -- Získanie stavu boja
SELECT sp_enter_combat(1, 4); -- Pokus o pridanie účastníka do boja, neuspesný pokus, účastník je v stave Resting.
SELECT * FROM cv_character_profile WHERE character_id = 4; -- Zobrazenie profilu postavy

-- 10th test case
-- Úspešné pridanie účastníka do boja
-- Testuje možnosť pridania účastníka do boja.
-- Účastník je v stave Resting, boj je aktívny.
-- Pokus o pridanie účastníka do boja.
-- Proces končí úspešne.
SELECT * FROM cv_character_profile WHERE character_id = 4; -- Zobrazenie profilu postavy
SELECT sp_enter_combat(2, 4); -- Pokus o pridanie účastníka do boja, úspešný pokus.
SELECT * FROM cv_character_profile WHERE character_id = 4; -- Zobrazenie profilu postavy
SELECT * FROM v_combat_state; -- Získanie stavu boja


-- 11th test case
-- Neúspešné zoslanie kúzla pri nedostatku AP
-- Testuje možnosť zoslania kúzla pri nedostatku AP.
-- Účastník je živý, v súboji, nedostatok AP.
-- Pokus o zoslanie kúzla.
-- Proces končí s chybou - Not enough action points to cast the spell.
SELECT * FROM v_combat_state; -- Získanie stavu boja



SELECT * FROM cv_character_profile WHERE character_id = 4; -- Zobrazenie profilu postavy
SELECT sp_cast_spell(4, 10, 14); -- Pokus o zoslanie kúzla, neuspesný pokus, nedostatok AP.
SELECT * FROM v_combat_state; -- Získanie stavu boja
SELECT * FROM cv_combat_actions WHERE combat_id = 2; -- Získanie akcií boja

