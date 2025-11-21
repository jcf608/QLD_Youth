# QLD Youth Justice - Project Structure

## 📁 Directory Structure

```
QLD_Youth/
├── 📄 README.md                    # Main project overview
├── 📄 README_SETUP.md              # Detailed setup instructions
├── 📄 PROJECT_STRUCTURE.md         # This file
├── 📄 ScenariosForQLDYouth.md      # Use case scenarios
├── 📄 Gemfile                      # Ruby dependencies
├── 📄 Rakefile                     # Database tasks
├── 📄 config.ru                    # Rack configuration
├── 📄 start-dev.sh                 # Development startup script
├── 📄 .env.example                 # Environment variables template
├── 📄 .gitignore                   # Git ignore rules
├── 📄 .ruby-version                # Ruby version specification
│
├── 📁 config/
│   ├── environment.rb              # Application environment setup
│   └── database.yml                # Database configuration
│
├── 📁 app/
│   ├── application.rb              # Main Sinatra application & API routes
│   └── 📁 models/
│       ├── youth.rb                # Youth model
│       ├── case_manager.rb         # Case Manager model
│       ├── youth_case.rb           # Youth Case model
│       ├── intervention.rb         # Intervention model
│       ├── program.rb              # Program model
│       └── case_note.rb            # Case Note model
│
├── 📁 db/
│   ├── seeds.rb                    # Database seed data
│   └── 📁 migrate/
│       ├── 20251121000001_create_youth.rb
│       ├── 20251121000002_create_case_managers.rb
│       ├── 20251121000003_create_youth_cases.rb
│       ├── 20251121000004_create_programs.rb
│       ├── 20251121000005_create_interventions.rb
│       └── 20251121000006_create_case_notes.rb
│
└── 📁 client/                      # React Frontend Application
    ├── 📄 package.json             # Node dependencies
    ├── 📄 vite.config.js           # Vite configuration
    ├── 📄 tailwind.config.js       # TailwindCSS configuration
    ├── 📄 postcss.config.js        # PostCSS configuration
    ├── 📄 index.html               # HTML entry point
    ├── 📄 .eslintrc.cjs            # ESLint configuration
    ├── 📄 .gitignore               # Frontend git ignore
    │
    └── 📁 src/
        ├── main.jsx                # React entry point
        ├── App.jsx                 # Main App component with routes
        ├── index.css               # Global styles with Tailwind
        │
        ├── 📁 api/
        │   └── client.js           # Axios API client & endpoints
        │
        ├── 📁 components/
        │   └── Layout.jsx          # Main layout with navigation (Lucide icons)
        │
        └── 📁 pages/
            ├── Dashboard.jsx       # Dashboard with stats (Lucide icons)
            ├── CasesList.jsx       # Cases list view (Lucide icons)
            ├── CaseDetail.jsx      # Individual case details (Lucide icons)
            ├── YouthList.jsx       # Youth registry (Lucide icons)
            ├── YouthDetail.jsx     # Youth profile details (Lucide icons)
            ├── CaseManagers.jsx    # Case managers view (Lucide icons)
            ├── Programs.jsx        # Programs management (Lucide icons)
            └── Interventions.jsx   # Interventions tracking (Lucide icons)
```

## 🎯 Key Components

### Backend (Ruby/Sinatra)

**Models (ActiveRecord)**
- `Youth` - Young persons aged 10-17 in justice system
- `CaseManager` - Staff managing cases
- `YouthCase` - Individual case records
- `Intervention` - Support programs and activities
- `Program` - Structured intervention programs
- `CaseNote` - Case documentation

**API Routes (RESTful)**
- Dashboard stats
- CRUD operations for all models
- Filtering and search capabilities
- Relationship data loading

### Frontend (React)

**Core Technologies**
- ⚛️ React 18 - UI framework
- 🎨 TailwindCSS - Styling
- 🎭 Lucide React - Icon library (as requested)
- 🛣️ React Router - Navigation
- 📡 Axios - API communication
- ⚡ Vite - Build tool

**Features**
- Responsive design (mobile & desktop)
- Real-time data fetching
- Advanced filtering and search
- Clean, modern UI with professional aesthetics
- Dashboard with statistics and charts
- Detailed views for all entities
- Status badges and visual indicators

## 🔌 API Endpoints

### Dashboard
- `GET /api/dashboard/stats`

### Cases
- `GET /api/cases`
- `GET /api/cases/:id`
- `POST /api/cases`
- `PUT /api/cases/:id`

### Youth
- `GET /api/youth`
- `GET /api/youth/:id`
- `POST /api/youth`

### Case Managers
- `GET /api/case-managers`
- `GET /api/case-managers/:id`

### Interventions
- `GET /api/interventions`
- `POST /api/interventions`
- `PUT /api/interventions/:id`

### Programs
- `GET /api/programs`
- `GET /api/programs/:id`
- `POST /api/programs`

### Case Notes
- `POST /api/case-notes`

## 🚀 Quick Start

```bash
# Install dependencies
bundle install
cd client && npm install

# Setup database
createdb qld_youth_development
bundle exec rake db:migrate db:seed

# Start both servers (from root)
./start-dev.sh

# Or manually:
# Terminal 1: bundle exec rackup -p 9292
# Terminal 2: cd client && npm run dev
```

## 🎨 UI Features with Lucide React Icons

All pages use Lucide React icons for a consistent, modern look:

- **Navigation**: `LayoutDashboard`, `Briefcase`, `Users`, `UserCheck`, `Folder`, `Target`
- **Actions**: `Search`, `Filter`, `Eye`, `ArrowLeft`, `Menu`, `X`
- **Data**: `Calendar`, `Phone`, `MapPin`, `Mail`, `TrendingUp`
- **Status**: `AlertCircle`, `CheckCircle`, `Clock`
- **Content**: `FileText`, `MessageSquare`, `User`

## 📊 Database Schema

```
youths
├── id (PK)
├── first_name, last_name
├── date_of_birth, age, gender
├── contact information
└── timestamps

case_managers
├── id (PK)
├── first_name, last_name, email
├── department, specializations
└── timestamps

youth_cases
├── id (PK)
├── youth_id (FK)
├── case_manager_id (FK)
├── case_number, case_type, status
├── description, conditions
└── timestamps

programs
├── id (PK)
├── name, program_type, status
├── duration_weeks, capacity, location
└── timestamps

interventions
├── id (PK)
├── youth_case_id (FK)
├── youth_id (FK)
├── program_id (FK)
├── intervention_type, status
├── attendance_rate, outcomes
└── timestamps

case_notes
├── id (PK)
├── youth_case_id (FK)
├── case_manager_id (FK)
├── note_type, content
└── timestamps
```

## 🔧 Technology Choices

### Why Sinatra?
- Lightweight and fast
- Perfect for REST APIs
- Minimal boilerplate
- Easy to understand and maintain

### Why React with Vite?
- Fast development experience
- Modern build tooling
- Excellent developer experience
- Hot module replacement

### Why TailwindCSS?
- Utility-first approach
- Rapid UI development
- Consistent design system
- Easy responsive design

### Why Lucide React?
- Modern, clean icon set
- Tree-shakeable (only imports used icons)
- Consistent stroke width and styling
- Active maintenance and updates
- MIT licensed

### Why PostgreSQL?
- Robust and reliable
- Excellent for government systems
- Strong data integrity
- Advanced querying capabilities

## 📝 Notes

- All timestamps are managed by ActiveRecord
- CORS is enabled for local development
- Database seeds provide realistic sample data
- Frontend proxies API calls through Vite
- Responsive design works on all devices

---

Built with ❤️ for Queensland Youth Justice Department

