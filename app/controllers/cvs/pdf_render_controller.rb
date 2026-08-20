module Cvs
  # A minimal ActionController used only to render the PDF template to an
  # HTML string outside of a request cycle. Deliberately does not inherit
  # from ApplicationController: that class carries browser-facing concerns
  # (session/cookies, importmap staleness) that don't apply here and would
  # needlessly couple PDF rendering to the browser app shell.
  class PdfRenderController < ActionController::Base
  end
end
