CREATE OR REPLACE FUNCTION sp_reset_round (
    p_combat_id BIGINT
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

    IF v_participant_count = 1 THEN -- Check if the character is the only participant alive
        SELECT sp_rest_character(character_id);
        RETURN;
    END IF;

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

SELECT sp_reset_round(1); -- Test the function with a combat ID

SELECT COUNT(*) FROM "CombatParticipants" WHERE combat_id = 1 AND round_passed = FALSE;
