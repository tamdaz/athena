require "./routing_spec_helper"

do_with_config do |client|
  describe "Constraints" do
    context "that is valid" do
      it "works" do
        client.get("/get/constraints/4:5:6").body.should eq "\"4:5:6\""
      end
    end

    context "that is invalid" do
      it "returns correct error" do
        response = client.get("/get/constraints/4:a:6")
        response.body.should eq %({"code":404,"message":"No route found for 'GET /get/constraints/4:a:6'"})
        response.status_code.should eq 404
      end
    end
  end
end