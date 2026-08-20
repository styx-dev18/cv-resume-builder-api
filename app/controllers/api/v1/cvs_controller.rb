module Api
  module V1
    class CvsController < BaseController
      UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

      before_action :authenticate_user!
      before_action :ensure_valid_id, only: [ :show, :update, :destroy, :duplicate, :pdf ]

      # Client-generated UUIDs make a same-id collision with another user's
      # row astronomically unlikely, but not impossible to construct.
      rescue_from ActiveRecord::RecordNotUnique, with: :render_conflict

      def index
        cvs = current_user.cvs.order(updated_at: :desc)
        render_data CvSummaryResource.new(cvs).as_json
      end

      def show
        cv = current_user.cvs.includes(cv_sections: :cv_section_items).find(params[:id])
        render_data CvResource.new(cv).as_json
      end

      def update
        cv = Cvs::Upserter.call(user: current_user, cv_id: params[:id], params: cv_params)
        render_data CvResource.new(cv).as_json
      end

      def destroy
        current_user.cvs.find(params[:id]).destroy!
        head :no_content
      end

      def duplicate
        source = current_user.cvs.includes(cv_sections: :cv_section_items).find(params[:id])
        copy = Cvs::Duplicator.call(source_cv: source, new_title: params[:title])
        render_data CvResource.new(copy).as_json, status: :created
      end

      def pdf
        cv = current_user.cvs.includes(cv_sections: :cv_section_items).find(params[:id])
        send_data Cvs::PdfRenderer.call(cv: cv),
          filename: "#{cv.title.presence || 'cv'}.pdf",
          type: "application/pdf",
          disposition: "attachment"
      end

      private

      def ensure_valid_id
        return if params[:id].to_s.match?(UUID_REGEX)
        render_error(status: :not_found, code: "not_found", message: "Couldn't find Cv")
      end

      def render_conflict(_exception)
        render_error(status: :conflict, code: "conflict", message: "That id is already in use")
      end

      def cv_params
        params.require(:cv).permit(
          :title, :schemaVersion,
          sections: [
            :id, :type, :title,
            items: [
              :id, :fullName, :location, :email, :phone, :linkedin, :github, :otherLink,
              :content, :company, :position, :startDate, :endDate, :current, :description,
              :school, :degree, :honors, :gpa, :category, :skills, :name, :date, :language,
              :proficiency, :link, :title, :publisher, :issuer, :relationship, :organization, :role
            ]
          ]
        )
      end
    end
  end
end
