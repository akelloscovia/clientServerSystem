ALTER TABLE `visitor_logs`
  MODIFY COLUMN `status` ENUM('waiting', 'pending', 'assigned', 'attended', 'closed') NOT NULL DEFAULT 'waiting';
