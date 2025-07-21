class AddIndexToApiHealthLogs < ActiveRecord::Migration[8.0]
  def change
    add_index :api_health_logs, :url
    add_index :api_health_logs, :checked_at
  end
end
