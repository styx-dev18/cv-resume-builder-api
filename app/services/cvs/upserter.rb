module Cvs
  # Full-document upsert: the frontend autosaves the entire CV (sections and
  # items included) on every change, always keyed by client-generated
  # UUIDs. This diffs the incoming payload against the current rows,
  # updating/creating what's present and destroying whatever the client
  # dropped, rather than modeling create vs. update separately.
  class Upserter
    def self.call(...)
      new(...).call
    end

    def initialize(user:, cv_id:, params:)
      @user = user
      @cv_id = cv_id
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        cv = user.cvs.find_or_initialize_by(id: cv_id)
        cv.title = params[:title]
        cv.schema_version = params[:schemaVersion] || cv.schema_version || 1
        cv.save!

        sync_sections(cv, params[:sections] || [])
        cv
      end
    end

    private

    attr_reader :user, :cv_id, :params

    def sync_sections(cv, sections_params)
      incoming_ids = sections_params.map { |s| s[:id] }.compact
      cv.cv_sections.where.not(id: incoming_ids).destroy_all

      sections_params.each_with_index do |section_params, index|
        section = cv.cv_sections.find_or_initialize_by(id: section_params[:id])
        section.section_type = section_params[:type]
        section.title = section_params[:title]
        section.position = index
        section.save!

        sync_items(section, section_params[:items] || [])
      end
    end

    def sync_items(section, items_params)
      incoming_ids = items_params.map { |i| i[:id] }.compact
      section.cv_section_items.where.not(id: incoming_ids).destroy_all

      items_params.each_with_index do |item_params, index|
        item = section.cv_section_items.find_or_initialize_by(id: item_params[:id])
        item.assign_attributes(CvSectionItem.attributes_from_json(section.section_type, item_params))
        item.position = index
        item.save!
      end
    end
  end
end
