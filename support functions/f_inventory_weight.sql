CREATE OR REPLACE FUNCTION f_inventory_weight(
    p_character_id BIGINT -- Character ID
) RETURNS NUMERIC AS $$
BEGIN
    -- Check if the character exists
    IF NOT EXISTS (SELECT 1 FROM "Characters" WHERE id = p_character_id) THEN
        RAISE EXCEPTION 'Character with ID % does not exist', p_character_id;
    END IF;

    -- Calculate the total weight of items in the character's inventory
    RETURN (SELECT COALESCE(SUM(i.weight), 0) -- Default to 0 if no items found
    FROM "Inventory" AS inv
    JOIN "Items" AS i ON inv.item_id = i.id
    WHERE inv.character_id = p_character_id);
END;
$$ LANGUAGE plpgsql ;

SELECT f_inventory_weight(1) AS "Inventory Weight"; -- Example call to the function