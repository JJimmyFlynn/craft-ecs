<?php
/**
 * Craft web bootstrap file
 */

define('CRAFT_STREAM_LOG', true);

// Set path constants
define('CRAFT_BASE_PATH', dirname(__DIR__));
define('CRAFT_VENDOR_PATH', CRAFT_BASE_PATH.'/vendor');

// Load Composer's autoloader
require_once CRAFT_VENDOR_PATH.'/autoload.php';

// Load dotenv?
if (file_exists(CRAFT_BASE_PATH.'/.env')) {
    Dotenv\Dotenv::create(CRAFT_BASE_PATH)->load();
}

define('CRAFT_ENVIRONMENT', getenv('CRAFT_ENVIRONMENT') ?: 'production');

// Load and run Craft
$app = require CRAFT_VENDOR_PATH.'/craftcms/cms/bootstrap/web.php';
$app->run();
