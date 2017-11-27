CREATE SCHEMA IF NOT EXISTS `dcps`;
USE `dcps`;
--
-- Table structure for table `apis`
--

/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `apis` (
    `id`                   INT(10) UNSIGNED    NOT NULL AUTO_INCREMENT,
    `company_id`           INT(10) UNSIGNED    NOT NULL DEFAULT '0',
    `user_id`              INT(10) UNSIGNED    NOT NULL DEFAULT '0',
    `url`                  VARCHAR(255)        NOT NULL DEFAULT '',
    `token`                VARCHAR(40)         NOT NULL DEFAULT '',
    `request_token`        VARCHAR(40)         NOT NULL DEFAULT '',
    `request_token_expire` BIGINT(20) UNSIGNED NOT NULL DEFAULT '0',
    `created_by`           INT(10) UNSIGNED    NOT NULL DEFAULT '0',
    `created`              BIGINT(20)          NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `clusters`
--

/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `clusters` (
    `id`                           INT(10) UNSIGNED                                                                                                    NOT NULL AUTO_INCREMENT,
    `company_id`                   INT(10) UNSIGNED                                                                                                    NOT NULL DEFAULT '0',
    `cluster_id`                   INT(10) UNSIGNED                                                                                                    NOT NULL DEFAULT '0'
    COMMENT 'This is the cluster_id on the cmon''s cluster, not used in ccui',
    `api_id`                       INT(10) UNSIGNED                                                                                                    NOT NULL DEFAULT '0',
    `name`                         VARCHAR(125)                                                                                                        NOT NULL DEFAULT '',
    `ip`                           VARCHAR(20)                                                                                                         NOT NULL DEFAULT '',
    `token`                        VARCHAR(255)                                                                                                                 DEFAULT NULL,
    `cmon_host`                    VARCHAR(50)                                                                                                         NOT NULL DEFAULT '',
    `cmon_port`                    VARCHAR(10)                                                                                                         NOT NULL DEFAULT '',
    `cmon_user`                    VARCHAR(50)                                                                                                         NOT NULL DEFAULT '',
    `cmon_pass`                    VARCHAR(50)                                                                                                         NOT NULL DEFAULT '',
    `cmon_db`                      VARCHAR(10)                                                                                                         NOT NULL DEFAULT 'cmon',
    `cmon_type`                    TINYINT(4)                                                                                                                   DEFAULT NULL
    COMMENT 'Either 0 (on premises), or 1 (cloud based)',
    `mysql_root_password`          VARCHAR(255)                                                                                                        NOT NULL DEFAULT ''
    COMMENT 'The mysql root password, used when initializing the Master',
    `type`                         ENUM ('mysqlcluster', 'replication', 'galera', 'mongodb', 'mysql_single', 'postgresql_single', 'group_replication') NOT NULL,
    `status`                       SMALLINT(6)                                                                                                         NOT NULL DEFAULT '204',
    `created`                      BIGINT(20)                                                                                                          NOT NULL DEFAULT '0',
    `ssh_key`                      VARBINARY(1024)                                                                                                              DEFAULT NULL DEFAULT '',
    `cluster_status`               TINYINT(3) UNSIGNED                                                                                                          DEFAULT NULL,
    `error_msg`                    VARCHAR(255)                                                                                                                 DEFAULT NULL,
    `error_code`                   INT(10) UNSIGNED                                                                                                             DEFAULT NULL,
    `updated`                      TIMESTAMP                                                                                                           NOT NULL DEFAULT '2013-01-01 00:00:00',
    `created_by`                   INT(10) UNSIGNED                                                                                                    NOT NULL DEFAULT '0',
    `cluster_status_txt`           VARCHAR(64)                                                                                                                  DEFAULT NULL DEFAULT '',
    `def_server_template_id`       INT(10) UNSIGNED                                                                                                             DEFAULT NULL,
    `def_db_template_id`           INT(10) UNSIGNED                                                                                                             DEFAULT NULL,
    `def_additional_disk_space_id` INT(10) UNSIGNED                                                                                                    NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `companies`
--

/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `companies` (
    `id`   INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(125)     NOT NULL DEFAULT '',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `jobs`
--

/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `jobs` (
    `jobid`                    INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `cc_vm_id`                 INT(10) UNSIGNED NOT NULL DEFAULT '0',
    `cluster_id`               INT(10) UNSIGNED NOT NULL DEFAULT '0',
    `command`                  VARCHAR(255)     NOT NULL DEFAULT '',
    `vm_ip`                    VARCHAR(15)      NOT NULL DEFAULT '',
    `master_vm_ip`             VARCHAR(15)               DEFAULT NULL,
    `role`                     TINYINT(4)       NOT NULL DEFAULT '0',
    `cluster_type`             TINYINT(4)       NOT NULL DEFAULT '0',
    `server_template_id`       INT(10) UNSIGNED NOT NULL DEFAULT '0',
    `db_template_id`           INT(10) UNSIGNED NOT NULL DEFAULT '0',
    `additional_disk_space_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
    `package_id`               INT(10) UNSIGNED NOT NULL DEFAULT '0',
    `size`                     TINYINT(4)       NOT NULL DEFAULT '0',
    `jobstatus`                TINYINT(4)       NOT NULL DEFAULT '2',
    `errmsg`                   VARCHAR(512)     NOT NULL DEFAULT '',
    `errno`                    INT(11)          NOT NULL DEFAULT '0',
    `cluster_name`             VARCHAR(255)              DEFAULT 'default_name',
    `root_password`            VARCHAR(255)              DEFAULT 'password',
    `created`                  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_updated`             TIMESTAMP        NOT NULL DEFAULT '2013-01-01 00:00:00',
    PRIMARY KEY (`jobid`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

/*!40101 SET @saved_cs_client = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE IF NOT EXISTS `users` (
    `id`                  INT(10) UNSIGNED    NOT NULL AUTO_INCREMENT,
    `company_id`          INT(10) UNSIGNED    NOT NULL DEFAULT '0',
    `email`               VARCHAR(125)        NOT NULL DEFAULT '',
    `password`            VARCHAR(64)         NOT NULL DEFAULT '',
    `name`                VARCHAR(125)        NOT NULL DEFAULT '',
    `timezone`            VARCHAR(100)                 DEFAULT '',
    `sa`                  TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
    `session_id`          VARCHAR(60)         NOT NULL DEFAULT '',
    `created`             BIGINT(20) UNSIGNED NOT NULL DEFAULT '0',
    `last_login`          BIGINT(20) UNSIGNED NOT NULL DEFAULT 0,
    `facebook_id`         VARCHAR(250)        NULL     DEFAULT '',
    `fbaccess_token`      VARCHAR(250)        NULL     DEFAULT '',
    `logins`              INT UNSIGNED        NULL     DEFAULT 0,
    `salt`                VARCHAR(64)         NOT NULL DEFAULT 'fIouG9Fzgzp34563b02GyxfUuDm4aJFgaC9mi',
    `uuid`                VARCHAR(64)         NOT NULL DEFAULT '',
    `verification_code`   VARCHAR(32)         NULL     DEFAULT '',
    `email_verified`      INT                 NOT NULL DEFAULT 0,
    `reset_password_code` VARCHAR(32)         NULL     DEFAULT '',
    `reset_password_date` BIGINT(20)          NULL     DEFAULT '0',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `roles`
--
CREATE TABLE IF NOT EXISTS `roles` (
    `id`        SMALLINT(3)  NOT NULL DEFAULT '1',
    `role_name` VARCHAR(100) NOT NULL DEFAULT '',
    `role_type` CHAR(1)               DEFAULT 'u',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;

--
-- Table structure for table `user_roles`
--

CREATE TABLE IF NOT EXISTS `user_roles` (
    `id`      INT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` INT(11)          NOT NULL DEFAULT '0',
    `role_id` INT(11)          NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    AUTO_INCREMENT = 1;

-- AWS credentials
CREATE TABLE IF NOT EXISTS `aws_credentials` (
    `id`                INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`           INT(11)          NOT NULL DEFAULT '0',
    `keypair_name`      VARCHAR(64)      NOT NULL DEFAULT '',
    `private_key`       VARCHAR(4096)    NOT NULL DEFAULT '',
    `access_key`        VARCHAR(256)     NOT NULL DEFAULT '',
    `secret_access_key` VARCHAR(256)     NOT NULL DEFAULT '',
    `comment`           VARCHAR(256)     NULL     DEFAULT '',
    `in_use`            TINYINT(1)       NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;

CREATE TABLE IF NOT EXISTS `deployments` (
    `id`           INT(11)      NOT NULL  AUTO_INCREMENT,
    `url`          VARCHAR(250) NOT NULL  DEFAULT '',
    `cluster_type` VARCHAR(50)  NOT NULL  DEFAULT '',
    `user_id`      INT(11)      NOT NULL  DEFAULT '0',
    `key_id`       INT(11)      NOT NULL  DEFAULT '0',
    `created`      DATETIME     NOT NULL  DEFAULT '2013-01-01 00:00:00',
    `last_updated` DATETIME     NOT NULL  DEFAULT '2013-01-01 00:00:00',
    `os_user`      VARCHAR(20)  NOT NULL  DEFAULT '',
    `session_dir`  VARCHAR(256) NOT NULL  DEFAULT '',
    `status`       TINYINT(4)   NOT NULL  DEFAULT '0',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;


CREATE TABLE IF NOT EXISTS `settings` (
    `id`          INT(11) UNSIGNED                                       NOT NULL AUTO_INCREMENT,
    `name`        VARCHAR(100)                                           NOT NULL DEFAULT '',
    `user_id`     INT(11)                                                NOT NULL DEFAULT '0',
    `location_id` INT(11)                                                         DEFAULT NULL
    COMMENT '1-overview,',
    `cluster_id`  INT(11)                                                NOT NULL DEFAULT '0',
    `selected`    TINYINT(4)                                             NOT NULL DEFAULT '0',
    `dash_order`  TINYINT(4)                                             NOT NULL DEFAULT '0',
    `rs_name`     VARCHAR(255)                                           NOT NULL DEFAULT 'none',
    `type`        ENUM ('dashboard', 'refresh_rate') DEFAULT 'dashboard' NOT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;


CREATE TABLE IF NOT EXISTS `settings_items` (
    `id`         INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `setting_id` INT(11)          NOT NULL DEFAULT '0',
    `item`       VARCHAR(2048)    NOT NULL DEFAULT '',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;

-- Update clusters table
CREATE TABLE IF NOT EXISTS `clusters_new` (
    `id`                           INT(10) UNSIGNED                                                          NOT NULL AUTO_INCREMENT,
    `company_id`                   INT(10) UNSIGNED                                                          NOT NULL DEFAULT '0',
    `cluster_id`                   INT(10) UNSIGNED                                                          NOT NULL DEFAULT '0'
    COMMENT 'This is the cluster_id on the cmon''s cluster, not used in ccui',
    `api_id`                       INT(10) UNSIGNED                                                          NOT NULL DEFAULT '0',
    `name`                         VARCHAR(125)                                                              NOT NULL DEFAULT '',
    `ip`                           VARCHAR(20)                                                               NOT NULL DEFAULT '',
    `cmon_host`                    VARCHAR(50)                                                               NOT NULL DEFAULT '',
    `cmon_port`                    VARCHAR(10)                                                               NOT NULL DEFAULT '',
    `cmon_user`                    VARCHAR(50)                                                               NOT NULL DEFAULT '',
    `cmon_pass`                    VARCHAR(50)                                                               NOT NULL DEFAULT '',
    `cmon_db`                      VARCHAR(10)                                                               NOT NULL DEFAULT 'cmon',
    `cmon_type`                    TINYINT(4)                                                                         DEFAULT NULL
    COMMENT 'Either 0 (on premises), or 1 (cloud based)',
    `mysql_root_password`          VARCHAR(255)                                                              NOT NULL DEFAULT ''
    COMMENT 'The mysql root password, used when initializing the Master',
    `type`                         ENUM ('mysqlcluster', 'replication', 'galera', 'mongodb', 'mysql_single') NOT NULL,
    `status`                       SMALLINT(6)                                                               NOT NULL DEFAULT '204',
    `created`                      BIGINT(20)                                                                NOT NULL DEFAULT '0',
    `ssh_key`                      VARBINARY(1024)                                                                    DEFAULT NULL DEFAULT '',
    `cluster_status`               TINYINT(3) UNSIGNED                                                                DEFAULT NULL,
    `error_msg`                    VARCHAR(255)                                                                       DEFAULT NULL,
    `error_code`                   INT(10) UNSIGNED                                                                   DEFAULT NULL,
    `updated`                      TIMESTAMP                                                                 NOT NULL DEFAULT '2013-01-01 00:00:00',
    `created_by`                   INT(10) UNSIGNED                                                          NOT NULL DEFAULT '0',
    `cluster_status_txt`           VARCHAR(64)                                                                        DEFAULT NULL DEFAULT '',
    `def_server_template_id`       INT(10) UNSIGNED                                                                   DEFAULT NULL,
    `def_db_template_id`           INT(10) UNSIGNED                                                                   DEFAULT NULL,
    `def_additional_disk_space_id` INT(10) UNSIGNED                                                          NOT NULL DEFAULT '0',
    `is_clone`                     TINYINT(4)                                                                NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;

DROP PROCEDURE IF EXISTS upgrade_clusters;

DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE upgrade_clusters()
    BEGIN
        DECLARE colName TEXT;
        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps' AND table_name = 'clusters' AND column_name = 'is_clone';

        IF colName IS NULL
        THEN
            DROP TABLE IF EXISTS clusters_old;
            INSERT INTO clusters_new (id, company_id, cluster_id, api_id, name, ip, cmon_host, cmon_port, cmon_user, cmon_pass, cmon_db, cmon_type, mysql_root_password, type, status, created, ssh_key, cluster_status, error_msg, error_code, updated, created_by, cluster_status_txt, def_server_template_id, def_db_template_id, def_additional_disk_space_id) SELECT
                                                                                                                                                                                                                                                                                                                                                                       id,
                                                                                                                                                                                                                                                                                                                                                                       company_id,
                                                                                                                                                                                                                                                                                                                                                                       cluster_id,
                                                                                                                                                                                                                                                                                                                                                                       api_id,
                                                                                                                                                                                                                                                                                                                                                                       name,
                                                                                                                                                                                                                                                                                                                                                                       ip,
                                                                                                                                                                                                                                                                                                                                                                       cmon_host,
                                                                                                                                                                                                                                                                                                                                                                       cmon_port,
                                                                                                                                                                                                                                                                                                                                                                       cmon_user,
                                                                                                                                                                                                                                                                                                                                                                       cmon_pass,
                                                                                                                                                                                                                                                                                                                                                                       cmon_db,
                                                                                                                                                                                                                                                                                                                                                                       cmon_type,
                                                                                                                                                                                                                                                                                                                                                                       mysql_root_password,
                                                                                                                                                                                                                                                                                                                                                                       type,
                                                                                                                                                                                                                                                                                                                                                                       status,
                                                                                                                                                                                                                                                                                                                                                                       created,
                                                                                                                                                                                                                                                                                                                                                                       ssh_key,
                                                                                                                                                                                                                                                                                                                                                                       cluster_status,
                                                                                                                                                                                                                                                                                                                                                                       error_msg,
                                                                                                                                                                                                                                                                                                                                                                       error_code,
                                                                                                                                                                                                                                                                                                                                                                       updated,
                                                                                                                                                                                                                                                                                                                                                                       created_by,
                                                                                                                                                                                                                                                                                                                                                                       cluster_status_txt,
                                                                                                                                                                                                                                                                                                                                                                       def_server_template_id,
                                                                                                                                                                                                                                                                                                                                                                       def_db_template_id,
                                                                                                                                                                                                                                                                                                                                                                       def_additional_disk_space_id
                                                                                                                                                                                                                                                                                                                                                                   FROM
                                                                                                                                                                                                                                                                                                                                                                       clusters;
            RENAME TABLE
                    clusters TO clusters_old,
                    clusters_new TO clusters;
        END IF;
    END$$

DELIMITER ;

CALL upgrade_clusters;

DROP PROCEDURE upgrade_clusters;

DROP TABLE IF EXISTS clusters_old;
DROP TABLE IF EXISTS clusters_new;

-- Need to make sure mysql_single, posgresql_single are there for prev versions
ALTER TABLE `clusters`
    CHANGE COLUMN `type` `type` ENUM('mysqlcluster','replication','galera','mongodb','mysql_single','postgresql_single','group_replication') NOT NULL;

-- upgrade 1.2.0/1.2.1/1.2.2 -> v1.2.3 settings should have rs_name and type already but in case it's not there
DROP PROCEDURE IF EXISTS upgrade_settings;

DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE upgrade_settings()
    BEGIN
        DECLARE colName TEXT;
        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps' AND table_name = 'settings' AND column_name = 'rs_name';

        IF colName IS NULL
        THEN
            ALTER TABLE `settings`
                ADD COLUMN `rs_name` VARCHAR(255) NOT NULL DEFAULT 'none';
            ALTER TABLE `settings`
                ADD COLUMN `type` ENUM ('dashboard', 'refresh_rate') DEFAULT 'dashboard' NOT NULL;
        END IF;
    END$$

DELIMITER ;

CALL upgrade_settings;

DROP PROCEDURE upgrade_settings;

-- v.1.2.4
ALTER TABLE `settings`
    MODIFY COLUMN `type` ENUM ('dashboard', 'refresh_rate', 'settings') DEFAULT 'dashboard' NOT NULL;

CREATE TABLE IF NOT EXISTS `onpremise_credentials` (
    `id`           INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`      INT(11)          NOT NULL DEFAULT '0',
    `keypair_name` VARCHAR(64)      NOT NULL DEFAULT '',
    `comment`      VARCHAR(256)              DEFAULT '',
    `in_use`       TINYINT(1)       NOT NULL DEFAULT '0',
    `private_key`  VARCHAR(4096)             DEFAULT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    AUTO_INCREMENT = 19
    DEFAULT CHARSET = latin1;

CREATE TABLE IF NOT EXISTS `onpremise_deployments` (
    `id`            INT(11)      NOT NULL AUTO_INCREMENT,
    `user_id`       INT(11)      NOT NULL DEFAULT '0',
    `key_id`        INT(11)      NOT NULL DEFAULT '0',
    `created`       DATETIME     NOT NULL DEFAULT '2013-01-01 00:00:00',
    `last_updated`  DATETIME     NOT NULL DEFAULT '2013-01-01 00:00:00',
    `os_user`       VARCHAR(20)  NOT NULL DEFAULT '',
    `package_name`  VARCHAR(256) NOT NULL DEFAULT '',
    `cc_ip_address` VARCHAR(100) NOT NULL,
    `key_from_aws`  INT          NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    AUTO_INCREMENT = 11
    DEFAULT CHARSET = latin1;

CREATE TABLE IF NOT EXISTS `backups` (
    `id`            INT(11) UNSIGNED                NOT NULL AUTO_INCREMENT,
    `container_id`  INT(11)                         NOT NULL,
    `backup_id`     INT(11)                         NOT NULL,
    `storage`       ENUM ('S3', 'Glacier', 'Other') NOT NULL DEFAULT 'Other',
    `archive_name`  VARCHAR(512)                             DEFAULT NULL,
    `archive_id`    VARCHAR(256)                             DEFAULT NULL
    COMMENT 'for glacier backup',
    `file_size`     INT(20)                                  DEFAULT NULL,
    `creation_date` DATETIME                        NOT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    AUTO_INCREMENT = 1;

CREATE TABLE IF NOT EXISTS `containers` (
    `id`         INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`       VARCHAR(512)     NOT NULL DEFAULT '',
    `cluster_id` INT(11)          NOT NULL,
    `key_id`     INT(11)          NOT NULL,
    `region`     VARCHAR(100)              DEFAULT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    AUTO_INCREMENT = 1;

CREATE TABLE IF NOT EXISTS `glacier_jobs` (
    `id`              INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `job_id`          VARCHAR(512)     NOT NULL DEFAULT '',
    `uri`             VARCHAR(1024)    NOT NULL DEFAULT '',
    `status`          VARCHAR(100)              DEFAULT NULL,
    `cloud_backup_id` INT(11)                   DEFAULT NULL,
    `creation_date`   DATETIME                  DEFAULT NULL,
    `last_update`     DATETIME                  DEFAULT NULL,
    `completion_time` INT(11) UNSIGNED          DEFAULT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    AUTO_INCREMENT = 1;

CREATE TABLE IF NOT EXISTS `cluster_keys` (
    `id`         INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `cluster_id` INT(11)          NOT NULL,
    `key_id`     INT(11)          NOT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    AUTO_INCREMENT = 1;

CREATE TABLE IF NOT EXISTS `cluster_aws_keys` (
    `id`         INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `cluster_id` INT(11)          NOT NULL,
    `key_id`     INT(11)          NOT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    AUTO_INCREMENT = 1;

-- not used atm
DROP TABLE IF EXISTS reports_emails;
DROP TABLE IF EXISTS smtp_server;

-- post v1.2.5

CREATE TABLE IF NOT EXISTS `openstack_credentials` (
    `id`           INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`      INT(11)          NOT NULL,
    `keypair_name` VARCHAR(64)      NOT NULL,
    `username`     VARCHAR(255)     NOT NULL DEFAULT '',
    `password`     VARCHAR(2048)    NOT NULL DEFAULT '',
    `tenant_name`  VARCHAR(255)     NOT NULL DEFAULT '',
    `identity_url` VARCHAR(512)     NOT NULL DEFAULT '',
    `private_key`  VARCHAR(4096)    NOT NULL DEFAULT '',
    `comment`      VARCHAR(256)     NOT NULL DEFAULT '',
    `in_use`       TINYINT(1)       NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    AUTO_INCREMENT = 1;

CREATE TABLE IF NOT EXISTS `ldap_settings` (
    `id`               INT(11)      NOT NULL AUTO_INCREMENT,
    `enable_ldap_auth` INT(11)      NOT NULL DEFAULT '0',
    `host`             VARCHAR(50)  NOT NULL,
    `port`             VARCHAR(10)  NOT NULL DEFAULT '389',
    `login`            VARCHAR(100) NOT NULL,
    `password`         VARCHAR(60)  NOT NULL,
    `base_dsn`         VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;

CREATE TABLE IF NOT EXISTS `ldap_group_roles` (
    `id`              INT(11)      NOT NULL AUTO_INCREMENT,
    `ldap_group_name` VARCHAR(100) NOT NULL,
    `role_id`         INT(11)      NOT NULL,
    `company_id`      INT(11)      NOT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;

DROP PROCEDURE IF EXISTS upgrade_onpremise_deployments;
DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE upgrade_onpremise_deployments()
    BEGIN
        DECLARE colName TEXT;
        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps' AND table_name = 'onpremise_deployments' AND column_name = 'ssh_port';

        IF colName IS NULL
        THEN
            ALTER TABLE `onpremise_deployments`
                ADD COLUMN ssh_port INT NOT NULL DEFAULT 22;
        END IF;
    END$$

DELIMITER ;

CALL upgrade_onpremise_deployments;

DROP PROCEDURE upgrade_onpremise_deployments;

DROP PROCEDURE IF EXISTS upgrade_ldap;
DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE upgrade_ldap()
    BEGIN
        DECLARE colName TEXT;
        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps' AND table_name = 'apis' AND column_name = 'from_ldap_user';

        IF colName IS NULL
        THEN
            ALTER TABLE apis
                ADD COLUMN `from_ldap_user` INT(11) NOT NULL DEFAULT 0;
            ALTER TABLE settings
                ADD COLUMN `from_ldap_user` INT(11) NOT NULL DEFAULT 0;
            ALTER TABLE onpremise_deployments
                ADD COLUMN `from_ldap_user` INT(11) NOT NULL DEFAULT 0;
            ALTER TABLE aws_credentials
                ADD COLUMN `from_ldap_user` INT(11) NOT NULL DEFAULT 0;
            ALTER TABLE onpremise_credentials
                ADD COLUMN `from_ldap_user` INT(11) NOT NULL DEFAULT 0;
            ALTER TABLE deployments
                ADD COLUMN `from_ldap_user` INT(11) NOT NULL DEFAULT 0;
            ALTER TABLE openstack_credentials
                ADD COLUMN `from_ldap_user` INT(11) NOT NULL DEFAULT 0;
        END IF;
    END$$

DELIMITER ;

CALL upgrade_ldap;

DROP PROCEDURE upgrade_ldap;

CREATE TABLE IF NOT EXISTS `acls` (
    `id`           INT(11)     NOT NULL AUTO_INCREMENT,
    `feature_name` VARCHAR(30) NOT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    AUTO_INCREMENT = 15
    DEFAULT CHARSET = latin1;

REPLACE INTO `acls` (`id`, `feature_name`)
    VALUES
        (1, 'Overview'),
        (2, 'Nodes'),
        (3, 'Configuration Management'),
        (4, 'Query Monitor'),
        (5, 'Performance'),
        (6, 'Backup'),
        (7, 'Manage'),
        (8, 'Alarms'),
        (9, 'Jobs'),
        (10, 'Settings'),
        (11, 'Add Existing Cluster'),
        (12, 'Create Cluster'),
        (13, 'Add Load Balancer'),
        (14, 'Clone'),
        (15, 'Access All Clusters'),
        (16, 'Cluster Registrations'),
        (17, 'Manage AWS'),
        (18, 'Search'),
        (19, 'Create Database Node'),
        (20, 'Developer studio'),
        (21, 'Custom Advisor'),
        (22, 'SSL Key Management'),
        (23, 'MySQL User Management'),
        (24, 'Operational Reports'),
        (25, 'Integrations'),
        (26, 'Web SSH');

CREATE TABLE IF NOT EXISTS `role_acls` (
    `id`         INT(11) NOT NULL AUTO_INCREMENT,
    `role_id`    INT(11) NOT NULL,
    `acl_id`     INT(11) NOT NULL,
    `permission` INT(11) NOT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1;

DROP PROCEDURE IF EXISTS update_role_acls;
DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE update_role_acls()
    BEGIN
        DECLARE cnt INT;
        SELECT count(*)
        INTO cnt
        FROM `role_acls`;

        IF cnt = 0
        THEN
            INSERT INTO `role_acls` (`role_id`, `acl_id`, `permission`)
            VALUES
                (2, 1, 17),
                (2, 2, 17),
                (2, 3, 17),
                (2, 4, 17),
                (2, 5, 1),
                (2, 6, 17),
                (2, 7, 17),
                (2, 8, 33),
                (2, 9, 33),
                (2, 10, 33),
                (2, 11, 16),
                (2, 12, 16),
                (2, 13, 16),
                (2, 14, 16),
                (2, 15, 1),
                (2, 16, 17),
                (2, 17, 17),
                (2, 18, 1),
                (2, 19, 16),
                (2, 20, 1),
                (3, 1, 17),
                (3, 2, 17),
                (3, 3, 17),
                (3, 4, 17),
                (3, 5, 1),
                (3, 6, 17),
                (3, 7, 17),
                (3, 8, 33),
                (3, 9, 33),
                (3, 10, 33),
                (3, 11, 16),
                (3, 12, 16),
                (3, 13, 16),
                (3, 14, 16),
                (3, 15, 2),
                (3, 16, 17),
                (3, 17, 17),
                (3, 18, 1),
                (2, 23, 1),
                (3, 23, 1),
                (2, 24, 1),
                (3, 24, 1),
                (2, 25, 1),
                (3, 25, 2),
                (2, 26, 1),
                (3, 26, 2);
        END IF;
    END$$

DELIMITER ;

CALL update_role_acls;
DROP PROCEDURE update_role_acls;


DROP PROCEDURE IF EXISTS upgrade_jobs;
DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE upgrade_jobs()
    BEGIN
        DECLARE colName TEXT;
        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps' AND table_name = 'jobs' AND column_name = 'from_ldap_user';

        IF colName IS NULL
        THEN
            DROP TABLE IF EXISTS `jobs`;
            CREATE TABLE `jobs` (
                `id`             INT(11) UNSIGNED                                                                                   NOT NULL AUTO_INCREMENT,
                `cluster_id`     INT(11) UNSIGNED                                                                                   NOT NULL DEFAULT '0',
                `cmon_jobid`     INT(11)                                                                                            NOT NULL,
                `job_command`    VARCHAR(2000)                                                                                      NOT NULL DEFAULT '0',
                `cluster_type`   VARCHAR(100)                                                                                       NOT NULL DEFAULT '0',
                `created`        DATETIME                                                                                           NOT NULL DEFAULT '2014-01-01 00:00:00',
                `last_updated`   DATETIME                                                                                           NOT NULL DEFAULT '2014-01-01 00:00:00',
                `status`         ENUM ('DEFINED', 'DEQUEUED', 'RUNNING', 'RUNNING_EXT', 'ABORTED', 'FINISHED', 'FAILED', 'DELETED') NOT NULL DEFAULT 'DEFINED',
                `user_id`        INT(11)                                                                                            NOT NULL,
                `from_ldap_user` INT(11)                                                                                            NOT NULL DEFAULT '0',
                PRIMARY KEY (`id`)
            )
                ENGINE = InnoDB
                DEFAULT CHARSET = latin1
                AUTO_INCREMENT = 1;
        END IF;
    END$$

DELIMITER ;

CALL upgrade_jobs;

DROP PROCEDURE upgrade_jobs;

-- upgrade settings table 1.2.8
DROP PROCEDURE IF EXISTS upgrade_settings;

DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE upgrade_settings()
    BEGIN
        DECLARE colName TEXT;
        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps' AND table_name = 'settings' AND column_name = 'cluster_type';

        IF colName IS NULL
        THEN
            ALTER TABLE `settings`
                ADD COLUMN `cluster_type` ENUM ('mysqlcluster', 'replication', 'galera', 'mongodb', 'mysql_single', 'postgresql_single', 'unknown') NOT NULL DEFAULT 'unknown';

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('InnoDB - Disk I/O', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'galera');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'INNODB_LOG_WRITES,INNODB_DATA_WRITES,INNODB_DATA_READS,INNODB_BACKGROUND_LOG_SYNC,INNODB_DATA_FSYNCS,INNODB_OS_LOG_FSYNCS:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('InnoDB - Disk I/O', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'replication');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'INNODB_LOG_WRITES,INNODB_DATA_WRITES,INNODB_DATA_READS,INNODB_BACKGROUND_LOG_SYNC,INNODB_DATA_FSYNCS,INNODB_OS_LOG_FSYNCS:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('InnoDB - Disk I/O', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mysql_single');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'INNODB_LOG_WRITES,INNODB_DATA_WRITES,INNODB_DATA_READS,INNODB_BACKGROUND_LOG_SYNC,INNODB_DATA_FSYNCS,INNODB_OS_LOG_FSYNCS:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Query Performance', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'galera');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'SLOW_QUERIES,SELECT_FULL_JOIN,SELECT_FULL_RANGE_JOIN,SELECT_RANGE_CHECK,SELECT_SCAN,CREATED_TMP_DISK_TABLES:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Query Performance', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'replication');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'SLOW_QUERIES,SELECT_FULL_JOIN,SELECT_FULL_RANGE_JOIN,SELECT_RANGE_CHECK,SELECT_SCAN,CREATED_TMP_DISK_TABLES:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Query Performance', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mysql_single');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'SLOW_QUERIES,SELECT_FULL_JOIN,SELECT_FULL_RANGE_JOIN,SELECT_RANGE_CHECK,SELECT_SCAN,CREATED_TMP_DISK_TABLES:linear');

                INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Query Performance', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mysqlcluster');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'SLOW_QUERIES,SELECT_FULL_JOIN,SELECT_FULL_RANGE_JOIN,SELECT_RANGE_CHECK,SELECT_SCAN,CREATED_TMP_DISK_TABLES:linear');

            /* bytes sent /recv all mysql based clusters */

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`) VALUES ('Bytes Sent/Recv', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'galera');

            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'BYTES_SENT,BYTES_RECEIVED:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Bytes Sent/Recv', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'replication');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'BYTES_SENT,BYTES_RECEIVED:linear');    


            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Bytes Sent/Recv', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mysqlcluster');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'BYTES_SENT,BYTES_RECEIVED:linear');


        
            /* replication specific */
            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Replication Lag', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'replication');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(), 'REPLICATION_LAG:linear');

            /*Galera specific*/
            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Galera - Queues', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'galera');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'WSREP_LOCAL_SEND_QUEUE, WSREP_LOCAL_SEND_QUEUE_AVG,WSREP_LOCAL_RECV_QUEUE,WSREP_LOCAL_RECV_QUEUE_AVG:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Galera - Flow Ctrl', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'galera');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'WSREP_LOCAL_CERT_FAILURES, WSREP_LOCAL_BF_ABORTS,WSREP_FLOW_CONTROL_SENT,WSREP_FLOW_CONTROL_RECV:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Galera - Innodb/Flow', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'galera');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'INNODB_BUFFER_POOL_PAGES_DIRTY, INNODB_BUFFER_POOL_PAGES_DATA, INNODB_OS_LOG_FSYNCS, INNODB_DATA_FSYNCS, WSREP_FLOW_CONTROL_SENT,WSREP_FLOW_CONTROL_RECV:logarithmic');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Galera - Replication', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'galera');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'WSREP_REPLICATED_BYTES,WSREP_RECEIVED_BYTES:linear');

            /* Mongodb */
            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('WT - Cache', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mongodb');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'wiredTiger.cache.bytes currently in the cache,wiredTiger.cache.tracked dirty bytes in the cache,wiredTiger.cache.maximum bytes configured:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Cursors', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mongodb');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'metrics.cursor.timedOut,metrics.cursor.open.noTimeout,metrics.cursor.open.total:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Asserts', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mongodb');
            INSERT INTO `settings_items` (`setting_id`, `item`)
            VALUES (LAST_INSERT_ID(), 'asserts.msg,asserts.warning,asserts.regular,asserts.user:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('GlobalLock', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mongodb');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'globalLock.currentQueue.readers,globalLock.currentQueue.writers,globalLock.activeClients.readers,globalLock.activeClients.writers:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Network', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mongodb');
            INSERT INTO `settings_items` (`setting_id`, `item`)
            VALUES (LAST_INSERT_ID(), 'network.bytesIn,network.bytesOut:linear');

            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('WT - ConcurrentTransactions', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mongodb');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'wiredTiger.concurrentTransactions.read.available,wiredTiger.concurrentTransactions.write.available,wiredTiger.concurrentTransactions.read.out,wiredTiger.concurrentTransactions.write.out:linear');


        END IF;
    END$$
DELIMITER ;
CALL upgrade_settings;
DROP PROCEDURE upgrade_settings;

DROP PROCEDURE IF EXISTS upgrade_settings_1210;
DELIMITER $$
CREATE DEFINER = CURRENT_USER PROCEDURE upgrade_settings_1210()
    BEGIN
        DECLARE colVal TEXT;
        SELECT name
        INTO colVal
        FROM dcps.settings
        WHERE name = 'Handler'
        LIMIT 1;

        IF colVal IS NULL
        THEN
            -- 1.2.10 handler dashboard
            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Handler', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'galera');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'HANDLER_COMMIT,HANDLER_DELETE,HANDLER_READ_FIRST,HANDLER_READ_KEY,HANDLER_READ_LAST,HANDLER_READ_NEXT,HANDLER_READ_PREV,HANDLER_READ_RND,HANDLER_READ_RND_NEXT,HANDLER_UPDATE,HANDLER_WRITE:linear');
            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Handler', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'mysql_single');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'HANDLER_COMMIT,HANDLER_DELETE,HANDLER_READ_FIRST,HANDLER_READ_KEY,HANDLER_READ_LAST,HANDLER_READ_NEXT,HANDLER_READ_PREV,HANDLER_READ_RND,HANDLER_READ_RND_NEXT,HANDLER_UPDATE,HANDLER_WRITE:linear');
            INSERT INTO `settings` (`name`, `user_id`, `location_id`, `cluster_id`, `selected`, `dash_order`, `rs_name`, `type`, `from_ldap_user`, `cluster_type`)
            VALUES ('Handler', 1, 1, -1, 0, 0, 'none', 'dashboard', 0, 'replication');
            INSERT INTO `settings_items` (`setting_id`, `item`) VALUES (LAST_INSERT_ID(),
                                                                        'HANDLER_COMMIT,HANDLER_DELETE,HANDLER_READ_FIRST,HANDLER_READ_KEY,HANDLER_READ_LAST,HANDLER_READ_NEXT,HANDLER_READ_PREV,HANDLER_READ_RND,HANDLER_READ_RND_NEXT,HANDLER_UPDATE,HANDLER_WRITE:linear');
        END IF;
    END$$
DELIMITER ;
CALL upgrade_settings_1210;
DROP PROCEDURE upgrade_settings_1210;

DROP PROCEDURE IF EXISTS update_ldap_settings;
DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE update_ldap_settings()
    BEGIN
        DECLARE colName TEXT;
        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps' AND table_name = 'ldap_settings' AND column_name = 'user_dn';

        IF colName IS NULL
        THEN
            ALTER TABLE `ldap_settings`
                ADD COLUMN `user_dn` VARCHAR(100) DEFAULT NULL;
            ALTER TABLE `ldap_settings`
                ADD COLUMN `group_dn` VARCHAR(100) DEFAULT NULL;
        END IF;
    END$$
DELIMITER ;
CALL update_ldap_settings;
DROP PROCEDURE update_ldap_settings;

--
-- Increment logins counter for the user
--
DROP TRIGGER IF EXISTS `users_update_logins`;
DELIMITER $$
CREATE TRIGGER users_update_logins BEFORE UPDATE ON users
FOR EACH ROW
    BEGIN
        SET NEW.logins = OLD.logins + 1;
    END
$$
DELIMITER ;

INSERT INTO `companies` (id, name) VALUES (1, 'Admin')
ON DUPLICATE KEY UPDATE name = name;
-- INSERT INTO `users` (id,company_id, email, password, name, sa, created) VALUES (1, 1, 'admin@localhost.xyz', '7163017d8e76e4b47ef16ffc5e346be010827adc', 'admin', 1, unix_timestamp(now())) ON DUPLICATE KEY UPDATE created=unix_timestamp(now());

--
-- version 1.2.12
--
CREATE TABLE IF NOT EXISTS `custom_advisors` (
    `id`                    BIGINT(18) UNSIGNED NOT NULL                                          AUTO_INCREMENT,
    `type`                  ENUM ('Threshold', 'Health', 'Security', 'Preditions', 'Auto tuning') DEFAULT NULL,
    `resource`              ENUM ('Host', 'Node')                                                 DEFAULT NULL,
    `cluster_id`            BIGINT(18)                                                            DEFAULT NULL,
    `node_id`               BIGINT(18)                                                            DEFAULT NULL,
    `hostname`              VARCHAR(500)                                                          DEFAULT NULL,
    `metric`                VARCHAR(255)                                                          DEFAULT NULL,
    `critical`              INT(11)                                                               DEFAULT '80',
    `warning`               INT(11)                                                               DEFAULT '70',
    `condition`             ENUM ('>', '<', '=')                                                  DEFAULT '=',
    `filename`              VARCHAR(500)        NOT NULL,
    `descr_title`           VARCHAR(255)                                                          DEFAULT NULL,
    `descr_advice`          TEXT                                                                  DEFAULT NULL,
    `descr_justification`   TEXT                                                                  DEFAULT NULL,
    `notification_types`    VARCHAR(255)                                                          DEFAULT NULL,
    `notification_settings` TEXT                                                                  DEFAULT NULL,
    `extra_data`            TEXT                                                                  DEFAULT NULL,
    `duration`              INT(11)                                                               DEFAULT '120',
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    AUTO_INCREMENT = 20
    DEFAULT CHARSET = utf8;

DROP TABLE IF EXISTS `service_configs`;

CREATE TABLE IF NOT EXISTS `integrations` (
    `id`         BIGINT(18)   UNSIGNED NOT NULL AUTO_INCREMENT,
    `is_active`  CHAR(1)      DEFAULT '1',
    `company_id` INT(10)      DEFAULT NULL,
    `service_id` VARCHAR(50)  NOT NULL,
    `name`       VARCHAR(255) NOT NULL,
    `config`     LONGTEXT     DEFAULT NULL,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    AUTO_INCREMENT = 20
    DEFAULT CHARSET = utf8;

/**
 * Extended the ACL
 */
--
-- Table structure for table `roles`
--
DROP PROCEDURE IF EXISTS add_column_to_role_table;
DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE add_column_to_role_table()
    BEGIN
        DECLARE colName TEXT;

        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps' AND table_name = 'roles' AND column_name = 'role_type';

        IF colName IS NULL
        THEN
            ALTER TABLE `roles`
                ADD COLUMN `role_type` CHAR(1) DEFAULT 'u'
                AFTER `role_name`;
        END IF;

        -- Only admin
        REPLACE INTO user_roles (id, user_id, role_id) VALUES (1, 1, 1);

        /** Update the data */
        #     UPDATE `roles` SET role_type = 's' where id = 1;
        #     UPDATE `roles` SET role_type = 'u' where id = 3;
        #     UPDATE `roles` SET role_type = 'a' where id = 2;

        REPLACE INTO `roles` (`id`, `role_name`, `role_type`)
        VALUES (1, 'Super Admin', 's'), (2, 'Admin', 'a'), (3, 'User', 'u');

    END$$
DELIMITER ;
CALL add_column_to_role_table;
DROP PROCEDURE add_column_to_role_table;


/**
* Add column ``token` varchar(255) DEFAULT NULL,` for the clusters table
*/
DROP PROCEDURE IF EXISTS add_column_to_clusters_table;
DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE add_column_to_clusters_table()
    BEGIN
        DECLARE colName TEXT;

        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps' AND table_name = 'clusters' AND column_name = 'token';

        IF colName IS NULL
        THEN
            ALTER TABLE `clusters`
                ADD COLUMN `token` VARCHAR(255) DEFAULT NULL
                AFTER `ip`;
        END IF;

    END$$
DELIMITER ;
CALL add_column_to_clusters_table;
DROP PROCEDURE add_column_to_clusters_table;

/**
 * Extended the ACL
 */
--
-- Table structure for table `roles`
--
DROP PROCEDURE IF EXISTS add_column_to_users_table;
DELIMITER $$

CREATE DEFINER = CURRENT_USER PROCEDURE add_column_to_users_table()
    BEGIN
        DECLARE colName TEXT;

        SELECT column_name
        INTO colName
        FROM information_schema.columns
        WHERE table_schema = 'dcps'
              AND table_name = 'users'
              AND column_name = 'timezone';

        IF colName IS NULL
        THEN
            ALTER TABLE `users`
                ADD COLUMN `timezone` VARCHAR(100) DEFAULT ''
                AFTER `name`;
        END IF;

    END$$
DELIMITER ;
CALL add_column_to_users_table;
DROP PROCEDURE add_column_to_users_table;

--
-- Extend clusters table bt a new enum type
--
DROP PROCEDURE IF EXISTS extend_cluster_type_clus_1609;
DELIMITER $$
CREATE DEFINER = CURRENT_USER PROCEDURE extend_cluster_type_clus_1609()
    BEGIN
        ALTER TABLE `clusters` CHANGE COLUMN
            `type` `type` ENUM(
                'mysqlcluster',
                'replication',
                'galera',
                'mongodb',
                'mysql_single',
                'postgresql_single',
                'group_replication'
            ) NOT NULL;
    END$$
DELIMITER ;
CALL extend_cluster_type_clus_1609;
DROP PROCEDURE extend_cluster_type_clus_1609;
