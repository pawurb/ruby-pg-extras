/* Check if SSL connection is used */

CREATE EXTENSION IF NOT EXISTS sslinfo;
SELECT ssl_is_used();
