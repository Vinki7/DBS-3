DROP VIEW IF EXISTS cv_complete_spell_statistics;
-- -- This view provides a comprehensive overview of spell statistics, including the effective cost of spells, their usage in combat, and their effects.
-- -- It aggregates data from multiple tables to present a complete picture of spell performance and effectiveness in the game.
CREATE OR REPLACE VIEW cv_complete_spell_statistics AS
SELECT *
FROM v_spell_statistics AS s
UNION ALL
SELECT
    s.id AS spell_id,
    s.name AS spell_name,
    COUNT(a.id) AS times_used,
    SUM(a.effect) AS total_effect,
    AVG(a.effect) AS average_effect,
    AVG(a.ap_cost) AS average_cost
FROM "Actions" AS a 
JOIN "Spells" AS s ON s.id = a.spell_id
WHERE s.effect_type <> 'damage'
GROUP BY s.id, s.name
ORDER BY spell_id;

SELECT * FROM cv_complete_spell_statistics; -- Example call to the view