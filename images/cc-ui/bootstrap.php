<?php
// Database
define('DB_HOST', getenv('DB_1_PORT_3306_TCP_ADDR'));
define('DB_PORT', getenv('DB_1_PORT_3306_TCP_PORT'));
define('DB_LOGIN', 'cmon');
define('DB_PASS', 'cmon');
define('DB_NAME', 'dcps');

// cmonapi
define('APP_PROTOCOL', 'http');
define('APP_HOST', '127.0.0.1');
define('APP_URL', APP_PROTOCOL.'://'.APP_HOST);
define('CMON_API', APP_URL.'/cmonapi');

// UI version
define('CC_UI_VERSION', 'CCUIVERSION');

define('SMTP_HOST', '');
define('SMTP_USER', '');
define('SMTP_PASS', '');
define('SMTP_PORT', '');

define('STATUS_REFRESH_RATE', 10000);

define('RPC_PORT','9500');
define('RPC_HOST','127.0.0.1');
define('RPC_TOKEN','RPCTOKEN');

define('VENDOR', 'Severalnines');

// Enable Web SSH
define('SSH_ENABLED', true);

// cmon-events configuration
define('CMON_EVENTS_ENABLED', true);
define('CMON_EVENTS_HOST', '127.0.0.1');
define('CMON_EVENTS_PORT', 9510);

// Cloud services
define('CLOUDS_ENABLED', true);

// In Docker
define('CONTAINER', 'docker');
