-- Get the caster's action points and combat ID
-- Validate that the caster is in combat and has action points
-- Get the target's participant details
-- Get the spell type
-- Calculate the effective cost of the spell
-- Validate that the caster has sufficient AP.
-- Deduct the appropriate AP from the caster.
-- Update the caster's action points in the database.
-- Perform a d20 roll and add the relevant attribute bonus.

CREATE OR REPLACE FUNCTION sp_cast_spell (
    p_caster_id INTEGER ,
    p_target_id INTEGER ,
    p_spell_id INTEGER
) RETURNS VOID AS $$
DECLARE
    v_combat_id BIGINT; -- Variable to hold the combat ID

    v_effective_cost NUMERIC; -- Variable to hold the effective spell cost
    v_new_action_points NUMERIC; -- Variable to hold the new action points after casting the spell

    v_spell_type VARCHAR; -- Variable to hold the type of spell (e.g., damage, healing)
    v_spell_effect NUMERIC; -- Variable to hold the spell effect value
    v_max_health INTEGER; -- Variable to hold the maximum health of the target

    v_caster_participant_id BIGINT; -- Record to hold the caster's participant details
    v_caster_ap NUMERIC; -- Variable to hold the caster's action points

    v_target_participant_id BIGINT; -- Record to hold the target's participant details
    v_target_health NUMERIC; -- Variable to hold the target's health after applying the spell effect
    v_target_armor_class NUMERIC; -- Variable to hold the target's armor class

    v_dice_roll INTEGER;

    r_item RECORD; -- Record to hold the item details (if any)
BEGIN
-- ----------------------------------------- Gather data ----------------------------------------- 
    SELECT cp.id, cp.act_action_points, cp.combat_id -- Get the caster's action points and combat ID
        INTO v_caster_participant_id, v_caster_ap, v_combat_id
    FROM "CombatParticipants" AS cp
        JOIN "Combats" AS c ON cp.combat_id = c.id
    WHERE c.time_ended IS NULL AND cp.character_id = p_caster_id;

    IF v_caster_ap IS NULL THEN -- Validate that the caster is in combat and has action points
        RAISE EXCEPTION 'Caster not found or not in combat.';
    END IF;

    SELECT cp.id, cp.act_health -- Get the target's participant details
        INTO v_target_participant_id, v_target_health
    FROM "CombatParticipants" AS cp
        JOIN "Combats" AS c ON cp.combat_id = c.id
    WHERE c.time_ended IS NULL AND cp.character_id = p_target_id;

    IF (SELECT COALESCE(cp.combat_id, -1) 
        FROM "CombatParticipants" AS cp 
        WHERE cp.character_id = p_target_id) <> v_combat_id THEN -- Validate that the target is in the same combat
        RAISE EXCEPTION 'Target not found or not in combat.';
    END IF;

    IF v_target_health IS NULL THEN -- Validate that the target is in combat and has health
        RAISE EXCEPTION 'Target not found or not in combat.';
    END IF;

    IF v_target_health <= 0 THEN -- Validate that the target is alive
        RAISE EXCEPTION 'Target is dead and cannot be affected by the spell.';
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
    WHERE id = v_caster_participant_id AND combat_id = v_combat_id;

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
END ;
$$ LANGUAGE plpgsql ;

SELECT sp_cast_spell(1, 5, 1);