CREATE OR REPLACE FUNCTION f_attribute_value(
    p_character_id BIGINT,
    p_attribute_id BIGINT
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
    SELECT class_attr.modifier 
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

    RETURN (base_value * class_modifier) + item_modifier;
END;
$$ LANGUAGE plpgsql ;

SELECT f_attribute_value(1, 1) AS result; -- Example call to the function

CREATE OR REPLACE FUNCTION f_effective_spell_cost(
    p_spell_id INTEGER,
    p_caster_id INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    base_cost INT;
    category_id BIGINT;
    base_effect INT;
    effect_type effect_type_enum;

    intelligence INT;
    spell_attributes ARRAY;
BEGIN
    SELECT 
        sp.category_id, sp.base_effect, sp.effect_type 
    INTO   
        category_id, base_effect, effect_type
    FROM Spells AS sp
    WHERE sp.id = p_spell_id;

    -- find the spell base cost
    SELECT sc.base_cost INTO base_cost
    FROM Spells s
    JOIN SpellCategories sc ON s.category_id = sc.id
    WHERE s.id = p_spell_id;

    SELECT ca.base_value INTO intelligence
    FROM CharacterAttributes ca
    JOIN Attributes a ON ca.atribute_id = a.id
    WHERE ca.character_id = p_caster_id AND LOWER(a.name) = 'intelligence';

    RETURN base_cost * (1 - intelligence / 100.0);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sp_cast_spell (
    p_caster_id INTEGER ,
    p_target_id INTEGER ,
    p_spell_id INTEGER
) RETURNS VOID AS $$
BEGIN
-- Validate that the caster has sufficient AP .
-- Calculate the effective spell cost based on character attributes .
-- Deduct the appropriate AP from the caster .
-- Perform a d20 roll and add the relevant attribute bonus .
-- Compare roll result with the target ’ s Armor Class .
-- If hit : calculate damage and update the target ’ s Health .
-- Log the spell casting event in the combat log .
END ;
$$ LANGUAGE plpgsql ;