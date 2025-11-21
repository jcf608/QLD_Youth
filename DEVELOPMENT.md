# Development Guide

## 🛠️ Development Workflow

### Daily Development

1. **Start Development Servers**
   ```bash
   ./start-dev.sh
   ```
   Or manually:
   ```bash
   # Terminal 1 - Backend
   bundle exec rerun 'rackup -p 9292'
   
   # Terminal 2 - Frontend
   cd client && npm run dev
   ```

2. **Access Application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:9292
   - API Test: http://localhost:9292/api/dashboard/stats

### Making Changes

#### Backend Changes (Ruby/Sinatra)

**Adding a New Model:**
```bash
# Create migration
bundle exec rake db:create_migration NAME=create_your_model

# Edit the migration in db/migrate/
# Create model in app/models/

# Run migration
bundle exec rake db:migrate
```

**Adding API Endpoints:**
Edit `app/application.rb` and add routes following RESTful conventions.

**Testing Changes:**
```bash
# Ruby console with models loaded
bundle exec irb -r ./config/environment
```

#### Frontend Changes (React)

**Adding a New Page:**
1. Create component in `client/src/pages/`
2. Import Lucide React icons as needed
3. Add route in `client/src/App.jsx`
4. Add navigation link in `client/src/components/Layout.jsx`

**Using Lucide Icons:**
```jsx
import { IconName } from 'lucide-react'

<IconName size={20} className="text-primary-600" />
```

### Database Management

**Reset Database:**
```bash
bundle exec rake db:drop db:create db:migrate db:seed
```

**Add Seed Data:**
Edit `db/seeds.rb` and run:
```bash
bundle exec rake db:seed
```

**Check Database:**
```bash
psql qld_youth_development
\dt  # List tables
\d youths  # Describe table
```

## 🎨 UI/UX Guidelines

### Color Scheme
- Primary: Blue shades (`primary-50` to `primary-900`)
- Success: Green (`badge-success`)
- Warning: Yellow (`badge-warning`)
- Danger: Red (`badge-danger`)
- Info: Blue (`badge-info`)

### Component Patterns

**Card:**
```jsx
<div className="card">
  <h2 className="text-xl font-semibold">Title</h2>
  <p>Content</p>
</div>
```

**Button:**
```jsx
<button className="btn btn-primary">
  <Icon size={18} className="inline mr-2" />
  Button Text
</button>
```

**Input:**
```jsx
<input type="text" className="input" placeholder="Placeholder" />
```

**Badge:**
```jsx
<span className="badge badge-success">Active</span>
```

### Lucide React Icons Usage

**Common Icons:**
- Navigation: `LayoutDashboard`, `Briefcase`, `Users`, `UserCheck`
- Actions: `Search`, `Filter`, `Eye`, `Edit`, `Trash`
- Status: `CheckCircle`, `AlertCircle`, `Clock`, `XCircle`
- UI: `Menu`, `X`, `ChevronDown`, `Plus`, `Minus`
- Data: `Calendar`, `Phone`, `Mail`, `MapPin`, `FileText`

**Best Practices:**
- Always specify size: `size={20}`
- Use className for styling: `className="text-primary-600"`
- Inline with text: `className="inline mr-2"`

## 🧪 Testing

### Manual API Testing

**Using curl:**
```bash
# Get all cases
curl http://localhost:9292/api/cases

# Get specific case
curl http://localhost:9292/api/cases/1

# Create new case
curl -X POST http://localhost:9292/api/cases \
  -H "Content-Type: application/json" \
  -d '{"youth_id":1,"case_manager_id":1,"case_type":"community_order","status":"active"}'
```

**Using Browser DevTools:**
Open Network tab to monitor API calls from the React frontend.

## 📦 Adding Dependencies

### Backend (Ruby)
```bash
# Add to Gemfile
gem 'gem_name', '~> version'

# Install
bundle install
```

### Frontend (Node)
```bash
cd client
npm install package-name
```

## 🐛 Debugging

### Backend Debugging
```ruby
# Add to code for debugging
puts "Debug: #{variable.inspect}"

# Use pry gem for breakpoints
require 'pry'
binding.pry
```

### Frontend Debugging
```jsx
// Console logging
console.log('Debug:', data)

// React DevTools (install browser extension)
// Network tab for API calls
```

## 🚀 Performance Tips

### Backend
- Use `.includes()` for eager loading: `YouthCase.includes(:youth, :case_manager)`
- Add database indexes for frequently queried columns
- Use pagination for large datasets

### Frontend
- Use React.memo() for expensive components
- Implement loading states
- Cache API responses where appropriate
- Lazy load routes with React.lazy()

## 📝 Code Style

### Ruby
- 2 spaces indentation
- Snake_case for variables and methods
- CamelCase for classes
- Follow ActiveRecord conventions

### JavaScript/React
- 2 spaces indentation
- camelCase for variables and functions
- PascalCase for components
- Use functional components with hooks
- Prefer arrow functions

## 🔒 Security Checklist

- [ ] Validate all inputs
- [ ] Sanitize user data
- [ ] Use prepared statements (ActiveRecord does this)
- [ ] Implement authentication (not yet implemented)
- [ ] Implement authorization (not yet implemented)
- [ ] Use HTTPS in production
- [ ] Keep dependencies updated
- [ ] Regular security audits

## 📊 Data Models Reference

### Youth
```ruby
first_name, last_name, date_of_birth, age, gender
address, phone, emergency_contact, emergency_phone
```

### CaseManager
```ruby
first_name, last_name, email, phone
department, specializations
```

### YouthCase
```ruby
youth_id, case_manager_id, case_number
case_type, status, description
start_date, end_date, court_reference, conditions
```

### Intervention
```ruby
youth_case_id, youth_id, program_id
intervention_type, status, description
start_date, end_date, outcomes, attendance_rate
```

### Program
```ruby
name, program_type, description
duration_weeks, capacity, location, status
```

### CaseNote
```ruby
youth_case_id, case_manager_id
note_type, content, is_confidential
```

## 🎯 Next Steps / TODOs

Future enhancements:
- [ ] Implement user authentication (JWT or session-based)
- [ ] Add authorization/role-based access control
- [ ] Implement form validation on frontend
- [ ] Add unit and integration tests
- [ ] Implement real-time notifications
- [ ] Add PDF report generation
- [ ] Implement data export (CSV, Excel)
- [ ] Add audit logging
- [ ] Implement file uploads for documents
- [ ] Add email notifications
- [ ] Create admin dashboard
- [ ] Implement search with full-text indexing
- [ ] Add data visualization charts
- [ ] Mobile app (React Native)

## 📚 Resources

### Documentation
- [Sinatra](http://sinatrarb.com/)
- [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html)
- [React](https://react.dev/)
- [Vite](https://vitejs.dev/)
- [TailwindCSS](https://tailwindcss.com/)
- [Lucide React](https://lucide.dev/)

### Useful Commands
```bash
# Ruby version
ruby -v

# Node version
node -v

# PostgreSQL version
psql --version

# List running processes
ps aux | grep ruby
ps aux | grep node

# Kill process on port
lsof -ti:9292 | xargs kill
lsof -ti:3000 | xargs kill
```

## 🤝 Git Workflow

```bash
# Check status
git status

# Create feature branch
git checkout -b feature/your-feature

# Stage changes
git add .

# Commit
git commit -m "Description of changes"

# Push to GitHub
git push origin feature/your-feature

# Merge to main (after review)
git checkout main
git merge feature/your-feature
git push origin main
```

---

Happy Coding! 🚀

