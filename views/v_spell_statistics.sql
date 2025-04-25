DROP VIEW IF EXISTS v_spell_statistics;
-- This view provides a summary of the statistics related to spell usage in the game.
-- It aggregates data from the "Actions" and "Spells" tables to provide insights into the effectiveness and frequency of spells used in combat.
CREATE OR REPLACE VIEW v_spell_statistics AS
SELECT
    s.id AS spell_id,
    s.name AS spell_name,
    COUNT(a.id) AS times_used,
    SUM(a.effect) AS total_effect,
    AVG(a.effect) AS average_effect
FROM "Actions" AS a 
JOIN "Spells" AS s ON s.id = a.spell_id
WHERE s.effect_type = 'damage'
GROUP BY s.id, s.name;

SELECT * FROM v_spell_statistics; -- Example call to the view
