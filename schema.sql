-- Active: 1740996226560@@localhost@5433@dnd_db
CREATE DATABASE "dnd_db";

CREATE TABLE "Combat" (
  "id" bigint NOT NULL UNIQUE,
  "act_round_number" int NOT NULL,
  "time_started" TIMESTAMP NOT NULL,
  "time_ended" TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE TYPE "character_state_enum" AS ENUM (
  'In combat',
  'Resting',
  'Died'
);

CREATE TABLE "Characters" (
  "id" bigint NOT NULL UNIQUE,
  "class_id" bigint NOT NULL,
  "state" "character_state_enum" NOT NULL,
  "experience_points" int NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "CombatParticipants" (
  "id" bigint NOT NULL UNIQUE,
  "character_id" bigint NOT NULL,
  "combat_id" bigint NOT NULL,
  "act_health" int NOT NULL,
  "act_action_points" int NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "Inventory" (
  "id" bigint NOT NULL UNIQUE,
  "character_id" bigint NOT NULL,
  "item_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "CombatItems" (
  "id" bigint NOT NULL UNIQUE,
  "combat_id" bigint NOT NULL,
  "item_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "Items" (
  "id" bigint NOT NULL UNIQUE,
  "name" varchar(100) NOT NULL,
  "description" text NOT NULL,
  "weight" int NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "ClassAttributes" (
  "id" bigint NOT NULL UNIQUE,
  "class_id" bigint NOT NULL,
  "attribute_id" bigint NOT NULL,
  "modifier" DECIMAL(3, 2) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "Classes" (
  "id" bigint NOT NULL UNIQUE,
  "name" varchar(50) NOT NULL UNIQUE,
  "description" text,
  "ap_modifier" DECIMAL(3, 2) NOT NULL,
  "inventory_modifier" DECIMAL(3, 2) NOT NULL,
  "ac_modifier" DECIMAL(3, 2) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "CharacterAttributes" (
  "id" bigint NOT NULL UNIQUE,
  "character_id" bigint NOT NULL,
  "attribute_id" bigint NOT NULL,
  "base_value" int NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "SpellAttributes" (
  "id" bigint NOT NULL UNIQUE,
  "spell_id" bigint NOT NULL,
  "attribute_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "ItemAttributes" (
  "id" bigint NOT NULL UNIQUE,
  "item_id" bigint NOT NULL,
  "attribute_id" bigint NOT NULL,
  "modifier" int NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "Attributes" (
  "id" bigint NOT NULL UNIQUE,
  "name" varchar(50) NOT NULL UNIQUE,
  "description" text NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "SpellCategories" (
  "id" bigint NOT NULL UNIQUE,
  "name" varchar(50) NOT NULL UNIQUE,
  "description" text NOT NULL,
  "base_cost" int NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "Actions" (
  "id" bigint NOT NULL UNIQUE,
  "round_id" bigint NOT NULL,
  "spell_id" bigint,
  "action_type" VARCHAR(50) NOT NULL,
  "actor_id" bigint,
  "target_id" bigint,
  "item_id" bigint,
  "ap_cost" int NOT NULL,
  "effect" int NOT NULL,
  "dice_roll" int,
  "action_timestamp" TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE TYPE "effect_type_enum" AS ENUM (
  'damage',
  'healing',
  'vamp'
);

CREATE TABLE "Spells" (
  "id" bigint NOT NULL UNIQUE,
  "name" varchar(100) NOT NULL UNIQUE,
  "description" text NOT NULL,
  "category_id" bigint NOT NULL,
  "base_effect" int NOT NULL,
  "effect_type" effect_type_enum NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "CharacterSpells" (
  "character_id" bigint NOT NULL,
  "spell_id" bigint NOT NULL,
  PRIMARY KEY ("character_id", "spell_id")
);

CREATE TABLE "CombatRounds" (
  "id" bigint NOT NULL UNIQUE,
  "combat_id" bigint NOT NULL,
  "time_started" TIMESTAMP NOT NULL,
  "time_ended" TIMESTAMP,
  "round_number" int NOT NULL,
  PRIMARY KEY ("id")
);
