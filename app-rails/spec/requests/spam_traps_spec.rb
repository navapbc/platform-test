RSpec.describe "Spam trap protection for public forms", type: :request do
  before do

    allow_any_instance_of(Users::PasswordsController).to receive(:auth_service).and_return(
      AuthService.new(Auth::MockAdapter.new)
    )
    
  end


  forms = [
    {
      name: "Password reset instructions",
      path: "/users/forgot-password",
      param_key: :users_forgot_password_form,
      valid_params: {
        email: "UsernameDoesntExistForSure@example.com"
      }
    },
    {
      name: "Password confirm reset",
      path: "/users/reset-password",
      param_key: :users_reset_password_form,
      valid_params: {
        email: "testIsANewUser@example.com",
        code: "123456",
        password: "aLongPassword123"
      }
    },
    {
      name: "Registration",
      path: "/users/registrations",
      param_key: :users_registration_form,
      valid_params: {
        email: "evenneweruser@example.com",
        password: "aLongPassword123"
      }
    }
  ]

  forms.each do |form|
    describe "#{form[:name]} form" do
      let(:spam_params) do
        {
          form[:param_key] => form[:valid_params].merge(spam_trap: "I am a bot")
        }
      end

      let(:valid_params) do
        {
          form[:param_key] => form[:valid_params]
        }
      end

      it "rejects spam submissions" do
        post form[:path], params: spam_params
        expect(response).to have_http_status(422), "Expected 422 for #{form[:name]} form, but got #{response.status}"
      end

      it "allows valid submissions" do
        post form[:path], params: valid_params
        puts response.body
        puts "#########"
        expect(response).to have_http_status(302), "Expected redirect for valid #{form[:name]} form, but got #{response.status}"
      end
    end
  end
end
