DROP VIEW IF EXISTS v_character_profile;
-- This view provides a comprehensive profile of each character, including their attributes, inventory items, and learned spells.
-- It aggregates data from multiple tables to present a complete picture of the character's status and capabilities.
CREATE OR REPLACE VIEW v_character_profile AS
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
    ARRAY_AGG(DISTINCT i.name) AS iventory_items,
    ARRAY_AGG(DISTINCT s.name) AS learned_spells
FROM "Characters" c
JOIN "Classes" cl ON c.class_id = cl.id
LEFT JOIN "CharacterAttributes" ca ON ca.character_id = c.id
LEFT JOIN "Attributes" a ON a.id = ca.attribute_id
LEFT JOIN "Inventory" inv ON inv.character_id = c.id
LEFT JOIN "Items" i ON i.id = inv.item_id
LEFT JOIN "CharacterSpells" cs ON cs.character_id = c.id
LEFT JOIN "Spells" s ON s.id = cs.spell_id
GROUP BY c.id, c.state, cl.name, c.experience_points;

SELECT * FROM v_character_profile;