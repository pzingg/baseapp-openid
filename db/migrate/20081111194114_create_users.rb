class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string   :login
      t.string   :email
      t.string   :state, :null => :false, :default => 'passive'
      t.string   :crypted_password
      t.string   :password_salt
      t.string   :remember_token
      t.string   :activation_code, :limit => 40
      t.string   :password_reset_code, :limit => 40
      t.integer  :login_count
      t.datetime :last_request_at
      t.datetime :last_login_at
      t.datetime :current_login_at
      t.datetime :activated_at
      t.datetime :deleted_at
      t.datetime :remember_token_expires_at
      t.string   :last_login_ip
      t.string   :current_login_ip
      t.string   :im
      t.string   :twitter
      t.string   :cell_phone

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
