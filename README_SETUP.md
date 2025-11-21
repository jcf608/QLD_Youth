# QLD Youth Justice Case Management System

A full-stack web application for managing youth justice cases, built with Sinatra, PostgreSQL, Ruby, React, and ActiveRecord.

## 🚀 Technology Stack

### Backend
- **Ruby** 3.0+
- **Sinatra** - Lightweight web framework
- **ActiveRecord** - ORM for database operations
- **PostgreSQL** - Database
- **Puma** - Web server

### Frontend
- **React** 18
- **Vite** - Build tool
- **TailwindCSS** - Styling
- **Lucide React** - Icons
- **React Router** - Navigation
- **Axios** - API client

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- Ruby 3.0 or higher
- PostgreSQL 12 or higher
- Node.js 18 or higher
- npm or yarn

## 🛠️ Installation & Setup

### 1. Clone the Repository

```bash
cd /Users/jimfreeman/Applications-Local/QLD_Youth
```

### 2. Backend Setup

#### Install Ruby Dependencies

```bash
bundle install
```

#### Configure Environment

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Edit `.env` with your PostgreSQL credentials:

```
DATABASE_URL=postgresql://localhost/qld_youth_development
RACK_ENV=development
PORT=9292
```

#### Create and Setup Database

```bash
# Create databases
createdb qld_youth_development
createdb qld_youth_test

# Run migrations
bundle exec rake db:migrate

# Seed the database with sample data
bundle exec rake db:seed
```

### 3. Frontend Setup

#### Install Node Dependencies

```bash
cd client
npm install
```

#### Configure Frontend Environment (Optional)

Create `client/.env` if you need custom API URL:

```
VITE_API_URL=http://localhost:9292
```

## 🏃 Running the Application

### Quick Start (Recommended)

Use the included startup script to run both servers:

```bash
./start
```

This will start:
- **Backend API** on `http://localhost:3090`
- **Frontend UI** on `http://localhost:3091`

Both servers run in the background with logs at `/tmp/qld-backend.log` and `/tmp/qld-frontend.log`

### Manual Start (Development)

If you prefer separate terminals for better visibility:

#### Terminal 1: Start Backend Server

```bash
# From project root
bundle exec rackup -p 3090

# Or use rerun for auto-reload during development
bundle exec rerun 'rackup -p 3090'
```

The API will be available at: `http://localhost:3090`

#### Terminal 2: Start Frontend Development Server

```bash
# From client directory
cd client
npm run dev -- --port 3091
```

The frontend will be available at: `http://localhost:3091`

### Alternative Ports

For default ports (9292 backend, 3000 frontend), use:

```bash
./start-dev.sh
```

## 📊 Database Structure

The application includes the following models:

- **Youth** - Young persons in the justice system (ages 10-17)
- **CaseManager** - Staff managing youth cases
- **YouthCase** - Individual case records
- **Intervention** - Support programs and activities
- **Program** - Structured intervention programs
- **CaseNote** - Case documentation and notes

## 🔌 API Endpoints

### Dashboard
- `GET /api/dashboard/stats` - Get dashboard statistics

### Cases
- `GET /api/cases` - List all cases
- `GET /api/cases/:id` - Get case details
- `POST /api/cases` - Create new case
- `PUT /api/cases/:id` - Update case

### Youth
- `GET /api/youth` - List all youth
- `GET /api/youth/:id` - Get youth details
- `POST /api/youth` - Register new youth

### Case Managers
- `GET /api/case-managers` - List all case managers
- `GET /api/case-managers/:id` - Get manager details

### Interventions
- `GET /api/interventions` - List all interventions
- `POST /api/interventions` - Create intervention
- `PUT /api/interventions/:id` - Update intervention

### Programs
- `GET /api/programs` - List all programs
- `GET /api/programs/:id` - Get program details
- `POST /api/programs` - Create program

### Case Notes
- `POST /api/case-notes` - Add case note

## 🎨 Frontend Features

- **Dashboard** - Overview with statistics and charts
- **Cases Management** - View, filter, and manage cases
- **Youth Registry** - Track all youth in the system
- **Case Managers** - Manage staff assignments
- **Programs** - Track rehabilitation and support programs
- **Interventions** - Monitor intervention effectiveness
- **Responsive Design** - Works on desktop and mobile
- **Modern UI** - Built with TailwindCSS and Lucide icons

## 🧪 Testing

### Backend Tests
```bash
bundle exec rspec
```

### Frontend Tests
```bash
cd client
npm test
```

## 📦 Building for Production

### Build Frontend
```bash
cd client
npm run build
```

### Production Server
```bash
RACK_ENV=production bundle exec rackup -p 9292
```

## 🔒 Security Considerations

- Always use environment variables for sensitive data
- Implement proper authentication before deployment
- Use HTTPS in production
- Sanitize all user inputs
- Implement proper authorization checks
- Regular security audits recommended

## 🤝 Contributing

This is an internal government system. Contact the development team for contribution guidelines.

## 📄 License

Internal use only - Queensland Government, Department of Youth Justice

## 📞 Support

For technical support, contact the Kyndryl team or the project maintainers.

---

**Last Updated:** November 2025  
**Version:** 1.0.0

