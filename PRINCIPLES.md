# Kyndryl Agentic AI Platform - Architectural Principles

## Project Overview
Agentic Workflow Orchestrator developed in partnership with UTS OPTIK AI for enterprise retail operations and beyond. This platform enables autonomous AI and human expert collaboration across organizational boundaries.

## Documentation Structure

All project documentation is organized in the `doc/` folder by category:

- **[doc/README.md](doc/README.md)** - Complete documentation index and navigation
- **[doc/architecture/](doc/architecture/)** - System design and patterns (7 docs)
- **[doc/guides/](doc/guides/)** - User and operational guides (26 docs)
- **[doc/implementation/](doc/implementation/)** - Phase implementation plans (11 docs)
- **[doc/testing/](doc/testing/)** - Test strategies and results (17 docs)
- **[doc/handoffs/](doc/handoffs/)** - Session transitions (19 docs)
- **[doc/compliance/](doc/compliance/)** - Reviews and audits (21 docs)
- **[doc/features/](doc/features/)** - Feature documentation (40 docs)
- **[doc/history/](doc/history/)** - Completed work records (72 docs)
- **[doc/refactoring/](doc/refactoring/)** - Code improvements (9 docs)

**Total:** 222 organized documents + this file + README.md + 🚀_START_HERE.md

---

## 1. Core Architecture

### 1.1 Code Organization
- **Keep files short**: Delegate to superclass or other classes
- **Minimize line count**: Use composition and inheritance
- **Single Responsibility**: Each class/file has one clear purpose
- **Delegate common patterns to superclass**: If multiple classes share identical methods, move to base class ⭐ IMPORTANT
  - Error handling patterns should be in base class
  - Common validation logic should be in base class
  - Shared utility methods should be in base class
  - **Bad Example:** Every production client has identical `ensure_configured!` method
  - **Good Example:** Base class provides `ensure_configured!`, children just call it
- **Prefer Ruby scripts over shell scripts**: Use `.rb` files instead of `.sh` when possible
  - Ruby scripts are more maintainable and easier to debug
  - Better error handling and cross-platform compatibility
  - Consistent with the project's primary language
- **Script Organization**: All development scripts organized in `script/` directory
  - `script/utilities/` - Database, debugging, and system utilities
  - `script/manual_tests/` - Manual testing scripts (complement automated tests)
  - `script/examples/` - Example code and demonstrations
  - See Section 11.6 for complete details
  - **Never put scripts in project root** (keep root clean)
- **Running Ruby scripts**: Use Rails runner for scripts that need the Rails environment
  - **Correct**: `~/.rbenv/shims/ruby ./bin/rails runner bin/script_name.rb`
  - **Why**: Ensures correct Ruby version (3.3.3) and Rails environment are loaded
  - For standalone scripts: `~/.rbenv/shims/ruby script_name.rb`
  - For organized scripts: `ruby script/utilities/script_name.rb`
  - This project uses rbenv for Ruby version management
- **Use GitHub CLI (`gh`) over git commands**: Prefer `gh` for repository operations
  - Better integration with GitHub features (PRs, issues, releases)
  - More user-friendly output and interactive prompts
  - Handles authentication seamlessly

### 1.2 Code Quality & Readability
- **Avoid regex when possible**: Use simple string methods (`.include?`, `.start_with?`, `.sub`, `.strip`) instead
  - Regex is hard to read and maintain
  - Only use regex when absolutely necessary for complex pattern matching
  - When regex is required, add clear comments explaining what it does
- **Avoid hardcoding when possible**: Discover data dynamically from configuration or database ⭐ IMPORTANT
  - Hardcoded lists become stale and require code changes to extend
  - Discover from configuration files, database, or credentials
  - Only hardcode when absolutely necessary (constants, enums that never change)
  - **Bad Example:** `[:sap, :slack, :teams].each { |service| ... }` (hardcoded list)
  - **Good Example:** `Rails.application.credentials.dig(:integrations).keys.each { |service| ... }` (discovered)
- **Avoid case statements when metaprogramming is clearer**: Use metaprogramming for repetitive patterns ⭐ IMPORTANT
  - Case statements that repeat the same pattern should use metaprogramming
  - Reduces duplication and makes code more maintainable
  - Adding new cases doesn't require code changes
  - **Bad Example:** Multiple methods with identical case statement patterns
    ```ruby
    def create_slack_client(mode)
      case mode
      when :sandbox then Sandbox::SandboxSlackClient.new
      when :simulation then Simulation::MockSlackClient.new
      when :production then Real::RealSlackClient.new
      end
    end
    
    def create_sap_client(mode)
      case mode
      when :sandbox then Sandbox::SandboxSapClient.new
      when :simulation then Simulation::MockSapClient.new
      when :production then Real::RealSapClient.new
      end
    end
    # ... more repetitive methods
    ```
  - **Good Example:** Single metaprogrammed method using constants and const_get
    ```ruby
    MODE_CONFIG = {
      sandbox: { module: Sandbox, prefix: 'Sandbox' },
      simulation: { module: Simulation, prefix: 'Mock' },
      production: { module: Real, prefix: 'Real' }
    }.freeze
    
    def self.create_client(service_name, mode)
      config = MODE_CONFIG[mode]
      raise ArgumentError, "Invalid mode" unless config
      
      class_name = "#{config[:prefix]}#{service_name.to_s.camelize}Client"
      config[:module].const_get(class_name).new
    end
    
    # Usage: create_client(:slack, :sandbox) - works for any service!
    ```
  - **When to use case statements:** Use when patterns are truly different, not repetitive
  - **Scrutinize every case statement:** Ask "Is this pattern repeating? Could metaprogramming eliminate duplication?"
- **Extract repeated code to methods**: If you write the same code twice, extract it to a method
  - Methods should be 5-15 lines when possible (justify longer methods with comments)
  - Each method should have a single, clear purpose
  - Name methods after what they do, not how they do it
- **Prefer explicit over clever**: Code should be obvious in intent
  - Exception: Metaprogramming that eliminates significant duplication is worth the abstraction
- **Comments for complex logic**: If it needs explanation, explain it

### 1.3 DRY Design Patterns

#### 1.3.1 Factory Pattern
Use factory classes to centralize and standardize object creation, especially when creation logic varies by context.

**When to Use:**
- Creating objects based on runtime conditions
- Complex initialization logic
- Multiple creation strategies

**Example (Existing Pattern):**
```ruby
# Good: Factory centralizes creation logic
class AiServiceFactory
  def self.default_service
    mode = EnvironmentMode.current_mode
    provider = SystemSetting.get("ai_provider")
    
    case mode
    when :sandbox then Sandbox::SandboxAnthropicService.new
    when :simulation then Simulation::MockAnthropicService.new
    when :production then provider_service(provider)
    end
  end
  
  def self.anthropic_service
    create_service(:anthropic)
  end
  
  def self.openai_service
    create_service(:openai)
  end
  
  private
  
  def self.create_service(provider)
    mode = EnvironmentMode.current_mode
    # Centralized creation logic here
  end
end

# Usage: Never instantiate services directly
ai_service = AiServiceFactory.default_service
ai_service = AiServiceFactory.anthropic_service
```

**Benefits:**
- Single place to change creation logic
- Consistent object initialization
- Respects environment modes
- Easy to test and mock

#### 1.3.2 Service Object Pattern
Extract complex business logic into dedicated service classes. One service per business operation.

**When to Use:**
- Business logic doesn't naturally belong in a model
- Operation involves multiple models
- Complex workflows or orchestrations
- Need to test business logic in isolation

**Pattern:**
```ruby
# Good: Service object with single responsibility
class WorkflowExecutionService
  def initialize(workflow, user)
    @workflow = workflow
    @user = user
  end
  
  def execute
    validate_preconditions!
    assign_experts
    create_execution_steps
    notify_participants
    
    { success: true, execution: @execution }
  rescue StandardError => e
    { success: false, error: e.message }
  end
  
  private
  
  def validate_preconditions!
    # Validation logic
  end
  
  def assign_experts
    # Expert assignment logic
  end
  
  # ... other private methods
end

# Usage in controller
result = WorkflowExecutionService.new(workflow, current_user).execute
if result[:success]
  render json: result[:execution]
else
  render json: { error: result[:error] }, status: :unprocessable_entity
end
```

**Benefits:**
- Keeps controllers thin
- Keeps models focused on data
- Testable in isolation
- Clear single responsibility

#### 1.3.3 Template Method Pattern
Define algorithm structure in base class, let subclasses override specific steps.

**When to Use:**
- Multiple classes follow same algorithm with variations
- Want to enforce sequence but allow customization
- Prevent duplication of algorithm structure

**Pattern:**
```ruby
# Good: Template method in base class
class BaseClient
  def execute_request(endpoint, data)
    prepare_request(endpoint, data)
    response = send_request
    process_response(response)
  rescue StandardError => e
    handle_error(e)
  end
  
  private
  
  # Template steps - subclasses override these
  def prepare_request(endpoint, data)
    raise NotImplementedError
  end
  
  def send_request
    raise NotImplementedError
  end
  
  def process_response(response)
    response  # Default implementation
  end
  
  def handle_error(error)
    Rails.logger.error("#{self.class.name}: #{error.message}")
    raise
  end
end

class SapClient < BaseClient
  private
  
  def prepare_request(endpoint, data)
    @endpoint = "#{base_url}/#{endpoint}"
    @payload = data.to_json
  end
  
  def send_request
    HTTP.post(@endpoint, body: @payload, headers: headers)
  end
end
```

**Benefits:**
- Algorithm structure defined once
- Consistent error handling
- Easy to add new implementations
- Clear extension points

#### 1.3.4 Query Object Pattern
Extract complex database queries into dedicated query objects.

**When to Use:**
- Complex queries with multiple conditions
- Queries reused across controllers/services
- Building composable query methods
- Need to test query logic separately

**Pattern:**
```ruby
# Good: Query object for complex filtering
class ExpertQuery
  def initialize(relation = DigitalExpert.all)
    @relation = relation
  end
  
  def with_capabilities(capability_names)
    @relation = @relation.joins(:capabilities)
                         .where(capabilities: { name: capability_names })
                         .distinct
    self
  end
  
  def available_for_workflow(workflow)
    @relation = @relation.where.not(
      id: workflow.assigned_experts.select(:id)
    )
    self
  end
  
  def in_domain(domain)
    @relation = @relation.where(domain: domain)
    self
  end
  
  def results
    @relation
  end
end

# Usage: Composable and reusable
experts = ExpertQuery.new
  .with_capabilities(['sap_integration', 'data_analysis'])
  .available_for_workflow(workflow)
  .in_domain('retail')
  .results
```

**Benefits:**
- Queries are reusable and composable
- Testable in isolation
- Keeps models and controllers clean
- Easy to modify and extend

#### 1.3.5 Decorator/Presenter Pattern
Separate presentation logic from models.

**When to Use:**
- Formatting data for views
- View-specific methods don't belong in models
- Multiple representations of same data
- Keep models free of presentation concerns

**Pattern:**
```ruby
# Good: Decorator for presentation logic
class WorkflowPresenter
  def initialize(workflow)
    @workflow = workflow
  end
  
  def status_badge_class
    case @workflow.status
    when 'completed' then 'badge-success'
    when 'failed' then 'badge-error'
    when 'executing' then 'badge-warning'
    else 'badge-neutral'
    end
  end
  
  def formatted_duration
    return 'Not started' unless @workflow.started_at
    
    duration = Time.current - @workflow.started_at
    "#{(duration / 3600).to_i}h #{((duration % 3600) / 60).to_i}m"
  end
  
  def expert_summary
    "#{@workflow.experts.count} experts (#{@workflow.digital_experts.count} digital, #{@workflow.human_experts.count} human)"
  end
  
  # Delegate other methods to workflow
  def method_missing(method, *args, &block)
    @workflow.send(method, *args, &block)
  end
  
  def respond_to_missing?(method, include_private = false)
    @workflow.respond_to?(method, include_private) || super
  end
end

# Usage in controller
workflow = WorkflowPresenter.new(@workflow)
render json: {
  status_class: workflow.status_badge_class,
  duration: workflow.formatted_duration,
  expert_summary: workflow.expert_summary
}
```

**Benefits:**
- Models stay focused on business logic
- Views get clean, formatted data
- Reusable across different views
- Testable presentation logic

### 1.4 Rails-Specific DRY Patterns

#### 1.4.1 Concerns vs Base Classes
Use concerns for cross-cutting behavior, inheritance for hierarchical relationships.

**Concerns (Mixins):**
```ruby
# Good: Concern for cross-cutting behavior
module Auditable
  extend ActiveSupport::Concern
  
  included do
    belongs_to :created_by, class_name: 'User', optional: true
    belongs_to :updated_by, class_name: 'User', optional: true
    
    before_create :set_created_by
    before_update :set_updated_by
  end
  
  private
  
  def set_created_by
    self.created_by ||= Current.user
  end
  
  def set_updated_by
    self.updated_by = Current.user
  end
end

# Usage: Mix into any model
class Workflow < ApplicationRecord
  include Auditable
  # Now has created_by/updated_by tracking
end

class Expert < ApplicationRecord
  include Auditable
  # Also has created_by/updated_by tracking
end
```

**Base Classes (Inheritance):**
```ruby
# Good: Base class for hierarchical relationship
class BaseExpert < ApplicationRecord
  self.abstract_class = true
  
  has_many :capabilities
  validates :name, presence: true
  
  def available?
    raise NotImplementedError
  end
  
  def assign_to_workflow(workflow)
    # Common assignment logic
  end
end

class DigitalExpert < BaseExpert
  def available?
    true  # Always available
  end
end

class HumanExpert < BaseExpert
  def available?
    !out_of_office? && within_working_hours?
  end
end
```

**When to Use:**
- **Concerns**: Cross-cutting behavior (auditing, soft deletes, tagging)
- **Base Classes**: Shared domain logic and hierarchy (Expert types)

#### 1.4.2 ActiveRecord Scope Reuse
Extract common query patterns to scopes.

**Pattern:**
```ruby
# Good: Reusable scopes
class Workflow < ApplicationRecord
  scope :active, -> { where(status: ['pending', 'executing', 'paused']) }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :for_company, ->(company) { where(company_id: company.id) }
  scope :urgent, -> { where('deadline < ?', 24.hours.from_now) }
  
  # Composable scopes
  scope :with_expert, ->(expert) {
    joins(:workflow_experts).where(workflow_experts: { expert_id: expert.id })
  }
end

# Usage: Clean and composable
Workflow.active.recent.urgent
Workflow.for_company(company).completed
Workflow.with_expert(expert).active
```

**Benefits:**
- Reusable across controllers and services
- Composable and chainable
- Testable
- Self-documenting

#### 1.4.3 Callback Extraction
Don't duplicate callback logic - extract to concerns or base classes.

**Pattern:**
```ruby
# Good: Shared callbacks in concern
module StatusTransitionCallbacks
  extend ActiveSupport::Concern
  
  included do
    before_update :validate_state_transition, if: :status_changed?
    after_update :notify_status_change, if: :saved_change_to_status?
  end
  
  private
  
  def validate_state_transition
    unless valid_transition?(status_was, status)
      errors.add(:status, "Invalid transition from #{status_was} to #{status}")
      throw :abort
    end
  end
  
  def notify_status_change
    StatusChangeNotificationJob.perform_later(self)
  end
  
  def valid_transition?(from, to)
    # Transition validation logic
  end
end

# Usage in multiple models
class Workflow < ApplicationRecord
  include StatusTransitionCallbacks
end

class WorkflowExecutionStep < ApplicationRecord
  include StatusTransitionCallbacks
end
```

**Benefits:**
- Callback logic defined once
- Consistent behavior across models
- Easy to test
- Reduces model bloat

#### 1.4.4 Form Objects for Complex Forms
Extract complex form logic to form objects.

**When to Use:**
- Form spans multiple models
- Complex validation logic
- Virtual attributes not persisted
- Multi-step form wizards

**Pattern:**
```ruby
# Good: Form object for complex workflow creation
class WorkflowCreationForm
  include ActiveModel::Model
  
  attr_accessor :name, :goal, :company_id, :user_id,
                :expert_ids, :success_criteria, :deadline
  
  validates :name, :goal, :company_id, presence: true
  validates :expert_ids, length: { minimum: 1 }
  validate :experts_available
  
  def save
    return false unless valid?
    
    ActiveRecord::Base.transaction do
      create_workflow
      assign_experts
      create_success_criteria
      notify_participants
    end
    
    true
  rescue StandardError => e
    errors.add(:base, e.message)
    false
  end
  
  private
  
  def create_workflow
    @workflow = Workflow.create!(
      name: name,
      goal: goal,
      company_id: company_id,
      created_by_id: user_id,
      deadline: deadline
    )
  end
  
  def assign_experts
    # Assignment logic
  end
  
  def experts_available
    # Validation logic
  end
end

# Usage in controller
form = WorkflowCreationForm.new(workflow_params)
if form.save
  render json: { success: true }
else
  render json: { errors: form.errors }, status: :unprocessable_entity
end
```

**Benefits:**
- Controller stays thin
- Models stay focused
- Complex validation in one place
- Transaction handling centralized

### 1.5 Test DRY Principles

#### 1.5.1 Shared Test Setup
Don't repeat test data setup - use setup blocks and helpers.

**Pattern:**
```ruby
# Good: Shared setup and helpers
class WorkflowTest < ActiveSupport::TestCase
  def setup
    @company = companies(:kyndryl)
    @user = users(:admin)
    @workflow = create_test_workflow
  end
  
  private
  
  # Test helper method
  def create_test_workflow(overrides = {})
    Workflow.create!(
      {
        name: 'Test Workflow',
        goal: 'Test Goal',
        company: @company,
        created_by: @user,
        status: 'pending'
      }.merge(overrides)
    )
  end
  
  # Assertion helper
  def assert_workflow_valid(workflow)
    assert workflow.valid?, workflow.errors.full_messages.join(', ')
    assert_equal 'pending', workflow.status
    assert_not_nil workflow.created_by
  end
end

# Usage in tests
test "should execute workflow" do
  workflow = create_test_workflow(status: 'approved')
  
  result = workflow.execute!
  
  assert result.success?
  assert_equal 'executing', workflow.reload.status
end
```

#### 1.5.2 Test Helper Modules
Extract common test utilities to helper modules.

**Pattern:**
```ruby
# test/test_helpers/authentication_helper.rb
module AuthenticationHelper
  def sign_in_as(user)
    @current_user = user
    session[:user_id] = user.id
  end
  
  def sign_out
    @current_user = nil
    session.delete(:user_id)
  end
  
  def assert_requires_authentication
    assert_response :unauthorized
    assert_match(/authentication required/i, response.body)
  end
end

# Include in test_helper.rb
class ActiveSupport::TestCase
  include AuthenticationHelper
end

# Usage in controller tests
test "should require authentication" do
  get :index
  assert_requires_authentication
end

test "should allow authenticated access" do
  sign_in_as(users(:admin))
  get :index
  assert_response :success
end
```

#### 1.5.3 Shared Examples with Concerns
Test concerns once, not in every model that includes them.

**Pattern:**
```ruby
# test/concerns/auditable_test.rb
module AuditableTest
  extend ActiveSupport::Concern
  
  included do
    test "should set created_by on create" do
      record = create_test_record
      assert_equal Current.user, record.created_by
    end
    
    test "should set updated_by on update" do
      record = create_test_record
      record.update!(name: 'Updated')
      assert_equal Current.user, record.updated_by
    end
  end
  
  private
  
  def create_test_record
    raise NotImplementedError, "Define create_test_record in test class"
  end
end

# Usage in model tests
class WorkflowTest < ActiveSupport::TestCase
  include AuditableTest
  
  private
  
  def create_test_record
    Workflow.create!(name: 'Test', company: companies(:one))
  end
  
  # Now has auditable tests automatically
end
```

**Benefits:**
- Test concern logic once
- Consistent test coverage
- Easy to add to new models
- Reduces test duplication

#### 1.5.4 Factory Methods Over Fixtures
Use factory methods when you need flexible test data.

**Pattern:**
```ruby
# test/factories/workflow_factory.rb
module WorkflowFactory
  def build_workflow(attributes = {})
    defaults = {
      name: "Test Workflow #{SecureRandom.hex(4)}",
      goal: "Test goal",
      company: companies(:kyndryl),
      created_by: users(:admin),
      status: 'pending'
    }
    
    Workflow.new(defaults.merge(attributes))
  end
  
  def create_workflow(attributes = {})
    build_workflow(attributes).tap(&:save!)
  end
  
  def create_workflow_with_experts(expert_count: 3, **attributes)
    workflow = create_workflow(attributes)
    expert_count.times do
      workflow.experts << create_digital_expert
    end
    workflow
  end
end

# Include in test_helper.rb
class ActiveSupport::TestCase
  include WorkflowFactory
end

# Usage: Flexible and readable
test "should require at least one expert" do
  workflow = build_workflow  # Not saved yet
  assert_not workflow.valid?
  
  workflow.experts << create_digital_expert
  assert workflow.valid?
end

test "should execute workflow with experts" do
  workflow = create_workflow_with_experts(expert_count: 5)
  result = workflow.execute!
  assert result.success?
end
```

**Benefits:**
- More flexible than fixtures
- Build vs create (save control)
- Composable helpers
- Easier to understand test setup

### 1.6 Documentation & Command Examples
- **NO COMMENTS in command copy/paste blocks**: Commands should be clean and directly executable
  - ❌ BAD: `./bin/rails db:migrate  # Run the migration`
  - ✅ GOOD: `./bin/rails db:migrate`
- **Single copy block for related commands**: When providing multiple related commands, put them in ONE code block
  - ❌ BAD: Three separate code blocks for three sequential commands
  - ✅ GOOD: One code block with all three commands
  - Reason: User can copy once and paste all commands
- **Explanation goes outside the code block**: Use prose before/after commands to explain
- **Multiple commands**: List each command separately with explanation between them
- **Comments are for code files only**: Not for terminal commands or configuration examples meant to be copied

---

## 2. Data & Persistence

### 2.1 Runtime Mutability
- Users can modify **any attribute** on any asset at runtime
- **Exception**: API keys stored in `.env` files
- **No ENV[] references** in application code for user-modifiable settings

### 2.2 Audit Trail
- **All modifications tracked**: Who changed what and when
- **Version history required** for: Workflows, Personas, and all critical entities
- **Coded + Free-form reasons** required for:
  - Success criteria changes
  - Validation overrides
  - Execution sequence modifications
  - Any workflow state changes

### 2.3 Created By / Updated By
- Track `created_by` and `updated_by` for all resources
- Maintain full change history with timestamps

### 2.4 Data Retention & Archival
- **12-month retention**: Archive workflows and related data after 12 months
- **Hard deletes permitted**: No soft delete requirement
- **Company deletion**: Only allowed if all workflow relationships are 12+ months old
- **No caching needed**: PostgreSQL performance is sufficient

### 2.5 Bulk Operations
- System must support bulk operations:
  - Create multiple users/experts at once
  - Bulk status updates
  - Batch imports/exports

---

## 3. User Experience

### 3.1 Human-Readable Interfaces
- **Never ask for resource IDs** on forms
- **Always show human-readable values**: Names, labels, descriptions
- Use dropdowns/selects with descriptive text
- Example: "User: Jim Freeman (Store Manager)" not "User ID: 1"

### 3.2 UI Patterns
- **Slide-out panels**: For view, edit, and create operations
- **Modals only for**:
  - Loading states (blocking user interaction during transactions)
  - Error messages with diagnostics (include copy-to-clipboard)
  - Confirmations for destructive actions
  
### 3.3 Color Palette (Nordic/Scandinavian)

**Backgrounds & Neutrals:**
- `#FAFAFA` - Main background (clean white)
- `#FFFFFF` - Card background (pure white)
- `#F5F5F7` - Tertiary background (light grey)
- `#E5E5E5` - Muted elements

**Sidebar & Navigation:**
- `#2C2C2E` - Deep charcoal

**Primary Colors (cool, muted):**
- `#5E87B0` - Primary blue (actions, links)
- `#8BA3B8` - Secondary grey-blue (subtle actions)
- `#6B9AC4` - Accent blue (highlights)

**Text Colors (high contrast):**
- `#1C1C1E` - Primary text (deep charcoal)
- `#3A3A3C` - Secondary text
- `#636366` - Tertiary text
- `#8E8E93` - Muted text

**Semantic Colors (Nordic-inspired):**
- Success: `#5A8F7B` - Muted teal
- Warning: `#D4A373` - Soft amber
- Error: `#B85C5C` - Muted red
- Info: `#5E87B0` - Cool blue

**Alternative Palettes Available:**
- `data-palette="green"` - Nature theme (sage greens)
- `data-palette="blue"` - Ocean theme (deeper blues)
- `data-palette="highcontrast"` - WCAG AAA compliant

**Design Rules:**
- Use **flat colors** for text and borders
- Use **subtle gradients** (from-X-50 to-X-100) for card backgrounds and feature highlights
- **Eased animations**: All transitions use ease-in-out timing
- **Consistent spacing**: Follow Tailwind's spacing scale
- **Typography hierarchy**: Maintain clear heading levels with appropriate weights

---

## 4. Workflow Management

### 4.1 Team Types

**Standing Teams:**
- Permanent baseline capacity
- Pre-configured for predictable workflows
- Can add members as needed
- Persistent across multiple workflows

**Adaptive Teams:**
- Ad-hoc, created for one-time workflows
- Dynamically assembled based on requirements
- Dissolved after workflow completion

**Team Switching:**
- Workflows can switch team types with approval
- Change must be audited with coded and free-form reasons

### 4.2 Workflow States

**State Sequence:** `pending → validating → approved → executing → paused → completed/failed`

**Execution Phase Sub-States:**
- Execution has **incremental states** designed by SME or user via wizard
- Defines: Who receives what data, in what order, what data passes to next persona
- **Parallel execution permitted** for independent steps
- **Sequential execution** when data dependencies exist

**State Transition Rules:**
- Must follow defined sequence (no arbitrary jumps)
- **Backwards movement permitted** within execution phase
- **Paused can happen anytime** (not just within execution)
- State changes trigger **automatic actions + notifications**
- Users can **visualize execution plan** before starting

**Checkpoints:**
- Execution can pause for human approval at defined checkpoints
- Checkpoints defined during workflow design

### 4.3 Success Criteria

**Definition:**
- Defined by **User + SME collaboration**
- Can include: baseline, target, deadline, metrics
- **Multiple criteria permitted** per workflow (AND/OR logic)

**Modification:**
- Success criteria can be modified after workflow starts
- Requires: audit trail + coded reason + free-form explanation

**Progress Measurement:**
- System **automatically measures** progress toward criteria
- Real-time visibility of progress

**Deadline Management:**
- If deadline missed: **Escalate to user** but work continues
- Does not auto-fail the workflow

### 4.4 Workflow Validation

**Pre-Approval Checks:**
- Resource availability (required experts exist and available)
- Budget validation
- Data format and completeness
- Expert capability matching

**Validation Overrides:**
- Users can override validation warnings
- Requires: coded reason + free-form explanation
- Hard blocks cannot be overridden (missing required data)

**Approval:**
- **User approves** workflows after validation
- Same validation rules for Standing and Adaptive workflows

**SLA/Timeouts:**
- Timeouts apply to **entire workflow**, not individual steps
- Configurable per workflow type

---

## 5. Expert Management

### 5.1 Expert Types

**Digital Experts (AI):**
- Have: domain, persona_id, capabilities
- Multiple experts can share same persona_id (instances/clones)
- 24/7 availability
- Instant response time

**Human Experts:**
- Have: role, escalation_hierarchy
- Subject to availability and working hours
- Can decline assignments
- Follow escalation paths

### 5.2 Capabilities Model

**Structure:**
- **HABTM relationship**: `Expert has_many :capabilities` and `Capability has_many :experts`
- **No JSON structures** for capabilities
- Use proper join table: `expert_capabilities`

**Capability Management:**
- Drawn from **master capabilities list**
- Both Digital and Human experts can **accumulate capabilities over time**
- Track when capabilities were acquired
- Capability matching for expert assignment

### 5.3 Expert Assignment

**Assignment Rules:**
- **Prefer local experts** over federated experts
- Match based on: domain, role, capabilities, availability
- Priority/ranking for specific domains (configurable)
- **Manual override permitted** by users
- No max concurrent workflows per expert

**Expert Consent:**
- Experts can **decline assignments**
- Decline/commitment occurs during **approval process**
- Declining expert must be replaced before workflow can execute

### 5.4 Expert Metrics

**Track for both Digital and Human experts:**
- Successful tasks completed
- Failure rate
- Average response time
- Workflows participated in
- Capability effectiveness scores

### 5.5 Escalation (Human Experts)

**Escalation Hierarchy:**
- Upward: `checkout_operator → team_leader → department_manager → store_manager → regional_manager → area_manager`
- **Sideways permitted**: To peers at same level

**Escalation Triggers:**
- **Automatic**: After timeout (no response)
- **Manual**: Expert can escalate before attempting
- **Failed notification**: If expert can't be reached

**Escalation Process:**
- Original expert **notified when escalation resolved**
- Escalation **does not cost more** (same billing rate)
- Escalation path logged in audit trail

**Note:** Hierarchy is **industry-specific** (supermarket example shown). System must support different hierarchies for different industries.

---

## 6. Federation & Multi-Company

### 6.1 Federation Enabled Companies

**Resource Sharing:**
- Federated companies can **share experts** across organizational boundaries
- **Explicit trust required** before sharing resources
- Trust relationships configured in `federation_config`

**Workflows Spanning Companies:**
- Workflows can span multiple companies (ecosystem thinking)
- Cross-company collaboration enabled
- Federation status tracked per company

### 6.2 Permissions

**Local vs Federated Resources:**
- **Local resources**: Full permissions
- **Federated resources**: Limited permissions
- Cannot modify another company's core configuration

**Visibility:**
- Any user can **see any other user** within the ecosystem
- Transparency across federated boundaries

### 6.3 Billing for Federated Work

**Time Claiming:**
- Experts (personas) **claim time** to workflows
- Time tracked per expert per workflow

**Billing:**
- **Company initiating workflow** is billed for all work
- Including federated expert time from other companies
- Inter-company billing settlement handled by system

---

## 7. Security & Access Control

### 7.1 Role-Based Permissions
- **Different users have different permissions** based on role
- **Admin users**: Full system access
- Permissions enforced at API level
- UI respects role permissions (hide unavailable actions)

### 7.2 Authentication
- **No authentication requirements yet** (future enhancement)
- Placeholder for: OAuth, SSO, API tokens

### 7.3 Data Privacy
- **No encryption at rest** required
- **No data residency** requirements
- **Never log**:
  - API keys
  - PII (Personally Identifiable Information)
  - Sensitive credentials

### 7.4 Credentials Management ⭐ IMPORTANT

**Use Rails Encrypted Credentials for API Keys**

All external service API keys and credentials must use Rails encrypted credentials system:

**Storage:**
- **File:** `config/credentials.yml.enc` (encrypted, safe to commit)
- **Key:** `config/master.key` (NOT in git, keep secure)
- **Access:** `Rails.application.credentials.dig(:key)`

**Editing:**
```bash
# Use project utility script
ruby script/utilities/edit_credentials.rb

# Or directly
EDITOR="mate -w" rails credentials:edit
```

**Pattern: Configuration Service Classes**

Create service classes following the `AiConfigurationService` pattern:

```ruby
class IntegrationConfigurationService
  class << self
    # Get credentials for any service (generic, no service-specific methods!)
    def get_credentials(service_name)
      credentials = Rails.application.credentials.dig(:integrations, service_name)
      raise KeyError, "#{service_name} not configured" if credentials.blank?
      credentials.symbolize_keys
    end
    
    # List all configured integrations (dynamically discovered)
    def list_configured
      all_integrations = Rails.application.credentials.dig(:integrations)
      return [] if all_integrations.blank?
      
      all_integrations.keys.select do |integration|
        credentials = all_integrations[integration]
        credentials.present? && credentials.is_a?(Hash)
      end
    end
    
    # Check if specific integration is configured
    def configured?(service_name)
      get_credentials(service_name)
      true
    rescue KeyError
      false
    end
  end
end

# Usage (clean and generic):
IntegrationConfigurationService.get_credentials(:sap)
IntegrationConfigurationService.get_credentials(:slack)
IntegrationConfigurationService.configured?(:jira)
```

**Example Credentials Structure:**
```yaml
# config/credentials.yml.enc (decrypted)
anthropic_api_key: sk-ant-...
openai_api_key: sk-...

integrations:
  service_name:
    api_url: "https://api.example.com"
    api_key: "your-key-here"
```

**Client Pattern: Lazy Loading**

Production clients should lazy-load credentials to avoid startup crashes:

```ruby
class RealServiceClient
  def initialize
    # Don't load credentials here - load lazily!
  end
  
  def some_method
    ensure_configured!  # Validate when method is called
    # Use credentials[:api_key] here
  end
  
  private
  
  def credentials
    @credentials ||= IntegrationConfigurationService.service_credentials
  end
  
  def ensure_configured!
    IntegrationConfigurationService.service_credentials
  rescue KeyError => e
    raise StandardError, "Service not configured. Run: ruby script/utilities/edit_credentials.rb"
  end
end
```

**Why This Pattern:**
1. ✅ Encrypted at rest (Rails credentials)
2. ✅ Not in version control (master.key in .gitignore)
3. ✅ Centralized access (Configuration Service)
4. ✅ Won't crash on startup (lazy loading)
5. ✅ Clear error messages (helpful instructions)
6. ✅ Consistent pattern (same as AI credentials)

**What NOT to Use:**
- ❌ ENV variables for API credentials (use Rails credentials)
- ❌ Validating credentials in `initialize` (crashes on startup)
- ❌ Hardcoded credentials (never!)
- ❌ Database storage for API keys (use encrypted credentials)

**Exception:** User-modifiable settings (not credentials) should use SystemSettings database with UI configuration.

---

## 8. API Standards

### 8.1 REST Conventions
- **Strict REST compliance**
- Standard HTTP methods: GET, POST, PUT/PATCH, DELETE
- Custom actions avoided (prefer REST resources)

### 8.2 Versioning
- Current: `/api/v1/`
- **Create v2 only for breaking changes**
- New features added to current version when backward-compatible

### 8.3 Response Standards
- **Always include timestamps** in API responses
- Consistent error format
- Pagination for large lists (configurable page size)

### 8.4 Rate Limiting
- **Rate limits on generative AI queries** matching provider maximums
- Protect against API abuse
- Per-user or per-company limits (configurable)

---

## 9. Error Handling

### 9.1 NO FALLBACKS - FAIL FAST ⭐ CRITICAL
**ABSOLUTE RULE: NEVER use fallback logic**

- If AI generation fails → operation fails (don't fall back to defaults)
- If external service fails → propagate the error (don't fall back to mock data)
- If validation fails → reject the request (don't coerce invalid data)
- **Why:** Fallbacks hide failures and create unpredictable behavior
- **Instead:** Fail fast with clear error messages so issues can be fixed

**Examples of FORBIDDEN fallbacks:**
```ruby
# ❌ WRONG - Silent fallback hides the real problem
begin
  ai_data = generate_with_ai()
rescue
  ai_data = default_data  # NO!
end

# ✅ CORRECT - Let it fail with clear error
ai_data = generate_with_ai()  # Raises exception if fails
```

### 9.2 Error Display (User-Facing)
- **Primary error message**: Clear, actionable
- **Suggested remediation steps**: How to fix the issue
- **Related resources**: Show name + ID
  - Example: "User: Jim Freeman (ID: 1)"
- **Timestamp**: When error occurred

### 9.3 Technical Details (Slide-out Panel)
- Stack trace
- Technical error details
- Request/response data
- System state at time of error
- **Copy to clipboard** functionality

### 9.4 Error Logging
- **Separate error log** (not mixed with API or Rails logs)
- Central error logging system
- Include full context for debugging
- Development: Extensive logging
- Production: Limited logging (errors and warnings only)

---

## 10. Notifications & Communication

### 10.1 Notification Channels
**Supported channels:**
- Email
- SMS
- In-app notifications
- Slack
- Microsoft Teams

### 10.2 User Preferences
- Users choose **primary and secondary channels**
- **Quiet hours** configurable per user
- Notifications follow user preferences
- Experts can **opt-out** of workflow types or domains

### 10.3 Priority Levels
- **Urgent**: Critical actions required
- **Informational**: FYI, no action needed

### 10.4 Notification Behavior
- **Send immediately** (no batching/digesting)
- **Failed notifications trigger escalation**
- **Log when sent** (audit trail)
- Track delivery status when possible

---

## 11. Testing & Quality

### 11.1 Test Coverage
- **80% code coverage** minimum
- Tests required for:
  - Models (business logic, validations, relationships)
  - Controllers (API endpoints, permissions)
  - Frontend components (rendering, user interactions)

### 11.2 Testing Approach
- **Mock AI behavior** in tests (don't call real AI APIs)
- Critical path coverage essential
- **Integration tests encouraged** for complex workflows
- Framework agnostic (RSpec/Minitest for backend, Jest/Vitest for frontend)
- **Browser automation** for UI testing (Playwright with Chromium)
  - Use headless browser tests for complex user workflows
  - Capture screenshots and console logs for debugging
  - Automate authentication and multi-step processes

### 11.3 Test at Reasonable Increments ⭐ NEW
**CRITICAL PRINCIPLE:** Test after each major component is implemented.

**When to Test:**
- ✅ After creating each new model → Run model tests
- ✅ After creating each new service → Run service tests
- ✅ After creating each new controller → Run controller tests
- ✅ After integrating components → Run integration tests
- ✅ Before committing code → Run full test suite
- ✅ After fixing bugs → Add regression test

**How to Test (Using rbenv):**
```bash
# Test specific file
~/.rbenv/shims/ruby ./bin/rails test test/models/my_model_test.rb

# Test specific directory
~/.rbenv/shims/ruby ./bin/rails test test/services/

# Test everything
~/.rbenv/shims/ruby ./bin/rails test
```

**Testing Workflow:**
1. Write component code
2. Write unit tests for component (aim for 8-12 tests per component)
3. Run tests immediately: `~/.rbenv/shims/ruby ./bin/rails test test/.../component_test.rb`
4. Fix failures before moving on
5. Run linter to check code quality
6. Commit working, tested code
7. Move to next component

**Red Flags (Stop and Test):**
- Created 3+ new methods → Write tests now
- Modified critical business logic → Add regression tests
- Added new database table → Test model validations
- Changed existing behavior → Update and run affected tests
- About to commit → Run full test suite

**Benefits:**
- Catch bugs early (cheaper to fix)
- Maintain confidence in codebase
- Enable safe refactoring
- Prevent regressions
- Document expected behavior

**Anti-Patterns to Avoid:**
- ❌ Writing all code then testing at end
- ❌ Skipping tests "to move faster"
- ❌ Testing only happy paths
- ❌ Ignoring failing tests
- ❌ Commenting out failing tests

### 11.4 Test Quality Standards
- **Each test should:**
  - Test one specific behavior
  - Have clear arrange/act/assert structure
  - Use descriptive test names (not "test_1", "test_2")
  - Include both happy and sad paths
  - Clean up after itself (transactions handle this automatically)

- **Test file structure:**
  ```ruby
  require "test_helper"

  class MyComponentTest < ActiveSupport::TestCase
    def setup
      # Arrange common test data
      @user = users(:one)
    end

    test "should do expected behavior with valid input" do
      # Arrange
      component = MyComponent.new(@user)
      
      # Act
      result = component.do_something("valid_input")
      
      # Assert
      assert result.success?
      assert_equal "expected", result.data
    end

    test "should handle invalid input gracefully" do
      component = MyComponent.new(@user)
      
      assert_raises MyComponent::ValidationError do
        component.do_something("invalid")
      end
    end
  end
  ```

### 11.5 Running Tests

**Use rbenv shims to avoid bundler issues:**

```bash
# Single test file
~/.rbenv/shims/ruby ./bin/rails test test/models/user_test.rb

# Multiple files
~/.rbenv/shims/ruby ./bin/rails test test/models/ test/services/

# All tests
~/.rbenv/shims/ruby ./bin/rails test

# With verbose output
~/.rbenv/shims/ruby ./bin/rails test -v

# Specific test by line
~/.rbenv/shims/ruby ./bin/rails test test/models/user_test.rb:15
```

**NEVER use:**
- `bundle exec rails test` (bundler version issues)
- Shell scripts for testing (use Ruby/Rails)

**Test Execution Frequency:**
- Every major component: Run component tests
- Every integration point: Run integration tests
- Before every commit: Run full suite
- After fixing bugs: Run affected tests
- Before deploy: Run full suite + manual smoke tests

### 11.6 Save Test Results for Analysis ⭐ MANDATORY

**MANDATORY PRACTICE:** ALL test runs MUST be saved to a file. NEVER run tests without redirecting output.

**Non-Negotiable Rule:**
- **EVERY** test run output MUST go to a file
- **NEVER** run tests without `> filename.txt 2>&1`
- **ALWAYS** use descriptive filenames that indicate what was tested
- Results files are the **source of truth** for test status

### 11.7 Pipe Development Server Logs to Files ⭐ BEST PRACTICE

**RECOMMENDED PRACTICE:** Development server logs should be piped to files so AI assistants (Cursor) can read them for debugging.

**Pattern:**
Use `tee` to send output to both terminal AND a file:

```bash
# API server
bundle exec rackup -p 9292 2>&1 | tee tmp/api.log

# Frontend server  
npm run dev 2>&1 | tee tmp/frontend.log

# Background workers
bundle exec sidekiq 2>&1 | tee tmp/workers.log
```

**Benefits:**
- ✅ AI assistants can read logs directly without copy/paste
- ✅ Logs still visible in terminal (tee shows both)
- ✅ Full history preserved for debugging
- ✅ Can grep/search logs without re-running
- ✅ Better collaboration and debugging

**Log File Locations:**
- Store in `tmp/` directory (already gitignored)
- Use descriptive names: `api.log`, `workers.log`, `frontend.log`
- Logs persist across restarts (useful for debugging)

**Example in package.json:**
```json
{
  "scripts": {
    "dev:api": "bundle exec rackup -p 9292 2>&1 | tee tmp/api.log",
    "dev:frontend": "npm run dev 2>&1 | tee tmp/frontend.log", 
    "dev:workers": "bundle exec sidekiq 2>&1 | tee tmp/workers.log"
  }
}
```

**When to Use:**
- ✅ Development servers (API, frontend, workers)
- ✅ Long-running processes that generate logs
- ✅ Any process you might need to debug
- ❌ One-off commands (just use terminal)
- ❌ Test runs (use `>` redirect instead, see 11.6)

**Why This Is Mandatory:**
- Test suites can take minutes to run (2,000+ tests = ~2 minutes)
- Re-running tests to check status wastes time and resources
- Results files can be grepped for ANY information without re-running
- Essential for debugging, regression testing, and baseline comparisons
- Enables sharing test results and collaboration
- Provides historical record of test evolution

**How to Save Test Results:**

```bash
# Save complete test output (recommended)
~/.rbenv/shims/ruby ./bin/rails test > test_results_full.txt 2>&1

# Save only failures and summary
~/.rbenv/shims/ruby ./bin/rails test 2>&1 | tee test_results.txt

# Save with timestamp for historical tracking
~/.rbenv/shims/ruby ./bin/rails test > test_results_$(date +%Y%m%d_%H%M%S).txt 2>&1
```

**Analyzing Saved Results:**

```bash
# Get summary
tail -20 test_results_full.txt

# Count failures
grep -E "^(Failure:|Error:)" test_results_full.txt | wc -l

# Find specific test failures
grep -A 5 "UserTest" test_results_full.txt

# Extract error patterns
grep "Admin access required" test_results_full.txt

# Compare before/after results
diff test_results_before.txt test_results_after.txt
```

### 11.7 NEVER Commit With Known Errors ⭐ CRITICAL

**CRITICAL RULE:** NEVER commit code that has known linter errors, syntax errors, or test errors.

**Non-Negotiable:**
- ✅ **ALWAYS** check for linter errors before committing: `read_lints` on modified files
- ✅ **ALWAYS** ensure tests pass (or failures are expected/documented)
- ✅ **ALWAYS** run RuboCop/linter on modified files
- ❌ **NEVER** commit if linter shows errors
- ❌ **NEVER** commit if tests have new failures
- ❌ **NEVER** push code that breaks the build

**Before Every Commit:**
```bash
# 1. Check linter errors on modified files
bin/rubocop app/models/my_model.rb

# 2. Run affected tests
bin/rails test test/models/my_model_test.rb > test_results_pre_commit.txt 2>&1

# 3. Verify no NEW failures/errors
grep "runs, .* assertions" test_results_pre_commit.txt

# 4. Only commit if clean (or failures are intentional/documented)
git add -A
git commit -m "..."
```

**Why This Is Critical:**
- Broken commits block other developers
- CI/CD pipelines fail
- Debugging becomes nightmare (which commit broke it?)
- Lost productivity across team
- Erodes confidence in codebase

**Exceptions (Rare):**
- If fixing linter errors in separate commit (document in message)
- If skipping known failing tests (mark with `skip` and document)
- If test baseline is being established (document in commit)

**File Naming Convention:**

```
test_results_full.txt          # Latest complete run
test_results_baseline.txt      # Clean baseline (all passing)
test_results_YYYYMMDD.txt      # Dated runs for comparison
test_results_feature_name.txt  # Feature-specific test runs
regression_results.txt         # Regression suite results
```

**When to Save Results (ALWAYS):**

- ✅ **MANDATORY:** Every single test run without exception
- ✅ **Always** when running full test suite
- ✅ **Always** when running partial test suites (e.g., regression only)
- ✅ Before starting major refactoring (baseline)
- ✅ After completing features (verification)
- ✅ When investigating failures (analysis)
- ✅ For regression testing (comparison)
- ✅ Before deployment (final check)
- ✅ During debugging sessions
- ✅ When fixing test failures (before/after comparison)

**What to Save in Git:**

- ❌ **Never** commit test result files to git
- ✅ **Add** `test_results*.txt` to `.gitignore`
- ✅ **Document** test statistics in commit messages
- ✅ **Keep** baseline results locally for reference

**Example Workflow:**

```bash
# 1. Save baseline (all tests passing)
~/.rbenv/shims/ruby ./bin/rails test > test_results_baseline.txt 2>&1
grep "runs, .* assertions" test_results_baseline.txt
# Output: 1825 runs, 4813 assertions, 0 failures, 0 errors, 0 skips

# 2. Make changes to codebase
# ... edit files ...

# 3. Run tests and save results
~/.rbenv/shims/ruby ./bin/rails test > test_results_new.txt 2>&1

# 4. Compare with baseline
grep "runs, .* assertions" test_results_new.txt
# Output: 1825 runs, 4813 assertions, 3 failures, 0 errors, 0 skips

# 5. Analyze failures without re-running
grep -A 5 "Failure:" test_results_new.txt | head -30

# 6. Fix issues and re-test
# ... fix code ...
~/.rbenv/shims/ruby ./bin/rails test > test_results_fixed.txt 2>&1

# 7. Verify clean
diff test_results_baseline.txt test_results_fixed.txt
```

**Benefits:**
- ⚡ Fast analysis without re-running tests
- 📊 Historical comparison of test results
- 🔍 Easy grep/search for specific failures
- 📈 Track test suite growth over time
- 🐛 Better debugging with full context
- 📝 Documentation of test state

**Anti-Patterns to Avoid:**
- ❌ Re-running tests just to see summary again
- ❌ Using `tail` or `head` on live test output (incomplete)
- ❌ Committing test result files to git
- ❌ Not saving results before major changes
- ❌ Losing baseline results (can't compare)

### 11.7 Script Directory Structure

**All development scripts organized under `script/` directory:**

```
script/
├── README.md              # Complete documentation of all scripts
├── utilities/             # Database, debugging, and system utilities
│   ├── check_executing.rb
│   ├── db_reset.rb
│   ├── debug_style_guide.rb
│   ├── edit_credentials.rb
│   └── install_style_guide_deps.rb
├── manual_tests/          # Manual testing scripts (non-automated)
│   ├── CONSOLE_TEST_GENAI.rb
│   ├── test_color_analysis.html
│   ├── test_gen_ai_services.rb
│   ├── test_kyndryl_headless.rb
│   ├── test_phase1_simple.rb
│   ├── test_phase2_simulation.rb
│   ├── test_style_guide.rb
│   └── test_url_suggestion_backend.rb
└── examples/              # Example code and demos
    ├── AI_WORKFLOW_DESIGNER_USAGE_EXAMPLE.rb
    ├── example_genai_usage.rb
    ├── federated_workflow_architecture.rb
    └── run_cli.rb
```

**Script Categories:**

**`script/utilities/`** - System maintenance and debugging
- Database management (reset, seed)
- Credentials management
- Dependency installation
- Debugging tools for specific features

**`script/manual_tests/`** - Development testing scripts
- Manual tests for specific features
- Service integration tests
- Phase testing scripts
- Console testing helpers
- Note: These complement automated tests in `test/`, not replace them

**`script/examples/`** - Example code and demos
- Usage examples for services
- Demo applications
- CLI tools for demonstrations
- Architecture proof-of-concepts

**Running Scripts:**

```bash
# Utility scripts (typically require Rails environment)
ruby script/utilities/check_executing.rb
ruby script/utilities/db_reset.rb

# Manual tests (development/debugging)
ruby script/manual_tests/test_gen_ai_services.rb
ruby script/manual_tests/test_phase1_simple.rb

# Examples (standalone or with Rails)
ruby script/examples/example_genai_usage.rb
ruby script/examples/run_cli.rb
```

**Directory Organization Rules:**
- ✅ All scripts in organized subdirectories (not root)
- ✅ README.md in script/ documents all scripts
- ✅ Clear naming conventions for easy discovery
- ✅ Manual tests don't replace automated tests
- ❌ No test/debug files in project root
- ❌ No shell scripts (prefer Ruby for consistency)

**Relationship to Automated Tests:**
- `script/manual_tests/` - Manual, ad-hoc testing during development
- `test/` - Automated test suite (models, controllers, services, integration)
- Both serve different purposes and both are important

---

## 12. System Configuration

### 12.1 AI Services - Three-Way Environment Mode ⭐ CRITICAL
**All AI service calls MUST route through AiServiceFactory to respect environment mode.**

**MANDATORY PATTERN: Always Use Factory**
```ruby
# ✅ CORRECT - Use factory (respects sandbox/simulation/production mode)
ai_service = AiServiceFactory.default_service
response = ai_service.query(prompt: "...", temperature: 0.7)

# ✅ CORRECT - Use specialized factory methods
ai_service = AiServiceFactory.for_workflow_design
ai_service = AiServiceFactory.anthropic_service
ai_service = AiServiceFactory.perplexity_service

# ❌ WRONG - Never instantiate directly (bypasses factory)
ai_service = AnthropicService.new  # NO!
ai_service = OpenAiService.new     # NO!
ai_service = PerplexityService.new # NO!
```

**CRITICAL: AI Services ALWAYS Use Real AI APIs** ⭐⭐⭐

Unlike other external services (email, SMS, SAP, etc.), **AI services MUST use real AI APIs in ALL modes**:

- **Sandbox**: Real AI (Claude/GPT/Perplexity) with isolated data
- **Simulation**: Real AI (Claude/GPT/Perplexity) with isolated data  
- **Production**: Real AI (Claude/GPT/Perplexity) with real data

**Why AI is Different:**
- ✅ AI intelligence cannot be simulated with templates
- ✅ AI responses must be contextual and intelligent
- ✅ Workflow design, expert matching, and analysis require real reasoning
- ✅ JSON generation, tool calling, and structured output need real AI
- ❌ Template-based responses create low-integrity results
- ❌ Mock AI responses break features that depend on intelligence

**What Changes Across Modes:**
- **Data isolation:** Sandbox/Simulation use test data, Production uses real data
- **Logging markers:** Mode is logged for tracking
- **Metadata:** Response includes mode indicator
- **Costs:** Same API costs in all modes (real AI = real costs)

**What Does NOT Change:**
- ❌ AI intelligence level (always real)
- ❌ API endpoints (always real Claude/GPT/Perplexity)
- ❌ Response quality (always real AI)

**Implementation:**
```ruby
# Sandbox AI Service
class SandboxAnthropicService < AnthropicService
  include Sandbox::SandboxAIWrapper
  # Calls real AnthropicService, adds sandbox metadata
end

# Simulation AI Service
class MockAnthropicService < AnthropicService
  # Calls real AnthropicService, adds simulation metadata
  # NO templates, NO mocking, REAL AI
end

# Production AI Service
class AnthropicService < GenAiService
  # Direct API calls to Claude
end
```

**Services That ARE Mocked (Sandbox/Simulation):**
- ✅ Email (SandboxEmailClient, MockEmailClient)
- ✅ SMS (SandboxSmsClient, MockSmsClient)
- ✅ SAP (SandboxSAPClient, MockSapClient)
- ✅ Slack (SandboxSlackClient, MockSlackClient)
- ✅ Teams (SandboxTeamsClient, MockTeamsClient)
- ✅ Kyndryl Bridge (SandboxKyndrylBridge, MockKyndrylBridge)

**Services That Are NEVER Mocked:**
- ❌ Anthropic (Claude) - Always real AI
- ❌ OpenAI (GPT) - Always real AI
- ❌ Perplexity - Always real AI

**Why This Matters:**
- Workflow Expediter generates valid JSON in all modes
- Expert matching works correctly in all modes
- Workflow wizard provides intelligent responses in all modes
- No degradation of AI quality across modes
- Predictable, high-integrity results

**Three Environment Modes:**
- **Sandbox**: Real AI + mocked external services + isolated data + instant speed + $$ AI costs
- **Simulation**: Real AI + mocked external services with delays + isolated data + realistic speed + $$ AI costs
- **Production**: Real AI + real external services + real data + variable speed + $$$ all costs

**Cost Implications:**
- Sandbox/Simulation are NOT free for AI calls (real API costs)
- Use judiciously during development
- Production mode adds costs for external services too
- AI costs apply to ALL modes

**Factory Methods Available:**
```ruby
# Generic (uses ai_provider system setting)
AiServiceFactory.default_service          # Recommended for most use cases
AiServiceFactory.for_workflow_design      # Alias for default_service
AiServiceFactory.for_expert_matching      # Alias for default_service

# Provider-specific (when you need a specific provider)
AiServiceFactory.anthropic_service        # Claude
AiServiceFactory.openai_service           # GPT
AiServiceFactory.perplexity_service       # Perplexity (web search)
```

**Changing Environment Mode:**
```ruby
# Via code
EnvironmentMode.set_mode(:sandbox)     # Instant, free responses
EnvironmentMode.set_mode(:simulation)  # Mock responses with delays
EnvironmentMode.set_mode(:production)  # Real AI API calls

# Via UI (SystemSetting)
SystemSetting.set("environment_mode", "sandbox")
```

**Where This Applies:**
- ✅ Controllers calling AI services
- ✅ Models calling AI services (e.g., DigitalExpert)
- ✅ Services calling AI services (e.g., WorkflowWizardService)
- ✅ Agents calling AI services (e.g., WorkflowPlanner)
- ✅ Background jobs calling AI services
- ❌ **Exception:** Manual test scripts in `script/manual_tests/` (testing direct instantiation)
- ❌ **Exception:** Example code in `script/examples/` (demonstrating patterns)

**Testing:**
```ruby
# Tests automatically use sandbox mode (see test/test_helper.rb)
setup do
  EnvironmentMode.set_mode(:sandbox)  # Ensures no real API calls in tests
end
```

**Compliance:**
- 100% of production application code uses AiServiceFactory (verified Nov 2025)
- Phase 4 integration complete (see doc/history/PHASE4_COMPLETE.md)

### 12.2 Configurable Settings (UI-Based)
**Everything configurable via UI except API keys:**
- Timeout durations
- Escalation rules
- Default SLAs
- Notification templates
- Capability master list
- Role hierarchies (per industry)
- Rate limits
- Billing rates
- Federation trust relationships

### 12.3 Admin Panel
- **Global settings/admin panel** for system-wide configuration
- Role-based access to admin features
- Audit trail for configuration changes

### 12.4 Environment Behaviors
- **Development**: Extensive logging, debug info visible
- **Production**: Limited logging (errors and warnings only)
- **No special deployment modes**: Single codebase for all environments

---

## 13. UX Design Standards

### 13.1 Typography
- Clear heading hierarchy (h1-h6)
- Appropriate font weights for emphasis
- Consistent font sizing across components

### 13.2 Spacing
- Follow Tailwind spacing scale
- Consistent padding and margins
- Adequate whitespace for readability

### 13.3 Animations & Transitions
- **All animations eased** (ease-in-out timing)
- Smooth, professional feel
- Sidebar: 1.5s hover delay before expansion
- State transitions: 300ms duration

### 13.4 Visual Hierarchy
- Thick left borders on cards (`4px`, `#A8B9C9` slate)
- Clear visual separation between sections
- Status indicators prominent and color-coded

---

## 14. Workflow Execution Details

### 14.1 Execution Design
- Designed by **SME or user** via wizard
- Defines sequence: Who → What data → In what order → What passes to next
- **Parallel steps permitted** when no data dependencies
- **Sequential required** when steps depend on previous output

### 14.2 Execution Modification
- Can be **dynamically modified** during execution
- Requires: audit trail + coded reason + free-form explanation
- Can add/remove/reorder steps mid-execution

### 14.3 Checkpoints
- Human approval checkpoints at defined points
- Workflow pauses until checkpoint approved
- Configurable per workflow template

---

## 15. Federation Principles

### 15.1 Trust Relationships
- **Explicit trust required** before resource sharing
- Configured in company's `federation_config`
- Bilateral agreements (both companies must agree)

### 15.2 Cross-Company Workflows
- Workflows can span multiple companies (ecosystem model)
- **Initiating company** owns the workflow
- **Initiating company billed** for all expert time (local + federated)

### 15.3 Expert Sharing
- Federated companies can share experts
- Local experts have priority over federated
- Federated experts bill back to home company

---

## 16. Partnership & Deployment

### 16.1 UTS OPTIK Integration
- Co-creation partnership with UTS OPTIK AI research team
- All IP exclusively retained by Kyndryl
- No special technical requirements for integration

### 16.2 Retail Focus (Initial)
- Built for retail operations (Coles/Myer use cases)
- **Generalizable architecture**: Supports any industry
- Industry-specific configurations (hierarchies, roles, capabilities)

---

## 17. Future Enhancements (Not Yet Implemented)

### 17.1 Authentication & Authorization
- OAuth, SSO, API token support (placeholder)
- Fine-grained permission system expansion

### 17.2 Integration Testing
- End-to-end workflow execution tests
- Multi-company federation scenarios

### 17.3 Data Residency
- Region-specific deployment support
- GDPR data export capabilities

---

## Key Design Decisions

### Models to Refactor
1. **Capabilities**: Migrate from JSON to HABTM join table
   - Create `capabilities` table
   - Create `expert_capabilities` join table
   - Remove JSON serialization from Expert models

2. **Execution Steps**: New model needed
   - Create `workflow_execution_steps` table
   - Track: sequence, persona, data_in, data_out, status, parallel_group
   - Enable step-level state management

3. **Audit Trail**: Consider audit gem or custom implementation
   - Track all changes to critical models
   - Store: who, what, when, why (coded + free-form)

### API Enhancements Needed
1. Pagination implementation (page, per_page, total_count)
2. Rate limiting middleware for AI queries
3. Timestamp standardization in all responses

---

## Version History
- **v1.0** (Current): Basic CRUD, modal-based UI
- **v1.1** (Planned): Slide-out panels, capabilities HABTM, execution steps
- **v2.0** (Future): Authentication, advanced federation, integration tests

---

## 18. No Backward Compatibility Requirement ⭐ NEW

### 18.1 Breaking Changes Are Acceptable

**PRINCIPLE:** This is a greenfield project under active development. Breaking changes are acceptable and encouraged when they improve architecture, performance, or maintainability.

**Rules:**
- ✅ **DO:** Refactor aggressively to improve code quality
- ✅ **DO:** Make breaking changes that simplify architecture
- ✅ **DO:** Remove deprecated patterns and code
- ✅ **DO:** Restructure APIs and interfaces when needed
- ✅ **DO:** Change database schemas to better represent the domain
- ❌ **DON'T:** Maintain backward compatibility at the cost of clean architecture
- ❌ **DON'T:** Keep deprecated code paths "just in case"
- ❌ **DON'T:** Add complexity to support old patterns

**Rationale:**
- Project is not yet in production (UTS OPTIK partnership, retail pilot phase)
- No external API consumers to maintain compatibility for
- Development velocity is more important than stability
- Clean architecture today prevents technical debt tomorrow
- Breaking changes are cheaper now than after production deployment

**When Breaking Changes Happen:**
1. Update all internal code to use new pattern
2. Remove old code completely (no deprecation period needed)
3. Update tests to expect new behavior
4. Document the change in commit message
5. Update relevant documentation in `doc/`

**Examples of Acceptable Breaking Changes:**
- Removing redundant tools/methods
- Changing MCP executor architecture
- Restructuring database schemas
- Refactoring service interfaces
- Changing API response formats
- Removing feature flags or mode switches

**When to Start Considering Compatibility:**
- After production deployment with external customers
- When external systems integrate via our APIs
- When federation partners depend on our interfaces
- Until then: **Refactor fearlessly**

---

## 19. Data Compatibility Principle

### 19.1 Fix Data, Not Logic

**CRITICAL RULE:** Never modify business logic to accommodate incompatible data.

**If business logic fails due to data:**
- ❌ DON'T: Change the logic to handle the bad data
- ✅ DO: Fix the seed data to match what the logic expects

**Example:**
```ruby
# BAD APPROACH - Modifying logic for incompatible data
def match_expert(step)
  # Adding fuzzy matching because seed data has wrong capability names
  capabilities.select { |c| c.name.include?(step.capability[0..3]) }
end

# GOOD APPROACH - Fix the seed data instead
# Update seeds.rb to create capabilities that match what AI generates:
Capability.create!(name: "strategic_planning", ...)
```

**Rationale:**
- Business logic represents the **real-world rules**
- Seed data is **test/demo data**
- Test data should conform to the system, not vice versa
- Changing logic for bad data creates technical debt
- Fixing seeds is one-time work that improves all future tests

**Application:**
- Seed capabilities that match AI-generated workflow steps
- Seed realistic expert configurations
- Seed valid workflow states and transitions
- Never add workarounds to accommodate seed data gaps

---

## 20. High Integrity Results - No Fallbacks ⭐ CRITICAL

### 20.1 AI Must Succeed or Fail - No Fallbacks

**CRITICAL PRINCIPLE:** When using AI for critical decisions, the AI must generate proper results or FAIL with clear error. Never use fallback heuristics or keyword matching.

**The Rule:**
- ❌ DON'T: Use keyword matching or heuristics when AI fails
- ❌ DON'T: Create "good enough" fallback results
- ❌ DON'T: Silently degrade to lower quality
- ✅ DO: Require AI to generate valid, structured output
- ✅ DO: Fail with clear error if AI can't deliver
- ✅ DO: Tell user what went wrong and how to fix it

**Example: Workflow Expediter**

```ruby
# ❌ BAD APPROACH - Fallback to keywords
def parse_ai_specification(content)
  parsed = try_parse_json(content)
  return parsed if parsed
  
  # WRONG: Fallback to keyword matching
  if goal.include?("inventory")
    return { experts: [{ role: "forecasting_analyst" }] }
  end
end

# ✅ GOOD APPROACH - Fail with integrity
def parse_ai_specification(content)
  json_match = content.match(/\{[\s\S]*\}/m)
  
  unless json_match
    raise StandardError, "AI did not return JSON. Switch to Production mode for better AI. Response: #{content[0..200]}"
  end

  parsed = JSON.parse(json_match[0], symbolize_names: true)
  
  unless parsed[:outcome] && parsed[:success_criteria] && parsed[:success_criteria][:experts]&.any?
    raise StandardError, "AI JSON incomplete. Required: outcome, success_criteria with experts array."
  end
  
  parsed  # Only return if valid
end
```

**Why This Matters:**
- **Integrity:** Users trust results are AI-generated, not keyword hacks
- **Quality:** Forces proper AI configuration (API keys, mode selection)
- **Debugging:** Clear errors show what's actually wrong
- **Transparency:** No hidden degradation of quality
- **Reliability:** Predictable behavior - works or fails, never "kinda works"

**When AI Fails:**
```ruby
# Return clear, actionable error
{
  success: false,
  error: "AI could not generate workflow specification. " \
         "Current mode: #{mode}. " \
         "Production mode recommended for complex workflows. " \
         "Ensure AI API keys are configured."
}
```

**Application Areas:**
- ✅ Workflow generation (Expediter)
- ✅ Expert matching
- ✅ Workflow wizard responses
- ✅ Any AI-driven decision making

**When Fallbacks ARE Okay:**
- ✅ UI defaults (user can override)
- ✅ Display formatting (cosmetic)
- ✅ Optional features (clearly marked)
- ❌ Never for business logic or data integrity

**Red Flags:**
- Code that checks keywords "just in case"
- "Intelligent fallback" logic
- Heuristic-based alternatives to AI
- Silent degradation of functionality
- Any variation of "if AI fails, use X instead"

**Enforcement:**
- Code review: Question all fallback logic
- Testing: Verify failure modes are clean
- Documentation: Make mode requirements clear
- Errors: Must be actionable and honest

---

## Contributing Guidelines

When making changes:
1. ✅ **Keep code DRY** - Follow patterns in Sections 1.1-1.5 (delegate to superclass, use metaprogramming, extract to methods/services)
2. ✅ Keep code files short and focused (5-15 lines per method when possible)
3. ✅ Add audit trails for critical changes
4. ✅ Use human-readable values in UI
5. ✅ Follow color palette standards
6. ✅ Write tests (80% coverage target) - Use test DRY principles (Section 1.5)
7. ✅ **Fix data, not logic** - Never modify business logic for incompatible data
8. ✅ Update this PRINCIPLES.md as decisions evolve
9. ✅ **Document in the right place** - Use organized doc/ folders (see Documentation Structure above)
10. ✅ **Organize scripts properly** - Use `script/utilities/`, `script/manual_tests/`, or `script/examples/` (never root)
11. ✅ **Update the splash page** - When implementing new features, update `frontend/src/pages/Dashboard.tsx` to reflect current capabilities

## Documentation Best Practices

### When to Document
- **Architecture changes** → `doc/architecture/`
- **New features** → `doc/features/`
- **User-facing changes** → `doc/guides/`
- **Refactoring plans** → `doc/refactoring/`
- **Implementation work** → `doc/implementation/`

### When NOT to Document ⭐ CRITICAL
- **NEVER create summary documentation when there are known errors or failing tests** ⭐ ABSOLUTE RULE
- **NEVER document incomplete work as if it's finished**
- **NEVER waste user time with summaries when stuff isn't working**
- **FIX the errors first**, then document the working solution
- Summary documents imply completion - only create them when work is actually complete and tested
- **If you want to communicate progress mid-way:** Tell the user what steps remain and what issues are open, don't create summary docs
- **Bug fixes** → `doc/history/` (after completion)
- **Testing** → `doc/testing/`

**What to Do Instead of Summaries:**
- State current test results (X passing, Y failing)
- List remaining issues to fix
- List remaining steps to complete
- Ask if user wants to continue or has input
- Only create summary documents when user explicitly agrees AND all tests pass

### Documentation Standards
1. **Use descriptive filenames** - UPPERCASE with underscores
2. **Start with context** - Explain why before what
3. **Link to related docs** - Cross-reference generously
4. **Update doc/README.md** - Keep the index current
5. **Keep root clean** - Only PRINCIPLES.md, README.md, 🚀_START_HERE.md stay in root

### Splash Page Updates (Dashboard)
**IMPORTANT:** When implementing new features, always update the splash page to keep it current:

**File:** `frontend/src/pages/Dashboard.tsx`

**What to Update:**
1. **Platform Features Section** - Add new feature cards with:
   - Appropriate icon from lucide-react
   - Clear title and description
   - 3 bullet points highlighting key capabilities
   - Blue border (`border-blue-500`) for newly added features
   
2. **Technical Specifications** - Update tech stack if changed:
   - Backend technologies
   - Frontend frameworks
   - UI/design systems

3. **Use Cases** - Add industry applications as they're validated

**Example Feature Card:**
```tsx
<div className="bg-card rounded-lg p-6 border-l-4 border-blue-500 shadow-sm hover:shadow-md transition-shadow">
  <div className="flex items-start gap-4">
    <div className="bg-theme-primary p-3 rounded-lg">
      <IconName className="h-6 w-6 text-white" />
    </div>
    <div className="flex-1">
      <h3 className="text-xl font-semibold text-theme-text-primary mb-2">Feature Name</h3>
      <p className="text-theme-text-secondary mb-3">
        Brief description of the feature and its value proposition.
      </p>
      <ul className="text-sm text-theme-text-tertiary space-y-1">
        <li className="flex items-center gap-2">
          <CheckCircle className="h-4 w-4 text-blue-600" />
          Key capability 1
        </li>
        <li className="flex items-center gap-2">
          <CheckCircle className="h-4 w-4 text-blue-600" />
          Key capability 2
        </li>
        <li className="flex items-center gap-2">
          <CheckCircle className="h-4 w-4 text-blue-600" />
          Key capability 3
        </li>
      </ul>
    </div>
  </div>
</div>
```

**Best Practices:**
- Update splash page **before** marking feature complete
- Use blue borders to highlight recently added features
- Keep descriptions concise (2-3 sentences max)
- Focus on user benefits, not technical details
- After 1-2 releases, change blue borders back to slate-500

### 11.8 Development Server Testing & Debugging ⭐ ESSENTIAL

**CRITICAL PRACTICE:** Always test in development environment with real servers running.

#### Starting Development Servers

**Automated Start (Recommended):**
```bash
cd /path/to/project
~/.rbenv/shims/ruby script/utilities/start_dev.rb
```

This single command:
- Starts API server (backend)
- Starts frontend dev server
- Starts background workers
- Cleans up stale jobs
- Opens browser automatically

**Manual Start (More Control):**
```bash
# Terminal 1: API Server
cd /path/to/project
~/.rbenv/shims/bundle exec rackup apps/api/config.ru -p 9292 > tmp/api.log 2>&1 &

# Terminal 2: Frontend
cd apps/frontend
npm run dev > ../tmp/frontend.log 2>&1 &

# Terminal 3: Workers (optional)
~/.rbenv/shims/ruby script/utilities/start_workers.rb > tmp/workers.log 2>&1 &
```

**Using npm scripts:**
```bash
# Start all servers
npm run dev

# Individual servers
npm run dev:api      # API only
npm run dev:frontend # Frontend only
npm run dev:workers  # Workers only
```

#### Log File Management ⭐ MANDATORY

**ALL development servers MUST pipe output to files:**

```bash
# Good - Logs are saved
~/.rbenv/shims/bundle exec rackup apps/api/config.ru -p 9292 > tmp/api.log 2>&1 &

# Bad - No logs, can't debug
~/.rbenv/shims/bundle exec rackup apps/api/config.ru -p 9292 &
```

**Why:**
- AI assistants can read logs for debugging
- Historical analysis of issues
- Error tracking across sessions
- Don't lose important error messages

**Log Locations:**
```
tmp/api.log          # API server logs
tmp/frontend.log     # Vite/React dev server
tmp/workers.log      # Sidekiq workers
```

#### Checking Server Status

**Check if servers are running:**
```bash
# Check API (port 9292)
lsof -ti:9292 && echo "✓ API running" || echo "✗ API not running"

# Check frontend (port 5173)
lsof -ti:5173 && echo "✓ Frontend running" || echo "✗ Frontend not running"

# Check all Ruby processes
ps aux | grep -E "puma|rackup|sidekiq" | grep -v grep
```

**Health checks:**
```bash
# API health
curl http://localhost:9292/health

# Frontend (should return HTML)
curl -s http://localhost:5173 | head -5
```

#### Viewing Real-Time Logs

**Tail logs while testing:**
```bash
# Watch API logs
tail -f tmp/api.log

# Watch with grep filter
tail -f tmp/api.log | grep -i "error\|upload\|search"

# Last 50 lines
tail -50 tmp/api.log

# Specific error patterns
grep -A 5 "ERROR" tmp/api.log
```

**Multi-tail (watch multiple logs):**
```bash
# Watch API and frontend simultaneously
tail -f tmp/api.log tmp/frontend.log
```

#### Killing and Restarting Servers

**Kill specific port:**
```bash
# Kill API server
lsof -ti:9292 | xargs kill -9

# Kill frontend
lsof -ti:5173 | xargs kill -9

# Kill all on both ports
lsof -ti:9292 | xargs kill -9; lsof -ti:5173 | xargs kill -9
```

**Kill by process name:**
```bash
# Kill all Sidekiq workers
pkill -9 -f sidekiq

# Kill all rackup processes
pkill -9 -f rackup

# Kill all puma processes
pkill -9 -f puma
```

**Clean restart:**
```bash
# 1. Kill everything
lsof -ti:9292 | xargs kill -9 2>/dev/null
lsof -ti:5173 | xargs kill -9 2>/dev/null
pkill -9 -f sidekiq 2>/dev/null

# 2. Wait for cleanup
sleep 2

# 3. Restart
~/.rbenv/shims/ruby script/utilities/start_dev.rb
```

#### Testing Backend Endpoints

**Using curl:**
```bash
# Get session token first
TOKEN=$(~/.rbenv/shims/ruby -r './config/database.rb' -e "
  require './libs/domain/session'
  puts Session.where('expires_at > ?', Time.now).first.token
")

# Test authenticated endpoint
curl -s "http://localhost:9292/api/v1/documents?token=$TOKEN" | head -50

# Test with Bearer auth
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://localhost:9292/api/v1/documents"

# Test POST with JSON
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Document"}' \
  "http://localhost:9292/api/v1/documents"

# Pretty print JSON response
curl -s "http://localhost:9292/health" | python3 -m json.tool
```

**File upload testing:**
```bash
# Create test file
echo "Test content" > /tmp/test.txt

# Upload via Ruby script (most reliable)
~/.rbenv/shims/ruby script/utilities/test_upload.rb

# Upload via curl (for testing)
curl -X POST "http://localhost:9292/api/v1/documents/1/upload?token=$TOKEN" \
  -F "file=@/tmp/test.txt"
```

#### Testing Ruby Services Directly

**Quick service tests:**
```bash
# Test search
~/.rbenv/shims/ruby script/utilities/test_search.rb "What is this about?"

# Test upload
~/.rbenv/shims/ruby script/utilities/test_upload_unique.rb

# Check database state
~/.rbenv/shims/ruby script/utilities/check_documents.rb

# Check environment
~/.rbenv/shims/ruby script/utilities/check_env.rb
```

**Interactive Ruby console:**
```bash
# Open console with app loaded
~/.rbenv/shims/ruby -r './config/database.rb' -e "
  require './libs/domain/document'
  require './libs/pipelines/rag_search_service'
  
  # Your test code here
  result = Pipelines::RagSearchService.call(nil, query: 'test')
  puts result.inspect
"
```

#### Database Inspection

**Quick queries:**
```bash
# Count documents
~/.rbenv/shims/ruby -r './config/database.rb' -e "
  require './libs/domain/document'
  puts Document.count
"

# Document status breakdown
~/.rbenv/shims/ruby -r './config/database.rb' -e "
  require './libs/domain/document'
  Document.group(:status).count.each { |s, c| puts \"#{s}: #{c}\" }
"

# Recent documents
~/.rbenv/shims/ruby -r './config/database.rb' -e "
  require './libs/domain/document'
  Document.order(created_at: :desc).limit(5).each do |d|
    puts \"#{d.id}: #{d.title} (#{d.status})\"
  end
"
```

**Use dedicated scripts:**
```bash
# Better approach - use script
~/.rbenv/shims/ruby script/utilities/check_documents.rb
```

#### Frontend Debugging

**Build and check for errors:**
```bash
cd apps/frontend

# Full build (checks TypeScript)
npm run build

# Type checking only (faster)
npx tsc --noEmit

# Linting
npm run lint
```

**Clear caches:**
```bash
# Clear Vite cache
rm -rf node_modules/.vite

# Clear all caches
rm -rf node_modules/.vite dist
```

**Check bundle size:**
```bash
npm run build 2>&1 | grep "dist/"
# Should show gzipped sizes
```

#### Testing Workflow Integration

**Full integration test:**
```bash
# 1. Start all servers
~/.rbenv/shims/ruby script/utilities/start_dev.rb

# 2. In browser: Open http://localhost:5173

# 3. Test each feature:
#    - Login
#    - Upload file
#    - View document
#    - Search
#    - Check provenance

# 4. Monitor logs in real-time:
tail -f tmp/api.log tmp/workers.log

# 5. Check for errors in browser console (F12)
```

#### Common Issues & Solutions

**Issue: API won't start**
```bash
# Check logs first
cat tmp/api.log | tail -50

# Common causes:
# - Port in use: lsof -ti:9292 | xargs kill -9
# - Syntax error: ~/.rbenv/shims/ruby -c apps/api/app.rb
# - Missing model: Check require statements in app.rb
# - Bad middleware: Check config.ru
```

**Issue: Upload fails (400/422)**
```bash
# Check server logs
tail -50 tmp/api.log | grep "Upload"

# Test backend directly
~/.rbenv/shims/ruby script/utilities/test_upload.rb

# If backend works but browser fails:
# - Check browser console for axios/fetch errors
# - Verify Content-Type header is being sent
# - Check Vite proxy configuration
```

**Issue: Database not connected**
```bash
# Check health endpoint
curl http://localhost:9292/health | python3 -m json.tool

# Should show "connected": true

# If false, restart server with bundler:
~/.rbenv/shims/bundle exec rackup apps/api/config.ru -p 9292
```

**Issue: Frontend shows blank page**
```bash
# Check browser console (F12)
# Check frontend build
cd apps/frontend && npm run build

# Check if frontend server is running
lsof -ti:5173

# View frontend logs
cat tmp/frontend.log | tail -30
```

#### Port Management

**Standard ports:**
- **9292** - API server (Sinatra/Puma)
- **5173** - Frontend (Vite)
- **6379** - Redis (if used)

**Quick port check:**
```bash
# See what's using ports
lsof -i :9292
lsof -i :5173

# Kill and restart
lsof -ti:9292 | xargs kill -9
sleep 2
npm run dev:api &
```

#### Testing After Code Changes

**Workflow:**
```bash
# 1. Make code changes
vim apps/api/routes/my_route.rb

# 2. Kill and restart API
lsof -ti:9292 | xargs kill -9
sleep 2
npm run dev:api > tmp/api.log 2>&1 &

# 3. Wait for startup
sleep 5

# 4. Test endpoint
curl http://localhost:9292/health

# 5. Check logs for errors
tail -20 tmp/api.log

# 6. Test in browser or with script
~/.rbenv/shims/ruby script/utilities/test_upload.rb
```

#### Debugging Production Issues

**Simulate production environment:**
```bash
# Run in production mode
RACK_ENV=production npm run dev:api

# Check what changes in production
curl http://localhost:9292/api/v1/status
```

**Performance testing:**
```bash
# Time API requests
time curl -s "http://localhost:9292/api/v1/documents?token=$TOKEN" > /dev/null

# Concurrent requests
for i in {1..10}; do
  curl -s "http://localhost:9292/health" &
done
wait
```

#### Test Script Best Practices

**Every feature should have a test script:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for Feature X
require_relative '../../config/database'
require_relative '../../libs/my_service'

puts "🧪 Testing Feature X"
puts "=" * 60

begin
  result = MyService.call(test_data)
  
  if result[:success]
    puts "✅ SUCCESS"
    puts result[:data].inspect
  else
    puts "❌ FAILED: #{result[:error]}"
    exit 1
  end
rescue => e
  puts "❌ ERROR: #{e.message}"
  puts e.backtrace.take(5).join("\n")
  exit 1
end

puts "=" * 60
```

**Test scripts location:**
- `script/utilities/test_*.rb` - Feature tests
- `script/utilities/check_*.rb` - Status checks
- Always use rbenv shims: `~/.rbenv/shims/ruby`

#### Browser Testing Checklist

**Before claiming "working":**
- [ ] Hard refresh browser (Cmd+Shift+R)
- [ ] Test in clean incognito window
- [ ] Check browser console for errors
- [ ] Check Network tab for failed requests
- [ ] Test all user flows
- [ ] Test error cases
- [ ] Check responsive design
- [ ] Verify CRUD operations
- [ ] Test with real data
- [ ] Check performance (no lag)

**Browser console debugging:**
```javascript
// In browser console:

// Check localStorage
localStorage.getItem('session_token')

// Check API calls
fetch('http://localhost:9292/health')
  .then(r => r.json())
  .then(console.log)

// Test upload
const formData = new FormData();
formData.append('file', document.querySelector('input[type=file]').files[0]);
fetch('http://localhost:9292/api/v1/documents/1/upload', {
  method: 'POST',
  headers: { 'Authorization': 'Bearer ' + localStorage.getItem('session_token') },
  body: formData
}).then(r => r.json()).then(console.log)
```

#### Automated Browser Testing with Playwright ⭐ ESSENTIAL

**CRITICAL PRACTICE:** Use headless browser automation for complex UI testing instead of manual browser verification.

**System Configuration (macOS):**
- **Node location:** `/opt/homebrew/Cellar/node/24.5.0/bin/node` (or find with `which node`)
- **Chrome location:** `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
- **npm location:** Usually in same directory as node

**Install Playwright:**
```bash
# Install Playwright (one-time setup)
npm install --no-save playwright

# Install Chromium browser (optional if using Chrome)
npx playwright install chromium
```

**Create Test Script:**
```javascript
// test-search.mjs
import { chromium } from 'playwright';

async function testSearch() {
  // Use installed Chrome instead of Playwright's Chromium
  const browser = await chromium.launch({ 
    headless: true,
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
  });
  const page = await browser.newPage();
  
  // Listen for errors
  page.on('console', msg => console.log('Browser:', msg.text()));
  page.on('pageerror', error => console.log('❌ Error:', error.message));
  
  try {
    // Login
    await page.goto('http://localhost:5173/login');
    await page.fill('input[type="email"]', 'admin@example.com');
    await page.fill('input[type="password"]', 'password123');
    await page.click('button[type="submit"]');
    await page.waitForURL('**');
    
    // Test search
    await page.goto('http://localhost:5173/search');
    await page.fill('textarea', 'What is this system?');
    
    // Wait for API response
    const response = await Promise.all([
      page.waitForResponse(r => r.url().includes('/api/v1/search')),
      page.click('button:has-text("Search")')
    ]);
    
    const data = await response[0].json();
    console.log('✅ Success:', data.success);
    console.log('Answer:', data.data?.answer?.substring(0, 100));
    
    // Screenshot
    await page.screenshot({ path: 'tmp/test-result.png' });
    
  } finally {
    await browser.close();
  }
}

testSearch();
```

**Run Automated Test:**
```bash
# Run test script with full path (if node not in PATH)
/opt/homebrew/Cellar/node/24.5.0/bin/node test-search.mjs

# Or use which to find node dynamically
$(which node) test-search.mjs

# Or if node is in PATH
node test-search.mjs

# Check screenshot
open tmp/test-result.png
```

**Finding Node Location:**
```bash
# Find node binary
which node

# Or search for it
find /opt -name node -type f 2>/dev/null | grep bin | head -1
find /usr/local -name node -type f 2>/dev/null | grep bin | head -1
```

**Benefits:**
- ✅ **Reproducible** - Same test every time
- ✅ **Fast** - No manual clicking
- ✅ **CI-Ready** - Can run in pipelines
- ✅ **Debugging** - Screenshots on failure
- ✅ **Network inspection** - Capture API calls
- ✅ **Console logs** - See JavaScript errors

**When to Use:**
- Testing complex user workflows
- Regression testing after changes
- Debugging frontend/backend integration issues
- Verifying error handling in UI
- Testing authentication flows
- Checking responsive behavior

**Test Script Location:**
All browser test scripts should be in:
- `script/utilities/test_*.mjs` - UI integration tests
- Use `.mjs` extension for ES modules
- Make executable: `chmod +x script/utilities/test_*.mjs`

**Example Test Scripts:**
- `script/utilities/test_pagination.mjs` - Test document pagination
- `script/utilities/test_ui_integration.sh` - Full UI integration test (bash)
- Store screenshots in `tmp/` directory

**Chrome vs Chromium:**
- **Prefer Chrome:** Use installed Chrome if available (more stable)
- **Chromium:** Playwright's bundled browser (requires installation)
- **Configuration:** Set `executablePath` in `launch()` options

```javascript
// Using installed Chrome (recommended)
const browser = await chromium.launch({
  headless: true,
  executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
});

// Using Playwright's Chromium (requires npx playwright install chromium)
const browser = await chromium.launch({ headless: true });
```

**Anti-Patterns to Avoid:**
- ❌ Manual browser testing for every change
- ❌ Guessing what happened in browser
- ❌ Not capturing console errors
- ❌ Testing without screenshots
- ❌ Ignoring network request failures
- ❌ Hardcoding node paths (use `which node` or environment detection)
- ❌ Not handling authentication in automated tests

#### Multi-Component Testing

**Test full stack:**
```bash
# 1. Backend service
~/.rbenv/shims/ruby script/utilities/test_search.rb "test query"

# 2. API endpoint
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"test"}' \
  "http://localhost:9292/api/v1/search"

# 3. Frontend (browser)
# Navigate to /search and test UI

# 4. Check logs
tail -100 tmp/api.log | grep -i "search"
```

#### Common Testing Patterns

**Pattern 1: Test service → Test API → Test UI**
```bash
# Backend service
~/.rbenv/shims/ruby script/utilities/test_feature.rb

# API endpoint  
curl http://localhost:9292/api/v1/feature

# Frontend
# Open http://localhost:5173/feature in browser
```

**Pattern 2: Test with logs**
```bash
# Terminal 1: Watch logs
tail -f tmp/api.log

# Terminal 2: Run test
~/.rbenv/shims/ruby script/utilities/test_feature.rb

# See real-time logging
```

**Pattern 3: Test error cases**
```bash
# Test with invalid data
curl -X POST http://localhost:9292/api/v1/endpoint \
  -H "Content-Type: application/json" \
  -d '{"invalid":"data"}'

# Should return proper error
# Check logs: tail -20 tmp/api.log
```

#### Debugging Checklist

**When something doesn't work:**

1. **Check servers are running:**
   ```bash
   lsof -ti:9292 && echo "API ✓" || echo "API ✗"
   lsof -ti:5173 && echo "Frontend ✓" || echo "Frontend ✗"
   ```

2. **Check logs for errors:**
   ```bash
   tail -50 tmp/api.log | grep -i error
   cat tmp/frontend.log | grep -i error
   ```

3. **Check browser console:**
   - F12 → Console tab
   - Look for red errors
   - Check Network tab for failed requests

4. **Test backend directly:**
   ```bash
   # Bypass frontend
   ~/.rbenv/shims/ruby script/utilities/test_*.rb
   ```

5. **Check database:**
   ```bash
   ~/.rbenv/shims/ruby script/utilities/check_documents.rb
   ```

6. **Verify authentication:**
   ```bash
   curl http://localhost:9292/health  # Should work
   curl http://localhost:9292/api/v1/documents  # Should be 401
   curl "http://localhost:9292/api/v1/documents?token=$TOKEN"  # Should work
   ```

7. **Check API response structure:**
   ```bash
   curl -s http://localhost:9292/api/v1/endpoint | python3 -m json.tool
   ```

#### Performance Testing

**Measure response times:**
```bash
# Simple timing
time curl -s http://localhost:9292/api/v1/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test"}'

# Multiple requests
for i in {1..5}; do
  time curl -s http://localhost:9292/health > /dev/null
done
```

**Check database query performance:**
```bash
# Check slow queries in logs
grep "DEBUG.*SELECT.*ms" tmp/api.log | grep -E "[0-9]{3,}\." | tail -10
# Shows queries taking 100ms+
```

#### Build Verification

**Always verify build before committing:**
```bash
# Backend syntax
~/.rbenv/shims/ruby -c apps/api/app.rb
find libs -name "*.rb" -exec ~/.rbenv/shims/ruby -c {} \;

# Frontend build
cd apps/frontend && npm run build

# Should show:
# ✓ 1777 modules transformed
# ✓ built in X.XXs
# NO errors
```

#### Integration Test Example

**Complete feature test:**
```bash
#!/bin/bash
# test_feature_integration.sh

echo "🧪 Testing Feature Integration"

# 1. Start servers
./script/utilities/start_dev.rb &
SERVER_PID=$!
sleep 10

# 2. Test backend
echo "Testing backend..."
~/.rbenv/shims/ruby script/utilities/test_feature.rb
BACKEND_EXIT=$?

# 3. Test API
echo "Testing API..."
curl -f http://localhost:9292/api/v1/feature || BACKEND_EXIT=1

# 4. Check logs
echo "Checking logs..."
grep -i "error" tmp/api.log && BACKEND_EXIT=1

# 5. Cleanup
kill $SERVER_PID

# 6. Report
if [ $BACKEND_EXIT -eq 0 ]; then
  echo "✅ All tests passed"
  exit 0
else
  echo "❌ Tests failed - check logs"
  exit 1
fi
```

#### Best Practices Summary

**DO:**
- ✅ Pipe ALL server output to log files
- ✅ Use rbenv shims for Ruby commands
- ✅ Test backend before frontend
- ✅ Check logs after every test
- ✅ Kill and restart servers after code changes
- ✅ Use test scripts for repeatable tests
- ✅ Check browser console for frontend errors
- ✅ Verify builds before committing

**DON'T:**
- ❌ Run servers without logging
- ❌ Use `bundle exec` directly (use rbenv shims)
- ❌ Skip backend testing
- ❌ Ignore log files
- ❌ Test only in browser
- ❌ Assume it works without verification
- ❌ Commit without building
- ❌ Skip health checks

#### Quick Reference Commands

```bash
# Start everything
~/.rbenv/shims/ruby script/utilities/start_dev.rb

# Check status
lsof -ti:9292 && echo "API ✓" || echo "API ✗"
curl -s http://localhost:9292/health

# View logs
tail -f tmp/api.log

# Test backend
~/.rbenv/shims/ruby script/utilities/test_*.rb

# Kill and restart
lsof -ti:9292 | xargs kill -9; npm run dev:api &

# Check database
~/.rbenv/shims/ruby script/utilities/check_documents.rb

# Build frontend
cd apps/frontend && npm run build
```

---

### Finding Documentation
- Start with `doc/README.md` for navigation
- Use grep: `grep -r "search term" doc/`
- Check by category folder first
- Reference by relative path: `doc/category/FILE.md`

