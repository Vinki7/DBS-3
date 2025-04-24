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
        v_armor_class_value + get_total_item_bonus(p_character_id, v_armor_id), -- Add item bonus to the armor class
    2); -- Round the value to 2 decimal places
    
    RETURN v_armor_class_value; -- Return the calculated armor class value
END;
$$ LANGUAGE plpgsql;

SELECT f_get_armor_class(2) AS "Armor Class"; -- Example call to the function