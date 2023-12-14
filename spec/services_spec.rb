require "services"
RSpec.describe "Services" do
  it "has app_env of test when APP_ENV is test" do
    expect(Services.app_env).to eq("test")
  end
  it "has a logger" do
    expect(Services.logger.class).to eq(SemanticLogger::Logger)
  end
end
