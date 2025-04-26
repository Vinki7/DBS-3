CREATE OR REPLACE FUNCTION sp_loot_item (
    p_combat_id BIGINT,
    p_character_id BIGINT,
    p_item_id BIGINT
) RETURNS VOID AS $$
DECLARE
    v_item_weight NUMERIC; -- Variable to hold the weight of the item
    v_inventory_limit NUMERIC; -- Variable to hold the character's maximum inventory capacity
    v_inventory_weight NUMERIC; -- Variable to hold the character's current inventory weight
BEGIN
-- ------------------------------------------------------ Validation of entry conditions ------------------------------------------------------
-- Check that the item is available in the combat area .
-- Verify the character ’ s current inventory weight and maximum capacity .
-- If the item is not available or the character ’ s inventory is full , raise an exception .
-- ------------------------------------------------------ Process loot data & state ------------------------------------------------------
-- If within limits , add the item to the character ’ s inventory and remove it from the combat area .
-- Log the looting event .

-- ------------------------------------------------------ Validation of entry conditions ------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM "Combats" WHERE id = p_combat_id) THEN -- Check that the combat exists
        RAISE EXCEPTION 'Combat with ID % does not exist', p_combat_id;
    END IF;

    IF NOT EXISTS ( -- Check that the character is in the combat
        SELECT 1 
        FROM "CombatParticipants" AS cp
        JOIN "Combats" AS c ON cp.combat_id = c.id
        WHERE cp.character_id = p_character_id AND c.id = p_combat_id AND c.time_ended IS NULL
    ) THEN 
        RAISE EXCEPTION 'Character with ID % is not in combat %', p_character_id, p_combat_id;
    END IF;

    IF (SELECT state FROM "Characters" WHERE id = p_character_id) <> 'In combat' THEN -- Check that the character is in a valid state to loot
        RAISE EXCEPTION 'Character with ID % is not in a valid state to loot', p_character_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "Items" WHERE id = p_item_id) THEN -- Check that the item exists
        RAISE EXCEPTION 'Item with ID % does not exist', p_item_id;
    END IF;

    IF NOT EXISTS ( -- Check that the item is available in the combat area
        SELECT 1 
        FROM "CombatItems" AS ci
        WHERE ci.combat_id = p_combat_id AND ci.item_id = p_item_id
    ) THEN 
        RAISE EXCEPTION 'Item with ID % is not available in combat %', p_item_id, p_combat_id;
    END IF;

    v_item_weight := (SELECT weight FROM "Items" WHERE id = p_item_id); -- Get the weight of the item

    IF v_item_weight IS NULL THEN -- Validate that the item has a weight
        RAISE EXCEPTION 'Item with ID % does not have a valid weight', p_item_id;
    END IF;

    v_inventory_limit := f_max_inventory_weight(p_character_id); -- Get the character's maximum inventory capacity

    IF v_inventory_limit IS NULL THEN -- Validate that the character has a valid inventory limit
        RAISE EXCEPTION 'Character with ID % does not have a valid inventory limit', p_character_id;
    END IF;

    v_inventory_weight := f_inventory_weight(p_character_id); -- Get the character's current inventory weight

    IF v_inventory_weight IS NULL THEN -- Validate that the character has a valid inventory weight
        RAISE EXCEPTION 'Character with ID % does not have a valid inventory weight', p_character_id;
    END IF;

    IF (v_inventory_weight + v_item_weight) > v_inventory_limit THEN -- Check if the character's inventory is full
        RAISE EXCEPTION 'Character with ID % cannot loot item % due to inventory limit', p_character_id, p_item_id;
    END IF;

    -- ------------------------------------------------------ Process loot data & state ------------------------------------------------------
    INSERT INTO "Inventory" (character_id, item_id)
        VALUES (
            p_character_id,
            p_item_id
        );

    DELETE FROM "CombatItems"
    WHERE item_id = p_item_id AND combat_id = p_combat_id;

    INSERT INTO "Actions" -- Log the item drop event in the combat log .
        (round_id, spell_id, action_type, actor_id, target_id, item_id, ap_cost, effect, dice_roll, action_timestamp)
    VALUES (
        (
            SELECT cr.id
            FROM "CombatRounds" AS cr
            WHERE cr.combat_id = p_combat_id AND cr.time_ended IS NULL
        ), NULL, 'collect item', p_character_id, NULL, p_item_id, 0, 0, NULL, now()
    );

    RETURN;

END ;
$$ LANGUAGE plpgsql ;

SELECT sp_loot_item(1, 1, 5); -- Test the function with a combat ID, character ID, and item ID