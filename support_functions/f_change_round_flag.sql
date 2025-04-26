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

SELECT f_change_round_flag(1, TRUE); -- Test the function with a character ID and pass flag