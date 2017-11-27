CREATE DATABASE IF NOT EXISTS cmon CHARACTER SET utf8;
USE cmon;

/* For upgrading from older schemas, where had
 * this error this has to be enabled: */
SET SQL_MODE='ALLOW_INVALID_DATES';

DROP PROCEDURE IF EXISTS sp_cmon_deletehost;
DELIMITER ||
CREATE PROCEDURE  sp_cmon_deletehost(_cid integer, _hostid integer)
SQL SECURITY INVOKER
BEGIN

   DECLARE _hostname VARCHAR(255);
   SELECT hostname INTO _hostname FROM hosts WHERE cid=_cid AND id=_hostid;
    
   DELETE FROM backup_schedule WHERE cid=_cid AND backup_host=_hostname;
   DELETE FROM hosts WHERE cid=_cid AND id=_hostid;
   DELETE FROM processes WHERE cid=_cid and hid=_hostid;
   DELETE FROM top WHERE cid=_cid AND hostid=_hostid;
   DELETE FROM galera_status WHERE cid=_cid AND hostid=_hostid;

   CALL sp_cmon_deletemysql(_cid, _hostid);
    
   SET @where = concat('WHERE cid=', _cid, ' AND hostid=', _hostid);

   DELETE FROM simple_alarm WHERE cid=_cid AND hostid=_hostid;

END;
||
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_cmon_deletemysql;
DELIMITER ||
CREATE PROCEDURE  sp_cmon_deletemysql(_cid integer, _hostid integer)
SQL SECURITY INVOKER
BEGIN
   DECLARE _nodeid INTEGER;	
   SELECT nodeid INTO _nodeid FROM mysql_server m WHERE m.cid=_cid AND m.id=_hostid;

   SET @where = concat('WHERE cid=', _cid, ' AND process="mysqld_safe" AND hid=', _hostid);
   CALL sp_delete_where('processes', @where , 100);

   SET @where = concat('WHERE cid=', _cid, ' AND filename="my.cnf" AND hid=', _hostid);

   DELETE FROM mysql_server WHERE cid=_cid AND id=_hostid;    
    
   DELETE FROM galera_status WHERE cid=_cid AND hostid=_hostid;
   IF _nodeid IS NOT NULL THEN 
      DELETE FROM mysql_advisor WHERE cid=_cid AND nodeid=_hostid;
      DELETE FROM mysql_memory_usage WHERE cid=_cid AND nodeid=_hostid;
      SET @where = concat('WHERE cid=', _cid, ' AND nodeid=', _nodeid);
      CALL sp_delete_where('mysql_advisor_history', @where , 100);

      DELETE FROM mysql_advisor_reco WHERE cid=_cid AND nodeid=_nodeid;
      SET @where = concat('WHERE cid=', _cid, ' AND hostid=', _nodeid);
      CALL sp_delete_where('mysql_performance_results', @where , 100);	

      DELETE FROM mysql_processlist WHERE cid=_cid AND id=_nodeid;

      SET @where = concat('WHERE cid=', _cid, ' AND id=', _nodeid);
      CALL sp_delete_where('mysql_query_histogram', @where , 100);	
    
      SET @where = concat('WHERE cid=', _cid, ' AND id=', _nodeid);
      CALL sp_delete_where('mysql_slow_queries', @where , 100);	

      DELETE FROM mysql_slow_queries WHERE cid=_cid AND id=_nodeid;
      DELETE FROM mysql_statistics WHERE cid=_cid AND id=_nodeid;

/* 
      Lets age out this data instead, too much to delete at once...
      SET @where = concat('WHERE cid=', _cid, ' AND id=', _nodeid);
      CALL sp_delete_where('mysql_statistics_history', @where , 100);
*/	
   END IF;
END;
||
DELIMITER ;



DROP PROCEDURE IF EXISTS sp_cmon_movehost;
DELIMITER ||
CREATE PROCEDURE  sp_cmon_movehost(_cid integer, _hostid integer)
SQL SECURITY INVOKER
BEGIN	    
   UPDATE hosts SET cid=_cid WHERE id=_hostid;
   UPDATE processes SET cid=_cid and hid=_hostid;
/*   UPDATE top SET cid=_cid WHERE hostid=_hostid;*/
   DELETE FROM top WHERE hostid=_hostid;
   UPDATE galera_status SET cid=_cid WHERE hostid=_hostid;
   CALL sp_cmon_movemysql(_cid, _hostid);
END;
||
DELIMITER ;



DROP PROCEDURE IF EXISTS sp_cmon_movemysql;
DELIMITER ||
CREATE PROCEDURE  sp_cmon_movemysql(_cid integer, _hostid integer)
SQL SECURITY INVOKER
BEGIN
   UPDATE IGNORE mysql_advisor SET cid=_cid  WHERE nodeid=_hostid;
   UPDATE IGNORE mysql_memory_usage SET cid=_cid  WHERE nodeid=_hostid;
/*   UPDATE IGNORE mysql_advisor_history SET cid=_cid  WHERE nodeid=_hostid;*/
   UPDATE IGNORE mysql_advisor_reco SET cid=_cid  WHERE nodeid=_hostid;	
   UPDATE IGNORE mysql_performance_results SET cid=_cid WHERE hostid=_hostid;
   UPDATE IGNORE mysql_processlist SET cid=_cid WHERE id=_hostid;
/*   UPDATE IGNORE mysql_query_histogram SET cid=_cid WHERE id=_hostid;*/
   UPDATE IGNORE mysql_server SET cid=_cid WHERE id=_hostid;
   UPDATE IGNORE mysql_slow_queries SET cid=_cid WHERE id=_hostid;
   UPDATE IGNORE mysql_statistics SET cid=_cid WHERE id=_hostid;
END;
||
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_cmon_deletecluster;
DROP PROCEDURE IF EXISTS sp_cmon_deletecpu;
DROP PROCEDURE IF EXISTS sp_cmon_delete_mongodb_cluster_stats_history;
DROP PROCEDURE IF EXISTS sp_cmon_delete_mongodb_stats_history;
DROP PROCEDURE IF EXISTS sp_cmon_delete_mongodb_rs_stats_history;
DROP PROCEDURE IF EXISTS sp_cmon_delete_mongodb_history;
DROP PROCEDURE IF EXISTS sp_cmon_purge_mongodb_history;
DROP EVENT IF EXISTS e_purge_mongodb_history;

DROP PROCEDURE IF EXISTS sp_delete_chunks;
delimiter //
CREATE PROCEDURE `sp_delete_chunks`(db_name VARCHAR(255), table_name VARCHAR(255), cid INT, chunk_sz INT)
BEGIN
  SET @table_name = table_name;
  SET @db_name = db_name;
  SET @cid_ = cid;
  SET @chunk_sz_ = chunk_sz;
  SET @num_deleted = 0;

  loop_label:  LOOP


    SET @sql_text3 = concat('DELETE FROM ', @db_name, '.' ,@table_name,' WHERE cid=', @cid_,' LIMIT ', @chunk_sz_);
    PREPARE stmt3 FROM @sql_text3;
    EXECUTE stmt3;
    SELECT ROW_COUNT() INTO @num_deleted;
    DEALLOCATE PREPARE stmt3;
    
    IF @num_deleted <= 0 THEN
        LEAVE loop_label;
    END IF;

  END LOOP;

  SET @sql_text4 = concat('DELETE FROM ', @db_name, '.' ,@table_name,' WHERE cid=', @cid_);
  PREPARE stmt4 FROM @sql_text4;
  EXECUTE stmt4;
  DEALLOCATE PREPARE stmt4;
END
//

delimiter ;


DROP PROCEDURE IF EXISTS sp_delete_where;
delimiter //
CREATE PROCEDURE `sp_delete_where`(table_name VARCHAR(255), where_clause VARCHAR(255), chunk_sz INT)
BEGIN
  SET @table_name = table_name;
  SET @where_clause = where_clause;
  SET @chunk_sz_ = chunk_sz;
  SET @num_deleted = 0;
  loop_label:  LOOP
    SET @sql_text3 = concat('DELETE FROM ' , @table_name,' ', @where_clause , ' LIMIT ',@chunk_sz_);
    PREPARE stmt3 FROM @sql_text3;
    EXECUTE stmt3;
    SELECT ROW_COUNT() INTO @num_deleted;
    DEALLOCATE PREPARE stmt3;
    IF @num_deleted <= 0 THEN
        LEAVE loop_label;
    END IF;
  END LOOP;
  SET @sql_text4 = concat('DELETE FROM ' , @table_name,' ', @where_clause );
  PREPARE stmt4 FROM @sql_text4;
  EXECUTE stmt4;
  DEALLOCATE PREPARE stmt4;
END
//

delimiter ;


DROP PROCEDURE IF EXISTS sp_cmon_deletenet;
DROP PROCEDURE IF EXISTS sp_cmon_deletedisk;
DROP PROCEDURE IF EXISTS sp_cmon_deleteram;
DROP PROCEDURE IF EXISTS sp_cmon_deleteresources;
DROP PROCEDURE IF EXISTS sp_cmon_deleteresources_all;

DROP PROCEDURE IF EXISTS sp_cmon_purge_history;
DELIMITER ||
CREATE PROCEDURE  sp_cmon_purge_history()
SQL SECURITY INVOKER
BEGIN
   DECLARE _cid INTEGER;
   DECLARE done TINYINT DEFAULT 0;
   DECLARE purge_interval char(255) DEFAULT '7';
   DECLARE purge_interval_daily char(255) DEFAULT '1';
   DECLARE purge_interval_minute char(255) DEFAULT '65';
   DECLARE purge_query_histogram char(255) DEFAULT '1';
   DECLARE epoch1x timestamp DEFAULT '2000-01-01 00:00:01';
   DECLARE epoch2x timestamp DEFAULT '2000-01-01 00:00:01';
   DECLARE epoch1 BIGINT DEFAULT 0;
   DECLARE epoch2 BIGINT DEFAULT 0;
   DECLARE cur CURSOR FOR SELECT id FROM cluster;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
   SELECT UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL purge_interval DAY)) INTO epoch1;
   SELECT DATE_SUB(NOW(), INTERVAL purge_interval DAY) INTO epoch1x;
   SELECT UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL purge_interval_daily DAY)) INTO epoch2;
   SELECT DATE_SUB(NOW(), INTERVAL purge_interval_daily DAY) INTO epoch2x;    
   DELETE FROM simple_alarm WHERE  report_ts <= epoch2x ;
   DELETE FROM mysql_statistics_history WHERE  report_ts <= epoch1;
   DELETE FROM mysql_advisor_history WHERE report_ts <= epoch1x and cid>0;
   DELETE FROM collected_logs WHERE created <= epoch1x ;
   DELETE FROM expression_result_history WHERE report_ts <= epoch1x and cid>0;
   OPEN cur;
   read_loop: 
       LOOP FETCH FROM cur INTO _cid;
         IF done THEN 
	     LEAVE read_loop; 
         END IF;
         SELECT ifnull(value,7) INTO purge_interval FROM cmon_configuration WHERE param='PURGE' and cid=_cid LIMIT 1;
    	 SELECT IFNULL((SELECT value  FROM cmon_configuration WHERE param='PURGE_QUERY_HISTOGRAM' and cid=_cid LIMIT 1),1) INTO purge_query_histogram;
         DELETE FROM mysql_performance_results WHERE cid=_cid AND  report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
         DELETE FROM cmon_job WHERE cid=_cid AND  report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
         DELETE FROM cmon_job_message WHERE cid=_cid AND report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
         DELETE FROM cluster_log WHERE cid=_cid AND report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
         DELETE FROM backup_log WHERE cid=_cid AND report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
         DELETE FROM restore_log WHERE cid=_cid AND report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
         DELETE FROM backup WHERE cid=_cid AND report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
         DELETE FROM restore WHERE cid=_cid AND report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
         DELETE FROM alarm_log WHERE cid=_cid AND report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
         DELETE FROM mysql_query_histogram WHERE cid=_cid AND ts <= UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL purge_query_histogram DAY));
         DELETE FROM mysql_slow_queries WHERE cid=_cid AND report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);	
	     DELETE FROM db_growth WHERE cid=_cid AND report_ts <= UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 366 DAY));	      
    	 DELETE FROM table_growth WHERE cid=_cid AND report_ts <= UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 366 DAY));	      
         DELETE FROM tx_deadlock_log WHERE cid=_cid AND  report_ts <= DATE_SUB(NOW(), INTERVAL purge_interval DAY);
   END LOOP;
   SELECT id INTO _cid FROM cluster LIMIT 1;
   CLOSE cur;
END;
||
DELIMITER ;

DROP EVENT IF EXISTS e_clear_tables;
delimiter ||
CREATE EVENT e_clear_tables
   ON SCHEDULE
     EVERY 1 DAY STARTS '2011-09-01 03:00:00'
   COMMENT 'Clears out tables each day at 3am.'
   DO
     BEGIN
         CALL sp_cmon_purge_history();
    END
||
delimiter ;

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
