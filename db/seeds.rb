puts "Seeding database..."

# Clear existing data
CaseNote.destroy_all
Intervention.destroy_all
YouthCase.destroy_all
Program.destroy_all
Youth.destroy_all
CaseManager.destroy_all

puts "Creating case managers..."
case_managers = [
  CaseManager.create!(
    first_name: "Sarah",
    last_name: "Johnson",
    email: "sarah.johnson@qld.gov.au",
    phone: "07 3234 5678",
    department: "Youth Justice",
    specializations: "Detention cases, Family support"
  ),
  CaseManager.create!(
    first_name: "Michael",
    last_name: "Chen",
    email: "michael.chen@qld.gov.au",
    phone: "07 3234 5679",
    department: "Community Corrections",
    specializations: "Community orders, Diversion programs"
  ),
  CaseManager.create!(
    first_name: "Emily",
    last_name: "Martinez",
    email: "emily.martinez@qld.gov.au",
    phone: "07 3234 5680",
    department: "Rehabilitation Services",
    specializations: "Substance abuse, Mental health support"
  )
]

puts "Creating youth..."
youth_records = [
  Youth.create!(
    first_name: "James",
    last_name: "Wilson",
    date_of_birth: Date.new(2010, 3, 15),
    age: 14,
    gender: "Male",
    address: "123 Brisbane St, Brisbane QLD 4000",
    phone: "0412 345 678",
    emergency_contact: "Mary Wilson (Mother)",
    emergency_phone: "0412 345 679"
  ),
  Youth.create!(
    first_name: "Sophie",
    last_name: "Brown",
    date_of_birth: Date.new(2009, 7, 22),
    age: 15,
    gender: "Female",
    address: "456 Gold Coast Rd, Gold Coast QLD 4217",
    phone: "0423 456 789",
    emergency_contact: "David Brown (Father)",
    emergency_phone: "0423 456 790"
  ),
  Youth.create!(
    first_name: "Liam",
    last_name: "O'Connor",
    date_of_birth: Date.new(2011, 11, 8),
    age: 13,
    gender: "Male",
    address: "789 Cairns Ave, Cairns QLD 4870",
    phone: "0434 567 890",
    emergency_contact: "Patricia O'Connor (Guardian)",
    emergency_phone: "0434 567 891"
  ),
  Youth.create!(
    first_name: "Olivia",
    last_name: "Nguyen",
    date_of_birth: Date.new(2008, 5, 14),
    age: 16,
    gender: "Female",
    address: "321 Townsville St, Townsville QLD 4810",
    phone: "0445 678 901",
    emergency_contact: "Thanh Nguyen (Father)",
    emergency_phone: "0445 678 902"
  )
]

puts "Creating programs..."
programs = [
  Program.create!(
    name: "Fresh Start Education",
    program_type: "education",
    description: "Educational support and tutoring for youth to complete schooling",
    duration_weeks: 24,
    capacity: 30,
    location: "Brisbane Youth Justice Centre",
    status: "active"
  ),
  Program.create!(
    name: "Youth Employment Pathways",
    program_type: "employment",
    description: "Job skills training and work placement program",
    duration_weeks: 16,
    capacity: 20,
    location: "Gold Coast Training Hub",
    status: "active"
  ),
  Program.create!(
    name: "Family Reconnect",
    program_type: "counseling",
    description: "Family therapy and relationship building sessions",
    duration_weeks: 12,
    capacity: 15,
    location: "Community Counseling Center",
    status: "active"
  ),
  Program.create!(
    name: "Substance Abuse Recovery",
    program_type: "rehabilitation",
    description: "Residential program for substance abuse treatment",
    duration_weeks: 20,
    capacity: 12,
    location: "Sunshine Coast Rehabilitation Center",
    status: "active"
  )
]

puts "Creating cases..."
cases = [
  YouthCase.create!(
    youth: youth_records[0],
    case_manager: case_managers[0],
    case_number: "YJ-2024-001",
    case_type: "community_order",
    status: "active",
    description: "Community order for minor theft offense",
    start_date: Date.new(2024, 9, 1),
    court_reference: "BCM-2024-5678",
    conditions: "40 hours community service, weekly check-ins, education attendance required"
  ),
  YouthCase.create!(
    youth: youth_records[1],
    case_manager: case_managers[1],
    case_number: "YJ-2024-002",
    case_type: "diversion",
    status: "active",
    description: "Diversion program for first-time offender",
    start_date: Date.new(2024, 10, 15),
    court_reference: "GCM-2024-1234",
    conditions: "Attend counseling sessions, complete youth justice conference, no further offenses"
  ),
  YouthCase.create!(
    youth: youth_records[2],
    case_manager: case_managers[2],
    case_number: "YJ-2024-003",
    case_type: "detention",
    status: "active",
    description: "Detention order with rehabilitation focus",
    start_date: Date.new(2024, 8, 20),
    end_date: Date.new(2025, 2, 20),
    court_reference: "CNM-2024-9876",
    conditions: "6 months detention, mandatory education and counseling programs"
  ),
  YouthCase.create!(
    youth: youth_records[3],
    case_manager: case_managers[1],
    case_number: "YJ-2024-004",
    case_type: "rehabilitation",
    status: "active",
    description: "Intensive rehabilitation program",
    start_date: Date.new(2024, 11, 1),
    court_reference: "TVM-2024-4321",
    conditions: "Residential treatment program, family counseling, educational support"
  )
]

puts "Creating interventions..."
interventions = [
  Intervention.create!(
    youth_case: cases[0],
    youth: youth_records[0],
    program: programs[0],
    intervention_type: "education_support",
    status: "in_progress",
    description: "Tutoring and educational support to complete Year 9",
    start_date: Date.new(2024, 9, 10),
    attendance_rate: 85
  ),
  Intervention.create!(
    youth_case: cases[0],
    youth: youth_records[0],
    intervention_type: "community_service",
    status: "in_progress",
    description: "Community service at local park maintenance",
    start_date: Date.new(2024, 9, 15),
    attendance_rate: 90
  ),
  Intervention.create!(
    youth_case: cases[1],
    youth: youth_records[1],
    program: programs[2],
    intervention_type: "family_support",
    status: "in_progress",
    description: "Family counseling sessions weekly",
    start_date: Date.new(2024, 10, 20),
    attendance_rate: 100
  ),
  Intervention.create!(
    youth_case: cases[2],
    youth: youth_records[2],
    program: programs[3],
    intervention_type: "substance_abuse",
    status: "in_progress",
    description: "Substance abuse treatment program",
    start_date: Date.new(2024, 8, 25),
    attendance_rate: 78
  ),
  Intervention.create!(
    youth_case: cases[3],
    youth: youth_records[3],
    program: programs[1],
    intervention_type: "employment_training",
    status: "in_progress",
    description: "Hospitality and customer service training",
    start_date: Date.new(2024, 11, 5),
    attendance_rate: 92
  )
]

puts "Creating case notes..."
CaseNote.create!(
  youth_case: cases[0],
  case_manager: case_managers[0],
  note_type: "progress",
  content: "Youth is showing good progress with community service. Attitude has improved significantly. Continues to attend school regularly."
)

CaseNote.create!(
  youth_case: cases[1],
  case_manager: case_managers[1],
  note_type: "review",
  content: "Family counseling session went well. Mother and youth are communicating better. Will continue weekly sessions."
)

CaseNote.create!(
  youth_case: cases[2],
  case_manager: case_managers[2],
  note_type: "incident",
  content: "Minor incident in detention facility - verbal altercation with another youth. Issue was resolved through mediation. No further action required.",
  is_confidential: true
)

CaseNote.create!(
  youth_case: cases[3],
  case_manager: case_managers[1],
  note_type: "general",
  content: "Youth has completed first week of employment training program. Showing enthusiasm and commitment. Positive feedback from instructors."
)

puts "Seeding completed!"
puts "Created:"
puts "  - #{CaseManager.count} case managers"
puts "  - #{Youth.count} youth"
puts "  - #{Program.count} programs"
puts "  - #{YouthCase.count} cases"
puts "  - #{Intervention.count} interventions"
puts "  - #{CaseNote.count} case notes"

