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

SELECT * FROM cv_battleground_loot;
