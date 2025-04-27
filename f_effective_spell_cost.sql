-- Active: 1740996226560@@localhost@5433@dnd_db
CREATE OR REPLACE FUNCTION f_effective_spell_cost(
    p_spell_id BIGINT,
    p_caster_id BIGINT
) RETURNS NUMERIC AS $$
DECLARE
    v_effective_cost NUMERIC; -- Variable to hold the effective spell cost
BEGIN
    WITH spell_validation AS (
        -- Validate that the spell exists and the caster is valid
        SELECT COUNT(*) AS spell_exists
        FROM "CharacterSpells" AS assigned_s
        WHERE assigned_s.spell_id = p_spell_id AND assigned_s.character_id = p_caster_id
    ),
    base_cost_query AS ( -- Get the base cost of the spell from category
        SELECT cat.base_cost
        FROM "SpellCategories" AS cat
        JOIN "Spells" AS sp ON cat.id = sp.category_id
        WHERE sp.id = p_spell_id
    ),
    attribute_values AS ( -- Get the total attribute value for the caster
        SELECT COALESCE(SUM(f_attribute_value(p_caster_id, sp_attr.attribute_id)), 0) AS total_value
        FROM "SpellAttributes" AS sp_attr
        WHERE sp_attr.spell_id = p_spell_id
    )
    SELECT 
        CASE
            WHEN spell_validation.spell_exists = 0
                THEN NULL
            ELSE ROUND(
                base_cost_query.base_cost * (1 - LEAST(80, attribute_values.total_value) / 100),
                2
            ) INTO v_effective_cost -- Calculate the effective cost using the formula
        END
    FROM base_cost_query, attribute_values, spell_validation
    WHERE base_cost_query.base_cost IS NOT NULL AND attribute_values.total_value IS NOT NULL;

    RETURN v_effective_cost;

END;
$$ LANGUAGE plpgsql;

SELECT f_effective_spell_cost(2, 1) AS "Effective Spell Cost"; -- Example call to the function