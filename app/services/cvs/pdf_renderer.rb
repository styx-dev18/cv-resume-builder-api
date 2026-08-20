module Cvs
  # Renders a Cv to a PDF that mirrors the frontend's CVPreview.tsx layout:
  # an ERB template (app/views/cvs/pdf.html.erb) reproduces that component's
  # markup/spacing 1:1, and Grover (headless Chromium) turns the resulting
  # HTML into a PDF so the two stay visually identical.
  class PdfRenderer
    FONT_DIR = Rails.root.join("app/assets/fonts/open_sans")
    FONT_WEIGHTS = [ 400, 600, 700 ].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(cv:)
      @cv = cv
    end

    def call
      Grover.new(html).to_pdf
    end

    private

    attr_reader :cv

    def html
      Cvs::PdfRenderController.render(
        template: "cvs/pdf",
        layout: false,
        assigns: { cv: cv, font_faces_css: font_faces_css }
      )
    end

    # Embeds the real Open Sans font files as base64 data URIs so the PDF
    # is byte-for-byte the same typeface as the live preview, without
    # Chromium needing network access to fetch a font at render time.
    def font_faces_css
      FONT_WEIGHTS.map do |weight|
        data = Base64.strict_encode64(File.binread(FONT_DIR.join("open-sans-latin-#{weight}-normal.woff2")))
        <<~CSS
          @font-face {
            font-family: 'Open Sans';
            font-style: normal;
            font-weight: #{weight};
            font-display: swap;
            src: url(data:font/woff2;base64,#{data}) format('woff2');
          }
        CSS
      end.join("\n")
    end
  end
end
