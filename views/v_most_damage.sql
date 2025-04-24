CREATE OR REPLACE VIEW v_most_damage AS
SELECT
    a.actor_id AS character_id,
    c.state AS character_state,
    cl.name AS class_name,
    SUM(a.effect) AS total_damage
FROM "Actions" AS a
JOIN "Characters" AS c ON a.actor_id = c.id
JOIN "Classes" AS cl ON c.class_id = cl.id
JOIN "Spells" AS s ON a.spell_id = s.id
WHERE a.spell_id IS NOT NULL AND s.effect_type = 'damage'
GROUP BY a.actor_id, c.state, cl.name
ORDER BY total_damage DESC;

SELECT * FROM v_most_damage; -- Example call to the view