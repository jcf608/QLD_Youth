# frozen_string_literal: true

# AuditLog model for security and compliance tracking
# Records all significant actions for audit trail
#
# Actions: login, logout, login_failed, create, update, delete, access_denied, etc.
# Status: success, failure
#
class AuditLog < ActiveRecord::Base
  # Associations
  belongs_to :user, optional: true # May be nil for failed login attempts

  # Validations
  validates :action, presence: true
  validates :status, presence: true, inclusion: { in: %w[success failure] }

  # Scopes
  scope :successes, -> { where(status: 'success') }
  scope :failures, -> { where(status: 'failure') }
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :for_action, ->(action) { where(action: action) }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :since, ->(time) { where('created_at > ?', time) }

  # Log an action
  #
  # @param action [String] Action performed
  # @param user [User, nil] User who performed action
  # @param status [String] 'success' or 'failure'
  # @param options [Hash] Additional context
  # @return [AuditLog] Created log entry
  def self.log(action:, user: nil, status: 'success', **options)
    create!(
      user: user,
      action: action,
      status: status,
      resource_type: options[:resource_type],
      resource_id: options[:resource_id],
      ip_address: options[:ip_address],
      user_agent: options[:user_agent],
      change_data: options[:changes], # Renamed column to avoid AR conflict
      metadata: options[:metadata],
      error_message: options[:error_message]
    )
  end

  # Log successful login
  def self.log_login(user, ip_address: nil, user_agent: nil)
    log(
      action: 'login',
      user: user,
      status: 'success',
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: { login_at: Time.current.iso8601 }
    )
  end

  # Log failed login attempt
  def self.log_login_failed(email_or_username, reason:, ip_address: nil)
    log(
      action: 'login_failed',
      user: nil,
      status: 'failure',
      ip_address: ip_address,
      error_message: reason,
      metadata: { attempted_login: email_or_username }
    )
  end

  # Log logout
  def self.log_logout(user, ip_address: nil)
    log(
      action: 'logout',
      user: user,
      status: 'success',
      ip_address: ip_address
    )
  end

  # Log permission denial
  def self.log_access_denied(user, permission, resource_type: nil, resource_id: nil)
    log(
      action: 'access_denied',
      user: user,
      status: 'failure',
      resource_type: resource_type,
      resource_id: resource_id,
      error_message: "Permission denied: #{permission}",
      metadata: { required_permission: permission }
    )
  end

  # Log resource access (document view, etc.)
  def self.log_access(user, resource_type, resource_id)
    log(
      action: 'access',
      user: user,
      status: 'success',
      resource_type: resource_type,
      resource_id: resource_id
    )
  end

  # Get recent failed login attempts for an email/username
  #
  # @param email_or_username [String] Email or username
  # @param since [Time] Look back this far
  # @return [Integer] Count of failed attempts
  def self.failed_login_count(email_or_username, since: 15.minutes.ago)
    where(action: 'login_failed', status: 'failure')
      .where('created_at > ?', since)
      .where("metadata->>'attempted_login' = ?", email_or_username)
      .count
  end
end
