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

SELECT f_max_inventory_weight(1) AS "Max Inventory Weight"; -- Example call to the function