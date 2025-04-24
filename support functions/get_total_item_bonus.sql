-- Active: 1740996226560@@localhost@5433@dnd_db
CREATE OR REPLACE FUNCTION get_total_item_bonus(
    p_character_id BIGINT, -- Character ID
    p_attribute_id BIGINT -- Attribute ID
) RETURNS NUMERIC AS $$
DECLARE
    total_bonus NUMERIC DEFAULT 0; -- Variable to hold the total item bonus
BEGIN
    SELECT COALESCE(SUM(i_attr.modifier), 0)
        INTO total_bonus
    FROM "ItemAttributes" AS i_attr
    JOIN "Inventory" AS i 
        ON i.item_id = i_attr.item_id
    WHERE i.character_id = p_character_id AND i_attr.attribute_id = p_attribute_id;

    RETURN total_bonus; -- Return the total item bonus
END;
$$ LANGUAGE plpgsql ;

SELECT get_total_item_bonus(1, 1) AS "Total Item Bonus"; -- Example call to the function