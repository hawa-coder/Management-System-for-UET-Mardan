-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: 127.0.0.1    Database: dcmcs
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `app_notifications`
--

DROP TABLE IF EXISTS `app_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `app_notifications` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `type` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `app_notifications_user_id_read_at_index` (`user_id`,`read_at`),
  CONSTRAINT `app_notifications_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_notifications`
--

LOCK TABLES `app_notifications` WRITE;
/*!40000 ALTER TABLE `app_notifications` DISABLE KEYS */;
INSERT INTO `app_notifications` VALUES (1,1,'complaint','Complaint submitted','CMP-260822-0001 was submitted successfully.','2026-08-22 05:17:06','2026-08-22 04:33:54','2026-08-22 05:17:06'),(2,1,'complaint','Complaint submitted','CMP-260823-0002 was submitted successfully.','2026-08-23 14:13:08','2026-08-23 13:29:40','2026-08-23 14:13:08'),(3,1,'complaint','Complaint status updated','CMP-260823-0002 is now forwarded.','2026-08-24 01:05:21','2026-08-23 14:15:10','2026-08-24 01:05:21'),(4,1,'complaint','Complaint submitted','CMP-260824-0003 was submitted successfully.','2026-08-24 14:44:50','2026-08-24 01:29:03','2026-08-24 14:44:50'),(5,1,'complaint','Complaint submitted','CMP-260824-0004 was submitted successfully.','2026-08-24 14:44:50','2026-08-24 01:35:53','2026-08-24 14:44:50'),(6,1,'complaint','Complaint status updated','CMP-260824-0004 is now forwarded.','2026-08-24 14:44:50','2026-08-24 01:38:06','2026-08-24 14:44:50'),(7,23,'complaint','Complaint submitted','CMP-260825-0005 was submitted successfully.','2026-08-25 01:56:00','2026-08-25 01:55:51','2026-08-25 01:56:00'),(8,23,'complaint','Complaint status updated','CMP-260825-0005 is now resolved.',NULL,'2026-08-25 01:58:44','2026-08-25 01:58:44'),(9,24,'complaint','Complaint submitted','CMP-260825-0006 was submitted successfully.',NULL,'2026-08-25 11:04:30','2026-08-25 11:04:30'),(10,24,'complaint','Complaint status updated','CMP-260825-0006 is now review.',NULL,'2026-08-25 11:15:35','2026-08-25 11:15:35');
/*!40000 ALTER TABLE `app_notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache`
--

LOCK TABLES `cache` WRITE;
/*!40000 ALTER TABLE `cache` DISABLE KEYS */;
INSERT INTO `cache` VALUES ('laravel-cache-27ac7b9f1a3bcc93f6f3a1876604af3d6221c498','i:1;',1787551562),('laravel-cache-27ac7b9f1a3bcc93f6f3a1876604af3d6221c498:timer','i:1787551562;',1787551562),('laravel-cache-487ae4882cca92fea4016732d9e9f480693adc8d','i:1;',1787509802),('laravel-cache-487ae4882cca92fea4016732d9e9f480693adc8d:timer','i:1787509802;',1787509802),('laravel-cache-5c785c036466adea360111aa28563bfd556b5fba','i:1;',1788462039),('laravel-cache-5c785c036466adea360111aa28563bfd556b5fba:timer','i:1788462039;',1788462039),('laravel-cache-6da661f742887900502b1064248d5ff65e83ce7c','i:1;',1788421123),('laravel-cache-6da661f742887900502b1064248d5ff65e83ce7c:timer','i:1788421123;',1788421123),('laravel-cache-76e45613249c12e8980db76a800bca5d0f2fe340','i:1;',1787512550),('laravel-cache-76e45613249c12e8980db76a800bca5d0f2fe340:timer','i:1787512550;',1787512550),('laravel-cache-f3594f0c9a86885796a2ad4caa0c2dcda9e0a1d0','i:3;',1787596049),('laravel-cache-f3594f0c9a86885796a2ad4caa0c2dcda9e0a1d0:timer','i:1787596049;',1787596049);
/*!40000 ALTER TABLE `cache` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_locks`
--

LOCK TABLES `cache_locks` WRITE;
/*!40000 ALTER TABLE `cache_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_locks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaint_comments`
--

DROP TABLE IF EXISTS `complaint_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `complaint_comments` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `comment` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `complaint_comments_complaint_id_foreign` (`complaint_id`),
  KEY `complaint_comments_user_id_foreign` (`user_id`),
  CONSTRAINT `complaint_comments_complaint_id_foreign` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`id`) ON DELETE CASCADE,
  CONSTRAINT `complaint_comments_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint_comments`
--

LOCK TABLES `complaint_comments` WRITE;
/*!40000 ALTER TABLE `complaint_comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `complaint_comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaint_histories`
--

DROP TABLE IF EXISTS `complaint_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `complaint_histories` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` bigint(20) unsigned NOT NULL,
  `acted_by` bigint(20) unsigned DEFAULT NULL,
  `action` varchar(255) NOT NULL,
  `from_status` varchar(255) DEFAULT NULL,
  `to_status` varchar(255) NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `complaint_histories_complaint_id_foreign` (`complaint_id`),
  KEY `complaint_histories_acted_by_foreign` (`acted_by`),
  CONSTRAINT `complaint_histories_acted_by_foreign` FOREIGN KEY (`acted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `complaint_histories_complaint_id_foreign` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaint_histories`
--

LOCK TABLES `complaint_histories` WRITE;
/*!40000 ALTER TABLE `complaint_histories` DISABLE KEYS */;
INSERT INTO `complaint_histories` VALUES (1,1,1,'Complaint submitted',NULL,'submitted',NULL,'2026-08-22 04:33:54','2026-08-22 04:33:54'),(2,2,1,'Complaint submitted',NULL,'submitted',NULL,'2026-08-23 13:29:40','2026-08-23 13:29:40'),(3,2,2,'Forward coordinator','submitted','forwarded',NULL,'2026-08-23 14:15:10','2026-08-23 14:15:10'),(4,3,1,'Complaint submitted',NULL,'submitted',NULL,'2026-08-24 01:29:03','2026-08-24 01:29:03'),(5,4,1,'Complaint submitted',NULL,'submitted',NULL,'2026-08-24 01:35:53','2026-08-24 01:35:53'),(6,4,2,'Forward coordinator','submitted','forwarded',NULL,'2026-08-24 01:38:06','2026-08-24 01:38:06'),(7,5,23,'Complaint submitted',NULL,'submitted',NULL,'2026-08-25 01:55:51','2026-08-25 01:55:51'),(8,5,13,'Resolve','submitted','resolved',NULL,'2026-08-25 01:58:44','2026-08-25 01:58:44'),(9,6,24,'Complaint submitted',NULL,'submitted',NULL,'2026-08-25 11:04:30','2026-08-25 11:04:30'),(10,6,13,'Accept','submitted','review',NULL,'2026-08-25 11:15:35','2026-08-25 11:15:35');
/*!40000 ALTER TABLE `complaint_histories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `complaints`
--

DROP TABLE IF EXISTS `complaints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `complaints` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `complaint_number` varchar(255) NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `details` text NOT NULL,
  `attachment_path` varchar(255) DEFAULT NULL,
  `attachment_name` varchar(255) DEFAULT NULL,
  `attachment_mime` varchar(100) DEFAULT NULL,
  `category` varchar(255) NOT NULL,
  `priority` enum('Low','Medium','High') NOT NULL DEFAULT 'Medium',
  `status` enum('submitted','review','forwarded','office','dean','resolved','rejected') NOT NULL DEFAULT 'submitted',
  `current_handler_role` varchar(255) NOT NULL DEFAULT 'adviser',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `complaints_complaint_number_unique` (`complaint_number`),
  KEY `complaints_user_id_foreign` (`user_id`),
  KEY `complaints_status_current_handler_role_index` (`status`,`current_handler_role`),
  CONSTRAINT `complaints_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `complaints`
--

LOCK TABLES `complaints` WRITE;
/*!40000 ALTER TABLE `complaints` DISABLE KEYS */;
INSERT INTO `complaints` VALUES (1,'CMP-260822-0001',1,'No internet','having no internet in deparment',NULL,NULL,NULL,'Internet','Medium','submitted','adviser','2026-08-22 04:33:54','2026-08-22 04:33:54'),(2,'CMP-260823-0002',1,'hostel issue','hostel',NULL,NULL,NULL,'Hostel','Medium','forwarded','coordinator','2026-08-23 13:29:40','2026-08-23 14:15:10'),(3,'CMP-260824-0003',1,'Tour not scheduled yet','in spring semester out tour was missed we wanna to arrange tour',NULL,NULL,NULL,'Other','Medium','submitted','adviser','2026-08-24 01:29:03','2026-08-24 01:29:03'),(4,'CMP-260824-0004',1,'result','spring 2026',NULL,NULL,NULL,'Other','Medium','forwarded','coordinator','2026-08-24 01:35:53','2026-08-24 01:38:06'),(5,'CMP-260825-0005',23,'no internet','internet','complaint-attachments/iiNFDry7rBLe6Fo0HPKsBSIt6kuJcpsAs5XqI9LU.png','Screenshot 2026-06-20 225520.png','image/png','Internet','Medium','resolved','closed','2026-08-25 01:55:51','2026-08-25 01:58:44'),(6,'CMP-260825-0006',24,'attendance problem','bad attendance in Machine Learning subject','complaint-attachments/obgHKGhuQavZmE3nuIrsRMGQoaYSskc804KKglQL.png','Screenshot 2026-06-20 225520.png','image/png','Attendance','Medium','review','adviser','2026-08-25 11:04:30','2026-08-25 11:15:35');
/*!40000 ALTER TABLE `complaints` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `failed_jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `failed_jobs`
--

LOCK TABLES `failed_jobs` WRITE;
/*!40000 ALTER TABLE `failed_jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `failed_jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_batches`
--

LOCK TABLES `job_batches` WRITE;
/*!40000 ALTER TABLE `job_batches` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_batches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL,
  `reserved_at` int(10) unsigned DEFAULT NULL,
  `available_at` int(10) unsigned NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `migrations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `migrations`
--

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES (1,'0001_01_01_000000_create_users_table',1),(2,'0001_01_01_000001_create_cache_table',1),(3,'0001_01_01_000002_create_jobs_table',1),(4,'2026_08_22_000001_create_complaints_table',1),(5,'2026_08_22_000002_create_complaint_histories_table',1),(6,'2026_08_22_000003_create_notices_table',1),(7,'2026_08_22_000004_create_app_notifications_table',1),(8,'2026_08_22_080113_create_personal_access_tokens_table',2),(9,'2026_08_24_000001_add_academic_details_to_users_table',3),(10,'2026_08_24_000002_add_account_status_to_users_table',4),(11,'2026_08_25_000001_add_attachment_to_complaints_table',5),(12,'2026_08_25_000002_create_complaint_comments_table',6),(13,'2026_08_25_000003_link_notices_to_complaints_table',7);
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notices`
--

DROP TABLE IF EXISTS `notices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notices` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `complaint_id` bigint(20) unsigned DEFAULT NULL,
  `published_by` bigint(20) unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `audience` varchar(255) NOT NULL DEFAULT 'all',
  `published_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `notices_complaint_id_unique` (`complaint_id`),
  KEY `notices_published_by_foreign` (`published_by`),
  CONSTRAINT `notices_complaint_id_foreign` FOREIGN KEY (`complaint_id`) REFERENCES `complaints` (`id`) ON DELETE SET NULL,
  CONSTRAINT `notices_published_by_foreign` FOREIGN KEY (`published_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notices`
--

LOCK TABLES `notices` WRITE;
/*!40000 ALTER TABLE `notices` DISABLE KEYS */;
INSERT INTO `notices` VALUES (1,NULL,4,'Mid-term examination schedule','The revised mid-term date sheet is available from the department office.','all','2026-08-22 02:58:31','2026-08-22 02:58:31','2026-08-22 02:58:31');
/*!40000 ALTER TABLE `notices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_reset_tokens`
--

DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_reset_tokens`
--

LOCK TABLES `password_reset_tokens` WRITE;
/*!40000 ALTER TABLE `password_reset_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_reset_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `personal_access_tokens`
--

DROP TABLE IF EXISTS `personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) unsigned NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personal_access_tokens`
--

LOCK TABLES `personal_access_tokens` WRITE;
/*!40000 ALTER TABLE `personal_access_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `personal_access_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('student','adviser','coordinator','chairman','office','dean') NOT NULL DEFAULT 'student',
  `registration_number` varchar(255) DEFAULT NULL,
  `department` varchar(255) NOT NULL DEFAULT 'Computer Science',
  `batch` varchar(255) DEFAULT NULL,
  `semester` tinyint(3) unsigned DEFAULT NULL,
  `section` varchar(255) DEFAULT NULL,
  `mobile_number` varchar(20) DEFAULT NULL,
  `batch_adviser_id` bigint(20) unsigned DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `account_status` enum('pending','approved','rejected') NOT NULL DEFAULT 'approved',
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`),
  UNIQUE KEY `users_registration_number_unique` (`registration_number`),
  KEY `users_batch_adviser_id_foreign` (`batch_adviser_id`),
  CONSTRAINT `users_batch_adviser_id_foreign` FOREIGN KEY (`batch_adviser_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'Hawa Sabir','2023cs001@uetmardan.edu.pk','2026-08-25 11:55:58','$2y$12$5mfRfqyEXmbse/kH60Q37eGrfMXkuslXK2yoUaHxlht0QODUa9Kim','student','2023-CS-001','Computer Science','2023',NULL,'A',NULL,NULL,1,'approved',NULL,'2026-08-22 02:58:30','2026-08-25 11:55:58'),(2,'Dr. Ahmad','adviser@uetmardan.edu.pk','2026-08-24 13:40:37','$2y$12$BvXL5HXwjpVq4rGz4kRK6eBlN0nfXB/jeSTkgBsTDhQuUxWqeU1nO','adviser',NULL,'Computer Science','2023',NULL,NULL,NULL,NULL,0,'approved',NULL,'2026-08-22 02:58:30','2026-08-25 11:55:59'),(3,'Coordinator','coordinator@uetmardan.edu.pk','2026-08-25 11:55:58','$2y$12$24.0XLVCwx59binZe9Wcc.qZmd/ZYlHvroZJzGqOEo2Zz1lWAGdaa','coordinator',NULL,'Computer Science',NULL,NULL,NULL,NULL,NULL,1,'approved',NULL,'2026-08-22 02:58:31','2026-08-25 11:55:58'),(4,'Usman','chairman@uetmardan.edu.pk','2026-08-25 11:55:58','$2y$12$5SgrQ7Nj/FjLk93yqDBYEOxHQRafrhCYG6b.g0X91MoYskIODH0GC','chairman',NULL,'Computer Science',NULL,NULL,NULL,NULL,NULL,1,'approved',NULL,'2026-08-22 02:58:31','2026-08-25 11:55:58'),(5,'Department Staff','office@uetmardan.edu.pk','2026-08-25 11:55:59','$2y$12$xq2NBZFwPu3WZdjhHo1bOeq0dH.S5baVC24Y9d6iUj4EmimIKukxu','office',NULL,'Computer Science',NULL,NULL,NULL,NULL,NULL,1,'approved',NULL,'2026-08-22 02:58:31','2026-08-25 11:55:59'),(6,'Dean','dean@uetmardan.edu.pk','2026-08-25 11:55:59','$2y$12$c3O0ohUjigJnUwrc2k9P/.jvjz0U4v6DEy17HRhyfZPTr6fBXCCS6','dean',NULL,'Computer Science',NULL,NULL,NULL,NULL,NULL,1,'approved',NULL,'2026-08-22 02:58:31','2026-08-25 11:55:59'),(7,'Inayat','inayat@uetmardan.edu.pk','2026-08-24 13:40:37','$2y$12$IjuLWqIw7Ltth9O/7gynBOdVVLdf5HrbFU52mD9r4gTkUTbCgX8qq','adviser',NULL,'Computer Science','2023',NULL,'AI',NULL,NULL,0,'approved',NULL,'2026-08-24 13:40:37','2026-08-25 11:55:59'),(8,'Ali','ali@uetmardan.edu.pk','2026-08-24 13:40:37','$2y$12$kbmtAKrM3lMLSOVscF.WbuTrPOdQ.IAT0E2OappoLUJcXYzuJcdqS','adviser',NULL,'Computer Science','2023',NULL,'DS',NULL,NULL,0,'approved',NULL,'2026-08-24 13:40:37','2026-08-25 11:55:59'),(9,'Noor','noor@uetmardan.edu.pk','2026-08-24 13:40:38','$2y$12$dkqxglps4.vit.A1HiRT/Owhn.9ZU9pllpgpD7CA6UfAqfrADjPNq','adviser',NULL,'Computer Science','2023',NULL,'CS',NULL,NULL,0,'approved',NULL,'2026-08-24 13:40:38','2026-08-25 11:55:59'),(10,'Dr. Shams Ur Rahman','shams.ur.rahman@uetmardan.edu.pk','2026-08-25 11:55:59','$2y$12$115MXITc6SFdA9BVQ4itZe28adCYvclh2qo35ClAKXbNjXNhH9i5y','adviser',NULL,'Computer Science','Batch 05',8,'AI',NULL,NULL,1,'approved',NULL,'2026-08-25 01:24:58','2026-08-25 11:55:59'),(11,'Dr. Tariq Sadad','tariq.sadad@uetmardan.edu.pk','2026-08-25 11:56:00','$2y$12$3TLB7sMKA2SIOJaOfCQ2quNFDhi.KMilHNamh995mGY7wEevYBBRS','adviser',NULL,'Computer Science','Batch 05',8,'CS',NULL,NULL,1,'approved',NULL,'2026-08-25 01:24:59','2026-08-25 11:56:00'),(12,'Ms. Faiza Tila','faiza.tila@uetmardan.edu.pk','2026-08-25 11:56:00','$2y$12$c4pTMTjX/i1wuNCn0EXFUulzQWFWkyECkfHMggVq6JnadCZPyIfF6','adviser',NULL,'Computer Science','Batch 05',8,'DS',NULL,NULL,1,'approved',NULL,'2026-08-25 01:24:59','2026-08-25 11:56:00'),(13,'Dr. Inayat Khan','inayat.khan@uetmardan.edu.pk','2026-08-25 11:56:00','$2y$12$CjpI2E1yAQOY/cAoNoUiIerkYAtFHoZRelWd5HpnGBxJsOSQArjEW','adviser',NULL,'Computer Science','Batch 06',6,'AI',NULL,NULL,1,'approved',NULL,'2026-08-25 01:24:59','2026-08-25 11:56:00'),(14,'Mr. Mian Saeed Akbar','mian.saeed.akbar@uetmardan.edu.pk','2026-08-25 11:56:01','$2y$12$JWLZCQO74k1HBqdxybxiF.TATT8bCvdnoqqW6BpFu/lFXkYNYFD06','adviser',NULL,'Computer Science','Batch 06',6,'CS',NULL,NULL,1,'approved',NULL,'2026-08-25 01:25:00','2026-08-25 11:56:01'),(15,'Dr. Raza Ullah Khan','raza.ullah.khan@uetmardan.edu.pk','2026-08-25 11:56:01','$2y$12$jMB77DzcFRzKXBtNdLqWbuwwfp50qXoZwzQxalQBaIL9HG4o9H.c.','adviser',NULL,'Computer Science','Batch 06',6,'DS',NULL,NULL,1,'approved',NULL,'2026-08-25 01:25:00','2026-08-25 11:56:01'),(16,'Mr. Zaheen Ahmed','zaheen.ahmed@uetmardan.edu.pk','2026-08-25 11:56:01','$2y$12$toP.MCxfOvDYcY3l/r2aFeci2A.TTvz0np6v2zAGhWaHtwn7tuLya','adviser',NULL,'Computer Science','Batch 07',4,'A',NULL,NULL,1,'approved',NULL,'2026-08-25 01:25:00','2026-08-25 11:56:01'),(17,'Mr. Bilal Khan','bilal.khan@uetmardan.edu.pk','2026-08-25 11:56:02','$2y$12$HthMrhO20zRrpQ8Dbuzo9OtuWvAL7nbU9zdtO0Xk0VON91dyq716O','adviser',NULL,'Computer Science','Batch 07',4,'B',NULL,NULL,1,'approved',NULL,'2026-08-25 01:25:01','2026-08-25 11:56:02'),(18,'Mr. Abdul Saboor','abdul.saboor@uetmardan.edu.pk','2026-08-25 11:56:02','$2y$12$0M0rawgeo3pJjWgBasSnW.veg6/k9dHBp1JRLfNM3zKNzQj5bukNO','adviser',NULL,'Computer Science','Batch 07',4,'C',NULL,NULL,1,'approved',NULL,'2026-08-25 01:25:01','2026-08-25 11:56:02'),(19,'Mr. Asad Jan','asad.jan@uetmardan.edu.pk','2026-08-25 11:56:02','$2y$12$QNcJMzGdfLP3H0AWwWjBeOrgifx84BcP7Wb21xGtSHx36I06jGQMC','adviser',NULL,'Computer Science','Batch 07',4,'D',NULL,NULL,1,'approved',NULL,'2026-08-25 01:25:01','2026-08-25 11:56:02'),(20,'Ms. Alishba Orakzai','alishba.orakzai@uetmardan.edu.pk','2026-08-25 11:56:03','$2y$12$1W0W9lJWZLwkSJDsbyhZzOzlw0XfWUvpzZhO94HovYBcoBplzuO8m','adviser',NULL,'Computer Science','Batch 08',2,'A',NULL,NULL,1,'approved',NULL,'2026-08-25 01:25:02','2026-08-25 11:56:03'),(21,'Ms. Hafsa Fayyaz','hafsa.fayyaz@uetmardan.edu.pk','2026-08-25 11:56:03','$2y$12$TzPqIkvA5/l2aeva5wJIP.w5bRSwQhhsikTrgfwIRtcZlqoBdrl9G','adviser',NULL,'Computer Science','Batch 08',2,'B',NULL,NULL,1,'approved',NULL,'2026-08-25 01:25:02','2026-08-25 11:56:03'),(22,'Muhammad Danyal','muhammad.danyal@uetmardan.edu.pk','2026-08-25 11:56:03','$2y$12$6.K99POFQX76P6v6kLw4cOqq8mRHCL89aCqfKbCPSAIhMatAXX2lq','adviser',NULL,'Computer Science','Batch 08',2,'C',NULL,NULL,1,'approved',NULL,'2026-08-25 01:25:02','2026-08-25 11:56:03'),(23,'Ali khan','235@uetmardan.edu.pk',NULL,'$2y$12$MMKrHF5nGmDBAOW/i84uquF0nFsvrEqIOLopBuS4KdOTgklq9AAJG','student','2023MDBCS235','Computer Science','2023',7,'AI','03928304893',13,1,'approved',NULL,'2026-08-25 01:35:42','2026-08-25 01:47:27'),(24,'Noor Khan','429@uetmardan.edu.pk',NULL,'$2y$12$PWzXK.IyILNhsYod9s2Iq.oU9ba9o/t5xYLsjfh1OnrvcjW0IuXwK','student','2023MDBCS429','Computer Science','2023',5,'AI','03709282383',13,1,'approved',NULL,'2026-08-25 10:56:28','2026-08-25 11:00:29');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'dcmcs'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-04  0:02:20
