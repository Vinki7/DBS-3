-- Active: 1740996226560@@localhost@5433@dnd_db
CREATE DATABASE "dnd_db";
DROP SCHEMA IF EXISTS "public" CASCADE;
CREATE SCHEMA IF NOT EXISTS "public";

-- ----------------------------------------- Sequences -----------------------------------------
CREATE SEQUENCE IF NOT EXISTS combats_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS characters_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS combatparticipants_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS inventory_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS combatitems_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS items_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS classattributes_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS classes_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS characterattributes_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS spellattributes_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS itemattributes_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS attributes_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS spellcategories_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS actions_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS spells_id_seq START 1;
CREATE SEQUENCE IF NOT EXISTS combatrounds_id_seq START 1;

-- ----------------------------------------- Tables -----------------------------------------
DROP TABLE IF EXISTS "Combats";
CREATE TABLE "Combats" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('combats_id_seq'),
  "act_round_number" int NOT NULL,
  "time_started" TIMESTAMP NOT NULL,
  "time_ended" TIMESTAMP,
  PRIMARY KEY ("id")
);

-- ----------------------------------------- Character State Enum -----------------------------------------
DROP TYPE IF EXISTS "character_state_enum";
CREATE TYPE "character_state_enum" AS ENUM (
  'In combat',
  'Resting',
  'Died'
);

DROP TABLE IF EXISTS "Characters";
CREATE TABLE "Characters" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('characters_id_seq'),
  "class_id" bigint NOT NULL,
  "state" "character_state_enum" NOT NULL,
  "experience_points" int NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "CombatParticipants";
CREATE TABLE "CombatParticipants" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('combatparticipants_id_seq'),
  "character_id" bigint NOT NULL,
  "combat_id" bigint NOT NULL,
  "act_health" int NOT NULL,
  "act_action_points" int NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "Inventory";
CREATE TABLE "Inventory" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('inventory_id_seq'),
  "character_id" bigint NOT NULL,
  "item_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "CombatItems";
CREATE TABLE "CombatItems" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('combatitems_id_seq'),
  "combat_id" bigint NOT NULL,
  "item_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "Items";
CREATE TABLE "Items" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('items_id_seq'),
  "name" varchar(100) NOT NULL,
  "description" text NOT NULL,
  "weight" int NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "ClassAttributes";
CREATE TABLE "ClassAttributes" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('classattributes_id_seq'),
  "class_id" bigint NOT NULL,
  "attribute_id" bigint NOT NULL,
  "modifier" DECIMAL(3, 2) NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "Classes";
CREATE TABLE "Classes" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('classes_id_seq'),
  "name" varchar(50) NOT NULL UNIQUE,
  "description" text,
  "ap_modifier" DECIMAL(3, 2) NOT NULL,
  "inventory_modifier" DECIMAL(3, 2) NOT NULL,
  "ac_modifier" DECIMAL(3, 2) NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "CharacterAttributes";
CREATE TABLE "CharacterAttributes" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('characterattributes_id_seq'),
  "character_id" bigint NOT NULL,
  "attribute_id" bigint NOT NULL,
  "base_value" int NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "SpellAttributes";
CREATE TABLE "SpellAttributes" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('spellattributes_id_seq'),
  "spell_id" bigint NOT NULL,
  "attribute_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "ItemAttributes";
CREATE TABLE "ItemAttributes" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('itemattributes_id_seq'),
  "item_id" bigint NOT NULL,
  "attribute_id" bigint NOT NULL,
  "modifier" int NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "Attributes";
CREATE TABLE "Attributes" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('attributes_id_seq'),
  "name" varchar(50) NOT NULL UNIQUE,
  "description" text NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "SpellCategories";
CREATE TABLE "SpellCategories" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('spellcategories_id_seq'),
  "name" varchar(50) NOT NULL UNIQUE,
  "description" text NOT NULL,
  "base_cost" int NOT NULL,
  PRIMARY KEY ("id")
);

-- ----------------------------------------- Action Type Enum -----------------------------------------
DROP TYPE IF EXISTS "action_type_enum";
CREATE TYPE "action_type_enum" AS ENUM (
  'cast spell',
  'collect item',
  'pass round',
  'death',
  'item drop'
);

DROP TABLE IF EXISTS "Actions";
CREATE TABLE "Actions" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('actions_id_seq'),
  "round_id" bigint NOT NULL,
  "spell_id" bigint,
  "action_type" action_type_enum NOT NULL,
  "actor_id" bigint,
  "target_id" bigint,
  "item_id" bigint,
  "ap_cost" int NOT NULL,
  "effect" int NOT NULL,
  "dice_roll" int,
  "action_timestamp" TIMESTAMP,
  PRIMARY KEY ("id")
);

-- ----------------------------------------- Spell Effect Type Enum -----------------------------------------
CREATE TYPE "effect_type_enum" AS ENUM (
  'damage',
  'healing',
  'vamp'
);

DROP TABLE IF EXISTS "Spells";
CREATE TABLE "Spells" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('spells_id_seq'),
  "name" varchar(100) NOT NULL UNIQUE,
  "description" text NOT NULL,
  "category_id" bigint NOT NULL,
  "base_effect" int NOT NULL,
  "effect_type" effect_type_enum NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "CharacterSpells";
CREATE TABLE "CharacterSpells" (
  "character_id" bigint NOT NULL,
  "spell_id" bigint NOT NULL,
  PRIMARY KEY ("character_id", "spell_id") -- Composite primary key
);

DROP TABLE IF EXISTS "CombatRounds";
CREATE TABLE "CombatRounds" (
  "id" bigint NOT NULL UNIQUE DEFAULT nextval('combatrounds_id_seq'),
  "combat_id" bigint NOT NULL,
  "time_started" TIMESTAMP NOT NULL,
  "time_ended" TIMESTAMP,
  "round_number" int NOT NULL,
  PRIMARY KEY ("id")
);
