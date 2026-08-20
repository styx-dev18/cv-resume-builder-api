require "rails_helper"

RSpec.describe Cvs::PdfRenderer do
  let(:user) { create(:user) }
  let(:cv) { create(:cv, user: user, title: "My CV") }

  it "renders the cv to HTML and hands it to Grover for PDF conversion" do
    section = create(:cv_section, cv: cv, section_type: "experience", title: "Work", position: 0)
    create(:cv_section_item, cv_section: section, position: 0,
      company: "Acme", job_title: "Engineer", location: "Remote",
      start_date: "2020-01", end_date: "", current: true, description: "<p>Did stuff</p>")

    grover = instance_double(Grover, to_pdf: "%PDF-1.7 fake bytes")
    html = nil
    allow(Grover).to receive(:new) { |content| html = content; grover }

    result = described_class.call(cv: cv)

    expect(result).to eq("%PDF-1.7 fake bytes")
    expect(html).to include("Acme", "Engineer", "Remote", "Did stuff", "Work")
  end

  it "sanitizes rich-text HTML fields before embedding them" do
    section = create(:cv_section, cv: cv, section_type: "summary", title: "Summary", position: 0)
    create(:cv_section_item, cv_section: section, position: 0,
      content: "<p>Hi<script>alert(1)</script></p>")

    grover = instance_double(Grover, to_pdf: "bytes")
    html = nil
    allow(Grover).to receive(:new) { |content| html = content; grover }

    described_class.call(cv: cv)

    expect(html).to include("Hi")
    expect(html).not_to include("<script>")
  end

  it "embeds the Open Sans font as base64 so rendering has no network dependency" do
    grover = instance_double(Grover, to_pdf: "bytes")
    html = nil
    allow(Grover).to receive(:new) { |content| html = content; grover }

    described_class.call(cv: cv)

    expect(html).to include("@font-face", "font-family: 'Open Sans'", "data:font/woff2;base64,")
  end
end
