DELETE FROM "Attributes";
INSERT INTO "Attributes" (name, description) VALUES
('Armor', 'Armor is a measure of how well you can defend against attacks.'),
('Health', 'Health is a measure of how much damage you can take before dying.'),
('Intelligence', 'Intelligence is a measure of how well you can think and reason.'),
('Dexterity', 'Dexterity is a measure of hand-eye coordination and agility.'),    
('Strength', 'Strength is a measure of how strong you are.'),
('Constitution', 'Constitution is a measure of how tough you are.');

-- ---------------------------- Spell Related Tables ----------------------------
DELETE FROM "SpellCategories";
INSERT INTO "SpellCategories" (name, base_cost, description) VALUES
-- ID 1
('Fire Magic', 20, 'Spells that harness the power of fire to deal burning damage.'),
-- ID 2
('Electric Magic', 25, 'Spells that unleash electric energy to shock enemies.'),
-- ID 3
('Frost Magic', 20, 'Spells that deal cold-based damage to slow or harm enemies.'),
-- ID 4
('Arcane Magic', 25, 'Spells based on pure magical force or arcane energy.'),
-- ID 5
('Healing Magic', 15, 'Spells that restore health and vitality.'),
-- ID 6
('Nature Magic', 20, 'Spells that channel natural energy for healing and rejuvenation.'),
-- ID 7
('Shadow Magic', 25, 'Spells that deal dark or shadow damage.'),
-- ID 8
('Holy Magic', 20, 'Spells of light used for healing and support.'),
-- ID 9
('Physical Techniques', 20, 'Weapon-based or physical attack spells.'),
-- ID 10
('Earth Magic', 30, 'Spells that manipulate the earth to damage or disrupt.');


DELETE FROM "Spells";
INSERT INTO "Spells" (name, category_id, base_effect, effect_type, description) VALUES
-- Fire Magic Spells
('Fireball', 1, 30, 'damage', 'Fireball is a powerful spell that deals fire damage to all enemies in a radius.'), -- 1
('Blazing Strike', 1, 45, 'damage', 'Blazing Strike is a spell that deals fire damage to a single target with a burning effect.'), -- 2
-- Electric Magic Spells
('Lightning Strike', 2, 40, 'damage', 'Lightning Strike is a spell that deals electric damage to a single target.'), -- 3
('Thunder Clap', 2, 35, 'damage', 'Thunder Clap is a spell that deals electric damage to all enemies in a small radius.'), -- 4
-- Frost Magic Spells
('Ice Shard', 3, 25, 'damage', 'Ice Shard is a spell that deals cold damage to a single target.'), -- 5
-- Arcane Magic Spells
('Arcane Blast', 4, 35, 'damage', 'Arcane Blast is a spell that deals arcane damage to a single target.'), -- 6
-- Healing Magic Spells
('Heal', 5, 20, 'healing', 'Heal is a spell that restores health to a single target.'), -- 7
('Greater Heal', 5, 50, 'healing', 'Greater Heal is a spell that restores a large amount of health to a single target.'), -- 8
('Life Surge', 5, 40, 'healing', 'Life Surge is a spell that instantly restores a large amount of health to a single target.'), -- 9
-- Nature Magic Spells
('Rejuvenation', 6, 30, 'healing', 'Rejuvenation is a spell that restores health.'), -- 10
('Renew', 6, 20, 'healing', 'Renew is a spell that provides a small healing effect.'), -- 11
-- Shadow Magic Spells
('Shadow Burst', 7, 45, 'damage', 'Shadow Burst is a spell that deals shadow damage to an enemy in a small radius.'), -- 12
-- Holy Magic Spells
('Holy Light', 8, 40, 'healing', 'Holy Light is a spell that restores health to an ally in a small radius.'), -- 13
-- Physical Techniques Spells
('Cleave', 9, 50, 'damage', 'Cleave is a spell that deals physical damage to an enemy in a cone.'), -- 14
('Dagger Throw', 9, 20, 'damage', 'Dagger Throw is a spell that deals physical damage to a single target from a distance.'), -- 15
('Piercing Arrow', 9, 25, 'damage', 'Piercing Arrow is a spell that deals physical damage to a single target and ignores armor.'), -- 16
('Crushing Blow', 9, 55, 'damage', 'Crushing Blow is a spell that deals massive physical damage to a single target.'), -- 17
-- Earth Magic Spells
('Earthquake', 10, 60, 'damage', 'Earthquake is a spell that deals massive damage in a large area.'); -- 18

DELETE FROM "SpellAttributes";
INSERT INTO "SpellAttributes" (spell_id, attribute_id) VALUES
-- Fire Magic
(1, 3),  -- Fireball → Intelligence
(1, 4),  -- Fireball → Dexterity
(2, 3),  -- Blazing Strike → Intelligence
(2, 5),  -- Blazing Strike → Strength
-- Electric Magic
(3, 3),  -- Lightning Strike → Intelligence
(4, 3),  -- Thunder Clap → Intelligence
(4, 6),  -- Thunder Clap → Constitution
-- Frost Magic
(5, 3),  -- Ice Shard → Intelligence
(5, 4),  -- Ice Shard → Dexterity
-- Arcane Magic
(6, 3),  -- Arcane Blast → Intelligence
-- Healing Magic
(7, 3),  -- Heal → Intelligence
(7, 2),  -- Heal → Health
(8, 3),  -- Greater Heal → Intelligence
(8, 2),  -- Greater Heal → Health
(9, 3),  -- Life Surge → Intelligence
(9, 6),  -- Life Surge → Constitution
-- Nature Magic
(10, 3), -- Rejuvenation → Intelligence
(10, 2), -- Rejuvenation → Health
(11, 3), -- Renew → Intelligence
(11, 2), -- Renew → Health
-- Shadow Magic
(12, 3), -- Shadow Burst → Intelligence
(12, 6), -- Shadow Burst → Constitution
-- Holy Magic
(13, 3), -- Holy Light → Intelligence
(13, 2), -- Holy Light → Health
-- Physical Techniques
(14, 5), -- Cleave → Strength
(14, 6), -- Cleave → Constitution
(15, 4), -- Dagger Throw → Dexterity
(15, 3), -- Dagger Throw → Intelligence
(16, 4), -- Piercing Arrow → Dexterity
(16, 5), -- Piercing Arrow → Strength
(17, 5), -- Crushing Blow → Strength
(17, 6), -- Crushing Blow → Constitution
-- Earth Magic
(18, 3), -- Earthquake → Intelligence
(18, 5), -- Earthquake → Strength
(18, 6); -- Earthquake → Constitution

-- ---------------------------- Class Related Tables ----------------------------
DELETE FROM "Classes";
INSERT INTO "Classes" (name, ap_modifier, ac_modifier, inventory_modifier) VALUES
('Wizard', 1.0, 0.9, 1.0),
('Rogue', 1.0, 1.1, 1.0),
('Cleric', 0.9, 1.0, 1.2),
('Warrior', 1.1, 1.3, 1.0),
('Necromancer', 1.0, 0.95, 1.1);

DELETE FROM "ClassAttributes";
INSERT INTO "ClassAttributes" (class_id, attribute_id, modifier) VALUES
-- Wizard
(1, 3, 1.2),  -- Intelligence
(1, 4, 1.0),  -- Dexterity
(1, 2, 0.9),  -- Health
-- Rogue
(2, 4, 1.25), -- Dexterity
(2, 3, 1.0),  -- Intelligence
(2, 5, 0.9),  -- Strength
-- Cleric
(3, 3, 1.1),  -- Intelligence
(3, 6, 1.15), -- Constitution
(3, 2, 1.05), -- Health
-- Warrior
(4, 5, 1.3),  -- Strength
(4, 6, 1.2),  -- Constitution
(4, 2, 1.1),  -- Health
(4, 1, 1.1),  -- Armor
-- Necromancer
(5, 3, 1.2),  -- Intelligence
(5, 2, 1.1),  -- Health
(5, 1, 0.9);  -- Armor

-- ---------------------------- Character Related Tables ----------------------------
DELETE FROM "Characters";
INSERT INTO "Characters" (state, class_id, experience_points) VALUES
('In combat', 1, 120),  -- Wizard
('In combat', 2, 80),   -- Rogue
('In combat', 3, 60),   -- Cleric
('Resting', 4, 200),    -- Warrior
('In combat', 5, 150),  -- Necromancer
('In combat', 1, 40),   -- Wizard
('In combat', 2, 30),   -- Rogue
('In combat', 4, 50),   -- Warrior
('In combat', 3, 70),   -- Cleric
('In combat', 5, 100); -- Necromancer


DELETE FROM "CharacterAttributes";
INSERT INTO "CharacterAttributes" (character_id, attribute_id, base_value) VALUES
-- Armor
(1, 1, 5), (2, 1, 8), (3, 1, 6), (4, 1, 15), (5, 1, 7),
(6, 1, 5), (7, 1, 8), (8, 1, 13), (9, 1, 6), (10, 1, 7),
-- Health
(1, 2, 100), (2, 2, 95), (3, 2, 110), (4, 2, 140), (5, 2, 90),
(6, 2, 95), (7, 2, 88), (8, 2, 130), (9, 2, 105), (10, 2, 98),
-- Intelligence
(1, 3, 12), (2, 3, 6), (3, 3, 8), (4, 3, 4), (5, 3, 14),
(6, 3, 11), (7, 3, 7), (8, 3, 5), (9, 3, 9), (10, 3, 13),
-- Dexterity
(1, 4, 7), (2, 4, 13), (3, 4, 9), (4, 4, 6), (5, 4, 10),
(6, 4, 8), (7, 4, 12), (8, 4, 7), (9, 4, 8), (10, 4, 9),
-- Strength
(1, 5, 10), (2, 5, 8), (3, 5, 7), (4, 5, 12), (5, 5, 9),
(6, 5, 11), (7, 5, 10), (8, 5, 8), (9, 5, 7), (10, 5, 6),
-- Constitution
(1, 6, 5), (2, 6, 7), (3, 6, 8), (4, 6, 9), (5, 6, 10),
(6, 6, 11), (7, 6, 12), (8, 6, 13), (9, 6, 14), (10, 6, 15);

DELETE FROM "CharacterSpells";
INSERT INTO "CharacterSpells" (character_id, spell_id) VALUES
-- Character 1 - Wizard (Fireball, Ice Shard, Arcane Blast)
(1, 1), (1, 5), (1, 6),
-- Character 2 - Rogue (Dagger Throw, Piercing Arrow)
(2, 15), (2, 16),
-- Character 3 - Cleric (Heal, Holy Light, Life Surge)
(3, 7), (3, 13), (3, 9),
-- Character 4 - Warrior (Cleave, Crushing Blow, Thunder Clap)
(4, 14), (4, 17), (4, 4),
-- Character 5 - Necromancer (Shadow Burst, Fireball, Rejuvenation)
(5, 12), (5, 1), (5, 10),
-- Character 6 - Wizard (Blazing Strike, Lightning Strike, Arcane Blast)
(6, 2), (6, 3), (6, 6),
-- Character 7 - Rogue (Lightning Strike, Dagger Throw)
(7, 3), (7, 15),
-- Character 8 - Warrior (Cleave, Piercing Arrow, Earthquake)
(8, 14), (8, 16), (8, 18),
-- Character 9 - Cleric (Greater Heal, Renew, Holy Light)
(9, 8), (9, 11), (9, 13),
-- Character 10 - Necromancer (Shadow Burst, Renew, Blazing Strike)
(10, 12), (10, 11), (10, 2);

-- ---------------------------- Combat Related Tables ----------------------------
DELETE FROM "Combats";
INSERT INTO "Combats" (act_round_number, time_started, time_ended) VALUES
(1, now(), NULL),
(1, now(), NULL); -- Combat 1

DELETE FROM "CombatRounds";
INSERT INTO "CombatRounds" (combat_id, time_started, time_ended, round_number) VALUES
(1, now(), NULL, 1),
(2, now(), NULL, 1);

DELETE FROM "CombatParticipants";
INSERT INTO "CombatParticipants" (character_id, combat_id, act_health, act_action_points) VALUES
(1, 1, 100, 50),  -- Wizard
(2, 1, 90, 40),   -- Rogue
(3, 1, 95, 45),   -- Cleric
(5, 1, 100, 55),  -- Necromancer

-- Combat 2 Participants
(6, 2, 80, 40),   -- Wizard
(7, 2, 85, 35),   -- Rogue
(8, 2, 110, 65),  -- Warrior
(9, 2, 100, 50),  -- Cleric
(10, 2, 90, 50);  -- Necromancer
-- ---------------------------- Item Related Tables ----------------------------
DELETE FROM "Items";
INSERT INTO "Items" (name, description, weight) VALUES 
('Ring of Wisdom', 'A ring that increases intelligence.', 0.1),
('Cloak of Agility', 'A cloak that increases dexterity.', 0.5),
('Necklace of Necromancy', 'A necklace that increases intelligence.', 0.2),
('Moon Steel Chest plate', 'A light yet tought chest plate crafted from supperior Moon Steel by Elven Master craftsmith.', 1),
('Staff of the Arcane', 'A magical staff that boosts intelligence and spell power.', 1.2),
('Boots of Swiftness', 'Light boots that increase dexterity and movement speed.', 0.4),
('Shield of Valor', 'A sturdy shield that boosts armor significantly.', 2.0),
('Tome of Undeath', 'A cursed book that increases necromantic power.', 1.5),
('Blessed Robes', 'Robes blessed by the light, increasing constitution and healing effects.', 0.7),
('Blade of Precision', 'A sharp dagger that increases dexterity and attack accuracy.', 1.0),
('Gauntlets of Might', 'Heavy gauntlets that increase strength significantly.', 1.3),
('Pendant of Focus', 'A mystical pendant that improves intelligence and armor.', 0.3),
('Hunter’s Hood', 'Camouflaged hood that increases stealth and dexterity.', 0.6),
('Battle Greaves', 'Steel greaves that improve constitution and armor.', 1.8);

-- Inventory
DELETE FROM "Inventory";
INSERT INTO "Inventory" (character_id, item_id) VALUES 
(1, 1),  -- Ring of Wisdom
(1, 5),  -- Blessed Robes
(6, 8),  -- Pendant of Focus
-- Rogue Characters (2, 7)
(2, 2),  -- Cloak of Agility
(2, 6),  -- Blade of Precision
(7, 9),  -- Hunter’s Hood
-- Cleric Characters (3, 9)
(3, 5),  -- Blessed Robes
(3, 10), -- Battle Greaves
(9, 2),  -- Cloak of Agility
-- Warrior Characters (4, 8)
(4, 4),  -- Moon Steel Chest plate
(4, 7),  -- Gauntlets of Might
(8, 3),  -- Necklace of Necromancy (could be a trophy)
-- Necromancer Characters (5, 10)
(5, 3),  -- Necklace of Necromancy
(5, 4),  -- Moon Steel Chest plate
(10, 4), -- Moon Steel Chest plate
(10, 9); -- Hunter’s Hood

-- ItemAttributeModifier
DELETE FROM "ItemAttributes";
INSERT INTO "ItemAttributes" (item_id, attribute_id, modifier) VALUES
-- Ring of Wisdom
(1, 1, 5), -- +5 Armor
(1, 2, 10), -- +10 Health
(1, 3, 5), -- +5 Intelligence
-- Cloak of Agility
(2, 1, 10), -- +10 Armor
(2, 4, 3), -- +3 Dexterity
-- Necklace of Necromancy
(3, 1, 3), -- +3 Armor
(3, 3, 10), -- +10 Intelligence
-- Moon Steel Chest plate
(4, 1, 20), -- +20 Armor
(4, 4, 10), -- +10 Dexterity
(4, 6, 5),  -- +5 Constitution
-- Staff of the Arcane
(5, 3, 8),  -- +8 Intelligence
-- Boots of Swiftness
(6, 4, 4),  -- +4 Dexterity
-- Shield of Valor
(7, 1, 15), -- +15 Armor
-- Tome of Undeath
(8, 3, 12), -- +12 Intelligence
-- Blessed Robes
(9, 6, 7),  -- +7 Constitution
(9, 2, 5),  -- +5 Health
-- Blade of Precision
(10, 4, 6), -- +6 Dexterity
-- Gauntlets of Might
(11, 5, 10), -- +10 Strength
-- Pendant of Focus
(12, 3, 5),  -- +5 Intelligence
(12, 1, 3),  -- +3 Armor
-- Hunter’s Hood
(13, 4, 4),  -- +4 Dexterity
-- Battle Greaves
(14, 6, 6),  -- +6 Constitution
(14, 1, 10); -- +10 Armor
