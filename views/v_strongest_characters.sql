DROP VIEW IF EXISTS v_strongest_characters;
-- -- This view provides a summary of the strongest characters in the game based on damage dealt, remaining health, and combat participation.
-- -- It aggregates data from the "Actions", "CombatParticipants", and "Characters" tables to present a comprehensive view of character performance.
-- -- The view includes a performance score that can be customized based on the game's requirements.
CREATE VIEW v_strongest_characters AS
SELECT 
    c.id AS character_id,
    cl.name AS class_name,
    c.state AS character_state,
    COALESCE(cp_count.combat_participated, 0) AS combat_participated,
    COALESCE(d.total_damage, 0) AS total_damage,
    COALESCE(cp.act_health, 0) AS remaining_health,
    -- You can customize this "performance score" formula
    (COALESCE(d.total_damage, 0) + COALESCE(cp.act_health, 0)) AS performance_score
FROM "Characters" c
JOIN "Classes" cl ON c.class_id = cl.id
LEFT JOIN (
    SELECT 
        a.actor_id AS character_id,
        SUM(a.effect) AS total_damage
    FROM "Actions" AS a
    JOIN "Spells" AS s ON a.spell_id = s.id
    WHERE s.effect_type = 'damage'
    GROUP BY a.actor_id
) AS d ON c.id = d.character_id
LEFT JOIN (
    SELECT 
        character_id,
        MAX(act_health) AS act_health
    FROM "CombatParticipants"
    GROUP BY character_id
) AS cp ON c.id = cp.character_id
LEFT JOIN (
    SELECT
        character_id,
        COUNT(*) AS combat_participated
    FROM "CombatParticipants"
    GROUP BY character_id
) AS cp_count ON c.id = cp_count.character_id
ORDER BY performance_score DESC, total_damage DESC, remaining_health DESC, combat_participated DESC;

SELECT * FROM v_strongest_characters; -- Example call to the view
