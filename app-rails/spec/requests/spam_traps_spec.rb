




  RSpec.describe "Spam trap protection for public forms", type: :request do
    before do
      Users::PasswordsController.auth_service = AuthService.new(Auth::MockAdapter.new)
      Users::RegistrationsController.auth_service = AuthService.new(Auth::MockAdapter.new)
      Users::SessionsController.auth_service = AuthService.new(Auth::MockAdapter.new(uid_generator: -> { "mock-uid" }))
    end

    after do
      # Clean up so this doesn't leak across tests
      Users::PasswordsController.auth_service = nil
      Users::RegistrationsController.auth_service = nil
      Users::SessionsController.auth_service = nil
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
      },
      {
        name: "Login",
        path: "/users/sign_in",
        param_key: :users_new_session_form,
        valid_params: {
          email: "test@example.com",
          password: "password"
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

        it "rejects spam submissions" do
          post form[:path], params: spam_params
          expect(response).to have_http_status(422), "Expected 422 for #{form[:name]} form, but got #{response.status}"
        end
      end
    end
  end
