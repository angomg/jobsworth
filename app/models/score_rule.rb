class ScoreRule < ActiveRecord::Base
  include ScoreRuleTypes

  attr_accessible(:name, :score, :score_type, :exponent)

  belongs_to :controlled_by, 
             :polymorphic => true

  validates :exponent,
            :presence => true

  validates :name, 
            :presence => true,
            :length   => { :maximum => 30 }

  validates :score, 
            :presence     => true, 
            :numericality => true

  validates :score_type,
            :presence  => true,
            :inclusion => { :in => ScoreRuleTypes::all_score_types }
  

  def calculate_score_for(task)
    case score_type
      when FIXED then 
        score
      when TASK_AGE then 
        task_age = get_task_age_for(task)
        score * (task_age ** exponent)
      when LAST_COMMENT_AGE then
        last_comment_age = get_last_comment_age_for(task)
        score * (last_comment_age ** exponent)
      when OVERDUE then
        pass_due_age = get_pass_due_age_for(task)
        score * (pass_due_age ** exponent)
    end
  end

  private 

  def get_task_age_for(task)
    # If the task is brand new 'created_at' should be nil, this code sets
    # a default value for it.
    task_created_at = (task.created_at.nil?) ? Time.now.utc : task.created_at
    (Date.today - task_created_at.to_date).to_f
  end

  def get_last_comment_age_for(task)
    # Set last_comment_started to a default value (in case the task doesn't 
    # have comments)
    last_comment_started_at = Time.now.utc

    if task.work_logs.any? and not task.work_logs.last.started_at.nil?
      last_comment_started_at = task.work_logs.last.started_at
    end
    (Date.today - last_comment_started_at.to_date).to_f
  end

  def get_pass_due_age_for(task)
    target_date = (task.target_date || Time.now.utc).to_date
    target_date <= Date.today ? 0.0 : (target_date - Date.today).to_f 
  end
end
