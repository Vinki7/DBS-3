CREATE OR REPLACE FUNCTION f_spell_effect(
    p_spell_id BIGINT,
    p_caster_id BIGINT,
    p_dice_roll INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    spell_exists INT; -- Variable to check if the spell exists
    base_effect INT;
    total_attribute_value NUMERIC DEFAULT 0;
    final_effect NUMERIC;

    rec RECORD; -- Record to hold the attribute values, generic type
BEGIN  
    SELECT COUNT(*) INTO spell_exists
    FROM "CharacterSpells" AS assigned_s
    WHERE assigned_s.spell_id = p_spell_id AND assigned_s.character_id = p_caster_id;

    -- Get the base effect of the spell
    SELECT sp.base_effect
        INTO base_effect
    FROM "Spells" AS sp
    WHERE sp.id = p_spell_id;

    -- Loop through the attributes that affect the spell and sum their values
    FOR rec IN
        SELECT sp_attr.attribute_id -- Get the attribute ID
        FROM "SpellAttributes" AS sp_attr
        WHERE sp_attr.spell_id = p_spell_id -- Get all attributes for the spell
    LOOP
        total_attribute_value := total_attribute_value + f_attribute_value(p_caster_id, rec.attribute_id);
    END LOOP;

    final_effect := base_effect * (1 + (total_attribute_value / (21 - p_dice_roll))); -- Calculate the final effect

    RETURN ROUND(final_effect, 2); -- Return the final effect rounded to 2 decimal places
END;
$$ LANGUAGE plpgsql;

SELECT f_spell_effect(1, 1, 15) AS "Spell Effect"; -- Example call to the function
