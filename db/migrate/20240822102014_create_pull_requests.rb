class CreatePullRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :pull_requests do |t|
      t.string :url
      t.string :title
      t.text :body
      t.string :repo_owner
      t.string :repo
      t.string :creator
      t.json :comments
      t.json :commits
      t.text :diff
      t.datetime :pr_created_at
      t.datetime :pr_updated_at

      t.timestamps
    end
  end
end
