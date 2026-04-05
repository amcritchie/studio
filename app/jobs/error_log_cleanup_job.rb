class ErrorLogCleanupJob < ApplicationJob
  queue_as :default

  def perform(days_old: 30)
    count = ErrorLog.where("created_at < ?", days_old.days.ago).delete_all
    Rails.logger.info "[ErrorLogCleanupJob] Deleted #{count} error logs older than #{days_old} days"
  end
end
