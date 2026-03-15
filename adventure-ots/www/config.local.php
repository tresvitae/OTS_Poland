<?php
// MyAAC - Local Configuration for Docker MVP
// Te ustawienia nadpisują wartości z config.lua

$config['installed'] = false;  // Set to false for first run — MyAAC installer creates myaac_* tables
$config['database_overwrite'] = true;

// Baza danych (musi być zgodne z docker-compose.yml)
$config['database_host'] = 'db';
$config['database_port'] = '3306';
$config['database_user'] = 'root';
$config['database_password'] = 'twoje_haslo';
$config['database_name'] = 'ots_baza';

// Ścieżka do silnika TFS (Docker montuje tfs/ w /srv/)
$config['server_path'] = '/srv/';

// Ustawienia strony
$config['client_version'] = 1098;
$config['lua_item_desc'] = true;

// Ustawienia startowe postaci
$config['warmup_town'] = 1;

// Bezpieczeństwo
$config['mail_enabled'] = false;
$config['encryption'] = 'sha1';

// Środowisko deweloperskie
$config['env'] = 'dev';
$config['cache_engine'] = 'file';