Grover.configure do |config|
  config.options = {
    format: "A4",
    print_background: true,
    prefer_css_page_size: true,
    wait_until: "networkidle0",
    timeout: 20_000
  }
end
