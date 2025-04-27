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

IF NOT EXISTS (SELECT 1 FROM "Combats" WHERE id = p_combat_id AND time_ended IS NULL) THEN -- Check if the combat is still ongoing
    RAISE EXCEPTION 'Combat with ID % has already ended', p_combat_id;
END IF;

-- ------------------------------------------------------ Process participant data & state ------------------------------------------------------
INSERT INTO "CombatParticipants" (character_id, combat_id, act_health, act_action_points, round_passed) 
    VALUES (
        p_character_id, 
        p_combat_id, 
        f_attribute_value(p_character_id, (SELECT id FROM "Attributes" WHERE name = 'Health')), -- Initialize the character's action points (AP), health points (HP), and starting round
        f_max_ap(P_character_id),
        FALSE
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

SELECT sp_enter_combat(2, 4); -- Example call to the function