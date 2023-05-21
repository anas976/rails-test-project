class CreateTriggerLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :trigger_logs do |t|
      t.datetime :last_requested_at

      t.timestamps
    end
  end
end
