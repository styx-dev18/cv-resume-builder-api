module Cvs
  # Deep-copies a CV (sections and items included) under fresh
  # server-generated UUIDs at all three levels.
  class Duplicator
    def self.call(...)
      new(...).call
    end

    def initialize(source_cv:, new_title: nil)
      @source_cv = source_cv
      @new_title = new_title
    end

    def call
      ActiveRecord::Base.transaction do
        copy = source_cv.dup
        copy.title = new_title.nil? ? "#{source_cv.title} (Copy)" : new_title
        copy.save!

        source_cv.cv_sections.each do |section|
          new_section = section.dup
          new_section.cv = copy
          new_section.save!

          section.cv_section_items.each do |item|
            new_item = item.dup
            new_item.cv_section = new_section
            new_item.save!
          end
        end

        copy
      end
    end

    private

    attr_reader :source_cv, :new_title
  end
end
