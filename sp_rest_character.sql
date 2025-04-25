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
    -- Update the character's state to 'resting'
    UPDATE "Characters"
    SET state = 'Resting'
    WHERE id = p_character_id; 
    
    -- log the action in the combat log
    v_act_round_id := (SELECT id FROM "CombatRounds" WHERE combat_id = v_combat_id AND time_ended IS NULL); -- Get the current round ID

    IF v_act_round_id IS NULL THEN
        RAISE EXCEPTION 'No active round found for combat %', v_combat_id;
    END IF;

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

SELECT sp_rest_character(1); -- Test the function with a character ID

-- Debugging the function
SELECT 
    com.id
FROM "CombatParticipants" AS cp
JOIN "Combats" AS com ON cp.combat_id = com.id
WHERE cp.character_id = 1 AND com.time_ended IS NULL;

INSERT INTO "Actions" (round_id, action_type, ap_cost, effect, action_timestamp)
VALUES (
    (SELECT id FROM "CombatRounds" WHERE combat_id = 1 AND time_ended IS NULL),
    'round end',
    0,
    0,
    NOW()
);

UPDATE "Characters"
SET state = 'Resting'
WHERE id = 1; -- log the action in the combat log

SELECT * FROM v_combat_state;