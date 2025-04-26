-- -----------------------------
-- Indexes for Foreign Key Columns
-- -----------------------------
CREATE INDEX idx_characters_class_id ON "Characters" ("class_id");

CREATE INDEX idx_combatparticipants_character_id ON "CombatParticipants" ("character_id");
CREATE INDEX idx_combatparticipants_combat_id ON "CombatParticipants" ("combat_id");

CREATE INDEX idx_inventory_character_id ON "Inventory" ("character_id");
CREATE INDEX idx_inventory_item_id ON "Inventory" ("item_id");

CREATE INDEX idx_combatitems_combat_id ON "CombatItems" ("combat_id");
CREATE INDEX idx_combatitems_item_id ON "CombatItems" ("item_id");

CREATE INDEX idx_classattributes_class_id ON "ClassAttributes" ("class_id");
CREATE INDEX idx_classattributes_attribute_id ON "ClassAttributes" ("attribute_id");

CREATE INDEX idx_characterattributes_character_id ON "CharacterAttributes" ("character_id");
CREATE INDEX idx_characterattributes_attribute_id ON "CharacterAttributes" ("attribute_id");

CREATE INDEX idx_spellattributes_spell_id ON "SpellAttributes" ("spell_id");
CREATE INDEX idx_spellattributes_attribute_id ON "SpellAttributes" ("attribute_id");

CREATE INDEX idx_itemattributes_item_id ON "ItemAttributes" ("item_id");
CREATE INDEX idx_itemattributes_attribute_id ON "ItemAttributes" ("attribute_id");

CREATE INDEX idx_spells_category_id ON "Spells" ("category_id");

CREATE INDEX idx_combatrounds_combat_id ON "CombatRounds" ("combat_id");

-- -----------------------------
-- Special Purpose Indexes
-- -----------------------------

-- For fast fetching all actions in a round, ordered by time
CREATE INDEX idx_actions_round_id_timestamp ON "Actions" ("round_id", "action_timestamp");

-- For filtering by action type (e.g., cast spell, death)
CREATE INDEX idx_actions_action_type ON "Actions" ("action_type");
