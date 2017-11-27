CREATE DATABASE IF NOT EXISTS cmon CHARACTER SET utf8;
USE cmon;

/* For upgrading from older schemas, where had
 * this error this has to be enabled: */
SET SQL_MODE='ALLOW_INVALID_DATES';

DROP PROCEDURE IF EXISTS sp_cmon_deletehost;
DROP PROCEDURE IF EXISTS sp_cmon_deletemysql;
DROP PROCEDURE IF EXISTS sp_cmon_movehost;
DROP PROCEDURE IF EXISTS sp_cmon_movemysql;
DROP PROCEDURE IF EXISTS sp_cmon_deletecluster;
DROP PROCEDURE IF EXISTS sp_cmon_deletecpu;
DROP PROCEDURE IF EXISTS sp_cmon_delete_mongodb_cluster_stats_history;
DROP PROCEDURE IF EXISTS sp_cmon_delete_mongodb_stats_history;
DROP PROCEDURE IF EXISTS sp_cmon_delete_mongodb_rs_stats_history;
DROP PROCEDURE IF EXISTS sp_cmon_delete_mongodb_history;
DROP PROCEDURE IF EXISTS sp_cmon_purge_mongodb_history;
DROP EVENT IF EXISTS e_purge_mongodb_history;
DROP PROCEDURE IF EXISTS sp_delete_chunks;
DROP PROCEDURE IF EXISTS sp_delete_where;
DROP PROCEDURE IF EXISTS sp_cmon_deletenet;
DROP PROCEDURE IF EXISTS sp_cmon_deletedisk;
DROP PROCEDURE IF EXISTS sp_cmon_deleteram;
DROP PROCEDURE IF EXISTS sp_cmon_deleteresources;
DROP PROCEDURE IF EXISTS sp_cmon_deleteresources_all;
DROP PROCEDURE IF EXISTS sp_cmon_purge_history;
DROP EVENT IF EXISTS e_clear_tables;
DROP TABLE IF EXISTS `alarm`;

CREATE TABLE IF NOT EXISTS  `simple_alarm` (
  `alarm_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  `id` bigint unsigned  NOT NULL DEFAULT '0',
  `component`  enum('Network','CmonDatabase','Mail','Cluster','ClusterConfiguration','ClusterRecovery','Node', 'Host', 'DbHealth','DbPerformance' ,'SoftwareInstallation','Backup','Unknown') DEFAULT 'Unknown',
  `alarm_type` int(11) NOT NULL DEFAULT '0',
  `alarm_name` varchar(256) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `alarm_cnt` int(11) NOT NULL DEFAULT '0',
  `email_sent` int(11) NOT NULL DEFAULT '0',
  `snmp_sent` int(11) NOT NULL DEFAULT '0',
  `message` varchar(4096) CHARACTER SET utf8 DEFAULT '',
  `recommendation` varchar(1024) CHARACTER SET utf8 DEFAULT '',
  `severity` enum('WARNING','CRITICAL') DEFAULT 'WARNING',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created` timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  `ignored` int(11) DEFAULT '0',
  `hostid` int(11) DEFAULT '0',
  `nodeid` int(11) DEFAULT '0',
  PRIMARY KEY (`alarm_id`),
  UNIQUE KEY `cid` (`cid`,`hostid`,`nodeid`,`alarm_type`),
  KEY `ix_hostid` (cid,hostid, nodeid, alarm_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!50503 ALTER TABLE simple_alarm MODIFY COLUMN `alarm_name` VARCHAR(256) CHARACTER SET utf8mb4 NOT NULL DEFAULT ''*/;
/*!50503 ALTER TABLE simple_alarm MODIFY COLUMN `message` VARCHAR(4096) CHARACTER SET utf8mb4 DEFAULT ''*/;
/*!50503 ALTER TABLE simple_alarm MODIFY COLUMN `recommendation` VARCHAR(1024) CHARACTER SET utf8 DEFAULT ''*/;

DROP TABLE IF EXISTS `simple_email`;
DROP TABLE IF EXISTS `db_notifications`;
DROP TABLE IF EXISTS `alarm_hosts`;
DROP TABLE IF EXISTS `alarm_log`;

CREATE TABLE IF NOT EXISTS `backup` (
  `cid` int(11) NOT NULL DEFAULT '0',
  `backupid` int(11) NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `master_nodeid` int(11) NOT NULL DEFAULT '0',
  `mgm_nodeid` int(11) NOT NULL DEFAULT '0',
  `status` char(255) DEFAULT NULL,
  `error` int(11) NOT NULL DEFAULT '0',
  `start_gci` int(11) DEFAULT '0',
  `stop_gci` int(11) DEFAULT '0',
  `records` bigint(20) unsigned DEFAULT '0',
  `log_records` bigint(20) unsigned DEFAULT '0',
  `bytes` bigint(20) unsigned DEFAULT '0',
  `log_bytes` bigint(20) unsigned DEFAULT '0',
  `directory` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`backupid`),
  KEY `report_ts` (`report_ts`),
  KEY `backup_cid_status` (`cid`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `backup_log` (
  `cid` int(11) NOT NULL DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `backupid` int(11) NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` char(255) DEFAULT NULL,
  `error` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `report_ts` (`report_ts`),
  KEY `backupid` (`backupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `backup_schedule` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  /* these will be deprecated */
  `weekday` int(11) DEFAULT '1',
  `exectime` varchar(8) DEFAULT '',
  /* the new CRON like format */
  `schedule` varchar(255) DEFAULT '',
  `last_exec` datetime DEFAULT NULL ,
  `backupdir` varchar(255) DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `backup_method` enum('ndb','mysqldump','xtrabackupfull','xtrabackupincr','mongodump','pg_dump','mysqlpump') DEFAULT 'mysqldump',
  `backup_host` varchar(255) DEFAULT 'none',
  `cc_storage` tinyint(4) NOT NULL DEFAULT '0',
  `json_command` varchar(1024) DEFAULT NULL,
  `enabled` TINYINT NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`,`cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;

CREATE TABLE IF NOT EXISTS `cluster` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `connectstring` char(255) DEFAULT NULL,
  `type` enum('mysqlcluster','replication','galera','mysql_single','mongodb','postgresql_single','group_replication') DEFAULT NULL,
  `name` char(255) CHARACTER SET utf8 DEFAULT NULL,
  `scriptsdir` char(255) DEFAULT NULL,
  `description` char(255) CHARACTER SET utf8 DEFAULT NULL,
  `feature_ts` int(11) DEFAULT '0',
  `deployed_version` int(11) DEFAULT '0',
  `config_version` int(11) DEFAULT '0',
  `config_change` enum('RRM', 'RR','RRI','NONE') DEFAULT 'NONE',
  `process_mgmt` int(11) DEFAULT '0',
  `feature_ndbinfo` int(11) DEFAULT '0',
  `feature_ndbinfo_dp` int(11) DEFAULT '0',
  `parent_id` int(11) NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `type_cid` (`type`),
  KEY `report_ts` (`report_ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;

DROP TABLE IF EXISTS `cluster_config`;
/* deprecated table */
    /*    
CREATE TABLE IF NOT EXISTS `cluster_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  `groupid` int(11) NOT NULL DEFAULT '0',
  `variable` char(255) NOT NULL DEFAULT '',
  `grp` char(255) DEFAULT NULL,
  `value` char(255) DEFAULT NULL,
  `version` int(11) NOT NULL DEFAULT '1',
  `filename` varchar(255) DEFAULT NULL,
  `configured` tinyint(4) DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`,`cid`,`variable`),
  KEY `cid` (`cid`,`variable`,`groupid`),
  KEY `cid_2` (`cid`,`version`,`groupid`),
  KEY `cid_3` (`cid`,`filename`,`version`,`groupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;
*/
    
/* deprecated table */    
DROP TABLE IF EXISTS ndb_config;
/*CREATE TABLE IF NOT EXISTS `ndb_config` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `var` varchar(255) NOT NULL DEFAULT '',
  `value` varchar(255) DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`nodeid`,`var`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;
*/
    
/* deprecated table */
DROP TABLE IF EXISTS cluster_configuration;

DROP TABLE IF EXISTS cluster_configuration_templates;
CREATE TABLE IF NOT EXISTS `cluster_configuration_templates` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `crc` int(11) unsigned NOT NULL DEFAULT '0',
  `filename` varchar(255) NOT NULL DEFAULT '',
  `fullpath` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `size` int(11) unsigned DEFAULT '0',
  `status` int(11) unsigned DEFAULT '0',
  `data` text,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`, `filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;


/* deprecated table */
DROP TABLE IF EXISTS `cluster_event_types`;
/*
CREATE TABLE IF NOT EXISTS `cluster_event_types` (
  `event` char(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
*/
DROP TABLE IF EXISTS `collected_logs`;
CREATE TABLE IF NOT EXISTS `collected_logs` (
  `id`        int(11) NOT NULL AUTO_INCREMENT,
  `cid`        int(11) NOT NULL,
  `hostid`     int(11) NOT NULL,
  `hostname`   varchar(64),
  `fileid`     int(11),
  `created`    datetime NOT NULL,
  `ident`      varchar(64),
  `severity`   enum('LOG_EMERG','LOG_ALERT','LOG_CRIT','LOG_ERR','LOG_WARNING','LOG_NOTICE','LOG_INFO','LOG_DEBUG') DEFAULT NULL,
  `component`  enum('Network','CmonDatabase','Mail','Cluster','ClusterConfiguration','ClusterRecovery','Node', 'Host', 'DbHealth','DbPerformance' ,'SoftwareInstallation','Backup','Unknown') DEFAULT 'Unknown',
  `message`    varchar(512),
  `origline`   varchar(8192),
 /* `origline`   text, */
  PRIMARY KEY `total_order` (`id`),
  UNIQUE  KEY `noduplications` (`cid`, `hostid`, `created`, `message`(224)),
  KEY `idx_cid_created` (`cid`, `created`),
  KEY `ix_cid` (`created`,`fileid`,`cid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*DROP TABLE IF EXISTS `component_meta`;*/
CREATE TABLE IF NOT EXISTS `component_meta` (
  `component`  enum('Network','CmonDatabase','Mail','Cluster','ClusterConfiguration','ClusterRecovery','Node', 'Host', 'DbHealth','DbPerformance' ,'SoftwareInstallation','Backup','Unknown') DEFAULT 'Unknown',
  `log_name`   varchar(128),
  `alarm_name` varchar(128),
  `message_name`  varchar(128),
  PRIMARY KEY (`component`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `component_defaults` (
  `component`  enum('Network','CmonDatabase','Mail','Cluster','ClusterConfiguration','ClusterRecovery','Node', 'Host', 'DbHealth','DbPerformance' ,'SoftwareInstallation','Backup','Unknown') DEFAULT 'Unknown',
  `critical` varchar(32),
  `warning`   varchar(32),
  `info`  varchar(32),
  PRIMARY KEY (`component`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `collected_log_files` (
  `id`         int NOT NULL AUTO_INCREMENT,
  `cid`        int(11) NOT NULL,
  `filename`   varchar(255) NOT NULL,
  `enabled`    tinyint NOT NULL DEFAULT '1',
  PRIMARY KEY `id` (`id`),
  UNIQUE KEY (`cid`, `filename`),
  KEY (`cid`, `enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `cluster_log` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `source_nodeid` int(11) NOT NULL DEFAULT '0',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `severity` enum('DEBUG','INFO','WARNING','ERROR','CRITICAL','ALERT') DEFAULT NULL,
  `loglevel` int(11) NOT NULL DEFAULT '0',
  `event` varchar(255) DEFAULT NULL,
  `message` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`,`cid`),
  KEY `cid_ix` (`cid`,`id`),
  KEY `report_ts` (`report_ts`),
  KEY `severity` (`severity`),
  KEY `event` (`event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;

CREATE TABLE IF NOT EXISTS `cluster_severity_types` (
  `severity` char(255) NOT NULL,
  PRIMARY KEY (`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `cluster_state` (
  `id` int(11) NOT NULL DEFAULT '0',
  `status` enum('MGMD_NO_CONTACT','STARTED','NOT_STARTED','DEGRADED','FAILURE','SHUTTING_DOWN','RECOVERING','STARTING','UNKNOWN', 'STOPPED') DEFAULT NULL,
  `previous_status` enum('MGMD_NO_CONTACT','STARTED','NOT_STARTED','DEGRADED','FAILURE','SHUTTING_DOWN','RECOVERING','STARTING','UNKNOWN','STOPPED') DEFAULT NULL,
  `c_restarts` int(11) NOT NULL DEFAULT '0',
  `uptime` bigint(20) DEFAULT '0',
  `downtime` bigint(20) DEFAULT '0',
  `sla_starttime` datetime DEFAULT NULL,
  `sla_started` int(11) DEFAULT '0',
  `mc_lcp_status` varchar(255) DEFAULT '',
  `mc_lcp_time` timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `replication_state` int(11) DEFAULT '0',
  `prev_replication_state` int(11) DEFAULT '0',
  `msg` varchar(512) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `cluster_statistics`;
DROP TABLE IF EXISTS `cluster_statistics_history`;
DROP TRIGGER IF EXISTS ut_cluster_statistics;
DROP TRIGGER IF EXISTS it_cluster_statistics;

DROP TABLE IF EXISTS `cmon_todo`;
DROP TABLE IF EXISTS `cmon_cluster_counters`;


CREATE TABLE IF NOT EXISTS `cmon_cluster_graphs` (
  `cid` int(11) NOT NULL DEFAULT '1',		
  `graphid` int(11) NOT NULL AUTO_INCREMENT,
  `graph` char(64) DEFAULT NULL,
  PRIMARY KEY (`graphid`),
  KEY `graph` (`cid`,`graph`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;


CREATE TABLE IF NOT EXISTS `cmon_configuration` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '0',
  `param` varchar(255) NOT NULL DEFAULT '',
  `value` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`,`param`),
  UNIQUE KEY `cid` (`cid`,`param`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;
/*!50503 ALTER TABLE cmon_configuration MODIFY COLUMN value VARCHAR(255) CHARACTER SET utf8mb4 DEFAULT NULL*/;

DROP TABLE IF EXISTS `cmon_host_log`;
CREATE TABLE IF NOT EXISTS `cmon_host_log` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `hostname` varchar(255) NOT NULL DEFAULT '',
  `filename` varchar(255) NOT NULL DEFAULT '',
  `jobid` int(11) NOT NULL DEFAULT '0',
  `result_len` int(11) NOT NULL DEFAULT '0',
  `result` longblob,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `hostid` int(11) DEFAULT NULL,
  `description` varchar(255) DEFAULT '',
  `tag` varchar(255) DEFAULT 'mysql',
  PRIMARY KEY (`cid`,`hostname`,`filename`),
  UNIQUE KEY `ix_cidhostid` (`cid`,`hostid`,`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `cmon_job` (
  `jobid` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  `jobspec` TEXT,
  `properties` TEXT,
  `status_txt` varchar(255) DEFAULT NULL,
  `status` enum('DEFINED','DEQUEUED','RUNNING','RUNNING2','RUNNING3','RUNNING_EXT','SCHEDULED','ABORTED','FINISHED','FAILED') DEFAULT 'DEFINED',
  `exit_code` int(11) DEFAULT '0',
  `checked` int(11) DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `parent_jobid` int(11) DEFAULT '0',
  `user_id` int(11) NOT NULL DEFAULT '0',
  `ip` varchar(20) NOT NULL DEFAULT '127.0.0.1',
  `user_name` varchar(125) NOT NULL DEFAULT 'system',
  PRIMARY KEY (`jobid`,`cid`),
  KEY (`parent_jobid`,`cid`),
  KEY `clusterid` (`cid`,`status`),
  KEY `report_ts` (`cid`,`report_ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;

/* DROP TABLE IF EXISTS `cmon_job_message`; */
CREATE TABLE IF NOT EXISTS `cmon_job_message` (
  `messageid` int(11) NOT NULL AUTO_INCREMENT,
  `jobid` int(11) NOT NULL DEFAULT '0',
  `cid` int(11) NOT NULL DEFAULT '1',
  `message` varchar(16384) DEFAULT NULL,
  `properties` TEXT,
  `exit_code` int(11) DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`messageid`,`jobid`,`cid`),
  KEY `clusterid` (`jobid`,`cid`),
  KEY `report_ts2` (`cid`, `report_ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;

DROP TABLE IF EXISTS `cmon_mysql_counters`;
DROP TABLE IF EXISTS `cmon_mysql_graphs`;
DROP TABLE IF EXISTS `cmon_schema_uploads`;
DROP TABLE IF EXISTS `cmon_status`;

/* to be deprecated - maybe used in UI */ 
CREATE TABLE if not exists `cmon_uploads` (
  `cid` int(11),
  `packageid` int(11) NOT NULL DEFAULT '0',
  `filename` varchar(255) NOT NULL DEFAULT '',
  `path` varchar(255) NOT NULL DEFAULT '',
  `cluster_type` varchar(64) NOT NULL DEFAULT '',
  `version_tag` varchar(64) NOT NULL DEFAULT '',
  `md5sum` varchar(1024) NOT NULL DEFAULT '',
  `filesize` int(11) NOT NULL DEFAULT '0',
  `selected` int(11) DEFAULT 0,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`packageid`,`filename`),
  KEY `ix_cluster_type` (`cid`, `cluster_type`, `packageid`),
  KEY `version_tag` (`version_tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `cmon_user`;
DROP TABLE IF EXISTS `cpu_info`;
DROP TABLE IF EXISTS cpu_stats;
DROP TABLE IF EXISTS cpu_stats_history;
DROP TRIGGER IF EXISTS `it_cpu_stats`;
DROP TRIGGER IF EXISTS `ut_cpu_stats`;
DROP TABLE IF EXISTS `database_conf`;

DROP TABLE IF EXISTS `diskdata`;
CREATE TABLE IF NOT EXISTS `diskdata` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `file_name` varchar(4096) NOT NULL DEFAULT '',
  `ts_name` varchar(512) NOT NULL DEFAULT '',
  `type` char(64) NOT NULL DEFAULT '',
  `logfile_group_name` char(64) NOT NULL DEFAULT '',
  `free_extents` bigint(20) unsigned NOT NULL DEFAULT '0',
  `total_extents` bigint(20) unsigned NOT NULL DEFAULT '0',
  `extent_size` bigint(20) unsigned NOT NULL DEFAULT '0',
  `initial_size` bigint(20) unsigned NOT NULL DEFAULT '0',
  `maximum_size` bigint(20) unsigned NOT NULL DEFAULT '0',
  `undo_buffer_size` bigint(20) unsigned NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`nodeid`,`file_name`(128))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TRIGGER IF EXISTS `it_diskdata`;
DROP TRIGGER IF EXISTS `ut_diskdata`;
DROP TABLE IF EXISTS `diskdata_history`;

DROP TABLE IF EXISTS `disk_stats`;
DROP TRIGGER IF EXISTS `it_disk_stats`;
DROP TRIGGER IF EXISTS `ut_disk_stats`;
DROP TABLE IF EXISTS `disk_stats_history`;

CREATE TABLE IF NOT EXISTS `email_notification` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '0',
  `fname` varchar(255) DEFAULT NULL,
  `lname` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `groupid` int(11) NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_email` (`email`),
  KEY `ix_fname_email` (`fname`,`email`),
  KEY `ix_cid` (`cid`,`groupid`),
  KEY `ix_lname_email` (`lname`,`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*DROP TABLE IF EXISTS `outgoing_messages`;*/
CREATE TABLE IF NOT EXISTS outgoing_messages (
  `message_id`  bigint unsigned NOT NULL AUTO_INCREMENT,
  `cid`         int(11) NOT NULL,
  `status`      enum('Created','Failing','Failed','Sent') DEFAULT 'Created',
  `component`  enum('Network','CmonDatabase','Mail','Cluster','ClusterConfiguration','ClusterRecovery','Node', 'Host', 'DbHealth','DbPerformance' ,'SoftwareInstallation','Backup','Unknown') DEFAULT 'Unknown',
  `subject`     varchar(512) CHARACTER SET utf8 DEFAULT NULL,
  `body`        text CHARACTER SET utf8,
  `created`     timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `retry_time`  timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  `retry_count` int(11) NOT NULL DEFAULT '0',
  KEY (`created`,`status`),
  KEY (cid,status,created),
  PRIMARY KEY (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!50503 ALTER TABLE outgoing_messages MODIFY COLUMN subject VARCHAR(512) CHARACTER SET utf8mb4 DEFAULT NULL*/;
/*!50503 ALTER TABLE outgoing_messages MODIFY COLUMN body TEXT CHARACTER SET utf8mb4*/;

CREATE TABLE IF NOT EXISTS outgoing_digest_messages (
  `id`  bigint unsigned NOT NULL AUTO_INCREMENT,
  `cid`        int(11) NOT NULL,
  `created`    timestamp NOT NULL,
  `recipient`  varchar(255) NOT NULL,
  `subject`    varchar(512) CHARACTER SET utf8 DEFAULT NULL,
  `body`       text CHARACTER SET utf8,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!50503 ALTER TABLE outgoing_digest_messages MODIFY COLUMN subject VARCHAR(512) CHARACTER SET utf8mb4 DEFAULT NULL*/;
/*!50503 ALTER TABLE outgoing_digest_messages MODIFY COLUMN body TEXT CHARACTER SET utf8mb4*/;

CREATE TABLE IF NOT EXISTS message_filters (
  `cid`           int(11) NOT NULL,
  `component`  enum('Network','CmonDatabase','Mail','Cluster','ClusterConfiguration','ClusterRecovery','Node', 'Host', 'DbHealth','DbPerformance' ,'SoftwareInstallation','Backup','Unknown') DEFAULT 'Unknown',
  `recipient`     varchar(255) NOT NULL,
  `delivery_type` enum('Ignore','Deliver','Digest'),
  `severity` enum('INFO','WARNING','CRITICAL') DEFAULT 'INFO',
  KEY `ix_recipient` (`cid`,`component`,`recipient`),
  PRIMARY KEY (`cid`, `component`, `severity`, `recipient`),
  UNIQUE KEY (`cid`, `component`, `severity`, `recipient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS message_recipients (
  `cid`           int(11) NOT NULL,
  `recipient`     varchar(255) NOT NULL,
  `state`         enum('Enabled','Disabled') DEFAULT 'Enabled',
  `time_zone`     int(11) NOT NULL DEFAULT '0',
  `digest_hour`   int(11) NOT NULL DEFAULT '7',
  `daily_limit`   int(11) NOT NULL DEFAULT '-1',
  `owner`         varchar(255) NOT NULL DEFAULT 'admin',
  PRIMARY KEY `noduplications` (`cid`, `recipient`),
  KEY `owner` (`cid`, `owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE  IF NOT EXISTS `hosts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  `hostname` varchar(255) NOT NULL DEFAULT '',
  `ping_status` int(11) NOT NULL DEFAULT '0',
  `ping_time` int(11) NOT NULL DEFAULT '0',
  `ip` varchar(255) NOT NULL DEFAULT '',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `msg` varchar(255) NOT NULL DEFAULT '',
  `cmon_version` varchar(16) DEFAULT NULL,
  `cmon_status` timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  `wall_clock_time` bigint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`,`cid`),
  UNIQUE KEY `hostname` (`hostname`,`cid`),
  UNIQUE KEY `ip` (`ip`,`cid`),
  UNIQUE KEY `hostname_ip` (`hostname`,`ip`,`cid`),
  KEY `cid` (`cid`,`ping_time`,`ping_status`)
) ENGINE=InnoDB;




CREATE TABLE IF NOT EXISTS `mailserver` (
  `username` varchar(64) DEFAULT NULL,
  `password` varchar(128) DEFAULT NULL,
  `base64_username` varchar(255) DEFAULT NULL,
  `from_email` varchar(128) DEFAULT NULL,
  `base64_password` varchar(255) DEFAULT NULL,
  `smtpserver` varchar(64) NOT NULL DEFAULT '',
  `smtpport` int(11) DEFAULT NULL,
  `use_ssl` int(11) DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`smtpserver`),
  KEY `report_ts` (`report_ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF  EXISTS `memory_usage`;
DROP TRIGGER IF EXISTS `it_memory_usage`;
DROP TRIGGER IF EXISTS `ut_memory_usage`;
DROP TABLE IF EXISTS `memory_usage_history`;

DROP TABLE IF EXISTS mysql_explains;
CREATE TABLE IF NOT EXISTS `mysql_explains` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `qid` bigint(20) unsigned NOT NULL DEFAULT '0',
  `partid` int(11) NOT NULL DEFAULT '0',
  `xid` int(11) NOT NULL DEFAULT '0',
  `xpartitions` varchar(64) NOT NULL DEFAULT '',
  `xselect_type` varchar(64) NOT NULL DEFAULT '',
  `xtable` varchar(64) NOT NULL DEFAULT '',
  `xtype` varchar(64) NOT NULL DEFAULT '',
  `xpossible_keys` varchar(255) NOT NULL DEFAULT '',
  `xkey` varchar(128) NOT NULL DEFAULT '',
  `xkey_len` int(11) NOT NULL DEFAULT '0',
  `xref` varchar(128) NOT NULL DEFAULT '',
  `xrows` int(11) NOT NULL DEFAULT '0',
  `xfiltered` varchar(8) NOT NULL DEFAULT '',
  `xextra` varchar(255) NOT NULL DEFAULT '',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`qid`,`partid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `mysql_global_statistics`;
DROP TRIGGER IF EXISTS `it_mysql_global_statistics`;
DROP TRIGGER IF EXISTS `ut_mysql_global_statistics`;
DROP TABLE IF EXISTS `mysql_global_statistics_history`;
DROP TABLE IF EXISTS `mysql_global_statistics_hour`;

/*DROP TABLE IF EXISTS `mysql_statistics_history`;*/
CREATE TABLE IF NOT EXISTS `mysql_statistics_history` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `id` int(11) NOT NULL DEFAULT '0',
  `var` varchar(64) NOT NULL DEFAULT '',
  `value` bigint(20) unsigned DEFAULT '0',
  `report_ts` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`cid`,`id`,`var`,`report_ts`),
  KEY(`report_ts`, `cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `mysql_statistics_hour`;
DROP TABLE IF EXISTS `mysql_master_status`;

CREATE TABLE IF NOT EXISTS `mysql_performance_meta` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `username` varchar(255) NOT NULL DEFAULT '',
  `password` varchar(255) DEFAULT '',
  `db` varchar(255) DEFAULT 'test',
  `socket` varchar(255) DEFAULT '',
  `status` varchar(255) DEFAULT '<empty>',
  `threads` int(11) DEFAULT '1',
  `runtime` int(11) DEFAULT '10',
  `periodicity` int(11) DEFAULT '300',
  PRIMARY KEY (`cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;





CREATE TABLE IF NOT EXISTS `mysql_performance_probes` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `probeid` int(11) NOT NULL DEFAULT '0',
  `err_no` int(11) NOT NULL DEFAULT '0',
  `active` int(11) NOT NULL DEFAULT '0',
  `statement` blob ,
  `err_msg` varchar(1024) DEFAULT '',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`probeid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;





CREATE TABLE IF NOT EXISTS `mysql_performance_results` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  `hostid` int(11) NOT NULL DEFAULT '0',
  `probeid` int(11) NOT NULL DEFAULT '0',
  `threads` int(11) NOT NULL DEFAULT '0',
  `connpool` int(11) NOT NULL DEFAULT '0',
  `exec_count` int(11) NOT NULL DEFAULT '0',
  `rows` int(11) NOT NULL DEFAULT '0',
  `avg` int(11) NOT NULL DEFAULT '0',
  `stdev_avg` int(11) NOT NULL DEFAULT '0',
  `max` int(11) NOT NULL DEFAULT '0',
  `pct` int(11) NOT NULL DEFAULT '0',
  `tps` int(11) NOT NULL DEFAULT '0',
  `stdev_tps` int(11) NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`,`cid`,`hostid`,`probeid`),
  KEY `cid` (`cid`,`hostid`,`probeid`,`report_ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;




DROP TABLE IF EXISTS `mysql_processlist`;
CREATE TABLE IF NOT EXISTS `mysql_processlist` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `id` int(11) NOT NULL DEFAULT '0',
  `qid` bigint(20) NOT NULL DEFAULT '0',
  `user` varchar(255) NOT NULL DEFAULT '',
  `host` varchar(64) NOT NULL DEFAULT '',
  `db` varchar(64) NOT NULL DEFAULT '',
  `command` varchar(16) NOT NULL DEFAULT '',
  `time` int(11) NOT NULL DEFAULT '0',
  `state` varchar(128) NOT NULL DEFAULT '',
  `info` longtext,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`id`,`qid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `mysql_repl_bw`;
DROP TABLE IF EXISTS `mysql_repl_link`;
DROP TABLE IF EXISTS `mysql_replication_recovery`;

CREATE TABLE IF NOT EXISTS `mysql_server` (
  `id` int(11) NOT NULL DEFAULT '0', 
  `cid` int(11) NOT NULL DEFAULT '0', 
  `serverid` int(11) NOT NULL DEFAULT '0',
  `nodeid` int(11) DEFAULT '0',
  `hostname` varchar(255) NOT NULL DEFAULT '',
  `username` varchar(255) NOT NULL DEFAULT '',
  `password` varchar(255) NOT NULL DEFAULT '',
  `version` varchar(255) NOT NULL DEFAULT 'Unknown',
  `role` enum('none','master','slave','multi') DEFAULT 'none',
  `port` int(11) NOT NULL DEFAULT '3306',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `connected` tinyint(4) NOT NULL DEFAULT '0',
  `msg` varchar(255) NOT NULL DEFAULT '', 
  `failures` int(11) DEFAULT '0',
  `status` int(11) DEFAULT '0',
  `progress_acct` bigint(20) NOT NULL DEFAULT '0',	
  `affinity` bigint(20) NOT NULL DEFAULT '0',	
  `server_uptime` bigint(20) NOT NULL DEFAULT '0',	
  PRIMARY KEY (`id`,`cid`,`serverid`),
  UNIQUE KEY `hostname` (`hostname`,`port`),
  KEY `cid` (`cid`,`serverid`),
  KEY `cid2` (`cid`,`nodeid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `mysql_slave_status`;

DROP TABLE IF EXISTS mysql_slow_queries;
CREATE TABLE IF NOT EXISTS `mysql_slow_queries` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `id` int(11) NOT NULL DEFAULT '0',
  `qid` bigint(20) unsigned NOT NULL DEFAULT '0',
  `cnt` bigint(20) unsigned NOT NULL DEFAULT '0',
  `user` varchar(64) NOT NULL DEFAULT '',
  `host` varchar(64) NOT NULL DEFAULT '',
  `db` varchar(64) NOT NULL DEFAULT '',
  `command` varchar(16) DEFAULT '',
  `time` double DEFAULT '0',
  `state` varchar(16) DEFAULT '',
  `info` longtext ,
  `canonical` longtext ,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lock_time` double DEFAULT '0',
  `rows_sent` int(10) unsigned DEFAULT '0',
  `rows_examined` int(10) unsigned DEFAULT '0',
  `total_rows_sent` bigint(20) unsigned DEFAULT '0',
  `total_rows_examined` bigint(20) unsigned DEFAULT '0',
  `total_time` double DEFAULT '0',
  `total_lock_time` double DEFAULT '0',
  `avg_query_time` bigint(20) unsigned DEFAULT '0',
  `max_query_time` bigint(20) unsigned DEFAULT '0',
  `min_query_time` bigint(20) unsigned DEFAULT '0',
  `stdev` double DEFAULT '0',
  `variance` bigint(20) unsigned DEFAULT '0',
  `sum_created_tmp_tables` bigint(20) unsigned DEFAULT '0',
  `sum_created_tmp_disk_tables` bigint(20) unsigned DEFAULT '0',
  `sum_no_index_used` bigint(20) DEFAULT '-1',
  `sum_no_good_index_used` bigint(20) DEFAULT '-1',    
  PRIMARY KEY (`cid`,`id`,`qid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;


DROP TABLE IF EXISTS mysql_query_histogram;
CREATE TABLE IF NOT EXISTS `mysql_query_histogram` ( 
  `id` int(11) NOT NULL AUTO_INCREMENT,    
  `cid` int(11) NOT NULL DEFAULT '1',
  `hostid` int(11) NOT NULL DEFAULT '0',
  `qid` bigint(20) unsigned NOT NULL DEFAULT '0',
  `ts` bigint(20) unsigned NOT NULL DEFAULT '0',
  `query_time` bigint(20) unsigned DEFAULT '0',
  `lock_time` bigint(20) unsigned DEFAULT '0',
  `avg_query_time` bigint(20) unsigned DEFAULT '0',
  `max_query_time` bigint(20) unsigned DEFAULT '0',
  `min_query_time` bigint(20) unsigned DEFAULT '0',
  `stdev` double DEFAULT '0',
  `ema` bigint(20) unsigned DEFAULT '0',
  `ems` bigint(20) unsigned DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY (`cid`,`hostid`, `qid`, `ts`),
  KEY (`cid`, `ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;

DROP TABLE IF EXISTS mysql_statistics;
CREATE TABLE IF NOT EXISTS `mysql_statistics` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `id` int(11) NOT NULL DEFAULT '0',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `var` varchar(64) NOT NULL DEFAULT '',
  `value` varchar(1024) DEFAULT '0',
  `value1` varchar(1024) DEFAULT '0',
  `value2` varchar(1024) DEFAULT '0',
  `value3` varchar(1024) DEFAULT '0',
  `report_ts` bigint(20) NOT NULL DEFAULT '0',
  `report_ts1` bigint(20) NOT NULL DEFAULT '0',
  `report_ts2` timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  `report_ts3` timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  PRIMARY KEY (`cid`,`id`,`var`),
  KEY `id` (`id`,`var`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*DROP TABLE IF EXISTS mysql_statistics_tm;*/
CREATE TABLE IF NOT EXISTS `mysql_statistics_tm` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `sampleid` bigint(20) unsigned DEFAULT '0',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `var` varchar(64) NOT NULL DEFAULT '',
  `value` varchar(64) DEFAULT '0',
  `report_ts` bigint(20) NOT NULL DEFAULT '0',
  PRIMARY KEY (`cid`,`sampleid`,`nodeid`,`var`),
  KEY `report_ts` (`cid`,`report_ts`, `nodeid`),
  KEY `report_ts2` (`report_ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `mysql_innodb_status`;
DROP TRIGGER IF EXISTS `it_mysql_statistics`;
DROP TRIGGER IF EXISTS `ut_mysql_statistics`;
DROP TABLE IF EXISTS `mysql_variables`;
DROP TABLE IF EXISTS `ndbinfo_diskpagebuffer`;
DROP TABLE IF EXISTS `ndbinfo_logbuffers`;
DROP TRIGGER IF EXISTS `it_ndbinfo_logbuffers`;
DROP TRIGGER IF EXISTS `ut_ndbinfo_logbuffers`;
DROP TABLE IF EXISTS `ndbinfo_logbuffers_history`;
DROP TABLE IF EXISTS `ndbinfo_logspaces`;
DROP TRIGGER IF EXISTS `it_ndbinfo_logspaces`;
DROP TRIGGER IF EXISTS `ut_ndbinfo_logspaces`;
DROP TABLE IF EXISTS `ndbinfo_logspaces_history`;
DROP TABLE IF EXISTS `net_stats`;
DROP TRIGGER IF EXISTS `it_net_stats`;
DROP TRIGGER IF EXISTS `ut_net_stats`;
DROP TABLE IF EXISTS `net_stats_history`;

CREATE TABLE IF NOT EXISTS `node_state` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `status` enum('STARTED','NOT_STARTED','SINGLEUSER','RESUME','RESTARTING','SHUTTING_DOWN','NO_CONTACT','STARTING','UNKNOWN','CONNECTED','DISCONNECTED') DEFAULT NULL,
  `node_type` enum('NDBD','API','NDB_MGMD') DEFAULT NULL,
  `nodegroup` int(11) DEFAULT NULL,
  `host` varchar(32) DEFAULT NULL,
  `version` varchar(64) DEFAULT NULL,
  `disconnects` int(11) DEFAULT '0',
  `start_phase` int(11) DEFAULT '0',
  `uptime` int(11) DEFAULT '0',
  `failed_restarts` int(11) DEFAULT '0',
  `startok` int(11) DEFAULT '0',
  /* For convenience. */
  `hostid` int(11) DEFAULT '0',
  `start_mode` enum('NR','INR') DEFAULT 'NR',
  /* Unused field. */
  `last_disconnect` datetime DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`nodeid`),
  KEY `node_type` (`node_type`,`nodeid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TRIGGER IF EXISTS `it_node_statistics`;
DROP TRIGGER IF EXISTS `ut_node_statistics`;
DROP TABLE IF EXISTS `node_statistics`;
DROP TABLE IF EXISTS `node_statistics_history`;

DROP TABLE  IF EXISTS `processes`;

CREATE TABLE  IF NOT EXISTS `processes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  `hid` int(11) NOT NULL DEFAULT '0',
  `nodeid` int(11) DEFAULT '0',
  `process` varchar(255) NOT NULL DEFAULT '',
  `exec_cmd` varchar(255) NOT NULL DEFAULT '',
  `pidfile` varchar(255) NOT NULL DEFAULT '',
  `pgrep_expr` varchar(255) DEFAULT '',
  `failed_restarts` int(11) DEFAULT '0',
  `status` int(11) DEFAULT '0',
  `active` tinyint(11) DEFAULT '1',
  `custom` tinyint(11) DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `msg` varchar(255) DEFAULT '',
  PRIMARY KEY (`id`,`cid`),
  UNIQUE KEY `cid` (`cid`,`hid`,`process`,`pidfile`),
  KEY (`nodeid`,`cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `ram_stats`;
DROP TRIGGER IF EXISTS `it_ram_stats`;
DROP TRIGGER IF EXISTS `ut_ram_stats`;
DROP TABLE IF EXISTS `ram_stats_history`;

CREATE TABLE IF NOT EXISTS `restore` (
  `cid` int(11) NOT NULL DEFAULT '0',
  `backupid` int(11) NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `master_nodeid` int(11) NOT NULL DEFAULT '0',
  `ndb_nodeid` int(11) NOT NULL DEFAULT '0',
  `status` varchar(255) DEFAULT NULL,
  `error` int(11) NOT NULL DEFAULT '0',
  `records` bigint(20) unsigned DEFAULT '0',
  `log_records` bigint(20) unsigned DEFAULT '0',
  `bytes` bigint(20) unsigned DEFAULT '0',
  `log_bytes` bigint(20) unsigned DEFAULT '0',
  `n_tables` int(10) unsigned DEFAULT '0',
  `n_tablespaces` int(10) unsigned DEFAULT '0',
  `n_logfilegroups` int(10) unsigned DEFAULT '0',
  `n_datafiles` int(10) unsigned DEFAULT '0',
  `n_undofiles` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`backupid`,`ndb_nodeid`),
  KEY `report_ts` (`report_ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;





CREATE TABLE IF NOT EXISTS `restore_log` (
  `cid` int(11) NOT NULL DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `backupid` int(11) NOT NULL DEFAULT '0',
  `master_nodeid` int(11) NOT NULL DEFAULT '0',
  `mgm_nodeid` int(11) NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` varchar(255) DEFAULT NULL,
  `error` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `report_ts` (`report_ts`),
  KEY `backupid` (`backupid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8  ;


DROP TABLE IF EXISTS `schema_object`;

CREATE TABLE IF NOT EXISTS `license` (
  `email` char(255) NOT NULL DEFAULT '',
  `company` char(255) NOT NULL DEFAULT '',
  `exp_date` char(255) DEFAULT NULL,
  `lickey` char(255)  DEFAULT NULL,
  PRIMARY KEY (`email`,`company`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8  ;

/* cmonapi (Frontend) uses this */
CREATE TABLE IF NOT EXISTS `cmon_mysql_users` (
  `userid` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) DEFAULT NULL,
  `cmd` varchar(16) DEFAULT NULL,
  `user` varchar(128) DEFAULT NULL,
  `hostname` varchar(128) DEFAULT NULL,
  `password` varchar(128) DEFAULT NULL,
  `success` varchar(2048) DEFAULT NULL,
  `failed` varchar(2048) DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cmdlong` varchar(255) DEFAULT '',
  `realcmd` varchar(255) DEFAULT '',
  `dropped` int(11) DEFAULT '0',
  PRIMARY KEY (`userid`),
  UNIQUE KEY `cid` (`cid`,`cmd`,`user`,`hostname`,`password`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8  ;

/* cmonapi (Frontend) uses this */
CREATE TABLE IF NOT EXISTS `cmon_mysql_grants` (
  `grantid` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '0',
  `userhost` varchar(260) DEFAULT NULL,
  `user` varchar(260) DEFAULT NULL,
  `host` varchar(260) DEFAULT NULL,
  `privlist` varchar(1024) DEFAULT NULL,
  `privlist_crc` int(11) unsigned DEFAULT NULL,
  `db` varchar(128) DEFAULT NULL,
  `success` varchar(2048) DEFAULT NULL,
  `failed` varchar(2048) DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `realcmd` varchar(1024) DEFAULT '',
  `dropped` int(11) DEFAULT '0',
  PRIMARY KEY (`grantid`,`cid`),
  UNIQUE KEY `privlist_crc` (`privlist_crc`,`db`,`userhost`),
  KEY `cid` (`cid`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `cmon_mysql_manual_grants`;
DROP TABLE IF EXISTS cmon_log;
DROP TABLE IF EXISTS `cmon_local_mysql_job`;

CREATE TABLE IF NOT EXISTS `cmon_sw_package` (
  `cid` int(11) NOT NULL,
  `packageid` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `rpm` int(11) DEFAULT 0,
  `selected` integer default 0,
  PRIMARY KEY (`packageid`,`cid`),
  UNIQUE KEY (`cid`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*DROP TABLE IF EXISTS `top`; */
CREATE TABLE IF NOT EXISTS `top` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `hostid` int(11) NOT NULL DEFAULT '0',
  `processid` int(11) NOT NULL DEFAULT '0',
  `user` varchar(64) DEFAULT NULL,
  `priority` int(11) NOT NULL DEFAULT '0',
  `nice` bigint  NOT NULL DEFAULT '0',
  `virt` varchar(16) DEFAULT NULL,
  `res` varchar(16) DEFAULT NULL,
  `shr` varchar(16) DEFAULT NULL,
  `state` varchar(4) DEFAULT NULL,
  `cpu` float NOT NULL  DEFAULT '0',
  `mem` float NOT NULL  DEFAULT '0',
  `time` varchar(32) DEFAULT NULL,
  `command` varchar(64) DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`hostid`,`processid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE  IF NOT EXISTS `galera_status` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `hostid` int(11) NOT NULL  DEFAULT '0',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `var` varchar(64) NOT NULL DEFAULT '' ,
  `value` bigint(20) unsigned DEFAULT '0',
  `value1` bigint(20) unsigned DEFAULT '0',
  `value2` bigint(20) unsigned DEFAULT '0',
  `value3` bigint(20) unsigned DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `report_ts1` timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  `report_ts2` timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  `report_ts3` timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  `value_txt` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`cid`,`hostid`,`var`),
  KEY (`cid`,`nodeid`,`var`),
  KEY `id` (`hostid`,`var`)
) ENGINE=InnoDB ;


DROP TABLE IF EXISTS `galera_status_history`;
DROP TRIGGER IF EXISTS `it_galera_status`;
DROP TRIGGER IF EXISTS `ut_galera_status`;

CREATE TABLE IF NOT EXISTS `mysql_backup` (
  `backupid` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  `storage_host` varchar(255) DEFAULT NULL,
  `hostname` varchar(255) DEFAULT NULL,
  `mysql_type` enum('mysql','galera','postgresql','mongodb') DEFAULT NULL,
  `directory` varchar(255) DEFAULT '',
  `filename` varchar(255) DEFAULT '',
  `size` bigint(20) DEFAULT '0',
  `error` int(11) DEFAULT '0',
  `status` enum('completed','failed','running','pending') DEFAULT 'pending',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `backup_type` enum('full','incremental') DEFAULT 'full',
  `lsn` bigint(20) DEFAULT '0',
  `parentid` int(11) NOT NULL DEFAULT '0',
  `backup_method` enum('xtrabackup','mysqldump', 'pg_dump', 'mongodump', 'mongodb-consistent-backup','mysqlpump') DEFAULT 'mysqldump',
  `md5sum` varchar(255) DEFAULT '',
  `cmdline` varchar(512) DEFAULT '',
  `logfile` longtext ,
  `cc_storage` tinyint(4) DEFAULT '0',
  `compressed` tinyint(4) DEFAULT '1',
  `db_name` varchar(255) DEFAULT 'ALL',
  PRIMARY KEY (`backupid`,`cid`),
  KEY `cid` (`cid`,`report_ts`),
  KEY `cid_2` (`cid`,`mysql_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* DROP TABLE IF EXISTS `backup_records`; */
CREATE TABLE IF NOT EXISTS `backup_records` (
  `id`          int(11) NOT NULL AUTO_INCREMENT,
  `cid`         int(11) NOT NULL DEFAULT '0',
  `status`      enum('completed','failed','running','pending') DEFAULT 'pending',
  `created`     timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `properties`  TEXT,
  `retention`   int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`, `cid`),
  KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `mysql_advisor`;
CREATE TABLE IF NOT EXISTS `mysql_advisor` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `module` varchar(32) DEFAULT NULL DEFAULT '',
  `rule_name` varchar(64) NOT NULL DEFAULT '',
  `advise` varchar(512) DEFAULT NULL,
  `value` bigint(20) DEFAULT '0',
  `warn` bigint(20) DEFAULT '0',
  `crit` bigint(20) DEFAULT '0',
  `status` int(11) DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`nodeid`,`rule_name`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `mysql_table_advisor`;
CREATE TABLE IF NOT EXISTS `mysql_table_advisor` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `xdb` varchar(64) NOT NULL DEFAULT '',
  `tbl` varchar(64) NOT NULL DEFAULT '',
  `xengine` varchar(64) DEFAULT NULL,	
  `nopk` int(11) NOT NULL DEFAULT '0',
  `ftidx` int(11) NOT NULL DEFAULT '0',
  `gsidx` int(11) NOT NULL DEFAULT '0',
  `alter_stmt` varchar(512) DEFAULT NULL,	
  `is_myisam` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`cid`,`xdb`,`tbl`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `mysql_duplindex_advisor`;
CREATE TABLE IF NOT EXISTS `mysql_duplindex_advisor` (
  `id` int(11) auto_increment NOT NULL,
  `cid` int(11) NOT NULL DEFAULT '1',
  `xdb` varchar(64) DEFAULT NULL,
  `tbl` varchar(64) DEFAULT NULL,	
  `red_idx` varchar(255) DEFAULT NULL,	
  `cols_in_redidx` varchar(255) DEFAULT NULL,
  `idx` varchar(255) DEFAULT NULL,
  `cols_in_idx` varchar(255) DEFAULT NULL,
  `advise` varchar(512) DEFAULT NULL,
  KEY (`cid`,`xdb`,`tbl`, `red_idx`),
  PRIMARY KEY(id)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS `mysql_selindex_advisor`;
CREATE TABLE IF NOT EXISTS `mysql_selindex_advisor` (
  `id` int(11) auto_increment NOT NULL,
  `cid` int(11) NOT NULL DEFAULT '1',
  `xdb` varchar(64) DEFAULT NULL,	
  `tbl` varchar(64) DEFAULT NULL,	
  `idx` varchar(64) DEFAULT NULL,	
  `fname` varchar(64) DEFAULT NULL,	
  `seq` integer NOT NULL DEFAULT '0',	
  `cols` integer NOT NULL DEFAULT '0',	
  `card` integer NOT NULL DEFAULT '0',	
  `xrows` integer NOT NULL DEFAULT '0',	
  `sel_pct` double NOT NULL DEFAULT '0',	
  KEY (`cid`,`xdb`,`tbl`, `idx`),
  PRIMARY KEY(id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `mysql_memory_usage`;
CREATE TABLE IF NOT EXISTS `mysql_memory_usage` (
  `cid` int(11) NOT NULL  DEFAULT '1',	
  `nodeid` int(11) NOT NULL  DEFAULT '0',	
  `system_memory` bigint(20) DEFAULT '0',
  `total_memory` bigint(20) DEFAULT '0',
  `max_memory_used` bigint(20) DEFAULT '0',
  `max_memory_curr` bigint(20) DEFAULT '0',
  `global_memory` bigint(20) DEFAULT '0',
  `memory_per_thread` bigint(20) DEFAULT '0',
  `memory_per_thread_curr` bigint(20) DEFAULT '0',
  `memory_per_thread_max_used` bigint(20) DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`nodeid`)) ENGINE=InnoDB;




CREATE TABLE IF NOT EXISTS `mysql_advisor_history` (
  `cid` int(11) NOT NULL DEFAULT '1',	
  `nodeid` int(11) NOT NULL DEFAULT '0',	
  `module` varchar(32) DEFAULT NULL DEFAULT '',
  `rule_name` varchar(64) NOT NULL DEFAULT '',
  `advise` varchar(512) DEFAULT NULL,
  `value` bigint(20) DEFAULT '0',
  `threshold` bigint(20) DEFAULT '0',
  `status` int(11) DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`nodeid`,`report_ts`,`rule_name`),
  KEY `report_ts` (report_ts, cid)
) ENGINE=InnoDB;


DROP TRIGGER IF EXISTS `it_mysql_advisor_history`;

CREATE TABLE IF NOT EXISTS `mysql_advisor_reco` (
  `cid` int(11) NOT NULL DEFAULT '1',	
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `param` varchar(64) NOT NULL DEFAULT '',
  `recommended` bigint(20) DEFAULT '0',
  `actual` bigint(20) DEFAULT '0',
  `diff` bigint(20) DEFAULT '0',
  PRIMARY KEY (`cid`,`nodeid`,`param`)
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS `mysql_states` (
  `id` int(11) PRIMARY KEY NOT NULL,
  `name` varchar(32) NOT NULL DEFAULT '',
  `description` varchar(128) DEFAULT NULL
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `cmon_daily_job`;

CREATE TABLE IF NOT EXISTS `db_growth_hashmap` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `hashkey` bigint(20) unsigned DEFAULT '0',
  `val` varchar(255) DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`hashkey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;

CREATE TABLE IF NOT EXISTS `table_growth_hashmap` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `hashkey` bigint(20) unsigned DEFAULT '0',
  `val` varchar(255) DEFAULT NULL,
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`hashkey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;



CREATE TABLE IF NOT EXISTS `db_growth2` (
  `cid` INT(11) NOT NULL DEFAULT '1',
  `host` VARCHAR(255)  NOT NULL,
  `yearday` SMALLINT(11) UNSIGNED  NOT NULL DEFAULT '0',
  `xyear` SMALLINT(11) UNSIGNED  NOT NULL DEFAULT '0',
  `data` LONGTEXT ,
  `report_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`, `host`,`xyear`,`yearday`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;


CREATE TABLE IF NOT EXISTS `db_growth` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `dbname_hash` bigint(20) unsigned NOT NULL DEFAULT '0',
  `xrows` bigint(20) unsigned DEFAULT '0',
  `index_length` bigint(20) UNSIGNED  DEFAULT '0',
  `data_length` bigint(20) UNSIGNED  DEFAULT '0',
  `yearday` smallint(11) UNSIGNED  NOT NULL DEFAULT '0',
  `xyear` smallint(11) UNSIGNED  NOT NULL DEFAULT '0',
  `xtables` bigint(20) unsigned DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`, `dbname_hash`, `yearday`,`xyear` )
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;

CREATE TABLE IF NOT EXISTS `table_growth` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `dbname_hash` bigint(20) unsigned NOT NULL DEFAULT '0',
  `tablename_hash` bigint(20) unsigned  NOT NULL DEFAULT '0',
  `xengine` VARCHAR(64) DEFAULT 'N/A',
  `xrows` bigint(20) unsigned DEFAULT '0',
  `index_length` bigint(20) unsigned  DEFAULT '0',
  `data_length` bigint(20) unsigned DEFAULT '0',
  `yearday`smallint(11) UNSIGNED  NOT NULL DEFAULT '0',
  `xyear` smallint(11) UNSIGNED  NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`, `dbname_hash`, `tablename_hash`, `yearday`,`xyear` )
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;


CREATE TABLE IF NOT EXISTS `table_growth2` (
  `cid` INT(11) NOT NULL DEFAULT '1',
  `host` VARCHAR(255) NOT NULL,
  `dbname` VARCHAR(64) NOT NULL,
  `yearday` SMALLINT(11) UNSIGNED  NOT NULL DEFAULT '0',
  `xyear` SMALLINT(11) UNSIGNED  NOT NULL DEFAULT '0',
  `data` LONGTEXT,
  `report_ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`, `host`, `dbname`, `xyear`,`yearday`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;

/* to be deprecated */
CREATE TABLE IF NOT EXISTS `haproxy_server` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `status` int(11) DEFAULT '2',
  `lb_host` varchar(255) NOT NULL DEFAULT '',
  `lb_name` varchar(255) NOT NULL DEFAULT '',
  `lb_port` int(11) NOT NULL DEFAULT '0',
  `lb_admin` varchar(255) DEFAULT NULL,
  `lb_password` varchar(255) DEFAULT NULL,
  `add_hook` varchar(512) DEFAULT NULL,
  `delete_hook` varchar(512) DEFAULT NULL,
  `server_addr` varchar(255) DEFAULT '',
  `connectstring` varchar(255) DEFAULT '',
  `stats_socket` varchar(255) DEFAULT '/tmp/haproxy.socket',
  `configpath` varchar(255) DEFAULT '/etc/haproxy/haproxy.cfg',
  `created` timestamp NOT NULL DEFAULT '2000-01-01 00:00:01',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cid`,`lb_host`,`lb_port`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* to be deprecated */
CREATE TABLE IF NOT EXISTS `keepalived` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `keepalived_addr` varchar(255) NOT NULL DEFAULT '',
  `virtual_ip` varchar(255) NOT NULL DEFAULT '',
  `haproxy_addr1` varchar(255) NOT NULL DEFAULT '',
  `haproxy_addr2` varchar(255) NOT NULL DEFAULT '',
  `haproxy_name1` varchar(255) NOT NULL DEFAULT 'not set',	
  `haproxy_name2` varchar(255) NOT NULL DEFAULT 'not set',	
  `name` varchar(255) NOT NULL DEFAULT '',	
  `nic` varchar(255) NOT NULL DEFAULT 'not set',	
  `comment` varchar(255) NOT NULL DEFAULT '',	  
  PRIMARY KEY (`cid`,`keepalived_addr`, `name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `galera_garbd_proc`;

/* cmonapi (cmonapi/api/settings_api.php) uses this */
/* to be deprecated */
CREATE TABLE IF NOT EXISTS `user_events` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cid` int(10) unsigned NOT NULL DEFAULT '1',
  `category` int(10) unsigned DEFAULT NULL,
  `custom_data` varchar(255) DEFAULT NULL,
  `comment` varchar(1024) DEFAULT NULL,
  `ts` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cid` (`cid`,`ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;

/* to be deprecated */
CREATE TABLE IF NOT EXISTS `user_event_categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cid` int(10) unsigned NOT NULL DEFAULT '1',
  `category` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cid` (`cid`,`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* to be deprecated */
CREATE TABLE IF NOT EXISTS `ext_proc` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cid` int(10) unsigned NOT NULL DEFAULT '1',
  `hostname` varchar(255) DEFAULT NULL,
  `bin` varchar(512) DEFAULT NULL,
  `opts` varchar(2028) DEFAULT NULL,
  `cmd` varchar(2048) DEFAULT NULL,
  `proc_name` varchar(512) DEFAULT NULL,
  `status` int(10) unsigned NOT NULL DEFAULT '1',
  `port` int(10) unsigned NOT NULL DEFAULT '0',
  `active` int(10) unsigned NOT NULL DEFAULT '1',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cid` (`cid`,`hostname`,`proc_name`),
  KEY `cid_2` (`cid`,`proc_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* to be deprecated */
DROP TABLE IF EXISTS `memcache_statistics`;
CREATE TABLE IF NOT EXISTS `memcache_statistics` (
  `cid` int(10) unsigned NOT NULL DEFAULT '1',
  `hostname` varchar(255) NOT NULL DEFAULT '',
  `port` int(10) unsigned NOT NULL DEFAULT '11211',
  `pid` bigint(20) unsigned DEFAULT '0',
  `uptime` bigint(20) unsigned DEFAULT '0',
  `time_` bigint(20) unsigned DEFAULT '0',
  `version` varchar(64) DEFAULT '',
  `libevent` varchar(64) DEFAULT '',
  `pointer_size` bigint(20) unsigned DEFAULT '0',
  `rusage_user` decimal(10,6) DEFAULT '0.000000',
  `rusage_system` decimal(10,6) DEFAULT '0.000000',
  `daemon_connections` bigint(20) unsigned DEFAULT '0',
  `curr_connections` bigint(20) unsigned DEFAULT '0',
  `total_connections` bigint(20) unsigned DEFAULT '0',
  `connection_structures` bigint(20) unsigned DEFAULT '0',
  `cmd_get` bigint(20) unsigned DEFAULT '0',
  `cmd_set` bigint(20) unsigned DEFAULT '0',
  `cmd_flush` bigint(20) unsigned DEFAULT '0',
  `auth_cmds` bigint(20) unsigned DEFAULT '0',
  `auth_errors` bigint(20) unsigned DEFAULT '0',
  `get_hits` bigint(20) unsigned DEFAULT '0',
  `get_misses` bigint(20) unsigned DEFAULT '0',
  `delete_misses` bigint(20) unsigned DEFAULT '0',
  `delete_hits` bigint(20) unsigned DEFAULT '0',
  `incr_misses` bigint(20) unsigned DEFAULT '0',
  `incr_hits` bigint(20) unsigned DEFAULT '0',
  `decr_misses` bigint(20) unsigned DEFAULT '0',
  `decr_hits` bigint(20) unsigned DEFAULT '0',
  `cas_misses` bigint(20) unsigned DEFAULT '0',
  `cas_hits` bigint(20) unsigned DEFAULT '0',
  `cas_badval` bigint(20) unsigned DEFAULT '0',
  `bytes_read` bigint(20) unsigned DEFAULT '0',
  `bytes_written` bigint(20) unsigned DEFAULT '0',
  `limit_maxbytes` bigint(20) unsigned DEFAULT '0',
  `accepting_conns` bigint(20) unsigned DEFAULT '0',
  `listen_disabled_num` bigint(20) unsigned DEFAULT '0',
  `rejected_conns` bigint(20) unsigned DEFAULT '0',
  `threads` bigint(20) unsigned DEFAULT '0',
  `conn_yields` bigint(20) unsigned DEFAULT '0',
  `evictions` bigint(20) unsigned DEFAULT '0',
  `curr_items` bigint(20) unsigned DEFAULT '0',
  `total_items` bigint(20) unsigned DEFAULT '0',
  `bytes` bigint(20) unsigned DEFAULT '0',
  `reclaimed` bigint(20) unsigned DEFAULT '0',
  `engine_maxbytes` bigint(20) unsigned DEFAULT '0',
  `rusage_user_g` decimal(10,6) DEFAULT '0.000000',
  `rusage_system_g` decimal(10,6) DEFAULT '0.000000',
  `daemon_connections_g` bigint(20) unsigned DEFAULT '0',
  `curr_connections_g` bigint(20) unsigned DEFAULT '0',
  `total_connections_g` bigint(20) unsigned DEFAULT '0',
  `connection_structures_g` bigint(20) unsigned DEFAULT '0',
  `cmd_get_g` bigint(20) unsigned DEFAULT '0',
  `cmd_set_g` bigint(20) unsigned DEFAULT '0',
  `cmd_flush_g` bigint(20) unsigned DEFAULT '0',
  `auth_cmds_g` bigint(20) unsigned DEFAULT '0',
  `auth_errors_g` bigint(20) unsigned DEFAULT '0',
  `get_hits_g` bigint(20) unsigned DEFAULT '0',
  `get_misses_g` bigint(20) unsigned DEFAULT '0',
  `delete_misses_g` bigint(20) unsigned DEFAULT '0',
  `delete_hits_g` bigint(20) unsigned DEFAULT '0',
  `incr_misses_g` bigint(20) unsigned DEFAULT '0',
  `incr_hits_g` bigint(20) unsigned DEFAULT '0',
  `decr_misses_g` bigint(20) unsigned DEFAULT '0',
  `decr_hits_g` bigint(20) unsigned DEFAULT '0',
  `cas_misses_g` bigint(20) unsigned DEFAULT '0',
  `cas_hits_g` bigint(20) unsigned DEFAULT '0',
  `cas_badval_g` bigint(20) unsigned DEFAULT '0',
  `bytes_read_g` bigint(20) unsigned DEFAULT '0',
  `bytes_written_g` bigint(20) unsigned DEFAULT '0',
  `listen_disabled_num_g` bigint(20) unsigned DEFAULT '0',
  `rejected_conns_g` bigint(20) unsigned DEFAULT '0',
  `conn_yields_g` bigint(20) unsigned DEFAULT '0',
  `evictions_g` bigint(20) unsigned DEFAULT '0',
  `total_items_g` bigint(20) unsigned DEFAULT '0',
  `reclaimed_g` bigint(20) unsigned DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cmd_touch` bigint(20) unsigned DEFAULT '0',
  `cmd_touch_g` bigint(20) unsigned DEFAULT '0',
  `evicted_unfetched` bigint(20) unsigned DEFAULT '0',
  `evicted_unfetched_g` bigint(20) unsigned DEFAULT '0',
  `expired_unfetched_g` bigint(20) unsigned DEFAULT '0',
  `expired_unfetched` bigint(20) unsigned DEFAULT '0',
  `hash_bytes` bigint(20) unsigned DEFAULT '0',
  `hash_is_expanding` bigint(20) unsigned DEFAULT '0',
  `hash_power_level` bigint(20) unsigned DEFAULT '0',
  `reserved_fds` bigint(20) unsigned DEFAULT '0',
  `touch_hits` bigint(20) unsigned DEFAULT '0',
  `touch_hits_g` bigint(20) unsigned DEFAULT '0',
  `touch_misses_g` bigint(20) unsigned DEFAULT '0',
  `touch_misses` bigint(20) unsigned DEFAULT '0',
  PRIMARY KEY (`cid`,`hostname`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `cmon_cron` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  `min_` varchar(16) DEFAULT '*',
  `hour_` varchar(16) DEFAULT '*',
  `dow_` varchar(16) DEFAULT '*',
  `dom_` varchar(16) DEFAULT '*',
  `month_` varchar(16) DEFAULT '*',
  `year_` varchar(16) DEFAULT '*',
  `hostname` varchar(255) DEFAULT '127.0.0.1',
  `external_cmd` varchar(512) DEFAULT NULL,
  `internal_cmd` varchar(512) DEFAULT NULL,
  `description` varchar(512) NOT NULL DEFAULT '',
  `create_job` tinyint(4) NOT NULL DEFAULT '0',
  `run_at_startup` tinyint(4) DEFAULT '0',
  `enabled` TINYINT NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY (`cid`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `mongodb_backup`;
DROP TABLE IF EXISTS `mongodb_cluster_stats`;
DROP TABLE IF EXISTS `mongodb_cluster_stats_hour`;
DROP TABLE IF EXISTS `mongodb_cluster_stats_history`;
DROP TABLE IF EXISTS `mongodb_databases`;
DROP TABLE IF EXISTS `mongodb_dbcollections`;
DROP TABLE IF EXISTS `mongodb_dbcollections_indexstats`;

/* to be deprecated */ 
CREATE TABLE IF NOT EXISTS `mongodb_nodetype_map` (
  `id` int(11) NOT NULL DEFAULT '1',
  `name` varchar(512) DEFAULT NULL,
  `proc_name` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `mongodb_replica_set`;
DROP TABLE IF EXISTS `mongodb_rs_stats`;
DROP TABLE IF EXISTS `mongodb_rs_stats_hour`;
DROP TABLE IF EXISTS `mongodb_rs_stats_history`;

DROP TABLE IF EXISTS `mongodb_running_queries` ;
CREATE TABLE IF NOT EXISTS `mongodb_running_queries` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `rs_name` varchar(512) DEFAULT NULL,
  `hostname` char(255) NOT NULL DEFAULT '',
  `port` int(11) NOT NULL DEFAULT '0',
  `serverid` int(11) NOT NULL DEFAULT '0',  
  `opid` int(11) NOT NULL DEFAULT '0',
  `active` tinyint(4) DEFAULT NULL,
  `secs_running` int(11) DEFAULT NULL,
  `op` varchar(255) DEFAULT NULL,
  `ns` varchar(512) DEFAULT NULL,
  `query` varchar(512) DEFAULT NULL,
  `client` varchar(512) DEFAULT NULL,
  `desc` varchar(512) DEFAULT NULL,
  `thread_id` varchar(255) DEFAULT NULL,
  `connection_id` int(11) DEFAULT NULL,
  `waiting_for_lock` tinyint(4) DEFAULT NULL,
  `msg` varchar(512) DEFAULT NULL,
  `read_lock` bigint(20) unsigned DEFAULT NULL,
  `write_lock` bigint(20) unsigned DEFAULT NULL,
  `wait_read_lock` bigint(20) unsigned DEFAULT NULL,
  `wait_write_lock` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY(cid, serverid, opid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

 CREATE TABLE IF NOT EXISTS `mongodb_server` (
  `cid` int(11) NOT NULL DEFAULT '1',
  `serverid` int(11) NOT NULL DEFAULT '0',
  `nodeid` int(11) NOT NULL AUTO_INCREMENT,
  `hostname` char(255) NOT NULL DEFAULT '',
  `port` int(11) NOT NULL DEFAULT '0',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` int(11) DEFAULT '0',
  `arbiter` tinyint(4) DEFAULT '0',
  `hidden` tinyint(4) DEFAULT '0',
  `votes` tinyint(4) DEFAULT '1',
  `slave_delay` int(11) NOT NULL DEFAULT '0',
  `username` char(255) NOT NULL DEFAULT '',
  `password` char(255) NOT NULL DEFAULT '',
  `node_type` int(11) NOT NULL DEFAULT '0',
  `rs_name` varchar(512) DEFAULT NULL,
  `cmdline` varchar(512) DEFAULT NULL,
  `dbpath` varchar(512) DEFAULT NULL,
  `config` varchar(512) DEFAULT NULL,
  `logpath` varchar(512) DEFAULT NULL,
  `pidfilepath` varchar(512) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `tokumx_version` varchar(32) DEFAULT '',
  `shardsvr` tinyint(4) DEFAULT '0',
  `pid` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`cid`,`node_type`,`hostname`,`port`),
  UNIQUE KEY `hostname` (`hostname`,`port`),
  KEY `cid` (`cid`,`rs_name`,`serverid`),
  KEY `cid2` (`cid`,`nodeid`),
  KEY `nodeid` (`nodeid`)
) ENGINE=InnoDB AUTO_INCREMENT=406 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `mongodb_server_states` (
  `id` int(11) NOT NULL DEFAULT '0',
  `name` varchar(32) DEFAULT NULL,
  `description` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `mongodb_stats`;
DROP TABLE IF EXISTS `mongodb_stats_hour`;
DROP TABLE IF EXISTS `mongodb_stats_history`;

/* to be deprecated */
CREATE TABLE IF NOT EXISTS `expression_group` (
  `id` int(11) AUTO_INCREMENT NOT NULL,
  `name` varchar(128) DEFAULT NULL,
  `db` varchar(128) DEFAULT NULL,
  `comment` varchar(256) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id),
  UNIQUE KEY(name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* to be deprecated */
/*DROP TABLE IF EXISTS expression;*/
CREATE TABLE IF NOT EXISTS `expression` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` int(11) NOT NULL DEFAULT '1',
  `groupid` int(11) NOT NULL DEFAULT '0',
  `expression` varchar(512) DEFAULT NULL,
  `result_var` varchar(128) DEFAULT NULL,
  `name` varchar(128) DEFAULT NULL,
  `comment` varchar(256) DEFAULT NULL,
  `advise` varchar(256) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `gt_trigger` int(11) NOT NULL DEFAULT '1', /**trigger if val is greater than, 0=lower than*/
  PRIMARY KEY (`id`),
  KEY `cid_2` (`cid`,`result_var`),
  UNIQUE KEY(`cid`,`groupid`,`result_var`) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* to be deprecated */
/*DROP TABLE IF EXISTS expression_trigger;*/
CREATE TABLE IF NOT EXISTS `expression_trigger` (
  `expressionid` int(11) NOT NULL DEFAULT '1', 
  `cid` int(11) NOT NULL DEFAULT '1',
  `hostid` int(11) NOT NULL DEFAULT '0' /* 0 = all hosts*/,
  `nodeid` int(11) NOT NULL DEFAULT '0' /* 0 = all nodes*/,
  `warning` int(11) NOT NULL DEFAULT '80',
  `critical` int(11) NOT NULL DEFAULT '90',
  `active` int(11) NOT NULL DEFAULT '1',
  `notify` int(11) NOT NULL DEFAULT '1',
  `alarm_created` int(11) NOT NULL DEFAULT '0',
  `alarm_created_threshold` int(11) NOT NULL DEFAULT '0',
  `max_threshold_breaches` int(11) NOT NULL DEFAULT '3',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(cid, expressionid, nodeid)  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* to be deprecated */
/*DROP TABLE IF EXISTS expression_result;*/
CREATE TABLE IF NOT EXISTS `expression_result` (
  `expressionid` int(11) NOT NULL DEFAULT '1', 
  `cid` int(11) NOT NULL DEFAULT '1',
  `hostid` int(11) NOT NULL DEFAULT '1',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `warning` int(11) NOT NULL DEFAULT '80',
  `critical` int(11) NOT NULL DEFAULT '90',
  `val` varchar(32) NOT NULL DEFAULT '',
  `errmsg` varchar(32) NOT NULL DEFAULT '',
  `severity` enum('OK', 'WARNING','CRITICAL') DEFAULT 'OK',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(expressionid, cid, nodeid)  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* to be deprecated */
DROP TABLE IF EXISTS expression_result_history;
CREATE TABLE IF NOT EXISTS `expression_result_history` (
  `expressionid` int(11) NOT NULL DEFAULT '1', 
  `cid` int(11) NOT NULL DEFAULT '1',
  `hostid` int(11) NOT NULL DEFAULT '1',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `warning` int(11) NOT NULL DEFAULT '80',
  `critical` int(11) NOT NULL DEFAULT '90',
  `val` varchar(32) NOT NULL DEFAULT '',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(expressionid, cid, nodeid, report_ts),
  KEY(report_ts)  
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* to be deprecated  - do we really need this :s*/ 
CREATE TABLE IF NOT EXISTS `metainfo` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `cid` int(11) DEFAULT NULL,
    `hostid` int(11) DEFAULT NULL,
    `nodeid` int(11) DEFAULT NULL,
    `attribute` varchar(250) NOT NULL,
    `value` varchar(250) NOT NULL,
    `description` varchar(250) DEFAULT '',
    PRIMARY KEY (`id`),
    UNIQUE KEY `cid` (`cid`,`hostid`,`nodeid`,`attribute`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*

get all expression results history:

select m.hostname, m.port, er.nodeid, er.hostid, result_var, expression, val, er.report_ts from expression e, expression_trigger et , expression_result_history er, mysql_server m where e.id=er.expressionid and er.expressionid=et.expressionid and er.nodeid=et.nodeid  and e.cid=er.cid and et.cid=er.cid  and m.cid=er.cid and m.nodeid=er.nodeid and m.nodeid=et.nodeid and e.cid=1;


filtration on particular expressions -> good for plotting an expression within a time range (time range not show here but should be on expression_result_history.report_ts)

select m.hostname, m.port, er.nodeid, er.hostid, result_var, expression, val, er.report_ts from expression e, expression_trigger et , expression_result_history er, mysql_server m where e.id=er.expressionid and er.expressionid=et.expressionid and er.nodeid=et.nodeid  and e.cid=er.cid and et.cid=er.cid  and m.cid=er.cid and m.nodeid=er.nodeid and m.nodeid=et.nodeid and e.cid=1 and e.result_var='% innodb log waits';


filtration on particular expressions -> good for plotting an expression within a time range 

select m.hostname, m.port, er.nodeid, er.hostid, result_var, expression, val, er.report_ts from expression e, expression_trigger et , expression_result_history er, mysql_server m where e.id=er.expressionid and er.expressionid=et.expressionid and er.nodeid=et.nodeid  and e.cid=er.cid and et.cid=er.cid  and m.cid=er.cid and m.nodeid=er.nodeid and m.nodeid=et.nodeid and e.cid=1 and e.result_var='% innodb log waits' and er.report_ts between date_sub(now(), interval 1 hour) and now();


filtration on a particular server (the mysql.nodeid also works here):

select m.hostname, m.port, er.nodeid, er.hostid, result_var, expression, val, er.report_ts from expression e, expression_trigger et , expression_result_history er, mysql_server m where e.id=er.expressionid and er.expressionid=et.expressionid and er. nodeid=et.nodeid  and e.cid=er.cid and et.cid=er.cid  and m.cid=er.cid and m.nodeid=er.nodeid and m.nodeid=et.nodeid and m.hostname='10.177.197.223' and e.cid=1;
 
get current expression results --> summary screenn

select m.hostname, m.port, er.nodeid, er.hostid, result_var, expression, val,report_ts from expression e, expression_trigger et , expression_result er, mysql_server m where e.id=er.expressionid and er.expressionid=et.expressionid and er.nodeid=et.nodeid  and e.cid=er.cid and et.cid=er.cid  and m.cid=er.cid and m.nodeid=er.nodeid and m.nodeid=et.nodeid and e.cid=1;
*/

/* DROP TABLE IF EXISTS cmon_stats; */
CREATE TABLE IF NOT EXISTS cmon_stats 
( 
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cid      INTEGER UNSIGNED NOT NULL DEFAULT '0',
  name     VARCHAR(255),
  statkey  VARCHAR(255),
  hostid   integer unsigned DEFAULT '0',
  value    VARBINARY(2048),
  ts       BIGINT UNSIGNED,
  KEY(cid,ts,name,hostid),
  PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* DROP TABLE IF EXISTS cmon_stats_daily; */
CREATE TABLE IF NOT EXISTS cmon_stats_daily 
( 
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cid      INTEGER UNSIGNED NOT NULL DEFAULT '0',
  name     VARCHAR(255),
  statkey  VARCHAR(255),
  hostid   integer unsigned DEFAULT '0',
  value    VARBINARY(2048),
  ts       BIGINT UNSIGNED,
  KEY(cid,ts,name,hostid),
  PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* DROP TABLE IF EXISTS cmon_stats_weekly; */
CREATE TABLE IF NOT EXISTS cmon_stats_weekly 
( 
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cid      INTEGER UNSIGNED NOT NULL DEFAULT '0',
  name     VARCHAR(255),
  statkey  VARCHAR(255),
  hostid   integer unsigned DEFAULT '0',
  value    VARBINARY(2048),
  ts       BIGINT UNSIGNED,
  KEY(cid,ts,name,hostid),
  PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* DROP TABLE IF EXISTS cmon_stats_monthly; */
CREATE TABLE IF NOT EXISTS cmon_stats_monthly
( 
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cid      INTEGER UNSIGNED NOT NULL DEFAULT '0',
  name     VARCHAR(255),
  statkey  VARCHAR(255),
  hostid   integer unsigned DEFAULT '0',
  value    VARBINARY(2048),
  ts       BIGINT UNSIGNED,
  KEY(cid,ts,name,hostid),
  PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* DROP TABLE IF EXISTS cmon_stats_yearly; */
CREATE TABLE IF NOT EXISTS cmon_stats_yearly
( 
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cid      INTEGER UNSIGNED NOT NULL DEFAULT '0',
  name     VARCHAR(255),
  statkey  VARCHAR(255),
  hostid   integer unsigned DEFAULT '0',
  value    VARBINARY(2048),
  ts       BIGINT UNSIGNED,
  KEY(cid,ts,name,hostid),
  PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*DEPRECATED - NOT USED*/
DROP TABLE IF EXISTS cmon_json;
DROP TABLE IF EXISTS `cmon_galera_counters`;
DROP TABLE IF EXISTS `configurator_nodemap`;
DROP TABLE IF EXISTS `ps_statment_digest`;

CREATE TABLE IF NOT EXISTS  `spreadsheets` (
  `id`      int(11) NOT NULL AUTO_INCREMENT,
  `cid`     int(11) NOT NULL DEFAULT '1',
  `name`    varchar(512) DEFAULT '',
  `content` mediumtext,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cid` (`cid`,`name`),
  KEY `cid2` (`cid`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/**
 * This is a planned unified 'server' table...
 * (lets keep the DROP TABLE there until the format isn't finalized...)
 */
/* DROP TABLE IF EXISTS `server_node`; */
CREATE TABLE IF NOT EXISTS `server_node` (
  `id`          int(11) NOT NULL AUTO_INCREMENT,
  `cid`         int(11) NOT NULL DEFAULT '0',
  /* This shows what kind of host this is. */
  `class_name`  varchar(32) NOT NULL,
  /* this might be redundant info, as 'hosts' table contains the IP/hostname: */
  `hostname`    varchar(255) NOT NULL DEFAULT '',
  `port`        int(11) NOT NULL DEFAULT '0',
  `properties`  varchar(16384) NOT NULL DEFAULT '',
  PRIMARY KEY (`cid`,`hostname`,`port`),
  UNIQUE KEY `hostname` (`cid`,`hostname`,`port`),
  KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `tx_deadlock_log`;
CREATE TABLE IF NOT EXISTS `tx_deadlock_log` (
  `cid` int(11) NOT NULL DEFAULT '0',
  `nodeid` int(11) NOT NULL DEFAULT '0',
  `host` varchar(255) NOT NULL DEFAULT '',
  `user` varchar(128) NOT NULL DEFAULT '',
  `db` varchar(128) NOT NULL DEFAULT '',
  `state` varchar(128) NOT NULL DEFAULT '',
  `internal_trx_id` varchar(64) NOT NULL DEFAULT '',
  `external_trx_id` varchar(64) NOT NULL DEFAULT '',
  `blocking_trx_id` varchar(64) NOT NULL DEFAULT '',
  `info` varchar(2048) NOT NULL DEFAULT '',
  `sql_text` varchar(2048) NOT NULL DEFAULT '',
  `message` varchar(2048) NOT NULL DEFAULT '',
  `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `duration` int(11) NOT NULL DEFAULT '0',
  `json` varbinary(16384) NOT NULL DEFAULT '',
  PRIMARY KEY(cid,nodeid,external_trx_id,internal_trx_id),
  KEY `report_ts` (cid, report_ts)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!50503 ALTER TABLE tx_deadlock_log CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci*/;

/* The new tables for the imperative scripts */
/* DROP TABLE IF EXISTS `scripts`; */
CREATE TABLE IF NOT EXISTS `scripts` (
    `filename` varchar(512) DEFAULT '',
    `version` int(11) DEFAULT '0',
    `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `content` mediumtext,
    PRIMARY KEY (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* DROP TABLE IF EXISTS `scripts_schedule`; */
CREATE TABLE IF NOT EXISTS `scripts_schedule` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `cid` int(11) NOT NULL DEFAULT '1',
    `filename` varchar(512) DEFAULT '',
    `schedule` varchar(512) DEFAULT '',
    `arguments` varchar(512) DEFAULT '',
    `enabled` TINYINT NOT NULL DEFAULT '1',
    PRIMARY KEY (`id`),
    UNIQUE KEY (`cid`, `id`, `filename`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* DROP TABLE IF EXISTS `scripts_results`; */
CREATE TABLE IF NOT EXISTS `scripts_results` (
    `cid` int(11) NOT NULL DEFAULT '1',
    `schedule_id` int(11) NOT NULL DEFAULT '0',
    `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `results` mediumtext,
    PRIMARY KEY (`cid`, `schedule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* DROP TABLE IF EXISTS `scripts_audit_log`; */
CREATE TABLE IF NOT EXISTS `scripts_audit_log` (
    `cid` int(11) NOT NULL DEFAULT '1',
    `filename` varchar(512) DEFAULT '',
    `username` varchar(512) DEFAULT 'unknown',
    `component`  enum('Edit','Execute','Move','Remove','Create') DEFAULT 'Edit',
    `message` varchar(512) DEFAULT '',
    `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
     PRIMARY KEY (`cid`,`filename`,`username`,`ts`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* DROP TABLE IF EXISTS `local_repository`; */
CREATE TABLE IF NOT EXISTS `local_repository` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL DEFAULT '',
    `path` varchar(1024) DEFAULT '',
    `clustertype` varchar(64) NOT NULL DEFAULT '',
    `vendor` varchar(64) NOT NULL DEFAULT '',
    `dbversion` varchar(16) NOT NULL DEFAULT '',
    `os` enum('debian','redhat') DEFAULT 'debian',
    `osrelease` varchar(64) NOT NULL DEFAULT '',
    `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`),
    KEY `ix_local_repo_type` (clustertype, vendor, dbversion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* DROP TABLE IF EXISTS `opreports`; */
CREATE TABLE IF NOT EXISTS `opreports` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `cid` int(11) NOT NULL DEFAULT '1',
    `reporttype` varchar(255) NOT NULL DEFAULT '',
    `name` varchar(255) NOT NULL DEFAULT '',
    `path` varchar(1024) DEFAULT '',
    `generatedby` varchar(255) NOT NULL DEFAULT '',
    `recipients` varchar(1024) DEFAULT '',
    `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* DROP TABLE IF EXISTS `opreports_schedule`; */
CREATE TABLE IF NOT EXISTS `opreports_schedule` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `cid` int(11) NOT NULL DEFAULT '1',
    `report_name` varchar(255) DEFAULT '',
    `schedule` varchar(512) DEFAULT '',
    `args` varchar(1024) DEFAULT '',
    `recipients` varchar(1024) DEFAULT '',
    `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* DROP TABLE IF EXISTS `certificate_data`; */
CREATE TABLE IF NOT EXISTS `certificate_data` (
    `id`            int(11) NOT NULL AUTO_INCREMENT,
    `issuerId`      int(11) DEFAULT NULL,
    `serialNumber`  bigint(20) NOT NULL DEFAULT 1,
    `requested`     timestamp DEFAULT '2000-01-01 00:00:01',
    `issued`        timestamp DEFAULT '2000-01-01 00:00:01',
    `revoked`       timestamp DEFAULT '2000-01-01 00:00:01',
    `status`        enum('Requested','Issued','Revoked') DEFAULT 'Requested',
    `certfile`      varchar(512) DEFAULT '',
    `keyfile`       varchar(512) DEFAULT '',
    `requestfile`   varchar(512) DEFAULT '',
    `properties`    varchar(16384) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE certificate_data MODIFY serialNumber bigint(20) UNSIGNED DEFAULT '1';

DROP TABLE IF EXISTS `cluster_events`;
CREATE TABLE IF NOT EXISTS `cluster_events` (
    `id`  bigint unsigned NOT NULL AUTO_INCREMENT,
    `cid` int(11) NOT NULL DEFAULT '1',
    `report_ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `previous_status` enum('MGMD_NO_CONTACT','STARTED','NOT_STARTED','DEGRADED','FAILURE','SHUTTING_DOWN','RECOVERING','STARTING','UNKNOWN', 'STOPPED') DEFAULT NULL,
    `next_status` enum('MGMD_NO_CONTACT','STARTED','NOT_STARTED','DEGRADED','FAILURE','SHUTTING_DOWN','RECOVERING','STARTING','UNKNOWN', 'STOPPED') DEFAULT NULL,
  KEY(cid, report_ts),
  PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* lets keep the enums in sync with CmonHost::statusToString(..) */
DROP TABLE IF EXISTS `node_events`;
CREATE TABLE IF NOT EXISTS `node_events` (
    `id`  bigint unsigned NOT NULL AUTO_INCREMENT,
    `cid`               int(11) NOT NULL DEFAULT '0',
    `hostname`          varchar(255) NOT NULL DEFAULT '',
    `port`              int(11) NOT NULL DEFAULT '0',
    `report_ts`         timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `previous_status`   enum('CmonHostUnknown','CmonHostOnline','CmonHostOffLine','CmonHostFailed','CmonHostRecovery','CmonHostShutDown') NOT NULL DEFAULT 'CmonHostUnknown',
    `next_status`       enum('CmonHostUnknown','CmonHostOnline','CmonHostOffLine','CmonHostFailed','CmonHostRecovery','CmonHostShutDown') NOT NULL DEFAULT 'CmonHostUnknown',
    KEY (`cid`,`hostname`,`port`),
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* s9s_error_report script table */
CREATE TABLE IF NOT EXISTS `cmon_error_reports` (
    `id` bigint unsigned auto_increment,
    `cid` integer unsigned,
    `errorlog_filepath` varchar(512) NOT NULL DEFAULT '',
    `www` tinyint DEFAULT '0', 
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, 
    PRIMARY KEY(`id`)
) ENGINE=innodb DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `cmon_log_class` (
  `id`         int(11) NOT NULL,
  `log_class`  varchar(128) NOT NULL,
   PRIMARY KEY(`id`),
  KEY (`log_class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `cmon_log_entries` (
  `id`         int(11) NOT NULL,
  `cid`        int(11) NOT NULL,
  `created`    datetime NOT NULL,
  `severity`   enum('LOG_EMERG','LOG_ALERT','LOG_CRIT','LOG_ERR','LOG_WARNING','LOG_INFO','LOG_DEBUG') DEFAULT NULL,
  `component`  enum('Network','CmonDatabase','Mail','Cluster','ClusterConfiguration','ClusterRecovery','Node', 'Host', 'DbHealth','DbPerformance' ,'SoftwareInstallation','Backup','Unknown') DEFAULT 'Unknown',
  `log_class_id` int unsigned NOT NULL REFERENCES cmon_log_class (id),
  `properties` varchar(16384) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY (`created`, `cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/*
 * User management related tables...
 */
CREATE TABLE IF NOT EXISTS `users` (
  `id`         bigint unsigned NOT NULL AUTO_INCREMENT,
  `username`   varchar(512) NOT NULL,
  `created`    timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `properties`  varchar(16384) NOT NULL DEFAULT '',
  PRIMARY KEY(`id`),
  KEY (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*
 * User management related tables...
 */
CREATE TABLE IF NOT EXISTS `groups` (
  `id`         bigint unsigned NOT NULL AUTO_INCREMENT,
  `groupname`  varchar(512) NOT NULL,
  `created`    timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `properties`  varchar(16384) NOT NULL DEFAULT '',
  PRIMARY KEY(`id`),
  KEY (`groupname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE  IF NOT EXISTS `cmon_schema_hugin` (
  `cid` int(10) unsigned NOT NULL,
  `db` varchar(128) NOT NULL,
  `tbl` varchar(128) NOT NULL,
  `hash` varchar(64) DEFAULT NULL,
  `stmt` text,
  PRIMARY KEY (`cid`,`db`,`tbl`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!50503 ALTER TABLE cmon_schema_hugin MODIFY COLUMN stmt TEXT CHARACTER SET utf8mb4 DEFAULT NULL*/;

/*
 * lets keep this at the end...
 */
CREATE TABLE IF NOT EXISTS `cmondb_version` (
    `id`            int(11) NOT NULL AUTO_INCREMENT,
    `schema_name`   varchar(128) NOT NULL DEFAULT 'cmon_db.sql',
    `version`       int(11) DEFAULT 0,
    UNIQUE KEY (`schema_name`),
    PRIMARY KEY id (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/* set/update the current main schema (cmon_db.sql) version */
REPLACE INTO cmondb_version VALUES (NULL, 'cmon_db.sql', 105000);

