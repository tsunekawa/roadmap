# frozen_string_literal: true

# == Schema Information
#
# Table name: stats
#
#  id         :integer          not null, primary key
#  count      :integer          default(0)
#  date       :date             not null
#  details    :text
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  org_id     :integer
#

require "set"

class StatCreatedPlan < Stat

  serialize :details, JSON

  def by_template
    by_template = self.details["by_template"]
    return [] unless by_template.present?
    by_template
  end

  class << self

    def to_csv(created_plans, details: { by_template: false })
      if details[:by_template]
        to_csv_by_template(created_plans)
      else
        super(created_plans)
      end
    end

    private

    def to_csv_by_template(created_plans)
      template_names = lambda do |created_plans|
        unique = Set.new
        created_plans.each do |created_plan|
          created_plan.details&.fetch("by_template", [])&.each do |name_count|
            unique.add(name_count.fetch("name"))
          end
        end
        unique.to_a
      end.call(created_plans)

      data = created_plans.map do |created_plan|
        tuple = { date: created_plan.date }
        template_names.reduce(tuple) do |acc, name|
          acc[name] = 0
          acc
        end
        created_plan.details&.fetch("by_template", [])&.each do |name_count|
          tuple[name_count.fetch("name")] = name_count.fetch("count")
        end
        tuple[:count] = created_plan.count
        tuple
      end

      Csvable.from_array_of_hashes(data)
    end

  end

end
