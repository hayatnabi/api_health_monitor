class CreateApiHealthLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :api_health_logs do |t|
      t.string :url
      t.string :status
      t.integer :latency_ms
      t.text :headers
      t.text :error
      t.datetime :checked_at

      t.timestamps
    end
  end
end
