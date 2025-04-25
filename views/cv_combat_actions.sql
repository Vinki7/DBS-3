DROP VIEW IF EXISTS v_combat_actions;
CREATE OR REPLACE VIEW v_combat_actions AS
SELECT 
    a.id AS action_id,
    a.actor_id,
    a.spell_id,
    a.target_id,
    a.item_id,
    a.effect,
    a.ap_cost,
    a.action_type,
    a.action_timestamp,
    a.round_id,
    cr.time_started AS round_start_time,
    cr.time_ended AS round_end_time,
    cr.combat_id
FROM "Actions" AS a
JOIN "CombatRounds" AS cr ON a.round_id = cr.id;

SELECT * FROM v_combat_actions;

