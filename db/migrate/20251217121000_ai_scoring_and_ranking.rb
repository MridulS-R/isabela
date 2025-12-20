class AiScoringAndRanking < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :toxicity_score, :float, null: false, default: 0.0
    add_column :posts, :nsfw_score, :float, null: false, default: 0.0
    add_column :posts, :hot_score, :float, null: false, default: 0.0
    add_column :posts, :needs_review, :boolean, null: false, default: false
    add_index :posts, :hot_score

    add_column :comments, :toxicity_score, :float, null: false, default: 0.0
  end
end

