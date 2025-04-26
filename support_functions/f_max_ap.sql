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

SELECT f_max_ap(1) AS "Max Action Points"; -- Example call to the function 