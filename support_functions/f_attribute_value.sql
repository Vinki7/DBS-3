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

SELECT f_attribute_value(2, 4) AS "Effective attribute value"; -- Example call to the function