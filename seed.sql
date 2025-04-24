DELETE FROM "Attributes";
INSERT INTO "Attributes" (id, name, description) VALUES
(1, 'Armor', 'Armor is a measure of how well you can defend against attacks.'),
(2, 'Intelligence', 'Intelligence is a measure of how well you can think and reason.'),
(3, 'Dexterity', 'Dexterity is a measure of hand-eye coordination and agility.');

-- ---------------------------- Spell Related Tables ----------------------------
DELETE FROM "SpellCategories";
INSERT INTO "SpellCategories" (id, name, base_cost, description) VALUES
(1, 'Magic Bolt', 20, 'Magic Bolt is a basic spell that deals damage to a single target.'),
(2, 'Healing', 15, 'Healing spells restore health to the target.');

DELETE FROM "Spells";
INSERT INTO "Spells" (id, name, category_id, base_effect, effect_type, description) VALUES
-- id: 1
-- name: Fireball
-- category_id: 1 (Magic Bolt)
-- base_effect: 30 (damage)
-- effect_type: damage
(1, 'Fireball', 1, 30, 'damage', 'Fireball is a powerful spell that deals fire damage to all enemies in a radius.'),
(2, 'Heal', 2, 20, 'healing', 'Heal is a spell that restores health to a single target.');

DELETE FROM "SpellAttributes";
INSERT INTO "SpellAttributes" (id, spell_id, attribute_id) VALUES
-- id: 1
-- spell_id: 1 (Fireball)
-- attribute_id: 1 (Intelligence)
(1, 1, 1),  -- Fireball depends on Intelligence
(2, 2, 2),  -- Heal depends on Dexterity
(3, 1, 2),  -- Fireball also depends on Dexterity
(4, 2, 1);  -- Heal depends on Intelligence

-- ---------------------------- Class Related Tables ----------------------------
DELETE FROM "Classes";
INSERT INTO "Classes" (id, name, ap_modifier, ac_modifier, inventory_modifier) VALUES
(1, 'Wizard', 1.0, 0.9, 1.0),
(2, 'Rogue', 1.0, 1.0, 1.0);

DELETE FROM "ClassAttributes";
INSERT INTO "ClassAttributes" (id, class_id, attribute_id, modifier) VALUES
(1, 1, 1, 1.1),  -- Intelligence modifier for Wizard
(2, 1, 2, 1.0);  -- Dexterity

-- ---------------------------- Character Related Tables ----------------------------
DELETE FROM "Characters";
INSERT INTO "Characters" (id, state, class_id, experience_points) VALUES
(1, 'In combat', 1, 0), -- Wizzard
(2, 'In combat', 2, 0);  -- Rogue

DELETE FROM "CharacterAttributes";
INSERT INTO "CharacterAttributes" (id, character_id, attribute_id, base_value) VALUES
(1, 1, 2, 10),  -- INTELLIGENCE
(2, 1, 3, 5);   -- DEXTERITY

DELETE FROM "CharacterSpells";
INSERT INTO "CharacterSpells" (character_id, spell_id) VALUES
(1, 1),  -- Character 1 has Fireball
(1, 2);  -- Character 1 has Heal

-- ---------------------------- Combat Related Tables ----------------------------
DELETE FROM "Combats";
INSERT INTO "Combats" (id, act_round_number, time_started, time_ended) VALUES
(1, 1, now(), NULL);

DELETE FROM "CombatRounds";
INSERT INTO "CombatRounds" (id, combat_id, time_started, time_ended, round_number) VALUES
(1, 1, now(), NULL, 1);

-- DELETE FROM "Actions";
-- INSERT INTO "Actions" (id, round_id, character_id, action_type, action_value) VALUES
-- (1, 1, 1, 'Attack', 30),  -- Character 1 attacks with Fireball
-- (2, 1, 1, 'Heal', 20);    -- Character 1 heals

DELETE FROM "CombatParticipants";
INSERT INTO "CombatParticipants" (id, character_id, combat_id, act_health, act_action_points) VALUES
(1, 1, 1, 100, 10), -- Character 1 in combat with full health and action points
(2, 2, 1, 100, 10); -- Character 2 in combat with full health and action points 
-- ---------------------------- Item Related Tables ----------------------------
DELETE FROM "Items";
INSERT INTO "Items" (id, name, description, weight) VALUES 
(1, 'Ring of Wisdom', 'A ring that increases intelligence.', 0.1),
(2, 'Cloak of Agility', 'A cloak that increases dexterity.', 0.5),
(3, 'Necklace of Necromancy', 'A necklace that increases intelligence.', 0.2);

-- Inventory
DELETE FROM "Inventory";
INSERT INTO "Inventory" (id, character_id, item_id) VALUES
(1, 1, 1),
(2, 1, 2), 
(3, 1, 3); -- Character 1 has all items

-- ItemAttributeModifier
DELETE FROM "ItemAttributes";
INSERT INTO "ItemAttributes" (id, item_id, attribute_id, modifier) VALUES
-- Ring of Wisdom
(1, 1, 1, 5), -- +1 Armor
(2, 1, 2, 5), -- +5 Intelligence
-- Cloak of Agility
(3, 2, 1, 10), -- +10 Armor
(4, 2, 3, 3), -- +3 Dexterity
-- Necklace of Necromancy
(5, 3, 1, 3), -- +3 Armor
(6, 3, 2, 10); -- +10 Intelligence
