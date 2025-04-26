-- ----------------------------------------------------- f_attribute_value.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION f_attribute_value(
    p_character_id BIGINT, -- Character ID
    p_attribute_id BIGINT -- Attribute ID
) RETURNS NUMERIC AS $$
DECLARE
    base_value INT; -- Base value from CharacterAttributes
    item_modifier NUMERIC DEFAULT 0; -- From ItemAttributes
    class_modifier NUMERIC DEFAULT 0; -- From ClassAttributes
    char_class_id BIGINT; -- Class ID of the character
BEGIN
    -- Get the base value from CharacterAttributes
    SELECT char_attr.base_value 
        INTO base_value
    FROM "CharacterAttributes" AS char_attr
    WHERE char_attr.character_id = p_character_id AND char_attr.attribute_id = p_attribute_id;

    -- Get the class ID of the character
    SELECT c.class_id 
        INTO char_class_id
    FROM "Characters" AS c
    WHERE c.id = p_character_id;

    -- Get the class modifier from ClassAttributes
    SELECT COALESCE(class_attr.modifier, 1) -- Default to 1 if no modifier found
        INTO class_modifier
    FROM "ClassAttributes" AS class_attr
    WHERE class_attr.class_id = char_class_id AND class_attr.attribute_id = p_attribute_id;

    -- Get total item bonus for this attribute
    SELECT COALESCE(SUM(i_attr.modifier), 0)
        INTO item_modifier
    FROM "ItemAttributes" AS i_attr
    JOIN "Inventory" AS i 
        ON i.item_id = i_attr.item_id
    WHERE i.character_id = p_character_id AND i_attr.attribute_id = p_attribute_id;

    RETURN (base_value * COALESCE(class_modifier, 1)) + item_modifier; -- Calculate the effective attribute value
END;
$$ LANGUAGE plpgsql ;

-- ----------------------------------------------------- f_change_round_flag.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION f_change_round_flag(
    p_character_id BIGINT, -- Character ID
    p_pass_flag BOOLEAN -- Flag to indicate if the character passed the round
) RETURNS VOID AS $$
DECLARE
    v_combat_id BIGINT; -- Variable to hold the combat ID
    v_round_id BIGINT; -- Variable to hold the round ID
BEGIN
    -- Check if the character is in a valid state
    IF NOT EXISTS (SELECT 1 FROM "Characters" WHERE id = p_character_id AND state = 'In combat') THEN
        RAISE EXCEPTION 'Character with ID % is not in a valid state to pass the round', p_character_id;
    END IF;

    v_combat_id := (
        SELECT combat_id 
        FROM "CombatParticipants" AS cp
        JOIN "Combats" AS c ON cp.combat_id = c.id
        WHERE cp.character_id = p_character_id 
            AND c.time_ended IS NULL
    ); -- Get the combat ID of the character 

    -- Check if the character is in an active combat  
    IF v_combat_id IS NULL THEN
        RAISE EXCEPTION 'Character with ID % is not in any active combat', p_character_id;
    END IF;

    -- Get the actual round ID
    v_round_id := (SELECT id FROM "CombatRounds" WHERE combat_id = v_combat_id AND time_ended IS NULL); -- Get the round ID of the combat

    -- Check if the round is active
    IF v_round_id IS NULL THEN
        RAISE EXCEPTION 'No active round found for combat ID %', v_combat_id;
    END IF;

    UPDATE "CombatParticipants" -- Update the combat participants table
    SET round_passed = TRUE
    WHERE character_id = p_character_id AND combat_id = v_combat_id;

    INSERT INTO "Actions" (round_id, actor_id, action_type, ap_cost, effect, action_timestamp) -- Insert a new action into the actions table
        VALUES (
            v_round_id, 
            p_character_id, 
            CAST(CASE WHEN p_pass_flag THEN 'pass round' ELSE 'continue' END AS action_type_enum),
            0, 
            0, 
            NOW()
        );
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------ f_get_armor_class.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION f_get_armor_class (
    p_character_id BIGINT
) RETURNS NUMERIC AS $$
DECLARE
    v_dexterity_id BIGINT; -- Assuming 1 is the ID for Dexterity attribute
    v_dexterity_value NUMERIC; -- Variable to hold the Dexterity value

    v_armor_id BIGINT;
    v_armor_class_value NUMERIC; -- Variable to hold the calculated armor class value
BEGIN
    SELECT id INTO v_dexterity_id 
    FROM "Attributes" AS attr 
    WHERE attr.name = 'Dexterity'; -- Get the ID for Dexterity attribute

    SELECT id INTO v_armor_id
    FROM "Attributes" AS attr
    WHERE attr.name = 'Armor';

    v_dexterity_value := f_attribute_value(p_character_id, v_dexterity_id); -- Get the Dexterity value for the character

    IF v_dexterity_value IS NULL THEN
        RAISE EXCEPTION 'Character or Dexterity attribute not found.'; -- tu mi to hadze exception
    END IF;

    WITH ac_modifier AS (
        SELECT cl.ac_modifier AS value
        FROM "Characters" AS c
        JOIN "Classes" AS cl ON c.class_id = cl.id
        WHERE c.id = p_character_id
    )
    SELECT 10 + (v_dexterity_value / 2) * ac_modifier.value
        INTO v_armor_class_value
    FROM ac_modifier; -- Calculate the base armor class value

    v_armor_class_value := ROUND(
        v_armor_class_value + f_total_item_bonus(p_character_id, v_armor_id), -- Add item bonus to the armor class
    2); -- Round the value to 2 decimal places
    
    RETURN v_armor_class_value; -- Return the calculated armor class value
END;
$$ LANGUAGE plpgsql;

SELECT sp_cast_spell(1, 2, 1);

-- ----------------------------------------------------- f_inventory_weight.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION f_inventory_weight(
    p_character_id BIGINT -- Character ID
) RETURNS NUMERIC AS $$
BEGIN
    -- Check if the character exists
    IF NOT EXISTS (SELECT 1 FROM "Characters" WHERE id = p_character_id) THEN
        RAISE EXCEPTION 'Character with ID % does not exist', p_character_id;
    END IF;

    -- Calculate the total weight of items in the character's inventory
    RETURN (SELECT COALESCE(SUM(i.weight), 0) -- Default to 0 if no items found
    FROM "Inventory" AS inv
    JOIN "Items" AS i ON inv.item_id = i.id
    WHERE inv.character_id = p_character_id);
END;
$$ LANGUAGE plpgsql ;

-- ----------------------------------------------------- f_max_ap -----------------------------------------------------
CREATE OR REPLACE FUNCTION f_max_ap(
    p_character_id BIGINT
) RETURNS NUMERIC AS $$
DECLARE
    v_max_ap NUMERIC; -- Variable to hold the maximum action points
    v_dexterity NUMERIC; -- Variable to hold the dexterity value
    v_intelligence NUMERIC; -- Variable to hold the intelligence value
BEGIN
    -- Check if the character exists
    IF NOT EXISTS (SELECT 1 FROM "Characters" WHERE id = p_character_id) THEN
        RAISE EXCEPTION 'Character with ID % does not exist', p_character_id;
    END IF;

    v_dexterity := f_attribute_value(p_character_id, (SELECT attr.id FROM "Attributes" AS attr WHERE attr.name = 'Dexterity')); -- Get the dexterity value of the character
    v_intelligence := f_attribute_value(p_character_id, (SELECT attr.id FROM "Attributes" AS attr WHERE attr.name = 'Intelligence')); -- Get the intelligence value of the character

    v_max_ap := (v_dexterity + v_intelligence) * (
        SELECT cl.ap_modifier
        FROM "Characters" AS c
        JOIN "Classes" AS cl ON c.class_id = cl.id
        WHERE c.id = p_character_id
    ); -- Calculate the maximum action points

    IF v_max_ap IS NULL THEN -- Validate that the maximum action points are not null
        RAISE EXCEPTION 'Error calculating maximum action points for character ID %', p_character_id;
    END IF;

    RETURN v_max_ap; -- Return the maximum action points
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------- f_max_inventory_weight.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION f_max_inventory_weight(
    p_character_id BIGINT -- Character ID
) RETURNS NUMERIC AS $$
DECLARE
    v_strength NUMERIC; -- Variable to hold the character's strength
    v_constitution NUMERIC; -- Variable to hold the character's constitution
    v_class_modifier NUMERIC; -- Variable to hold the class modifier for inventory weight
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "Characters" WHERE id = p_character_id) THEN -- Check if the character exists
        RAISE EXCEPTION 'Character with ID % does not exist', p_character_id;
    END IF;

    v_strength := f_attribute_value(
        p_character_id, 
        (SELECT id FROM "Attributes" WHERE name = 'Strength') -- Get the character's strength attribute ID
    ); -- Get the character's strength

    v_constitution := f_attribute_value(
        p_character_id, 
        (SELECT id FROM "Attributes" WHERE name = 'Constitution') -- Get the character's constitution attribute ID
    ); -- Get the character's constitution

    v_class_modifier := COALESCE((
        SELECT inventory_modifier 
        FROM "Classes" 
        WHERE id = (SELECT class_id FROM "Characters" WHERE id = p_character_id)
    ), 1); -- Get the class modifier for inventory weight

    RETURN ROUND(((v_strength + v_constitution) * v_class_modifier), 2);

END;
$$ LANGUAGE plpgsql ;

-- ----------------------------------------------------- f_spell_effect.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION f_spell_effect(
    p_spell_id BIGINT,
    p_caster_id BIGINT,
    p_dice_roll INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    spell_exists INT; -- Variable to check if the spell exists
    base_effect INT;
    total_attribute_value NUMERIC DEFAULT 0;
    final_effect NUMERIC;

    rec RECORD; -- Record to hold the attribute values, generic type
BEGIN  
    SELECT COUNT(*) INTO spell_exists
    FROM "CharacterSpells" AS assigned_s
    WHERE assigned_s.spell_id = p_spell_id AND assigned_s.character_id = p_caster_id;

    -- Get the base effect of the spell
    SELECT sp.base_effect
        INTO base_effect
    FROM "Spells" AS sp
    WHERE sp.id = p_spell_id;

    -- Loop through the attributes that affect the spell and sum their values
    FOR rec IN
        SELECT sp_attr.attribute_id -- Get the attribute ID
        FROM "SpellAttributes" AS sp_attr
        WHERE sp_attr.spell_id = p_spell_id -- Get all attributes for the spell
    LOOP
        total_attribute_value := total_attribute_value + COALESCE(f_attribute_value(p_caster_id, rec.attribute_id), 0);
    END LOOP;

    final_effect := base_effect * (1 + (total_attribute_value / (21 - p_dice_roll))); -- Calculate the final effect

    RETURN ROUND(final_effect, 2); -- Return the final effect rounded to 2 decimal places
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------- f_total_item_bonus.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION f_total_item_bonus(
    p_character_id BIGINT, -- Character ID
    p_attribute_id BIGINT -- Attribute ID
) RETURNS NUMERIC AS $$
DECLARE
    total_bonus NUMERIC DEFAULT 0; -- Variable to hold the total item bonus
BEGIN
    SELECT COALESCE(SUM(i_attr.modifier), 0)
        INTO total_bonus
    FROM "ItemAttributes" AS i_attr
    JOIN "Inventory" AS i 
        ON i.item_id = i_attr.item_id
    WHERE i.character_id = p_character_id AND i_attr.attribute_id = p_attribute_id;

    RETURN total_bonus; -- Return the total item bonus
END;
$$ LANGUAGE plpgsql ;

-- ----------------------------------------------------- f_effective_spell_cost.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION f_effective_spell_cost(
    p_spell_id INTEGER,
    p_caster_id INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    v_effective_cost NUMERIC; -- Variable to hold the effective spell cost
BEGIN
    WITH spell_validation AS (
        -- Validate that the spell exists and the caster is valid
        SELECT COUNT(*) AS spell_exists
        FROM "CharacterSpells" AS assigned_s
        WHERE assigned_s.spell_id = p_spell_id AND assigned_s.character_id = p_caster_id
    ),
    base_cost_query AS ( -- Get the base cost of the spell from category
        SELECT cat.base_cost
        FROM "SpellCategories" AS cat
        JOIN "Spells" AS sp ON cat.id = sp.category_id
        WHERE sp.id = p_spell_id
    ),
    attribute_values AS ( -- Get the total attribute value for the caster
        SELECT COALESCE(SUM(f_attribute_value(p_caster_id, sp_attr.attribute_id)), 0) AS total_value
        FROM "SpellAttributes" AS sp_attr
        WHERE sp_attr.spell_id = p_spell_id
    )
    SELECT 
        CASE
            WHEN spell_validation.spell_exists = 0
                THEN NULL
            ELSE ROUND(
                base_cost_query.base_cost * (1 - LEAST(80, attribute_values.total_value) / 100),
                2
            ) INTO v_effective_cost -- Calculate the effective cost using the formula
        END
    FROM base_cost_query, attribute_values, spell_validation
    WHERE base_cost_query.base_cost IS NOT NULL AND attribute_values.total_value IS NOT NULL;

    RETURN v_effective_cost;

END;
$$ LANGUAGE plpgsql;

-- 
CREATE OR REPLACE FUNCTION sp_cast_spell (
    p_caster_id INTEGER ,
    p_target_id INTEGER ,
    p_spell_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_combat_id BIGINT; -- Variable to hold the combat ID

    v_effective_cost NUMERIC; -- Variable to hold the effective spell cost

    v_spell_type VARCHAR; -- Variable to hold the type of spell (e.g., damage, healing)
    v_spell_effect NUMERIC; -- Variable to hold the spell effect value
    v_max_health INTEGER; -- Variable to hold the maximum health of the target

    v_caster_ap NUMERIC; -- Variable to hold the caster's action points

    v_target_health NUMERIC; -- Variable to hold the target's health after applying the spell effect
    v_target_armor_class NUMERIC; -- Variable to hold the target's armor class

    v_dice_roll INTEGER;

    r_item RECORD; -- Record to hold the item details (if any)
BEGIN
-- ----------------------------------------- Gather data -----------------------------------------
    IF NOT EXISTS (SELECT 1 FROM "Characters" WHERE id = p_caster_id) THEN -- Validate that the caster exists
        RAISE EXCEPTION 'Caster with ID % does not exist.', p_caster_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "Characters" WHERE id = p_target_id) THEN -- Validate that the target exists
        RAISE EXCEPTION 'Target with ID % does not exist.', p_target_id;
    END IF;

    SELECT cp.act_action_points, cp.combat_id -- Get the caster's action points and combat ID
        INTO v_caster_ap, v_combat_id
    FROM "CombatParticipants" AS cp
        JOIN "Combats" AS c ON cp.combat_id = c.id
    WHERE c.time_ended IS NULL AND cp.character_id = p_caster_id;

    SELECT cp.act_health -- Get the target's health
        INTO v_target_health
    FROM "CombatParticipants" AS cp
        JOIN "Combats" AS c ON cp.combat_id = c.id
    WHERE c.time_ended IS NULL AND cp.character_id = p_target_id;

    IF NOT EXISTS (SELECT 1 FROM "CombatParticipants" AS cp WHERE cp.character_id = p_target_id AND cp.combat_id = v_combat_id) THEN -- Validate that the target is in the same combat
        RAISE EXCEPTION 'Target not found or not in combat.';
    END IF;

    IF v_target_health IS NULL THEN -- Validate that the target is in combat and has health
        RAISE EXCEPTION 'Target not found or not in combat.';
    END IF;

    IF v_target_health <= 0 THEN -- Validate that the target is alive
        RAISE EXCEPTION 'Target is dead and cannot be affected by the spell.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "Spells" WHERE id = p_spell_id) THEN -- Validate that the spell exists
        RAISE EXCEPTION 'Spell with ID % does not exist.', p_spell_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "CharacterSpells" WHERE character_id = p_caster_id AND spell_id = p_spell_id) THEN -- Validate that the caster has the spell
        RAISE EXCEPTION 'Caster does not have the spell with ID %.', p_spell_id;
    END IF;

    SELECT s.effect_type -- Get the spell type
        INTO v_spell_type
    FROM "Spells" AS s
    WHERE s.id = p_spell_id;

-- ----------------------------------------- Manipulate AP -----------------------------------------
    v_effective_cost := f_effective_spell_cost(p_spell_id, p_caster_id); -- Calculate the effective cost of the spell

    IF v_effective_cost IS NULL THEN -- Validate that the spell exists and the caster has the spell
        RAISE EXCEPTION 'Spell not found or caster does not have the spell.';
    END IF;

    IF v_caster_ap < v_effective_cost THEN -- Validate that the caster has sufficient AP.
        RAISE EXCEPTION 'Not enough action points to cast the spell.';
    END IF;

    v_caster_ap := v_caster_ap - v_effective_cost; -- Deduct the appropriate AP from the caster.
    UPDATE "CombatParticipants"
    SET act_action_points = v_caster_ap -- Update the caster's action points in the database.
    WHERE character_id = p_caster_id AND combat_id = v_combat_id;

    SELECT f_change_round_flag(p_caster_id, FALSE); -- Call the function to change the round flag for the caster.

-- ----------------------------------------- Perform the cast -----------------------------------------
    v_dice_roll := FLOOR(RANDOM() * 20) + 1; -- Simulate a d20 roll (random number between 1 and 20)
    v_spell_effect := f_spell_effect(p_spell_id, p_caster_id, v_dice_roll); -- Perform a d20 roll and add the relevant attribute bonus.
-- ----------------------------------------- Healing -----------------------------------------
    IF v_spell_type = 'healing' THEN
        v_max_health := f_attribute_value(
            p_target_id, 
            (SELECT attr.id
            FROM "Attributes" AS attr
            WHERE attr.name = 'Health')
        );

        IF (v_target_health + v_spell_effect) > v_max_health THEN -- If the target's health exceeds max health, set it to max health.
            v_spell_effect := v_max_health - v_target_health; -- Calculate the effective healing amount.
            v_target_health := v_max_health; -- Set the target's health to max health.
        ELSE
            v_spell_effect := v_spell_effect; -- No adjustment needed.
            v_target_health := v_target_health + v_spell_effect; -- Heal the target.
        END IF;

        UPDATE "CombatParticipants"
        SET act_health = v_target_health
        WHERE combat_id = v_combat_id AND character_id = p_target_id;

        INSERT INTO "Actions"
            (round_id, spell_id, action_type, actor_id, target_id, item_id, ap_cost, effect, dice_roll, action_timestamp)
        VALUES (
            (
                SELECT cr.id
                FROM "CombatRounds" AS cr
                WHERE cr.combat_id = v_combat_id AND cr.time_ended IS NULL
            ), p_spell_id, 'cast spell', p_caster_id, p_target_id, NULL, v_effective_cost, v_spell_effect, v_dice_roll, now()
        );

        RETURN;
    END IF;
-- ----------------------------------------- Damage -----------------------------------------
    v_target_armor_class := f_get_armor_class(p_target_id); -- Get the target's armor class.

    IF v_target_armor_class < v_spell_effect THEN -- If hit: calculate damage and update the target's Health.
        v_target_health := v_target_health - (v_spell_effect - v_target_armor_class); -- Calculate the new health.
        
        UPDATE "CombatParticipants"
        SET act_health = GREATEST(v_target_health, 0) -- Ensure health does not go below 0.
        WHERE combat_id = v_combat_id AND character_id = p_target_id;
    END IF;

-- ----------------------------------------- Log the cast -----------------------------------------
    INSERT INTO "Actions" -- Log the spell casting event in the combat log .
        (round_id, spell_id, action_type, actor_id, target_id, item_id, ap_cost, effect, dice_roll, action_timestamp)
    VALUES (
    (
        SELECT cr.id
        FROM "CombatRounds" AS cr
        WHERE cr.combat_id = v_combat_id AND cr.time_ended IS NULL
    ), p_spell_id, 'cast spell', p_caster_id, p_target_id, NULL, v_effective_cost, GREATEST(v_spell_effect - v_target_armor_class, 0), v_dice_roll, now()
    );
-- ----------------------------------------- Handle death during cast -----------------------------------------
    IF v_target_health <= 0 THEN -- If the target's health is 0 or less, log the death event.
        INSERT INTO "Actions" -- Log the death event in the combat log .
            (round_id, spell_id, action_type, actor_id, target_id, item_id, ap_cost, effect, dice_roll, action_timestamp)
        VALUES (
        (
            SELECT cr.id
            FROM "CombatRounds" AS cr
            WHERE cr.combat_id = v_combat_id AND cr.time_ended IS NULL
        ), NULL, 'death', NULL, p_target_id, NULL, 0, 0, NULL, now()
        );

        UPDATE "Characters"
        SET state = 'Died' -- Update the target's state to died.
        WHERE id = p_target_id;

        SELECT f_change_round_flag(p_target_id, TRUE); -- Call the function to change the round flag for the target.
-- ----------------------------------------- Handle item drop -----------------------------------------
        -- Transfer the target's items from Invetory to the CombatItems table and remove them from the Inventory table.
        FOR r_item IN
            SELECT i.id, i.character_id, i.item_id
            FROM "Inventory" AS i
            WHERE i.character_id = p_target_id
        LOOP
            INSERT INTO "CombatItems" (combat_id, item_id)
            VALUES (
                v_combat_id,
                r_item.item_id
            );

            DELETE FROM "Inventory"
            WHERE id = r_item.id AND character_id = p_target_id;

            INSERT INTO "Actions" -- Log the item drop event in the combat log .
                (round_id, spell_id, action_type, actor_id, target_id, item_id, ap_cost, effect, dice_roll, action_timestamp)
            VALUES (
            (
                SELECT cr.id
                FROM "CombatRounds" AS cr
                WHERE cr.combat_id = v_combat_id AND cr.time_ended IS NULL
            ), NULL, 'item drop', p_target_id, NULL, r_item.item_id, 0, 0, NULL, now()
            );
        END LOOP;
    END IF;

    RETURN;
END ;
$$ LANGUAGE plpgsql ;

-- ----------------------------------------------------- sp_enter_combat.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION sp_enter_combat (
    p_combat_id BIGINT,
    p_character_id BIGINT
) RETURNS VOID AS $$
BEGIN
-- ------------------------------------------------------ Validation of entry conditions ------------------------------------------------------
-- Check if the character exists and retrieve their state
-- If the character does not exist, raise an exception 
-- Check if the character is in a valid state to enter combat (e.g., not dead, not in combat)
-- If the character is dead or already in combat, raise an exception
-- Check if the character already in combat
-- ------------------------------------------------------ Validate the combat session ------------------------------------------------------
-- Check if the combat exists
-- Check if the combat is still ongoing
-- If the combat is not ongoing, raise an exception
-- If the combat does not exist, raise an exception
-- ------------------------------------------------------ Process participant data & state ------------------------------------------------------
-- Create a new combat participant record for the character
-- Initialize the character's action points (AP), health points (HP), and starting round
-- Log the character's entry into combat

-- ------------------------------------------------------ Validation of entry conditions ------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM "Characters" WHERE id = p_character_id) THEN -- Check if the character exists
    RAISE EXCEPTION 'Character with ID % does not exist', p_character_id;
END IF;

IF (SELECT c.state FROM "Characters" AS c WHERE c.id = p_character_id) <> 'Resting' THEN -- Check if the character is in a valid state to enter combat
    RAISE EXCEPTION 'Character with ID % is not in a valid state to enter combat', p_character_id;
END IF;

IF EXISTS (
    SELECT 1 
    FROM "CombatParticipants" AS cp 
    JOIN "Combats" AS c ON cp.combat_id = c.id 
    WHERE cp.character_id = p_character_id AND c.time_ended IS NULL
) THEN -- Check if the character is already in combat
    RAISE EXCEPTION 'Character with ID % is already in combat', p_character_id;
END IF;

-- ------------------------------------------------------ Validate the combat session ------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM "Combats" WHERE id = p_combat_id) THEN -- Check if the combat exists
    RAISE EXCEPTION 'Combat with ID % does not exist', p_combat_id;
END IF;

IF NOT EXISTS (SELECT 1 FROM "Combats" WHERE id = p_combat_id AND time_ended IS NOT NULL) THEN -- Check if the combat is still ongoing
    RAISE EXCEPTION 'Combat with ID % has already ended', p_combat_id;
END IF;

-- ------------------------------------------------------ Process participant data & state ------------------------------------------------------
INSERT INTO "CombatParticipants" (character_id, combat_id, act_health, act_action_points) 
    VALUES (
        p_character_id, 
        p_combat_id, 
        f_attribute_value(p_character_id, (SELECT id FROM "Attributes" WHERE name = 'Health')), -- Initialize the character's action points (AP), health points (HP), and starting round
        f_max_ap(P_character_id)
    ); -- Create a new combat participant record for the character

    
    UPDATE "Characters"
    SET state = 'In combat'
    WHERE id = p_character_id;

INSERT INTO "Actions" (round_id, action_type, actor_id, ap_cost, effect, action_timestamp) 
    VALUES (
        (
            SELECT id 
            FROM "CombatRounds" 
            WHERE combat_id = p_combat_id AND time_ended IS NULL
        ),
        'join', 
        p_character_id, 
        0, 0, NOW()
    ); -- Log the action in the combat log (Actions)

    RETURN;

-- Insert a new record associating the character with the combat session .
-- Initialize the character ’ s AP and starting round .
-- Log the character ’ s entry into combat .
END ;
$$ LANGUAGE plpgsql ;

-- ----------------------------------------------------- sp_loot_item.sql -----------------------------------------------------
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

-- ----------------------------------------------------- sp_reset_round.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION sp_reset_round (
    p_combat_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_round_id BIGINT; -- Variable to hold the round ID
    v_round_number INTEGER; -- Variable to hold the round number
    rec RECORD; -- Record variable to hold the result of the query
    v_participant_count INTEGER; -- Variable to hold the count of participants in the combat
BEGIN
    -- Check if the combat ID is valid
    IF NOT EXISTS (SELECT 1 FROM "Combats" WHERE id = p_combat_id AND time_ended IS NULL) THEN
        RAISE EXCEPTION 'Combat with ID % does not exist or has already ended', p_combat_id;
    END IF;

    -- Check if the combat is active
    IF NOT EXISTS (
        SELECT 1 
        FROM "CombatRounds" WHERE combat_id = p_combat_id AND time_ended IS NULL) THEN
        RAISE EXCEPTION 'No active round found for combat ID %', p_combat_id;
    END IF;

    v_participant_count := (
        SELECT COUNT(*) 
        FROM "CombatParticipants" 
        WHERE combat_id = p_combat_id AND act_health > 0 -- Only include participants with health > 0
    );

    IF v_participant_count = 0 THEN -- Check if there are any active participants in the combat
        RAISE EXCEPTION 'No active participants found for combat ID %', p_combat_id;
    END IF;

    IF (SELECT COUNT(*) FROM "CombatParticipants" WHERE combat_id = p_combat_id AND round_passed = FALSE) <> 0 THEN
        RAISE EXCEPTION 'Not all participants have passed the round for combat ID %', p_combat_id;
    END IF;

    FOR rec IN -- Loop through all characters in the combat session and reset their action points
        SELECT character_id
        FROM "CombatParticipants" 
        WHERE combat_id = p_combat_id AND act_health > 0 -- Only include participants with health > 0
    LOOP
        UPDATE "CombatParticipants"
        SET act_action_points = f_max_ap(rec.character_id), round_passed = FALSE
        WHERE character_id = rec.character_id AND combat_id = p_combat_id; -- Only update the specified combat participant
    END LOOP;

    -- Get the current round ID and round number
    SELECT id, round_number INTO v_round_id, v_round_number
    FROM "CombatRounds" 
    WHERE combat_id = p_combat_id AND time_ended IS NULL;

    -- End the current round
    UPDATE "CombatRounds"
    SET time_ended = NOW()
    WHERE id = v_round_id;

    -- Log the round end action
    INSERT INTO "Actions" (round_id, action_type, ap_cost, effect, action_timestamp)
        VALUES (v_round_id, 'round end', 0, 0, NOW()); 

    v_round_number := v_round_number + 1; -- Increment the round number

    -- Start a new round for the combat
    INSERT INTO "CombatRounds" (combat_id, time_started, round_number)
        VALUES (p_combat_id, NOW(), (v_round_number)); 

    v_round_id := (SELECT id FROM "CombatRounds" WHERE combat_id = p_combat_id AND time_ended IS NULL); -- Get the new round ID

    -- Log the round start action
    INSERT INTO "Actions" (round_id, action_type, ap_cost, effect, action_timestamp)
        VALUES (v_round_id, 'round start', 0, 0, NOW());
    UPDATE "Combats"
    SET act_round_number = v_round_number
    WHERE id = p_combat_id;

    RETURN;
END ;
$$ LANGUAGE plpgsql ;

-- ----------------------------------------------------- sp_rest_character.sql -----------------------------------------------------
CREATE OR REPLACE FUNCTION sp_rest_character(
    p_character_id BIGINT
) RETURNS VOID AS $$
DECLARE
    v_state character_state_enum;
    v_class_id BIGINT;
    v_combat_id BIGINT;
    v_act_round_id BIGINT;
BEGIN
-- ------------------------------------------------------ Validation of entry conditions ------------------------------------------------------
-- Check if the character exists
-- Retrieve the character's state and class ID
-- Check if the character is in a valid state to rest (e.g., not dead)
-- If the character is dead, raise an exception
-- ------------------------------------------------------ Process combat data & state ------------------------------------------------------
-- Check if the combat is still ongoing - whether is the character single living participant
-- If the character is not the only participant alive, raise an exception
-- ------------------------------------------------------ End combat ------------------------------------------------------ 
-- Update the character's state to 'resting'
-- log the action in the combat log
-- End the actuall round of the combat - update time_ended
-- log the action in the combat log
-- End the combat - update time_ended
-- log the action in the combat log

-- ------------------------------------------------------ Validation of entry conditions ------------------------------------------------------
    IF (SELECT COUNT(*) FROM "Characters" WHERE id = p_character_id) = 0 THEN -- Check if the character exists
        RAISE EXCEPTION 'Character with ID % does not exist', p_character_id;
    END IF;

    SELECT state, class_id INTO v_state, v_class_id -- Retrieve the character's state and class ID
    FROM "Characters"
    WHERE id = p_character_id;

    IF v_state = 'Died' THEN -- Check if the character is in a valid state to rest (e.g., not dead)
        RAISE EXCEPTION 'Character with ID % is dead and cannot rest', p_character_id;
    END IF;

-- ------------------------------------------------------ Process combat data & state ------------------------------------------------------
    -- Check if the combat is still ongoing - whether is the character single living participant
    SELECT 
        com.id INTO v_combat_id
    FROM "CombatParticipants" AS cp
    JOIN "Combats" AS com ON cp.combat_id = com.id
    WHERE cp.character_id = p_character_id AND com.time_ended IS NULL;

    IF (
        SELECT COUNT(*)
        FROM v_combat_state
        WHERE combat_id = v_combat_id 
            AND character_id <> p_character_id 
            AND character_state = 'In combat'
    ) != 0 THEN 
        RAISE EXCEPTION 'Character with ID % is not the only participant alive in combat %', p_character_id, v_combat_id; 
    END IF; -- If the character is not the only participant alive, raise an exception 

-- ------------------------------------------------------ End combat ------------------------------------------------------
    
    -- log the action in the combat log
    v_act_round_id := (SELECT id FROM "CombatRounds" WHERE combat_id = v_combat_id AND time_ended IS NULL); -- Get the current round ID

    IF v_act_round_id IS NULL THEN
        RAISE EXCEPTION 'No active round found for combat %', v_combat_id;
    END IF;
    
    -- Update the character's state to 'resting'
    UPDATE "Characters"
    SET state = 'Resting'
    WHERE id = p_character_id; 

    INSERT INTO "Actions" (round_id, actor_id, action_type, ap_cost, effect, action_timestamp)
    VALUES (
        v_act_round_id, p_character_id, 'rest', 0, 0, NOW()
    );
    
    -- End the actuall round of the combat - update time_ended
    UPDATE "CombatRounds"
    SET time_ended = NOW()
    WHERE id = v_act_round_id; 
    
    -- log the action in the combat log
    INSERT INTO "Actions" (round_id, action_type, ap_cost, effect, action_timestamp)
    VALUES (
        v_act_round_id,
        'round end',
        0,
        0,
        NOW()
    );

    -- End the combat - update time_ended
    UPDATE "Combats"
    SET time_ended = NOW()
    WHERE id = v_combat_id; 
    
    -- log the action in the combat log
    INSERT INTO "Actions" (round_id, action_type, ap_cost, effect, action_timestamp)
    VALUES (
        v_act_round_id,
        'combat end',
        0,
        0,
        NOW()
    );

    RETURN;
END ;
$$ LANGUAGE plpgsql ;

SELECT sp_cast_spell(1, 2, 1); -- Example call to the sp_cast_spell function