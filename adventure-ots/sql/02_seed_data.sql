-- =============================================
-- Adventure OTS - Seed Data
-- Runs AFTER 01_schema.sql (TFS schema)
-- =============================================

-- Create default admin account (login: 1, password: 1)
-- SHA1 hash of "1" = 356a192b7913b04c54574d18c28d46e6395428ab
INSERT INTO `accounts` (`id`, `name`, `password`, `type`, `premium_ends_at`, `email`, `creation`)
VALUES (1, '1', '356a192b7913b04c54574d18c28d46e6395428ab', 5, 0, 'admin@adventure.ots', UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `id` = `id`;

-- Create sample admin character (GOD)
INSERT INTO `players` (`name`, `group_id`, `account_id`, `level`, `vocation`, `health`, `healthmax`, `experience`, `lookbody`, `lookfeet`, `lookhead`, `looklegs`, `looktype`, `maglevel`, `mana`, `manamax`, `soul`, `town_id`, `posx`, `posy`, `posz`, `cap`, `sex`, `conditions`, `skill_fist`, `skill_club`, `skill_sword`, `skill_axe`, `skill_dist`, `skill_shielding`, `skill_fishing`)
VALUES ('Admin', 6, 1, 100, 0, 10000, 10000, 15694800, 0, 0, 0, 0, 75, 0, 10000, 10000, 100, 1, 0, 0, 0, 50000, 1, NULL, 10, 10, 10, 10, 10, 10, 10)
ON DUPLICATE KEY UPDATE `name` = `name`;
