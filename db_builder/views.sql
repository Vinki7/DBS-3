-- ----------------------------------------------------- v_strongest_characters.sql -----------------------------------------------------
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

-- ----------------------------------------------------- v_spell_statistics.sql -----------------------------------------------------
DROP VIEW IF EXISTS v_spell_statistics;
-- This view provides a summary of the statistics related to spell usage in the game.
-- It aggregates data from the "Actions" and "Spells" tables to provide insights into the effectiveness and frequency of spells used in combat.
CREATE OR REPLACE VIEW v_spell_statistics AS
SELECT
    s.id AS spell_id,
    s.name AS spell_name,
    COUNT(a.id) AS times_used,
    SUM(a.effect) AS total_effect,
    ROUND(AVG(a.effect), 2) AS average_effect,
    ROUND(AVG(a.ap_cost), 2) AS average_cost
FROM "Actions" AS a 
JOIN "Spells" AS s ON s.id = a.spell_id
WHERE s.effect_type = 'damage'
GROUP BY s.id, s.name;

DROP VIEW IF EXISTS v_most_damage;
-- This view provides a summary of the most damaging actions performed by characters in the game.
-- It aggregates data from the "Actions" table, joining with "Characters", "Classes", and "Spells" to provide a comprehensive view of damage dealt.
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

-- ----------------------------------------------------- v_combat_state.sql -----------------------------------------------------
DROP VIEW IF EXISTS v_combat_state CASCADE;
CREATE OR REPLACE VIEW v_combat_state AS
-- This view provides a snapshot of the current state of all characters involved in active combats.
-- It includes details such as the combat ID, character ID, class name, current state, remaining action points, and health.
SELECT
    cp.combat_id,
    c.id AS character_id,
    cl.name AS class_name,
    c.state AS character_state,
    cp.act_action_points AS remaining_ap,
    cp.act_health AS remaining_health,
    cp.round_passed AS round_passed,
    com.act_round_number AS current_round
FROM "CombatParticipants" AS cp
JOIN "Characters" AS c ON cp.character_id = c.id
JOIN "Combats" AS com ON cp.combat_id = com.id
JOIN "Classes" AS cl ON c.class_id = cl.id
WHERE c.state = 'In combat';

-- ----------------------------------------------------- v_combat_damage.sql -----------------------------------------------------
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

-- ----------------------------------------------------- cv_complete_spell_statistics.sql -----------------------------------------------------
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

-- ----------------------------------------------------- cv_combat_actions.sql -----------------------------------------------------
DROP VIEW IF EXISTS cv_combat_actions;
CREATE OR REPLACE VIEW cv_combat_actions AS
SELECT 
    a.id AS action_id,
    a.actor_id,
    a.spell_id,
    a.target_id,
    a.item_id,
    a.effect,
    a.dice_roll,
    a.ap_cost,
    a.action_type,
    a.action_timestamp,
    a.round_id,
    cr.time_started AS round_start_time,
    cr.time_ended AS round_end_time,
    cr.combat_id
FROM "Actions" AS a
JOIN "CombatRounds" AS cr ON a.round_id = cr.id
ORDER BY cr.combat_id, a.action_timestamp, a.id;

-- ----------------------------------------------------- cv_character_profile.sql -----------------------------------------------------
DROP VIEW IF EXISTS cv_character_profile;
-- This view provides a comprehensive profile of each character, including their attributes, inventory items, and learned spells.
-- It aggregates data from multiple tables to present a complete picture of the character's status and capabilities.
CREATE OR REPLACE VIEW cv_character_profile AS
SELECT 
    c.id AS character_id,
    c.state,
    cl.name AS class_name,
    c.experience_points,
    f_attribute_value(c.id, (
        SELECT attr.id
        FROM "Attributes" AS attr
        WHERE attr.name = 'Health'
    )) AS max_health,
    f_max_ap(c.id) AS max_action_points,
    f_max_inventory_weight(c.id) AS max_inventory_weight,
    f_inventory_weight(c.id) AS current_inventory_weight,
    f_attribute_value(c.id, (
        SELECT attr.id
        FROM "Attributes" AS attr
        WHERE attr.name = 'Armor'
    )) AS armor_total,
    f_attribute_value(c.id, (
        SELECT attr.id
        FROM "Attributes" AS attr
        WHERE attr.name = 'Intelligence'
    )) AS intelligence_total,
    f_attribute_value(c.id, (
        SELECT attr.id
        FROM "Attributes" AS attr
        WHERE attr.name = 'Dexterity'
    )) AS dexterity_total,
    f_attribute_value(c.id, (
        SELECT attr.id
        FROM "Attributes" AS attr
        WHERE attr.name = 'Strength'
    )) AS strength_total,
    f_attribute_value(c.id, (
        SELECT attr.id
        FROM "Attributes" AS attr
        WHERE attr.name = 'Constitution'
    )) AS constitution_total,
    ARRAY_AGG(DISTINCT a.name || ': ' || ca.base_value) AS attributes_base,
    ARRAY_AGG(i.name) AS iventory_items,
    ARRAY_AGG(DISTINCT s.name) AS learned_spells
FROM "Characters" AS c
JOIN "Classes" AS cl ON c.class_id = cl.id
LEFT JOIN "CharacterAttributes" AS ca ON ca.character_id = c.id
LEFT JOIN "Attributes" AS a ON a.id = ca.attribute_id
LEFT JOIN "Inventory" inv ON inv.character_id = c.id
LEFT JOIN "Items" AS i ON i.id = inv.item_id
LEFT JOIN "CharacterSpells" AS cs ON cs.character_id = c.id
LEFT JOIN "Spells" AS s ON s.id = cs.spell_id
GROUP BY c.id, c.state, cl.name, c.experience_points;

-- ----------------------------------------------------- cv_battleground_loot.sql -----------------------------------------------------
DROP VIEW IF EXISTS cv_battleground_loot;

CREATE OR REPLACE VIEW cv_battleground_loot AS
SELECT
    ci.combat_id,
    COUNT(i.id) AS item_count,
    array_agg(i.id) AS item_ids,
    array_agg(i.name) AS item_names,
    STRING_AGG(i.name, ', ') AS loot_items
FROM "CombatItems" AS ci
JOIN "Items" AS i ON ci.item_id = i.id
GROUP BY ci.combat_id;