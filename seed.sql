INSERT INTO "Attributes" (id, name, description) VALUES
(1, 'Intelligence', 'Intelligence is a measure of how well you can think and reason.'),
(2, 'Dexterity', 'Dexterity is a measure of hand-eye coordination and agility.');


INSERT INTO "Classes" (id, name, ap_modifier, ac_modifier, inventory_modifier) VALUES
(1, 'Wizard', 1.0, 1.0, 1.0),
(2, 'Rogue', 1.0, 1.0, 1.0);

INSERT INTO "Characters" (id, state, class_id, experience_points) VALUES
(1, 'Resting', 1, 0);

INSERT INTO "CharacterAttributes" (id, character_id, attribute_id, base_value) VALUES
(1, 1, 1, 15),  -- Intelligence
(2, 1, 2, 10);  -- Dexterity

INSERT INTO "ClassAttributes" (id, class_id, attribute_id, modifier) VALUES
(1, 1, 1, 1.1),  -- Intelligence modifier for Wizard
(2, 1, 2, 1.0);  -- Dexterity

INSERT INTO "SpellCategories" (id, name, base_cost, description) VALUES
(1, 'Magic Bolt', 20, 'Magic Bolt is a basic spell that deals damage to a single target.'),
(2, 'Healing', 15, 'Healing spells restore health to the target.');

INSERT INTO "Spells" (id, name, category_id, base_effect, effect_type, description) VALUES
(1, 'Fireball', 1, 30, 'damage', 'Fireball is a powerful spell that deals fire damage to all enemies in a radius.'),
(2, 'Heal', 2, 20, 'healing', 'Heal is a spell that restores health to a single target.');

INSERT INTO "SpellAttributes" (id, spell_id, attribute_id) VALUES
(1, 1, 1);  -- Fireball depends on Intelligence

-- Item
INSERT INTO "Items" (id, name, description, weight) VALUES 
(1, 'Ring of Wisdom', 'A ring that increases intelligence.', 0.1);

-- Inventory
INSERT INTO "Inventory" (id, character_id, item_id) VALUES
(1, 1, 1);

-- ItemAttributeModifier
INSERT INTO "ItemAttributes" (id, item_id, attribute_id, modifier) VALUES
(1, 1, 1, 5);  -- +5 Intelligence
