require 'sinatra/base'
require 'sinatra/cross_origin'
require 'json'

class Application < Sinatra::Base
  register Sinatra::CrossOrigin

  configure do
    enable :cross_origin
    set :allow_origin, '*'
    set :allow_methods, 'GET,HEAD,POST,PUT,PATCH,DELETE,OPTIONS'
    set :allow_headers, 'content-type,if-modified-since'
    set :expose_headers, 'location,link'
  end

  before do
    content_type :json
  end

  # Health check
  get '/' do
    { status: 'ok', message: 'QLD Youth Justice API' }.to_json
  end

  # Youth Cases endpoints
  get '/api/cases' do
    cases = YouthCase.includes(:youth, :case_manager).all
    cases.to_json(include: { youth: {}, case_manager: {} })
  end

  get '/api/cases/:id' do
    case_record = YouthCase.includes(:youth, :case_manager, :interventions, :case_notes).find(params[:id])
    case_record.to_json(include: { 
      youth: {}, 
      case_manager: {}, 
      interventions: {}, 
      case_notes: { methods: [:created_at_formatted] } 
    })
  rescue ActiveRecord::RecordNotFound
    status 404
    { error: 'Case not found' }.to_json
  end

  post '/api/cases' do
    data = JSON.parse(request.body.read)
    case_record = YouthCase.create(data)
    
    if case_record.persisted?
      status 201
      case_record.to_json
    else
      status 422
      { errors: case_record.errors.full_messages }.to_json
    end
  end

  put '/api/cases/:id' do
    case_record = YouthCase.find(params[:id])
    data = JSON.parse(request.body.read)
    
    if case_record.update(data)
      case_record.to_json
    else
      status 422
      { errors: case_record.errors.full_messages }.to_json
    end
  rescue ActiveRecord::RecordNotFound
    status 404
    { error: 'Case not found' }.to_json
  end

  # Youth endpoints
  get '/api/youth' do
    youth = Youth.all
    youth.to_json
  end

  get '/api/youth/:id' do
    youth = Youth.includes(:cases, :interventions).find(params[:id])
    youth.to_json(include: { cases: {}, interventions: {} })
  rescue ActiveRecord::RecordNotFound
    status 404
    { error: 'Youth not found' }.to_json
  end

  post '/api/youth' do
    data = JSON.parse(request.body.read)
    youth = Youth.create(data)
    
    if youth.persisted?
      status 201
      youth.to_json
    else
      status 422
      { errors: youth.errors.full_messages }.to_json
    end
  end

  # Case Managers endpoints
  get '/api/case-managers' do
    managers = CaseManager.includes(:cases).all
    managers.to_json(include: { cases: { include: :youth } })
  end

  get '/api/case-managers/:id' do
    manager = CaseManager.includes(:cases).find(params[:id])
    manager.to_json(include: { cases: { include: :youth } })
  rescue ActiveRecord::RecordNotFound
    status 404
    { error: 'Case manager not found' }.to_json
  end

  # Interventions endpoints
  get '/api/interventions' do
    interventions = Intervention.includes(:youth_case, :youth).all
    interventions.to_json(include: { youth_case: {}, youth: {} })
  end

  post '/api/interventions' do
    data = JSON.parse(request.body.read)
    intervention = Intervention.create(data)
    
    if intervention.persisted?
      status 201
      intervention.to_json
    else
      status 422
      { errors: intervention.errors.full_messages }.to_json
    end
  end

  put '/api/interventions/:id' do
    intervention = Intervention.find(params[:id])
    data = JSON.parse(request.body.read)
    
    if intervention.update(data)
      intervention.to_json
    else
      status 422
      { errors: intervention.errors.full_messages }.to_json
    end
  rescue ActiveRecord::RecordNotFound
    status 404
    { error: 'Intervention not found' }.to_json
  end

  # Case Notes endpoints
  post '/api/case-notes' do
    data = JSON.parse(request.body.read)
    note = CaseNote.create(data)
    
    if note.persisted?
      status 201
      note.to_json
    else
      status 422
      { errors: note.errors.full_messages }.to_json
    end
  end

  # Programs endpoints
  get '/api/programs' do
    programs = Program.includes(:interventions).all
    programs.to_json(include: :interventions)
  end

  get '/api/programs/:id' do
    program = Program.includes(:interventions).find(params[:id])
    program.to_json(include: { interventions: { include: :youth } })
  rescue ActiveRecord::RecordNotFound
    status 404
    { error: 'Program not found' }.to_json
  end

  post '/api/programs' do
    data = JSON.parse(request.body.read)
    program = Program.create(data)
    
    if program.persisted?
      status 201
      program.to_json
    else
      status 422
      { errors: program.errors.full_messages }.to_json
    end
  end

  # Dashboard/Analytics endpoints
  get '/api/dashboard/stats' do
    {
      total_cases: YouthCase.count,
      active_cases: YouthCase.where(status: 'active').count,
      total_youth: Youth.count,
      total_interventions: Intervention.count,
      active_interventions: Intervention.where(status: 'in_progress').count,
      cases_by_status: YouthCase.group(:status).count,
      interventions_by_type: Intervention.group(:intervention_type).count
    }.to_json
  end

  # Error handlers
  error ActiveRecord::RecordNotFound do
    status 404
    { error: 'Record not found' }.to_json
  end

  error JSON::ParserError do
    status 400
    { error: 'Invalid JSON' }.to_json
  end

  error do
    status 500
    { error: 'Internal server error' }.to_json
  end
end

