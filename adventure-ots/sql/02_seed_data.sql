-- =============================================
-- Adventure OTS - Seed Data
-- Runs AFTER 01_schema.sql (TFS schema)
-- Safe to re-run manually on existing databases
-- =============================================

-- Create default admin account (login: 1, password: 1)
-- SHA1 hash of "1" = 356a192b7913b04c54574d18c28d46e6395428ab
INSERT INTO `accounts` (`id`, `name`, `password`, `type`, `premium_ends_at`, `email`, `creation`)
VALUES (1, '1', '356a192b7913b04c54574d18c28d46e6395428ab', 5, 0, 'admin@adventure.ots', UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
	`password` = VALUES(`password`),
	`type` = VALUES(`type`),
	`premium_ends_at` = VALUES(`premium_ends_at`),
	`email` = VALUES(`email`);

-- Create deterministic login test account (login: Patryk, password: test)
-- SHA1 hash of "test" = a94a8fe5ccb19ba61c4c0873d391e987982fbbd3
INSERT INTO `accounts` (`name`, `password`, `type`, `premium_ends_at`, `email`, `creation`)
VALUES ('Patryk', 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3', 1, 0, 'patryk.test@adventure.ots', UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
	`password` = VALUES(`password`),
	`type` = VALUES(`type`),
	`premium_ends_at` = VALUES(`premium_ends_at`),
	`email` = VALUES(`email`);

-- Create sample admin character (GOD)
INSERT INTO `players` (`name`, `group_id`, `account_id`, `level`, `vocation`, `health`, `healthmax`, `experience`, `lookbody`, `lookfeet`, `lookhead`, `looklegs`, `looktype`, `maglevel`, `mana`, `manamax`, `soul`, `town_id`, `posx`, `posy`, `posz`, `cap`, `sex`, `conditions`, `skill_fist`, `skill_club`, `skill_sword`, `skill_axe`, `skill_dist`, `skill_shielding`, `skill_fishing`)
VALUES ('Admin', 6, 1, 100, 0, 10000, 10000, 15694800, 0, 0, 0, 0, 75, 0, 10000, 10000, 100, 1, 0, 0, 0, 50000, 1, NULL, 10, 10, 10, 10, 10, 10, 10)
ON DUPLICATE KEY UPDATE
	`group_id` = VALUES(`group_id`),
	`account_id` = VALUES(`account_id`),
	`level` = VALUES(`level`),
	`vocation` = VALUES(`vocation`),
	`health` = VALUES(`health`),
	`healthmax` = VALUES(`healthmax`),
	`experience` = VALUES(`experience`),
	`lookbody` = VALUES(`lookbody`),
	`lookfeet` = VALUES(`lookfeet`),
	`lookhead` = VALUES(`lookhead`),
	`looklegs` = VALUES(`looklegs`),
	`looktype` = VALUES(`looktype`),
	`maglevel` = VALUES(`maglevel`),
	`mana` = VALUES(`mana`),
	`manamax` = VALUES(`manamax`),
	`soul` = VALUES(`soul`),
	`town_id` = VALUES(`town_id`),
	`posx` = VALUES(`posx`),
	`posy` = VALUES(`posy`),
	`posz` = VALUES(`posz`),
	`cap` = VALUES(`cap`),
	`sex` = VALUES(`sex`),
	`conditions` = VALUES(`conditions`),
	`skill_fist` = VALUES(`skill_fist`),
	`skill_club` = VALUES(`skill_club`),
	`skill_sword` = VALUES(`skill_sword`),
	`skill_axe` = VALUES(`skill_axe`),
	`skill_dist` = VALUES(`skill_dist`),
	`skill_shielding` = VALUES(`skill_shielding`),
	`skill_fishing` = VALUES(`skill_fishing`);
