DROP VIEW IF EXISTS v_combat_damage;
-- This view provides a summary of the most damaging actions performed by characters in the game.
-- It aggregates data from the "Actions" table, joining with "Characters", "Classes", and "Spells" to provide a comprehensive view of damage dealt.
CREATE VIEW v_combat_damage AS
SELECT 
    c.id AS combat_id,
    SUM(a.effect) AS total_damage
FROM "Actions" AS a
JOIN "CombatRounds" AS cr ON a.round_id = cr.id
JOIN "Combats" AS c ON cr.combat_id = c.id
JOIN "Spells" AS s ON a.spell_id = s.id
WHERE s.effect_type = 'damage'
GROUP BY c.id
ORDER BY c.id;

SELECT * FROM v_combat_damage; -- Example call to the view
-- This needs to be validated and tested after implementation of all procedures and functions.