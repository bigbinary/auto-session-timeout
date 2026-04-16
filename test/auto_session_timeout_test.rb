# frozen_string_literal: true

require_relative "test_helper"

describe AutoSessionTimeout do
  # Stub controller that includes AutoSessionTimeout for testing
  class StubController
    include AutoSessionTimeout

    attr_accessor :session, :signed_in, :current_user_obj, :sign_out_called_with,
      :reset_session_called, :single_sign_out_called

    def initialize
      @session = {}
      @signed_in = false
      @current_user_obj = nil
      @sign_out_called_with = nil
      @reset_session_called = false
      @single_sign_out_called = false
    end

    def user_signed_in?
      @signed_in
    end

    def current_user
      @current_user_obj
    end

    def sign_out(user)
      @sign_out_called_with = user
    end

    def reset_session
      @reset_session_called = true
    end

    def single_sign_out
      @single_sign_out_called = true
    end
  end

  describe "#handle_session_reset" do
    it "does not call single_sign_out" do
      controller = StubController.new
      controller.signed_in = true
      controller.current_user_obj = "user"
      controller.send(:handle_session_reset, controller)

      assert_equal false, controller.single_sign_out_called
    end

    it "calls sign_out with current_user when user is signed in" do
      controller = StubController.new
      controller.signed_in = true
      controller.current_user_obj = "the_user"
      controller.send(:handle_session_reset, controller)

      assert_equal "the_user", controller.sign_out_called_with
    end

    it "does not call sign_out when user is not signed in" do
      controller = StubController.new
      controller.signed_in = false
      controller.send(:handle_session_reset, controller)

      assert_nil controller.sign_out_called_with
    end

    it "always calls reset_session" do
      controller = StubController.new
      controller.signed_in = false
      controller.send(:handle_session_reset, controller)

      assert controller.reset_session_called
    end
  end

  describe "#set_session_expiry" do
    it "sets auto_session_started_at alongside auto_session_expires_at when session is fresh" do
      controller = StubController.new

      controller.send(:set_session_expiry, controller, 3600)

      refute_nil controller.session[:auto_session_started_at]
      refute_nil controller.session[:auto_session_expires_at]
      assert_in_delta Time.now.to_f, controller.session[:auto_session_started_at].to_f, 1.0
      assert_in_delta (Time.now + 3600).to_f, controller.session[:auto_session_expires_at].to_f, 1.0
    end

    it "does not overwrite timestamps when auto_session_expires_at is already set" do
      controller = StubController.new
      original_started_at = Time.now - 1000
      original_expires_at = Time.now + 3600
      controller.session[:auto_session_started_at] = original_started_at
      controller.session[:auto_session_expires_at] = original_expires_at

      controller.send(:set_session_expiry, controller, 3600)

      assert_equal original_started_at, controller.session[:auto_session_started_at]
      assert_equal original_expires_at, controller.session[:auto_session_expires_at]
    end

    it "does nothing when offset is nil" do
      controller = StubController.new

      controller.send(:set_session_expiry, controller, nil)

      assert_nil controller.session[:auto_session_started_at]
      assert_nil controller.session[:auto_session_expires_at]
    end
  end
end
