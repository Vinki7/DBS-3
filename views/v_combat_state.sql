CREATE OR REPLACE VIEW v_combat_state AS
SELECT
    cp.combat_id,
    c.id AS character_id,
    cl.name AS class_name,
    c.state AS character_state,
    cp.act_action_points AS remaining_ap,
    cp.act_health AS remaining_health,
    com.act_round_number AS current_round
FROM "CombatParticipants" AS cp
JOIN "Characters" AS c ON cp.character_id = c.id
JOIN "Combats" AS com ON cp.combat_id = com.id
JOIN "Classes" AS cl ON c.class_id = cl.id
WHERE c.state = 'In combat';

SELECT * FROM v_combat_state; -- Example call to the view